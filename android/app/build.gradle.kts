import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// 릴리스 서명 값: android/key.properties(로컬, git 제외) 또는 환경 변수(CI). docs/release.md
// 키: storeFile, storePassword, keyAlias, keyPassword / 환경 변수: MULO_KEYSTORE_FILE, MULO_KEYSTORE_PASSWORD, MULO_KEY_ALIAS, MULO_KEY_PASSWORD
val keyProps = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
fun signingValue(prop: String, env: String): String? =
    keyProps.getProperty(prop)?.takeIf { it.isNotBlank() } ?: System.getenv(env)?.takeIf { it.isNotBlank() }
val releaseStoreFile = signingValue("storeFile", "MULO_KEYSTORE_FILE")
val releaseStorePassword = signingValue("storePassword", "MULO_KEYSTORE_PASSWORD")
val releaseKeyAlias = signingValue("keyAlias", "MULO_KEY_ALIAS")
val releaseKeyPassword = signingValue("keyPassword", "MULO_KEY_PASSWORD")
val hasReleaseSigning = listOf(releaseStoreFile, releaseStorePassword, releaseKeyAlias, releaseKeyPassword).all { it != null }
// 배포 빌드(CI)는 키가 없으면 debug 키로 몰래 서명하지 않고 실패시킨다.
val requireReleaseSigning = System.getenv("MULO_REQUIRE_RELEASE_SIGNING") == "true"

android {
    namespace = "com.mulo.app"
    // permission_handler 13이 API 37 이상으로 컴파일을 요구한다.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications가 java.time 등을 쓴다.
        isCoreLibraryDesugaringEnabled = true
    }

    // 에디션: lite는 서버 모드만, full은 로컬 엔진(youtubedl-android)을 APK에 넣는다.
    flavorDimensions += "edition"
    productFlavors {
        create("lite") { dimension = "edition" }
        create("full") { dimension = "edition" }
    }

    packaging {
        // youtubedl-android가 네이티브 라이브러리(파이썬 · yt-dlp)를 파일로 풀어 실행한다.
        jniLibs { useLegacyPackaging = true }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mulo.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = rootProject.file(releaseStoreFile!!).takeIf { it.exists() } ?: file(releaseStoreFile)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                if (requireReleaseSigning) {
                    throw GradleException("릴리스 서명 키가 없습니다 (MULO_KEYSTORE_* 환경 변수 또는 android/key.properties). docs/release.md")
                }
                // 키가 없는 로컬 빌드는 `flutter run --release`가 되도록 debug 키로 서명한다 (배포 금지).
                signingConfig = signingConfigs.getByName("debug")
            }
            // 용량: 코드 · 리소스를 줄인다. ABI 분할은 빌드 명령(`--split-per-abi`)으로 한다.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    // 네이티브 순수 규칙 단위 테스트 (MediaButtonPolicy).
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20240303") // 단위 테스트에서 안드로이드 org.json 대신 쓴다
    // 재생 엔진(ExoPlayer) · 미디어 세션 · 재생 알림 (PlaybackHub / MuloPlaybackService).
    implementation("androidx.media3:media3-exoplayer:1.7.1")
    implementation("androidx.media3:media3-session:1.7.1")
    // 미리 듣기가 HLS · DASH 재생 목록 주소도 틀 수 있게 (just_audio가 해 주던 일을 PreviewChannel이 한다).
    implementation("androidx.media3:media3-exoplayer-hls:1.7.1")
    implementation("androidx.media3:media3-exoplayer-dash:1.7.1")
    // 구독 채널의 새 영상을 주기적으로 확인 (NewVideoWorker).
    implementation("androidx.work:work-runtime-ktx:2.10.1")
    "fullImplementation"("io.github.junkfood02.youtubedl-android:library:0.18.1")
    // 받은 오디오를 mp3 · opus로 바꾸는 ffmpeg (APK에 네이티브로 들어간다).
    "fullImplementation"("io.github.junkfood02.youtubedl-android:ffmpeg:0.18.1")
}

flutter {
    source = "../.."
}
