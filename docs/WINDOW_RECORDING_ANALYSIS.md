# MacroRecorder Application Structure Analysis
## Comprehensive Guide for Window-Specific Recording Features

Generated: November 14, 2025

---

## 1. PROJECT OVERVIEW

**MacroRecorder** is a macOS application written in SwiftUI that records and plays back mouse and keyboard events. Currently, it records ALL system-wide events without any window-specific filtering.

### Current Architecture
- **Swift Version**: 5.9+
- **Minimum OS**: macOS 13.0+
- **Build System**: Xcode (SPM available)
- **Total Swift Files**: 15 files (~3,100 LOC)

### Core Dependencies
- **CoreGraphics**: For event capture and posting (CGEvent)
- **ApplicationServices**: For accessibility APIs (AX utilities)
- **Carbon**: For hotkey management (EventHotKeyRef)
- **SwiftUI**: For UI
- **Combine**: For reactive patterns
- **AppKit**: For native macOS integration

---

## 2. FILE STRUCTURE AND LOCATIONS

```
/Users/jacklau/MacroRecorder/MacroRecorder/
├── Models/
│   └── MacroEvent.swift              (190 lines)
├── Services/
│   ├── EventRecorder.swift           (195 lines) *** KEY FOR RECORDING ***
│   ├── EventPlayer.swift             (109 lines)
│   ├── MacroSession.swift            (193 lines)
│   └── HotkeyManager.swift           (228 lines)
├── Views/
│   ├── ContentView.swift             (247 lines)
│   ├── ControlsView.swift            (166 lines)
│   ├── EventListView.swift           (433 lines)
│   ├── EventEditorView.swift         (375 lines)
│   ├── MacroListView.swift           (145 lines)
│   ├── StatusBarView.swift           (93 lines)
│   ├── StatusOverlayView.swift       (163 lines)
│   ├── PreferencesView.swift         (328 lines)
│   └── KeybindCaptureView.swift      (158 lines)
├── MacroRecorderApp.swift            (85 lines)
└── Info.plist
```

---

## 3. EVENT RECORDING MECHANISM

### 3.1 EventRecorder.swift - Core Recording Engine

**Location**: `/Users/jacklau/MacroRecorder/MacroRecorder/Services/EventRecorder.swift`

#### Key Components:
```swift
class EventRecorder: ObservableObject {
    @Published var isRecording = false
    @Published var recordedEvents: [MacroEvent] = []
    
    private var eventTap: CFMachPort?           // System event tap
    private var runLoopSource: CFRunLoopSource? // Event processing
    private var lastEventTime: TimeInterval = 0
    private var startTime: TimeInterval = 0
    
    var recordingHotkey: (keyCode: UInt32, modifiers: UInt32)?
    var playbackHotkey: (keyCode: UInt32, modifiers: UInt32)?
}
```

#### Event Capture Method:
- Uses **CGEvent.tapCreate()** with:
  - **Tap Position**: `.cgSessionEventTap` (system-wide)
  - **Tap Option**: `.listenOnly` (non-invasive monitoring)
  - **Event Mask**: 10 event types (see below)
  - **Callback**: Uses unmanaged pointer to self

#### Events Captured:
1. **Mouse Events**:
   - `leftMouseDown` / `leftMouseUp`
   - `rightMouseDown` / `rightMouseUp`
   - `mouseMoved` (throttled to >100ms delays)
   - `leftMouseDragged` / `rightMouseDragged`

2. **Keyboard Events**:
   - `keyDown` / `keyUp`

3. **Scroll Events**:
   - `scrollWheel`

#### Key Recording Functions:

**startRecording()** (Line 51-104):
```
1. Clear previous events
2. Set startTime
3. Create event tap callback (closure with unmanaged self pointer)
4. Install event tap with .listenOnly option
5. Add to run loop
6. Enable tap
```

**handleEvent()** (Line 124-185):
- Called for each captured event
- Filters out recording/playback hotkeys
- Throttles mouse moves (skips if delay < 0.1s)
- Converts CGEvent → MacroEvent
- Appends to recordedEvents array

**Filtering**:
- Hotkeys are filtered to prevent recording the trigger keys
- Mouse move filtering reduces noise

#### Accessibility Check:
```swift
func checkAccessibilityPermissions() -> Bool {
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
    return AXIsProcessTrustedWithOptions(options)
}
```

### 3.2 MacroEvent.swift - Event Data Model

**Location**: `/Users/jacklau/MacroRecorder/MacroRecorder/Models/MacroEvent.swift`

#### MacroEvent Structure:
```swift
struct MacroEvent: Codable, Identifiable {
    let id: UUID
    let type: EventType              // Enum of 9 types
    let timestamp: TimeInterval      // Absolute time
    let position: CGPoint?           // Mouse position
    let keyCode: UInt16?            // Keyboard key code
    let flags: UInt64?              // Modifier flags
    let scrollDeltaX: Double?       // Scroll horizontal
    let scrollDeltaY: Double?       // Scroll vertical
    var delay: TimeInterval         // Time since previous event
}

enum EventType: String, Codable {
    case mouseLeftDown, mouseLeftUp, mouseRightDown, mouseRightUp
    case mouseMove, mouseDrag
    case keyDown, keyUp
    case scroll
}
```

**Key Methods**:
- `MacroEvent.from(cgEvent:delay:)` - Converts CGEvent → MacroEvent
- `toCGEvent()` - Converts MacroEvent → CGEvent for playback

**Important**: Events store absolute screen coordinates (CGPoint), NO window information

#### Macro Structure:
```swift
struct Macro: Codable, Identifiable {
    let id: UUID
    var name: String
    var events: [MacroEvent]
    let createdAt: Date
    var modifiedAt: Date
}
```

---

## 4. EVENT PLAYBACK MECHANISM

### 4.1 EventPlayer.swift

**Location**: `/Users/jacklau/MacroRecorder/MacroRecorder/Services/EventPlayer.swift`

#### Playback Modes:
```swift
enum PlaybackMode {
    case once
    case count(Int)      // Loop N times
    case infinite
}
```

#### Playback Flow:
```swift
func play(events: [MacroEvent], mode: PlaybackMode, speed: Double)
    → performPlayback() async
    → playOnce() for each loop
    → For each event:
       1. Wait for event.delay (adjusted by speed)
       2. Convert MacroEvent → CGEvent
       3. Post event via cgEvent.post(tap: .cghidEventTap)
```

**Critical Point**: Events are posted to **system-wide HID tap**, not to specific windows

---

## 5. SESSION MANAGEMENT

### 5.2 MacroSession.swift

**Location**: `/Users/jacklau/MacroRecorder/MacroRecorder/Services/MacroSession.swift`

```swift
class MacroSession: ObservableObject {
    @Published var currentMacro: Macro?
    @Published var isRecording: Bool
    @Published var isPlaying: Bool
    
    let recorder = EventRecorder()
    let player = EventPlayer()
    
    // UserDefaults persistence key
    private let storageKey = "SavedMacros"
}
```

#### Key Responsibilities:
1. **Recording Management**: Coordinates between UI and EventRecorder
2. **Playback Management**: Coordinates between UI and EventPlayer
3. **Event Editing**: CRUD operations on events
4. **Persistence**: Saves/loads macros to UserDefaults as JSON

#### Storage:
- Uses UserDefaults.standard
- Encodes [Macro] to JSON using JSONEncoder
- Supports import/export as JSON files

---

## 6. HOTKEY MANAGEMENT

### 6.1 HotkeyManager.swift

**Location**: `/Users/jacklau/MacroRecorder/MacroRecorder/Services/HotkeyManager.swift`

```swift
class HotkeyManager: ObservableObject {
    @Published var recordingHotkey: (keyCode: UInt32, modifiers: UInt32)
    @Published var playbackHotkey: (keyCode: UInt32, modifiers: UInt32)
    
    private var recordingEventHandler: EventHotKeyRef?
    private var playbackEventHandler: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    
    var onRecordingTriggered: (() -> Void)?
    var onPlaybackTriggered: (() -> Void)?
}
```

#### Default Hotkeys:
- **Recording**: `⌘⇧/` (keyCode: 0x2C, modifiers: cmdKey | shiftKey)
- **Playback**: `⌘⇧P` (keyCode: 0x23, modifiers: cmdKey | shiftKey)

#### Implementation:
- Uses Carbon framework EventHotKey APIs
- Registers at application level
- Handlers called globally (not window-specific)

---

## 7. USER INTERFACE COMPONENTS

### 7.1 ContentView.swift - Main Application View

**Location**: `/Users/jacklau/MacroRecorder/MacroRecorder/Views/ContentView.swift`

```swift
struct ContentView: View {
    @StateObject private var session = MacroSession()
    @StateObject private var hotkeyManager = HotkeyManager()
    
    @AppStorage("showStatusOverlay") private var showStatusOverlay: Bool = true
    @State private var statusOverlayWindow: StatusOverlayWindow?
}
```

**Layout**: HSplitView with:
- Left sidebar: MacroListView (saved macros)
- Main area: ControlsView, EventListView, StatusBarView

### 7.2 EventListView.swift - Event Display

**Location**: `/Users/jacklau/MacroRecorder/MacroRecorder/Views/EventListView.swift`

#### Features:
- List of all events in current macro
- Multi-select with Shift/Cmd modifiers
- Timeline visualization (horizontal bar with event dots)
- Drag-and-drop reordering
- Edit/delete actions

#### Event Display:
```
Index | Type Icon | Type Name | Details (position or key) | Delay (s)
```

**Note**: Shows absolute screen coordinates, NOT window info

### 7.3 StatusOverlayView.swift - Real-time Overlay

**Location**: `/Users/jacklau/MacroRecorder/MacroRecorder/Views/StatusOverlayView.swift`

#### Features:
- Floating window showing recording/playback status
- Positions: top-left, top-right, bottom-left, bottom-right
- Recording: shows red dot + event count
- Playback: shows progress, loop count
- Non-interactive (`allowsHitTesting(false)`)

#### Window Properties:
```swift
class StatusOverlayWindow: NSWindow {
    .styleMask: [.borderless]
    .level: .statusBar              // Above most windows
    .ignoresMouseEvents: true
    .collectionBehavior: [.canJoinAllSpaces, .stationary, .ignoresCycle]
}
```

### 7.4 PreferencesView.swift - Settings

**Location**: `/Users/jacklau/MacroRecorder/MacroRecorder/Views/PreferencesView.swift`

#### Tabs:
1. **General**: Status overlay, playback speed, playback mode
2. **Recording**: Mouse move recording, mouse move threshold
3. **Hotkeys**: View current hotkeys (customization disabled)
4. **About**: Feature list and version

---

## 8. CURRENT LIMITATIONS - NO WINDOW TRACKING

### What's Missing for Window-Specific Recording:

**1. NO Window Identification**:
   - Events only capture absolute screen coordinates
   - No window PID, bundle ID, or process name
   - No way to associate events with specific applications

**2. NO Window Focus Tracking**:
   - Application focus not recorded
   - Window switching during recording not captured
   - No context about which window each event targeted

**3. NO Workspace Awareness**:
   - Screen coordinates are absolute (0,0 at top-left)
   - No awareness of window positions or size
   - No relative positioning within windows

**4. Recording is System-Wide**:
   - EventRecorder captures ALL mouse/keyboard events
   - No filtering by window or application
   - Hotkeys recorded same way as regular events

**5. Playback is Absolute**:
   - Events posted to system-wide HID tap
   - No window focus before playback
   - No coordinate adjustment for different window positions

---

## 9. EXTERNAL APIs & FRAMEWORKS USED

### CoreGraphics (CGEvent) - Main Event Capture
```swift
// From EventRecorder.swift
CGEvent.tapCreate(
    tap: .cgSessionEventTap,        // System-wide
    place: .headInsertEventTap,     // Before other taps
    options: .listenOnly,           // Don't modify events
    eventsOfInterest: eventMask,    // Bit mask of event types
    callback: callback,             // Unmanaged closure
    userInfo: selfPointer           // Pass self
)

// From EventPlayer.swift
cgEvent.post(tap: .cghidEventTap)  // Post to HID system
```

### ApplicationServices - Accessibility
```swift
// From EventRecorder.swift
AXIsProcessTrustedWithOptions(options)  // Check accessibility
kAXTrustedCheckOptionPrompt             // Prompt if needed
```

### Carbon - Global Hotkeys
```swift
// From HotkeyManager.swift
RegisterEventHotKey(keyCode, modifiers, hotKeyID, target, options, &handler)
```

### AppKit - Native Integration
```swift
// Various views
NSWindow, NSView, NSEvent, NSScreen, NSApplication
NSWorkspace.shared.open(url)        // Open system settings
NSAlert                             // Show dialogs
```

---

## 10. DATA FLOW DIAGRAM

### Recording Flow:
```
User Action (keyboard/mouse)
    ↓
CGEvent (from OS)
    ↓
EventRecorder.eventTap (CFMachPort callback)
    ↓
EventRecorder.handleEvent()
    ├─ Filter hotkeys
    ├─ Throttle mouse moves
    └─ Convert CGEvent → MacroEvent
    ↓
EventRecorder.recordedEvents[] (array)
    ↓
(User clicks "Save")
    ↓
MacroSession.saveCurrentMacro()
    ↓
Macro { name, events[], timestamps } (Codable)
    ↓
JSONEncoder
    ↓
UserDefaults.standard (persistent)
```

### Playback Flow:
```
User clicks "Play"
    ↓
MacroSession.play(macro:)
    ↓
EventPlayer.play(events:)
    ↓
EventPlayer.performPlayback() async
    ├─ For each loop in mode:
    └─ For each event:
        ├─ Wait event.delay (adjusted by speed)
        ├─ Convert MacroEvent → CGEvent
        └─ cgEvent.post(tap: .cghidEventTap)
    ↓
OS receives CGEvent
    ↓
Application processes event
```

---

## 11. KEY ARCHITECTURAL PATTERNS

### 1. MVVM Pattern
- **Models**: MacroEvent, Macro, HotkeyConfig
- **ViewModels**: MacroSession, EventRecorder, EventPlayer, HotkeyManager
- **Views**: SwiftUI views with @ObservedObject bindings

### 2. Unmanaged Pointers for C Callbacks
```swift
// In EventRecorder.startRecording()
let selfPointer = Unmanaged.passUnretained(self).toOpaque()
// In callback:
let recorder = Unmanaged<EventRecorder>.fromOpaque(refcon).takeUnretainedValue()
```

### 3. Codable for Serialization
```swift
struct MacroEvent: Codable { ... }
struct Macro: Codable { ... }
struct HotkeyConfig: Codable { ... }
```

### 4. ObservableObject for Reactive UI
```swift
class MacroSession: ObservableObject {
    @Published var isRecording: Bool
    @Published var recordedEvents: [MacroEvent]
}
```

### 5. UserDefaults for Persistence
```swift
UserDefaults.standard.set(data, forKey: "SavedMacros")
UserDefaults.standard.data(forKey: "SavedMacros")
```

---

## 12. ENTRYPOINTS FOR WINDOW-SPECIFIC FEATURES

### Option A: Minimal Changes (Add Window Tracking to Events)
**Modified Files**: MacroEvent.swift, EventRecorder.swift

**Add to MacroEvent**:
```swift
struct MacroEvent: Codable {
    // Existing fields...
    
    // NEW:
    var windowInfo: WindowInfo?  // Optional: PID, bundle ID, window title
    var relativePosition: CGPoint?  // Position relative to window
}

struct WindowInfo: Codable {
    var processID: pid_t
    var bundleID: String
    var windowTitle: String
    var applicationName: String
}
```

**Modify EventRecorder.handleEvent()**:
```swift
// Use AXUIElementCreateSystemwide() to find focused window
let systemWideElement = AXUIElementCreateSystemwide()
// Extract window info before creating MacroEvent
```

---

### Option B: Window-Specific Recording Filter
**New File**: WindowFilter.swift

```swift
class WindowFilter {
    var recordingModeFilter: RecordingMode = .allWindows
    var targetWindow: (pid: pid_t, bundleID: String)?
    
    enum RecordingMode {
        case allWindows
        case specificWindow(pid: pid_t)
        case specificApplication(bundleID: String)
        case excludeApplications([String])
    }
    
    func shouldRecordEvent(_ event: MacroEvent, inWindow: WindowInfo) -> Bool {
        // Filter logic
    }
}
```

**Modify EventRecorder**:
```swift
class EventRecorder: ObservableObject {
    var windowFilter = WindowFilter()
    
    private func handleEvent(event: CGEvent, type: CGEventType) {
        // Get current window
        let window = getCurrentFocusedWindow()
        
        // Check filter
        if !windowFilter.shouldRecordEvent(macroEvent, inWindow: window) {
            return
        }
        
        recordedEvents.append(macroEvent)
    }
}
```

---

### Option C: Window-Aware Playback
**New File**: WindowTargeting.swift

```swift
class WindowTargeter {
    func focusWindow(_ windowInfo: WindowInfo) throws {
        let app = NSRunningApplication(processIdentifier: windowInfo.processID)
        app?.activate(options: .activateIgnoringOtherApps)
        
        // Find and focus specific window via AX APIs
    }
    
    func adjustCoordinates(_ position: CGPoint, for window: WindowInfo) -> CGPoint {
        // Convert absolute → window-relative → adjusted absolute
    }
}
```

**Modify EventPlayer**:
```swift
class EventPlayer: ObservableObject {
    var windowTargeter = WindowTargeter()
    
    private func playOnce() async {
        for event in events {
            // If event has window info, focus that window first
            if let windowInfo = event.windowInfo {
                try? windowTargeter.focusWindow(windowInfo)
            }
            
            // Adjust coordinates if needed
            let adjustedEvent = event.adjusted(for: windowInfo)
            
            // Post adjusted event
        }
    }
}
```

---

## 13. ACCESSIBILITY FRAMEWORK (AX API) INTEGRATION POINTS

### Available macOS Accessibility APIs for Window Tracking:

**1. Get Focused Window**:
```swift
import AppKit

let systemWideElement = AXUIElementCreateSystemwide()
var focusedApp: AnyObject? = nil
AXUIElementCopyAttributeValue(systemWideElement, kAXFocusedApplicationAttribute as CFString, &focusedApp)

if let appRef = focusedApp as! AXUIElement? {
    var focusedWindow: AnyObject? = nil
    AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &focusedWindow)
}
```

**2. Get Window Information**:
```swift
var pidRef: AnyObject? = nil
AXUIElementCopyAttributeValue(windowElement, kAXParentAttribute as CFString, &pidRef)

var titleRef: AnyObject? = nil
AXUIElementCopyAttributeValue(windowElement, kAXTitleAttribute as CFString, &titleRef)

var posRef: AnyObject? = nil
AXUIElementCopyAttributeValue(windowElement, kAXPositionAttribute as CFString, &posRef)

var sizeRef: AnyObject? = nil
AXUIElementCopyAttributeValue(windowElement, kAXSizeAttribute as CFString, &sizeRef)
```

**3. From NSEvent**:
```swift
// In event callback:
let event = NSEvent.from(cgEvent)  // Note: not available in C callback context
let pid = event.windowProcessSerialNumber  // May be limited info
```

---

## 14. RECOMMENDED APPROACH FOR WINDOW-SPECIFIC RECORDING

Based on the architecture analysis, here's the recommended approach:

### Phase 1: Capture Window Information
1. **Add WindowInfo struct** to MacroEvent
2. **Query AX APIs** in EventRecorder.handleEvent() to get focused window
3. **Store window metadata** (PID, bundle ID, window title) with each event
4. **Store relative coordinates** by calculating offset from window bounds

### Phase 2: Filtering
1. **Add RecordingFilter** to EventRecorder
2. **Allow users to select**:
   - Record all windows
   - Record specific application only
   - Record specific window only
   - Exclude certain applications
3. **Filter in handleEvent()** before appending to recordedEvents

### Phase 3: Playback Adaptation
1. **Add WindowTargeter** class
2. **Before playback**, focus the target window(s)
3. **Adjust mouse coordinates** if target window is in different position
4. **Handle missing windows** gracefully

### Phase 4: UI Updates
1. Add preferences tab for "Window Recording"
2. Show window info in EventListView
3. Add window selection UI to PreferencesView
4. Display target window during playback

---

## 15. FILE DEPENDENCY MAP

```
MacroRecorderApp.swift
    ├→ ContentView.swift
    │   ├→ MacroSession.swift
    │   │   ├→ EventRecorder.swift
    │   │   │   ├→ MacroEvent.swift (Models)
    │   │   │   └→ HotkeyManager.swift (filters hotkeys)
    │   │   └→ EventPlayer.swift
    │   │       └→ MacroEvent.swift
    │   ├→ HotkeyManager.swift
    │   ├→ MacroListView.swift
    │   ├→ ControlsView.swift
    │   ├→ EventListView.swift
    │   │   ├→ EventEditorView.swift
    │   │   └→ TimelineView (inline)
    │   ├→ StatusBarView.swift
    │   └→ StatusOverlayView.swift
    │       ├→ StatusOverlayWindow.swift
    │       └→ MacroSession.swift
    └→ PreferencesView.swift
        ├→ HotkeyManager.swift
        └→ KeybindCaptureView.swift
```

---

## 16. SUMMARY TABLE: CURRENT CAPABILITIES VS. NEEDED FEATURES

| Feature | Current | Needed for Window-Specific Recording |
|---------|---------|--------------------------------------|
| Event Capture | System-wide CGEvent tap | + Window identification at capture time |
| Event Metadata | Type, position, timing | + Window PID, bundle ID, title, relative position |
| Filtering | Hotkey filtering only | + By window, application, process |
| Playback | Post to HID system tap | + Focus specific window first, adjust coordinates |
| Storage | JSON with absolute coords | + Window metadata, relative coordinates |
| UI Display | Absolute coordinates only | + Window info, relative positions |
| Preferences | Limited options | + Window recording modes and targeting |

---

## 17. CRITICAL CODE SECTIONS FOR MODIFICATION

### Section A: Event Recording (EventRecorder.swift lines 124-185)
**Function**: `handleEvent()`
**Purpose**: Process each captured CGEvent
**Modification Point**: After event validation, before MacroEvent creation

### Section B: Event Model (MacroEvent.swift lines 21-52)
**Struct**: `MacroEvent`
**Purpose**: Event data container
**Modification Point**: Add optional WindowInfo field

### Section C: Playback Loop (EventPlayer.swift lines 80-108)
**Function**: `playOnce()`
**Purpose**: Execute recorded events
**Modification Point**: Before posting each event, focus target window

### Section D: Session Management (MacroSession.swift lines 38-56)
**Functions**: `startRecording()`, `stopRecording()`
**Purpose**: Coordinate recording/playback
**Modification Point**: Pass recording filter settings to EventRecorder

---

## 18. TESTING STRATEGY FOR NEW FEATURES

### Unit Tests Needed:
1. WindowFilter.shouldRecordEvent() with various modes
2. WindowTargeter.adjustCoordinates() calculations
3. WindowInfo extraction from AX APIs
4. Relative position calculations

### Integration Tests:
1. Record in specific app, playback in same app
2. Record in one app, playback in another
3. Window focused/unfocused during recording
4. Window moving during playback

### Manual Testing:
1. Record macro in specific app only
2. Switch to different app during recording (should not record if filtered)
3. Playback targets and focuses correct window
4. Macros work after window is moved
5. Export/import preserves window info

---

## 19. PERFORMANCE CONSIDERATIONS

### Current Performance Characteristics:
- Event tap callback runs on high-priority thread
- Mouse move throttling at 100ms helps reduce event volume
- JSON serialization of large macros (~10k events) is manageable

### Window-Specific Additions Performance Impact:
- AX API calls in hot path (event callback) should be minimal
- **Recommendation**: Cache current window info, update only on focus change
- Use window tracking notification instead of per-event lookup

### Optimized Approach:
```swift
class EventRecorder {
    private var cachedWindowInfo: WindowInfo?
    private var windowChangeMonitor: NSObject?  // Listen for focus events
    
    private func updateWindowInfoIfNeeded() {
        // Only query AX when window actually changed
        // Use NSWorkspace or other notification mechanism
    }
}
```

---

## CONCLUSION

MacroRecorder is a well-structured application with clear separation of concerns. The current architecture makes it straightforward to add window-specific recording by:

1. **Extending MacroEvent** with window metadata
2. **Adding window monitoring** to EventRecorder
3. **Implementing filtering** in the recording pipeline
4. **Enhancing playback** with window focusing
5. **Updating UI** to show and control window-specific options

The use of Codable makes backward compatibility easy, and the SwiftUI reactive patterns make UI updates natural. The main technical challenge is working with macOS Accessibility APIs, which have specific requirements for permission and threading.

