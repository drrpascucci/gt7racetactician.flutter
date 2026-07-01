import java.io.File

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "it.pasqc.gt7racetactician_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "25.2.9519653"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "it.pasqc.gt7racetactician_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

val localAppData =
    System.getenv("LOCALAPPDATA")
        ?: File(System.getProperty("user.home"), "AppData\\Local").absolutePath
val externalBuildRoot = File(localAppData, "gt7racetactician_flutter_build")
val flutterExpectedOutputsDir =
    File(rootProject.projectDir.parentFile, "build/app/outputs")

val copyFlutterOutputs by tasks.registering(Copy::class) {
    from(File(externalBuildRoot, "app/outputs"))
    into(flutterExpectedOutputsDir)
}

tasks.configureEach {
    if (name.startsWith("assemble") || name.startsWith("bundle")) {
        finalizedBy(copyFlutterOutputs)
    }
}
