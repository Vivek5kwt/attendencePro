import org.gradle.api.tasks.compile.JavaCompile

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
}

subprojects {
    if (name == "flutter_local_notifications") {
        tasks.withType<JavaCompile>().configureEach {
            doFirst {
                val pluginSource = project.projectDir.resolve(
                    "src/main/java/com/dexterous/flutterlocalnotifications/FlutterLocalNotificationsPlugin.java"
                )
                if (pluginSource.exists()) {
                    // Android 14's new BigPictureStyle#bigLargeIcon overload that accepts an Icon
                    // makes the original call with a null argument ambiguous. Patch the generated
                    // plugin source before compilation so that the call is explicitly routed to the
                    // Bitmap overload, matching the behaviour on older Android versions.
                    val target = "bigPictureStyle.bigLargeIcon(null);"
                    val replacement = "bigPictureStyle.bigLargeIcon((Bitmap) null);"
                    val originalContent = pluginSource.readText()
                    if (originalContent.contains(target) && !originalContent.contains(replacement)) {
                        pluginSource.writeText(originalContent.replace(target, replacement))
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
