# ProGuard rules for code shrinking and obfuscation.
# Add your custom rules here.

# Suppression for Facebook Infer annotations
-dontwarn com.facebook.infer.annotation.Nullsafe$Mode
-dontwarn com.facebook.infer.annotation.Nullsafe

# Keep Facebook Ads SDK classes
-keep class com.facebook.ads.** { *; }
-keep interface com.facebook.ads.** { *; }

# Keep Facebook Mediation Adapter
-keep class com.google.ads.mediation.facebook.** { *; }

# Google Mobile Ads SDK rules
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# Flutter Google Mobile Ads plugin rules
-keep class io.flutter.plugins.googlemobileads.** { *; }

# Keep GMS and Firebase classes that might be used by AdMob
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }

# Keep common attributes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Optimization: Do not obfuscate classes used by JNI
-keepclasseswithmembernames class * {
    native <methods>;
}



