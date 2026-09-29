import React, { useState, useEffect, useRef } from 'react';
import { View, StyleSheet, Platform, TouchableOpacity, Alert, ActivityIndicator } from 'react-native';
import { Text, IconButton } from 'react-native-paper';
import { WebView } from 'react-native-webview';
import { 
  getCurrentLocation, 
  reverseGeocodeLatLng, 
  openLocationInExternalMaps, 
  getApproxCoordinates,
  LocationCoords
} from '../services/location';

interface GMapProps {
  lat?: number;
  lng?: number;
  latitude?: number;
  longitude?: number;
  state?: string;
  district?: string;
  title?: string;
  zoom?: number;
  interactive?: boolean;
  onLocationSelect?: (coords: LocationCoords) => void;
  style?: any;
  height?: number;
  showDetectBtn?: boolean;
}

const GMap: React.FC<GMapProps> = ({
  lat,
  lng,
  latitude,
  longitude,
  state,
  district,
  title = 'Spare Part Location',
  zoom = 14,
  interactive = false,
  onLocationSelect,
  style,
  height = 150,
  showDetectBtn = true,
}) => {
  const resolvedLat = lat ?? latitude ?? (state || district ? getApproxCoordinates(state, district).lat : 19.0760);
  const resolvedLng = lng ?? longitude ?? (state || district ? getApproxCoordinates(state, district).lng : 72.8777);

  const [currentLat, setCurrentLat] = useState<number>(resolvedLat);
  const [currentLng, setCurrentLng] = useState<number>(resolvedLng);
  const [address, setAddress] = useState<string>('');
  const [loading, setLoading] = useState(false);
  const webViewRef = useRef<WebView>(null);

  useEffect(() => {
    const nextLat = lat ?? latitude ?? (state || district ? getApproxCoordinates(state, district).lat : 19.0760);
    const nextLng = lng ?? longitude ?? (state || district ? getApproxCoordinates(state, district).lng : 72.8777);
    setCurrentLat(nextLat);
    setCurrentLng(nextLng);
    loadAddress(nextLat, nextLng);
    
    // Update map if webview is loaded
    updateMapLocation(nextLat, nextLng);
  }, [lat, lng, latitude, longitude, state, district]);

  const loadAddress = async (la: number, lo: number) => {
    try {
      const geo = await reverseGeocodeLatLng(la, lo);
      if (geo?.formattedAddress) {
        setAddress(geo.formattedAddress);
      } else if (geo?.district) {
        setAddress(`${geo.district}, ${geo.state}`);
      }
    } catch (err) {
      console.warn('[GMap] Reverse geocode notice:', err);
    }
  };

  const updateMapLocation = (la: number, lo: number) => {
    if (webViewRef.current) {
      webViewRef.current.injectJavaScript(`
        if (typeof map !== 'undefined' && typeof marker !== 'undefined') {
          var newLatLng = new L.LatLng(${la}, ${lo});
          marker.setLatLng(newLatLng);
          map.setView(newLatLng, ${zoom});
        }
        true;
      `);
    }
  };

  const handleOpenGoogleMaps = () => {
    openLocationInExternalMaps(currentLat, currentLng, title);
  };

  const handleDetectGPS = async () => {
    setLoading(true);
    try {
      const coords = await getCurrentLocation();
      if (coords) {
        setCurrentLat(coords.latitude);
        setCurrentLng(coords.longitude);
        loadAddress(coords.latitude, coords.longitude);
        updateMapLocation(coords.latitude, coords.longitude);
        if (onLocationSelect) {
          onLocationSelect(coords);
        }
      }
    } catch (e: any) {
      Alert.alert('GPS Location', 'Unable to retrieve location. Please check device GPS permissions.');
    } finally {
      setLoading(false);
    }
  };

  const mapHtml = `
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no" />
      <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css" />
      <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
      <style>
        body { padding: 0; margin: 0; background-color: #F1F5F9; }
        #map { width: 100vw; height: 100vh; }
        
        /* Custom Marker */
        .custom-marker {
          display: flex;
          align-items: center;
          justify-content: center;
        }
        .marker-dot {
          width: 16px;
          height: 16px;
          background-color: #0066FF;
          border: 3px solid #FFFFFF;
          border-radius: 50%;
          box-shadow: 0 0 10px rgba(0,0,0,0.5);
        }
        .marker-pulse {
          position: absolute;
          width: 36px;
          height: 36px;
          background-color: rgba(21, 101, 255, 0.3);
          border-radius: 50%;
          border: 1px solid #38BDF8;
          animation: pulse 2s infinite;
        }
        @keyframes pulse {
          0% { transform: scale(0.5); opacity: 1; }
          100% { transform: scale(1.5); opacity: 0; }
        }
      </style>
    </head>
    <body>
      <div id="map"></div>
      <script>
        var map = L.map('map', {
          zoomControl: false,
          attributionControl: false,
          dragging: ${interactive ? 'true' : 'false'},
          touchZoom: ${interactive ? 'true' : 'false'},
          scrollWheelZoom: ${interactive ? 'true' : 'false'},
          doubleClickZoom: ${interactive ? 'true' : 'false'},
        }).setView([${currentLat}, ${currentLng}], ${zoom});
        
        L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png').addTo(map);

        var customIcon = L.divIcon({
          className: 'custom-marker',
          html: "<div class='marker-pulse'></div><div class='marker-dot'></div>",
          iconSize: [40, 40],
          iconAnchor: [20, 20]
        });

        var marker = L.marker([${currentLat}, ${currentLng}], {icon: customIcon}).addTo(map);
      </script>
    </body>
    </html>
  `;

  return (
    <View style={[styles.container, style]}>
      {/* Map Canvas */}
      <View style={[styles.mapCanvas, { height }]}>
        <View pointerEvents={interactive ? "auto" : "none"} style={StyleSheet.absoluteFill}>
          {React.createElement(WebView as any, {
            ref: webViewRef,
            originWhitelist: ['*'],
            source: { html: mapHtml },
            style: { flex: 1, backgroundColor: '#F1F5F9' },
            scrollEnabled: false,
            showsHorizontalScrollIndicator: false,
            showsVerticalScrollIndicator: false,
          })}
        </View>

        {/* Action Controls Bar */}
        <View style={styles.controlsBar} pointerEvents="box-none">
          <TouchableOpacity
            style={styles.actionBtn}
            onPress={handleOpenGoogleMaps}
            activeOpacity={0.85}
          >
            <IconButton icon="google-maps" iconColor="#FFFFFF" size={16} style={styles.btnIcon} />
            <Text style={styles.actionBtnText}>Open in Maps</Text>
          </TouchableOpacity>

          {interactive && showDetectBtn && (
            <TouchableOpacity
              style={[styles.actionBtn, styles.gpsBtn]}
              onPress={handleDetectGPS}
              disabled={loading}
              activeOpacity={0.85}
            >
              {loading ? (
                <ActivityIndicator size="small" color="#FFFFFF" style={{ marginHorizontal: 4 }} />
              ) : (
                <>
                  <IconButton icon="crosshairs-gps" iconColor="#FFFFFF" size={16} style={styles.btnIcon} />
                  <Text style={styles.actionBtnText}>My GPS</Text>
                </>
              )}
            </TouchableOpacity>
          )}
        </View>

        {/* Center Target Info Box Overlay */}
        {!interactive && (
          <View style={styles.centerOverlay} pointerEvents="none">
            <View style={styles.pinCallout}>
              <Text style={styles.pinCalloutText} numberOfLines={1}>
                {title}
              </Text>
            </View>
          </View>
        )}

        {/* Coordinates HUD Badge */}
        <View style={styles.coordsBadge} pointerEvents="none">
          <Text style={styles.coordsText}>
            LAT: {currentLat.toFixed(4)} | LNG: {currentLng.toFixed(4)}
          </Text>
        </View>
      </View>

      {/* Address & Verified Location Card */}
      <View style={styles.infoCard}>
        <View style={styles.infoRow}>
          <IconButton icon="map-marker-radius" iconColor="#0066FF" size={20} style={{ margin: 0, padding: 0 }} />
          <View style={styles.addressWrapper}>
            <Text style={styles.addressHeading} numberOfLines={1}>
              {title}
            </Text>
            <Text style={styles.addressText} numberOfLines={2}>
              {address || `Lat: ${currentLat.toFixed(4)}, Long: ${currentLng.toFixed(4)} (OpenStreetMap Verified)`}
            </Text>
          </View>
        </View>
      </View>
    </View>
  );
};

export default GMap;

const styles = StyleSheet.create({
  container: {
    width: '100%',
    borderRadius: 16,
    overflow: 'hidden',
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E2E8F0',
  },
  mapCanvas: {
    width: '100%',
    position: 'relative',
    backgroundColor: '#F1F5F9',
    overflow: 'hidden',
  },
  centerOverlay: {
    ...StyleSheet.absoluteFillObject,
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 10,
  },
  pinCallout: {
    marginTop: 20, 
    backgroundColor: 'rgba(11, 18, 32, 0.85)',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#334155',
  },
  pinCalloutText: {
    color: '#F8FAFC',
    fontSize: 12,
    fontWeight: '600',
  },
  controlsBar: {
    position: 'absolute',
    top: 10,
    right: 10,
    flexDirection: 'row',
    gap: 8,
    zIndex: 20,
  },
  actionBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#0066FF',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 20,
    elevation: 3,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.3,
    shadowRadius: 3,
  },
  gpsBtn: {
    backgroundColor: '#059669',
  },
  btnIcon: {
    margin: 0,
    marginRight: -4,
  },
  actionBtnText: {
    color: '#FFFFFF',
    fontSize: 12,
    fontWeight: '700',
    marginLeft: 2,
  },
  coordsBadge: {
    position: 'absolute',
    bottom: 8,
    left: 8,
    backgroundColor: 'rgba(15, 23, 42, 0.85)',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
    borderWidth: 0.5,
    borderColor: '#334155',
    zIndex: 10,
  },
  coordsText: {
    color: '#94A3B8',
    fontSize: 11,
    fontWeight: '500',
    fontFamily: Platform.OS === 'ios' ? 'Courier' : 'monospace',
  },
  infoCard: {
    backgroundColor: '#F8FAFC',
    padding: 12,
    borderTopWidth: 1,
    borderTopColor: '#F1F5F9',
  },
  infoRow: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  addressWrapper: {
    flex: 1,
    marginLeft: 6,
  },
  addressHeading: {
    color: '#0F172A',
    fontSize: 13,
    fontWeight: '700',
  },
  addressText: {
    color: '#475569',
    fontSize: 12,
    marginTop: 2,
    lineHeight: 16,
  },
});
