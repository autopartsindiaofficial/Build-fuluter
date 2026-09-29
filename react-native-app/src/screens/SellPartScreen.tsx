import React, { useState, useEffect, useRef, useMemo } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Image,
  Modal,
  Alert,
  Dimensions,
  Platform,
  ActivityIndicator,
  FlatList,
  LayoutAnimation,
  UIManager,
  TextInput as RNTextInput,
  KeyboardAvoidingView,
} from 'react-native';
import { BottomSheetModal } from '../components/BottomSheetModal';
import { NativeButton } from '../components/NativeButton';
import {
  TextInput,
  Button,
  IconButton,
  Chip,
  Divider,
  Surface,
  useTheme,
  Appbar,
  Icon,
} from 'react-native-paper';
import {
  openNativeCamera,
  openNativeGallery,
  openNativeGalleryMultiple,
  promptImageSourceDialog,
} from '../services/imagePickerService';
import { uploadImageToCloudinary, uploadMultipleImagesToCloudinary, deleteImageFromCloudinary } from '../services/cloudinary';
import {
  getCurrentLocation,
  reverseGeocodeLatLng,
  getApproxCoordinates,
  GeocodedLocation,
  saveUserLocation,
  getUserSavedLocation,
} from '../services/location';
import { getFirebaseFirestore, getCurrentUser, getFirestoreInstance } from '../services/firebase';
import { useLanguage } from '../context/LanguageContext';
import { MapLocationModal } from '../components/MapLocationModal';
import { BrandLogo } from '../components/BrandLogo';
import { ScalePressable } from '../components/animations/ScalePressable';
import { INDIAN_STATES_AND_DISTRICTS, StateWithDistricts } from '../data/indianLocations';
import { MASTER_CATEGORY_PARTS } from '../constants/categories';

const { width } = Dimensions.get('window');

// Default comprehensive taxonomy fallback for instant offline-first & zero-latency cascading
export const DEFAULT_BRAND_MODELS: Record<string, string[]> = {
  'Maruti Suzuki': ['Swift', 'Baleno', 'Brezza', 'Dzire', 'Ertiga', 'Wagon R', 'Alto', 'Grand Vitara', 'Ciaz', 'Fronx', 'Jimny', 'XL6', 'Ignis', 'S-Presso', 'Celerio', 'Ritz', 'Zen', '800'],
  'Hyundai': ['Creta', 'i20', 'Venue', 'Verna', 'Grand i10', 'Aura', 'Tucson', 'Exter', 'Alcazar', 'Santro', 'Eon', 'Xcent', 'Elantra', 'Sonata'],
  'Tata': ['Nexon', 'Punch', 'Harrier', 'Safari', 'Altroz', 'Tiago', 'Tigor', 'Curvv', 'Hexa', 'Indica', 'Indigo', 'Sumo', 'Sierra', 'Bolt', 'Zest'],
  'Mahindra': ['Thar', 'Scorpio-N', 'XUV700', 'Bolero', 'XUV300', 'Scorpio Classic', 'XUV400', 'Marazzo', 'Xylo', 'KUV100', 'TUV300', 'Armada', 'Major'],
  'Toyota': ['Innova Crysta', 'Innova Hycross', 'Fortuner', 'Hyryder', 'Glanza', 'Hilux', 'Camry', 'Etios', 'Etios Liva', 'Corolla Altis', 'Yaris', 'Land Cruiser'],
  'Honda': ['City', 'Amaze', 'Elevate', 'WR-V', 'Jazz', 'Civic', 'BR-V', 'CR-V', 'Brio', 'Accord'],
  'Kia': ['Seltos', 'Sonet', 'Carens', 'Carnival', 'EV6', 'EV9'],
  'Volkswagen': ['Virtus', 'Taigun', 'Polo', 'Vento', 'Tiguan', 'Ameo', 'Jetta', 'Passat'],
  'Skoda': ['Slavia', 'Kushaq', 'Kodiaq', 'Octavia', 'Superb', 'Rapid', 'Fabia', 'Yeti'],
  'Ford': ['EcoSport', 'Endeavour', 'Figo', 'Aspire', 'Freestyle', 'Fiesta', 'Ikon'],
  'MG': ['Hector', 'Hector Plus', 'Astor', 'ZS EV', 'Comet EV', 'Gloster'],
  'Renault': ['Kwid', 'Triber', 'Kiger', 'Duster', 'Lodgy', 'Pulse', 'Scala'],
  'Nissan': ['Magnite', 'Kicks', 'Micra', 'Sunny', 'Terrano', 'Evalia'],
  'Jeep': ['Compass', 'Meridian', 'Wrangler', 'Grand Cherokee'],
  'BMW': ['3 Series', '5 Series', '7 Series', 'X1', 'X3', 'X5', 'X7', 'M3', 'M5'],
  'Mercedes-Benz': ['A-Class', 'C-Class', 'E-Class', 'S-Class', 'GLA', 'GLC', 'GLE', 'GLS'],
  'Audi': ['A4', 'A6', 'A8', 'Q3', 'Q5', 'Q7', 'Q8'],
};

// Brand-specific canonical variants for accurate automotive fitment
export const DEFAULT_BRAND_VARIANTS: Record<string, string[]> = {
  'Maruti Suzuki': [
    'All Variants (Fits All)',
    'LXI',
    'VXI',
    'ZXI',
    'ZXI Plus',
    'LDI',
    'VDI',
    'ZDI',
    'ZDI Plus',
    'Sigma',
    'Delta',
    'Zeta',
    'Alpha',
    'Tour',
    'Base Model',
    'Top Model',
  ],
  'Hyundai': [
    'All Variants (Fits All)',
    'E',
    'EX',
    'S',
    'S(O)',
    'SX',
    'SX(O)',
    'SX Tech',
    'Era',
    'Magna',
    'Sportz',
    'Asta',
    'Asta(O)',
    'Executive',
    'Knight Edition',
    'N Line',
    'Base Model',
    'Top Model',
  ],
  'Tata': [
    'All Variants (Fits All)',
    'Smart',
    'Smart+',
    'Pure',
    'Pure+',
    'Creative',
    'Creative+',
    'Fearless',
    'Fearless+',
    'XE',
    'XM',
    'XT',
    'XZ',
    'XZ+',
    'XZA+',
    'Dark Edition',
    'Red Dark',
    'Base Model',
    'Top Model',
  ],
  'Mahindra': [
    'All Variants (Fits All)',
    'Z2',
    'Z4',
    'Z6',
    'Z8',
    'Z8 Select',
    'Z8L',
    'AX3',
    'AX5',
    'AX7',
    'AX7L',
    'MX',
    'S3',
    'S5',
    'S7',
    'S9',
    'S11',
    'Classic',
    'B4',
    'B6',
    'B6(O)',
    'Base Model',
    'Top Model',
  ],
  'Toyota': [
    'All Variants (Fits All)',
    'E',
    'G',
    'GX',
    'GX+',
    'VX',
    'ZX',
    'ZX(O)',
    'V',
    'Z',
    'Legender',
    'GR Sport',
    'Touring Sport',
    'Base Model',
    'Top Model',
  ],
  'Honda': [
    'All Variants (Fits All)',
    'E',
    'S',
    'V',
    'VX',
    'ZX',
    'SV',
    'Elegance',
    'Exclusive',
    'e:HEV Hybrid',
    'Base Model',
    'Top Model',
  ],
  'Kia': [
    'All Variants (Fits All)',
    'HTE',
    'HTK',
    'HTK+',
    'HTX',
    'HTX+',
    'GTX',
    'GTX+',
    'X-Line',
    'Base Model',
    'Top Model',
  ],
  'Volkswagen': [
    'All Variants (Fits All)',
    'Trendline',
    'Comfortline',
    'Highline',
    'Highline Plus',
    'Topline',
    'GT',
    'GT Plus',
    'Dynamic Line',
    'Base Model',
    'Top Model',
  ],
  'Skoda': [
    'All Variants (Fits All)',
    'Active',
    'Ambition',
    'Style',
    'Prestige',
    'Monte Carlo',
    'Onyx',
    'L&K',
    'RS',
    'Base Model',
    'Top Model',
  ],
  'Ford': [
    'All Variants (Fits All)',
    'Ambiente',
    'Trend',
    'Trend+',
    'Titanium',
    'Titanium+',
    'Sports',
    'S Edition',
    'Base Model',
    'Top Model',
  ],
  'Renault': [
    'All Variants (Fits All)',
    'RXE',
    'RXL',
    'RXT',
    'RXZ',
    'Climber',
    'RXT(O)',
    'Base Model',
    'Top Model',
  ],
  'Nissan': [
    'All Variants (Fits All)',
    'XE',
    'XL',
    'XV',
    'XV Premium',
    'Geza Edition',
    'Base Model',
    'Top Model',
  ],
  'MG': [
    'All Variants (Fits All)',
    'Style',
    'Super',
    'Smart',
    'Smart Pro',
    'Sharp',
    'Sharp Pro',
    'Savvy',
    'Savvy Pro',
    'Blackstorm',
    'Base Model',
    'Top Model',
  ],
  'Jeep': [
    'All Variants (Fits All)',
    'Sport',
    'Longitude',
    'Night Eagle',
    'Limited',
    'Model S',
    'Trailhawk',
  ],
  'BMW': [
    'All Variants (Fits All)',
    'Sport',
    'Luxury Line',
    'M Sport',
    'xDrive',
    'sDrive',
  ],
  'Mercedes-Benz': [
    'All Variants (Fits All)',
    'Progressive',
    'AMG Line',
    'Exclusive',
    'Avantgarde',
    '4MATIC',
  ],
  'Audi': [
    'All Variants (Fits All)',
    'Premium',
    'Premium Plus',
    'Technology',
    'quattro',
  ],
};

// Model-specific popular trim definitions
export const MODEL_SPECIFIC_VARIANTS: Record<string, string[]> = {
  // Maruti Popular
  'Maruti Suzuki Swift': ['All Variants (Fits All)', 'LXI', 'VXI', 'ZXI', 'ZXI Plus', 'LDI (Diesel)', 'VDI (Diesel)', 'ZDI (Diesel)'],
  'Maruti Suzuki Dzire': ['All Variants (Fits All)', 'LXI', 'VXI', 'ZXI', 'ZXI Plus', 'Tour S', 'VDI (Diesel)', 'ZDI (Diesel)'],
  'Maruti Suzuki Baleno': ['All Variants (Fits All)', 'Sigma', 'Delta', 'Zeta', 'Alpha'],
  'Maruti Suzuki Brezza': ['All Variants (Fits All)', 'LXI', 'VXI', 'ZXI', 'ZXI Plus', 'LDI', 'VDI', 'ZDI'],
  'Maruti Suzuki Ertiga': ['All Variants (Fits All)', 'LXI', 'VXI', 'ZXI', 'ZXI Plus', 'Tour M'],
  'Maruti Suzuki Wagon R': ['All Variants (Fits All)', 'LXI (1.0L)', 'VXI (1.0L)', 'ZXI (1.2L)', 'ZXI Plus (1.2L)', 'Tour H3'],
  'Maruti Suzuki Alto': ['All Variants (Fits All)', 'Std', 'LXI', 'VXI', 'VXI Plus', 'Tour H1'],
  // Hyundai Popular
  'Hyundai Creta': ['All Variants (Fits All)', 'E', 'EX', 'S', 'S(O)', 'SX', 'SX(O)', 'SX Tech', 'Knight Edition', 'N Line'],
  'Hyundai i20': ['All Variants (Fits All)', 'Era', 'Magna', 'Sportz', 'Sportz(O)', 'Asta', 'Asta(O)', 'N Line'],
  'Hyundai Venue': ['All Variants (Fits All)', 'E', 'S', 'S(O)', 'S+', 'SX', 'SX(O)', 'Knight Edition', 'N Line'],
  'Hyundai Verna': ['All Variants (Fits All)', 'EX', 'S', 'SX', 'SX(O)', 'Turbo SX(O)'],
  'Hyundai Grand i10': ['All Variants (Fits All)', 'Era', 'Magna', 'Sportz', 'Asta', 'Corporate Edition'],
  // Tata Popular
  'Tata Nexon': ['All Variants (Fits All)', 'Smart', 'Smart+', 'Pure', 'Pure+', 'Creative', 'Creative+', 'Fearless', 'Fearless+', 'Dark Edition'],
  'Tata Punch': ['All Variants (Fits All)', 'Pure', 'Adventure', 'Accomplished', 'Creative', 'Camo Edition'],
  'Tata Harrier': ['All Variants (Fits All)', 'Smart', 'Pure', 'Adventure', 'Fearless', 'Dark Edition'],
  'Tata Safari': ['All Variants (Fits All)', 'Smart', 'Pure', 'Adventure', 'Accomplished', 'Dark Edition', 'Gold Edition'],
  'Tata Altroz': ['All Variants (Fits All)', 'XE', 'XM', 'XM+', 'XT', 'XZ', 'XZ+', 'Racer', 'Dark Edition'],
  'Tata Tiago': ['All Variants (Fits All)', 'XE', 'XT', 'XZ', 'XZ+', 'NRG'],
  // Mahindra Popular
  'Mahindra Scorpio-N': ['All Variants (Fits All)', 'Z2', 'Z4', 'Z6', 'Z8', 'Z8 Select', 'Z8L'],
  'Mahindra Scorpio Classic': ['All Variants (Fits All)', 'S', 'S11', 'S3', 'S5', 'S7', 'S9'],
  'Mahindra Thar': ['All Variants (Fits All)', 'AX', 'AX(O)', 'LX Hard Top', 'LX Soft Top', 'RWD', 'Earth Edition'],
  'Mahindra XUV700': ['All Variants (Fits All)', 'MX', 'AX3', 'AX5', 'AX7', 'AX7L', 'Blaze Edition'],
  'Mahindra Bolero': ['All Variants (Fits All)', 'B4', 'B6', 'B6(O)', 'Power+', 'Plus'],
  'Mahindra XUV300': ['All Variants (Fits All)', 'W4', 'W6', 'W8', 'W8(O)'],
  // Toyota Popular
  'Toyota Innova Crysta': ['All Variants (Fits All)', 'G', 'GX', 'GX+', 'VX', 'ZX', 'Touring Sport'],
  'Toyota Innova Hycross': ['All Variants (Fits All)', 'G', 'GX', 'GX(O)', 'VX', 'ZX', 'ZX(O)'],
  'Toyota Fortuner': ['All Variants (Fits All)', '4x2 MT', '4x2 AT', '4x4 MT', '4x4 AT', 'Legender', 'GR Sport'],
  'Toyota Glanza': ['All Variants (Fits All)', 'E', 'S', 'G', 'V'],
  // Honda Popular
  'Honda City': ['All Variants (Fits All)', 'SV', 'V', 'VX', 'ZX', 'e:HEV Hybrid', 'Type 1', 'Type 2'],
  'Honda Amaze': ['All Variants (Fits All)', 'E', 'S', 'V', 'VX'],
  // Kia Popular
  'Kia Seltos': ['All Variants (Fits All)', 'HTE', 'HTK', 'HTK+', 'HTX', 'HTX+', 'GTX+', 'X-Line'],
  'Kia Sonet': ['All Variants (Fits All)', 'HTE', 'HTK', 'HTK+', 'HTX', 'HTX+', 'GTX+', 'X-Line'],
  // VW & Skoda Popular
  'Volkswagen Polo': ['All Variants (Fits All)', 'Trendline', 'Comfortline', 'Highline', 'Highline Plus', 'GT TSI', 'GT TDI'],
  'Volkswagen Virtus': ['All Variants (Fits All)', 'Comfortline', 'Highline', 'Topline', 'GT', 'GT Plus'],
  'Skoda Slavia': ['All Variants (Fits All)', 'Active', 'Ambition', 'Style', 'Prestige', 'Monte Carlo'],
  'Skoda Rapid': ['All Variants (Fits All)', 'Active', 'Ambition', 'Style', 'Onyx', 'Monte Carlo', 'Rider'],
};

export const DEFAULT_CATEGORY_PARTS: Record<string, string[]> = MASTER_CATEGORY_PARTS;

const CONDITION_OPTIONS = [
  { id: 'New', label: '✨ Brand New', color: '#10B981' },
  { id: 'Used', label: '🔧 Used / Pre-owned', color: '#0B1426' },
] as const;

function formatIndianCurrency(numStr: string | number): string {
  const digits = String(numStr).replace(/[^0-9]/g, '');
  if (!digits) return '';
  const num = parseInt(digits, 10);
  if (isNaN(num)) return '';
  return num.toLocaleString('en-IN');
}

export default function SellPartScreen({ navigation, user: initialUser }: any) {
  const activeUser = initialUser || getCurrentUser();
  const { translateDynamic, language } = useLanguage();

  const SUPER_ADMIN_EMAILS = [
    'wwwautoparts2@gmail.com',
    'www.allahforgiveness877@gmail.com'
  ];
  const isAdmin = 
    activeUser?.role === 'admin' || 
    SUPER_ADMIN_EMAILS.includes((activeUser?.email || '').toLowerCase().trim());

  // Form State
  const [currentStep, setCurrentStep] = useState<1 | 2 | 3>(1);

  
  useEffect(() => {
    if (Platform.OS === 'android' && UIManager.setLayoutAnimationEnabledExperimental) {
      UIManager.setLayoutAnimationEnabledExperimental(true);
    }
  }, []);

  // Prevent going back if not on step 1
  useEffect(() => {
    const unsubscribe = navigation.addListener('beforeRemove', (e: any) => {
      // If we are not on Step 1, prevent the default back action and instead go to the previous step.
      if (currentStep > 1 && e.data.action.type === 'GO_BACK') {
        e.preventDefault();
        LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
        setCurrentStep((prev) => (prev - 1) as 1 | 2 | 3);
      }
    });
    return unsubscribe;
  }, [navigation, currentStep]);

  const [title, setTitle] = useState('');
  const [finalBrand, setCarBrand] = useState('');
  const [finalModel, setCarModel] = useState('');
  const [carVariant, setCarVariant] = useState('');
  const [fuelType, setFuelType] = useState('Petrol');
  const [carYear, setCarYear] = useState('2023');
  const [finalCategory, setCategory] = useState('');
  const [finalPartName, setPartName] = useState('');
  const [condition, setCondition] = useState<'New' | 'Used'>('New');
  const [price, setPrice] = useState('');
  const [isPriceNegotiable, setIsPriceNegotiable] = useState(false);
  const [description, setDescription] = useState('');

  // Location State
  const [finalState, setSelectedState] = useState('');
  const [finalDistrict, setSelectedDistrict] = useState('');
  const [selectedArea, setSelectedArea] = useState('');
  const [lat, setLat] = useState<number | undefined>(undefined);
  const [lng, setLng] = useState<number | undefined>(undefined);
  const [showMapModal, setShowMapModal] = useState(false);

  // Seller Contact
  const [contactName, setContactName] = useState(
    activeUser?.displayName || activeUser?.name || activeUser?.email?.split('@')[0] || ''
  );
  const [contactPhone, setContactPhone] = useState(activeUser?.phone || activeUser?.phoneNumber || '');

  // Media
  const [finalImagesToUse, setUploadedImages] = useState<string[]>([]);
  const [directUrlInput, setDirectUrlInput] = useState('');
  const [showDirectUrlInput, setShowDirectUrlInput] = useState(false);

  // UI Flow States
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [uploadProgress, setUploadProgress] = useState<string | null>(null);
  const [isDetectingLocation, setIsDetectingLocation] = useState(false);
  const [submittedAttempt, setSubmittedAttempt] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [showSuccessScreen, setShowSuccessScreen] = useState(false);

  // User Active Ads Guard
  const [userActiveAdsCount, setUserActiveAdsCount] = useState(0);
  const [userActiveListings, setUserActiveListings] = useState<any[]>([]);
  const [isLimitReached, setIsLimitReached] = useState(false);

  // Dynamic Taxonomy
  const scrollRef = useRef<ScrollView>(null);
  const [taxonomyBrands, setTaxonomyBrands] = useState<Record<string, string[]>>(DEFAULT_BRAND_MODELS);
  const [taxonomyCategories, setTaxonomyCategories] = useState<Record<string, string[]>>(DEFAULT_CATEGORY_PARTS);
  const [isTaxonomyLoading, setIsTaxonomyLoading] = useState(true);

  // Search & Selector Modals
  const [pickerModalType, setPickerModalType] = useState<
    'brand' | 'model' | 'finalCategory' | 'finalPartName' | 'state' | 'district' | 'carYear' | 'carVariant' | null
  >(null);
  const [pickerSearchQuery, setPickerSearchQuery] = useState('');

  // 1. Initialize User Profile and Active Ads check
  useEffect(() => {
    if (activeUser) {
      if (activeUser.displayName || activeUser.name) {
        setContactName(activeUser.displayName || activeUser.name);
      }
      if (activeUser.phone || activeUser.phoneNumber) {
        setContactPhone(activeUser.phone || activeUser.phoneNumber);
      }
      // Also fetch live user document to get latest photoURL/profilePhoto from Firestore
      const db = getFirestoreInstance();
      if (db && activeUser?.uid) {
        db.collection('users').doc(activeUser.uid).get().then((docSnap: any) => {
          if (docSnap.exists) {
            const uData = docSnap.data();
            if (uData.photoURL || uData.profilePhoto) {
              activeUser.photoURL = uData.photoURL || uData.profilePhoto;
              activeUser.profilePhoto = uData.profilePhoto || uData.photoURL;
            }
          }
        }).catch(() => {});
      }
    }

    // Pre-populate saved location if available
    getUserSavedLocation().then((saved) => {
      if (saved) {
        if (saved.state && !finalState) setSelectedState(saved.state);
        if (saved.district && !finalDistrict) setSelectedDistrict(saved.district);
        if (saved.area && !selectedArea) setSelectedArea(saved.area);
        if (saved.lat) setLat(saved.lat);
        if (saved.lng) setLng(saved.lng);
      }
    }).catch(() => {});

    // Check user active ads count in Firestore
    const db = getFirestoreInstance();
    if (db && activeUser?.uid) {
      db.collection('spareParts')
        .where('sellerId', '==', activeUser.uid)
        .get()
        .then((snapshot: any) => {
          const activeDocs: any[] = [];
          snapshot.forEach((doc: any) => {
            const data = doc.data();
            if (data.sold !== true) {
              activeDocs.push({ id: doc.id, ...data });
            }
          });
          setUserActiveAdsCount(activeDocs.length);
          setUserActiveListings(activeDocs);
          if (activeDocs.length >= 5) { /* unlimited posting allowed */ }
        })
        .catch((err: any) => {
          console.warn('[SellScreen] Error fetching user ads count:', err);
        });
    }
  }, [activeUser]);

  // 2. Fetch Taxonomy and TopCategories from Firestore with Real-time Support and Fallback
  useEffect(() => {
    let unsubTaxonomy = () => {};
    let unsubTopCats = () => {};

    try {
      const db = getFirestoreInstance();
      if (db) {
        // Real-time listener for taxonomy/data
        unsubTaxonomy = db.collection('taxonomy').doc('data').onSnapshot(
          (docSnap: any) => {
            if (docSnap && docSnap.exists) {
              const data = docSnap.data();
              if (data?.brands && Array.isArray(data.brands)) {
                const brandMap: Record<string, string[]> = {};
                data.brands.forEach((b: any) => {
                  if (b.name) brandMap[b.name] = b.models || [];
                });
                setTaxonomyBrands(brandMap);
              }
              if (data?.categories && Array.isArray(data.categories)) {
                const catMap: Record<string, string[]> = {};
                data.categories.forEach((c: any) => {
                  if (c.name) catMap[c.name] = c.subcategories || [];
                });
                setTaxonomyCategories(catMap);
              }
            }
            setIsTaxonomyLoading(false);
          },
          (err: any) => {
            console.warn('[SellScreen] Taxonomy snapshot warning:', err);
            setIsTaxonomyLoading(false);
          }
        );

        // Also listen to topCategories collection (synced by Admin CMS)
        unsubTopCats = db.collection('topCategories').onSnapshot(
          (catSnap: any) => {
            if (catSnap && !catSnap.empty) {
              setTaxonomyCategories((prev) => {
                const updated = { ...prev };
                catSnap.forEach((doc: any) => {
                  const cData = doc.data ? doc.data() : doc;
                  if (cData?.name && Array.isArray(cData?.subcategories)) {
                    updated[cData.name] = cData.subcategories;
                  }
                });
                return updated;
              });
            }
          },
          (err: any) => console.warn('[SellScreen] topCategories listener warning:', err)
        );
      }
    } catch (err) {
      console.warn('[SellScreen] Taxonomy setup error:', err);
      setIsTaxonomyLoading(false);
    }

    return () => {
      try { unsubTaxonomy(); } catch (_) {}
      try { unsubTopCats(); } catch (_) {}
    };
  }, []);

  // Derived available options
  const availableBrands = Object.keys(taxonomyBrands);
  const availableModels = finalBrand && taxonomyBrands[finalBrand] ? taxonomyBrands[finalBrand] : [];
  const availableCategories = Object.keys(taxonomyCategories);
  const availablePartNames = finalCategory && taxonomyCategories[finalCategory] ? taxonomyCategories[finalCategory] : [];

  const availableVariants = useMemo(() => {
    if (!finalBrand && !finalModel) {
      return ['All Variants (Fits All)', 'Base Model', 'Mid Model', 'Top Model'];
    }

    const brandKey = finalBrand.trim();
    const modelKey = `${brandKey} ${finalModel}`.trim();

    // Check if model-specific variant list exists
    if (MODEL_SPECIFIC_VARIANTS[modelKey]) {
      return MODEL_SPECIFIC_VARIANTS[modelKey];
    }

    // Check if brand-specific variant list exists
    if (DEFAULT_BRAND_VARIANTS[brandKey]) {
      return DEFAULT_BRAND_VARIANTS[brandKey];
    }

    // Default fallback
    return [
      'All Variants (Fits All)',
      'Base Model',
      'Mid Model',
      'Top Model',
    ];
  }, [finalBrand, finalModel]);

  const availableStates = INDIAN_STATES_AND_DISTRICTS.map((s) => s.state);
  const finalStateObj = INDIAN_STATES_AND_DISTRICTS.find((s) => s.state === finalState);
  const availableDistricts = finalStateObj ? finalStateObj.districts : [];

  // Helper: Auto-compose ad title
  const updateAutoTitle = (brand: string, model: string, variant: string, part: string) => {
    const partsList = [brand, model, variant, part].filter(Boolean);
    if (partsList.length >= 2) {
      setTitle(partsList.join(' '));
    }
  };

  const handleBrandSelect = (brand: string) => {
    setCarBrand(brand);
    setCarModel('');
    setCarVariant('');
    updateAutoTitle(brand, '', '', finalPartName);
    setPickerModalType(null);
    setPickerSearchQuery('');
  };

  const handleModelSelect = (model: string) => {
    setCarModel(model);
    setCarVariant('');
    updateAutoTitle(finalBrand, model, '', finalPartName);
    setPickerModalType(null);
    setPickerSearchQuery('');
  };

  const handleCategorySelect = (cat: string) => {
    setCategory(cat);
    setPartName('');
    updateAutoTitle(finalBrand, finalModel, carVariant, '');
    setPickerModalType(null);
    setPickerSearchQuery('');
  };

  const handlePartNameSelect = (part: string) => {
    setPartName(part);
    updateAutoTitle(finalBrand, finalModel, carVariant, part);
    setPickerModalType(null);
    setPickerSearchQuery('');
  };

  const handleStateSelect = (state: string) => {
    setSelectedState(state);
    setSelectedDistrict('');
    setPickerModalType(null);
    setPickerSearchQuery('');
  };

  const handleDistrictSelect = (district: string) => {
    setSelectedDistrict(district);
    setPickerModalType(null);
    setPickerSearchQuery('');
  };

  // Image actions - Instant Optimistic UI
  const handleAddPhoto = async () => {
    if (finalImagesToUse.length >= 6) {
      Alert.alert('Limit Reached', 'You can upload a maximum of 6 images.');
      return;
    }
    try {
      const uri = await promptImageSourceDialog(
        'Upload Auto Part Photo',
        'Choose an option to upload the spare part picture:'
      );
      if (uri) {
        setUploadedImages((prev) => [...prev, uri]);
      }
    } catch (err) {
      console.warn('Image picker error:', err);
    }
  };

  // Instant deletion without extra blocking confirmation delays
  const handleRemoveImage = (index: number) => {
    const targetUri = finalImagesToUse[index];
    // Immediate optimistic state update
    setUploadedImages((prev) => prev.filter((_, i) => i !== index));

    // Async background Cloudinary cleanup if it was already uploaded
    if (targetUri && (targetUri.startsWith('http://') || targetUri.startsWith('https://'))) {
      deleteImageFromCloudinary(targetUri).catch((err) =>
        console.log('[Async Image Delete Notice]', err)
      );
    }
  };

  const handleSetCoverPhoto = (index: number) => {
    if (index === 0) return;
    setUploadedImages((prev) => {
      const copy = [...prev];
      const target = copy.splice(index, 1)[0];
      copy.unshift(target);
      return copy;
    });
  };

  const handleMoveImage = (index: number, direction: 'left' | 'right') => {
    setUploadedImages((prev) => {
      const copy = [...prev];
      const targetIndex = direction === 'left' ? index - 1 : index + 1;
      if (targetIndex < 0 || targetIndex >= copy.length) return prev;
      const temp = copy[index];
      copy[index] = copy[targetIndex];
      copy[targetIndex] = temp;
      return copy;
    });
  };

  const handleAddDirectUrl = () => {
    const cleanUrl = directUrlInput.trim();
    if (!cleanUrl) return;
    if (!cleanUrl.startsWith('http://') && !cleanUrl.startsWith('https://')) {
      Alert.alert('Invalid URL', 'Please enter a valid image URL starting with https://');
      return;
    }
    if (finalImagesToUse.length >= 6) {
      Alert.alert('Limit Reached', 'Maximum 6 photos allowed.');
      return;
    }
    setUploadedImages((prev) => [...prev, cleanUrl]);
    setDirectUrlInput('');
    setShowDirectUrlInput(false);
  };

  // GPS Location Detection
  const handleDetectLocation = async () => {
    setIsDetectingLocation(true);
    setErrorMessage(null);
    try {
      const coords = await getCurrentLocation();
      if (coords) {
        setLat(coords.latitude);
        setLng(coords.longitude);
        const geocoded: GeocodedLocation = await reverseGeocodeLatLng(coords.latitude, coords.longitude);
        if (geocoded?.state) setSelectedState(geocoded.state);
        if (geocoded?.district) setSelectedDistrict(geocoded.district);
        if (geocoded?.area) setSelectedArea(geocoded.area);
        await saveUserLocation({
          city: geocoded?.district || geocoded?.state || 'Chennai',
          district: geocoded?.district,
          state: geocoded?.state,
          area: geocoded?.area,
          lat: coords.latitude,
          lng: coords.longitude,
          isGPS: true,
        });
      }
    } catch (err: any) {
      console.warn('GPS detection error:', err);
      setErrorMessage('Could not auto-detect location. Please select State & District manually.');
    } finally {
      setIsDetectingLocation(false);
    }
  };

  const handleNextStep1 = () => {
    setSubmittedAttempt(true);
    setErrorMessage(null);

    if (!finalCategory) {
      setErrorMessage('Please select a Part Category.');
      return;
    }
    if (!finalPartName) {
      setErrorMessage('Please select or enter the Part Name.');
      return;
    }
    if (!finalBrand) {
      setErrorMessage('Please select the Car Brand.');
      return;
    }
    if (!finalModel) {
      setErrorMessage('Please select the Car Model.');
      return;
    }
    if (!title.trim()) {
      const composed = `${finalBrand} ${finalModel} ${finalPartName}`.trim();
      setTitle(composed);
    }

    setSubmittedAttempt(false);
    LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
    setCurrentStep(2);
    scrollRef.current?.scrollTo({ y: 0, animated: true });
  };

  const handleNextStep2 = () => {
    setSubmittedAttempt(true);
    setErrorMessage(null);

    if (finalImagesToUse.length === 0) {
      setErrorMessage('Please upload at least 1 photo of your spare part.');
      return;
    }

    const cleanPriceDigits = String(price).replace(/[^0-9.]/g, '');
    const priceNum = parseFloat(cleanPriceDigits);
    if (!cleanPriceDigits || isNaN(priceNum) || priceNum <= 0) {
      setErrorMessage('Please enter a valid selling price in ₹.');
      return;
    }

    setSubmittedAttempt(false);
    LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
    setCurrentStep(3);
    scrollRef.current?.scrollTo({ y: 0, animated: true });
  };

  const handlePublish = async () => {
    setSubmittedAttempt(true);
    setErrorMessage(null);

    // 0. Authentication Check
    if (!activeUser?.uid) {
      setErrorMessage('Please sign in or log in to post your spare part ad.');
      return;
    }

    // Mandatory Price Validation
    const cleanPriceDigits = String(price).replace(/[^0-9.]/g, '');
    const priceNum = parseFloat(cleanPriceDigits);
    if (!cleanPriceDigits || isNaN(priceNum) || priceNum <= 0) {
      setErrorMessage('Please enter a valid selling price greater than ₹0.');
      return;
    }

    // Mandatory State & District Validation
    if (!finalState.trim() || !finalDistrict.trim()) {
      setErrorMessage('Please select both State and District / City.');
      return;
    }

    // Mandatory Contact Phone Validation
    const cleanPhone = (contactPhone || '').replace(/[^0-9]/g, '');
    if (!cleanPhone || cleanPhone.length < 10) {
      setErrorMessage('Please enter a valid 10-digit mobile number.');
      return;
    }

    const resolvedBrand = finalBrand.trim();
    const resolvedModel = finalModel.trim();
    const resolvedCategory = finalCategory.trim();
    const resolvedPartName = finalPartName.trim();
    const resolvedTitle = title.trim() || `${resolvedBrand} ${resolvedModel} ${resolvedPartName}`.trim();
    const resolvedDesc = description.trim() || `High quality ${resolvedPartName} for ${resolvedBrand} ${resolvedModel} in ${condition} condition.`;
    const resolvedState = finalState.trim();
    const resolvedDistrict = finalDistrict.trim();
    const resolvedContactName = contactName.trim() || activeUser?.displayName || 'Auto Parts Seller';
    const resolvedContactPhone = cleanPhone;

    if (isSubmitting) return;

    setIsSubmitting(true);
    setUploadProgress('Uploading photos in parallel...');

    try {
      const finalImageUrls = await uploadMultipleImagesToCloudinary(
        finalImagesToUse,
        'spare_parts',
        (completed, total) => {
          setUploadProgress(`Uploading photos (${completed}/${total})...`);
        }
      );

      setUploadProgress('Saving ad across India...');

      let finalLat = lat;
      let finalLng = lng;
      if (finalLat === undefined || finalLng === undefined || finalLat === 0 || finalLng === 0) {
        const approx = getApproxCoordinates(resolvedState, resolvedDistrict);
        finalLat = approx.lat;
        finalLng = approx.lng;
      }

      const readableLoc = selectedArea.trim()
        ? `${selectedArea.trim()}, ${resolvedDistrict}`
        : `${resolvedDistrict}, ${resolvedState}`;

      const listingData = {
        title: resolvedTitle,
        description: resolvedDesc,
        price: priceNum,
        isPriceNegotiable: isPriceNegotiable,
        brand: resolvedBrand,
        carBrand: resolvedBrand,
        finalBrand: resolvedBrand,
        model: resolvedModel,
        carModel: resolvedModel,
        finalModel: resolvedModel,
        carVariant: carVariant.trim() || null,
        fuelType: fuelType && fuelType !== 'All / Any' ? fuelType : null,
        carYear: carYear || '2023',
        category: resolvedCategory,
        finalCategory: resolvedCategory,
        partName: resolvedPartName,
        finalPartName: resolvedPartName,
        condition,
        location: readableLoc,
        city: resolvedDistrict,
        state: resolvedState,
        district: resolvedDistrict,
        area: selectedArea.trim() || null,
        lat: finalLat || null,
        lng: finalLng || null,
        latitude: finalLat || null,
        longitude: finalLng || null,
        contactName: resolvedContactName,
        contactPhone: resolvedContactPhone,
        imageUrl: finalImageUrls[0] || finalImagesToUse[0] || '',
        imageUrls: finalImageUrls.length > 0 ? finalImageUrls : finalImagesToUse,
        images: finalImageUrls.length > 0 ? finalImageUrls : finalImagesToUse,
        sellerId: activeUser?.uid || 'guest-seller',
        ownerId: activeUser?.uid || 'guest-seller',
        userId: activeUser?.uid || 'guest-seller',
        sellerEmail: activeUser?.email || '',
        ownerEmail: activeUser?.email || '',
        sellerPhoto: activeUser?.photoURL || activeUser?.profilePhoto || '',
        sellerPhotoURL: activeUser?.photoURL || activeUser?.profilePhoto || '',
        sellerAvatar: activeUser?.photoURL || activeUser?.profilePhoto || '',
        sellerName: resolvedContactName || activeUser?.displayName || 'Auto Seller',
        sold: false,
        isDeleted: false,
        status: 'active',
        approved: true,
        verified: true,
        createdAt: Date.now(),
        updatedAt: Date.now(),
      };

      const db = getFirestoreInstance();
      if (db) {
        const newDocId = 'part_' + Date.now() + '_' + Math.random().toString(36).substring(2, 7);
        const fullListing = { id: newDocId, ...listingData };
        await db.collection('spareParts').doc(newDocId).set(fullListing);
      }

      setUploadProgress(null);
      setShowSuccessScreen(true);

      setTimeout(() => {
        setShowSuccessScreen(false);
        resetForm();
        LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
        setCurrentStep(1);
        navigation.navigate('MainTabs', { screen: 'HomeTab' });
      }, 1000);
    } catch (err: any) {
      setErrorMessage(err.message || 'Failed to post ad. Please check internet connection.');
    } finally {
      setIsSubmitting(false);
      setUploadProgress(null);
    }
  };

  const resetForm = () => {
    setTitle('');
    setDescription('');
    setPrice('');
    setCarBrand('');
    setCarModel('');
    setCarVariant('');
    setFuelType('All / Any');
    setCategory('');
    setPartName('');
    setCondition('New');
    setSelectedState('');
    setSelectedDistrict('');
    setSelectedArea('');
    setUploadedImages([]);
    setLat(undefined);
    setLng(undefined);
    setSubmittedAttempt(false);
    setErrorMessage(null);
  };

  // Success View Screen
  if (showSuccessScreen) {
    return (
      <View style={styles.successContainer}>
        <View style={styles.successBadge}>
          <Text style={{ fontSize: 36 }}>✅</Text>
        </View>
        <Text style={styles.successTitle}>Ad Posted Successfully!</Text>
        <Text style={styles.successSub}>
          Your spare part listing is now live across India! Buyers can contact you directly via phone or in-app chat.
        </Text>
        <ActivityIndicator size="small" color="#60A5FA" style={{ marginTop: 24 }} />
        <Text style={styles.successRedirect}>Redirecting to marketplace...</Text>
      </View>
    );
  }

  // Active Ads Limit View Screen
  if (isLimitReached) {
    return (
      <View style={styles.limitContainer}>
        <View style={styles.nativeHeader}>
          <BrandLogo size={32} />
          <View style={{ marginLeft: 10 }}>
            <Text style={{ fontSize: 18, fontWeight: '800', color: '#FFFFFF' }}>Sell Spare Part</Text>
            <Text style={{ fontSize: 12, color: '#94A3B8' }}>Post ads across India</Text>
          </View>
        </View>

        <ScrollView contentContainerStyle={styles.limitContent}>
          <View style={styles.limitIconBox}>
            <IconButton icon="alert-circle" size={36} iconColor="#F59E0B" />
          </View>
          <Text style={styles.limitTitle}>5 Active Ads Limit Reached</Text>
          <Text style={styles.limitSub}>
            You currently have {userActiveAdsCount} active listings. Delete or mark an existing ad as sold to post new parts.
          </Text>

          <Surface style={styles.activeAdsCard} elevation={1}>
            <Text style={styles.activeAdsHeading}>Your Active Ads ({userActiveListings.length}):</Text>
            {userActiveListings.map((ad) => (
              <View key={ad.id} style={styles.adItemRow}>
                <Image
                  source={{ uri: ad.imageUrl || 'https://via.placeholder.com/60' }}
                  style={styles.adItemThumb}
                />
                <View style={{ flex: 1, marginLeft: 10 }}>
                  <Text style={styles.adItemTitle} numberOfLines={1}>
                    {ad.title}
                  </Text>
                  <Text style={styles.adItemPrice}>₹{Number(ad.price || 0).toLocaleString('en-IN')}</Text>
                </View>
              </View>
            ))}
          </Surface>

          <Button
            mode="contained"
            buttonColor="#0F172A"
            onPress={() => navigation.navigate('MainTabs', { screen: 'MyAdsTab' })}
            style={{ marginTop: 20, borderRadius: 12, width: '100%' }}
          >
            Manage My Listings
          </Button>
        </ScrollView>
      </View>
    );
  }

  // Modal List Filter Items
  const getModalItems = () => {
    const q = pickerSearchQuery.trim().toLowerCase();
    switch (pickerModalType) {
      case 'brand':
        return availableBrands.filter((b) => b.toLowerCase().includes(q));
      case 'model':
        return availableModels.filter((m) => m.toLowerCase().includes(q));
      case 'finalCategory':
        return availableCategories.filter((c) =>
          c.toLowerCase().includes(q) || translateDynamic(c).toLowerCase().includes(q)
        );
      case 'finalPartName':
        return availablePartNames.filter((p) => p.toLowerCase().includes(q));
      case 'state':
        return availableStates.filter((s) => s.toLowerCase().includes(q));
      case 'district':
        return availableDistricts.filter((d) => d.toLowerCase().includes(q));
      case 'carYear': {
        const years = Array.from({ length: 37 }, (_, i) => String(2026 - i));
        return years.filter((y) => y.includes(q));
      }
      case 'carVariant': {
        const filtered = availableVariants.filter((v) => v.toLowerCase().includes(q));
        // If user typed a search query that isn't already an exact match, allow selecting as custom variant
        if (q && !availableVariants.some((v) => v.toLowerCase() === q)) {
          return [pickerSearchQuery.trim(), ...filtered];
        }
        return filtered;
      }
      default:
        return [];
    }
  };

  return (
    <KeyboardAvoidingView
      style={styles.root}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      {/* Native-style header with step info */}
      <View style={styles.nativeHeader}>
        <Appbar.BackAction
          color="#FFFFFF"
          onPress={() => {
            if (currentStep > 1) {
              LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
        setCurrentStep((prev) => (prev - 1) as 1 | 2 | 3);
            } else {
              navigation.goBack();
            }
          }}
          style={styles.headerBack}
        />

        <View style={styles.headerCenter}>
          <Text style={styles.nativeHeaderTitle}>Sell Your Part</Text>
          <Text style={styles.nativeHeaderSub}>
            {currentStep === 1 && 'Step 1 of 3: Part & Vehicle Fitment'}
            {currentStep === 2 && 'Step 2 of 3: Photos, Condition & Price'}
            {currentStep === 3 && 'Step 3 of 3: Location & Seller Details'}
          </Text>
        </View>

        <View style={styles.stepBadgePill}>
          <Text style={styles.stepBadgePillText}>{currentStep}/3</Text>
        </View>
      </View>

      {/* Segmented Progress Indicator Bar */}
      <View style={styles.segmentProgressTrack}>
        <View style={[styles.segmentBar, currentStep >= 1 ? styles.segmentBarActive : styles.segmentBarInactive]} />
        <View style={[styles.segmentBar, currentStep >= 2 ? styles.segmentBarActive : styles.segmentBarInactive]} />
        <View style={[styles.segmentBar, currentStep >= 3 ? styles.segmentBarActive : styles.segmentBarInactive]} />
      </View>

      <ScrollView
        ref={scrollRef}
        style={styles.nativeScroll}
        contentContainerStyle={styles.nativeContent}
        keyboardShouldPersistTaps="handled"
        keyboardDismissMode="on-drag"
        showsVerticalScrollIndicator={false}
        scrollEventThrottle={16}
        bounces={true}
        alwaysBounceVertical={true}
        decelerationRate="normal"
        overScrollMode="never"
      >
        {errorMessage && (
          <View style={styles.errorBanner}>
            <IconButton icon="alert-circle-outline" size={19} iconColor="#DC2626" style={{ margin: 0 }} />
            <Text style={styles.errorText}>{errorMessage}</Text>
          </View>
        )}

        {/* STEP 1: Part Info & Vehicle Compatibility */}
        {currentStep === 1 && (
          <>
            {/* Part Information Card */}
            <View style={styles.nativeSection}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 12 }}>
                <View style={styles.sectionIconCircle}>
                  <Icon source="format-list-bulleted" size={18} color="#0066FF" />
                </View>
                <Text style={styles.nativeSectionTitle}>Part Information</Text>
              </View>

              {/* Category */}
              <View style={styles.nativeField}>
                <Text style={styles.fieldLabel}>Category *</Text>
                <TouchableOpacity
                  style={[styles.nativePicker, submittedAttempt && !finalCategory && styles.fieldError]}
                  onPress={() => {
                    setPickerSearchQuery('');
                    setPickerModalType('finalCategory');
                  }}
                >
                  <View style={{ marginRight: 8 }}><Icon source="cog-outline" size={18} color="#0066FF" /></View>
                  <Text style={[styles.pickerValue, !finalCategory && styles.pickerPlaceholder]} numberOfLines={1}>
                    {finalCategory ? translateDynamic(finalCategory) : 'Select Category'}
                  </Text>
                  <Icon source="chevron-down" size={20} color="#64748B" />
                </TouchableOpacity>
              </View>

              {/* Part Name */}
              <View style={styles.nativeField}>
                <Text style={styles.fieldLabel}>Part Name *</Text>
                <TouchableOpacity
                  style={[styles.nativePicker, !finalCategory && styles.nativePickerDisabled, submittedAttempt && !finalPartName && styles.fieldError]}
                  disabled={!finalCategory}
                  onPress={() => {
                    setPickerSearchQuery('');
                    setPickerModalType('finalPartName');
                  }}
                >
                  <View style={{ marginRight: 8 }}><Icon source="cube-outline" size={18} color="#0066FF" /></View>
                  <Text style={[styles.pickerValue, !finalPartName && styles.pickerPlaceholder]} numberOfLines={1}>
                    {finalPartName || (finalCategory ? 'e.g. Alternator, Headlight, Bumper' : 'Select Category First')}
                  </Text>
                  <Icon source="chevron-down" size={20} color="#64748B" />
                </TouchableOpacity>
              </View>
            </View>

            {/* Vehicle Fitment Card */}
            <View style={styles.nativeSection}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 12 }}>
                <View style={styles.sectionIconCircle}>
                  <Icon source="car" size={18} color="#0066FF" />
                </View>
                <Text style={styles.nativeSectionTitle}>Vehicle Fitment</Text>
              </View>

              {/* Car Brand */}
              <View style={styles.nativeField}>
                <Text style={styles.fieldLabel}>Car Brand *</Text>
                <TouchableOpacity
                  style={[styles.nativePicker, submittedAttempt && !finalBrand && styles.fieldError]}
                  onPress={() => {
                    setPickerSearchQuery('');
                    setPickerModalType('brand');
                  }}
                >
                  <View style={{ marginRight: 8 }}><Icon source="car-outline" size={18} color="#0066FF" /></View>
                  <Text style={[styles.pickerValue, !finalBrand && styles.pickerPlaceholder]}>
                    {finalBrand || 'Select Brand (e.g. Maruti, Hyundai, Tata)'}
                  </Text>
                  <Icon source="chevron-down" size={20} color="#64748B" />
                </TouchableOpacity>
              </View>

              {/* Car Model */}
              <View style={styles.nativeField}>
                <Text style={styles.fieldLabel}>Car Model *</Text>
                <TouchableOpacity
                  style={[styles.nativePicker, !finalBrand && styles.nativePickerDisabled, submittedAttempt && !finalModel && styles.fieldError]}
                  disabled={!finalBrand}
                  onPress={() => {
                    setPickerSearchQuery('');
                    setPickerModalType('model');
                  }}
                >
                  <View style={{ marginRight: 8 }}><Icon source="car-side" size={18} color="#0066FF" /></View>
                  <Text style={[styles.pickerValue, !finalModel && styles.pickerPlaceholder]}>
                    {finalModel || (finalBrand ? 'Select Model (e.g. Swift, Creta)' : 'Select Brand First')}
                  </Text>
                  <Icon source="chevron-down" size={20} color="#64748B" />
                </TouchableOpacity>
              </View>

              {/* Year & Fuel Type Row */}
              <View style={{ flexDirection: 'row', gap: 10, marginTop: 4 }}>
                <View style={{ flex: 1 }}>
                  <Text style={styles.fieldLabel}>Model Year *</Text>
                  <TouchableOpacity
                    style={styles.nativePicker}
                    onPress={() => {
                      setPickerSearchQuery('');
                      setPickerModalType('carYear');
                    }}
                  >
                    <View style={{ marginRight: 4 }}><Icon source="calendar" size={16} color="#0066FF" /></View>
                    <Text style={[styles.pickerValue, !carYear && styles.pickerPlaceholder]} numberOfLines={1}>
                      {carYear || 'Select Year'}
                    </Text>
                    <Icon source="chevron-down" size={18} color="#64748B" />
                  </TouchableOpacity>
                </View>

                <View style={{ flex: 1 }}>
                  <Text style={styles.fieldLabel}>Fuel Type</Text>
                  <TouchableOpacity
                    style={styles.nativePicker}
                    onPress={() => {
                      Alert.alert(
                        'Select Fuel Type',
                        'Choose vehicle fuel type:',
                        ['Petrol', 'Diesel', 'CNG', 'Electric', 'Hybrid'].map((ft) => ({
                          text: ft,
                          onPress: () => setFuelType(ft),
                        }))
                      );
                    }}
                  >
                    <View style={{ marginRight: 4 }}><Icon source="gas-station" size={16} color="#0066FF" /></View>
                    <Text style={styles.pickerValue} numberOfLines={1}>
                      {fuelType || 'Petrol'}
                    </Text>
                    <Icon source="chevron-down" size={18} color="#64748B" />
                  </TouchableOpacity>
                </View>
              </View>

              {/* Variant (Optional) */}
              <View style={[styles.nativeField, { marginTop: 10 }]}>
                <Text style={styles.fieldLabel}>Variant (Optional)</Text>
                <TouchableOpacity
                  style={[styles.nativePicker, !finalModel && styles.nativePickerDisabled]}
                  disabled={!finalModel}
                  onPress={() => {
                    setPickerSearchQuery('');
                    setPickerModalType('carVariant');
                  }}
                >
                  <View style={{ marginRight: 8 }}><Icon source="layers-outline" size={18} color="#0066FF" /></View>
                  <Text style={[styles.pickerValue, !carVariant && styles.pickerPlaceholder]}>
                    {carVariant || 'e.g. VXI, ZXI, SX(O)'}
                  </Text>
                  <Icon source="chevron-down" size={20} color="#64748B" />
                </TouchableOpacity>
              </View>
            </View>

            {/* Ad Title Card */}
            <View style={styles.nativeSection}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 10 }}>
                <View style={styles.sectionIconCircle}>
                  <Icon source="file-document-outline" size={18} color="#0066FF" />
                </View>
                <Text style={styles.nativeSectionTitle}>Ad Title</Text>
              </View>

              <View style={[styles.nativePicker, submittedAttempt && !title && styles.fieldError]}>
                <RNTextInput
                  value={title}
                  onChangeText={(val) => setTitle(val.slice(0, 100))}
                  placeholder="e.g. Maruti Swift Alternator (2020)"
                  placeholderTextColor="#94A3B8"
                  style={{ flex: 1, fontSize: 13, color: '#0F172A', paddingVertical: 8 }}
                />
              </View>
              <Text style={styles.counterTextRight}>{title.length}/100</Text>
            </View>
          </>
        )}

        {/* STEP 2: Photos, Condition & Pricing */}
        {currentStep === 2 && (
          <>
            {/* Photos Upload Section */}
            <View style={styles.nativeSection}>
              <View style={styles.sectionTopRow}>
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
                  <View style={styles.sectionIconCircle}>
                    <Icon source="camera-outline" size={18} color="#0066FF" />
                  </View>
                  <Text style={styles.nativeSectionTitle}>Photos Upload *</Text>
                </View>
                <Text style={styles.sectionBadgeText}>{finalImagesToUse.length}/6 added</Text>
              </View>

              <View style={styles.photoActionRow}>
                <TouchableOpacity style={styles.photoBoxCard} onPress={handleAddPhoto}>
                  <Icon source="camera-plus-outline" size={24} color="#0066FF" />
                  <Text style={styles.photoBoxText}>Add Photo</Text>
                </TouchableOpacity>
              </View>

              {finalImagesToUse.length > 0 && (
                <View style={styles.photoGrid}>
                  {finalImagesToUse.map((uri, index) => (
                    <View key={`${uri}-${index}`} style={styles.photoTile}>
                      <Image source={{ uri }} style={styles.photoImage} resizeMode="cover" />
                      {index === 0 && (
                        <View style={styles.coverPill}>
                          <Text style={styles.coverPillText}>COVER</Text>
                        </View>
                      )}
                      <TouchableOpacity
                        style={styles.photoDelete}
                        onPress={() => handleRemoveImage(index)}
                        hitSlop={{ top: 10, bottom: 10, left: 10, right: 10 }}
                      >
                        <Icon source="close" size={14} color="#FFFFFF" />
                      </TouchableOpacity>
                    </View>
                  ))}
                </View>
              )}
            </View>

            {/* Condition Section */}
            <View style={styles.nativeSection}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 12 }}>
                <View style={styles.sectionIconCircle}>
                  <Icon source="cube-outline" size={18} color="#0066FF" />
                </View>
                <Text style={styles.nativeSectionTitle}>Condition *</Text>
              </View>

              <View style={styles.conditionCardsRow}>
                <TouchableOpacity
                  style={[
                    styles.conditionCard,
                    condition === 'New' && styles.conditionCardActive,
                  ]}
                  onPress={() => setCondition('New')}
                  activeOpacity={0.85}
                >
                  <View style={styles.conditionIconBadge}>
                    <Text style={{ fontSize: 16 }}>✦</Text>
                  </View>
                  <Text style={[styles.conditionCardTitle, condition === 'New' && styles.conditionTextActive]}>
                    Brand New
                  </Text>
                  <Text style={styles.conditionCardSub}>Unused, OEM/Original</Text>
                  {condition === 'New' && (
                    <View style={styles.conditionCheckBadge}>
                      <Icon source="check" size={12} color="#FFFFFF" />
                    </View>
                  )}
                </TouchableOpacity>

                <TouchableOpacity
                  style={[
                    styles.conditionCard,
                    condition === 'Used' && styles.conditionCardActive,
                  ]}
                  onPress={() => setCondition('Used')}
                  activeOpacity={0.85}
                >
                  <View style={styles.conditionIconBadge}>
                    <Icon source="sync" size={18} color="#0066FF" />
                  </View>
                  <Text style={[styles.conditionCardTitle, condition === 'Used' && styles.conditionTextActive]}>
                    Used – Pre-owned
                  </Text>
                  <Text style={styles.conditionCardSub}>Working condition</Text>
                  {condition === 'Used' && (
                    <View style={styles.conditionCheckBadge}>
                      <Icon source="check" size={12} color="#FFFFFF" />
                    </View>
                  )}
                </TouchableOpacity>
              </View>
            </View>

            {/* Price Section */}
            <View style={styles.nativeSection}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 12 }}>
                <View style={styles.sectionIconCircle}>
                  <Icon source="currency-inr" size={18} color="#0066FF" />
                </View>
                <Text style={styles.nativeSectionTitle}>Set Your Price *</Text>
              </View>

              <View style={[styles.priceBoxRow, submittedAttempt && (!price || parseFloat(price) <= 0) && styles.fieldError]}>
                <Text style={styles.rupeeSymbol}>₹</Text>
                <RNTextInput
                  value={price ? formatIndianCurrency(price) : ''}
                  onChangeText={(val) => setPrice(val.replace(/[^0-9]/g, ''))}
                  keyboardType="numeric"
                  placeholder="Enter selling price"
                  placeholderTextColor="#94A3B8"
                  style={styles.priceTextInput}
                />
              </View>

              <View style={styles.negotiableSwitchRow}>
                <View style={{ marginRight: 8 }}><Icon source="handshake-outline" size={18} color="#0066FF" /></View>
                <View style={{ flex: 1 }}>
                  <Text style={{ fontSize: 13, fontWeight: '700', color: '#0F172A' }}>Price Negotiable</Text>
                  <Text style={{ fontSize: 11, color: '#64748B' }}>Allow buyers to negotiate best price</Text>
                </View>
                <TouchableOpacity
                  onPress={() => setIsPriceNegotiable(!isPriceNegotiable)}
                  style={[styles.customToggleTrack, isPriceNegotiable && styles.customToggleActive]}
                >
                  <View style={[styles.customToggleThumb, isPriceNegotiable && styles.customToggleThumbActive]} />
                </TouchableOpacity>
              </View>
            </View>
          </>
        )}

        {/* STEP 3: Location, Description & Contact */}
        {currentStep === 3 && (
          <>
            {/* Live Summary Preview Card */}
            <View style={styles.previewSummaryCard}>
              <View style={styles.previewSummaryTop}>
                {finalImagesToUse[0] ? (
                  <Image source={{ uri: finalImagesToUse[0] }} style={styles.previewSummaryThumb} resizeMode="cover" />
                ) : (
                  <View style={[styles.previewSummaryThumb, { alignItems: 'center', justifyContent: 'center', backgroundColor: '#E2E8F0' }]}>
                    <Icon source="image-outline" size={20} color="#94A3B8" />
                  </View>
                )}
                <View style={{ flex: 1, marginLeft: 10 }}>
                  <Text style={styles.previewSummaryTitle} numberOfLines={1}>
                    {title || `${finalBrand} ${finalModel} ${finalPartName}`}
                  </Text>
                  <Text style={styles.previewSummaryFitment}>
                    {finalBrand} {finalModel} • {carYear} • {condition}
                  </Text>
                  <Text style={styles.previewSummaryPrice}>
                    ₹{price ? formatIndianCurrency(price) : '0'}
                    {isPriceNegotiable && <Text style={{ fontSize: 11, color: '#16A34A', fontWeight: '600' }}> (Negotiable)</Text>}
                  </Text>
                </View>
              </View>
            </View>

            {/* Location Section */}
            <View style={styles.nativeSection}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 12 }}>
                <View style={styles.sectionIconCircle}>
                  <Icon source="map-marker-outline" size={18} color="#0066FF" />
                </View>
                <Text style={styles.nativeSectionTitle}>Location *</Text>
              </View>

              {/* State */}
              <View style={styles.nativeField}>
                <Text style={styles.fieldLabel}>State *</Text>
                <TouchableOpacity
                  style={[styles.nativePicker, submittedAttempt && !finalState && styles.fieldError]}
                  onPress={() => {
                    setPickerSearchQuery('');
                    setPickerModalType('state');
                  }}
                >
                  <View style={{ marginRight: 8 }}><Icon source="map-marker" size={18} color="#0066FF" /></View>
                  <Text style={[styles.pickerValue, !finalState && styles.pickerPlaceholder]}>
                    {finalState || 'Select State (e.g. Tamil Nadu, Maharashtra)'}
                  </Text>
                  <Icon source="chevron-down" size={20} color="#64748B" />
                </TouchableOpacity>
              </View>

              {/* District / City */}
              <View style={styles.nativeField}>
                <Text style={styles.fieldLabel}>District / City *</Text>
                <TouchableOpacity
                  style={[styles.nativePicker, !finalState && styles.nativePickerDisabled, submittedAttempt && !finalDistrict && styles.fieldError]}
                  disabled={!finalState}
                  onPress={() => {
                    setPickerSearchQuery('');
                    setPickerModalType('district');
                  }}
                >
                  <View style={{ marginRight: 8 }}><Icon source="city" size={18} color="#0066FF" /></View>
                  <Text style={[styles.pickerValue, !finalDistrict && styles.pickerPlaceholder]}>
                    {finalDistrict || (finalState ? 'Select District / City' : 'Select State First')}
                  </Text>
                  <Icon source="chevron-down" size={20} color="#64748B" />
                </TouchableOpacity>
              </View>

              {/* Area / Town */}
              <View style={styles.nativeField}>
                <Text style={styles.fieldLabel}>Area / Town (Optional)</Text>
                <View style={styles.nativePicker}>
                  <View style={{ marginRight: 8 }}><Icon source="map" size={18} color="#0066FF" /></View>
                  <RNTextInput
                    value={selectedArea}
                    onChangeText={setSelectedArea}
                    placeholder="e.g. Anna Nagar, T. Nagar"
                    placeholderTextColor="#94A3B8"
                    style={{ flex: 1, fontSize: 13, color: '#0F172A', paddingVertical: 8 }}
                  />
                </View>
              </View>

              {/* Location Action Buttons */}
              <View style={{ flexDirection: 'row', gap: 10, marginTop: 10 }}>
                <TouchableOpacity
                  style={styles.gpsButtonCard}
                  onPress={async () => {
                    setIsDetectingLocation(true);
                    try {
                      const loc = await getCurrentLocation();
                      if (loc) {
                        const geocoded = await reverseGeocodeLatLng(loc.latitude, loc.longitude);
                        if (geocoded) {
                          if (geocoded.state) setSelectedState(geocoded.state);
                          if (geocoded.district) setSelectedDistrict(geocoded.district);
                          if (geocoded.area) setSelectedArea(geocoded.area);
                          setLat(loc.latitude);
                          setLng(loc.longitude);
                        }
                      }
                    } catch (err) {
                      Alert.alert('GPS Error', 'Unable to detect location automatically.');
                    } finally {
                      setIsDetectingLocation(false);
                    }
                  }}
                >
                  {isDetectingLocation ? (
                    <ActivityIndicator size="small" color="#0066FF" />
                  ) : (
                    <Icon source="crosshairs-gps" size={18} color="#0066FF" />
                  )}
                  <View style={{ marginLeft: 8 }}>
                    <Text style={{ fontSize: 13, fontWeight: '700', color: '#0066FF' }}>Auto GPS</Text>
                    <Text style={{ fontSize: 11, color: '#64748B' }}>Detect current location</Text>
                  </View>
                </TouchableOpacity>

                <TouchableOpacity style={styles.gpsButtonCard} onPress={() => setShowMapModal(true)}>
                  <Icon source="map-outline" size={18} color="#0066FF" />
                  <View style={{ marginLeft: 8 }}>
                    <Text style={{ fontSize: 13, fontWeight: '700', color: '#0066FF' }}>Pick on Map</Text>
                    <Text style={{ fontSize: 11, color: '#64748B' }}>Pinpoint exact spot</Text>
                  </View>
                </TouchableOpacity>
              </View>
            </View>

            {/* Description Section */}
            <View style={styles.nativeSection}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 10 }}>
                <View style={styles.sectionIconCircle}>
                  <Icon source="file-document-edit-outline" size={18} color="#0066FF" />
                </View>
                <Text style={styles.nativeSectionTitle}>Description (Optional)</Text>
              </View>

              <RNTextInput
                value={description}
                onChangeText={(val) => setDescription(val.slice(0, 500))}
                multiline
                textAlignVertical="top"
                placeholder="Mention part condition, warranty, or any extra fitment details..."
                placeholderTextColor="#94A3B8"
                style={[styles.descriptionBox, submittedAttempt && !description && styles.fieldError]}
              />
              <Text style={styles.counterTextRight}>{description.length}/500</Text>
            </View>

            {/* Contact Details Section */}
            <View style={styles.nativeSection}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 12 }}>
                <View style={styles.sectionIconCircle}>
                  <Icon source="account-outline" size={18} color="#0066FF" />
                </View>
                <Text style={styles.nativeSectionTitle}>Seller Contact *</Text>
              </View>

              <View style={styles.nativeField}>
                <Text style={styles.fieldLabel}>Your Name *</Text>
                <View style={styles.nativePicker}>
                  <View style={{ marginRight: 8 }}><Icon source="account" size={18} color="#0066FF" /></View>
                  <RNTextInput
                    value={contactName}
                    onChangeText={setContactName}
                    placeholder="Enter your name"
                    placeholderTextColor="#94A3B8"
                    style={{ flex: 1, fontSize: 13, color: '#0F172A', paddingVertical: 8 }}
                  />
                </View>
              </View>

              <View style={styles.nativeField}>
                <Text style={styles.fieldLabel}>Mobile Number (For Buyer Calls) *</Text>
                <View style={styles.nativePicker}>
                  <View style={{ marginRight: 8 }}><Icon source="phone" size={18} color="#0066FF" /></View>
                  <RNTextInput
                    value={contactPhone}
                    onChangeText={setContactPhone}
                    keyboardType="phone-pad"
                    placeholder="10-digit mobile number"
                    placeholderTextColor="#94A3B8"
                    style={{ flex: 1, fontSize: 13, color: '#0F172A', paddingVertical: 8 }}
                  />
                </View>
              </View>
            </View>
          </>
        )}
      </ScrollView>

      {/* INLINE ERROR BANNER (Native Form Feedback) */}
      {errorMessage ? (
        <View style={styles.inlineErrorBanner}>
          <Icon source="alert-circle-outline" size={18} color="#EF4444" />
          <Text style={styles.inlineErrorBannerText}>{errorMessage}</Text>
        </View>
      ) : null}

      {/* FIXED STICKY BOTTOM ACTION BAR (Native Mobile UX) */}
      <View style={styles.fixedBottomNav}>
        {currentStep > 1 && (
          <TouchableOpacity
            style={styles.fixedBackBtn}
            onPress={() => {
              LayoutAnimation.configureNext(LayoutAnimation.Presets.easeInEaseOut);
        setCurrentStep((prev) => (prev - 1) as 1 | 2 | 3);
              scrollRef.current?.scrollTo({ y: 0, animated: false });
            }}
            activeOpacity={0.8}
          >
            <Text style={styles.fixedBackBtnText}>← Back</Text>
          </TouchableOpacity>
        )}

        <TouchableOpacity
          style={[
            styles.fixedPrimaryBtn,
            currentStep === 1 && { flex: 1 },
            isSubmitting && { opacity: 0.8 },
          ]}
          onPress={
            currentStep === 1
              ? handleNextStep1
              : currentStep === 2
              ? handleNextStep2
              : handlePublish
          }
          disabled={isSubmitting}
          activeOpacity={0.85}
        >
          {isSubmitting ? (
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8 }}>
              <ActivityIndicator size="small" color="#FFFFFF" />
              <Text style={styles.fixedPrimaryBtnText}>
                {uploadProgress || 'Posting Ad...'}
              </Text>
            </View>
          ) : (
            <Text style={styles.fixedPrimaryBtnText}>
              {currentStep === 1
                ? 'Next: Photos & Price ➔'
                : currentStep === 2
                ? 'Next: Location & Post ➔'
                : 'Post Ad Across India 🚀'}
            </Text>
          )}
        </TouchableOpacity>
      </View>

      {/* Interactive Map Modal */}
      <MapLocationModal
        visible={showMapModal}
        onClose={() => setShowMapModal(false)}
        initialLat={lat}
        initialLng={lng}
        initialState={finalState}
        initialDistrict={finalDistrict}
        initialArea={selectedArea}
        onSelectLocation={(data) => {
          setLat(data.lat);
          setLng(data.lng);
          setSelectedState(data.state);
          setSelectedDistrict(data.district);
          if (data.area) setSelectedArea(data.area);
        }}
      />

      {/* Searchable picker */}
      <BottomSheetModal
        visible={pickerModalType !== null}
        onClose={() => setPickerModalType(null)}
        height="85%"
      >
        <View style={styles.modalHeaderRow}>
          <Text style={styles.modalTitle}>
            {pickerModalType === 'brand' && 'Select Car Brand'}
            {pickerModalType === 'model' && `Select Model for ${finalBrand}`}
            {pickerModalType === 'finalCategory' && 'Select Part Category'}
            {pickerModalType === 'finalPartName' && `Select Part in ${finalCategory}`}
            {pickerModalType === 'state' && 'Select State'}
            {pickerModalType === 'district' && `Select District in ${finalState}`}
            {pickerModalType === 'carYear' && 'Select Manufacturing Year'}
            {pickerModalType === 'carVariant' && (finalModel ? `Select Variant for ${finalBrand} ${finalModel}` : finalBrand ? `Select Variant for ${finalBrand}` : 'Select Car Variant')}
          </Text>
          <TouchableOpacity onPress={() => setPickerModalType(null)}>
            <IconButton icon="close" size={20} iconColor="#0F172A" style={{ margin: 0 }} />
          </TouchableOpacity>
        </View>

        <View style={styles.modalSearchBox}>
          <IconButton icon="magnify" size={19} iconColor="#64748B" style={{ margin: 0 }} />
          <RNTextInput
            value={pickerSearchQuery}
            onChangeText={setPickerSearchQuery}
            placeholder={pickerModalType === 'carVariant' ? 'Search or type custom variant...' : 'Search...'}
            placeholderTextColor="#94A3B8"
            style={styles.modalSearchInput}
            autoFocus
          />
          {pickerSearchQuery ? (
            <TouchableOpacity onPress={() => setPickerSearchQuery('')}>
              <IconButton icon="close-circle" size={17} iconColor="#94A3B8" style={{ margin: 0 }} />
            </TouchableOpacity>
          ) : null}
        </View>

        <FlatList
          data={getModalItems()}
          keyExtractor={(item) => item}
          keyboardShouldPersistTaps="handled"
          contentContainerStyle={{ paddingBottom: 18 }}
          renderItem={({ item }) => {
            const isSelected =
              (pickerModalType === 'brand' && finalBrand === item) ||
              (pickerModalType === 'model' && finalModel === item) ||
              (pickerModalType === 'finalCategory' && finalCategory === item) ||
              (pickerModalType === 'finalPartName' && finalPartName === item) ||
              (pickerModalType === 'state' && finalState === item) ||
              (pickerModalType === 'district' && finalDistrict === item) ||
              (pickerModalType === 'carYear' && carYear === item) ||
              (pickerModalType === 'carVariant' && carVariant === item);

            return (
              <NativeButton
                style={[styles.modalItemRow, isSelected && styles.modalItemRowSelected]}
                onPress={() => {
                  if (pickerModalType === 'brand') handleBrandSelect(item);
                  else if (pickerModalType === 'model') handleModelSelect(item);
                  else if (pickerModalType === 'finalCategory') handleCategorySelect(item);
                  else if (pickerModalType === 'finalPartName') handlePartNameSelect(item);
                  else if (pickerModalType === 'state') handleStateSelect(item);
                  else if (pickerModalType === 'district') handleDistrictSelect(item);
                  else if (pickerModalType === 'carYear') {
                    setCarYear(item);
                    setPickerModalType(null);
                  }
                  else if (pickerModalType === 'carVariant') {
                    setCarVariant(item);
                    updateAutoTitle(finalBrand, finalModel, item, finalPartName);
                    setPickerModalType(null);
                  }
                }}
              >
                <View style={{ flexDirection: 'row', width: '100%', alignItems: 'center', justifyContent: 'space-between' }}>
                  <Text style={[styles.modalItemText, isSelected && styles.modalItemTextSelected]}>
                    {pickerModalType === 'finalCategory' ? translateDynamic(item) : item}
                  </Text>
                  {isSelected && (
                    <IconButton icon="check" size={19} iconColor="#0066FF" style={{ margin: 0 }} />
                  )}
                </View>
              </NativeButton>
            );
          }}
          ListEmptyComponent={() => (
            <View style={{ padding: 28, alignItems: 'center' }}>
              {pickerModalType === 'carVariant' && pickerSearchQuery.trim() ? (
                <TouchableOpacity
                  onPress={() => {
                    const custom = pickerSearchQuery.trim();
                    setCarVariant(custom);
                    updateAutoTitle(finalBrand, finalModel, custom, finalPartName);
                    setPickerModalType(null);
                  }}
                  style={{
                    paddingVertical: 10,
                    paddingHorizontal: 16,
                    backgroundColor: '#EFF6FF',
                    borderRadius: 8,
                    borderWidth: 0,
                    borderColor: '#BFDBFE',
                    alignItems: 'center',
                  }}
                >
                  <Text style={{ color: '#0066FF', fontWeight: '600', fontSize: 14 }}>
                    Use "{pickerSearchQuery.trim()}" as custom variant
                  </Text>
                </TouchableOpacity>
              ) : pickerModalType === 'finalPartName' && pickerSearchQuery.trim() ? (
                <TouchableOpacity
                  onPress={() => {
                    const custom = pickerSearchQuery.trim();
                    handlePartNameSelect(custom);
                  }}
                  style={{
                    paddingVertical: 10,
                    paddingHorizontal: 16,
                    backgroundColor: '#EFF6FF',
                    borderRadius: 8,
                    borderWidth: 0,
                    borderColor: '#BFDBFE',
                    alignItems: 'center',
                  }}
                >
                  <Text style={{ color: '#0066FF', fontWeight: '600', fontSize: 14 }}>
                    Use "{pickerSearchQuery.trim()}" as custom Part Name
                  </Text>
                </TouchableOpacity>
              ) : (
                <Text style={{ color: '#94A3B8', fontSize: 13 }}>No matching results found</Text>
              )}
            </View>
          )}
        />
      </BottomSheetModal>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({

  sectionIconCircle: {
    width: 36,
    height: 36,
    borderRadius: 18,
    backgroundColor: '#EFF6FF',
    alignItems: 'center',
    justifyContent: 'center',
    marginRight: 12,
  },
  counterTextRight: {
    fontSize: 12,
    color: '#94A3B8',
    textAlign: 'right',
    marginTop: 4,
  },
  sectionBadgeText: {
    fontSize: 12,
    fontWeight: '600',
    color: '#3B82F6',
  },

  root: {
    flex: 1,
    backgroundColor: '#F7F8FA',
  },
  nativeHeader: {
    height: 68,
    backgroundColor: '#0066FF',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 10,
  },
  headerBack: {
    width: 42,
    height: 42,
    alignItems: 'center',
    justifyContent: 'center',
  },
  headerCenter: {
    flex: 1,
    paddingLeft: 4,
  },
  nativeHeaderTitle: {
    color: '#FFFFFF',
    fontSize: 18,
    fontWeight: '800',
    letterSpacing: -0.2,
  },
  nativeHeaderSub: {
    color: '#BAE6FD',
    fontSize: 11,
    marginTop: 2,
  },
  helpIconButton: {
    padding: 6,
    alignItems: 'center',
    justifyContent: 'center',
  },
  stepBadgePill: {
    backgroundColor: 'rgba(255, 255, 255, 0.16)',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
  },
  stepBadgePillText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '800',
  },
  previewSummaryCard: {
    backgroundColor: '#EFF6FF',
    borderRadius: 14,
    padding: 12,
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#DBEAFE',
  },
  previewSummaryTop: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  previewSummaryThumb: {
    width: 52,
    height: 52,
    borderRadius: 10,
    backgroundColor: '#E2E8F0',
  },
  previewSummaryTitle: {
    fontSize: 13.5,
    fontWeight: '800',
    color: '#0F172A',
  },
  previewSummaryFitment: {
    fontSize: 11.5,
    color: '#64748B',
    marginTop: 2,
  },
  previewSummaryPrice: {
    fontSize: 14,
    fontWeight: '800',
    color: '#0066FF',
    marginTop: 3,
  },
  fixedBottomNav: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    backgroundColor: '#FFFFFF',
    borderTopWidth: 1,
    borderTopColor: '#E2E8F0',
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: Platform.OS === 'ios' ? 24 : 14,
    flexDirection: 'row',
    gap: 10,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: -3 },
    shadowOpacity: 0.08,
    shadowRadius: 6,
    elevation: 10,
    zIndex: 99,
  },
  fixedBackBtn: {
    height: 48,
    paddingHorizontal: 18,
    borderRadius: 12,
    backgroundColor: '#F1F5F9',
    alignItems: 'center',
    justifyContent: 'center',
  },
  fixedBackBtnText: {
    fontSize: 14,
    fontWeight: '700',
    color: '#475569',
  },
  fixedPrimaryBtn: {
    flex: 1,
    height: 48,
    borderRadius: 12,
    backgroundColor: '#FF6B00',
    alignItems: 'center',
    justifyContent: 'center',
    shadowColor: '#FF6B00',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 3,
  },
  fixedPrimaryBtnText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '800',
  },
  segmentProgressTrack: {
    flexDirection: 'row',
    gap: 6,
    paddingHorizontal: 16,
    paddingVertical: 10,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  segmentBar: { flex: 1, height: 4, borderRadius: 2 },
  segmentBarActive: { backgroundColor: '#0066FF' },
  segmentBarInactive: { backgroundColor: '#E2E8F0' },
  sectionHeaderIconBox: {
    width: 42,
    height: 42,
    borderRadius: 12,
    backgroundColor: '#EFF6FF',
    alignItems: 'center',
    justifyContent: 'center',
  },
  nativeSectionTitleLarge: { fontSize: 16, fontWeight: '800', color: '#0F172A' },
  nativeSectionSub: { fontSize: 12, color: '#64748B', marginTop: 2 },
  photoBoxCard: {
    flex: 1,
    height: 80,
    borderRadius: 12,
    borderWidth: 0,
    borderStyle: 'dashed',
    borderColor: '#CBD5E1',
    backgroundColor: '#F8FAFC',
    alignItems: 'center',
    justifyContent: 'center',
  },
  photoBoxText: { fontSize: 12, fontWeight: '700', color: '#0066FF', marginTop: 4 },
  conditionCardsRow: { flexDirection: 'row', gap: 12 },
  conditionCard: {
    flex: 1,
    padding: 14,
    borderRadius: 14,
    backgroundColor: '#FFFFFF',
    position: 'relative',
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.04,
    shadowRadius: 6,
    elevation: 2,
  },
  conditionCardActive: { backgroundColor: '#EFF6FF' },
  conditionIconBadge: { width: 36, height: 36, borderRadius: 10, backgroundColor: '#F1F5F9', alignItems: 'center', justifyContent: 'center', marginBottom: 8 },
  conditionCardTitle: { fontSize: 14, fontWeight: '700', color: '#0F172A' },
  conditionTextActive: { color: '#0066FF' },
  conditionCardSub: { fontSize: 11, color: '#64748B', marginTop: 2 },
  conditionCheckBadge: { position: 'absolute', top: 8, right: 8, width: 18, height: 18, borderRadius: 9, backgroundColor: '#0066FF', alignItems: 'center', justifyContent: 'center' },
  nextBigButton: {
    height: 50,
    backgroundColor: '#FF6B00',
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 8,
  },
  nextBigButtonText: { color: '#FFFFFF', fontSize: 15, fontWeight: '800' },
  buttonsTwoRow: { flexDirection: 'row', gap: 12, marginTop: 8 },
  backButtonOutline: {
    height: 50,
    paddingHorizontal: 24,
    borderRadius: 12,
    backgroundColor: '#F1F5F9',
    alignItems: 'center',
    justifyContent: 'center',
  },
  backButtonOutlineText: { fontSize: 14, fontWeight: '700', color: '#475569' },
  nextBigButtonFlex: {
    flex: 1,
    height: 50,
    backgroundColor: '#FF6B00',
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  publishOrangeButtonFlex: {
    flex: 1,
    height: 50,
    backgroundColor: '#FF6B00',
    borderRadius: 12,
    alignItems: 'center',
    justifyContent: 'center',
  },
  publishOrangeButtonText: { color: '#FFFFFF', fontSize: 15, fontWeight: '800' },
  priceBoxRow: {
    height: 52,
    borderRadius: 12,
    backgroundColor: '#F1F5F9',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
  },
  rupeeSymbol: { fontSize: 18, fontWeight: '800', color: '#0F172A', marginRight: 8 },
  priceTextInput: { flex: 1, fontSize: 16, fontWeight: '700', color: '#0F172A', paddingVertical: 0 },
  negotiableSwitchRow: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 14,
    paddingTop: 12,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
  },
  customToggleTrack: { width: 44, height: 24, borderRadius: 12, backgroundColor: '#CBD5E1', padding: 2 },
  customToggleActive: { backgroundColor: '#0066FF' },
  customToggleThumb: { width: 20, height: 20, borderRadius: 10, backgroundColor: '#FFFFFF' },
  customToggleThumbActive: { transform: [{ translateX: 20 }] },
  descriptionBox: {
    height: 110,
    borderRadius: 12,
    backgroundColor: '#F1F5F9',
    padding: 12,
    fontSize: 13,
    color: '#0F172A',
  },
  gpsButtonCard: {
    flex: 1,
    padding: 10,
    borderRadius: 12,
    backgroundColor: '#EFF6FF',
    flexDirection: 'row',
    alignItems: 'center',
  },
  saveDraftButton: {
    width: 42,
    height: 42,
    alignItems: 'center',
    justifyContent: 'center',
  },
  progressWrap: {
    backgroundColor: '#0B1220',
    paddingHorizontal: 18,
    paddingBottom: 12,
  },
  progressTrack: {
    height: 3,
    backgroundColor: '#263244',
    borderRadius: 3,
    overflow: 'hidden',
  },
  progressFill: {
    width: '24%',
    height: '100%',
    backgroundColor: '#FF7A00',
    borderRadius: 3,
  },
  progressLabel: {
    color: '#94A3B8',
    fontSize: 12,
    fontWeight: '600',
    marginTop: 6,
  },
  nativeScroll: {
    flex: 1,
  },
  nativeContent: {
    padding: 16,
    paddingBottom: 130,
  },
  nativeSection: {
    backgroundColor: '#FFFFFF',
    borderRadius: 18,
    padding: 15,
    marginBottom: 12,
    shadowColor: '#0F172A',
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.05,
    shadowRadius: 10,
    elevation: 2.5,
  },
  sectionTopRow: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
  },
  nativeSectionTitle: {
    color: '#0F172A',
    fontSize: 16,
    fontWeight: '800',
    letterSpacing: -0.15,
  },
  nativeSectionHint: {
    color: '#475569',
    fontSize: 12.5,
    marginTop: 3,
    lineHeight: 18,
  },
  countPill: {
    backgroundColor: '#F1F5F9',
    borderRadius: 20,
    paddingHorizontal: 9,
    paddingVertical: 5,
  },
  countPillText: {
    color: '#475569',
    fontSize: 12,
    fontWeight: '700',
  },
  photoEmpty: {
    marginTop: 14,
    borderRadius: 16,
    borderWidth: 0,
    borderStyle: 'dashed',
    borderColor: '#BFD0E8',
    backgroundColor: '#F8FBFF',
    padding: 18,
    alignItems: 'center',
  },
  photoEmptyIcon: {
    width: 54,
    height: 54,
    borderRadius: 18,
    backgroundColor: '#EAF2FF',
    alignItems: 'center',
    justifyContent: 'center',
  },
  photoEmptyTitle: {
    color: '#0F172A',
    fontSize: 14.5,
    fontWeight: '700',
    marginTop: 9,
  },
  photoEmptyHint: {
    color: '#475569',
    fontSize: 12,
    marginTop: 3,
  },
  photoActionRow: {
    flexDirection: 'row',
    width: '100%',
    gap: 9,
    marginTop: 14,
  },
  photoPrimary: {
    flex: 1,
    height: 44,
    borderRadius: 12,
    backgroundColor: '#0066FF',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  photoPrimaryText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '700',
    marginLeft: 4,
  },
  photoSecondary: {
    flex: 1,
    height: 43,
    borderRadius: 12,
    backgroundColor: '#FFFFFF',
    borderWidth: 0,
    borderColor: '#D7DDE6',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  photoSecondaryText: {
    color: '#0F172A',
    fontSize: 12,
    fontWeight: '800',
    marginLeft: 4,
  },
  photoGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
    marginTop: 14,
  },
  photoTile: {
    width: (width - 62) / 3,
    height: (width - 62) / 3,
    borderRadius: 13,
    overflow: 'hidden',
    backgroundColor: '#E5E7EB',
    position: 'relative',
  },
  photoImage: {
    width: '100%',
    height: '100%',
  },
  photoAddTile: {
    width: (width - 62) / 3,
    height: (width - 62) / 3,
    borderRadius: 13,
    borderWidth: 0,
    borderStyle: 'dashed',
    borderColor: '#B8C5D8',
    backgroundColor: '#F8FAFC',
    alignItems: 'center',
    justifyContent: 'center',
  },
  photoAddText: {
    color: '#0066FF',
    fontSize: 11.5,
    fontWeight: '700',
    marginTop: -3,
  },
  coverPill: {
    position: 'absolute',
    left: 6,
    bottom: 6,
    backgroundColor: '#0B1220',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
  },
  coverPillText: {
    color: '#FFFFFF',
    fontSize: 11,
    fontWeight: '700',
  },
  photoDelete: {
    position: 'absolute',
    right: 4,
    top: 4,
    width: 25,
    height: 25,
    borderRadius: 13,
    backgroundColor: 'rgba(15,23,42,0.82)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  quickCamera: {
    marginTop: 9,
    height: 38,
    borderRadius: 10,
    backgroundColor: '#F1F5F9',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  quickCameraText: {
    color: '#0066FF',
    fontSize: 12,
    fontWeight: '700',
    marginLeft: 2,
  },
  aiButton: {
    height: 43,
    borderRadius: 12,
    backgroundColor: '#FF7A00',
    marginTop: 12,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  aiIcon: {
    color: '#FFFFFF',
    fontSize: 17,
    fontWeight: '900',
    marginRight: 6,
  },
  aiButtonText: {
    color: '#FFFFFF',
    fontSize: 11.5,
    fontWeight: '900',
  },
  segmentRow: {
    flexDirection: 'row',
    backgroundColor: '#F1F5F9',
    borderRadius: 12,
    padding: 3,
    marginTop: 14,
  },
  segmentButton: {
    flex: 1,
    height: 38,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 9,
  },
  segmentButtonActive: {
    backgroundColor: '#0B1220',
  },
  segmentText: {
    color: '#64748B',
    fontSize: 11,
    fontWeight: '800',
  },
  segmentTextActive: {
    color: '#FFFFFF',
  },
  nativeField: {
    marginTop: 13,
  },
  fieldLabel: {
    color: '#475569',
    fontSize: 12.5,
    fontWeight: '700',
    letterSpacing: 0.2,
    marginBottom: 6,
  },
  nativePicker: {
    minHeight: 50,
    borderRadius: 13,
    borderWidth: 0,
    borderColor: '#DDE2EA',
    backgroundColor: '#FFFFFF',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 9,
  },
  nativePickerDisabled: {
    backgroundColor: '#F3F4F6',
    borderColor: '#E5E7EB',
  },
  fieldIconCircle: {
    width: 33,
    height: 33,
    borderRadius: 10,
    backgroundColor: '#F1F5F9',
    alignItems: 'center',
    justifyContent: 'center',
  },
  pickerValue: {
    flex: 1,
    color: '#0F172A',
    fontSize: 14.5,
    fontWeight: '600',
    marginLeft: 8,
  },
  pickerPlaceholder: {
    color: '#94A3B8',
    fontWeight: '400',
  },
  nativeTextInput: {
    minHeight: 52,
    borderRadius: 14,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    backgroundColor: '#F8FAFC',
    paddingHorizontal: 16,
    paddingVertical: 12,
    color: '#0F172A',
    fontSize: 15,
    fontWeight: '500',
  },
  fieldError: {
    borderColor: '#EF4444',
    backgroundColor: '#FFF7F7',
  },
  twoFieldRow: {
    flexDirection: 'row',
    gap: 10,
    marginTop: 13,
  },
  halfField: {
    flex: 1,
  },
  priceBox: {
    height: 62,
    borderRadius: 15,
    borderWidth: 0,
    borderColor: '#CBD5E1',
    backgroundColor: '#FAFBFC',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 15,
    marginTop: 14,
  },
  priceSymbol: {
    color: '#0F172A',
    fontSize: 25,
    fontWeight: '900',
  },
  priceInput: {
    flex: 1,
    color: '#0F172A',
    fontSize: 21,
    fontWeight: '800',
    marginLeft: 9,
    paddingVertical: 0,
  },
  conditionSegmentContainer: {
    flexDirection: 'row',
    backgroundColor: '#EEF2F6',
    borderRadius: 14,
    padding: 4,
    marginTop: 14,
    marginBottom: 4,
  },
  conditionTab: {
    flex: 1,
    paddingVertical: 12,
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 11,
  },
  conditionTabActive: {
    backgroundColor: '#0B1426',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.12,
    shadowRadius: 2,
    elevation: 2,
  },
  conditionTabActiveNew: {
    backgroundColor: '#059669',
    shadowColor: '#059669',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.25,
    shadowRadius: 4,
    elevation: 3,
  },
  conditionTabText: {
    color: '#64748B',
    fontSize: 14,
    fontWeight: '700',
  },
  conditionTabTextActive: {
    color: '#FFFFFF',
    fontWeight: '800',
  },
  descriptionInput: {
    minHeight: 120,
    borderRadius: 13,
    borderWidth: 0,
    borderColor: '#DDE2EA',
    backgroundColor: '#FFFFFF',
    color: '#0F172A',
    fontSize: 14.5,
    lineHeight: 22,
    paddingHorizontal: 13,
    paddingTop: 12,
    marginTop: 13,
  },
  charCount: {
    color: '#94A3B8',
    fontSize: 12,
    fontWeight: '500',
    marginTop: 2,
  },
  gpsButton: {
    height: 32,
    paddingHorizontal: 8,
    borderRadius: 9,
    backgroundColor: '#EFF6FF',
    flexDirection: 'row',
    alignItems: 'center',
  },
  gpsText: {
    color: '#0066FF',
    fontSize: 12,
    fontWeight: '700',
    marginLeft: 2,
  },
  mapButton: {
    minHeight: 60,
    marginTop: 12,
    borderRadius: 13,
    backgroundColor: '#F5F9FF',
    borderWidth: 0,
    borderColor: '#D7E5FF',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 8,
  },
  mapButtonTitle: {
    color: '#0066FF',
    fontSize: 13,
    fontWeight: '700',
  },
  mapButtonSub: {
    color: '#64748B',
    fontSize: 12,
    marginTop: 2,
  },
  safetyRow: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 4,
    paddingVertical: 5,
    marginBottom: 8,
  },
  safetyText: {
    flex: 1,
    color: '#64748B',
    fontSize: 12,
    lineHeight: 17,
    marginLeft: 3,
  },
  bottomBar: {
    backgroundColor: '#FFFFFF',
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
    paddingHorizontal: 14,
    paddingTop: 10,
    paddingBottom: Platform.OS === 'ios' ? 22 : 12,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  bottomHint: {
    flex: 1,
  },
  bottomHintTitle: {
    color: '#0F172A',
    fontSize: 13,
    fontWeight: '800',
  },
  bottomHintSub: {
    color: '#64748B',
    fontSize: 11.5,
    marginTop: 2,
  },
  publishButton: {
    minWidth: 124,
    height: 48,
    borderRadius: 13,
    backgroundColor: '#FF7A00',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  publishButtonText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '900',
  },
  errorBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFF1F2',
    borderWidth: 0,
    borderColor: '#FECDD3',
    borderRadius: 13,
    padding: 9,
    marginBottom: 12,
  },
  errorText: {
    flex: 1,
    color: '#DC2626',
    fontSize: 12,
    fontWeight: '600',
  },
  modalBackdrop: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'flex-end',
  },
  modalContainer: {
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    maxHeight: '82%',
    minHeight: '45%',
    paddingBottom: 10,
  },
  modalHandle: {
    width: 38,
    height: 4,
    borderRadius: 3,
    backgroundColor: '#D1D5DB',
    alignSelf: 'center',
    marginTop: 9,
    marginBottom: 3,
  },
  modalHeaderRow: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    paddingTop: 9,
    paddingBottom: 8,
  },
  modalTitle: {
    flex: 1,
    color: '#111827',
    fontSize: 15,
    fontWeight: '900',
  },
  modalSearchBox: {
    height: 44,
    marginHorizontal: 14,
    marginBottom: 8,
    borderRadius: 11,
    backgroundColor: '#F1F5F9',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 5,
  },
  modalSearchInput: {
    flex: 1,
    color: '#0F172A',
    fontSize: 14.5,
    paddingVertical: 5,
  },
  modalItemRow: {
    minHeight: 48,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 16,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  modalItemRowSelected: {
    backgroundColor: '#EFF6FF',
  },
  modalItemText: {
    flex: 1,
    color: '#475569',
    fontSize: 14.5,
    fontWeight: '500',
  },
  modalItemTextSelected: {
    color: '#0066FF',
    fontWeight: '700',
  },
  successContainer: {
    flex: 1,
    backgroundColor: '#0B1220',
    justifyContent: 'center',
    alignItems: 'center',
    padding: 24,
  },
  successBadge: {
    width: 72,
    height: 72,
    borderRadius: 22,
    backgroundColor: 'rgba(16,185,129,0.15)',
    borderWidth: 0,
    borderColor: 'rgba(16,185,129,0.4)',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 16,
  },
  successTitle: {
    fontSize: 18,
    fontWeight: '900',
    color: '#FFFFFF',
    textAlign: 'center',
  },
  successSub: {
    fontSize: 12,
    color: '#94A3B8',
    textAlign: 'center',
    marginTop: 8,
    lineHeight: 18,
    maxWidth: 280,
  },
  successRedirect: {
    color: '#60A5FA',
    fontSize: 11,
    fontWeight: '700',
    marginTop: 8,
  },
  limitContainer: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  limitContent: {
    padding: 20,
    alignItems: 'center',
    justifyContent: 'center',
  },
  limitIconBox: {
    width: 64,
    height: 64,
    borderRadius: 20,
    backgroundColor: '#FEF3C7',
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 12,
  },
  limitTitle: {
    fontSize: 16,
    fontWeight: '900',
    color: '#0F172A',
    textAlign: 'center',
  },
  limitSub: {
    fontSize: 12,
    color: '#64748B',
    textAlign: 'center',
    marginTop: 6,
    lineHeight: 18,
  },
  activeAdsCard: {
    backgroundColor: '#FFFFFF',
    borderRadius: 14,
    padding: 12,
    width: '100%',
    marginTop: 16,
    borderWidth: 0,
    borderColor: '#E2E8F0',
  },
  activeAdsHeading: {
    fontSize: 11,
    fontWeight: '800',
    color: '#64748B',
    marginBottom: 8,
    textTransform: 'uppercase',
  },
  adItemRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F8FAFC',
    padding: 8,
    borderRadius: 10,
    marginBottom: 6,
  },
  adItemThumb: {
    width: 36,
    height: 36,
    borderRadius: 8,
    backgroundColor: '#E2E8F0',
  },
  adItemTitle: {
    fontSize: 12,
    fontWeight: '700',
    color: '#0F172A',
  },
  adItemPrice: {
    fontSize: 11,
    fontWeight: '800',
    color: '#0066FF',
  },
  inlineErrorBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FEF2F2',
    borderWidth: 1,
    borderColor: '#FCA5A5',
    paddingHorizontal: 16,
    paddingVertical: 10,
    marginHorizontal: 16,
    marginBottom: 8,
    borderRadius: 12,
    gap: 8,
  },
  inlineErrorBannerText: {
    color: '#991B1B',
    fontSize: 13,
    fontWeight: '600',
    flex: 1,
  },
});
