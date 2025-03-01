#!/usr/bin/env kotlin

// SPDX-FileCopyrightText: 2024 The ORT Project Authors (see <https://github.com/oss-review-toolkit/ort/blob/main/NOTICE>)
// SPDX-License-Identifier: Apache-2.0

@file:CompilerOptions("-jvm-target", "11")
@file:DependsOn("org.ossreviewtoolkit:model:22.0.0")

import com.fasterxml.jackson.module.kotlin.readValue

import kotlin.system.exitProcess

import org.ossreviewtoolkit.model.Identifier
import org.ossreviewtoolkit.model.PackageCuration
import org.ossreviewtoolkit.model.mapper
import org.ossreviewtoolkit.utils.common.encodeOr
import org.ossreviewtoolkit.utils.spdx.SpdxExpression

import org.semver4j.RangesListFactory

private var fileCount = 0
private var curationCount = 0
private val issues = mutableListOf<String>()

private fun String.hasVersionRangeIndicators() = versionRangeIndicators.any { contains(it, ignoreCase = true) }
private val versionRangeIndicators = listOf(",", "~", "*", "+", ">", "<", "=", " - ", "^", ".x", "||")

fun Identifier.toCurationPath() =
    "${type.encodeOr("_")}/${namespace.encodeOr("_")}/${name.encodeOr("_")}.yml"

private val curationsDir = __FILE__.parentFile.resolve("../curations")

curationsDir.walk().filter { it.isFile }.forEach { file ->
    fileCount++

    val relativePath = file.relativeTo(curationsDir).invariantSeparatorsPath

    runCatching {
        if (file.extension != "yml") {
            issues += "The file '$relativePath' does not use the expected extension '.yml'."
        }

        val curations = file.mapper().readValue<List<PackageCuration>>(file)

        curationCount += curations.size

        if (curations.isEmpty()) {
            issues += "The file '$relativePath' does not contain any curations."
        }

        curations.forEach { curation ->
            val version = curation.id.version
            if (version.isNotBlank() && version.hasVersionRangeIndicators()) {
                val range = RangesListFactory.create(version)
                if (range.get().size == 0) {
                    issues += "The version of package '${curation.id.toCoordinates()}' in file " +
                            "'$relativePath' contains version range indicators, but cannot be parsed to a " +
                            "valid version range."
                }
            }

            if (curation.data.authors != null) {
                issues += "Curating authors is not allowed, but the curation for package " +
                        "'${curation.id.toCoordinates()}' in file '$relativePath' sets the authors to " +
                        "'${curation.data.authors}'."
            }

            if (curation.data.concludedLicense != null) {
                issues += "Curating concluded licenses is not allowed, but the curation for package " +
                        "'${curation.id.toCoordinates()}' in file '$relativePath' sets the concluded license " +
                        "to '${curation.data.concludedLicense}'."
            }

            curation.data.declaredLicenseMapping.forEach { (source, target) ->
                runCatching {
                    target.validate(SpdxExpression.Strictness.ALLOW_CURRENT)
                }.onFailure {
                    issues += "The declared license mapping for package '${curation.id.toCoordinates()}' in " +
                            "file '$relativePath' maps '$source' to '$target', but '$target' is not a valid " +
                            "SPDX license expression: ${it.message}"
                }
            }

            val expectedPath = curation.id.toCurationPath()
            if (relativePath != expectedPath) {
                issues += "The curation for package '${curation.id.toCoordinates()}' is in the wrong file " +
                        "'$relativePath'. The expected file is '$expectedPath'."
            }
        }
    }.onFailure { e ->
        issues += "Could not parse curations from file '$relativePath': ${e.message}"
    }
}

if (issues.isNotEmpty()) {
    println(
        "Found ${issues.size} curation issue(s) in $fileCount package curation file(s) containing " +
                "$curationCount curation(s):\n${issues.joinToString("\n")}"
    )

    exitProcess(1)
} else {
    println(
        "Successfully verified $fileCount package curation file(s) containing $curationCount curation(s)."
    )

    exitProcess(0)
}
