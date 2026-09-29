import { Share, Platform, Alert } from 'react-native';

export const APP_RELEASE_URL = 'https://autopartsindiaofficial.github.io/auto-parts-india-download/';

export interface ShareProductOptions {
  id?: string;
  title: string;
  price?: number;
  imageUrl?: string;
  imageUrls?: string[];
  carBrand?: string;
  brand?: string;
  carModel?: string;
  model?: string;
  location?: string;
  district?: string;
  state?: string;
}

/**
 * Rich Product & App Share Helper
 * Includes Title, Price, Location, Photo URL, and Official Website Download link
 */
export async function shareProductListing(product: ShareProductOptions) {
  try {
    const formattedPrice = product.price != null ? `₹${Number(product.price).toLocaleString('en-IN')}` : '';
    const brandModel = [product.carBrand || product.brand, product.carModel || product.model].filter(Boolean).join(' ');
    const locationStr = product.location || [product.district, product.state].filter(Boolean).join(', ');
    const primaryImg = product.imageUrl || (product.imageUrls && product.imageUrls[0]) || '';

    // Direct Web & Deep Link for listing
    const listingWebUrl = product.id 
      ? `${APP_RELEASE_URL}?partId=${encodeURIComponent(product.id)}`
      : APP_RELEASE_URL;

    // Compose Rich Share Message
    let shareText = `🚗 *${product.title.trim()}*\n`;
    if (formattedPrice) {
      shareText += `💰 *Price:* ${formattedPrice}\n`;
    }
    if (brandModel) {
      shareText += `🏎️ *Vehicle:* ${brandModel}\n`;
    }
    if (locationStr) {
      shareText += `📍 *Location:* ${locationStr}\n`;
    }

    if (primaryImg) {
      shareText += `🖼️ *Photo:* ${primaryImg}\n`;
    }

    shareText += `\n📲 *View item & Download Auto Parts India App:*\n${listingWebUrl}`;

    if (Platform.OS === 'web') {
      if (typeof navigator !== 'undefined' && navigator.share) {
        await navigator.share({
          title: product.title,
          text: shareText,
          url: listingWebUrl,
        });
      } else if (typeof navigator !== 'undefined' && navigator.clipboard) {
        await navigator.clipboard.writeText(shareText);
        Alert.alert('Link Copied!', 'Listing details & app link copied to clipboard. You can now paste and share it anywhere!');
      } else {
        Alert.alert('Share Listing', shareText);
      }
    } else {
      await Share.share(
        {
          title: `Auto Parts India: ${product.title}`,
          message: shareText,
          url: listingWebUrl, // Included for iOS Share Sheet thumbnail/link preview
        },
        {
          dialogTitle: `Share ${product.title}`,
          subject: product.title,
        }
      );
    }
  } catch (error: any) {
    if (error?.message && !error.message.includes('User cancelled')) {
      console.warn('[ShareUtils] Error sharing listing:', error);
    }
  }
}

/**
 * Share App Link / Invite Friends Helper
 */
export async function shareAppWithFriends() {
  try {
    const shareText = `🚀 *Auto Parts India App*\nBuy & Sell genuine car & bike spare parts directly with sellers across India!\n\n👇 *Download App / Visit Website:*\n${APP_RELEASE_URL}`;

    if (Platform.OS === 'web') {
      if (typeof navigator !== 'undefined' && navigator.share) {
        await navigator.share({
          title: 'Auto Parts India App',
          text: shareText,
          url: APP_RELEASE_URL,
        });
      } else if (typeof navigator !== 'undefined' && navigator.clipboard) {
        await navigator.clipboard.writeText(shareText);
        Alert.alert('App Link Copied!', 'Auto Parts India app link copied to clipboard. Share it with your friends!');
      } else {
        Alert.alert('Share App', shareText);
      }
    } else {
      await Share.share(
        {
          title: 'Auto Parts India',
          message: shareText,
          url: APP_RELEASE_URL,
        },
        {
          dialogTitle: 'Invite Friends to Auto Parts India',
          subject: 'Auto Parts India App Download',
        }
      );
    }
  } catch (error: any) {
    if (error?.message && !error.message.includes('User cancelled')) {
      console.warn('[ShareUtils] Error sharing app:', error);
    }
  }
}
