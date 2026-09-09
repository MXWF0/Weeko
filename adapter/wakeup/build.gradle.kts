plugins {
    alias(libs.plugins.android.library)
}

android {
    namespace = "io.github.mxwf.weeko.adapter.wakeup"
    compileSdk = 36

    defaultConfig {
        minSdk = 26
    }
}

dependencies {
    implementation(libs.gson)
    testImplementation(libs.junit)
}
