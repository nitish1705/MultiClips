// Version parsing and comparison tests for the auto-updater.
//
// Run with:   swift Tests/VersionLogicTests.swift
//
// The project has no XCTest target, so this is a standalone script. The three
// functions below are COPIES of the implementations in MultiClips/UpdateManager.swift
// (parseReleaseVersion, normalizeVersion, isUpdateNewer). They are pure, which is what
// makes testing them this way possible at all — but it also means this file can drift.
// If you change the originals, change them here too, or add a real test target and
// delete the copies.

import Foundation

struct AppVersionInfo: Equatable {
    let versionComponents: [Int]
    let buildNumber: Int
    let rawVersionString: String
    var displayString: String { "v\(rawVersionString) (Build \(buildNumber))" }
}

// MARK: - Copies of UpdateManager's parsing logic

func parseReleaseVersion(tag: String, body: String?) -> AppVersionInfo {
    let cleanTag = tag.trimmingCharacters(in: CharacterSet(charactersIn: "vV "))
    var versionStr = cleanTag
    var buildNum = 1
    var buildFound = false

    let pattern = #"(?i)^([0-9\.]+)[-_\+](?:b|build)?\s*([0-9]+)$"#
    if let regex = try? NSRegularExpression(pattern: pattern),
       let match = regex.firstMatch(in: cleanTag, range: NSRange(cleanTag.startIndex..., in: cleanTag)) {
        if let vRange = Range(match.range(at: 1), in: cleanTag) {
            versionStr = String(cleanTag[vRange])
        }
        if let bRange = Range(match.range(at: 2), in: cleanTag), let bVal = Int(cleanTag[bRange]) {
            buildNum = bVal
            buildFound = true
        }
    }

    if !buildFound, let bodyText = body {
        let bodyPattern = #"(?i)\bbuild\s*(?:number|num)?\s*:?\s*([0-9]+)"#
        if let bodyRegex = try? NSRegularExpression(pattern: bodyPattern),
           let match = bodyRegex.firstMatch(in: bodyText, range: NSRange(bodyText.startIndex..., in: bodyText)),
           let bRange = Range(match.range(at: 1), in: bodyText), let bVal = Int(bodyText[bRange]) {
            buildNum = bVal
        }
    }

    return AppVersionInfo(versionComponents: normalizeVersion(versionStr),
                          buildNumber: buildNum,
                          rawVersionString: versionStr)
}

func normalizeVersion(_ versionString: String) -> [Int] {
    var cleaned = versionString.trimmingCharacters(in: .whitespacesAndNewlines)
    cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: "."))
    let components = cleaned.split(separator: ".").compactMap {
        Int($0.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    var result = components
    while result.count < 3 { result.append(0) }
    return result
}

func isCheckStale(lastCheck: Date?, now: Date, interval: TimeInterval) -> Bool {
    guard let lastCheck else { return true }
    let elapsed = now.timeIntervalSince(lastCheck)
    guard elapsed >= 0 else { return false }
    return elapsed >= interval
}

func isUpdateNewer(remote: AppVersionInfo, local: AppVersionInfo) -> Bool {
    let maxCount = max(remote.versionComponents.count, local.versionComponents.count)
    for i in 0..<maxCount {
        let rVal = i < remote.versionComponents.count ? remote.versionComponents[i] : 0
        let lVal = i < local.versionComponents.count ? local.versionComponents[i] : 0
        if rVal > lVal { return true } else if rVal < lVal { return false }
    }
    return remote.buildNumber > local.buildNumber
}

// MARK: - Harness

var failures = 0
func check(_ name: String, _ got: Any, _ want: Any) {
    let g = "\(got)", w = "\(want)"
    if g == w {
        print("  ok   \(name)")
    } else {
        failures += 1
        print("  FAIL \(name)\n         got:  \(g)\n         want: \(w)")
    }
}

// MARK: - Tests

print("\n— tag parsing: formats this project actually publishes —")
let t20b7 = parseReleaseVersion(tag: "v2.0-b7", body: nil)
check("v2.0-b7 version", t20b7.versionComponents, [2, 0, 0])
check("v2.0-b7 build", t20b7.buildNumber, 7)

let t21b9 = parseReleaseVersion(tag: "v2.1-b9", body: nil)
check("v2.1-b9 version", t21b9.versionComponents, [2, 1, 0])
check("v2.1-b9 build", t21b9.buildNumber, 9)

check("v2.0+6 build (alt format in VERSION_HISTORY.md)",
      parseReleaseVersion(tag: "v2.0+6", body: nil).buildNumber, 6)
check("v2.0.0 (old tag, no build suffix) falls back to 1",
      parseReleaseVersion(tag: "v2.0.0", body: nil).buildNumber, 1)

print("\n— body fallback when the tag carries no build number —")
// Regression: the original pattern required "number", "num" or ":" straight after
// "build", so the two most natural phrasings silently fell back to build 1.
check("body 'Build 7'",
      parseReleaseVersion(tag: "v2.0.0", body: "Build 7").buildNumber, 7)
check("body 'Build Number: 7'",
      parseReleaseVersion(tag: "v2.0.0", body: "Build Number: 7").buildNumber, 7)
check("body 'build: 7'",
      parseReleaseVersion(tag: "v2.0.0", body: "build: 7").buildNumber, 7)
check("body 'Build num 12'",
      parseReleaseVersion(tag: "v2.0.0", body: "Build num 12").buildNumber, 12)
check("body 'MultiClips v2.0 Build 7'",
      parseReleaseVersion(tag: "v2.0.0", body: "MultiClips v2.0 Build 7").buildNumber, 7)
check("'rebuild 3' must not match — \\b guards the word boundary",
      parseReleaseVersion(tag: "v2.0.0", body: "rebuild 3").buildNumber, 1)
check("a build in the tag still wins over the body",
      parseReleaseVersion(tag: "v2.0-b7", body: "Build 99").buildNumber, 7)

print("\n— version comparison —")
let local21b9 = AppVersionInfo(versionComponents: [2, 1, 0], buildNumber: 9, rawVersionString: "2.1")
let local20b7 = AppVersionInfo(versionComponents: [2, 0, 0], buildNumber: 7, rawVersionString: "2.0")

check("older release vs newer install -> no update",
      isUpdateNewer(remote: t20b7, local: local21b9), false)
check("newer release vs older install -> update",
      isUpdateNewer(remote: t21b9, local: local20b7), true)
check("identical version and build -> no update",
      isUpdateNewer(remote: t21b9, local: local21b9), false)
check("marketing bump wins even when build number drops",
      isUpdateNewer(remote: parseReleaseVersion(tag: "v2.1-b1", body: nil), local: local20b7), true)
check("2.10 is newer than 2.9, not older",
      isUpdateNewer(remote: parseReleaseVersion(tag: "v2.10-b1", body: nil),
                    local: AppVersionInfo(versionComponents: [2, 9, 0],
                                          buildNumber: 1, rawVersionString: "2.9")), true)
check("build-only bump is an update",
      isUpdateNewer(remote: parseReleaseVersion(tag: "v2.1-b10", body: nil), local: local21b9), true)

print("\n— the 5-minute staleness gate —")
let interval: TimeInterval = 5 * 60
let now = Date()
check("never checked -> stale",
      isCheckStale(lastCheck: nil, now: now, interval: interval), true)
check("checked just now -> fresh",
      isCheckStale(lastCheck: now, now: now, interval: interval), false)
check("4m59s ago -> fresh",
      isCheckStale(lastCheck: now.addingTimeInterval(-299), now: now, interval: interval), false)
check("exactly 5m ago -> stale",
      isCheckStale(lastCheck: now.addingTimeInterval(-300), now: now, interval: interval), true)
check("an hour ago -> stale",
      isCheckStale(lastCheck: now.addingTimeInterval(-3600), now: now, interval: interval), true)
// Clock skew, or the user moved their clock back: a future timestamp must not make every
// window open re-check.
check("timestamp in the future -> fresh, not stale",
      isCheckStale(lastCheck: now.addingTimeInterval(600), now: now, interval: interval), false)

print("\n— banner text —")
check("displayString already carries its own parentheses",
      local21b9.displayString, "v2.1 (Build 9)")
// Which is why the banner must not wrap it in another pair:
// "MultiClips is up to date (v2.1 (Build 9))" was the bug.

if failures == 0 {
    print("\nALL PASS\n")
} else {
    print("\n\(failures) FAILURE(S)\n")
    exit(1)
}
