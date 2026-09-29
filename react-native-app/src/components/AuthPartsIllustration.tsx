import React from 'react';
import { View, StyleSheet, useWindowDimensions } from 'react-native';
import Svg, { 
  Path, 
  Circle, 
  Rect, 
  G, 
  Defs, 
  LinearGradient, 
  RadialGradient, 
  Stop, 
  Mask,
  Line
} from 'react-native-svg';

/**
 * High-definition vector emblem of aerodynamic sportscar silhouette + cyan mechanical gear
 * matching the user's reference logo with exact fidelity.
 */
export const AuthCarLogo = ({ size = 110 }: { size?: number }) => {
  const width = size * 1.8;
  const height = size;

  return (
    <View style={{ width, height, alignItems: 'center', justifyContent: 'center' }}>
      <Svg width={width} height={height} viewBox="0 0 180 100" fill="none">
        <Defs>
          <LinearGradient id="carStrokeGrad" x1="0%" y1="0%" x2="100%" y2="0%">
            <Stop offset="0%" stopColor="#FFFFFF" stopOpacity="0.7" />
            <Stop offset="30%" stopColor="#FFFFFF" stopOpacity="1" />
            <Stop offset="70%" stopColor="#38BDF8" stopOpacity="1" />
            <Stop offset="100%" stopColor="#60A5FA" stopOpacity="0.85" />
          </LinearGradient>
          <LinearGradient id="gearGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <Stop offset="0%" stopColor="#38BDF8" stopOpacity="0.9" />
            <Stop offset="100%" stopColor="#0284C7" stopOpacity="0.5" />
          </LinearGradient>
        </Defs>

        {/* Glowing Cyan Gear behind Car Roof */}
        <G transform="translate(100, 32)">
          {/* Gear teeth & body */}
          <Path
            d="M 0,-24 L 4,-24 L 5,-19 L 10,-17 L 14,-21 L 18,-18 L 16,-13 L 20,-9 L 25,-10 L 26,-5 L 21,-2 L 21,3 L 26,6 L 25,11 L 20,10 L 16,14 L 18,19 L 14,22 L 10,18 L 5,20 L 4,25 L -1,25 L -2,20 L -7,18 L -11,22 L -15,19 L -13,14 L -17,10 L -22,11 L -23,6 L -18,3 L -18,-2 L -23,-5 L -22,-10 L -17,-9 L -13,-13 L -15,-18 L -11,-21 L -7,-17 L -2,-19 Z"
            fill="url(#gearGrad)"
          />
          <Circle cx="0" cy="0" r="10" fill="#003B94" />
          <Circle cx="0" cy="0" r="6" fill="#38BDF8" opacity="0.7" />
        </G>

        {/* Sleek Aerodynamic Car Silhouette Roof & Body Lines */}
        {/* Main roofline arc */}
        <Path
          d="M 12 72 C 30 68, 48 40, 78 30 C 108 20, 138 28, 168 68 C 172 73, 165 75, 156 74 C 130 66, 105 52, 74 52 C 45 52, 28 66, 12 72 Z"
          fill="url(#carStrokeGrad)"
        />

        {/* Upper roof highlight curve */}
        <Path
          d="M 44 56 C 65 34, 98 28, 142 54"
          stroke="#FFFFFF"
          strokeWidth="3.5"
          strokeLinecap="round"
        />

        {/* Car Windshield & Side Window Dividers */}
        <Path
          d="M 72 50 L 82 34 C 95 32, 108 34, 116 48 Z"
          fill="#002D7A"
          stroke="#38BDF8"
          strokeWidth="1.2"
        />
        <Path
          d="M 120 48 C 128 44, 136 46, 142 52 L 126 53 Z"
          fill="#002D7A"
          stroke="#38BDF8"
          strokeWidth="1"
        />

        {/* Headlight & Hood Sharp Character Line */}
        <Path
          d="M 152 66 C 160 67, 168 69, 172 70"
          stroke="#67E8F9"
          strokeWidth="2.5"
          strokeLinecap="round"
        />
        <Path
          d="M 14 71 C 22 70, 32 68, 40 68"
          stroke="#93C5FD"
          strokeWidth="2.5"
          strokeLinecap="round"
        />

        {/* Front Wheel Arch Accent */}
        <Path
          d="M 142 74 C 145 68, 155 68, 158 74"
          stroke="#38BDF8"
          strokeWidth="2"
          strokeLinecap="round"
        />
        {/* Rear Wheel Arch Accent */}
        <Path
          d="M 28 73 C 31 67, 41 67, 44 73"
          stroke="#38BDF8"
          strokeWidth="2"
          strokeLinecap="round"
        />
      </Svg>
    </View>
  );
};

/**
 * Ultra-detailed 3D Spare Parts Visual Cluster on Curved Asphalt Road
 * Features:
 * - Cross-drilled Ventilated Brake Disc Rotor
 * - Cobalt Blue Shock Absorber Coilover Spring
 * - Spin-on Blue Oil Filter Canister
 * - Friction Brake Pad
 * - Spark Plug with Thread & Ceramic Ribs
 * - Precision Ball Bearing
 * - Asphalt Road with Tire Tread Tracks
 */
export const AuthPartsShowcase = () => {
  const { width: screenWidth } = useWindowDimensions();
  const svgWidth = screenWidth;
  const svgHeight = Math.min(screenWidth * 0.95, 380);

  return (
    <View style={{ width: svgWidth, height: svgHeight, overflow: 'hidden' }}>
      <Svg width={svgWidth} height={svgHeight} viewBox="0 0 400 360" fill="none">
        <Defs>
          {/* Background Radial Glow */}
          <RadialGradient id="blueAtmosphereGlow" cx="50%" cy="40%" r="60%">
            <Stop offset="0%" stopColor="#0066FF" stopOpacity="0.45" />
            <Stop offset="60%" stopColor="#003399" stopOpacity="0.2" />
            <Stop offset="100%" stopColor="#001640" stopOpacity="0" />
          </RadialGradient>

          {/* Road Asphalt Gradient */}
          <LinearGradient id="roadGradient" x1="0%" y1="0%" x2="0%" y2="100%">
            <Stop offset="0%" stopColor="#0A162B" stopOpacity="0.2" />
            <Stop offset="30%" stopColor="#061224" stopOpacity="0.85" />
            <Stop offset="100%" stopColor="#030A14" stopOpacity="1" />
          </LinearGradient>

          {/* Metallic Rotor Steel Gradient */}
          <LinearGradient id="rotorSteelGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <Stop offset="0%" stopColor="#E2E8F0" />
            <Stop offset="35%" stopColor="#94A3B8" />
            <Stop offset="70%" stopColor="#CBD5E1" />
            <Stop offset="100%" stopColor="#64748B" />
          </LinearGradient>

          {/* Rotor Inner Hub Dark Steel */}
          <LinearGradient id="hubSteelGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <Stop offset="0%" stopColor="#475569" />
            <Stop offset="50%" stopColor="#1E293B" />
            <Stop offset="100%" stopColor="#0F172A" />
          </LinearGradient>

          {/* Blue Performance Coil Spring Gradient */}
          <LinearGradient id="springBlueGrad" x1="0%" y1="0%" x2="100%" y2="0%">
            <Stop offset="0%" stopColor="#0284C7" />
            <Stop offset="40%" stopColor="#38BDF8" />
            <Stop offset="70%" stopColor="#0066FF" />
            <Stop offset="100%" stopColor="#075985" />
          </LinearGradient>

          {/* Oil Filter Canister Gradient */}
          <LinearGradient id="oilFilterGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <Stop offset="0%" stopColor="#0284C7" />
            <Stop offset="30%" stopColor="#02458A" />
            <Stop offset="70%" stopColor="#002244" />
            <Stop offset="100%" stopColor="#00142A" />
          </LinearGradient>

          {/* Brake Pad Friction Material */}
          <LinearGradient id="padMaterialGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <Stop offset="0%" stopColor="#334155" />
            <Stop offset="50%" stopColor="#1E293B" />
            <Stop offset="100%" stopColor="#0F172A" />
          </LinearGradient>

          {/* Spark Plug Ceramic Grad */}
          <LinearGradient id="sparkCeramicGrad" x1="0%" y1="0%" x2="100%" y2="0%">
            <Stop offset="0%" stopColor="#FFFFFF" />
            <Stop offset="50%" stopColor="#F1F5F9" />
            <Stop offset="100%" stopColor="#CBD5E1" />
          </LinearGradient>

          {/* Chrome Metal Specular */}
          <LinearGradient id="chromeMetalGrad" x1="0%" y1="0%" x2="100%" y2="100%">
            <Stop offset="0%" stopColor="#FFFFFF" />
            <Stop offset="30%" stopColor="#94A3B8" />
            <Stop offset="60%" stopColor="#F8FAFC" />
            <Stop offset="100%" stopColor="#475569" />
          </LinearGradient>
        </Defs>

        {/* Ambient Radial Spotlight behind parts */}
        <Rect x="0" y="0" width="400" height="360" fill="url(#blueAtmosphereGlow)" />

        {/* Subtle Tire Tread Marks on curved road */}
        <G opacity="0.22">
          {/* Curved road base */}
          <Path
            d="M -20 360 Q 150 200 420 220 L 420 360 Z"
            fill="url(#roadGradient)"
          />
          
          {/* Realistic Dual Tire Tread Grooves */}
          <Path
            d="M -10 320 Q 120 240 240 235"
            stroke="#38BDF8"
            strokeWidth="8"
            strokeDasharray="14,10,6,10"
            strokeLinecap="round"
          />
          <Path
            d="M -5 340 Q 135 255 260 245"
            stroke="#38BDF8"
            strokeWidth="8"
            strokeDasharray="14,10,6,10"
            strokeLinecap="round"
          />
        </G>

        {/* 1. BLUE SHOCK ABSORBER COILOVER STRUT (Right Background) */}
        <G transform="translate(325, 140)">
          {/* Chrome central piston shaft */}
          <Rect x="-8" y="0" width="16" height="180" fill="url(#chromeMetalGrad)" rx="3" />
          
          {/* Top strut mount & cap */}
          <Rect x="-22" y="-12" width="44" height="18" fill="#1E293B" rx="4" />
          <Rect x="-16" y="-18" width="32" height="8" fill="url(#chromeMetalGrad)" rx="2" />
          
          {/* Coiled Blue Springs */}
          <Path
            d="M -24 16 C -20 8, 20 18, 24 24 C 28 30, -20 34, -24 42
               C -28 50, 20 54, 24 62 C 28 70, -20 74, -24 82
               C -28 90, 20 94, 24 102 C 28 110, -20 114, -24 122
               C -28 130, 20 134, 24 142 C 28 150, -20 154, -24 162"
            stroke="url(#springBlueGrad)"
            strokeWidth="14"
            strokeLinecap="round"
          />
          {/* Spring Highlights */}
          <Path
            d="M -18 18 C -14 12, 14 20, 18 24 M -18 58 C -14 52, 14 60, 18 64 M -18 98 C -14 92, 14 100, 18 104 M -18 138 C -14 132, 14 140, 18 144"
            stroke="#93C5FD"
            strokeWidth="3.5"
            strokeLinecap="round"
          />

          {/* Lower Strut Base */}
          <Rect x="-20" y="165" width="40" height="20" fill="#0F172A" rx="4" />
          <Circle cx="0" cy="180" r="8" fill="url(#chromeMetalGrad)" />
        </G>

        {/* 2. VENTILATED CROSS-DRILLED BRAKE ROTOR DISC (Center) */}
        <G transform="translate(260, 245)">
          {/* Cast iron outer disc */}
          <Circle cx="0" cy="0" r="78" fill="url(#rotorSteelGrad)" stroke="#64748B" strokeWidth="2" />
          
          {/* Rotor edge bevel highlight */}
          <Circle cx="0" cy="0" r="76" stroke="#FFFFFF" strokeWidth="1.5" opacity="0.6" fill="none" />
          <Circle cx="0" cy="0" r="48" stroke="#475569" strokeWidth="1.5" fill="none" />

          {/* Cross Drilled Cooling Holes array */}
          <G fill="#0F172A">
            {/* Pattern holes */}
            <Circle cx="-58" cy="-18" r="2.8" /><Circle cx="-48" cy="-22" r="2.8" /><Circle cx="-38" cy="-28" r="2.8" />
            <Circle cx="-54" cy="16" r="2.8" /><Circle cx="-44" cy="24" r="2.8" /><Circle cx="-34" cy="30" r="2.8" />
            <Circle cx="-18" cy="-58" r="2.8" /><Circle cx="-22" cy="-48" r="2.8" /><Circle cx="-28" cy="-38" r="2.8" />
            <Circle cx="16" cy="-54" r="2.8" /><Circle cx="24" cy="-44" r="2.8" /><Circle cx="30" cy="-34" r="2.8" />
            <Circle cx="58" cy="-18" r="2.8" /><Circle cx="48" cy="-22" r="2.8" /><Circle cx="38" cy="-28" r="2.8" />
            <Circle cx="54" cy="16" r="2.8" /><Circle cx="44" cy="24" r="2.8" /><Circle cx="34" cy="30" r="2.8" />
            <Circle cx="-18" cy="58" r="2.8" /><Circle cx="-22" cy="48" r="2.8" /><Circle cx="-28" cy="38" r="2.8" />
            <Circle cx="16" cy="54" r="2.8" /><Circle cx="24" cy="44" r="2.8" /><Circle cx="30" cy="34" r="2.8" />
          </G>

          {/* Rotor Inner Hub Bell */}
          <Circle cx="0" cy="0" r="42" fill="url(#hubSteelGrad)" stroke="#334155" strokeWidth="2" />
          <Circle cx="0" cy="0" r="24" fill="#0B132B" />
          <Circle cx="0" cy="0" r="14" fill="#1E293B" stroke="url(#chromeMetalGrad)" strokeWidth="2" />

          {/* 5-Lug Wheel Bolt Studs */}
          <G fill="url(#chromeMetalGrad)">
            <Circle cx="0" cy="-30" r="4.5" />
            <Circle cx="28" cy="-9" r="4.5" />
            <Circle cx="18" cy="24" r="4.5" />
            <Circle cx="-18" cy="24" r="4.5" />
            <Circle cx="-28" cy="-9" r="4.5" />
          </G>
        </G>

        {/* 3. ROLLER BEARING / GEAR HUB (Right Foreground) */}
        <G transform="translate(345, 295)">
          <Circle cx="0" cy="0" r="34" fill="url(#chromeMetalGrad)" stroke="#334155" strokeWidth="1.5" />
          <Circle cx="0" cy="0" r="26" fill="#0F172A" />
          {/* Bearing balls */}
          <Circle cx="0" cy="-18" r="5" fill="url(#chromeMetalGrad)" />
          <Circle cx="15" cy="-10" r="5" fill="url(#chromeMetalGrad)" />
          <Circle cx="17" cy="8" r="5" fill="url(#chromeMetalGrad)" />
          <Circle cx="4" cy="18" r="5" fill="url(#chromeMetalGrad)" />
          <Circle cx="-14" cy="12" r="5" fill="url(#chromeMetalGrad)" />
          <Circle cx="-17" cy="-7" r="5" fill="url(#chromeMetalGrad)" />
          {/* Inner ring */}
          <Circle cx="0" cy="0" r="12" fill="url(#chromeMetalGrad)" stroke="#1E293B" strokeWidth="1" />
          <Circle cx="0" cy="0" r="7" fill="#050C1A" />
        </G>

        {/* 4. BLUE SPIN-ON OIL FILTER (Left Foreground) */}
        <G transform="translate(195, 280)">
          {/* Filter Canister Body */}
          <Rect x="-42" y="-35" width="84" height="65" rx="14" fill="url(#oilFilterGrad)" stroke="#0284C7" strokeWidth="1.5" />
          
          {/* Glossy Reflection highlight on canister */}
          <Path
            d="M -34 -24 Q -10 -28 20 -25"
            stroke="#60A5FA"
            strokeWidth="3.5"
            strokeLinecap="round"
            opacity="0.8"
          />

          {/* Top Gasket / Flange Ring */}
          <G transform="translate(-40, 2)">
            <Circle cx="0" cy="0" r="38" fill="url(#hubSteelGrad)" stroke="url(#chromeMetalGrad)" strokeWidth="1.5" />
            <Circle cx="0" cy="0" r="32" fill="#09121D" />
            
            {/* Center Thread Hole */}
            <Circle cx="0" cy="0" r="12" fill="url(#chromeMetalGrad)" />
            <Circle cx="0" cy="0" r="8" fill="#000000" />
            
            {/* Oil Inlet Holes array */}
            <Circle cx="0" cy="-22" r="3" fill="url(#chromeMetalGrad)" />
            <Circle cx="16" cy="-16" r="3" fill="url(#chromeMetalGrad)" />
            <Circle cx="22" cy="0" r="3" fill="url(#chromeMetalGrad)" />
            <Circle cx="16" cy="16" r="3" fill="url(#chromeMetalGrad)" />
            <Circle cx="0" cy="22" r="3" fill="url(#chromeMetalGrad)" />
            <Circle cx="-16" cy="16" r="3" fill="url(#chromeMetalGrad)" />
            <Circle cx="-22" cy="0" r="3" fill="url(#chromeMetalGrad)" />
            <Circle cx="-16" cy="-16" r="3" fill="url(#chromeMetalGrad)" />
          </G>
        </G>

        {/* 5. CERAMIC BRAKE PAD (Center Lower) */}
        <G transform="translate(255, 305)">
          {/* Steel backing plate */}
          <Path
            d="M -32 -20 C -20 -28, 20 -28, 32 -20 L 36 -12 L 34 16 C 20 22, -20 22, -34 16 L -36 -12 Z"
            fill="url(#hubSteelGrad)"
            stroke="#64748B"
            strokeWidth="1.5"
          />
          {/* Friction lining block */}
          <Path
            d="M -26 -16 C -16 -22, 16 -22, 26 -16 L 28 12 C 16 16, -16 16, -28 12 Z"
            fill="url(#padMaterialGrad)"
          />
          {/* Center heat dissipation slot */}
          <Line x1="0" y1="-18" x2="0" y2="14" stroke="#000000" strokeWidth="2.5" />
          {/* Anti-squeal shim clip */}
          <Circle cx="-24" cy="-8" r="2.5" fill="url(#chromeMetalGrad)" />
          <Circle cx="24" cy="-8" r="2.5" fill="url(#chromeMetalGrad)" />
        </G>

        {/* 6. SPARK PLUG (Bottom Right Front) */}
        <G transform="translate(325, 328) rotate(-18)">
          {/* Terminal Nut */}
          <Rect x="-3" y="-30" width="6" height="8" fill="url(#chromeMetalGrad)" rx="1.5" />
          {/* Ribbed Ceramic Insulator */}
          <Rect x="-6" y="-22" width="12" height="24" fill="url(#sparkCeramicGrad)" rx="2" />
          <Line x1="-6" y1="-18" x2="6" y2="-18" stroke="#CBD5E1" strokeWidth="1.5" />
          <Line x1="-6" y1="-14" x2="6" y2="-14" stroke="#CBD5E1" strokeWidth="1.5" />
          <Line x1="-6" y1="-10" x2="6" y2="-10" stroke="#CBD5E1" strokeWidth="1.5" />
          {/* Hex Nut Body */}
          <Rect x="-8" y="2" width="16" height="8" fill="url(#hubSteelGrad)" rx="1" />
          {/* Threaded Shell */}
          <Rect x="-5.5" y="10" width="11" height="14" fill="url(#chromeMetalGrad)" />
          <Line x1="-5.5" y1="13" x2="5.5" y2="13" stroke="#475569" strokeWidth="1" />
          <Line x1="-5.5" y1="17" x2="5.5" y2="17" stroke="#475569" strokeWidth="1" />
          <Line x1="-5.5" y1="21" x2="5.5" y2="21" stroke="#475569" strokeWidth="1" />
          {/* Electrode Ground Tip */}
          <Path d="M -2 24 L -2 28 L 2 28" stroke="url(#chromeMetalGrad)" strokeWidth="1.8" fill="none" />
        </G>
      </Svg>
    </View>
  );
};

export default AuthPartsShowcase;
