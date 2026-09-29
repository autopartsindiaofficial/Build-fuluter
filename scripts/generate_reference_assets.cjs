const fs = require('fs');
const path = require('path');
const sharp = require('sharp');

// Target output directories
const DIRS = [
  path.join(__dirname, '../react-native-app/src/assets/brands'),
  path.join(__dirname, '../react-native-app/src/assets/categories'),
  path.join(__dirname, '../react-native-app/src/assets/banner'),
  path.join(__dirname, '../public/assets/brands'),
  path.join(__dirname, '../public/assets/categories'),
  path.join(__dirname, '../public/assets/banner'),
  path.join(__dirname, '../react-native-app/android/app/src/main/res/drawable'),
];

DIRS.forEach(dir => fs.mkdirSync(dir, { recursive: true }));

// Helper to save SVG to PNG across multiple directories
async function saveSvgToPng(svgString, baseName, width, height, androidDrawableName) {
  const pngBuffer = await sharp(Buffer.from(svgString))
    .resize(width, height)
    .png({ compressionLevel: 9, quality: 100 })
    .toBuffer();

  // Save to react-native-app assets
  const rnaPath = path.join(__dirname, `../react-native-app/src/assets/${baseName}.png`);
  fs.writeFileSync(rnaPath, pngBuffer);

  // Save to public assets for web
  const webPath = path.join(__dirname, `../public/assets/${baseName}.png`);
  fs.writeFileSync(webPath, pngBuffer);

  // Save to android drawable if specified
  if (androidDrawableName) {
    const androidPath = path.join(__dirname, `../react-native-app/android/app/src/main/res/drawable/${androidDrawableName}.png`);
    fs.writeFileSync(androidPath, pngBuffer);
  }

  console.log(`Saved ${baseName}.png (${width}x${height})`);
}

// ==========================================
// 1. BRAND LOGOS (Transparent, Pristine)
// ==========================================

// Maruti Suzuki: The iconic OEM sharp 'S' emblem
const svgMarutiSuzuki = `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="200" height="200">
  <defs>
    <linearGradient id="suzukiRedGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#EF4444"/>
      <stop offset="50%" stop-color="#DC2626"/>
      <stop offset="100%" stop-color="#991B1B"/>
    </linearGradient>
    <filter id="suzukiShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="6" stdDeviation="6" flood-color="#000000" flood-opacity="0.25"/>
    </filter>
  </defs>
  <g filter="url(#suzukiShadow)">
    <!-- Exact mathematical OEM Suzuki Red S -->
    <path d="M 98 36 L 154 36 L 106 84 L 148 84 L 102 164 L 46 164 L 94 116 L 52 116 Z" fill="url(#suzukiRedGrad)"/>
    <!-- Top Chrome highlight edge -->
    <path d="M 98 36 L 154 36 L 146 44 L 102 44 Z" fill="#FFFFFF" opacity="0.6"/>
    <!-- Central bevel reflection -->
    <path d="M 106 84 L 148 84 L 140 92 L 98 92 Z" fill="#FCA5A5" opacity="0.7"/>
    <!-- Bottom base shadow -->
    <path d="M 46 164 L 102 164 L 96 156 L 54 156 Z" fill="#7F1D1D" opacity="0.8"/>
  </g>
</svg>
`;

// Hyundai: The slanted oval 'H' emblem
const svgHyundai = `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="200" height="200">
  <defs>
    <linearGradient id="hyundaiSilver" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#475569"/>
      <stop offset="40%" stop-color="#1E293B"/>
      <stop offset="70%" stop-color="#334155"/>
      <stop offset="100%" stop-color="#0F172A"/>
    </linearGradient>
  </defs>
  <!-- Outer slanted ellipse -->
  <ellipse cx="100" cy="100" rx="88" ry="54" transform="rotate(-15, 100, 100)" fill="none" stroke="url(#hyundaiSilver)" stroke-width="16"/>
  <!-- Slanted H monogram inside -->
  <g transform="rotate(-15, 100, 100)">
    <!-- Left vertical bar (curving inward) -->
    <path d="M 52 64 C 62 85, 62 115, 52 136 C 68 136, 74 125, 78 100 C 74 80, 68 64, 52 64 Z" fill="url(#hyundaiSilver)"/>
    <!-- Right vertical bar (curving inward) -->
    <path d="M 148 64 C 138 85, 138 115, 148 136 C 132 136, 126 125, 122 100 C 126 80, 132 64, 148 64 Z" fill="url(#hyundaiSilver)"/>
    <!-- Center connecting arch -->
    <path d="M 68 103 C 85 92, 115 92, 132 103 C 125 113, 75 113, 68 103 Z" fill="url(#hyundaiSilver)"/>
  </g>
</svg>
`;

// Tata: The official blue oval with dual curved wings forming the iconic T emblem
const svgTata = `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="200" height="200">
  <defs>
    <linearGradient id="tataBlue" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#0284C7"/>
      <stop offset="50%" stop-color="#0369A1"/>
      <stop offset="100%" stop-color="#075985"/>
    </linearGradient>
    <linearGradient id="tataSilver" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#FFFFFF"/>
      <stop offset="60%" stop-color="#F1F5F9"/>
      <stop offset="100%" stop-color="#CBD5E1"/>
    </linearGradient>
    <filter id="tataShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="5" stdDeviation="5" flood-color="#000" flood-opacity="0.25"/>
    </filter>
  </defs>
  <g filter="url(#tataShadow)">
    <!-- Outer Royal Blue Oval -->
    <ellipse cx="100" cy="100" rx="90" ry="60" fill="url(#tataBlue)"/>
    <ellipse cx="100" cy="100" rx="86" ry="56" fill="none" stroke="#7DD3FC" stroke-width="2" opacity="0.6"/>
    
    <!-- Authentic Official Tata Motors 'T' Split Wings Motif -->
    <!-- Left Wing -->
    <path d="M 100 56 C 72 56, 32 78, 32 104 C 32 118, 52 136, 88 142 C 60 134, 46 118, 46 104 C 46 88, 76 72, 100 68 Z" fill="url(#tataSilver)"/>
    <!-- Right Wing -->
    <path d="M 100 56 C 128 56, 168 78, 168 104 C 168 118, 148 136, 112 142 C 140 134, 154 118, 154 104 C 154 88, 124 72, 100 68 Z" fill="url(#tataSilver)"/>
    <!-- Center Dividing Stem -->
    <path d="M 97 66 L 103 66 L 103 140 L 97 140 Z" fill="url(#tataSilver)"/>
  </g>
</svg>
`;

// Mahindra: The new Twin Peaks red butterfly / infinity chrome logo
const svgMahindra = `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="200" height="200">
  <defs>
    <linearGradient id="mahindraRed" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#EF4444"/>
      <stop offset="50%" stop-color="#DC2626"/>
      <stop offset="100%" stop-color="#991B1B"/>
    </linearGradient>
  </defs>
  <!-- Authentic New Mahindra Twin Peaks Logo (Dual flowing red ribbon peaks) -->
  <g transform="translate(10, 30)">
    <!-- Left peak loop -->
    <path d="M 90 95 C 75 75, 45 45, 25 60 C 5 75, 15 110, 45 110 C 70 110, 85 95, 90 95 Z" 
          fill="none" stroke="url(#mahindraRed)" stroke-width="15" stroke-linecap="round" stroke-linejoin="round"/>
    <!-- Right peak loop -->
    <path d="M 90 95 C 105 75, 135 45, 155 60 C 175 75, 165 110, 135 110 C 110 110, 95 95, 90 95 Z" 
          fill="none" stroke="url(#mahindraRed)" stroke-width="15" stroke-linecap="round" stroke-linejoin="round"/>
    <!-- Top interlocking peak crests -->
    <path d="M 52 48 L 90 85 L 128 48" fill="none" stroke="url(#mahindraRed)" stroke-width="12" stroke-linecap="round"/>
  </g>
</svg>
`;

// Toyota: The iconic three overlapping ellipses
const svgToyota = `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 200 200" width="200" height="200">
  <defs>
    <linearGradient id="toyotaMet" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#334155"/>
      <stop offset="50%" stop-color="#0F172A"/>
      <stop offset="100%" stop-color="#1E293B"/>
    </linearGradient>
  </defs>
  <!-- Outer Ellipse -->
  <ellipse cx="100" cy="100" rx="90" ry="62" fill="none" stroke="url(#toyotaMet)" stroke-width="16"/>
  <!-- Vertical center ellipse -->
  <ellipse cx="100" cy="100" rx="30" ry="58" fill="none" stroke="url(#toyotaMet)" stroke-width="14"/>
  <!-- Horizontal inner cross ellipse -->
  <ellipse cx="100" cy="80" rx="60" ry="24" fill="none" stroke="url(#toyotaMet)" stroke-width="14"/>
</svg>
`;

// ==========================================
// 2. CATEGORY 3D ICONS (256x256 Transparent)
// ==========================================

// Category 1: Engine & Parts (3D silver/metallic engine block)
const svgCatEngine = `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
  <defs>
    <linearGradient id="metalTop" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#F8FAFC"/>
      <stop offset="50%" stop-color="#CBD5E1"/>
      <stop offset="100%" stop-color="#94A3B8"/>
    </linearGradient>
    <linearGradient id="metalSide" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#334155"/>
      <stop offset="70%" stop-color="#1E293B"/>
      <stop offset="100%" stop-color="#0F172A"/>
    </linearGradient>
    <linearGradient id="redAccentEngine" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#EF4444"/>
      <stop offset="100%" stop-color="#991B1B"/>
    </linearGradient>
    <radialGradient id="pulleyGleam" cx="40%" cy="40%" r="60%">
      <stop offset="0%" stop-color="#E2E8F0"/>
      <stop offset="60%" stop-color="#64748B"/>
      <stop offset="100%" stop-color="#1E293B"/>
    </radialGradient>
    <filter id="engShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="12" stdDeviation="10" flood-color="#000" flood-opacity="0.25"/>
    </filter>
  </defs>

  <g filter="url(#engShadow)" transform="translate(18, 20) scale(0.86)">
    <!-- Engine Block Base (Cast Iron / Dark Aluminum) -->
    <polygon points="40,110 130,60 210,105 120,165" fill="url(#metalTop)"/>
    <polygon points="40,110 120,165 120,225 40,170" fill="url(#metalSide)"/>
    <polygon points="120,165 210,105 210,165 120,225" fill="#1E293B"/>

    <!-- Dual V-Bank Cylinder Heads (Isometric 3D) -->
    <!-- Left Cylinder Bank -->
    <polygon points="55,100 95,78 120,95 80,118" fill="url(#redAccentEngine)"/>
    <polygon points="80,118 120,95 120,115 80,138" fill="#7F1D1D"/>
    <!-- Cylinder spark plug recesses -->
    <ellipse cx="78" cy="98" rx="6" ry="3" fill="#1E293B"/>
    <ellipse cx="92" cy="90" rx="6" ry="3" fill="#1E293B"/>
    <ellipse cx="106" cy="82" rx="6" ry="3" fill="#1E293B"/>

    <!-- Right Cylinder Bank -->
    <polygon points="125,65 165,45 190,62 150,85" fill="url(#redAccentEngine)"/>
    <polygon points="150,85 190,62 190,82 150,105" fill="#7F1D1D"/>
    <ellipse cx="148" cy="65" rx="6" ry="3" fill="#1E293B"/>
    <ellipse cx="162" cy="57" rx="6" ry="3" fill="#1E293B"/>
    <ellipse cx="176" cy="49" rx="6" ry="3" fill="#1E293B"/>

    <!-- Center Aluminum Intake Manifold Runners -->
    <path d="M 85 85 C 95 65, 130 55, 140 75" stroke="url(#metalTop)" stroke-width="12" fill="none" stroke-linecap="round"/>
    <path d="M 98 92 C 108 72, 143 62, 153 82" stroke="url(#metalTop)" stroke-width="12" fill="none" stroke-linecap="round"/>
    
    <!-- Front Serpentine Pulleys & Belt Assembly -->
    <!-- Crankshaft Pulley (Large Bottom) -->
    <circle cx="80" cy="180" r="28" fill="#0F172A"/>
    <circle cx="80" cy="180" r="24" fill="url(#pulleyGleam)"/>
    <circle cx="80" cy="180" r="10" fill="#0F172A"/>
    <!-- Alternator Pulley (Top Right) -->
    <circle cx="115" cy="140" r="18" fill="#0F172A"/>
    <circle cx="115" cy="140" r="15" fill="url(#pulleyGleam)"/>
    <!-- Water Pump Pulley (Top Left) -->
    <circle cx="50" cy="135" r="16" fill="#0F172A"/>
    <circle cx="50" cy="135" r="13" fill="url(#pulleyGleam)"/>
    <!-- Black Rubber Ribbed Drive Belt connecting all 3 -->
    <path d="M 40 145 C 50 180, 60 205, 80 208 C 100 208, 110 175, 128 150 C 130 130, 110 125, 100 135 C 90 145, 60 125, 42 125 C 34 130, 36 140, 40 145 Z" 
          fill="none" stroke="#090D16" stroke-width="7" stroke-linejoin="round"/>
          
    <!-- Chrome Oil Filter on Front Left -->
    <rect x="22" y="160" width="22" height="34" rx="6" fill="#2563EB" transform="rotate(20, 33, 177)"/>
    <rect x="24" y="162" width="18" height="6" rx="2" fill="#93C5FD" transform="rotate(20, 33, 177)"/>
  </g>
</svg>
`;

// Category 2: Body Parts (3D Electric Blue Car Door)
const svgCatBody = `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
  <defs>
    <linearGradient id="doorBluePaint" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#38BDF8"/>
      <stop offset="30%" stop-color="#0284C7"/>
      <stop offset="70%" stop-color="#0369A1"/>
      <stop offset="100%" stop-color="#0C4A6E"/>
    </linearGradient>
    <linearGradient id="doorWindowGlass" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#1E293B"/>
      <stop offset="40%" stop-color="#334155"/>
      <stop offset="70%" stop-color="#64748B"/>
      <stop offset="100%" stop-color="#0F172A"/>
    </linearGradient>
    <linearGradient id="glassSpecular" x1="0" y1="0" x2="1" y2="0.8">
      <stop offset="0%" stop-color="#FFFFFF" stop-opacity="0.6"/>
      <stop offset="30%" stop-color="#FFFFFF" stop-opacity="0.1"/>
      <stop offset="100%" stop-color="#FFFFFF" stop-opacity="0"/>
    </linearGradient>
    <filter id="doorDrop" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="4" dy="14" stdDeviation="12" flood-color="#0284C7" flood-opacity="0.3"/>
    </filter>
  </defs>

  <g filter="url(#doorDrop)" transform="translate(18, 14)">
    <!-- 3D Car Door Outer Shell -->
    <!-- Window Frame Top Curve -->
    <path d="M 45 110 L 85 35 C 130 35, 175 42, 195 55 L 185 110 Z" fill="#0F172A"/>
    <!-- Glass with realistic automotive reflection -->
    <path d="M 55 105 L 90 45 C 128 45, 165 52, 180 62 L 175 105 Z" fill="url(#doorWindowGlass)"/>
    <path d="M 65 100 L 95 50 L 125 50 L 95 100 Z" fill="url(#glassSpecular)"/>
    
    <!-- Lower Painted Door Body with Aero Curves -->
    <path d="M 40 108 
             C 40 108, 195 105, 195 108 
             C 192 145, 186 185, 175 210 
             C 140 215, 80 215, 52 208 
             C 42 180, 38 140, 40 108 Z" 
          fill="url(#doorBluePaint)"/>

    <!-- Specular Highlight Swage Line (Body character crease) -->
    <path d="M 44 140 C 90 144, 150 144, 188 138" stroke="#7DD3FC" stroke-width="3" fill="none" opacity="0.8"/>
    <!-- Bottom shadow bevel of swage line -->
    <path d="M 44 143 C 90 147, 150 147, 188 141" stroke="#0369A1" stroke-width="2.5" fill="none"/>

    <!-- Flush Modern Chrome Door Handle -->
    <rect x="135" y="125" width="34" height="10" rx="5" fill="#0F172A"/>
    <rect x="136" y="126" width="32" height="7" rx="3.5" fill="#E2E8F0"/>
    <rect x="140" y="128" width="24" height="2" fill="#FFFFFF"/>

    <!-- Side View Mirror Assembly on Window Base -->
    <path d="M 46 95 C 30 92, 15 98, 20 110 C 25 118, 42 112, 48 106 Z" fill="#0F172A"/>
    <path d="M 42 97 C 32 95, 20 99, 23 107 C 27 113, 38 108, 44 104 Z" fill="url(#doorBluePaint)"/>
  </g>
</svg>
`;

// Category 3: Electricals (3D Automotive Battery + Golden Electric Spark)
const svgCatElectricals = `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
  <defs>
    <linearGradient id="batteryBody" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#334155"/>
      <stop offset="60%" stop-color="#1E293B"/>
      <stop offset="100%" stop-color="#0F172A"/>
    </linearGradient>
    <linearGradient id="batteryTop" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#475569"/>
      <stop offset="100%" stop-color="#1E293B"/>
    </linearGradient>
    <linearGradient id="goldFront" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#FEF08A"/>
      <stop offset="40%" stop-color="#FACC15"/>
      <stop offset="100%" stop-color="#EAB308"/>
    </linearGradient>
    <linearGradient id="goldSide" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#CA8A04"/>
      <stop offset="50%" stop-color="#A16207"/>
      <stop offset="100%" stop-color="#713F12"/>
    </linearGradient>
    <filter id="goldGlow" x="-30%" y="-30%" width="160%" height="160%">
      <feDropShadow dx="0" dy="8" stdDeviation="12" flood-color="#EAB308" flood-opacity="0.6"/>
    </filter>
    <filter id="batteryShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="2" dy="12" stdDeviation="10" flood-color="#000000" flood-opacity="0.3"/>
    </filter>
  </defs>

  <g filter="url(#batteryShadow)" transform="translate(18, 14)">
    <!-- 3D Heavy Duty Automotive 12V Battery -->
    <!-- Battery Top Cover -->
    <polygon points="35,110 115,70 195,105 115,145" fill="url(#batteryTop)"/>
    <!-- Battery Front Face -->
    <polygon points="35,110 115,145 115,215 35,180" fill="url(#batteryBody)"/>
    <!-- Battery Side Face -->
    <polygon points="115,145 195,105 195,175 115,215" fill="#0F172A"/>
    
    <!-- Red Positive (+) Terminal Post -->
    <ellipse cx="65" cy="100" rx="10" ry="5" fill="#DC2626"/>
    <rect x="57" y="90" width="16" height="10" rx="2" fill="#EF4444"/>
    <ellipse cx="65" cy="90" rx="8" ry="4" fill="#FCA5A5"/>
    <!-- Red Terminal Lead Wire -->
    <path d="M 65 90 C 65 72, 42 72, 38 85" stroke="#EF4444" stroke-width="4" fill="none" stroke-linecap="round"/>

    <!-- Black/Blue Negative (-) Terminal Post -->
    <ellipse cx="165" cy="95" rx="10" ry="5" fill="#1D4ED8"/>
    <rect x="157" y="85" width="16" height="10" rx="2" fill="#2563EB"/>
    <ellipse cx="165" cy="85" rx="8" ry="4" fill="#93C5FD"/>
    <!-- Blue Terminal Lead Wire -->
    <path d="M 165 85 C 165 68, 188 68, 192 80" stroke="#3B82F6" stroke-width="4" fill="none" stroke-linecap="round"/>

    <!-- Battery Top Cell Caps -->
    <ellipse cx="90" cy="112" rx="7" ry="3.5" fill="#334155"/>
    <ellipse cx="115" cy="122" rx="7" ry="3.5" fill="#334155"/>
    <ellipse cx="140" cy="112" rx="7" ry="3.5" fill="#334155"/>

    <!-- 3D Energetic Electric Spark / Lightning in Front -->
    <g filter="url(#goldGlow)" transform="translate(60, 15) scale(0.8)">
      <polygon points="85,5 20,95 65,95 10,185 105,75 55,75" fill="url(#goldFront)"/>
      <circle cx="85" cy="8" r="4" fill="#FFFFFF"/>
      <line x1="85" y1="0" x2="85" y2="16" stroke="#FFFFFF" stroke-width="2"/>
      <line x1="77" y1="8" x2="93" y2="8" stroke="#FFFFFF" stroke-width="2"/>
    </g>
  </g>
</svg>
`;

// Category 4: Suspension (3D Coilover Shock Spring & Slotted Brake Rotor)
const svgCatSuspension = `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
  <defs>
    <linearGradient id="rotorSilver" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#F8FAFC"/>
      <stop offset="45%" stop-color="#94A3B8"/>
      <stop offset="70%" stop-color="#64748B"/>
      <stop offset="100%" stop-color="#334155"/>
    </linearGradient>
    <linearGradient id="springRed" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#1E293B"/>
      <stop offset="30%" stop-color="#475569"/>
      <stop offset="70%" stop-color="#0F172A"/>
      <stop offset="100%" stop-color="#020617"/>
    </linearGradient>
    <linearGradient id="chromeShaft" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#94A3B8"/>
      <stop offset="50%" stop-color="#FFFFFF"/>
      <stop offset="100%" stop-color="#64748B"/>
    </linearGradient>
    <filter id="suspShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="2" dy="12" stdDeviation="10" flood-color="#000" flood-opacity="0.3"/>
    </filter>
  </defs>

  <g filter="url(#suspShadow)" transform="translate(20, 16)">
    <!-- 1. Brake Disc Rotor (Behind, slightly to the right) -->
    <g transform="translate(90, 85) rotate(15)">
      <!-- Outer Disc Thickness (3D Edge) -->
      <ellipse cx="40" cy="45" rx="55" ry="55" fill="#334155"/>
      <!-- Rotor Face -->
      <circle cx="40" cy="40" r="54" fill="url(#rotorSilver)"/>
      <circle cx="40" cy="40" r="48" fill="none" stroke="#E2E8F0" stroke-width="1" stroke-dasharray="4,4"/>
      <!-- Ventilation Slots on Disc Face -->
      <path d="M 25 15 Q 35 25 32 32" stroke="#1E293B" stroke-width="2.5" fill="none" stroke-linecap="round"/>
      <path d="M 55 15 Q 45 25 48 32" stroke="#1E293B" stroke-width="2.5" fill="none" stroke-linecap="round"/>
      <path d="M 68 30 Q 58 40 54 48" stroke="#1E293B" stroke-width="2.5" fill="none" stroke-linecap="round"/>
      <path d="M 65 58 Q 52 55 48 48" stroke="#1E293B" stroke-width="2.5" fill="none" stroke-linecap="round"/>
      <path d="M 20 50 Q 30 48 35 42" stroke="#1E293B" stroke-width="2.5" fill="none" stroke-linecap="round"/>
      <!-- Center Hub with Wheel Stud Holes -->
      <circle cx="40" cy="40" r="24" fill="#1E293B"/>
      <circle cx="40" cy="40" r="20" fill="#475569"/>
      <circle cx="40" cy="40" r="10" fill="#0F172A"/>
      <circle cx="40" cy="27" r="3" fill="#E2E8F0"/>
      <circle cx="52" cy="35" r="3" fill="#E2E8F0"/>
      <circle cx="48" cy="49" r="3" fill="#E2E8F0"/>
      <circle cx="32" cy="49" r="3" fill="#E2E8F0"/>
      <circle cx="28" cy="35" r="3" fill="#E2E8F0"/>
    </g>

    <!-- 2. Coilover Strut / Shock Absorber (In front, angled) -->
    <g transform="translate(60, 20) rotate(-25)">
      <!-- Top Mount Pillow-ball Hat -->
      <rect x="25" y="0" width="30" height="12" rx="4" fill="#0F172A"/>
      <rect x="35" y="12" width="10" height="10" fill="#E2E8F0"/>
      <!-- Upper Spring Perch Collar -->
      <rect x="20" y="22" width="40" height="8" rx="2" fill="#E11D48"/>
      <!-- Polished Chrome Damper Shaft inside Spring -->
      <rect x="34" y="30" width="12" height="110" fill="url(#chromeShaft)"/>
      
      <!-- Helical Coil Spring Rings (Heavy Duty 3D Coils) -->
      <ellipse cx="40" cy="38" rx="22" ry="7" fill="url(#springRed)"/>
      <ellipse cx="40" cy="54" rx="22" ry="7" fill="url(#springRed)"/>
      <ellipse cx="40" cy="70" rx="22" ry="7" fill="url(#springRed)"/>
      <ellipse cx="40" cy="86" rx="22" ry="7" fill="url(#springRed)"/>
      <ellipse cx="40" cy="102" rx="22" ry="7" fill="url(#springRed)"/>
      <ellipse cx="40" cy="118" rx="22" ry="7" fill="url(#springRed)"/>

      <!-- Lower Adjustable Threaded Locking Rings -->
      <rect x="22" y="125" width="36" height="6" rx="1" fill="#E11D48"/>
      <rect x="24" y="132" width="32" height="6" rx="1" fill="#BE123C"/>
      <!-- Lower Damper Body Tube -->
      <rect x="28" y="138" width="24" height="40" rx="2" fill="#0F172A"/>
      <!-- Bottom Eyelet Bushing Mount -->
      <circle cx="40" cy="188" r="14" fill="#0F172A"/>
      <circle cx="40" cy="188" r="8" fill="url(#chromeShaft)"/>
    </g>
  </g>
</svg>
`;

// Category 5: Exhaust (3D High-Polish Chrome Dual Exhaust Muffler System)
const svgCatExhaust = `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
  <defs>
    <linearGradient id="chromeCanister" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#FFFFFF"/>
      <stop offset="20%" stop-color="#E2E8F0"/>
      <stop offset="45%" stop-color="#64748B"/>
      <stop offset="70%" stop-color="#CBD5E1"/>
      <stop offset="100%" stop-color="#1E293B"/>
    </linearGradient>
    <linearGradient id="pipeChrome" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#F8FAFC"/>
      <stop offset="35%" stop-color="#94A3B8"/>
      <stop offset="70%" stop-color="#475569"/>
      <stop offset="100%" stop-color="#0F172A"/>
    </linearGradient>
    <linearGradient id="titaniumBlue" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#2563EB"/>
      <stop offset="40%" stop-color="#60A5FA"/>
      <stop offset="70%" stop-color="#93C5FD"/>
      <stop offset="100%" stop-color="#38BDF8"/>
    </linearGradient>
    <filter id="exhShadow" x="-25%" y="-25%" width="150%" height="150%">
      <feDropShadow dx="3" dy="10" stdDeviation="8" flood-color="#000000" flood-opacity="0.3"/>
    </filter>
  </defs>

  <g filter="url(#exhShadow)" transform="translate(18, 28) rotate(-14, 110, 100)">
    <!-- Inlet Pipe from Engine Header (Front Right) -->
    <path d="M 180 96 C 210 96, 215 125, 205 155" stroke="url(#pipeChrome)" stroke-width="26" fill="none" stroke-linecap="round"/>
    <ellipse cx="205" cy="155" rx="13" ry="10" fill="#0F172A"/>

    <!-- Main Oval Muffler Silencer Body (3D Cylinder) -->
    <rect x="52" y="58" width="135" height="78" rx="36" fill="url(#chromeCanister)"/>
    
    <!-- Polished Weld Seams & Ribs -->
    <line x1="68" y1="60" x2="68" y2="134" stroke="#FFFFFF" stroke-width="2.5" opacity="0.8"/>
    <line x1="172" y1="60" x2="172" y2="134" stroke="#334155" stroke-width="2.5" opacity="0.8"/>
    <line x1="120" y1="60" x2="120" y2="134" stroke="#CBD5E1" stroke-width="1.5" opacity="0.5"/>

    <!-- Dual Sport Chrome Exhaust Tips (Left) -->
    <!-- Top Tailpipe -->
    <g>
      <path d="M 60 76 L 12 76" stroke="url(#pipeChrome)" stroke-width="22" stroke-linecap="round"/>
      <!-- Burnt Titanium Tip Trim -->
      <rect x="10" y="65" width="16" height="22" rx="4" fill="url(#titaniumBlue)" opacity="0.85"/>
      <!-- Exhaust Tip Opening & Depth -->
      <ellipse cx="12" cy="76" rx="7" ry="11" fill="#0F172A"/>
      <ellipse cx="12" cy="76" rx="4" ry="8" fill="#020617"/>
    </g>

    <!-- Bottom Tailpipe -->
    <g>
      <path d="M 60 118 L 12 118" stroke="url(#pipeChrome)" stroke-width="22" stroke-linecap="round"/>
      <!-- Burnt Titanium Tip Trim -->
      <rect x="10" y="107" width="16" height="22" rx="4" fill="url(#titaniumBlue)" opacity="0.85"/>
      <!-- Exhaust Tip Opening & Depth -->
      <ellipse cx="12" cy="118" rx="7" ry="11" fill="#0F172A"/>
      <ellipse cx="12" cy="118" rx="4" ry="8" fill="#020617"/>
    </g>

    <!-- Heavy Duty Metal Mounting Bracket -->
    <path d="M 90 50 L 134 50" stroke="#94A3B8" stroke-width="6" stroke-linecap="round"/>
    <circle cx="90" cy="50" r="4" fill="#475569"/>
    <circle cx="134" cy="50" r="4" fill="#475569"/>
  </g>
</svg>
`;

// Category 6: Brakes (3D Ventilated Disc Brake Rotor with High-Gloss Racing Red Brembo Caliper)
const svgCatBrakes = `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
  <defs>
    <linearGradient id="brakeRotorFace" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#F8FAFC"/>
      <stop offset="35%" stop-color="#E2E8F0"/>
      <stop offset="70%" stop-color="#94A3B8"/>
      <stop offset="100%" stop-color="#475569"/>
    </linearGradient>
    <linearGradient id="brakeRotorEdge" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#334155"/>
      <stop offset="100%" stop-color="#0F172A"/>
    </linearGradient>
    <linearGradient id="caliperRed" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#FF3838"/>
      <stop offset="40%" stop-color="#E11D48"/>
      <stop offset="80%" stop-color="#BE123C"/>
      <stop offset="100%" stop-color="#881337"/>
    </linearGradient>
    <filter id="brakeShadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="2" dy="12" stdDeviation="10" flood-color="#000" flood-opacity="0.28"/>
    </filter>
  </defs>
  <g filter="url(#brakeShadow)" transform="translate(18, 16)">
    <!-- 3D Disc Rotor -->
    <ellipse cx="110" cy="116" rx="90" ry="90" fill="url(#brakeRotorEdge)"/>
    <circle cx="110" cy="110" r="88" fill="url(#brakeRotorFace)"/>
    <circle cx="110" cy="110" r="82" fill="none" stroke="#CBD5E1" stroke-width="1.5"/>
    <circle cx="110" cy="110" r="54" fill="none" stroke="#64748B" stroke-width="1"/>
    
    <!-- Cross-drilled cooling holes -->
    <circle cx="90" cy="45" r="2.5" fill="#1E293B"/>
    <circle cx="95" cy="50" r="2.5" fill="#1E293B"/>
    <circle cx="100" cy="55" r="2.5" fill="#1E293B"/>
    <circle cx="65" cy="75" r="2.5" fill="#1E293B"/>
    <circle cx="72" cy="82" r="2.5" fill="#1E293B"/>
    <circle cx="80" cy="88" r="2.5" fill="#1E293B"/>
    <circle cx="45" cy="120" r="2.5" fill="#1E293B"/>
    <circle cx="53" cy="125" r="2.5" fill="#1E293B"/>
    <circle cx="62" cy="130" r="2.5" fill="#1E293B"/>
    <circle cx="65" cy="160" r="2.5" fill="#1E293B"/>
    <circle cx="75" cy="165" r="2.5" fill="#1E293B"/>
    <circle cx="85" cy="168" r="2.5" fill="#1E293B"/>
    <circle cx="110" cy="180" r="2.5" fill="#1E293B"/>
    <circle cx="120" cy="180" r="2.5" fill="#1E293B"/>
    <circle cx="130" cy="178" r="2.5" fill="#1E293B"/>
    <circle cx="155" cy="165" r="2.5" fill="#1E293B"/>
    <circle cx="163" cy="158" r="2.5" fill="#1E293B"/>
    <circle cx="170" cy="150" r="2.5" fill="#1E293B"/>

    <!-- Slotted curved grooves on friction band -->
    <path d="M 125 35 Q 115 50 120 62" stroke="#475569" stroke-width="2" fill="none" stroke-linecap="round"/>
    <path d="M 52 95 Q 68 98 75 110" stroke="#475569" stroke-width="2" fill="none" stroke-linecap="round"/>
    <path d="M 75 170 Q 90 160 100 165" stroke="#475569" stroke-width="2" fill="none" stroke-linecap="round"/>
    <path d="M 165 130 Q 155 142 145 140" stroke="#475569" stroke-width="2" fill="none" stroke-linecap="round"/>

    <!-- Center Aluminum Hat / Hub -->
    <circle cx="110" cy="110" r="42" fill="#1E293B"/>
    <circle cx="110" cy="110" r="38" fill="#334155"/>
    <circle cx="110" cy="110" r="18" fill="#0F172A"/>
    <!-- 5 Chrome Wheel Stud Lug Holes -->
    <circle cx="110" cy="86" r="4.5" fill="#E2E8F0"/>
    <circle cx="110" cy="86" r="2.5" fill="#0F172A"/>
    <circle cx="131" cy="100" r="4.5" fill="#E2E8F0"/>
    <circle cx="131" cy="100" r="2.5" fill="#0F172A"/>
    <circle cx="123" cy="126" r="4.5" fill="#E2E8F0"/>
    <circle cx="123" cy="126" r="2.5" fill="#0F172A"/>
    <circle cx="97" cy="126" r="4.5" fill="#E2E8F0"/>
    <circle cx="97" cy="126" r="2.5" fill="#0F172A"/>
    <circle cx="89" cy="100" r="4.5" fill="#E2E8F0"/>
    <circle cx="89" cy="100" r="2.5" fill="#0F172A"/>

    <!-- High-Performance Racing Red Caliper (Top-Right mount) -->
    <g transform="translate(130, 20)">
      <path d="M 5 20 C 15 5, 55 15, 75 45 C 85 60, 75 95, 60 105 C 45 95, 30 70, 25 50 Z" fill="#4C0519"/>
      <path d="M 8 18 C 18 3, 58 12, 78 42 C 86 58, 76 92, 62 102 C 48 92, 33 68, 28 48 Z" fill="url(#caliperRed)"/>
      <path d="M 16 18 C 30 12, 60 22, 72 45" stroke="#FFA4B4" stroke-width="2.5" fill="none" stroke-linecap="round"/>
      <rect x="22" y="5" width="6" height="10" rx="2" fill="#CBD5E1"/>
      <circle cx="25" cy="5" r="2.5" fill="#94A3B8"/>
      <circle cx="50" cy="45" r="10" fill="#BE123C" opacity="0.6"/>
      <circle cx="58" cy="72" r="10" fill="#BE123C" opacity="0.6"/>
      <rect x="36" y="54" width="22" height="4" rx="2" fill="#FFFFFF" transform="rotate(35, 47, 56)"/>
    </g>
  </g>
</svg>
`;

// Category 7: Filters (3D Automotive Pleated Air/Oil Filter with rubber flanges)
const svgCatFilters = `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
  <defs>
    <linearGradient id="filterOrange" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#EA580C"/>
      <stop offset="35%" stop-color="#F97316"/>
      <stop offset="70%" stop-color="#FB923C"/>
      <stop offset="100%" stop-color="#C2410C"/>
    </linearGradient>
    <linearGradient id="rubberEndCap" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#334155"/>
      <stop offset="40%" stop-color="#1E293B"/>
      <stop offset="100%" stop-color="#0F172A"/>
    </linearGradient>
    <linearGradient id="chromeClamp" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#94A3B8"/>
      <stop offset="50%" stop-color="#F8FAFC"/>
      <stop offset="100%" stop-color="#475569"/>
    </linearGradient>
    <filter id="filterDrop" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="3" dy="12" stdDeviation="10" flood-color="#000" flood-opacity="0.25"/>
    </filter>
  </defs>

  <g filter="url(#filterDrop)" transform="translate(42, 22) rotate(15, 85, 105)">
    <!-- Top Rubber Flange & Neck Collar -->
    <ellipse cx="85" cy="22" rx="38" ry="14" fill="#0F172A"/>
    <ellipse cx="85" cy="20" rx="36" ry="12" fill="#1E293B"/>
    <ellipse cx="85" cy="20" rx="26" ry="9" fill="#020617"/>
    
    <!-- Chrome Hose Clamp Band -->
    <ellipse cx="85" cy="30" rx="40" ry="13" fill="none" stroke="url(#chromeClamp)" stroke-width="6"/>
    <rect x="115" y="24" width="10" height="7" rx="2" fill="#E2E8F0"/>
    
    <!-- Top Rubber Molded Flange Base -->
    <path d="M 35 38 C 35 38, 85 52, 135 38 L 138 48 C 138 48, 85 62, 32 48 Z" fill="url(#rubberEndCap)"/>

    <!-- Pleated Filter Paper Body -->
    <path d="M 35 44 L 20 160 C 20 176, 150 176, 150 160 L 135 44 Z" fill="url(#filterOrange)"/>

    <!-- Accordion Pleat Ridges -->
    <line x1="42" y1="46" x2="30" y2="162" stroke="#9A3412" stroke-width="2.5"/>
    <line x1="44" y1="46" x2="32" y2="162" stroke="#FDBA74" stroke-width="1.5"/>
    <line x1="53" y1="48" x2="44" y2="165" stroke="#9A3412" stroke-width="2.5"/>
    <line x1="55" y1="48" x2="46" y2="165" stroke="#FDBA74" stroke-width="1.5"/>
    <line x1="65" y1="49" x2="58" y2="168" stroke="#9A3412" stroke-width="2.5"/>
    <line x1="67" y1="49" x2="60" y2="168" stroke="#FED7AA" stroke-width="1.5"/>
    <line x1="77" y1="50" x2="73" y2="170" stroke="#9A3412" stroke-width="2.5"/>
    <line x1="79" y1="50" x2="75" y2="170" stroke="#FFFFFF" stroke-width="1.5" opacity="0.8"/>
    <line x1="89" y1="50" x2="88" y2="170" stroke="#9A3412" stroke-width="2.5"/>
    <line x1="91" y1="50" x2="90" y2="170" stroke="#FED7AA" stroke-width="1.5"/>
    <line x1="101" y1="49" x2="103" y2="168" stroke="#9A3412" stroke-width="2.5"/>
    <line x1="103" y1="49" x2="105" y2="168" stroke="#FDBA74" stroke-width="1.5"/>
    <line x1="113" y1="48" x2="118" y2="165" stroke="#9A3412" stroke-width="2.5"/>
    <line x1="115" y1="48" x2="120" y2="165" stroke="#FDBA74" stroke-width="1.5"/>
    <line x1="124" y1="46" x2="132" y2="162" stroke="#9A3412" stroke-width="2.5"/>
    <line x1="126" y1="46" x2="134" y2="162" stroke="#FDBA74" stroke-width="1.5"/>

    <!-- Stainless Mesh Grid overlay -->
    <path d="M 28 75 Q 85 92 142 75" stroke="#FFFFFF" stroke-width="1" fill="none" opacity="0.4" stroke-dasharray="3,3"/>
    <path d="M 24 115 Q 85 132 146 115" stroke="#FFFFFF" stroke-width="1" fill="none" opacity="0.4" stroke-dasharray="3,3"/>
    <path d="M 21 145 Q 85 162 149 145" stroke="#FFFFFF" stroke-width="1" fill="none" opacity="0.4" stroke-dasharray="3,3"/>

    <!-- Bottom Molded Rubber End Cap -->
    <ellipse cx="85" cy="162" rx="66" ry="18" fill="#0F172A"/>
    <ellipse cx="85" cy="159" rx="64" ry="16" fill="url(#rubberEndCap)"/>
    <ellipse cx="85" cy="157" rx="56" ry="13" fill="#1E293B"/>
    <circle cx="85" cy="157" r="4" fill="#334155"/>
  </g>
</svg>
`;

// Category 8: More (3D Royal Blue 4-Square Apps Grid with depth)
const svgCatMore = `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256" width="256" height="256">
  <defs>
    <linearGradient id="cubeTop" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#60A5FA"/>
      <stop offset="100%" stop-color="#2563EB"/>
    </linearGradient>
    <linearGradient id="cubeSide" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0%" stop-color="#1D4ED8"/>
      <stop offset="100%" stop-color="#1E3A8A"/>
    </linearGradient>
    <filter id="cubeDrop" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="2" dy="8" stdDeviation="8" flood-color="#1D4ED8" flood-opacity="0.35"/>
    </filter>
  </defs>

  <g filter="url(#cubeDrop)" transform="translate(38, 38)">
    <!-- Top-Left Cube -->
    <g transform="translate(0, 0)">
      <rect x="0" y="4" width="76" height="76" rx="18" fill="url(#cubeSide)"/>
      <rect x="0" y="0" width="76" height="74" rx="18" fill="url(#cubeTop)"/>
    </g>

    <!-- Top-Right Cube -->
    <g transform="translate(100, 0)">
      <rect x="0" y="4" width="76" height="76" rx="18" fill="url(#cubeSide)"/>
      <rect x="0" y="0" width="76" height="74" rx="18" fill="url(#cubeTop)"/>
    </g>

    <!-- Bottom-Left Cube -->
    <g transform="translate(0, 100)">
      <rect x="0" y="4" width="76" height="76" rx="18" fill="url(#cubeSide)"/>
      <rect x="0" y="0" width="76" height="74" rx="18" fill="url(#cubeTop)"/>
    </g>

    <!-- Bottom-Right Cube -->
    <g transform="translate(100, 100)">
      <rect x="0" y="4" width="76" height="76" rx="18" fill="url(#cubeSide)"/>
      <rect x="0" y="0" width="76" height="74" rx="18" fill="url(#cubeTop)"/>
    </g>
  </g>
</svg>
`;

// ==========================================
// 3. HERO BANNER PARTS COMPOSITION
// ==========================================
const svgBannerParts = `
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 500 380" width="500" height="380">
  <defs>
    <radialGradient id="stageGlow" cx="50%" cy="50%" r="50%">
      <stop offset="0%" stop-color="#38BDF8" stop-opacity="0.25"/>
      <stop offset="70%" stop-color="#0284C7" stop-opacity="0.05"/>
      <stop offset="100%" stop-color="#000000" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="discGrad" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0%" stop-color="#F1F5F9"/>
      <stop offset="40%" stop-color="#94A3B8"/>
      <stop offset="80%" stop-color="#475569"/>
      <stop offset="100%" stop-color="#1E293B"/>
    </linearGradient>
    <linearGradient id="altGrad" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="#E2E8F0"/>
      <stop offset="60%" stop-color="#64748B"/>
      <stop offset="100%" stop-color="#1E293B"/>
    </linearGradient>
  </defs>

  <!-- Ambient blue spotlight behind parts -->
  <circle cx="300" cy="180" r="170" fill="url(#stageGlow)"/>

  <!-- 1. Big Slotted Brake Rotor (Right background) -->
  <g transform="translate(260, 40)">
    <circle cx="100" cy="110" r="100" fill="#1E293B"/>
    <circle cx="100" cy="106" r="98" fill="url(#discGrad)"/>
    <!-- Ventilation Slots & Grooves -->
    <circle cx="100" cy="106" r="86" fill="none" stroke="#E2E8F0" stroke-width="1.5" stroke-dasharray="8,6"/>
    <circle cx="100" cy="106" r="70" fill="none" stroke="#CBD5E1" stroke-width="1" stroke-dasharray="6,4"/>
    <path d="M 60 60 Q 80 80 75 95" stroke="#334155" stroke-width="3.5" fill="none" stroke-linecap="round"/>
    <path d="M 140 60 Q 120 80 125 95" stroke="#334155" stroke-width="3.5" fill="none" stroke-linecap="round"/>
    <path d="M 155 120 Q 135 125 120 120" stroke="#334155" stroke-width="3.5" fill="none" stroke-linecap="round"/>
    <path d="M 45 120 Q 65 125 80 120" stroke="#334155" stroke-width="3.5" fill="none" stroke-linecap="round"/>
    <!-- Center Hub -->
    <circle cx="100" cy="106" r="44" fill="#1E293B"/>
    <circle cx="100" cy="106" r="36" fill="#475569"/>
    <circle cx="100" cy="106" r="18" fill="#0F172A"/>
    <!-- 5 Wheel Lugs -->
    <circle cx="100" cy="80" r="5" fill="#E2E8F0"/>
    <circle cx="122" cy="95" r="5" fill="#E2E8F0"/>
    <circle cx="114" cy="122" r="5" fill="#E2E8F0"/>
    <circle cx="86" cy="122" r="5" fill="#E2E8F0"/>
    <circle cx="78" cy="95" r="5" fill="#E2E8F0"/>
  </g>

  <!-- 2. Motor Oil Bottle Canister (Far Right) -->
  <g transform="translate(390, 140)">
    <rect x="0" y="40" width="65" height="130" rx="12" fill="#334155"/>
    <rect x="4" y="44" width="57" height="122" rx="10" fill="#1E293B"/>
    <!-- Golden label with oil drop -->
    <rect x="10" y="80" width="45" height="60" rx="6" fill="#FACC15"/>
    <path d="M 32 95 C 25 105, 25 115, 32 120 C 39 115, 39 105, 32 95 Z" fill="#0F172A"/>
    <!-- Cap and neck -->
    <rect x="18" y="22" width="28" height="20" rx="4" fill="#E11D48"/>
    <rect x="14" y="16" width="36" height="12" rx="4" fill="#BE123C"/>
  </g>

  <!-- 3. Heavy Duty Coilover Suspension Strut (Center, Standing Tall) -->
  <g transform="translate(180, 20)">
    <!-- Top Pillowball Mount Hat -->
    <rect x="30" y="5" width="40" height="15" rx="5" fill="#0F172A"/>
    <rect x="44" y="20" width="12" height="12" fill="#E2E8F0"/>
    <rect x="22" y="32" width="56" height="12" rx="3" fill="#E11D48"/>
    
    <!-- Chrome Shock Shaft -->
    <rect x="42" y="44" width="16" height="150" fill="#E2E8F0"/>
    
    <!-- High-Tension Black Coilover Spring (Isometric Helix) -->
    <ellipse cx="50" cy="55" rx="32" ry="12" fill="#0F172A"/>
    <ellipse cx="50" cy="78" rx="32" ry="12" fill="#0F172A"/>
    <ellipse cx="50" cy="101" rx="32" ry="12" fill="#0F172A"/>
    <ellipse cx="50" cy="124" rx="32" ry="12" fill="#0F172A"/>
    <ellipse cx="50" cy="147" rx="32" ry="12" fill="#0F172A"/>
    <ellipse cx="50" cy="170" rx="32" ry="12" fill="#0F172A"/>

    <!-- Lower Locking Aluminum Perches -->
    <rect x="26" y="195" width="48" height="10" rx="2" fill="#E11D48"/>
    <rect x="30" y="206" width="40" height="10" rx="2" fill="#BE123C"/>
    
    <!-- Lower Body & Mount Bushing -->
    <rect x="36" y="218" width="28" height="50" rx="4" fill="#0F172A"/>
    <circle cx="50" cy="285" r="18" fill="#0F172A"/>
    <circle cx="50" cy="285" r="10" fill="#E2E8F0"/>
  </g>

  <!-- 4. Automotive Alternator (Front Left) -->
  <g transform="translate(80, 160)">
    <!-- Alternator Ribbed Housing -->
    <ellipse cx="75" cy="80" rx="65" ry="60" fill="url(#altGrad)"/>
    <ellipse cx="75" cy="80" rx="55" ry="50" fill="#1E293B"/>
    <!-- Copper wire windings visible inside cooling slots -->
    <circle cx="75" cy="80" r="45" fill="none" stroke="#D97706" stroke-width="8" stroke-dasharray="10,6"/>
    <!-- Center Serpentine Pulley and Nut -->
    <circle cx="75" cy="80" r="28" fill="#475569"/>
    <circle cx="75" cy="80" r="22" fill="#E2E8F0"/>
    <polygon points="75,70 84,75 84,85 75,90 66,85 66,75" fill="#0F172A"/>
    <!-- Mounting ears with bolt holes -->
    <rect x="5" y="60" width="20" height="24" rx="6" fill="#64748B"/>
    <circle cx="15" cy="72" r="5" fill="#0F172A"/>
    <rect x="125" y="60" width="20" height="24" rx="6" fill="#64748B"/>
    <circle cx="135" cy="72" r="5" fill="#0F172A"/>
  </g>

  <!-- 5. Yellow Pleated Paper Oil Filter Cartridge (Front Right) -->
  <g transform="translate(285, 175)">
    <!-- Black Base and Top Rubber Caps -->
    <ellipse cx="45" cy="20" rx="38" ry="12" fill="#0F172A"/>
    <!-- Yellow accordion pleats -->
    <rect x="8" y="20" width="74" height="75" fill="#FACC15"/>
    <!-- Dark vertical pleat grooves -->
    <line x1="16" y1="20" x2="16" y2="95" stroke="#CA8A04" stroke-width="2"/>
    <line x1="24" y1="20" x2="24" y2="95" stroke="#CA8A04" stroke-width="2"/>
    <line x1="32" y1="20" x2="32" y2="95" stroke="#CA8A04" stroke-width="2"/>
    <line x1="40" y1="20" x2="40" y2="95" stroke="#CA8A04" stroke-width="2"/>
    <line x1="48" y1="20" x2="48" y2="95" stroke="#CA8A04" stroke-width="2"/>
    <line x1="56" y1="20" x2="56" y2="95" stroke="#CA8A04" stroke-width="2"/>
    <line x1="64" y1="20" x2="64" y2="95" stroke="#CA8A04" stroke-width="2"/>
    <line x1="72" y1="20" x2="72" y2="95" stroke="#CA8A04" stroke-width="2"/>
    <!-- Bottom rubber flange cap -->
    <ellipse cx="45" cy="95" rx="38" ry="12" fill="#0F172A"/>
    <ellipse cx="45" cy="92" rx="36" ry="10" fill="#334155"/>
  </g>
</svg>
`;

async function run() {
  console.log('Generating Authentic Pixel-Perfect Assets...');

  // 1. Car Brands (200x200)
  await saveSvgToPng(svgMarutiSuzuki, 'brands/maruti_suzuki', 200, 200, 'brand_maruti_suzuki');
  await saveSvgToPng(svgHyundai, 'brands/hyundai', 200, 200, 'brand_hyundai');
  await saveSvgToPng(svgTata, 'brands/tata', 200, 200, 'brand_tata');
  await saveSvgToPng(svgMahindra, 'brands/mahindra', 200, 200, 'brand_mahindra');
  await saveSvgToPng(svgToyota, 'brands/toyota', 200, 200, 'brand_toyota');

  // 2. 3D Categories (256x256)
  await saveSvgToPng(svgCatEngine, 'categories/engine', 256, 256, 'cat_engine');
  await saveSvgToPng(svgCatBody, 'categories/body', 256, 256, 'cat_body');
  await saveSvgToPng(svgCatElectricals, 'categories/electricals', 256, 256, 'cat_electricals');
  await saveSvgToPng(svgCatSuspension, 'categories/suspension', 256, 256, 'cat_suspension');
  await saveSvgToPng(svgCatExhaust, 'categories/exhaust', 256, 256, 'cat_exhaust');
  await saveSvgToPng(svgCatBrakes, 'categories/brakes', 256, 256, 'cat_brakes');
  await saveSvgToPng(svgCatFilters, 'categories/filters', 256, 256, 'cat_filters');
  await saveSvgToPng(svgCatMore, 'categories/more', 256, 256, 'cat_more');

  // 3. Hero Banner Right Art (500x380)
  await saveSvgToPng(svgBannerParts, 'banner/hero_parts_collage', 500, 380, 'banner_parts_collage');

  console.log('All Reference Assets Generated Successfully!');
}

run().catch(err => {
  console.error('Error generating assets:', err);
  process.exit(1);
});
