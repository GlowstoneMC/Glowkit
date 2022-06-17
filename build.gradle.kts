import org.gradle.api.tasks.testing.logging.TestExceptionFormat
import org.gradle.api.tasks.testing.logging.TestLogEvent
import io.papermc.paperweight.util.Git
import io.papermc.paperweight.patcher.tasks.PaperweightPatcherPrepareForDownstream

plugins {
    java
    `maven-publish`
    id("io.papermc.paperweight.patcher") version "1.3.7"
}

val javaVersion = 17

allprojects {
    apply(plugin = "java")
    apply(plugin = "maven-publish")

    java {
        toolchain {
            languageVersion.set(JavaLanguageVersion.of(javaVersion))
        }
    }
}

subprojects {
    tasks.withType<JavaCompile> {
        options.encoding = Charsets.UTF_8.name()
        options.release.set(javaVersion)
    }
    tasks.withType<Javadoc> {
        options.encoding = Charsets.UTF_8.name()

        if (JavaVersion.current().isJava9Compatible) {
            (options as StandardJavadocDocletOptions).addBooleanOption("html5", true)
        }

        exclude("**/*.xml")
    }
    tasks.withType<ProcessResources> {
        filteringCharset = Charsets.UTF_8.name()
    }
    tasks.withType<Test> {
        testLogging {
            showStackTraces = true
            exceptionFormat = TestExceptionFormat.FULL
            events(TestLogEvent.STANDARD_OUT)
        }
    }

    repositories {
        maven("https://repo.glowstone.net/repository/maven-public/")
        maven("https://repo.glowstone.net/repository/snapshots/")
        maven("https://repo.glowstone.net/repository/internal/")
    }
}

dependencies {
}

val paperDir = layout.projectDirectory.dir("work/Paper")
val initSubmodules by tasks.registering {
    outputs.upToDateWhen { false }
    doLast {
        Git(layout.projectDirectory)("submodule", "update", "--init").executeOut()
    }
}

val paperMavenPublicUrl = "https://papermc.io/repo/repository/maven-public/"

paperweight {
    mcDevSourceDir.set(layout.buildDirectory.dir("ignore"))

    remapRepo.set(paperMavenPublicUrl)
    decompileRepo.set(paperMavenPublicUrl)

    upstreams {
        register("paper") {
            upstreamDataTask {
                dependsOn(initSubmodules)
                projectDir.set(paperDir)
            }
            patchTasks {
                register("api") {
                    upstreamDir.set(paperDir.dir("Paper-API"))
                    patchDir.set(layout.projectDirectory.dir("Paper-API-Patches"))
                    outputDir.set(layout.projectDirectory.dir("Glowkit"))
                    importMcDev.set(false)
                }
            }
        }
    }
}

allprojects {
    publishing {
        repositories {
            maven("https://repo.glowstone.net/content/repositories/snapshots/") {
                name = "glowstone"
                credentials(PasswordCredentials::class)
            }
        }
    }
}

tasks.register("printMinecraftVersion") {
    doLast {
        println(providers.gradleProperty("mcVersion").get().trim())
    }
}

tasks.register("printGlowkitVersion") {
    doLast {
        println(project.version)
    }
}
