# Window-Specific Recording - Quick Reference Guide

## Most Important Files to Modify

### 1. **EventRecorder.swift** (HIGHEST PRIORITY)
**Path**: `/Users/jacklau/MacroRecorder/MacroRecorder/Services/EventRecorder.swift`
**Size**: 195 lines
**Purpose**: Captures system events via CGEvent tap

**Critical Section**:
- Lines 124-185: `handleEvent()` - THIS IS WHERE TO ADD WINDOW TRACKING
- Line 181: `MacroEvent.from(cgEvent:)` - Convert CGEvent to MacroEvent

**What to do**:
```swift
// In handleEvent(), after filtering hotkeys and before creating MacroEvent:
let currentWindow = getCurrentFocusedWindow()  // NEW
let windowInfo = extractWindowInfo(currentWindow)  // NEW

if !shouldRecordEvent(for: windowInfo) { return }  // NEW - filtering

// Then pass windowInfo when creating MacroEvent
```

---

### 2. **MacroEvent.swift** (HIGH PRIORITY)
**Path**: `/Users/jacklau/MacroRecorder/MacroRecorder/Models/MacroEvent.swift`
**Size**: 190 lines
**Purpose**: Event data model - stores all captured event information

**Current Structure** (lines 21-52):
```swift
struct MacroEvent: Codable, Identifiable {
    let id: UUID
    let type: EventType
    let timestamp: TimeInterval
    let position: CGPoint?        // ONLY POSITION - NO WINDOW INFO
    let keyCode: UInt16?
    let flags: UInt64?
    let scrollDeltaX: Double?
    let scrollDeltaY: Double?
    var delay: TimeInterval
}
```

**What to add** (BEFORE the existing fields for backward compatibility):
```swift
struct MacroEvent: Codable, Identifiable {
    // ... existing fields ...
    
    // NEW FIELDS:
    var windowInfo: WindowInfo?        // Optional window metadata
    var relativePosition: CGPoint?     // Position relative to window origin
}

// NEW STRUCT:
struct WindowInfo: Codable {
    var processID: pid_t
    var bundleID: String
    var windowTitle: String
    var applicationName: String
    var windowFrame: CGRect            // Position and size of window
}
```

---

### 3. **EventPlayer.swift** (MEDIUM PRIORITY)
**Path**: `/Users/jacklau/MacroRecorder/MacroRecorder/Services/EventPlayer.swift`
**Size**: 109 lines
**Purpose**: Plays back recorded events

**Critical Section**:
- Lines 80-108: `playOnce()` - Event playback loop

**What to do**:
```swift
// Before posting each event (around line 99):
if let windowInfo = event.windowInfo {
    // Focus the target window first
    windowTargeter.focusWindow(windowInfo)
    
    // Adjust coordinates if window moved
    let adjustedPosition = event.adjustedPosition(for: windowInfo)
}
```

---

### 4. **PreferencesView.swift** (MEDIUM PRIORITY)
**Path**: `/Users/jacklau/MacroRecorder/MacroRecorder/Views/PreferencesView.swift`
**Size**: 328 lines
**Purpose**: Settings/preferences UI

**What to do**:
- Add new "Window Recording" tab
- Allow users to select:
  - Record all windows
  - Record specific application only
  - Record specific window only
  - Exclude certain apps

---

### 5. **EventListView.swift** (LOW PRIORITY - UI ONLY)
**Path**: `/Users/jacklau/MacroRecorder/MacroRecorder/Views/EventListView.swift`
**Size**: 433 lines
**Purpose**: Display events in list format

**What to do**:
- Show window info in event rows
- Display relative coordinates instead of absolute
- Add window column to table

---

## NEW FILES TO CREATE

### 1. **WindowHelper.swift**
Utility functions for window operations:
```swift
class WindowHelper {
    static func getCurrentFocusedWindow() -> WindowInfo?
    static func getWindowInfo(from element: AXUIElement) -> WindowInfo?
    static func getApplicationName(pid: pid_t) -> String
    static func focusWindow(pid: pid_t) -> Bool
}
```

### 2. **WindowFilter.swift**
Filtering logic for recording:
```swift
class WindowFilter {
    enum RecordingMode {
        case allWindows
        case specificApplication(bundleID: String)
        case specificWindow(pid: pid_t)
        case excludeApplications([String])
    }
    
    func shouldRecord(in window: WindowInfo) -> Bool
}
```

### 3. **WindowTargeter.swift**
Playback coordination:
```swift
class WindowTargeter {
    func focusWindow(_ windowInfo: WindowInfo) -> Bool
    func adjustCoordinates(_ point: CGPoint, for window: WindowInfo) -> CGPoint
}
```

---

## KEY APIS TO USE

### Accessibility Framework (AX APIs)
```swift
import ApplicationServices

// Get system-wide element
let systemWide = AXUIElementCreateSystemwide()

// Get focused application
var focusedApp: AnyObject? = nil
AXUIElementCopyAttributeValue(
    systemWide, 
    kAXFocusedApplicationAttribute as CFString, 
    &focusedApp
)

// Get focused window of app
if let appRef = focusedApp as! AXUIElement? {
    var focusedWindow: AnyObject? = nil
    AXUIElementCopyAttributeValue(
        appRef, 
        kAXFocusedWindowAttribute as CFString, 
        &focusedWindow
    )
}

// Get window properties
AXUIElementCopyAttributeValue(window, kAXTitleAttribute as CFString, &title)
AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &position)
AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &size)
```

### Running Applications
```swift
import AppKit

// Get app by PID
let app = NSRunningApplication(processIdentifier: pid)

// Activate app
app?.activate(options: .activateIgnoringOtherApps)

// Get bundle ID
let bundleID = app?.bundleIdentifier

// Get localized name
let name = app?.localizedName
```

---

## IMPLEMENTATION PRIORITY & EFFORT

| Phase | Files | Effort | Impact |
|-------|-------|--------|--------|
| Phase 1: Model | MacroEvent.swift | 2 hours | Foundation |
| Phase 2: Capture | EventRecorder.swift | 4 hours | Core feature |
| Phase 3: Playback | EventPlayer.swift | 2 hours | Completeness |
| Phase 4: UI | PreferencesView, EventListView | 3 hours | Usability |
| Phase 5: Polish | Testing, optimization | 3 hours | Quality |

**Total**: ~14 hours for complete window-specific recording

---

## BACKWARD COMPATIBILITY

**IMPORTANT**: Use optional fields to maintain compatibility

```swift
// OLD events will have nil windowInfo
let oldEvent = MacroEvent(...) // windowInfo will be nil
let newEvent = MacroEvent(..., windowInfo: info)  // new events have info

// In playback: if windowInfo is nil, use absolute positioning (old behavior)
if let windowInfo = event.windowInfo {
    // New behavior: focus window and use relative coords
} else {
    // Old behavior: use absolute coords (backward compatible)
}
```

---

## TESTING CHECKLIST

### Unit Tests
- [ ] WindowInfo extraction from AX APIs
- [ ] WindowFilter logic for all modes
- [ ] Coordinate adjustment calculations
- [ ] Window focusing on non-existent window

### Integration Tests
- [ ] Record in single app, playback works
- [ ] Record in multiple apps, correct windows focused
- [ ] Export/import preserves window info
- [ ] Old macros still play back correctly

### Manual Testing
- [ ] Record in TextEdit only
- [ ] Switch apps during recording (filtered out)
- [ ] Playback focuses correct app
- [ ] Move window, playback still works
- [ ] Close target app, playback handles gracefully

---

## PERFORMANCE TIPS

1. **Cache Window Info**: Don't query AX APIs on every event
   - Listen for focus change notifications instead
   - Update cache only when focus changes

2. **Lazy Initialization**: Only query full window info when needed
   - Store just PID initially
   - Query full info on first access

3. **Async Operations**: Window focusing in playback can be async
   - Don't block event posting on window focus

4. **Error Handling**: AX APIs are fragile
   - Handle missing windows gracefully
   - Fall back to absolute positioning

---

## EXAMPLE IMPLEMENTATION FLOW

### Recording with Window Tracking:

```
1. Event tap fires → handleEvent()
2. Check if should record (filtering)
3. Query current focused window via AX APIs
4. Extract WindowInfo (PID, bundle ID, title, frame)
5. Calculate relative position (event.position - window.origin)
6. Create MacroEvent with windowInfo field
7. Append to recordedEvents
```

### Playback with Window Targeting:

```
1. User clicks Play
2. For each event in macro:
   a. If event.windowInfo exists:
      - Focus that window
      - Adjust coordinates relative to window position
   b. Create CGEvent with adjusted position
   c. Post event to system
3. If window not found:
   - Fall back to absolute coordinates
   - Log warning
```

---

## ACCESSIBILITY REQUIREMENTS

**Already in place**:
- App requests accessibility on launch (MacroRecorderApp.swift line 47)
- User sees permission prompt automatically
- Fallback if permission denied

**For window tracking**:
- Same accessibility permission covers AX API access
- No additional permissions needed

---

## USEFUL CONSTANTS & KEY CODES

### macOS Key Codes for Command Menu
```swift
let cmdKey = UInt32(cmdKey)           // 0x100
let shiftKey = UInt32(shiftKey)       // 0x20000
let optionKey = UInt32(optionKey)     // 0x80000
let controlKey = UInt32(controlKey)   // 0x40000
```

### AX Attribute Names
```swift
kAXFocusedApplicationAttribute
kAXFocusedWindowAttribute
kAXTitleAttribute
kAXPositionAttribute
kAXSizeAttribute
kAXWindowsAttribute
kAXMainWindowAttribute
```

---

## COMMON PITFALLS TO AVOID

1. **Don't call AX APIs in event callback** - too slow
   - Cache window info instead
   - Update on notification

2. **Don't forget optional fields** - breaks compatibility
   - Use `windowInfo: WindowInfo?`
   - Handle nil case in playback

3. **Don't assume window exists** at playback time
   - User might close app between record/playback
   - Have fallback to absolute coordinates

4. **Don't convert coordinates incorrectly**
   - CGPoint origin is different between frameworks
   - Test with multi-monitor setups

---

## FILE CHECKLIST FOR MODIFICATIONS

- [ ] MacroEvent.swift - Add WindowInfo struct and fields
- [ ] EventRecorder.swift - Capture window info in handleEvent()
- [ ] EventPlayer.swift - Focus window before playback
- [ ] WindowHelper.swift - Create new utility file
- [ ] WindowFilter.swift - Create new filtering file
- [ ] WindowTargeter.swift - Create new playback file
- [ ] PreferencesView.swift - Add window recording tab
- [ ] EventListView.swift - Display window info
- [ ] ContentView.swift - Pass filter to recorder

---

## RESOURCES & REFERENCES

### macOS Accessibility APIs
- Apple Developer: Accessibility Programming Guide
- Framework: ApplicationServices (AXUIElement)

### CGEvent Documentation
- Apple Developer: Core Graphics Event Tap
- Framework: CoreGraphics (CGEvent)

### SwiftUI & macOS
- Apple Developer: SwiftUI Documentation
- Framework: AppKit (NSRunningApplication, NSWorkspace)

