//
//  MacroRecorderApp.swift
//  MacroRecorder
//

import SwiftUI
import ApplicationServices

@main
struct MacroRecorderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .commands {
            CommandGroup(replacing: .newItem) {}

            CommandMenu("Macro") {
                Button("Start/Stop Recording") {
                    NotificationCenter.default.post(name: .toggleRecording, object: nil)
                }
                .keyboardShortcut("r", modifiers: [.command])

                Button("Play/Stop Playback") {
                    NotificationCenter.default.post(name: .togglePlayback, object: nil)
                }
                .keyboardShortcut("p", modifiers: [.command])

                Divider()

                Button("Save Macro") {
                    NotificationCenter.default.post(name: .saveMacro, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command])
            }
        }

        Settings {
            PreferencesView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Check for accessibility permissions on launch
        checkAccessibilityPermissions()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    private func checkAccessibilityPermissions() {
        // First check without prompting
        let accessEnabled = AXIsProcessTrusted()

        if !accessEnabled {
            // Only show prompt if not already trusted
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permissions Required"
                alert.informativeText = "MacroRecorder needs accessibility permissions to record and playback mouse and keyboard events. Please grant access in System Settings > Privacy & Security > Accessibility."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "Later")

                if alert.runModal() == .alertFirstButtonReturn {
                    // For macOS 13+ use the new Settings app URL scheme
                    if #available(macOS 13, *) {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    } else {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
            }
        }
    }
}

// Notification names for menu commands
extension Notification.Name {
    static let toggleRecording = Notification.Name("toggleRecording")
    static let togglePlayback = Notification.Name("togglePlayback")
    static let saveMacro = Notification.Name("saveMacro")
    // hotkeysChanged is defined in HotkeyConfig.swift
}
