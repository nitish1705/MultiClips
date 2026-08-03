#!/usr/bin/env swift

import Foundation

// This test verifies the update detection logic works correctly
// Run with: swift test_update_logic.swift

struct AppVersionInfo: Equatable {
    let versionComponents: [Int]
    let buildNumber: Int
    let rawVersionString: String
    
    var displayString: String {
        "v\(rawVersionString) (Build \(buildNumber))"
    }
}

func normalizeVersion(_ versionString: String) -> [Int] {
    var cleaned = versionString.trimmingCharacters(in: .whitespacesAndNewlines)
    cleaned = cleaned.trimmingCharacters(in: CharacterSet(charactersIn: "."))
    
    let components = cleaned.split(separator: ".").compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
    var result = components
    while result.count < 3 {
        result.append(0)
    }
    return result
}

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
        let bodyPattern = #"(?i)build\s*(?:number|num|:)\s*([0-9]+)"#
        if let bodyRegex = try? NSRegularExpression(pattern: bodyPattern),
           let match = bodyRegex.firstMatch(in: bodyText, range: NSRange(bodyText.startIndex..., in: bodyText)),
           let bRange = Range(match.range(at: 1), in: bodyText),
           let bVal = Int(bodyText[bRange]) {
            buildNum = bVal
        }
    }
    
    return AppVersionInfo(
        versionComponents: normalizeVersion(versionStr),
        buildNumber: buildNum,
        rawVersionString: versionStr
    )
}

func isUpdateNewer(remote: AppVersionInfo, local: AppVersionInfo) -> Bool {
    let maxCount = max(remote.versionComponents.count, local.versionComponents.count)
    for i in 0..<maxCount {
        let rVal = i < remote.versionComponents.count ? remote.versionComponents[i] : 0
        let lVal = i < local.versionComponents.count ? local.versionComponents[i] : 0
        
        if rVal > lVal {
            return true
        } else if rVal < lVal {
            return false
        }
    }
    
    return remote.buildNumber > local.buildNumber
}

// MARK: - Tests

print("╔════════════════════════════════════════════════════════╗")
print("║   MultiClips Update Detection Logic Test Suite       ║")
print("╚════════════════════════════════════════════════════════╝\n")

// Current app state (from project.pbxproj)
let currentLocal = AppVersionInfo(
    versionComponents: [2, 0, 0],
    buildNumber: 2,
    rawVersionString: "2.0"
)

print("📱 Current App: \(currentLocal.displayString)\n")

print("═══ GitHub Release Tag Parsing Tests ═══\n")

let tagTests: [(tag: String, body: String?, expected: AppVersionInfo)] = [
    ("v.2.1.0", nil, AppVersionInfo(versionComponents: [2,1,0], buildNumber: 1, rawVersionString: ".2.1.0")),
    ("v2.0.0-b5", nil, AppVersionInfo(versionComponents: [2,0,0], buildNumber: 5, rawVersionString: "2.0.0")),
    ("v2.0.0+3", nil, AppVersionInfo(versionComponents: [2,0,0], buildNumber: 3, rawVersionString: "2.0.0")),
    ("v2.0.0-build7", nil, AppVersionInfo(versionComponents: [2,0,0], buildNumber: 7, rawVersionString: "2.0.0")),
    ("v2.1.0", "Build: 10", AppVersionInfo(versionComponents: [2,1,0], buildNumber: 10, rawVersionString: "2.1.0")),
    ("v2.1.0", nil, AppVersionInfo(versionComponents: [2,1,0], buildNumber: 1, rawVersionString: "2.1.0")),
]

var passCount = 0
var failCount = 0

for (tag, body, expected) in tagTests {
    let result = parseReleaseVersion(tag: tag, body: body)
    let matches = result.versionComponents == expected.versionComponents && result.buildNumber == expected.buildNumber
    
    if matches {
        print("✅ PASS: '\(tag)' → \(result.displayString)")
        passCount += 1
    } else {
        print("❌ FAIL: '\(tag)'")
        print("   Expected: \(expected.displayString)")
        print("   Got: \(result.displayString)")
        failCount += 1
    }
}

print("\n═══ Update Detection Tests ═══\n")

let updateTests: [(remote: AppVersionInfo, shouldUpdate: Bool, reason: String)] = [
    // Version upgrades
    (AppVersionInfo(versionComponents: [2,1,0], buildNumber: 1, rawVersionString: "2.1.0"), true, "Major version upgrade"),
    (AppVersionInfo(versionComponents: [3,0,0], buildNumber: 1, rawVersionString: "3.0.0"), true, "Major version upgrade"),
    
    // Build number upgrades (same version)
    (AppVersionInfo(versionComponents: [2,0,0], buildNumber: 3, rawVersionString: "2.0.0"), true, "Same version, newer build"),
    (AppVersionInfo(versionComponents: [2,0,0], buildNumber: 10, rawVersionString: "2.0.0"), true, "Same version, much newer build"),
    
    // No update needed
    (AppVersionInfo(versionComponents: [2,0,0], buildNumber: 2, rawVersionString: "2.0.0"), false, "Same version and build"),
    (AppVersionInfo(versionComponents: [2,0,0], buildNumber: 1, rawVersionString: "2.0.0"), false, "Same version, older build"),
    (AppVersionInfo(versionComponents: [1,9,9], buildNumber: 99, rawVersionString: "1.9.9"), false, "Older version"),
]

for (remote, shouldUpdate, reason) in updateTests {
    let result = isUpdateNewer(remote: remote, local: currentLocal)
    let matches = result == shouldUpdate
    
    if matches {
        print("✅ PASS: \(remote.displayString) → Update: \(result)")
        print("   Reason: \(reason)")
        passCount += 1
    } else {
        print("❌ FAIL: \(remote.displayString)")
        print("   Expected: \(shouldUpdate), Got: \(result)")
        print("   Reason: \(reason)")
        failCount += 1
    }
}

print("\n═══ Real GitHub Release Test ═══\n")

// Test with actual GitHub release
let githubTag = "v.2.1.0"
let githubRelease = parseReleaseVersion(tag: githubTag, body: nil)
let willUpdate = isUpdateNewer(remote: githubRelease, local: currentLocal)

print("Current App: \(currentLocal.displayString)")
print("GitHub Release: \(githubRelease.displayString)")
print("Update Available: \(willUpdate ? "✅ YES" : "❌ NO")")

print("\n╔════════════════════════════════════════════════════════╗")
print("║                    Test Summary                        ║")
print("╠════════════════════════════════════════════════════════╣")
print("║  Total Tests: \(passCount + failCount)                                          ║")
print("║  ✅ Passed: \(passCount)                                            ║")
print("║  ❌ Failed: \(failCount)                                            ║")
print("╚════════════════════════════════════════════════════════╝")

exit(failCount == 0 ? 0 : 1)
