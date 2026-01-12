# ORT Config Helper

This Gradle project contains tasks to help you manage the contents of the ort-config repository.

## Available commands

### Check all package curations

To verify that all package curations in the `curations` directory adhere to the rules of this repository, run:

```
./gradlew verifyPackageCurations
```

### Check all package configurations

To verify that all package curations in the `package-configurations` directory adhere to the rules of this repository, run:

```
./gradlew verifyPackageConfigurations
```

### Checking ort-config pull requests

Both of the above commands are used to check every pull request made
to the ort-config repository, see the [.github/workflows/verification.yml](../../.github/workflows/verification.yml) for implementation details.

### Generate license classifications

To generate the `license-classifications.yml` from ScanCode's license database available hosted at
[scancode-licensedb.aboutcode.org](https://scancode-licensedb.aboutcode.org), run:

```
./gradlew generateLicenseClassifications
```

### Generating VCS path curations

This Gradle project contains several taks that use heuristics to
generate VCS path curations for packages from large multi-module repositories which are tedious which would otherwise be tedious to write by hand.

At this time all generation tasks use the GitHub API and therefore require your GitHub user name and [token][github-token] which need to be passed as Gradle properties.

💡 To not add your GitHub token to your shell history, it is recommended to put it into an environment variable.

#### Generate VCS path curations for ASP.NET Core

To generate curations for each tag found within [github.com/dotnet/aspnetcore](https://github.com/dotnet/aspnetcore), run:

```
./gradlew -P githubUsername=<your username> -P githubToken=<your GitHub API token> generateAspNetCoreCurations
```

####  Generate VCS path curations for AWS SDK for .NET Runtime

To  generate curations for each tag found within [github.com/aws/aws-sdk-net](https://github.com/aws/aws-sdk-net), run:

```
./gradlew -P githubUsername=<your username> -P githubToken=<your GitHub API token> generateAwsSdkForNetCurations
```

####  Generate VCS path curations for Azure SDK for .NET

To generate curations for each tag found within [github.com/azure/azure-sdk-for-net](https://github.com/azure/azure-sdk-for-net), run:

```
./gradlew -P githubUsername=<your username> -P githubToken=<your GitHub API token> generateAzureSdkForNetCurations
```

####  Generate VCS path curations for .NET Runtime

To generate curations for each tag found within [github.com/dotnet/runtime](https://github.com/dotnet/runtime), run:

```
./gradlew -P githubUsername=<your username> -P githubToken=<your GitHub API token> generateDotNetRuntimeCurations
```

## Something missing?

If you find issues with this Gradle project or have suggestions for improvements, please [file an issue][ort-config-github-issues] for us, send a message in the *general* channel on our [Slack][ort-slack] or join us at the next [ORT weekly community meeting][ort-weekly-meeting].

[github-token]: https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/managing-your-personal-access-tokens
[ort-config-github-issues]: https://github.com/oss-review-toolkit/ort-config/issues
[ort-slack]: http://slack.oss-review-toolkit.org/
[ort-weekly-meeting]: https://github.com/oss-review-toolkit/ort/wiki/ORT-Weekly-Meeting
