//
//  WindowDetector.swift
//  MacroRecorder
//

import Foundation
import CoreGraphics
import AppKit

class WindowDetector {
    static let shared = WindowDetector()

    private init() {}

    // Get information about the window at a specific point
    func getWindowInfo(at point: CGPoint) -> WindowInfo? {
        // Get the window list
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        // Find the window at the given point
        for window in windowList {
            guard let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let x = bounds["X"] as? CGFloat,
                  let y = bounds["Y"] as? CGFloat,
                  let width = bounds["Width"] as? CGFloat,
                  let height = bounds["Height"] as? CGFloat else {
                continue
            }

            let windowRect = CGRect(x: x, y: y, width: width, height: height)

            // Check if point is within window bounds
            if windowRect.contains(point) {
                let pid = window[kCGWindowOwnerPID as String] as? Int32 ?? 0
                var windowTitle = window[kCGWindowName as String] as? String
                let layer = window[kCGWindowLayer as String] as? Int ?? 0

                // Skip menu bar and other system windows
                if layer != 0 { continue }

                // If window title is nil or empty, try to get a meaningful title
                if windowTitle == nil || windowTitle?.isEmpty == true {
                    // Try to get the app name as fallback
                    if let appName = getAppName(for: pid) {
                        windowTitle = "\(appName) Window"
                    } else {
                        windowTitle = "Window"
                    }
                }

                // Get bundle identifier for the process
                let bundleId = getBundleIdentifier(for: pid)

                // Check if window is active
                let isActive = isWindowActive(window: window)

                let windowID = window[kCGWindowNumber as String] as? CGWindowID

                return WindowInfo(
                    processID: pid,
                    bundleIdentifier: bundleId,
                    windowTitle: windowTitle,
                    windowBounds: windowRect,
                    isActive: isActive,
                    windowID: windowID
                )
            }
        }

        return nil
    }

    // Get the frontmost application's window info
    func getFrontmostWindowInfo() -> WindowInfo? {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let pid = frontApp.processIdentifier

        // Get window info for the frontmost app
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        // Find the main window of the frontmost app
        for window in windowList {
            let windowPid = window[kCGWindowOwnerPID as String] as? Int32 ?? 0
            if windowPid == pid {
                guard let bounds = window[kCGWindowBounds as String] as? [String: Any],
                      let x = bounds["X"] as? CGFloat,
                      let y = bounds["Y"] as? CGFloat,
                      let width = bounds["Width"] as? CGFloat,
                      let height = bounds["Height"] as? CGFloat else {
                    continue
                }

                let windowRect = CGRect(x: x, y: y, width: width, height: height)
                let windowTitle = window[kCGWindowName as String] as? String
                let windowID = window[kCGWindowNumber as String] as? CGWindowID

                // Skip empty windows
                if windowRect.width > 0 && windowRect.height > 0 {
                    return WindowInfo(
                        processID: pid,
                        bundleIdentifier: frontApp.bundleIdentifier,
                        windowTitle: windowTitle,
                        windowBounds: windowRect,
                        isActive: true,
                        windowID: windowID
                    )
                }
            }
        }

        return nil
    }

    // Get window info for a specific process and bounds
    func getWindowInfo(for processID: Int32, matchingBounds: CGRect? = nil) -> WindowInfo? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        for window in windowList {
            let windowPid = window[kCGWindowOwnerPID as String] as? Int32 ?? 0
            if windowPid == processID {
                guard let bounds = window[kCGWindowBounds as String] as? [String: Any],
                      let x = bounds["X"] as? CGFloat,
                      let y = bounds["Y"] as? CGFloat,
                      let width = bounds["Width"] as? CGFloat,
                      let height = bounds["Height"] as? CGFloat else {
                    continue
                }

                let windowRect = CGRect(x: x, y: y, width: width, height: height)

                // If we have a specific bounds to match, check similarity
                if let targetBounds = matchingBounds {
                    // Allow some tolerance for window position changes
                    if abs(windowRect.width - targetBounds.width) < 50 &&
                       abs(windowRect.height - targetBounds.height) < 50 {
                        let windowTitle = window[kCGWindowName as String] as? String
                        let bundleId = getBundleIdentifier(for: processID)
                        let windowID = window[kCGWindowNumber as String] as? CGWindowID

                        return WindowInfo(
                            processID: processID,
                            bundleIdentifier: bundleId,
                            windowTitle: windowTitle,
                            windowBounds: windowRect,
                            isActive: isWindowActive(window: window),
                            windowID: windowID
                        )
                    }
                } else {
                    // Return the first valid window for this process
                    if windowRect.width > 0 && windowRect.height > 0 {
                        let windowTitle = window[kCGWindowName as String] as? String
                        let bundleId = getBundleIdentifier(for: processID)
                        let windowID = window[kCGWindowNumber as String] as? CGWindowID

                        return WindowInfo(
                            processID: processID,
                            bundleIdentifier: bundleId,
                            windowTitle: windowTitle,
                            windowBounds: windowRect,
                            isActive: isWindowActive(window: window),
                            windowID: windowID
                        )
                    }
                }
            }
        }

        return nil
    }

    // Focus a window
    func focusWindow(with info: WindowInfo) -> Bool {
        // Try to activate the application
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            if app.processIdentifier == info.processID {
                return app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            }
        }
        return false
    }

    // Helper to get bundle identifier
    private func getBundleIdentifier(for pid: Int32) -> String? {
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            if app.processIdentifier == pid {
                return app.bundleIdentifier
            }
        }
        return nil
    }

    // Helper to check if window is active
    private func isWindowActive(window: [String: Any]) -> Bool {
        // Check if the window's app is frontmost
        if let pid = window[kCGWindowOwnerPID as String] as? Int32,
           let frontApp = NSWorkspace.shared.frontmostApplication {
            return frontApp.processIdentifier == pid
        }
        return false
    }

    // Get list of all available windows for UI selection
    func getAllWindows() -> [(app: String, windows: [WindowInfo])] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        var windowsByApp: [String: [WindowInfo]] = [:]

        for window in windowList {
            guard let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let x = bounds["X"] as? CGFloat,
                  let y = bounds["Y"] as? CGFloat,
                  let width = bounds["Width"] as? CGFloat,
                  let height = bounds["Height"] as? CGFloat,
                  width > 0, height > 0 else {
                continue
            }

            let windowRect = CGRect(x: x, y: y, width: width, height: height)
            let pid = window[kCGWindowOwnerPID as String] as? Int32 ?? 0
            var windowTitle = window[kCGWindowName as String] as? String
            let layer = window[kCGWindowLayer as String] as? Int ?? 0
            let windowID = window[kCGWindowNumber as String] as? CGWindowID

            // Skip menu bar and other system windows
            if layer != 0 { continue }

            // Get app name and bundle ID
            let bundleId = getBundleIdentifier(for: pid)
            let appName = getAppName(for: pid) ?? bundleId ?? "Unknown App"

            // Improve window title
            if windowTitle == nil || windowTitle?.isEmpty == true {
                // Try to get a more descriptive title
                if let windowID = windowID {
                    windowTitle = "\(appName) - Window \(windowID)"
                } else {
                    windowTitle = "\(appName) Window"
                }
            } else if windowTitle == "Item-0" || windowTitle == "Window" {
                // Replace generic titles
                windowTitle = "\(appName) - \(windowTitle ?? "Window")"
            }

            let windowInfo = WindowInfo(
                processID: pid,
                bundleIdentifier: bundleId,
                windowTitle: windowTitle,
                windowBounds: windowRect,
                isActive: isWindowActive(window: window),
                windowID: windowID
            )

            if windowsByApp[appName] == nil {
                windowsByApp[appName] = []
            }
            windowsByApp[appName]?.append(windowInfo)
        }

        // Sort by app name and convert to array
        return windowsByApp
            .sorted { $0.key < $1.key }
            .map { (app: $0.key, windows: $0.value) }
    }

    // Helper to get app name
    private func getAppName(for pid: Int32) -> String? {
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            if app.processIdentifier == pid {
                return app.localizedName
            }
        }
        return nil
    }

    // Capture a snapshot of a window
    func captureWindowSnapshot(windowID: CGWindowID) -> NSImage? {
        // Create an image from the window
        guard let cgImage = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowID,
            [.boundsIgnoreFraming, .nominalResolution]
        ) else {
            return nil
        }

        let size = NSSize(width: cgImage.width, height: cgImage.height)
        return NSImage(cgImage: cgImage, size: size)
    }

    // Cache for window thumbnails to improve performance
    private var thumbnailCache: [CGWindowID: (image: NSImage, timestamp: Date)] = [:]
    private let cacheTimeout: TimeInterval = 5.0 // 5 seconds cache

    // Get a small thumbnail for the window with caching
    func getWindowThumbnail(for windowInfo: WindowInfo) -> NSImage? {
        guard let windowID = windowInfo.windowID else { return nil }

        // Check cache first
        if let cached = thumbnailCache[windowID],
           Date().timeIntervalSince(cached.timestamp) < cacheTimeout {
            return cached.image
        }

        // Create thumbnail on background queue for better performance
        var thumbnail: NSImage?

        // Capture with lower quality for speed
        guard let cgImage = CGWindowListCreateImage(
            .null,
            .optionIncludingWindow,
            windowID,
            [.boundsIgnoreFraming, .bestResolution]
        ) else {
            return nil
        }

        let fullImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))

        // Create a larger thumbnail for better visibility (max 300x200)
        let targetSize = NSSize(width: 300, height: 200)
        let aspectRatio = fullImage.size.width / fullImage.size.height

        var thumbnailSize = targetSize
        if aspectRatio > targetSize.width / targetSize.height {
            thumbnailSize.height = targetSize.width / aspectRatio
        } else {
            thumbnailSize.width = targetSize.height * aspectRatio
        }

        thumbnail = NSImage(size: thumbnailSize)
        thumbnail?.lockFocus()

        // Use high quality interpolation
        NSGraphicsContext.current?.imageInterpolation = .high

        fullImage.draw(in: NSRect(origin: .zero, size: thumbnailSize),
                      from: NSRect(origin: .zero, size: fullImage.size),
                      operation: .copy,
                      fraction: 1.0)
        thumbnail?.unlockFocus()

        // Cache the result
        if let thumbnail = thumbnail {
            thumbnailCache[windowID] = (image: thumbnail, timestamp: Date())
        }

        return thumbnail
    }

    // Clear old cache entries periodically
    func clearThumbnailCache() {
        let now = Date()
        thumbnailCache = thumbnailCache.filter { _, value in
            now.timeIntervalSince(value.timestamp) < cacheTimeout
        }
    }
}