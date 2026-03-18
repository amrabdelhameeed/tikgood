import com.android.build.gradle.internal.dsl.BaseAppModuleExtension
import org.gradle.api.JavaVersion
import org.gradle.jvm.toolchain.JavaLanguageVersion

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics") // Firebase
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "id.amrabdelhameed.tikgood"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "id.amrabdelhameed.tikgood"
        minSdk = 24
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            storeFile = file("key.jks")
            storePassword = "123456"
            keyAlias = "key"
            keyPassword = "123456"
        }
    }

    buildTypes {
        release {
            isDebuggable = false
            isMinifyEnabled = false               // Disable R8 shrinking
            isShrinkResources = false             // Disable resource shrinking
            proguardFiles(
    getDefaultProguardFile("proguard-android-optimize.txt"),
    "proguard-rules.pro"
)                 // Clear ProGuard rules
            signingConfig = signingConfigs.getByName("release")
        }
// build.gradle.kts
debug {
    isMinifyEnabled = false      // ← this is the immediate fix
    isShrinkResources = false
}
    }
}

flutter {
    source = "../.."
}

dependencies {

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    implementation(platform("com.google.firebase:firebase-bom:33.1.2"))

    implementation("com.google.firebase:firebase-messaging") {
        exclude(group = "com.google.firebase", module = "firebase-iid")
    }

implementation("com.google.android.gms:play-services-auth:20.7.0") // last version with Credentials API
}

configurations.all {
    exclude(group = "com.google.firebase", module = "firebase-iid")
}


// Use Java Toolchain to specify JDK 17
java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(17))
    }
}

// Ensure Kotlin also uses the correct JDK
kotlin {
    jvmToolchain(17)
}


