import org.ossreviewtoolkit.tools.config.helper.GenerateAspNetCoreCurationsTask
import org.ossreviewtoolkit.tools.config.helper.GenerateAwsSdkForNetCurationsTask
import org.ossreviewtoolkit.tools.config.helper.GenerateAzureSdkForNetCurationsTask
import org.ossreviewtoolkit.tools.config.helper.GenerateDotNetRuntimeCurationsTask
import org.ossreviewtoolkit.tools.config.helper.GenerateLicenseClassificationsTask
import org.ossreviewtoolkit.tools.config.helper.VerifyPackageConfigurationsTask
import org.ossreviewtoolkit.tools.config.helper.VerifyPackageCurationsTask

tasks {
    register<GenerateLicenseClassificationsTask>("generateLicenseClassifications")
    register<GenerateAspNetCoreCurationsTask>("generateAspNetCoreCurations")
    register<GenerateAzureSdkForNetCurationsTask>("generateAzureSdkForNetCurations")
    register<GenerateAwsSdkForNetCurationsTask>("generateAwsSdkForNetCurations")
    register<GenerateDotNetRuntimeCurationsTask>("generateDotNetRuntimeCurations")

    register<VerifyPackageConfigurationsTask>("verifyPackageConfigurations")
    register<VerifyPackageCurationsTask>("verifyPackageCurations")

    register("verify") {
        group = "verification"

        setDependsOn(this@tasks.filter { it.group == "verification" && it != this })
    }
}
