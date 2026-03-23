##──────────────────────────────────────────
## Flutter Core
##──────────────────────────────────────────
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.plugin.common.** { *; }
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-dontwarn io.flutter.**

##──────────────────────────────────────────
## JNI / Native Methods (media_kit needs this)
##──────────────────────────────────────────
-keepclasseswithmembernames class * {
    native <methods>;
}

##──────────────────────────────────────────
## media_kit
##──────────────────────────────────────────
-keep class com.alexmercerind.media_kit.** { *; }
-keep class com.alexmercerind.media_kit_video.** { *; }
-keep class com.alexmercerind.media_kit_libs_android_video.** { *; }
-keep class com.alexmercerind.pdf.** { *; }

##──────────────────────────────────────────
## Firebase
##──────────────────────────────────────────
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

##──────────────────────────────────────────
## Kotlin
##──────────────────────────────────────────
-keepclassmembers class kotlin.Metadata { *; }
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlin.**

##──────────────────────────────────────────
## Your App Package
##──────────────────────────────────────────
-keep class id.amrabdelhameed.tikgood.** { *; }

##──────────────────────────────────────────
## Accessibility Service (TikTokInterceptService)
##──────────────────────────────────────────
-keep public class * extends android.accessibilityservice.AccessibilityService
-keepclassmembers class * extends android.accessibilityservice.AccessibilityService {
    public *;
}

##──────────────────────────────────────────
## Android Components (always keep)
##──────────────────────────────────────────
-keep public class * extends android.app.Activity
-keep public class * extends android.app.Service
-keep public class * extends android.content.BroadcastReceiver
-keep public class * extends android.content.ContentProvider

##──────────────────────────────────────────
## Gson / JSON
##──────────────────────────────────────────
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

##──────────────────────────────────────────
## Play Core
##──────────────────────────────────────────
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

##──────────────────────────────────────────
## OkHttp / Retrofit (if used by plugins)
##──────────────────────────────────────────
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn retrofit2.**