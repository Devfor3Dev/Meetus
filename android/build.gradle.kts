plugins {
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")

    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        val androidExt = project.extensions.findByName("android") as? com.android.build.gradle.BaseExtension
        val target = androidExt?.compileOptions?.targetCompatibility?.toString() ?: "17"
        val targetJvm = when (target) {
            "1.8", "8" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
            "11" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11
            "17" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            else -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
        }
        compilerOptions {
            jvmTarget.set(targetJvm)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
