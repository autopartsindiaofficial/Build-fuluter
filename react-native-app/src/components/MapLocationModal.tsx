import React, { useState, useEffect } from 'react';
import {
  Modal,
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  ScrollView,
  TextInput as RNTextInput,
  ActivityIndicator,
  useWindowDimensions,
  Platform,
  Alert,
} from 'react-native';
import { IconButton, Button, Chip, Divider, Surface } from 'react-native-paper';
import { 
  getCurrentLocation, 
  reverseGeocodeLatLng, 
  getApproxCoordinates, 
  searchLocationsOSM,
  LatLng,
  GeocodedLocation
} from '../services/location';
import { INDIAN_STATES_AND_DISTRICTS, POPULAR_CITIES } from '../data/indianLocations';
import GMap from './GMap';

interface MapLocationModalProps {
  visible: boolean;
  onClose: () => void;
  onSelectLocation: (locationData: {
    lat: number;
    lng: number;
    state: string;
    district: string;
    area: string;
    locationText: string;
  }) => void;
  initialLat?: number;
  initialLng?: number;
  initialState?: string;
  initialDistrict?: string;
  initialArea?: string;
}

export const MapLocationModal: React.FC<MapLocationModalProps> = ({
  visible,
  onClose,
  onSelectLocation,
  initialLat,
  initialLng,
  initialState = '',
  initialDistrict = '',
  initialArea = '',
}) => {
  const { width, height } = useWindowDimensions();
  const [selectedLat, setSelectedLat] = useState<number>(initialLat || 19.0760);
  const [selectedLng, setSelectedLng] = useState<number>(initialLng || 72.8777);
  const [state, setState] = useState<string>(initialState);
  const [district, setDistrict] = useState<string>(initialDistrict);
  const [area, setArea] = useState<string>(initialArea);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [searchResults, setSearchResults] = useState<any[]>([]);
  const [isSearching, setIsSearching] = useState(false);
  const [isDetectingGPS, setIsDetectingGPS] = useState(false);
  const [activeTab, setActiveTab] = useState<'map' | 'states'>('map');
  const [selectedStateForDistricts, setSelectedStateForDistricts] = useState<string>(initialState || 'Maharashtra');

  useEffect(() => {
    if (initialLat && initialLng && initialLat !== 0 && initialLng !== 0) {
      setSelectedLat(initialLat);
      setSelectedLng(initialLng);
    }
    if (initialState) setState(initialState);
    if (initialDistrict) setDistrict(initialDistrict);
    if (initialArea) setArea(initialArea);
  }, [initialLat, initialLng, initialState, initialDistrict, initialArea, visible]);

  // Handle GPS Auto Detect
  const handleGPSDetect = async () => {
    setIsDetectingGPS(true);
    try {
      const coords = await getCurrentLocation();
      if (coords) {
        setSelectedLat(coords.latitude);
        setSelectedLng(coords.longitude);

        const geocoded: GeocodedLocation = await reverseGeocodeLatLng(coords.latitude, coords.longitude);
        if (geocoded.state) setState(geocoded.state);
        if (geocoded.district) setDistrict(geocoded.district);
        if (geocoded.area) setArea(geocoded.area);
        if (geocoded.state) setSelectedStateForDistricts(geocoded.state);
      }
    } catch (e) {
      console.warn('GPS detection notice:', e);
      Alert.alert('Location Notice', 'Could not detect your current location. Please choose your city or tap on the map.');
    } finally {
      setIsDetectingGPS(false);
    }
  };

  // Search places via OSM
  const handleSearch = async (text: string) => {
    setSearchQuery(text);
    if (text.trim().length >= 2) {
      setIsSearching(true);
      try {
        const results = await searchLocationsOSM(text);
        setSearchResults(results);
      } catch (err) {
        console.warn('Search location error:', err);
      } finally {
        setIsSearching(false);
      }
    } else {
      setSearchResults([]);
    }
  };

  const handleSelectSearchResult = (item: any) => {
    setSelectedLat(item.latitude);
    setSelectedLng(item.longitude);
    if (item.state) setState(item.state);
    if (item.city) setDistrict(item.city);
    setSearchQuery('');
    setSearchResults([]);
  };

  const handleSelectDistrict = (selectedDistrict: string, stateName: string) => {
    setDistrict(selectedDistrict);
    setState(stateName);
    const coords = getApproxCoordinates(stateName, selectedDistrict);
    setSelectedLat(coords.lat);
    setSelectedLng(coords.lng);
    setActiveTab('map');
  };

  const handleConfirm = () => {
    const locText = area && district ? `${area}, ${district}` : district && state ? `${district}, ${state}` : district || state || 'India';
    onSelectLocation({
      lat: selectedLat,
      lng: selectedLng,
      state: state || 'Maharashtra',
      district: district || 'Mumbai',
      area: area || '',
      locationText: locText,
    });
    onClose();
  };

  const currentDistricts = INDIAN_STATES_AND_DISTRICTS.find(
    (s) => s.state.toLowerCase() === selectedStateForDistricts.toLowerCase()
  )?.districts || [];

  return (
    <Modal visible={visible} animationType="slide" transparent onRequestClose={onClose}>
      <View style={styles.overlay}>
        <Surface style={styles.container} elevation={5}>
          {/* Header */}
          <View style={styles.header}>
            <View style={styles.headerTitleRow}>
              <IconButton icon="map-marker-radius" size={22} iconColor="#0066FF" style={styles.headerIcon} />
              <View>
                <Text style={styles.title}>Select Location</Text>
                <Text style={styles.subtitle}>Set your shop / spare part location</Text>
              </View>
            </View>
            <TouchableOpacity onPress={onClose} style={styles.closeBtn}>
              <IconButton icon="close" size={20} iconColor="#64748B" />
            </TouchableOpacity>
          </View>

          {/* Tab Switcher */}
          <View style={styles.tabBar}>
            <TouchableOpacity
              style={[styles.tabItem, activeTab === 'map' && styles.activeTabItem]}
              onPress={() => setActiveTab('map')}
            >
              <IconButton 
                icon="map-outline" 
                size={18} 
                iconColor={activeTab === 'map' ? '#0066FF' : '#64748B'} 
                style={styles.tabIcon}
              />
              <Text style={[styles.tabText, activeTab === 'map' && styles.activeTabText]}>
                Map & GPS
              </Text>
            </TouchableOpacity>

            <TouchableOpacity
              style={[styles.tabItem, activeTab === 'states' && styles.activeTabItem]}
              onPress={() => setActiveTab('states')}
            >
              <IconButton 
                icon="city-variant-outline" 
                size={18} 
                iconColor={activeTab === 'states' ? '#0066FF' : '#64748B'} 
                style={styles.tabIcon}
              />
              <Text style={[styles.tabText, activeTab === 'states' && styles.activeTabText]}>
                States & Districts
              </Text>
            </TouchableOpacity>
          </View>

          {activeTab === 'map' ? (
            <ScrollView style={styles.scrollBody} contentContainerStyle={{ paddingBottom: 20 }}>
              {/* Search Location Input */}
              <View style={styles.searchBoxWrapper}>
                <View style={styles.searchBox}>
                  <IconButton icon="magnify" size={18} iconColor="#64748B" style={styles.searchIcon} />
                  <RNTextInput
                    value={searchQuery}
                    onChangeText={handleSearch}
                    placeholder="Search city, town, locality..."
                    placeholderTextColor="#94A3B8"
                    style={styles.searchInput}
                  />
                  {searchQuery ? (
                    <TouchableOpacity onPress={() => setSearchQuery('')}>
                      <IconButton icon="close-circle" size={16} iconColor="#94A3B8" />
                    </TouchableOpacity>
                  ) : null}
                </View>

                {/* Search Auto-complete Suggestions */}
                {searchResults.length > 0 && (
                  <View style={styles.suggestionsContainer}>
                    {searchResults.map((item, idx) => (
                      <TouchableOpacity
                        key={idx}
                        style={styles.suggestionItem}
                        onPress={() => handleSelectSearchResult(item)}
                      >
                        <IconButton icon="map-marker" size={16} iconColor="#0066FF" style={{ margin: 0 }} />
                        <Text style={styles.suggestionText} numberOfLines={1}>
                          {item.displayName}
                        </Text>
                      </TouchableOpacity>
                    ))}
                  </View>
                )}
              </View>

              {/* Quick GPS auto-detect trigger button */}
              <View style={styles.gpsBanner}>
                <View style={{ flex: 1 }}>
                  <Text style={styles.gpsBannerTitle}>Current GPS Detection</Text>
                  <Text style={styles.gpsBannerSub}>
                    Auto-detect latitude, longitude & district instantly
                  </Text>
                </View>
                <TouchableOpacity
                  style={styles.gpsButton}
                  onPress={handleGPSDetect}
                  disabled={isDetectingGPS}
                  activeOpacity={0.8}
                >
                  {isDetectingGPS ? (
                    <ActivityIndicator size={16} color="#FFFFFF" />
                  ) : (
                    <>
                      <IconButton icon="crosshairs-gps" size={16} iconColor="#FFFFFF" style={{ margin: 0 }} />
                      <Text style={styles.gpsButtonText}>My GPS</Text>
                    </>
                  )}
                </TouchableOpacity>
              </View>

              {/* Map Preview */}
              <View style={styles.mapCard}>
                <GMap
                  latitude={selectedLat}
                  longitude={selectedLng}
                  title={`${district || state || 'Selected'} Location`}
                  interactive={true}
                  height={180}
                  onLocationSelect={(coords) => {
                    setSelectedLat(coords.latitude);
                    setSelectedLng(coords.longitude);
                    reverseGeocodeLatLng(coords.latitude, coords.longitude).then((geo) => {
                      if (geo.state) setState(geo.state);
                      if (geo.district) setDistrict(geo.district);
                      if (geo.area) setArea(geo.area);
                    });
                  }}
                  style={{ borderRadius: 14 }}
                />
              </View>

              {/* Manual Area / Locality Input Field */}
              <View style={styles.formSection}>
                <Text style={styles.fieldLabel}>Locality / Area Name (Optional)</Text>
                <RNTextInput
                  value={area}
                  onChangeText={setArea}
                  placeholder="e.g. Andheri East, T. Nagar, Gandhipuram"
                  placeholderTextColor="#94A3B8"
                  style={styles.fieldInput}
                />
              </View>

              {/* Resolved Location Summary */}
              <View style={styles.resolvedCard}>
                <IconButton icon="check-circle" size={20} iconColor="#10B981" style={{ margin: 0 }} />
                <View style={{ flex: 1, marginLeft: 6 }}>
                  <Text style={styles.resolvedTitle}>
                    {district || 'Mumbai'}, {state || 'Maharashtra'}
                  </Text>
                  <Text style={styles.resolvedCoords}>
                    Coordinates: {selectedLat.toFixed(4)}° N, {selectedLng.toFixed(4)}° E
                  </Text>
                </View>
              </View>
            </ScrollView>
          ) : (
            <View style={styles.statesContainer}>
              {/* State & District Selector view */}
              <View style={styles.statesColumn}>
                <Text style={styles.columnHeader}>Select State</Text>
                <ScrollView style={styles.columnList}>
                  {INDIAN_STATES_AND_DISTRICTS.map((s) => (
                    <TouchableOpacity
                      key={s.state}
                      style={[
                        styles.stateItem,
                        selectedStateForDistricts === s.state && styles.activeStateItem,
                      ]}
                      onPress={() => setSelectedStateForDistricts(s.state)}
                    >
                      <Text
                        style={[
                          styles.stateText,
                          selectedStateForDistricts === s.state && styles.activeStateText,
                        ]}
                      >
                        {s.state}
                      </Text>
                    </TouchableOpacity>
                  ))}
                </ScrollView>
              </View>

              <View style={styles.districtsColumn}>
                <Text style={styles.columnHeader}>{selectedStateForDistricts} Districts</Text>
                <ScrollView style={styles.columnList}>
                  {currentDistricts.map((d) => (
                    <TouchableOpacity
                      key={d}
                      style={[styles.districtItem, district === d && styles.activeDistrictItem]}
                      onPress={() => handleSelectDistrict(d, selectedStateForDistricts)}
                    >
                      <Text
                        style={[
                          styles.districtText,
                          district === d && styles.activeDistrictText,
                        ]}
                      >
                        {d}
                      </Text>
                      {district === d && (
                        <IconButton icon="check" size={16} iconColor="#0066FF" style={{ margin: 0 }} />
                      )}
                    </TouchableOpacity>
                  ))}
                </ScrollView>
              </View>
            </View>
          )}

          {/* Footer Actions */}
          <View style={styles.footer}>
            <Button
              mode="outlined"
              onPress={onClose}
              style={styles.cancelBtn}
              textColor="#64748B"
            >
              Cancel
            </Button>
            <Button
              mode="contained"
              onPress={handleConfirm}
              style={styles.confirmBtn}
              buttonColor="#0066FF"
              textColor="#FFFFFF"
              icon="check"
            >
              Confirm Location
            </Button>
          </View>
        </Surface>
      </View>
    </Modal>
  );
};

export default MapLocationModal;

const styles = StyleSheet.create({
  overlay: {
    flex: 1,
    backgroundColor: 'rgba(15, 23, 42, 0.75)',
    justifyContent: 'flex-end',
  },
  container: {
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 24,
    borderTopRightRadius: 24,
    maxHeight: '88%',
    minHeight: '65%',
    overflow: 'hidden',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 18,
    paddingTop: 16,
    paddingBottom: 12,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  headerTitleRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  headerIcon: {
    margin: 0,
    marginRight: 6,
  },
  title: {
    fontSize: 17,
    fontWeight: '800',
    color: '#0F172A',
  },
  subtitle: {
    fontSize: 12,
    color: '#64748B',
    marginTop: 1,
  },
  closeBtn: {
    padding: 4,
  },
  tabBar: {
    flexDirection: 'row',
    backgroundColor: '#F8FAFC',
    borderBottomWidth: 1,
    borderBottomColor: '#E2E8F0',
    paddingHorizontal: 12,
  },
  tabItem: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 10,
    borderBottomWidth: 2,
    borderBottomColor: 'transparent',
  },
  activeTabItem: {
    borderBottomColor: '#0066FF',
  },
  tabIcon: {
    margin: 0,
    marginRight: 4,
  },
  tabText: {
    fontSize: 13,
    fontWeight: '600',
    color: '#64748B',
  },
  activeTabText: {
    color: '#0066FF',
    fontWeight: '800',
  },
  scrollBody: {
    padding: 16,
  },
  searchBoxWrapper: {
    position: 'relative',
    zIndex: 30,
    marginBottom: 12,
  },
  searchBox: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F1F5F9',
    borderRadius: 12,
    paddingHorizontal: 10,
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  searchIcon: {
    margin: 0,
    marginRight: 4,
  },
  searchInput: {
    flex: 1,
    height: 42,
    color: '#0F172A',
    fontSize: 14,
  },
  suggestionsContainer: {
    position: 'absolute',
    top: 46,
    left: 0,
    right: 0,
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    elevation: 6,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 3 },
    shadowOpacity: 0.15,
    shadowRadius: 6,
    borderWidth: 1,
    borderColor: '#E2E8F0',
    zIndex: 40,
  },
  suggestionItem: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  suggestionText: {
    fontSize: 13,
    color: '#0F172A',
    marginLeft: 6,
    flex: 1,
  },
  gpsBanner: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#EFF6FF',
    borderRadius: 14,
    padding: 12,
    marginBottom: 14,
    borderWidth: 1,
    borderColor: '#BFDBFE',
  },
  gpsBannerTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: '#1E40AF',
  },
  gpsBannerSub: {
    fontSize: 11,
    color: '#3B82F6',
    marginTop: 2,
  },
  gpsButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#0066FF',
    paddingHorizontal: 12,
    paddingVertical: 7,
    borderRadius: 20,
    elevation: 2,
  },
  gpsButtonText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '800',
    marginLeft: 2,
  },
  mapCard: {
    marginBottom: 14,
    borderRadius: 14,
    overflow: 'hidden',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  formSection: {
    marginBottom: 14,
  },
  fieldLabel: {
    fontSize: 12,
    fontWeight: '700',
    color: '#475569',
    marginBottom: 6,
  },
  fieldInput: {
    backgroundColor: '#F8FAFC',
    borderWidth: 1,
    borderColor: '#CBD5E1',
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 10,
    fontSize: 14,
    color: '#0F172A',
  },
  resolvedCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#ECFDF5',
    padding: 12,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#A7F3D0',
  },
  resolvedTitle: {
    fontSize: 13,
    fontWeight: '800',
    color: '#065F46',
  },
  resolvedCoords: {
    fontSize: 11,
    color: '#047857',
    marginTop: 2,
    fontFamily: Platform.OS === 'ios' ? 'Courier' : 'monospace',
  },
  statesContainer: {
    flex: 1,
    flexDirection: 'row',
    minHeight: 350,
  },
  statesColumn: {
    flex: 1,
    borderRightWidth: 1,
    borderRightColor: '#E2E8F0',
    backgroundColor: '#F8FAFC',
  },
  districtsColumn: {
    flex: 1.2,
    backgroundColor: '#FFFFFF',
  },
  columnHeader: {
    fontSize: 12,
    fontWeight: '800',
    color: '#64748B',
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: '#F1F5F9',
    textTransform: 'uppercase',
  },
  columnList: {
    flex: 1,
  },
  stateItem: {
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#F1F5F9',
  },
  activeStateItem: {
    backgroundColor: '#EFF6FF',
    borderLeftWidth: 3,
    borderLeftColor: '#0066FF',
  },
  stateText: {
    fontSize: 13,
    color: '#334155',
  },
  activeStateText: {
    fontWeight: '800',
    color: '#0066FF',
  },
  districtItem: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 12,
    paddingVertical: 10,
    borderBottomWidth: 1,
    borderBottomColor: '#F8FAFC',
  },
  activeDistrictItem: {
    backgroundColor: '#EFF6FF',
  },
  districtText: {
    fontSize: 13,
    color: '#0F172A',
  },
  activeDistrictText: {
    fontWeight: '800',
    color: '#0066FF',
  },
  footer: {
    flexDirection: 'row',
    gap: 12,
    paddingHorizontal: 16,
    paddingVertical: 12,
    borderTopWidth: 1,
    borderTopColor: '#E2E8F0',
    backgroundColor: '#FFFFFF',
  },
  cancelBtn: {
    flex: 1,
    borderRadius: 12,
  },
  confirmBtn: {
    flex: 1.6,
    borderRadius: 12,
  },
});
