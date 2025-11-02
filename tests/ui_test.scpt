#!/usr/bin/osascript

-- MacroRecorder UI Test Script
-- This script tests the UI functionality of MacroRecorder

on run
    set testResults to {}

    -- Test 1: Check if app is running
    tell application "System Events"
        set appList to name of every process
        if "MacroRecorder" is in appList then
            set end of testResults to "✅ Test 1 PASSED: MacroRecorder is running"
        else
            set end of testResults to "❌ Test 1 FAILED: MacroRecorder is not running"
            -- Try to launch it
            do shell script "open -a '/Users/jacklau/Library/Developer/Xcode/DerivedData/MacroRecorder-ezwwgiakxmeqrtegvjwsqwtgkiii/Build/Products/Debug/MacroRecorder.app'"
            delay 2
        end if
    end tell

    -- Test 2: Check main window
    tell application "System Events"
        tell process "MacroRecorder"
            set frontmost to true
            delay 0.5

            if exists window 1 then
                set end of testResults to "✅ Test 2 PASSED: Main window exists"
            else
                set end of testResults to "❌ Test 2 FAILED: Main window not found"
            end if
        end tell
    end tell

    -- Test 3: Check for Record button
    tell application "System Events"
        tell process "MacroRecorder"
            tell window 1
                if exists button "Record" then
                    set end of testResults to "✅ Test 3 PASSED: Record button found"
                else if exists button "Stop" then
                    set end of testResults to "✅ Test 3 PASSED: Stop button found (recording active)"
                else
                    set end of testResults to "❌ Test 3 FAILED: Record/Stop button not found"
                end if
            end tell
        end tell
    end tell

    -- Test 4: Check for Play button
    tell application "System Events"
        tell process "MacroRecorder"
            tell window 1
                if exists button "Play" then
                    set end of testResults to "✅ Test 4 PASSED: Play button found"
                else if exists button "Stop" then
                    set end of testResults to "✅ Test 4 PASSED: Stop button found (playback active)"
                else
                    set end of testResults to "❌ Test 4 FAILED: Play/Stop button not found"
                end if
            end tell
        end tell
    end tell

    -- Test 5: Check menu bar
    tell application "System Events"
        tell process "MacroRecorder"
            if exists menu bar 1 then
                set end of testResults to "✅ Test 5 PASSED: Menu bar exists"

                -- Check for Macro menu
                tell menu bar 1
                    if exists menu "Macro" then
                        set end of testResults to "✅ Test 6 PASSED: Macro menu exists"
                    else
                        set end of testResults to "❌ Test 6 FAILED: Macro menu not found"
                    end if
                end tell
            else
                set end of testResults to "❌ Test 5 FAILED: Menu bar not found"
            end if
        end tell
    end tell

    -- Test 7: Test Preferences window
    tell application "System Events"
        tell process "MacroRecorder"
            -- Open preferences
            keystroke "," using command down
            delay 1

            if exists window "Preferences" or exists window "Settings" then
                set end of testResults to "✅ Test 7 PASSED: Preferences window opened"

                -- Close preferences
                keystroke "w" using command down
                delay 0.5
            else
                set end of testResults to "❌ Test 7 FAILED: Preferences window not found"
            end if
        end tell
    end tell

    -- Print all results
    set output to "🧪 MacroRecorder UI Test Results" & return
    set output to output & "================================" & return & return

    repeat with testResult in testResults
        set output to output & testResult & return
    end repeat

    set output to output & return & "================================" & return
    set passCount to 0
    set failCount to 0

    repeat with testResult in testResults
        if testResult contains "✅" then
            set passCount to passCount + 1
        else
            set failCount to failCount + 1
        end if
    end repeat

    set totalTests to passCount + failCount
    set output to output & "Total Tests: " & totalTests & return
    set output to output & "Passed: " & passCount & return
    set output to output & "Failed: " & failCount & return

    if failCount = 0 then
        set output to output & return & "🎉 All UI tests passed!"
    else
        set output to output & return & "⚠️ Some UI tests failed"
    end if

    return output
end run