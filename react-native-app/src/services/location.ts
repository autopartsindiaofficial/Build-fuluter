import { PermissionsAndroid, Platform, Linking } from 'react-native';
import Geolocation from '@react-native-community/geolocation';
import AsyncStorage from '@react-native-async-storage/async-storage';
import { INDIAN_STATES_AND_DISTRICTS } from '../data/indianLocations';

export const USER_SAVED_LOCATION_KEY = '@autoparts_user_selected_location';

export interface UserSavedLocation {
  city: string;
  state?: string;
  district?: string;
  area?: string;
  lat?: number;
  lng?: number;
  isGPS?: boolean;
  timestamp?: number;
}

export interface LatLng {
  lat: number;
  lng: number;
}

export interface LocationCoords {
  latitude: number;
  longitude: number;
}

export interface GeocodedLocation {
  state: string;
  district: string;
  area: string;
  formattedAddress?: string;
  lat: number;
  lng: number;
}

export interface GeocodeResult {
  city: string;
  state: string;
  country: string;
  displayName: string;
  latitude: number;
  longitude: number;
}

// In-memory cache for fast reverse geocoding
const reverseGeocodeCache = new Map<string, GeocodedLocation>();

/**
 * Saves user selected/detected location to persistent AsyncStorage
 */
export async function saveUserLocation(loc: Partial<UserSavedLocation>): Promise<void> {
  try {
    const payload: UserSavedLocation = {
      city: loc.city || 'All India',
      state: loc.state,
      district: loc.district,
      area: loc.area,
      lat: loc.lat,
      lng: loc.lng,
      isGPS: loc.isGPS ?? false,
      timestamp: Date.now(),
    };
    await AsyncStorage.setItem(USER_SAVED_LOCATION_KEY, JSON.stringify(payload));
  } catch (err) {
    console.warn('Error saving user location to AsyncStorage:', err);
  }
}

/**
 * Gets user saved location from persistent AsyncStorage
 */
export async function getUserSavedLocation(): Promise<UserSavedLocation | null> {
  try {
    const data = await AsyncStorage.getItem(USER_SAVED_LOCATION_KEY);
    if (!data) return null;
    return JSON.parse(data) as UserSavedLocation;
  } catch (err) {
    console.warn('Error retrieving user location from AsyncStorage:', err);
    return null;
  }
}

/**
 * Clears user saved location from persistent AsyncStorage
 */
export async function clearUserSavedLocation(): Promise<void> {
  try {
    await AsyncStorage.removeItem(USER_SAVED_LOCATION_KEY);
  } catch (err) {
    console.warn('Error clearing user location:', err);
  }
}

// Master District Coordinates Table for fallback and auto-centering
export const DISTRICT_COORDINATES: Record<string, LatLng> = {
  // Delhi
  "new delhi": { lat: 28.6139, lng: 77.2090 },
  "central delhi": { lat: 28.6448, lng: 77.2167 },
  "north delhi": { lat: 28.7041, lng: 77.1025 },
  "south delhi": { lat: 28.5300, lng: 77.2628 },
  "east delhi": { lat: 28.6304, lng: 77.2921 },
  "west delhi": { lat: 28.6675, lng: 77.1250 },
  "dwarka": { lat: 28.5889, lng: 77.0578 },
  "rohini": { lat: 28.7455, lng: 77.1149 },
  "connaught place": { lat: 28.6304, lng: 77.2177 },

  // Maharashtra
  "mumbai": { lat: 19.0760, lng: 72.8777 },
  "mumbai city": { lat: 18.9388, lng: 72.8354 },
  "mumbai suburban": { lat: 19.0760, lng: 72.8777 },
  "pune": { lat: 18.5204, lng: 73.8567 },
  "nagpur": { lat: 21.1458, lng: 79.0882 },
  "thane": { lat: 19.2183, lng: 72.9781 },
  "nashik": { lat: 19.9975, lng: 73.7898 },
  "navi mumbai": { lat: 19.0330, lng: 73.0297 },
  "aurangabad": { lat: 19.8762, lng: 75.3433 },
  "solapur": { lat: 17.6599, lng: 75.9064 },
  "kolhapur": { lat: 16.7050, lng: 74.2433 },

  // Karnataka
  "bengaluru": { lat: 12.9716, lng: 77.5946 },
  "bengaluru urban": { lat: 12.9716, lng: 77.5946 },
  "bengaluru rural": { lat: 13.2200, lng: 77.5800 },
  "mysuru": { lat: 12.2958, lng: 76.6394 },
  "mangaluru": { lat: 12.9141, lng: 74.8560 },
  "hubballi-dharwad": { lat: 15.3647, lng: 75.1240 },
  "belagavi": { lat: 15.8497, lng: 74.4977 },

  // Tamil Nadu
  "chennai": { lat: 13.0827, lng: 80.2707 },
  "coimbatore": { lat: 11.0168, lng: 76.9558 },
  "karur": { lat: 10.9601, lng: 78.0766 },
  "pallapatti": { lat: 10.7412, lng: 77.9234 },
  "madurai": { lat: 9.9252, lng: 78.1198 },
  "trichy": { lat: 10.7905, lng: 78.7047 },
  "tiruchirappalli": { lat: 10.7905, lng: 78.7047 },
  "salem": { lat: 11.6643, lng: 78.1460 },
  "tiruppur": { lat: 11.1085, lng: 77.3411 },
  "erode": { lat: 11.3410, lng: 77.7172 },
  "thanjavur": { lat: 10.7870, lng: 79.1378 },
  "vellore": { lat: 12.9165, lng: 79.1325 },
  "tirunelveli": { lat: 8.7139, lng: 77.7567 },
  "thoothukudi": { lat: 8.7642, lng: 78.1348 },

  // Telangana
  "hyderabad": { lat: 17.3850, lng: 78.4867 },
  "warangal": { lat: 17.9689, lng: 79.5941 },
  "nizamabad": { lat: 18.6725, lng: 78.0941 },

  // Gujarat
  "ahmedabad": { lat: 23.0225, lng: 72.5714 },
  "surat": { lat: 21.1702, lng: 72.8311 },
  "vadodara": { lat: 22.3072, lng: 73.1812 },
  "rajkot": { lat: 22.3039, lng: 70.8022 },
  "gandhinagar": { lat: 23.2156, lng: 72.6369 },

  // West Bengal
  "kolkata": { lat: 22.5726, lng: 88.3639 },
  "howrah": { lat: 22.5958, lng: 88.2636 },
  "darjeeling": { lat: 27.0410, lng: 88.2627 },
  "siliguri": { lat: 26.7271, lng: 88.3953 },

  // Uttar Pradesh
  "lucknow": { lat: 26.8467, lng: 80.9462 },
  "kanpur": { lat: 26.4499, lng: 80.3319 },
  "noida": { lat: 28.5355, lng: 77.3910 },
  "gautam buddha nagar": { lat: 28.5355, lng: 77.3910 },
  "ghaziabad": { lat: 28.6692, lng: 77.4538 },
  "agra": { lat: 27.1767, lng: 78.0081 },
  "varanasi": { lat: 25.3176, lng: 82.9739 },
  "prayagraj": { lat: 25.4358, lng: 81.8463 },

  // Kerala
  "kochi": { lat: 9.9312, lng: 76.2673 },
  "thiruvananthapuram": { lat: 8.5241, lng: 76.9366 },
  "kozhikode": { lat: 11.2588, lng: 75.7804 },
  "thrissur": { lat: 10.5276, lng: 76.2144 },

  // Rajasthan
  "jaipur": { lat: 26.9124, lng: 75.7873 },
  "jodhpur": { lat: 26.2389, lng: 73.0243 },
  "udaipur": { lat: 24.5854, lng: 73.7125 },
  "kota": { lat: 25.2138, lng: 75.8648 },

  // Haryana
  "gurugram": { lat: 28.4595, lng: 77.0266 },
  "faridabad": { lat: 28.4089, lng: 77.3178 },
  "panipat": { lat: 29.3909, lng: 76.9635 },

  // Punjab
  "ludhiana": { lat: 30.9010, lng: 75.8573 },
  "amritsar": { lat: 31.6340, lng: 74.8723 },
  "jalandhar": { lat: 31.3260, lng: 75.5762 },

  // Bihar
  "patna": { lat: 25.5941, lng: 85.1376 },
  "gaya": { lat: 24.7914, lng: 85.0002 },

  // Madhya Pradesh
  "indore": { lat: 22.7196, lng: 75.8577 },
  "bhopal": { lat: 23.2599, lng: 77.4126 },
  "gwalior": { lat: 26.2183, lng: 78.1828 },

  // Andhra Pradesh
  "visakhapatnam": { lat: 17.6868, lng: 83.2185 },
  "vijayawada": { lat: 16.5062, lng: 80.6480 },

  // Assam
  "guwahati": { lat: 26.1445, lng: 91.7362 },

  // Chandigarh
  "chandigarh": { lat: 30.7333, lng: 76.7794 }
};

export const STATE_COORDINATES: Record<string, LatLng> = {
  "andhra pradesh": { lat: 15.9129, lng: 79.7400 },
  "assam": { lat: 26.2006, lng: 92.9376 },
  "bihar": { lat: 25.0961, lng: 85.3131 },
  "delhi": { lat: 28.7041, lng: 77.1025 },
  "delhi (nct)": { lat: 28.7041, lng: 77.1025 },
  "gujarat": { lat: 22.2587, lng: 71.1924 },
  "haryana": { lat: 29.0588, lng: 76.0856 },
  "karnataka": { lat: 15.3173, lng: 75.7139 },
  "kerala": { lat: 10.8505, lng: 76.2711 },
  "madhya pradesh": { lat: 22.9734, lng: 78.6569 },
  "maharashtra": { lat: 19.7515, lng: 75.7139 },
  "punjab": { lat: 31.1471, lng: 75.3412 },
  "rajasthan": { lat: 27.0238, lng: 74.2179 },
  "tamil nadu": { lat: 11.1271, lng: 78.6569 },
  "telangana": { lat: 18.1124, lng: 79.0193 },
  "uttar pradesh": { lat: 26.8467, lng: 80.9462 },
  "west bengal": { lat: 22.9868, lng: 87.8550 },
  "odisha": { lat: 20.9517, lng: 85.0985 },
  "chandigarh": { lat: 30.7333, lng: 76.7794 }
};

/**
 * Calculates straight line distance in km between two geo points using Haversine formula
 */
export function calculateDistance(lat1: number, lon1: number, lat2: number, lon2: number): number {
  if (!lat1 || !lon1 || !lat2 || !lon2) return 0;
  const R = 6371; // Earth radius in km
  const dLat = (lat2 - lat1) * (Math.PI / 180);
  const dLon = (lon2 - lon1) * (Math.PI / 180);
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * (Math.PI / 180)) *
      Math.cos(lat2 * (Math.PI / 180)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

/**
 * Finds closest known State and District geometrically
 */
export function findNearestStateAndDistrict(lat: number, lng: number): { state: string; district: string } {
  let closestDistrictName = "New Delhi";
  let minDistDist = Infinity;

  for (const [distKey, coords] of Object.entries(DISTRICT_COORDINATES)) {
    const d = calculateDistance(lat, lng, coords.lat, coords.lng);
    if (d < minDistDist) {
      minDistDist = d;
      closestDistrictName = distKey;
    }
  }

  let closestStateName = "Delhi";
  let minStateDist = Infinity;

  for (const [stateKey, coords] of Object.entries(STATE_COORDINATES)) {
    const d = calculateDistance(lat, lng, coords.lat, coords.lng);
    if (d < minStateDist) {
      minStateDist = d;
      closestStateName = stateKey;
    }
  }

  const capitalize = (str: string) => str.replace(/\b\w/g, l => l.toUpperCase());
  return {
    state: capitalize(closestStateName),
    district: capitalize(closestDistrictName)
  };
}

/**
 * Requests location permission on Android devices
 */
export async function requestLocationPermission(): Promise<boolean> {
  if (Platform.OS !== 'android') return true;

  try {
    const permissionsToRequest: any[] = [
      PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION,
      PermissionsAndroid.PERMISSIONS.ACCESS_COARSE_LOCATION,
    ];

    const result = await PermissionsAndroid.requestMultiple(permissionsToRequest);
    const fineGranted = result[PermissionsAndroid.PERMISSIONS.ACCESS_FINE_LOCATION] === PermissionsAndroid.RESULTS.GRANTED;
    const coarseGranted = result[PermissionsAndroid.PERMISSIONS.ACCESS_COARSE_LOCATION] === PermissionsAndroid.RESULTS.GRANTED;

    return fineGranted || coarseGranted;
  } catch (err) {
    console.warn('Location permission error:', err);
    return false;
  }
}

/**
 * Reverse geocodes coordinates to state/district/area using OSM Nominatim with fallback
 */
export async function reverseGeocodeLatLng(
  lat: number,
  lng: number,
  allStatesAndDistricts?: { state: string; districts: string[] }[]
): Promise<GeocodedLocation> {
  const roundLat = parseFloat(lat.toFixed(4));
  const roundLng = parseFloat(lng.toFixed(4));
  const cacheKey = `${roundLat}_${roundLng}`;
  
  if (reverseGeocodeCache.has(cacheKey)) {
    return reverseGeocodeCache.get(cacheKey)!;
  }

  const statesDataset = allStatesAndDistricts || INDIAN_STATES_AND_DISTRICTS;

  try {
    const controller = new AbortController();
    // Fast 2-second timeout to prevent waiting if network is sluggish
    const timeoutId = setTimeout(() => controller.abort(), 2200);

    const response = await fetch(
      `https://nominatim.openstreetmap.org/reverse?format=json&lat=${roundLat}&lon=${roundLng}&zoom=14&addressdetails=1`,
      {
        signal: controller.signal,
        headers: {
          "Accept-Language": "en",
          "User-Agent": "AutoPartsIndiaApp/1.0 (contact@autopartsmarketplace.com)"
        }
      }
    );
    clearTimeout(timeoutId);

    if (response.ok) {
      const data: any = await response.json();
      const addr = data?.address || {};

      const rawState = addr.state || addr.region || addr.territory || "";
      const rawDistrict = addr.state_district || addr.county || addr.city || addr.district || "";
      const rawArea = addr.suburb || addr.town || addr.village || addr.hamlet || addr.neighbourhood || addr.quarter || addr.residential || addr.city_district || addr.subdistrict || addr.road || "";

      // Clean district string (remove words like 'district', 'city', etc.)
      const cleanedDistrict = rawDistrict
        .replace(/\b(district|dist|city|taluk|division)\b/gi, "")
        .trim();

      // Clean area string
      const cleanedArea = rawArea
        .replace(/\b(post office|po|suburb|taluk)\b/gi, "")
        .trim();

      let finalState = rawState || "";
      let finalDistrict = cleanedDistrict || rawDistrict || "";

      // Match against normalized Indian states dataset
      if (statesDataset && statesDataset.length > 0) {
        const matchedState = statesDataset.find(
          s => rawState.toLowerCase().includes(s.state.toLowerCase()) || s.state.toLowerCase().includes(rawState.toLowerCase())
        );

        if (matchedState) {
          finalState = matchedState.state;
          const matchedDistrict = matchedState.districts.find(
            d => (cleanedDistrict || rawDistrict || "").toLowerCase().includes(d.toLowerCase()) || d.toLowerCase().includes((cleanedDistrict || rawDistrict || "").toLowerCase())
          );
          if (matchedDistrict) {
            finalDistrict = matchedDistrict;
          }
        }
      }

      if (finalState && finalDistrict) {
        const result: GeocodedLocation = {
          state: finalState,
          district: finalDistrict,
          area: cleanedArea,
          formattedAddress: data.display_name,
          lat: roundLat,
          lng: roundLng
        };
        reverseGeocodeCache.set(cacheKey, result);
        return result;
      }
    }
  } catch (err) {
    // Fall back to nearest geometric coordinates in 1ms
  }

  // Geometric instant fallback
  const nearest = findNearestStateAndDistrict(roundLat, roundLng);
  let stateName = nearest.state || "Delhi";
  let districtName = nearest.district || "New Delhi";

  if (statesDataset && statesDataset.length > 0) {
    const stateObj = statesDataset.find(s => s.state.toLowerCase() === stateName.toLowerCase()) ||
      statesDataset.find(s => s.state.toLowerCase().includes(stateName.toLowerCase()));
    if (stateObj) {
      stateName = stateObj.state;
      const foundDist = stateObj.districts.find(
        d => d.toLowerCase() === districtName.toLowerCase() || d.toLowerCase().includes(districtName.toLowerCase())
      );
      if (foundDist) districtName = foundDist;
    }
  }

  const fallbackResult: GeocodedLocation = {
    state: stateName,
    district: districtName,
    area: "",
    lat: roundLat,
    lng: roundLng
  };
  reverseGeocodeCache.set(cacheKey, fallbackResult);
  return fallbackResult;
}

/**
 * Gets current device GPS coordinates with fast-lock and low latency
 */
export async function getCurrentLocation(): Promise<LocationCoords | null> {
  const hasPermission = await requestLocationPermission();
  if (!hasPermission) {
    console.warn('Location permission denied.');
    return { latitude: 19.0760, longitude: 72.8777 }; // Default Mumbai fallback
  }

  return new Promise((resolve) => {
    let resolved = false;

    // Fast resolution guard
    const finish = (coords: LocationCoords) => {
      if (!resolved) {
        resolved = true;
        resolve(coords);
      }
    };

    // 1. Try quick network / cached position first (resolves in ~100-500ms)
    Geolocation.getCurrentPosition(
      (pos) => {
        if (pos?.coords?.latitude && pos?.coords?.longitude) {
          finish({
            latitude: parseFloat(pos.coords.latitude.toFixed(6)),
            longitude: parseFloat(pos.coords.longitude.toFixed(6)),
          });
        }
      },
      () => {
        // network location failed, high accuracy will try
      },
      { enableHighAccuracy: false, timeout: 3000, maximumAge: 180000 }
    );

    // 2. Concurrently attempt High Accuracy GPS with 4.5s max timeout
    Geolocation.getCurrentPosition(
      (pos) => {
        if (pos?.coords?.latitude && pos?.coords?.longitude) {
          finish({
            latitude: parseFloat(pos.coords.latitude.toFixed(6)),
            longitude: parseFloat(pos.coords.longitude.toFixed(6)),
          });
        }
      },
      (error) => {
        console.warn('High accuracy GPS fetch error:', error);
        // Fallback default
        finish({ latitude: 19.0760, longitude: 72.8777 });
      },
      { enableHighAccuracy: true, timeout: 4500, maximumAge: 10000 }
    );

    // Ultimate safeguard timeout (5s)
    setTimeout(() => {
      finish({ latitude: 19.0760, longitude: 72.8777 });
    }, 5000);
  });
}

/**
 * Detects user location and reverse geocodes to state, district, and area
 */
export async function detectUserLocationWithReverseGeocode(): Promise<GeocodedLocation> {
  const coords = await getCurrentLocation();
  const lat = coords?.latitude || 19.0760;
  const lng = coords?.longitude || 72.8777;
  return await reverseGeocodeLatLng(lat, lng);
}

/**
 * Format part location nicely as "Area • District" or "District • State"
 */
export function formatPartLocation(part: { area?: string; district?: string; location?: string; state?: string }): string {
  const area = (part.area || "").trim();
  const district = (part.district || "").trim();
  const state = (part.state || "").trim();

  if (area && district && area.toLowerCase() !== district.toLowerCase()) {
    return `${area} • ${district}`;
  }
  if (area && state && !district) {
    return `${area} • ${state}`;
  }
  if (district && state && district.toLowerCase() !== state.toLowerCase()) {
    return `${district} • ${state}`;
  }
  if (district) {
    return district;
  }
  if (part.location) {
    return part.location;
  }
  if (state) {
    return state;
  }
  return "India";
}

/**
 * Formats location text along with exact distance from current user
 */
export function formatLocationBadgeWithDistance(
  part: { area?: string; district?: string; location?: string; state?: string; lat?: number; lng?: number; latitude?: number; longitude?: number },
  userCoords?: LatLng | LocationCoords | null
): { text: string; distanceText?: string; distanceKm?: number } {
  const locText = formatPartLocation(part);
  const partLat = part.latitude ?? part.lat;
  const partLng = part.longitude ?? part.lng;
  const uLat = (userCoords as any)?.latitude ?? (userCoords as any)?.lat;
  const uLng = (userCoords as any)?.longitude ?? (userCoords as any)?.lng;

  if (
    typeof uLat === "number" && 
    typeof uLng === "number" && 
    typeof partLat === "number" && 
    typeof partLng === "number" && 
    partLat !== 0 && 
    partLng !== 0
  ) {
    const dist = calculateDistance(uLat, uLng, partLat, partLng);
    const distFormatted = dist < 1 ? `${Math.round(dist * 1000)} m away` : `${dist.toFixed(1)} km away`;
    return {
      text: locText,
      distanceText: distFormatted,
      distanceKm: dist
    };
  }

  return { text: locText };
}

/**
 * Gets approximate coordinates for state / district name
 */
export function getApproxCoordinates(state?: string, district?: string): LatLng {
  const normDistrict = district?.toLowerCase().trim();
  const normState = state?.toLowerCase().trim();

  if (normDistrict && DISTRICT_COORDINATES[normDistrict]) {
    return DISTRICT_COORDINATES[normDistrict];
  }

  if (normState && STATE_COORDINATES[normState]) {
    return STATE_COORDINATES[normState];
  }

  return { lat: 28.6139, lng: 77.2090 };
}

/**
 * Backward compatibility: reverseGeocodeOSM
 */
export async function reverseGeocodeOSM(lat: number, lon: number): Promise<GeocodeResult> {
  const res = await reverseGeocodeLatLng(lat, lon);
  return {
    city: res.district || res.area || 'Mumbai',
    state: res.state || 'Maharashtra',
    country: 'India',
    displayName: res.formattedAddress || `${res.district}, ${res.state}`,
    latitude: res.lat,
    longitude: res.lng
  };
}

/**
 * Search locations using OpenStreetMap Nominatim
 */
export async function searchLocationsOSM(query: string): Promise<GeocodeResult[]> {
  if (!query || query.trim().length < 2) return [];

  try {
    const encoded = encodeURIComponent(`${query}, India`);
    const url = `https://nominatim.openstreetmap.org/search?format=json&q=${encoded}&countrycodes=in&limit=6&addressdetails=1`;
    const response = await fetch(url, {
      headers: {
        'User-Agent': 'AutoPartsIndiaApp/1.0',
        'Accept': 'application/json',
      },
    });

    if (!response.ok) return [];

    const results: any = await response.json();
    if (!Array.isArray(results)) return [];

    return results.map((item: any) => {
      const addr = item.address || {};
      const city = addr.city || addr.town || addr.village || addr.county || item.display_name.split(',')[0];
      const state = addr.state || '';
      return {
        city,
        state,
        country: 'India',
        displayName: item.display_name,
        latitude: parseFloat(item.lat),
        longitude: parseFloat(item.lon),
      };
    });
  } catch (err) {
    console.warn('OSM location search error:', err);
    return [];
  }
}

/**
 * Opens Google Maps Navigation or Web Directions directly with intent support
 */
export function openLocationInExternalMaps(lat: number, lng: number, label?: string) {
  const gmapsNavUrl = `google.navigation:q=${lat},${lng}`;
  const gmapsWebUrl = `https://www.google.com/maps/dir/?api=1&destination=${lat},${lng}${label ? `&destination_place_id=${encodeURIComponent(label)}` : ''}`;

  if (Platform.OS === 'android') {
    Linking.canOpenURL(gmapsNavUrl)
      .then((supported) => {
        if (supported) {
          Linking.openURL(gmapsNavUrl);
        } else {
          Linking.openURL(gmapsWebUrl);
        }
      })
      .catch(() => {
        Linking.openURL(gmapsWebUrl);
      });
  } else if (Platform.OS === 'ios') {
    const iosGmapsUrl = `comgooglemaps://?daddr=${lat},${lng}&directionsmode=driving`;
    Linking.canOpenURL(iosGmapsUrl)
      .then((supported) => {
        if (supported) {
          Linking.openURL(iosGmapsUrl);
        } else {
          Linking.openURL(gmapsWebUrl);
        }
      })
      .catch(() => {
        Linking.openURL(gmapsWebUrl);
      });
  } else {
    Linking.openURL(gmapsWebUrl);
  }
}
