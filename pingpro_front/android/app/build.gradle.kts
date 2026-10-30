import java.util.Properties

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Clave de subida a Google Play: android/key.properties (fuera de git) dice
// dónde está el keystore y sus contraseñas. Sin ese archivo el release se firma
// con la clave de debug, para que el build siga funcionando en cualquier PC.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}

android {
    namespace = "com.pingpro.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        // flutter_local_notifications usa APIs de java.time también en
        // Android viejos: el desugaring las incluye en la app.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // Definitivo: Google Play no deja cambiarlo después de publicar.
        applicationId = "com.pingpro.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (!keystoreProperties.isEmpty) {
            create("upload") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName(if (keystoreProperties.isEmpty) "debug" else "upload")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
  // Fija las versiones de las librerías nativas de Firebase que traen los
  // plugins (firebase_core, firebase_auth). Sin productos propios: la app no
  // usa Analytics, que añadía permisos de ID de publicidad, mandaba eventos de
  // uso a Google y arrastraba un Guava con vulnerabilidades conocidas.
  implementation(platform("com.google.firebase:firebase-bom:34.2.0"))

  // Lo exige isCoreLibraryDesugaringEnabled (flutter_local_notifications).
  coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}