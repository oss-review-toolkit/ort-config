[#--
    Renders a GitHub-flavored Markdown summary of an ORT CI run, intended for a GitHub Actions job
    summary or a PR comment. It has two layouts, selected by the run verdict:

      * a compact "succeeded" view (or "succeeded with warnings"), and
      * a detailed "failed" view that additionally lists the open rule violations, issues and
        vulnerabilities so they can be acted on without opening the full reports.

    The run is considered FAILED when there are open (unresolved, non-excluded) issues or policy rule
    violations at or above the configured severe threshold (statistics.openIssues.severe /
    statistics.openRuleViolations.severe). Open vulnerabilities are surfaced but do not fail the run
    by themselves — add "|| (vulnerabilities > 0)" to the "failed" assignment below to gate on them.
--]
[#-- Escape a value for use inside a single Markdown table cell. --]
[#function cell value][#return '${value}'?replace('|', '\\|')?replace('\r\n', ' ')?replace('\n', ' ')?replace('\r', ' ')][/#function]
[#-- Status icon from a severe/warning count pair. --]
[#function statusIcon severe warnings][#if (severe > 0)][#return '❌'][#elseif (warnings > 0)][#return '⚠️'][#else][#return '✅'][/#if][/#function]
[#-- Colored badge for an issue/violation severity. --]
[#function severityBadge severity][#assign s = '${severity}'][#if s == 'ERROR'][#return '🔴 ERROR'][#elseif s == 'WARNING'][#return '🟡 WARNING'][#else][#return '🔵 ' + s][/#if][/#function]
[#-- Format a count with the correct singular or plural noun, e.g. "1 issue" / "3 issues". --]
[#function pluralize n one many][#return n?c + ' ' + (n == 1)?then(one, many)][/#function]
[#assign issues = statistics.openIssues]
[#assign violations = statistics.openRuleViolations]
[#assign vulnerabilities = statistics.openVulnerabilities]
[#assign tree = statistics.dependencyTree]
[#assign config = statistics.repositoryConfiguration]
[#assign vcs = ortResult.repository.vcsProcessed]
[#assign failed = (issues.severe > 0) || (violations.severe > 0)]
[#assign warned = (vulnerabilities > 0) || (issues.warnings > 0) || (violations.warnings > 0)]
[#assign hours = (statistics.executionDurationInSeconds / 3600)?floor]
[#assign minutes = ((statistics.executionDurationInSeconds % 3600) / 60)?floor]
[#assign seconds = statistics.executionDurationInSeconds % 60]
[#assign openViolations = ortResult.getRuleViolations(true, Severity.WARNING)]
[#assign openIssues = ortResult.getOpenIssues(Severity.WARNING)]
[#assign openVulnerabilities = ortResult.getVulnerabilities(true, true)]
[#if failed]
## ❌ ORT run failed
[#elseif warned]
## ⚠️ ORT run succeeded with warnings
[#else]
## ✅ ORT run succeeded
[/#if]

[#if failed]
[#assign failureParts = []]
[#if issues.severe > 0][#assign failureParts = failureParts + [pluralize(issues.severe, "severe issue", "severe issues")]][/#if]
[#if violations.severe > 0][#assign failureParts = failureParts + [pluralize(violations.severe, "severe policy violation", "severe policy violations")]][/#if]
This run finished with ${failureParts?join(" and ")}. See the details below.
[#elseif warned]
No severe issues or policy violations.[#if vulnerabilities > 0] ${pluralize(vulnerabilities, "open vulnerability", "open vulnerabilities")} to review.[/#if]
[#else]
No open issues, policy violations or vulnerabilities. 🎉
[/#if]

| Check | Status | Details |
| --- | --- | --- |
| ⚠️ Issues | ${statusIcon(issues.severe, issues.warnings)} | ${pluralize(issues.errors, "error", "errors")}, ${pluralize(issues.warnings, "warning", "warnings")}, ${pluralize(issues.hints, "hint", "hints")} |
| 🚫 Policy rule violations | ${statusIcon(violations.severe, violations.warnings)} | ${pluralize(violations.errors, "error", "errors")}, ${pluralize(violations.warnings, "warning", "warnings")}, ${pluralize(violations.hints, "hint", "hints")} |
| 🛡️ Vulnerabilities | [#if vulnerabilities > 0]⚠️[#else]✅[/#if] | ${pluralize(vulnerabilities, "open vulnerability", "open vulnerabilities")} |
| 📦 Dependencies | ℹ️ | ${pluralize(tree.includedPackages, "package", "packages")} across ${pluralize(tree.includedProjects, "project", "projects")} |

[#if failed]
[#if openViolations?has_content]
### 🚫 Policy rule violations (${openViolations?size})

<details>
<summary>Show ${pluralize(openViolations?size, "rule violation", "rule violations")}</summary>

| Severity | Rule | Package | Message |
| --- | --- | --- | --- |
[#list openViolations as v]
| ${severityBadge(v.severity)} | ${cell(v.rule)} | [#if v.pkg??]`${cell(v.pkg.toCoordinates())}`[#else]—[/#if] | ${cell(v.message)} |
[/#list]

</details>

[/#if]
[#if openIssues?has_content]
### ⚠️ Issues (${openIssues?size})

<details>
<summary>Show ${pluralize(openIssues?size, "issue", "issues")}</summary>

| Severity | Source | Message |
| --- | --- | --- |
[#list openIssues as issue]
| ${severityBadge(issue.severity)} | ${cell(issue.source)} | ${cell(issue.message)} |
[/#list]

</details>

[/#if]
[#if vulnerabilities > 0]
### 🛡️ Vulnerabilities (${vulnerabilities})

<details>
<summary>Show vulnerabilities</summary>

| Package | Vulnerability | References |
| --- | --- | --- |
[#list openVulnerabilities as id, vulns]
[#list vulns as vuln]
| `${cell(id.toCoordinates())}` | ${cell(vuln.id)} | ${vuln.references?size} |
[/#list]
[/#list]

</details>

[/#if]
[/#if]
### 📋 Run details

- **Repository:** ${vcs.type} `${vcs.url}`[#if vcs.path?has_content] (path `${vcs.path}`)[/#if]
- **Revision:** `${vcs.revision}`
- **Duration:** ${hours}h ${minutes}m ${seconds}s
- **Scanned:** ${pluralize(tree.includedPackages, "package", "packages")}, ${pluralize(tree.includedProjects, "project", "projects")}[#if (tree.excludesPackages > 0) || (tree.excludedProjects > 0)]; excluded ${pluralize(tree.excludesPackages, "package", "packages")}, ${pluralize(tree.excludedProjects, "project", "projects")}[/#if]
- **Configuration:** ${pluralize(config.pathExcludes, "path exclude", "path excludes")}, ${pluralize(config.issueResolutions, "issue resolution", "issue resolutions")}, ${pluralize(config.ruleViolationResolutions, "rule-violation resolution", "rule-violation resolutions")}, ${pluralize(config.vulnerabilityResolutions, "vulnerability resolution", "vulnerability resolutions")}
