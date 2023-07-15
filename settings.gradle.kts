pluginManagement {
    repositories {
        gradlePluginPortal()
        maven("https://repo.papermc.io/repository/maven-public/")
    }
}

plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.4.0"
}

if (!file(".git").exists()) {
    val errorText = """
        
        =====================[ ERROR ]=====================
         The Glowkit project directory is not a properly cloned Git repository.
         
         In order to build Glowkit from source you must clone
         the Glowkit repository using Git, not download a code
         zip from GitHub.
         
         Built Glowkit jars are available for download at
         https://repo.glowstone.net/#browse/browse:snapshots:net%2Fglowstone%2Fglowkit
         
         See https://github.com/GlowstoneMC/Glowkit/wiki
         for further information on building and modifying Glowkit.
        ===================================================
    """.trimIndent()
    error(errorText)
}

rootProject.name = "glowkit"

include("glowkit")
