# Règles ProGuard/R8 pour OnBuch.
# Activées uniquement si isMinifyEnabled = true dans build.gradle.kts.
# Conserve les classes des plugins natifs qui font de la réflexion / JNI.

# --- Flutter ---
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# --- Firebase (core + messaging / FCM push) ---
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# --- Google Play Billing (in_app_purchase) ---
-keep class com.android.vending.billing.** { *; }
-keep class com.android.billingclient.** { *; }

# --- Google Play Core (deferred components Flutter) ---
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# --- Syncfusion PDF viewer ---
-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

# --- Modèles avec sérialisation / annotations ---
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes SourceFile,LineNumberTable
