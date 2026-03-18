# ==============================
# Flutter
# ==============================
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugins.** { *; }

# ==============================
# Firebase
# ==============================
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# MLKit (Fix FirebaseInstanceId reference)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# ==============================
# Google Play Services (Auth + Credentials API)
# ==============================
-keep class com.google.android.gms.auth.api.credentials.** { *; }
-keep class com.google.android.gms.auth.api.identity.** { *; }
-keep class com.google.android.gms.tasks.** { *; }

-dontwarn com.google.android.gms.**

# ==============================
# Play Core
# ==============================
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# ==============================
# AndroidX
# ==============================
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# ==============================
# Retrofit
# ==============================
-keepattributes Signature
-keepattributes *Annotation*

-keep,allowobfuscation,allowshrinking interface retrofit2.Call
-keep,allowobfuscation,allowshrinking class retrofit2.Response

# ==============================
# Gson
# ==============================
-dontwarn sun.misc.**

-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ==============================
# Keep native methods
# ==============================
-keepclassmembers class * {
    native <methods>;
}

# ==============================
# Keep Exceptions
# ==============================
-keep public class * extends java.lang.Exception

# ==============================
# Keep debugging metadata for Crashlytics
# ==============================
-keepattributes SourceFile,LineNumberTable
# Suppress missing FirebaseInstanceId (removed in Firebase BOM 32+, referenced by old MLKit)
-dontwarn com.google.firebase.iid.**
-dontwarn com.google.firebase.iid.FirebaseInstanceId

# Fix missing Credentials API classes (used by smart_auth plugin)
-dontwarn com.google.android.gms.auth.api.credentials.**
-keep class com.google.android.gms.auth.api.credentials.** { *; }