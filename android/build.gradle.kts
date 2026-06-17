import java.io.File
import com.android.build.gradle.BaseExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val localAppData =
    System.getenv("LOCALAPPDATA")
        ?: File(System.getProperty("user.home"), "AppData\\Local").absolutePath
val externalBuildRoot = File(localAppData, "gt7racetactician_flutter_build")
val newBuildDir = rootProject.layout.dir(project.provider { externalBuildRoot })
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.map { it.dir(project.name) }
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    if (project.name != "app") {
        project.evaluationDependsOn(":app")
    }

    afterEvaluate {
        if (project.hasProperty("android")) {
            project.extensions.configure<com.android.build.gradle.BaseExtension>("android") {
                ndkVersion = "29.0.14206865"
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
    delete(File(rootProject.projectDir.parentFile, "build"))
}
