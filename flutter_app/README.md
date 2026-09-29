# 🚗 Auto Parts Marketplace (Flutter Mobile App)

This is the complete, cross-platform **Flutter (Android & iOS)** application for the **Auto Parts Marketplace** with full Firebase Firestore realtime sync, Authentication, Cloudinary image uploads, multi-language support (English, Tamil, Hindi), and direct Seller Chat & Calling.

---

## 📁 Directory Structure

```
flutter_app/
├── lib/
│   ├── main.dart                     # App entry point with MultiProvider & Theme
│   ├── constants/
│   │   ├── app_colors.dart           # Brand colors & styling tokens
│   │   ├── categories_data.dart      # 6 main automotive categories & top brands
│   │   └── translations_data.dart    # English, Tamil & Hindi language packs
│   ├── models/
│   │   ├── spare_part.dart           # Spare part data model with Firestore converter
│   │   ├── user_profile.dart         # User profile data model
│   │   └── chat_message.dart         # Realtime chat message model
│   ├── services/
│   │   ├── firebase_service.dart     # Firestore CRUD, realtime streams, and chats
│   │   ├── auth_service.dart         # Firebase Auth (Email/Google)
│   │   └── cloudinary_service.dart   # Image upload direct to Cloudinary
│   ├── providers/
│   │   ├── parts_provider.dart       # Filtering, search & category state
│   │   ├── auth_provider.dart        # Authentication & current user state
│   │   └── language_provider.dart    # Realtime app language switcher
│   ├── screens/
│   │   ├── home_screen.dart          # Marketplace feed with category tabs & banner
│   │   ├── all_categories_screen.dart# Deep-dive category explorer
│   │   ├── search_screen.dart        # Instant search with filter chips
│   │   ├── sell_part_screen.dart     # Post an ad with photo upload
│   │   ├── product_detail_screen.dart# Product specifications, seller call & chat
│   │   ├── chats_screen.dart         # Buyer-seller inbox
│   │   ├── chat_room_screen.dart     # Realtime 1-on-1 message thread
│   │   ├── my_ads_screen.dart        # Manage & mark your ads as sold
│   │   ├── wishlist_screen.dart      # Saved favorite spare parts
│   │   ├── profile_screen.dart       # Profile info, language & settings
│   │   └── auth_screen.dart          # Sign in / Register modal
│   └── widgets/
│       ├── product_card.dart         # Responsive spare part card
│       ├── make_offer_dialog.dart    # Bargaining / price negotiation modal
│       └── category_chip.dart        # Fast category pill widget
├── android/                          # Native Android Gradle configuration
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
