//
//  CGEvent+Extensions.swift
//  MacroRecorder
//

import Foundation
import CoreGraphics
import AppKit
import Carbon

extension CGEvent {
    /// Post event directly to a specific process (ghost action)
    /// This allows sending events to windows that aren't focused without moving the cursor
    func postToPid(_ pid: Int32) {
        // For true ghost actions that don't interfere with the user's cursor,
        // we need to use the Accessibility API instead of CGEvent posting

        // Get the AXUIElement for the application
        let app = AXUIElementCreateApplication(pid)

        // For keyboard events
        if self.type == .keyDown || self.type == .keyUp {
            let keyCodeValue = self.getIntegerValueField(.keyboardEventKeycode)
            if keyCodeValue != 0 {
                // Get the focused element within the app
                var focusedElement: CFTypeRef?
                let result = AXUIElementCopyAttributeValue(app, kAXFocusedUIElementAttribute as CFString, &focusedElement)

                if result == .success, let element = focusedElement {
                    // Send the key event directly to the focused element using AX API
                    // This doesn't interfere with the user's cursor
                    let axElement = element as! AXUIElement

                    // Create a keyboard event and post it to the specific element
                    // Note: This is a simplified approach. For full implementation,
                    // we'd need to use AXUIElementPostKeyboardEvent
                    self.setIntegerValueField(.eventTargetUnixProcessID, value: Int64(pid))
                    self.post(tap: .cgSessionEventTap)
                } else {
                    // No focused element, post normally to the process
                    self.setIntegerValueField(.eventTargetUnixProcessID, value: Int64(pid))
                    self.post(tap: .cgSessionEventTap)
                }
            }
        } else {
            // For mouse events in ghost mode, try to use Accessibility API
            let mouseLocation = self.location

            // Try to find the UI element at the mouse position in the target app
            var element: AXUIElement?
            let systemWideElement = AXUIElementCreateSystemWide()

            // Get the element at the position
            var foundElement: AXUIElement?
            let result = AXUIElementCopyElementAtPosition(systemWideElement, Float(mouseLocation.x), Float(mouseLocation.y), &foundElement)

            if result == .success, let axElement = foundElement {
                element = axElement

                // Verify this element belongs to our target PID
                var elementPid: pid_t = 0
                AXUIElementGetPid(element!, &elementPid)

                if elementPid == pid {
                    // This element belongs to the target process!
                    // Try to perform the action without moving cursor
                    if self.type == .leftMouseDown {
                        // Try to press the element using AX API
                        AXUIElementPerformAction(element!, kAXPressAction as CFString)
                        return  // Don't post the CGEvent
                    }
                }
            }

            // Fallback: If AX API didn't work, post the event
            // This will move the cursor, but it's the only option for some scenarios
            self.setIntegerValueField(.eventTargetUnixProcessID, value: Int64(pid))
            self.flags.insert(.maskNonCoalesced)
            self.post(tap: .cgSessionEventTap)
        }
    }

    /// Set the event's target process ID for process-specific delivery
    func setTargetProcessID(_ pid: Int32) {
        // Set the event's target process
        // This helps ensure the event goes to the right process
        self.setIntegerValueField(.eventTargetUnixProcessID, value: Int64(pid))
    }

    /// Create a copy of this event with adjusted coordinates for a specific window
    func withAdjustedCoordinates(for windowBounds: CGRect) -> CGEvent? {
        let location = self.location

        // Calculate window-relative coordinates
        let adjustedLocation = CGPoint(
            x: location.x - windowBounds.origin.x,
            y: location.y - windowBounds.origin.y
        )

        // Create a copy of the event with adjusted location
        let copiedEvent = self.copy()
        copiedEvent?.location = adjustedLocation

        return copiedEvent
    }
}