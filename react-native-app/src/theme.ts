import { MD3LightTheme } from 'react-native-paper';

/**
 * Unified Native Design System & Color Tokens for PartX Auto Parts App.
 * Strict Single Source of Truth for colors, fonts, and surface styling.
 */

export const AppColors = {
  // Brand Colors
  primary: '#0066FF',
  primaryDark: '#0052CC',
  primaryLight: '#EFF6FF',
  primaryMuted: '#DBEAFE',

  // Text Colors (Accessible Contrast)
  text: {
    primary: '#0F172A',    // Headlines, Titles, High-priority values
    secondary: '#475569',  // Body text, Subtitles, Descriptions, Specs
    muted: '#94A3B8',      // Placeholders, Timestamps, Inactive hints
    inverse: '#FFFFFF',    // White text on dark/colored buttons
    brand: '#0066FF',      // Action links, Active indicators
    success: '#16A34A',    // Verified, In-Stock, Low-price deals
    danger: '#DC2626',     // Errors, Out of stock, Sold, Delete
    warning: '#D97706',    // Pending approval, Alerts
  },

  // Surfaces & Backgrounds
  surface: {
    background: '#F8FAFC', // Main screen background
    card: '#FFFFFF',       // Native card background
    cardSecondary: '#F1F5F9', // Inset card, subtle chip
    border: '#E2E8F0',     // Standard card & divider border
    borderLight: '#F1F5F9',// Subtle divider
    dark: '#0B1220',       // Header & dark surface accents
  },

  // Status & Badges
  status: {
    success: '#16A34A',
    successBg: '#DCFCE7',
    danger: '#DC2626',
    dangerBg: '#FEE2E2',
    warning: '#D97706',
    warningBg: '#FEF3C7',
    info: '#0066FF',
    infoBg: '#EFF6FF',
  },
} as const;

export const Typography = {
  size: {
    xs: 12,    // Smallest mobile label (no 9-10px web micro-text)
    sm: 13,    // Secondary labels, timestamps
    body: 14,  // Standard mobile body text
    bodyLarge: 15, // High-readability input / description
    title: 16, // Card titles, section subheads
    h3: 18,    // Section headers, modal titles
    h2: 20,    // Screen subtitles, prominent prices
    h1: 24,    // Main screen titles
  },
  weight: {
    regular: '400' as const,
    medium: '500' as const,
    semibold: '600' as const,
    bold: '700' as const,
    heavy: '800' as const,
  },
} as const;

export const theme = {
  ...MD3LightTheme,
  isV3: true,
  version: 3 as any,
  fonts: MD3LightTheme?.fonts || {},
  colors: {
    ...(MD3LightTheme?.colors || {}),
    primary: AppColors.primary,
    secondary: AppColors.primaryDark,
    tertiary: AppColors.primaryLight,
    background: AppColors.surface.background,
    surface: AppColors.surface.card,
    surfaceVariant: AppColors.surface.cardSecondary,
    outline: AppColors.surface.border,
    error: AppColors.text.danger,
  },
};

export default AppColors;
