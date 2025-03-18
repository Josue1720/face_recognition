plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ Required for Firebase
}

android {
    namespace = "com.example.face_recognition"
    compileSdk = 35 // ✅ Set to a fixed version if needed

    ndkVersion = "27.0.12077973"  // ✅ Required NDK version

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.face_recognition"
        minSdk = 23 // ✅ Manually set the minSdk version
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:33.10.0")) // ✅ Ensures Firebase dependencies use the same version

    // ✅ Add Firebase SDKs as needed (Example: Firebase Auth & Firestore)
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
}
