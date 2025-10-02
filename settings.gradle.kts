rootProject.name = "ORT Scripting Environment"

dependencyResolutionManagement {
    repositories {
        mavenCentral()
    }

    versionCatalogs {
        create("ortLibs") {
            from("org.ossreviewtoolkit:version-catalog:69.1.0")
        }
    }
}
