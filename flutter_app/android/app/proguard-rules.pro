# Flutter Standard Engine Rules
-keep class io.flutter.app.FlutterApplication { *; }
-keep class io.flutter.embedding.engine.FlutterJNI { *; }
-keep class io.flutter.embedding.android.FlutterActivity { *; }
-keep class io.flutter.embedding.android.FlutterFragment { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugins.** { *; }

# Firebase & Google Play Services
-keepattributes *Annotation*,Signature
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
