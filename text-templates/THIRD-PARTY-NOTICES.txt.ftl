[#--
    Copyright (C) 2020 The ORT Project Authors (see <https://github.com/oss-review-toolkit/ort-config/blob/main/NOTICE>)

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
    This template produces a third-party attribution notices document listing the SPDX license expressions,
    license texts and copyright statements of the analyzed projects and their dependencies. The
    output is plain text that uses reStructuredText section markup (titles underlined with '=' for
    the document, '-' for packages and '~' for the blocks within a package), so it can be read as-is
    or rendered to HTML/PDF with a reStructuredText processor such as docutils.

    Only licenses categorized as "include-in-notice-file" are shown. Excluded projects and packages,
    and packages without any notice-worthy license, are omitted. The document is structured as:

    1. A "Third-Party Notices" title.

    2. A projects section, introduced by "This software includes external packages and source
       code.". It merges the licenses and copyrights of all (non-excluded) projects into a single,
       de-duplicated list. Projects cannot have a concluded license, so LicenseView.ALL is used.

    3. A dependencies section, introduced by "This software depends on external packages and source
       code.", with one subsection per (non-excluded) package. Each package subsection contains:
         * a "Package <namespace>:<name>:<version>" heading, its "PURL:" and its effective "License:"
           expression (LicenseView.CONCLUDED_OR_DECLARED_AND_DETECTED);
         * a "License files for ..." block for each archived root license file, showing the verbatim
           file contents and the related copyright holders. Note that ORT only surfaces root-level
           license files here, so license files nested deeper in the source tree are not shown;
         * a "Copyrights for <license>" and a "License text(s) for <license>" block for every
           remaining concluded/declared/detected license that is not already covered by a license
           file above.

    Example (abridged; license texts truncated):

        Third-Party Notices
        ===============================================================================

        This software depends on external packages and source code.
        The applicable license information is listed below.


        Package aenum:3.1.16
        -------------------------------------------------------------------------------
        PURL: pkg:pypi/aenum@3.1.16
        License: BSD-3-Clause

        Copyrights for BSD-3-Clause
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        The following copyrights for aenum:3.1.16 correspond to the BSD-3-Clause license.

        Copyright (c) 2015-2018 Ethan Furman

        License text(s) for BSD-3-Clause
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        The following license text for aenum:3.1.16 corresponds to the BSD-3-Clause license.

        Redistribution and use in source and binary forms, ...


        Package click:8.4.2
        -------------------------------------------------------------------------------
        PURL: pkg:pypi/click@8.4.2
        License: BSD-3-Clause

        License files for click:8.4.2
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        This package contains the file click-8.3.3/LICENSE.txt with the following contents.

        Copyright 2014 Pallets ...

        Copyrights for BSD-3-Clause
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        The following copyrights for click:8.4.2 correspond to the BSD-3-Clause license.

        Copyright 2001-2006 Gregory P. Ward
        Copyright 2014 Pallets
        Copyright 2002-2006 Python Software Foundation

        License text for BSD-3-Clause
        ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

        The following license text for click:8.4.2 corresponds to the BSD-3-Clause license.
--]
Third-Party Notices
===============================================================================
[#assign noticeCategoryName = "include-in-notice-file"]
[#-- Add the licenses of the projects. --]
[#assign hasNoticeProjectLicenses = false]
[#--
    Merge the licenses and copyrights of all projects into a single list. The default LicenseView.ALL is used because
    projects cannot have a concluded license (compare with the handling of packages below).
--]
[#assign mergedLicenses = helper.mergeLicenses(projects)]
[#-- Filter for those licenses that are categorized to be included in notice files. --]
[#assign filteredLicenses = helper.filterForCategory(mergedLicenses, noticeCategoryName)]
[#list filteredLicenses as resolvedLicense]
    [#assign licenseName = resolvedLicense.license.simpleLicense()]
    [#assign licenseText = licenseFactProvider.getLicenseText(licenseName)!]
    [#if !licenseText?has_content][#continue][/#if]
    [#if !hasNoticeProjectLicenses]

This software includes external packages and source code.
The applicable license information is listed below.

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
        [#assign hasNoticeProjectLicenses = true]
    [#else]
  --
    [/#if]
    [#assign copyrights = resolvedLicense.getCopyrights()]
    [#if copyrights?has_content]

    [/#if]
${copyrights?join("\n", "", "\n")}
${licenseText}
    [#assign exceptionName = resolvedLicense.license.exception()!]
    [#assign exceptionText = licenseFactProvider.getLicenseText(exceptionName)!]
    [#if exceptionText?has_content]
${exceptionText}
    [/#if]
[/#list]
[#-- Add the licenses of all packages. --]
[#if packages?has_content]
    [#if hasNoticeProjectLicenses]
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    [/#if]

This software depends on external packages and source code.
The applicable license information is listed below.

[/#if]
[#--
    Render the package heading with its name, PURL and effective license. Called wherever the
    heading is first emitted, so that packages with archived license files and packages without
    both show the PURL and license directly below the heading.
--]
[#macro packageHeading]
Package ${packageCoordinates}
-------------------------------------------------------------------------------
PURL: ${packagePurl}
    [#if packageLicense?has_content]
License: ${packageLicense}
    [/#if]
    [#--
        List the license choices that were applied to resolve the effective license above. A single choice is shown
        inline after "License choice:"; when more than one choice was applied they are listed one per line under
        "License choices:" so the block stays readable. Each choice renders as "<given> — selected: <choice>", or just
        "<choice>" when the choice was applied to the whole license expression (i.e. it has no specific sub-expression).
        The block is omitted when no choices were applied.
    --]
    [#if appliedLicenseChoices?has_content]
        [#if (appliedLicenseChoices?size > 1)]
License choices:
            [#list appliedLicenseChoices as licenseChoice]
  [#if licenseChoice.given??]${licenseChoice.given} — selected: ${licenseChoice.choice}[#else]${licenseChoice.choice}[/#if]
            [/#list]
        [#else]
            [#assign licenseChoice = appliedLicenseChoices?first]
License choice: [#if licenseChoice.given??]${licenseChoice.given} — selected: ${licenseChoice.choice}[#else]${licenseChoice.choice}[/#if]
        [/#if]
    [/#if]
[/#macro]
[#list packages?filter(p -> !p.excluded) as package]
    [#assign hasNoticePackageLicenses = false]
    [#assign packageCoordinates][#if package.id.namespace?has_content]${package.id.namespace}:[/#if]${package.id.name}:${package.id.version}[/#assign]
    [#assign packagePurl = helper.getPackage(package.id).purl]
    [#assign filteredLicenseInfo = package.license.filterExcluded()]
    [#--
        Resolve the effective license together with the license choices that were applied to obtain it.
        effectiveLicenseAndAppliedChoices() returns a (SpdxExpression?, List<SpdxLicenseChoice>) pair: the first element
        is the effective license (identical to what effectiveLicense() would return), the second is the subset of the
        configured package and repository license choices that were actually applied for this package. Both are computed
        from the excluded-filtered license info so the "License:" and "License choices:" lines stay consistent.
    --]
    [#assign effectiveLicenseAndChoices = filteredLicenseInfo.effectiveLicenseAndAppliedChoices(
        LicenseView.CONCLUDED_OR_DECLARED_AND_DETECTED,
        package.licenseChoices
    )]
    [#assign effectiveLicense = effectiveLicenseAndChoices.first!]
    [#assign appliedLicenseChoices = effectiveLicenseAndChoices.second]
    [#if effectiveLicense?has_content]
        [#assign packageLicense = effectiveLicense.sorted()]
    [#else]
        [#assign packageLicense = ""]
    [/#if]
    [#-- List the content of archived license files and associated copyrights. --]
    [#list package.licenseFiles.files as licenseFile]
        [#if !hasNoticePackageLicenses]

[@packageHeading/]
            [#assign hasNoticePackageLicenses = true]
        [/#if]

License files for ${packageCoordinates}
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

This package contains the file ${licenseFile.path} with the following contents.

${licenseFile.text}
        [#assign copyrights = licenseFile.getCopyrights()]
        [#if copyrights?has_content]
The following copyright holder information relates to the license(s) above.

${copyrights?join("\n", "")}
        [/#if]
    [/#list]
    [#--
        Filter the licenses of the package using LicenseView.CONCLUDED_OR_DECLARED_AND_DETECTED. This is the default
        view which ignores declared and detected licenses if a license conclusion for the package was made. If
        copyrights were detected for a concluded license those statements are kept. Also filter all licenses that
        are configured not to be included in notice files, and filter all licenses that are contained in the license
        files already printed above.
    --]
    [#assign resolvedLicenseInfo = LicenseView.CONCLUDED_OR_DECLARED_AND_DETECTED.filter(filteredLicenseInfo, package.licenseChoices)]
    [#assign resolvedLicenses = helper.filterForCategory(
        package.licensesNotInLicenseFiles(resolvedLicenseInfo.licenses, true),
        noticeCategoryName
    )]
    [#assign isFirst = true]
    [#list resolvedLicenses as resolvedLicense]
        [#assign singleLicenseExpression = resolvedLicense.license.toString()]
        [#assign licenseTexts = licenseFactProvider.getLicenseTextsString(singleLicenseExpression, package.id)!]
        [#if !licenseTexts?has_content][#continue][/#if]
        [#if isFirst]
            [#if !hasNoticePackageLicenses]

[@packageHeading/]
                [#assign hasNoticePackageLicenses = true]
            [/#if]
            [#assign isFirst = false]
        [/#if]
        [#assign copyrights = resolvedLicense.getCopyrights()]
        [#if copyrights?has_content]

Copyrights for ${singleLicenseExpression}
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The following copyrights for ${packageCoordinates} correspond to the ${singleLicenseExpression} license.

${copyrights?join("\n", "", "\n")}
        [/#if]
        [#list licenseTexts as licenseText]
License text for ${singleLicenseExpression}
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The following license text for ${packageCoordinates} corresponds to the ${singleLicenseExpression} license.

${licenseText}
        [/#list]
    [/#list]
[/#list]
