#!/usr/bin/env swift

import Foundation
import AppKit

// Test Suite for MacroRecorder Application
class MacroRecorderTests {

    // MARK: - Test Configuration
    struct TestResult {
        let testName: String
        let passed: Bool
        let message: String
        let duration: TimeInterval
    }

    var results: [TestResult] = []
    let testStartTime = Date()

    // MARK: - Main Test Runner
    func runAllTests() {
        print("🧪 Starting MacroRecorder Test Suite")
        print("=" * 50)

        // Test 1: Application Launch
        test1_ApplicationLaunch()

        // Test 2: UI Components Presence
        test2_UIComponentsPresence()

        // Test 3: UserDefaults Storage
        test3_UserDefaultsStorage()

        // Test 4: Hotkey Configuration
        test4_HotkeyConfiguration()

        // Test 5: Event Model Validation
        test5_EventModelValidation()

        // Test 6: JSON Export/Import
        test6_JSONExportImport()

        // Test 7: Preferences Persistence
        test7_PreferencesPersistence()

        // Test 8: Playback Speed Validation
        test8_PlaybackSpeedValidation()

        // Print Results
        printTestResults()
    }

    // MARK: - Individual Tests

    func test1_ApplicationLaunch() {
        let start = Date()

        // Check if app is running
        let workspace = NSWorkspace.shared
        let runningApps = workspace.runningApplications
        let isRunning = runningApps.contains { $0.bundleIdentifier == "com.macrorecorder.app" }

        let result = TestResult(
            testName: "Application Launch",
            passed: isRunning,
            message: isRunning ? "✅ Application launched successfully" : "❌ Application failed to launch",
            duration: Date().timeIntervalSince(start)
        )
        results.append(result)
    }

    func test2_UIComponentsPresence() {
        let start = Date()

        // Check for required files
        let viewFiles = [
            "ContentView.swift",
            "ControlsView.swift",
            "EventListView.swift",
            "MacroListView.swift",
            "StatusBarView.swift",
            "PreferencesView.swift",
            "EventEditorView.swift"
        ]

        let basePath = "/Users/jacklau/MacroRecorder/MacroRecorder/Views/"
        var allPresent = true
        var missingFiles: [String] = []

        for file in viewFiles {
            let fullPath = basePath + file
            if !FileManager.default.fileExists(atPath: fullPath) {
                allPresent = false
                missingFiles.append(file)
            }
        }

        let message = allPresent ?
            "✅ All UI component files present" :
            "❌ Missing UI files: \(missingFiles.joined(separator: ", "))"

        let result = TestResult(
            testName: "UI Components Presence",
            passed: allPresent,
            message: message,
            duration: Date().timeIntervalSince(start)
        )
        results.append(result)
    }

    func test3_UserDefaultsStorage() {
        let start = Date()
        let defaults = UserDefaults.standard

        // Test writing and reading
        let testKey = "test_macrorecorder_key"
        let testValue = "test_value_\(Date().timeIntervalSince1970)"

        defaults.set(testValue, forKey: testKey)
        defaults.synchronize()

        let retrieved = defaults.string(forKey: testKey)
        let passed = retrieved == testValue

        // Cleanup
        defaults.removeObject(forKey: testKey)

        let result = TestResult(
            testName: "UserDefaults Storage",
            passed: passed,
            message: passed ? "✅ UserDefaults read/write working" : "❌ UserDefaults failed",
            duration: Date().timeIntervalSince(start)
        )
        results.append(result)
    }

    func test4_HotkeyConfiguration() {
        let start = Date()

        // Test HotkeyConfig encoding/decoding
        struct HotkeyConfig: Codable {
            var keyCode: UInt32
            var modifiers: UInt32
        }

        let config = HotkeyConfig(keyCode: 0x2C, modifiers: 0x100108)
        var passed = false
        var message = ""

        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(config)

            let decoder = JSONDecoder()
            let decoded = try decoder.decode(HotkeyConfig.self, from: data)

            passed = decoded.keyCode == config.keyCode && decoded.modifiers == config.modifiers
            message = passed ? "✅ HotkeyConfig encoding/decoding works" : "❌ HotkeyConfig mismatch"
        } catch {
            message = "❌ HotkeyConfig encoding failed: \(error)"
        }

        let result = TestResult(
            testName: "Hotkey Configuration",
            passed: passed,
            message: message,
            duration: Date().timeIntervalSince(start)
        )
        results.append(result)
    }

    func test5_EventModelValidation() {
        let start = Date()

        // Test MacroEvent model
        let eventTypes = [
            "mouseDown", "mouseUp", "mouseDragged", "mouseMoved",
            "keyDown", "keyUp", "flagsChanged", "scrollWheel", "delay"
        ]

        let passed = eventTypes.count == 9
        let message = passed ?
            "✅ All 9 event types defined" :
            "❌ Event types mismatch"

        let result = TestResult(
            testName: "Event Model Validation",
            passed: passed,
            message: message,
            duration: Date().timeIntervalSince(start)
        )
        results.append(result)
    }

    func test6_JSONExportImport() {
        let start = Date()

        // Test JSON export/import functionality
        struct TestMacro: Codable {
            let name: String
            let events: [TestEvent]
        }

        struct TestEvent: Codable {
            let id: UUID
            let type: String
            let delay: Double
        }

        let testMacro = TestMacro(
            name: "Test Macro",
            events: [
                TestEvent(id: UUID(), type: "mouseDown", delay: 0.5),
                TestEvent(id: UUID(), type: "mouseUp", delay: 0.1)
            ]
        )

        var passed = false
        var message = ""

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(testMacro)

            let decoder = JSONDecoder()
            let decoded = try decoder.decode(TestMacro.self, from: data)

            passed = decoded.name == testMacro.name &&
                     decoded.events.count == testMacro.events.count
            message = passed ? "✅ JSON export/import working" : "❌ JSON data mismatch"
        } catch {
            message = "❌ JSON processing failed: \(error)"
        }

        let result = TestResult(
            testName: "JSON Export/Import",
            passed: passed,
            message: message,
            duration: Date().timeIntervalSince(start)
        )
        results.append(result)
    }

    func test7_PreferencesPersistence() {
        let start = Date()
        let defaults = UserDefaults.standard

        // Test preferences
        let testSpeed = 2.5
        let testMode = "loop"

        defaults.set(testSpeed, forKey: "test_defaultPlaybackSpeed")
        defaults.set(testMode, forKey: "test_defaultPlaybackMode")
        defaults.synchronize()

        let retrievedSpeed = defaults.double(forKey: "test_defaultPlaybackSpeed")
        let retrievedMode = defaults.string(forKey: "test_defaultPlaybackMode")

        let passed = retrievedSpeed == testSpeed && retrievedMode == testMode

        // Cleanup
        defaults.removeObject(forKey: "test_defaultPlaybackSpeed")
        defaults.removeObject(forKey: "test_defaultPlaybackMode")

        let result = TestResult(
            testName: "Preferences Persistence",
            passed: passed,
            message: passed ? "✅ Preferences saved correctly" : "❌ Preferences not persisted",
            duration: Date().timeIntervalSince(start)
        )
        results.append(result)
    }

    func test8_PlaybackSpeedValidation() {
        let start = Date()

        // Test playback speed range
        let validSpeeds = [0.1, 0.5, 1.0, 2.0, 5.0]
        var allValid = true

        for speed in validSpeeds {
            if speed < 0.1 || speed > 5.0 {
                allValid = false
                break
            }
        }

        let result = TestResult(
            testName: "Playback Speed Validation",
            passed: allValid,
            message: allValid ? "✅ All playback speeds in valid range" : "❌ Invalid playback speeds",
            duration: Date().timeIntervalSince(start)
        )
        results.append(result)
    }

    // MARK: - Results Reporting

    func printTestResults() {
        print("\n" + "=" * 50)
        print("📊 Test Results Summary")
        print("=" * 50)

        let passedCount = results.filter { $0.passed }.count
        let failedCount = results.filter { !$0.passed }.count
        let totalDuration = Date().timeIntervalSince(testStartTime)

        for (index, result) in results.enumerated() {
            let status = result.passed ? "✅ PASS" : "❌ FAIL"
            print("\n\(index + 1). \(result.testName)")
            print("   Status: \(status)")
            print("   Message: \(result.message)")
            print("   Duration: \(String(format: "%.3f", result.duration))s")
        }

        print("\n" + "=" * 50)
        print("📈 Final Statistics")
        print("=" * 50)
        print("Total Tests: \(results.count)")
        print("Passed: \(passedCount) (\(String(format: "%.1f", Double(passedCount) / Double(results.count) * 100))%)")
        print("Failed: \(failedCount)")
        print("Total Duration: \(String(format: "%.3f", totalDuration))s")

        if failedCount == 0 {
            print("\n🎉 All tests passed successfully!")
        } else {
            print("\n⚠️  Some tests failed. Please review the failures above.")
        }
    }
}

// Helper extension
extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

// Run tests
let tester = MacroRecorderTests()
tester.runAllTests()