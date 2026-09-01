plugins {
    id("com.android.application")
}

android {
    namespace = "com.ftrakademi.preview3"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.ftrakademi.preview3"
        minSdk = 23
        targetSdk = 36
        versionCode = 29
        versionName = "2.4"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.18.0"))
    implementation("com.google.firebase:firebase-messaging")
}
