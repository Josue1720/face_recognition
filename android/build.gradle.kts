// ✅ Project-level build.gradle.kts
plugins {
    // Add the Google services Gradle plugin
    id("com.google.gms.google-services") version "4.4.2" apply false
}

buildscript {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal() // ✅ Ensure this is included
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.1.3") // ✅ Required for Android build
    }
}

allprojects {
    repositories {
        google()          // ✅ Firebase requires Google repository
        mavenCentral()
    }
}

// ✅ Fix for Build Directory Issues
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
