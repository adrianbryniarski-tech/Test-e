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

// AGP 8+ wymaga `namespace` w każdym Android module. Starsze pluginy
// (m.in. vosk_flutter_2 1.0.5 — ostatnio wydany 2 lata temu, nie będzie
// fix'a) tego nie deklarują. Patchujemy w runtime: jak plugin Android
// library nie ma namespace, ustawiamy go na "com.<nazwa_pluginu>".
//
// MUSI być PRZED `subprojects { evaluationDependsOn(":app") }` poniżej
// — tamto forsuje eager ewaluację subprojektów, a wtedy `afterEvaluate`
// rzuca "Cannot run afterEvaluate when project already evaluated".
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExt = project.extensions.findByName("android")
            if (androidExt is com.android.build.gradle.LibraryExtension &&
                androidExt.namespace == null
            ) {
                androidExt.namespace = "com.${project.name.replace("-", "_")}"
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
