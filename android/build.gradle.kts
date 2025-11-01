allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Match Flutter template exactly (helps Flutter locate flutter-apk output)
rootProject.buildDir = file("../build")
subprojects {
    project.buildDir = file("${rootProject.buildDir}/${project.name}")
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.buildDir)
}
