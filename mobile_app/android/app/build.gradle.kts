plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties

val hasGoogleServicesFile =
    file("google-services.json").exists() ||
    file("src/debug/google-services.json").exists() ||
    file("src/google-services.json").exists()

if (hasGoogleServicesFile) {
    apply(plugin = "com.google.gms.google-services")
} else {
    logger.lifecycle("google-services.json not found; building Android app without Google Services plugin.")
}

val localProperties = Properties().apply {
    val localPropertiesFile = rootProject.file("local.properties")
    if (localPropertiesFile.exists()) {
        localPropertiesFile.inputStream().use { load(it) }
    }
}

val generatedSecretsProperties = Properties().apply {
    val generatedSecretsFile = rootProject.file("secrets.properties")
    if (generatedSecretsFile.exists()) {
        generatedSecretsFile.inputStream().use { load(it) }
    }
}

val releaseSigningProperties = Properties().apply {
    val releaseSigningFile = rootProject.file("key.properties")
    if (releaseSigningFile.exists()) {
        releaseSigningFile.inputStream().use { load(it) }
    }
}

fun signingValue(key: String): String? {
    return releaseSigningProperties.getProperty(key)
        ?: project.findProperty(key) as String?
        ?: System.getenv(key)
}

val releaseStoreFile = signingValue("storeFile")
val releaseStorePassword = signingValue("storePassword")
val releaseKeyAlias = signingValue("keyAlias")
val releaseKeyPassword = signingValue("keyPassword")
val hasReleaseSigning =
    !releaseStoreFile.isNullOrBlank() &&
    !releaseStorePassword.isNullOrBlank() &&
    !releaseKeyAlias.isNullOrBlank() &&
    !releaseKeyPassword.isNullOrBlank()

val googleMapsApiKey = (
    generatedSecretsProperties.getProperty("GOOGLE_MAPS_API_KEY")
        ?: localProperties.getProperty("GOOGLE_MAPS_API_KEY")
        ?: localProperties.getProperty("googleMapsApiKey")
        ?: project.findProperty("GOOGLE_MAPS_API_KEY") as String?
        ?: System.getenv("GOOGLE_MAPS_API_KEY")
        ?: ""
)

android {
    namespace = "com.dealfinder.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973" // Updated to match plugin requirement

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.dealfinder.mobile"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["googleMapsApiKey"] = googleMapsApiKey
    }

    buildTypes {
        release {
            if (!hasReleaseSigning) {
                throw GradleException(
                    "Release signing is not configured. Add android/key.properties or provide storeFile, storePassword, keyAlias, and keyPassword.",
                )
            }
            signingConfig = signingConfigs.create("release") {
                storeFile = rootProject.file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.10.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-messaging")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

flutter {
    source = "../.."
}
