# MacroRecorder Codebase Analysis - Executive Summary

## What I've Analyzed

I've completed a comprehensive analysis of the MacroRecorder application to understand its structure and identify how to add window-specific recording features. This analysis covers all 15 Swift files (~3,100 lines of code) across the Models, Services, Views, and App layers.

## Key Findings

### Current State: System-Wide Recording Only
- The app captures ALL mouse and keyboard events from the entire system
- Events store only absolute screen coordinates (no window information)
- Recording happens via a system-level CGEvent tap
- Playback posts events to the system-wide HID tap

### Architecture Quality: Excellent
- Clean MVVM pattern with clear separation of concerns
- Well-organized file structure (Models, Services, Views)
- Proper use of Swift modern patterns (SwiftUI, Combine, Codable)
- Backward-compatible design ready for extensions

## Three Analysis Documents Created

### 1. **WINDOW_RECORDING_ANALYSIS.md** (24 KB)
**Most Comprehensive** - Detailed technical analysis covering:
- Complete file structure and locations
- Event recording mechanism (CGEvent tap details)
- Event data model structure
- Playback mechanism
- Session management
- Hotkey system
- All UI components
- Current limitations
- External APIs used (CoreGraphics, ApplicationServices, Carbon, AppKit)
- 3 implementation approaches (minimal, filtering, playback-aware)
- AX API integration points
- Recommended phased approach
- File dependency map
- Critical code sections
- Testing strategy
- Performance considerations

**Best For**: Deep technical understanding, implementation planning

### 2. **WINDOW_TRACKING_QUICK_REFERENCE.md** (8 KB)
**Most Practical** - Quick action guide covering:
- Top 5 files to modify (with priorities)
- 3 new files to create
- Key APIs to use
- Implementation priority matrix
- Backward compatibility strategy
- Testing checklist
- Performance tips
- Example implementation flows
- Common pitfalls to avoid
- File modification checklist

**Best For**: Starting implementation, quick lookups

### 3. **ANALYSIS_SUMMARY.md** (This file)
**Quick Overview** - Executive summary covering:
- What was analyzed
- Key findings
- File locations
- Main recording mechanism
- Event data model
- How to extend for windows
- Next steps

---

## Core Files You Need to Know

### Recording Pipeline
```
System Event (keyboard/mouse)
    ↓
EventRecorder (Uses CGEvent tap)  ← START HERE FOR WINDOW TRACKING
    ↓
MacroEvent (Data model - add WindowInfo here)
    ↓
MacroSession (Coordination layer)
    ↓
UserDefaults (Persistence as JSON)
```

### Playback Pipeline
```
MacroSession (Load macro)
    ↓
EventPlayer (Async playback)  ← MODIFY FOR WINDOW-AWARE PLAYBACK
    ↓
CGEvent.post() (Posts to HID system)
    ↓
OS Routes to Target Window
```

---

## Most Important Files & Locations

| File | Path | Size | Priority | Why Important |
|------|------|------|----------|---------------|
| **EventRecorder.swift** | `/Services/` | 195 lines | HIGHEST | WHERE events are captured - add window detection here |
| **MacroEvent.swift** | `/Models/` | 190 lines | HIGH | Event data model - extend with WindowInfo struct |
| **EventPlayer.swift** | `/Services/` | 109 lines | MEDIUM | Playback engine - add window focusing |
| **MacroSession.swift** | `/Services/` | 193 lines | MEDIUM | Coordinator - pass filter settings |
| **PreferencesView.swift** | `/Views/` | 328 lines | MEDIUM | UI for window recording options |
| **ContentView.swift** | `/Views/` | 247 lines | LOW | Main window - minimal changes needed |
| **EventListView.swift** | `/Views/` | 433 lines | LOW | Display - show window info in list |

---

## How Event Recording Currently Works

### Step 1: System Level
```swift
let eventTap = CGEvent.tapCreate(
    tap: .cgSessionEventTap,        // System-wide monitoring
    place: .headInsertEventTap,     // Before other taps
    options: .listenOnly,           // Don't modify events
    eventsOfInterest: eventMask,    // 10 types: mouse clicks, moves, drags, keyboard, scroll
    callback: callback,              // Function to handle events
    userInfo: selfPointer           // Reference to EventRecorder instance
)
```

### Step 2: Event Callback
```swift
// Called for every captured event
private func handleEvent(event: CGEvent, type: CGEventType) {
    // Current logic:
    // 1. Filter hotkeys (don't record Cmd+Shift+/)
    // 2. Throttle mouse moves (skip if < 100ms)
    // 3. Convert CGEvent → MacroEvent
    // 4. Append to recordedEvents array
}
```

### Step 3: Event Model
```swift
struct MacroEvent: Codable {
    let id: UUID
    let type: EventType                // .mouseLeftDown, .keyDown, etc.
    let timestamp: TimeInterval        // When it happened
    let position: CGPoint?             // Screen coordinates ONLY
    let keyCode: UInt16?              // For keyboard events
    let flags: UInt64?                // Modifier keys (Cmd, Shift, etc.)
    let scrollDeltaX: Double?         // For scroll events
    let scrollDeltaY: Double?
    var delay: TimeInterval           // Time since previous event
    // NO WINDOW INFORMATION! ← THIS IS WHAT NEEDS ADDING
}
```

### Step 4: Persistence
```swift
// Stored in UserDefaults as JSON
Macro {
    id: UUID
    name: String
    events: [MacroEvent]              // Array of all recorded events
    createdAt: Date
    modifiedAt: Date
}
```

---

## How to Add Window-Specific Recording

### Approach: Extend the Model, Filter in Recording, Focus in Playback

**Phase 1: Extend MacroEvent** (2 hours)
```swift
struct WindowInfo: Codable {
    var processID: pid_t              // Application process ID
    var bundleID: String              // com.apple.TextEdit
    var windowTitle: String           // Window name
    var applicationName: String       // "TextEdit"
    var windowFrame: CGRect            // Position and size
}

struct MacroEvent: Codable {
    // ... existing fields ...
    var windowInfo: WindowInfo?        // NEW - optional for backward compatibility
    var relativePosition: CGPoint?     // NEW - position relative to window
}
```

**Phase 2: Capture Window Info** (4 hours)
```swift
// In EventRecorder.handleEvent():
let focusedWindow = getCurrentFocusedWindow()      // Query AX APIs
let windowInfo = extractWindowInfo(focusedWindow)  // Get metadata
let shouldRecord = filterCheck(windowInfo)         // Filter if needed
let macroEvent = createEvent(cgEvent, windowInfo)  // Add window info
```

**Phase 3: Use Window Info in Playback** (2 hours)
```swift
// In EventPlayer.playOnce():
for event in events {
    if let windowInfo = event.windowInfo {
        windowTargeter.focusWindow(windowInfo)     // Focus app first
        let adjusted = adjustCoordinates(for: windowInfo)
        cgEvent.post(tap: .cghidEventTap)          // Post to focused window
    }
}
```

**Phase 4: UI & Settings** (3 hours)
- Add "Window Recording" tab to preferences
- Show window info in event list
- Allow filtering: all windows, specific app, specific window, exclude apps

---

## Key Technical Details

### Event Tap Callback
- Runs on a high-priority thread
- Used for capturing all system events
- Cannot perform long operations here
- Recommendation: Cache window info, don't query on every event

### Accessibility APIs (AX)
```swift
import ApplicationServices

AXUIElementCreateSystemwide()                    // Get system element
AXUIElementCopyAttributeValue()                  // Read element attributes
// Attributes: kAXFocusedApplicationAttribute, kAXFocusedWindowAttribute, kAXTitleAttribute
```

### Running Applications
```swift
import AppKit

NSRunningApplication(processIdentifier: pid)    // Get app by PID
app?.activate(options: .activateIgnoringOtherApps)  // Focus app
app?.bundleIdentifier                           // Get bundle ID
```

### Backward Compatibility
- Use optional fields (WindowInfo?)
- Old recorded events will have nil windowInfo
- Playback checks if windowInfo exists before using it
- Falls back to absolute positioning if nil

---

## Files Generated for You

1. **WINDOW_RECORDING_ANALYSIS.md**
   - 24 KB comprehensive technical guide
   - Every file analyzed with line numbers
   - APIs, patterns, data structures
   - 3 different implementation approaches
   - Performance analysis and tips

2. **WINDOW_TRACKING_QUICK_REFERENCE.md**
   - 8 KB quick start guide
   - Top 5 files to modify with exact sections
   - 3 new files to create
   - Example code snippets
   - Common pitfalls and solutions

3. **ANALYSIS_SUMMARY.md** (this file)
   - High-level overview
   - Key files and locations
   - Core mechanisms
   - Quick reference

---

## Recommended Next Steps

### If implementing window-specific recording:

1. **Start with MacroEvent.swift** (Easiest)
   - Add WindowInfo struct
   - Add optional fields to MacroEvent
   - Takes ~2 hours
   - No breaking changes (optional fields)

2. **Then EventRecorder.swift** (Core logic)
   - Add window capture in handleEvent()
   - Implement window filtering
   - Most complex part - ~4 hours
   - Performance critical

3. **Then EventPlayer.swift** (Playback)
   - Add window focusing before events
   - Adjust coordinates if needed
   - ~2 hours

4. **Finally UI updates** (Polish)
   - Add preferences tab
   - Show window info in event list
   - ~3 hours total

5. **Testing & optimization** (~3 hours)

**Total: ~14 hours for complete feature**

---

## Key Code Locations You'll Need

### Event Capture (EventRecorder.swift)
- Line 51: `startRecording()` - Initialize event tap
- Line 124: `handleEvent()` - WHERE TO ADD WINDOW TRACKING
- Line 187: `checkAccessibilityPermissions()` - Permission check (already works)

### Event Model (MacroEvent.swift)
- Line 21: `MacroEvent struct` - ADD WindowInfo here
- Line 55: `from(cgEvent:)` - Conversion from CGEvent

### Event Playback (EventPlayer.swift)
- Line 28: `play()` - Start playback
- Line 80: `playOnce()` - Event loop, ADD window focusing here

### UI Components
- Line 46-58 in PreferencesView.swift - Where to add Window Recording tab
- Line 183-200 in EventListView.swift - Event row display (show window info)

---

## Important Notes

### Permissions Already Handled
- App requests Accessibility permission on launch
- Same permission allows AX API access
- User gets automatic prompt

### Backward Compatibility
- Use optional fields (WindowInfo?)
- Old macros will still work (windowInfo = nil)
- Graceful fallback to absolute positioning

### Performance
- Window info querying should be cached
- Don't call AX APIs on every event
- Listen for focus change notifications instead

### Multi-Monitor Support
- Screen coordinates are absolute (0,0 at main screen top-left)
- Relative positioning helps here
- Test across multiple displays

---

## Summary

MacroRecorder is a well-architected application that's well-positioned for adding window-specific recording. The MVVM pattern, clean separation, and use of Codable make it straightforward to extend. The main implementation challenge is learning the macOS AX APIs for window detection, but I've provided specific code examples and API calls needed.

All three analysis documents are saved in the repo root:
- `/WINDOW_RECORDING_ANALYSIS.md` - Full technical details
- `/WINDOW_TRACKING_QUICK_REFERENCE.md` - Quick implementation guide
- `/ANALYSIS_SUMMARY.md` - This overview

Use the Quick Reference to get started, refer to the full analysis for details.

