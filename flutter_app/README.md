# 🚗 Auto Parts India (Flutter Mobile App)

This is the complete, production-grade **Flutter (Android & iOS)** application for **Auto Parts India** — the #1 Marketplace for Used & OEM Automobile Spare Parts. Built with full **Firebase Cloud Firestore Realtime Sync**, **Authentication**, **Cloudinary Multi-Image Uploads**, **Multi-Language Support (English, Tamil, Hindi)**, and direct **In-App Realtime Buyer-Seller Chat & Calling**.

---

## 📱 Complete List of 24 Flutter Screens

| # | Screen File | Description |
|---|---|---|
| 1 | `splash_screen.dart` | Animated splash entry, auto-login check & background connectivity verification. |
| 2 | `main_nav_screen.dart` | Floating 5-Tab Navigation Bar with live unread badge counters. |
| 3 | `home_screen.dart` | Location selector, promo banners, top categories, brand carousels & 2-column live feed. |
| 4 | `all_categories_screen.dart` | Deep-dive category explorer with 8 major categories and 48+ subcategories. |
| 5 | `search_screen.dart` | Instant live search, recent searches history, trending chips & advanced filters modal. |
| 6 | `product_detail_screen.dart` | High-res image gallery, specifications, Call Seller, In-App Chat, Make Offer & safety tips. |
| 7 | `sell_part_screen.dart` | Photo upload (Camera/Gallery), cascading brand/model/category & auto-title generator. |
| 8 | `chats_screen.dart` | Buyer/Seller inbox with All, Buying & Selling tabs, live unread counts & search. |
| 9 | `chat_room_screen.dart` | 1-on-1 realtime chat thread, sticky product header, Make Offer cards, quick replies & image sharing. |
| 10 | `my_ads_screen.dart` | Active / Sold tabs, view counter, one-tap "Mark as Sold" toggle, edit & delete actions. |
| 11 | `edit_listing_screen.dart` | Live listing update form with photo management and specs editing. |
| 12 | `profile_screen.dart` | Live metrics (Ads, Followers, Following, Saved), profile photo, admin badge & settings. |
| 13 | `edit_profile_screen.dart` | Update full name, phone number, location, bio & profile picture with Cloudinary upload. |
| 14 | `wishlist_screen.dart` | Saved / Bookmarked spare parts with instant bookmark toggle. |
| 15 | `recently_viewed_screen.dart` | Recently browsed automobile parts history. |
| 16 | `seller_profile_screen.dart` | Public seller shop page with direct call, in-app chat, follow button & seller's listings. |
| 17 | `seller_reviews_screen.dart` | Buyer ratings & reviews breakdown with 5-star ratings. |
| 18 | `location_select_screen.dart` | State and district selection for all major Indian cities. |
| 19 | `notifications_screen.dart` | Realtime alerts for inquiries, price drops, and admin announcements. |
| 20 | `admin_dashboard_screen.dart` | 8-tab admin master console (Overview, Listings, Users, Banners, Categories, Brands, Broadcasts, Versions). |
| 21 | `admin_taxonomy_screen.dart` | Vehicle CMS for adding & editing car brands, models, and spare parts taxonomy. |
| 22 | `help_support_screen.dart` | 24x7 customer helpline, official email support & marketplace FAQs. |
| 23 | `settings_screen.dart` | Push notification toggles, location permissions, sound & temporary cache cleanup. |
| 24 | `auth_screen.dart` | Google One-Tap & Email authentication modal. |

---

## 📁 Directory Structure

```
flutter_app/
├── lib/
│   ├── main.dart                     # App entry point with MultiProvider & Theme
│   ├── constants/
│   │   ├── app_colors.dart           # Brand colors & styling tokens
│   │   ├── categories_data.dart      # Automotive categories & top brands
│   │   └── translations_data.dart    # English, Tamil & Hindi language packs
│   ├── models/
│   │   ├── spare_part.dart           # Spare part data model with Firestore converter
│   │   ├── user_profile.dart         # User profile data model
│   │   └── chat_message.dart         # Realtime chat message model
│   ├── services/
│   │   ├── firebase_service.dart     # Firestore CRUD, realtime streams, and chats
│   │   ├── auth_service.dart         # Firebase Auth (Email/Google)
│   │   └── cloudinary_service.dart   # Direct image uploads to Cloudinary
│   ├── providers/
│   │   ├── parts_provider.dart       # Filtering, search & category state
│   │   ├── auth_provider.dart        # Authentication & current user state
│   │   └── language_provider.dart    # Realtime app language switcher
│   ├── screens/                      # 24 complete screen files
│   └── widgets/
│       ├── product_card.dart         # Responsive 2-column spare part card
│       ├── make_offer_dialog.dart    # Bargaining / price negotiation modal
│       └── category_chip.dart        # Fast category pill widget
├── android/                          # Native Android configuration
└── pubspec.yaml                      # Flutter dependencies
```

---

## ⚡ How to Run on Your Local Computer

### 1. Requirements:
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (version 3.10 or later)
- Android Studio / VS Code with Flutter Extension
- Connected Android Device or Emulator

### 2. Install Packages:
```bash
cd flutter_app
flutter pub get
```

### 3. Setup Firebase for Android:
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Add an Android app with package name `com.autoparts.marketplace`
3. Download `google-services.json` and place it inside:
   `flutter_app/android/app/google-services.json`

### 4. Run Debug App:
```bash
flutter run
```

### 5. Build Release APK (for Android Phones):
```bash
flutter build apk --release
```
The generated APK will be located at:
`flutter_app/build/app/outputs/flutter-apk/app-release.apk`
