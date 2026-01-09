package org.ossreviewtoolkit.tools.curations

import org.gradle.api.DefaultTask
import org.gradle.api.logging.Logging
import org.ossreviewtoolkit.model.Identifier
import org.ossreviewtoolkit.model.PackageCuration
import org.ossreviewtoolkit.model.PackageCurationData
import org.ossreviewtoolkit.model.SourceCodeOrigin
import org.ossreviewtoolkit.model.VcsInfoCurationData
import org.ossreviewtoolkit.model.config.PackageConfiguration
import org.ossreviewtoolkit.utils.common.encodeOr
import org.semver4j.Semver

import java.io.File

// Matches Ivy version range 1.0.+, 1.1+ but does not match
// 0.9.34+deprecated, 0.11.1+wasi-snapshot-preview1, 0.14.2+wasi-0.2.4
private val ivyPrefixMatcherRegex =
    Regex("""^\d+(?:\.\d+)*\.?\+$""")

// Matches Ivy version range [1.0,2.0], [1.0,2.0[, ]1.0,2.0], ]1.0,2.0[,
// [1.0,), ]1.0,), (,2.0], (,2.0[
private val ivyRangeMatcherRegex =
    Regex("""^[\[\]\(]\s*[A-Za-z0-9._-]*\s*,\s*[A-Za-z0-9._-]*\s*[\]\[\)]$""")

// Explicit "number+qualifier" pattern that must NOT be treated as a matcher
// e.g. 0.9.34+deprecated, 0.11.1+wasi-snapshot-preview1, 0.14.2+wasi-0.2.4
private val numericWithPlusQualifierRegex =
    Regex("""^\d+(?:\.\d+)*\+[A-Za-z0-9._-]+$""")

private val logger = Logging.getLogger("utils")
private val versionRegex = Regex("^v?\\d+\\.\\d+\\.\\d+\$")

val DefaultTask.curationsDir: File
    get() = project.rootDir.resolve("../../curations")

val DefaultTask.packageConfigurationsDir: File
    get() = project.rootDir.resolve("../../package-configurations")

fun Identifier.toCurationPath() =
    "${type.encodeOr("_")}/${namespace.encodeOr("_")}/${name.encodeOr("_")}.yml"

fun List<PathCurationData>.toPathCurations(): List<PackageCuration> {
    var lastPath = ""

    // Group subsequent versions which belong to the same path.
    val grouped = sortedBy { Semver.coerce(it.tag.removePrefix("v")) }
        .fold(mutableListOf<MutableList<PathCurationData>>()) { acc, cur ->
            if (cur.path != lastPath) {
                acc.add(mutableListOf())
            }
            lastPath = cur.path
            acc.apply { last() += cur }
        }

    return grouped.mapIndexed { index, curations ->
        val firstVersion = curations.first().tag.removePrefix("v")
        val lastVersion = curations.last().tag.removePrefix("v")

        val versionRange = when {
            index == grouped.size - 1 -> "[$firstVersion,)"
            firstVersion == lastVersion -> firstVersion
            else -> "[$firstVersion,$lastVersion]"
        }

        val id = curations.first().id.copy(version = versionRange)
        val path = curations.first().path

        logger.quiet("Creating path curation for id=${id.toCoordinates()} path=$path.")

        PackageCuration(
            id = id.copy(version = versionRange),
            data = PackageCurationData(
                comment = "Set the VCS path of the module inside the multi-module repository.",
                vcs = VcsInfoCurationData(
                    path = path
                )
            )
        )
    }
}

fun PackageConfiguration.expectedPath(): String {
    val basePath = "${id.type.encodeOr("_")}/${id.namespace.encodeOr("_")}/${id.name.encodeOr("_")}"

    val filename = when {
        sourceCodeOrigin == SourceCodeOrigin.ARTIFACT -> "source-artifact.yml"
        sourceCodeOrigin == SourceCodeOrigin.VCS || vcs != null -> "vcs.yml"
        else -> "source-artifact.yml"
    }

    val versionSegment = if (id.version.hasVersionIvyRanges()) {
        ""
    } else {
        "/${id.version.replace("%25", "%").encodeOr("_")}"
    }

    return "$basePath$versionSegment/$filename"
}

fun String.hasVersionIvyRanges(): Boolean {
    // Exclude forms like 0.9.34+deprecated, 0.11.1+wasi-snapshot-preview1, 0.14.2+wasi-0.2.4
    if (numericWithPlusQualifierRegex.matches(this)) {
        return false
    }

    // Prefix matchers: 1.0.+, 1.1+
    if (ivyPrefixMatcherRegex.matches(this)) {
        return true
    }

    // Range matchers: [1.0,2.0], [1.0,2.0[, ]1.0,2.0], ]1.0,2.0[, [1.0,), ]1.0,), (,2.0], (,2.0[
    if (ivyRangeMatcherRegex.matches(this)) {
        return true
    }

    return false
}

fun String.hasVersionRangeIndicators() = versionRangeIndicators.any { contains(it, ignoreCase = true) }

fun String.isVersion() = matches(versionRegex)

private val versionRangeIndicators = listOf(",", "~", "*", "+", ">", "<", "=", " - ", "^", ".x", "||")
