import java.io.File

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
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
