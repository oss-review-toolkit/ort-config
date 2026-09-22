[#--
    Copyright (C) 2026 The ORT Project Authors (see <https://github.com/oss-review-toolkit/ort-config/blob/main/NOTICE>)

    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        https://www.apache.org/licenses/LICENSE-2.0

    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

    SPDX-License-Identifier: Apache-2.0
    License-Filename: LICENSE
--]
[#--
    This template renders the "Package Information" of an SPDX Lite document (the lightweight SPDX
    profile defined by the OpenChain Japan Work Group) as a CSV file — one row per non-excluded
    package (dependency). The columns are the SPDX Lite package fields; each value is mapped from the
    ORT model the same way ORT's own SPDX reporter maps it:

      * SPDX Identifier           -> "SPDXRef-Package-" + the package coordinates, with any character
                                     that is not a letter, digit, '.' or '-' replaced by '-'.
      * Package Name / Version    -> the package identifier's name and version.
      * Package Supplier          -> "Person: <authors>" or NOASSERTION.
      * Package Download Location -> source artifact URL, else VCS (<type>+<url>@<revision>), else
                                     binary artifact URL, else NOASSERTION.
      * Package Home Page         -> the package homepage URL or NOASSERTION.
      * External Reference        -> "PACKAGE-MANAGER purl <purl>" for the package's Package URL (purl),
                                     or empty when the package has no purl.
      * Concluded License         -> the package's explicitly concluded license (from a package
                                     curation) or NOASSERTION.
      * Declared License          -> the processed declared license expression or NOASSERTION.
      * Comments on License       -> SPDX Lite field L2.11 (spec 7.16, PackageLicenseComments):
                                     "effectiveLicense: <expression>", the license ORT resolves for the
                                     package (LicenseView.CONCLUDED_OR_DECLARED_AND_DETECTED with
                                     license choices applied, excluded findings filtered out, sorted),
                                     or "effectiveLicense: NONE". This mirrors how ORT's own SPDX
                                     reporter records the effective license in PackageLicenseComments.
      * Copyright Text            -> the newline-separated, non-excluded copyright statements or NONE.
--]
[#-- Quote an arbitrary value as a single RFC 4180 CSV field. --]
[#function csv value][#return '"' + '${value}'?replace('"', '""') + '"'][/#function]
"SPDX Identifier","Package Name","Package Version","Package Supplier","Package Download Location","Package Home Page","External Reference","Concluded License","Declared License","Comments on License","Copyright Text"
[#list packages?filter(p -> !p.excluded) as package]
    [#assign pkg = helper.getPackage(package.id)]
    [#assign filteredLicenseInfo = package.license.filterExcluded()]
    [#assign effectiveLicense = filteredLicenseInfo.effectiveLicense(
        LicenseView.CONCLUDED_OR_DECLARED_AND_DETECTED,
        package.licenseChoices
    )!]
    [#assign spdxId = "SPDXRef-Package-" + package.id.toCoordinates()?replace("[^0-9A-Za-z.-]", "-", "r")]
    [#assign supplier][#if pkg.authors?has_content]Person: ${pkg.authors?join(", ")}[#else]NOASSERTION[/#if][/#assign]
    [#assign downloadLocation][#if pkg.sourceArtifact.url?has_content]${pkg.sourceArtifact.url}[#elseif pkg.vcsProcessed.url?has_content]${"${pkg.vcsProcessed.type}"?lower_case}+${pkg.vcsProcessed.url}[#if pkg.vcsProcessed.revision?has_content]@${pkg.vcsProcessed.revision}[/#if][#elseif pkg.binaryArtifact.url?has_content]${pkg.binaryArtifact.url}[#else]NOASSERTION[/#if][/#assign]
    [#assign homepage][#if pkg.homepageUrl?has_content]${pkg.homepageUrl}[#else]NOASSERTION[/#if][/#assign]
    [#assign externalRef][#if pkg.purl?has_content]PACKAGE-MANAGER purl ${pkg.purl}[/#if][/#assign]
    [#assign concludedLicense][#if pkg.concludedLicense??]${pkg.concludedLicense}[#else]NOASSERTION[/#if][/#assign]
    [#assign declaredLicense][#if pkg.declaredLicensesProcessed.spdxExpression??]${pkg.declaredLicensesProcessed.spdxExpression}[#else]NOASSERTION[/#if][/#assign]
    [#assign licenseComments][#if effectiveLicense?has_content]effectiveLicense: ${effectiveLicense.sorted()}[#else]effectiveLicense: NONE[/#if][/#assign]
    [#assign copyrights = package.license.getCopyrights()]
    [#assign copyrightText][#if copyrights?has_content]${copyrights?sort?join("\n")}[#else]NONE[/#if][/#assign]
${csv(spdxId)},${csv(package.id.name)},${csv(package.id.version)},${csv(supplier)},${csv(downloadLocation)},${csv(homepage)},${csv(externalRef)},${csv(concludedLicense)},${csv(declaredLicense)},${csv(licenseComments)},${csv(copyrightText)}
[/#list]
