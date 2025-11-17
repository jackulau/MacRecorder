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
    /// This allows sending events to windows that aren't focused
    func postToPid(_ pid: Int32) {
        // First set the target process ID for the event
        self.setIntegerValueField(.eventTargetUnixProcessID, value: Int64(pid))

        // Get the running application for this PID
        let runningApps = NSWorkspace.shared.runningApplications

        if runningApps.contains(where: { $0.processIdentifier == pid }) {
            // For ghost actions, we don't activate the app
            // The event system will route it to the correct process based on the PID

            // Post the event with the session tap which respects the process ID
            self.post(tap: .cgSessionEventTap)
        } else {
            // Process not found, post normally
            self.post(tap: .cghidEventTap)
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