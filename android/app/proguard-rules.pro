# Keep Flutter classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugin.** { *; }

# Keep generated plugin registrant
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }

# Firebase: keep messages & annotations
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep Kotlin metadata
-keepclassmembers class kotlin.Metadata { *; }

# Keep your package classes if reflection used
-keep class id.amrabdelhameed.tikgood.** { *; }

# Keep JSON serializers (if any)
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# MediaKit and pdf may use reflection
-keep class com.alexmercerind.media_kit.** { *; }
-keep class com.alexmercerind.pdf.** { *; }

-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**