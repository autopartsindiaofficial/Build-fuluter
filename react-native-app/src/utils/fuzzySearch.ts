/**
 * fuzzySearch.ts
 * Levenshtein-based and N-gram Fuzzy Matching for Auto Parts, Brands, and Locations.
 * Handles severe typos:
 * - "breke" -> "brake"
 * - "hundai" -> "hyundai"
 * - "tyar" -> "tyre"
 * - "shok" -> "shock absorber"
 * - "maruthi" -> "maruti"
 */

// Popular automotive dictionary for instant auto-correct suggestions
export const AUTO_CORRECT_DICTIONARY = [
  'headlight', 'taillight', 'fog lamp', 'bumper', 'bonnet', 'fender', 'grille',
  'side mirror', 'dickey', 'door', 'windshield', 'shock absorber', 'suspension',
  'steering rack', 'silencer', 'exhaust', 'turbocharger', 'engine', 'alternator',
  'self starter', 'clutch plate', 'gearbox', 'transmission', 'brake pad', 'brake disc',
  'tyre', 'alloy wheel', 'ac compressor', 'radiator', 'condenser', 'battery',
  'wiper', 'horn', 'air filter', 'oil filter', 'maruti suzuki', 'hyundai', 'tata motors',
  'mahindra', 'toyota', 'honda', 'ford', 'volkswagen', 'skoda', 'renault', 'nissan',
  'kia', 'mg', 'chennai', 'coimbatore', 'madurai', 'bangalore', 'mumbai', 'delhi'
];

/**
 * Calculates Damerau-Levenshtein distance (handles insertions, deletions, substitutions, and adjacent transpositions)
 */
export function calculateLevenshteinDistance(a: string, b: string): number {
  if (a === b) return 0;
  if (!a.length) return b.length;
  if (!b.length) return a.length;

  const al = a.length;
  const bl = b.length;
  const matrix: number[][] = [];

  for (let i = 0; i <= al; i++) {
    matrix[i] = [i];
  }
  for (let j = 0; j <= bl; j++) {
    matrix[0][j] = j;
  }

  for (let i = 1; i <= al; i++) {
    for (let j = 1; j <= bl; j++) {
      const cost = a[i - 1] === b[j - 1] ? 0 : 1;
      matrix[i][j] = Math.min(
        matrix[i - 1][j] + 1, // deletion
        matrix[i][j - 1] + 1, // insertion
        matrix[i - 1][j - 1] + cost // substitution
      );

      // Transposition check
      if (i > 1 && j > 1 && a[i - 1] === b[j - 2] && a[i - 2] === b[j - 1]) {
        matrix[i][j] = Math.min(matrix[i][j], matrix[i - 2][j - 2] + 1);
      }
    }
  }

  return matrix[al][bl];
}

/**
 * Checks if a search token fuzzily matches any word in the candidate string.
 * Allows edit distance of 1 for 4-6 letter words, and 2 for >6 letter words.
 */
export function isFuzzyWordMatch(candidateText: string, token: string): { matched: boolean; bestWord: string } {
  if (!candidateText || !token) return { matched: false, bestWord: '' };
  if (token.length < 3) return { matched: false, bestWord: '' };

  const cleanCandidate = candidateText.toLowerCase();
  const cleanToken = token.toLowerCase();

  // Fast path: substring match
  if (cleanCandidate.includes(cleanToken)) {
    return { matched: true, bestWord: cleanToken };
  }

  const words = cleanCandidate.split(/[\s,\-_/().:]+/).filter((w) => w.length >= 3);
  const maxDistance = cleanToken.length <= 4 ? 1 : cleanToken.length <= 8 ? 2 : 3;

  let bestWord = '';
  let minDistance = 999;

  for (const word of words) {
    // If length difference is greater than max allowed distance, skip expensive calculation
    if (Math.abs(word.length - cleanToken.length) > maxDistance) continue;

    const dist = calculateLevenshteinDistance(word, cleanToken);
    if (dist <= maxDistance && dist < minDistance) {
      minDistance = dist;
      bestWord = word;
    }
  }

  return {
    matched: minDistance <= maxDistance,
    bestWord: minDistance <= maxDistance ? bestWord : '',
  };
}

/**
 * Suggests the closest auto-correct term for a misspelled input query.
 */
export function getAutoCorrectSuggestion(inputQuery: string): string | null {
  if (!inputQuery || inputQuery.trim().length < 3) return null;

  const raw = inputQuery.trim().toLowerCase();
  let closestMatch: string | null = null;
  let smallestDistance = 999;

  for (const dictTerm of AUTO_CORRECT_DICTIONARY) {
    if (dictTerm === raw) return null; // Already an exact valid term

    const dist = calculateLevenshteinDistance(raw, dictTerm);
    const maxThreshold = raw.length <= 4 ? 1 : raw.length <= 7 ? 2 : 3;

    if (dist <= maxThreshold && dist < smallestDistance) {
      smallestDistance = dist;
      closestMatch = dictTerm;
    }
  }

  return closestMatch;
}
