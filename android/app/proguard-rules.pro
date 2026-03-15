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

# Keep common attributes
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod


