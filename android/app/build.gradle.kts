import java.util.Properties
import java.io.FileInputStream

// Load keystore properties for signing
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.assisted.nepika"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.assisted.nepika"
        minSdk = 23
        targetSdk = 34
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Disable features that aren't needed
    buildFeatures {
        buildConfig = true
        aidl = false
        renderScript = false
        shaders = false
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

// Properly handle deep link extraction tasks
tasks.whenTaskAdded {
    if (name.contains("extractDeepLinks")) {
        // Create empty navigation.json before the task runs
        doFirst {
            val navigationJsonDir = project.layout.buildDirectory.dir(
                "intermediates/navigation_json/${name.replace("extractDeepLinks", "").replaceFirstChar { it.lowercase() }}/extractDeepLinks${name.replace("extractDeepLinks", "")}"
            ).get().asFile
            navigationJsonDir.mkdirs()
            val navigationJsonFile = File(navigationJsonDir, "navigation.json")
            if (!navigationJsonFile.exists()) {
                navigationJsonFile.writeText("{}")
            }
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:32.2.0")) // compatible
    implementation("com.google.firebase:firebase-messaging-ktx")
    implementation("com.google.firebase:firebase-analytics-ktx")

    // Google Play Billing for In-App Purchases
    implementation("com.android.billingclient:billing:6.0.1")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

