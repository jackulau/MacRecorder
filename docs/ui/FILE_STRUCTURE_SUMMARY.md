# MacroRecorder - Complete File Structure & Dependencies

## File Organization Summary

```
MacroRecorder/ (Root Project)
├── MacroRecorderApp.swift          Entry point (@main) - 77 lines
├── Info.plist                      App configuration
├── Package.swift                   SPM configuration
│
├── Models/
│   └── MacroEvent.swift            Event types & data structures - 191 lines
│       ├── EventType (enum, 9 cases)
│       ├── MacroEvent (struct, Codable, Identifiable)
│       └── Macro (struct, Codable, Identifiable)
│
├── Services/
│   ├── MacroSession.swift          Main orchestrator - 193 lines
│   │   ├── Recording coordination
│   │   ├── Playback management
│   │   ├── Event editing
│   │   ├── Persistence (UserDefaults)
│   │   └── Import/Export
│   │
│   ├── EventRecorder.swift         Event capture - 195 lines
│   │   ├── CGEvent tap setup
│   │   ├── Event filtering
│   │   └── Accessibility checks
│   │
│   ├── EventPlayer.swift           Event playback - 109 lines
│   │   ├── Async playback loop
│   │   ├── Playback modes
│   │   └── Speed adjustment
│   │
│   └── HotkeyManager.swift         Global hotkeys - 184 lines
│       ├── Hotkey registration
│       ├── Event handling
│       └── UserDefaults sync
│
├── Views/ (8 SwiftUI files)
│   ├── ContentView.swift           Main container - 216 lines
│   │   ├── Layout: HSplitView
│   │   ├── Modal dialogs management
│   │   ├── Hotkey coordination
│   │   └── Import/Export workflows
│   │
│   ├── ControlsView.swift          User controls - 167 lines
│   │   ├── Recording controls
│   │   ├── Playback controls
│   │   ├── Speed slider
│   │   └── Mode picker
│   │
│   ├── MacroListView.swift         Sidebar macros - 146 lines
│   │   ├── Macro listing
│   │   ├── Context menu
│   │   ├── Load/Export/Delete actions
│   │   └── Selection highlighting
│   │
│   ├── EventListView.swift         Main event display - 381 lines
│   │   ├── TimelineView (visualization)
│   │   ├── EventRow (detailed view)
│   │   ├── Drag-drop support
│   │   ├── Event coloring
│   │   └── Edit/Delete actions
│   │
│   ├── StatusBarView.swift         Status indicator - 93 lines
│   │   ├── Recording/Playing/Ready indicators
│   │   ├── Event count
│   │   ├── Progress info
│   │   └── Hotkey hints
│   │
│   ├── EventEditorView.swift       Event modal - 163 lines
│   │   ├── Delay editor
│   │   ├── Position editor
│   │   ├── Key code display
│   │   └── Form validation
│   │
│   ├── PreferencesView.swift       Settings tabs - 303 lines
│   │   ├── GeneralPreferencesView
│   │   ├── RecordingPreferencesView
│   │   ├── HotkeyPreferencesView
│   │   └── AboutView
│   │
│   └── KeybindCaptureView.swift    Hotkey capture - 158 lines
│       ├── HotkeyConfig (struct)
│       ├── KeybindCaptureView (SwiftUI)
│       ├── KeybindCaptureHelper (NSViewRepresentable)
│       └── KeyCaptureNSView (NSView)
│
├── Controllers/                    (empty directory)
├── Utilities/                      (empty directory)
└── Resources/                      (empty directory)
```

## Import Dependencies by File

### MacroRecorderApp.swift
```swift
import SwiftUI
import ApplicationServices  // AXIsProcessTrustedWithOptions
```

### Models/MacroEvent.swift
```swift
import Foundation
import CoreGraphics           // CGEvent, CGPoint, CGEventTap
```

### Services/MacroSession.swift
```swift
import Foundation
import Combine               // @Published, ObservableObject
```

### Services/EventRecorder.swift
```swift
import Foundation
import CoreGraphics          // CGEvent, CGEventTap, CGEventMask
import Combine              // @Published, ObservableObject
import ApplicationServices  // AXIsProcessTrustedWithOptions
import Carbon              // Carbon key codes
```

### Services/EventPlayer.swift
```swift
import Foundation
import CoreGraphics         // CGEvent
import Combine             // @Published, ObservableObject
```

### Services/HotkeyManager.swift
```swift
import Foundation
import Carbon              // EventHotKeyRef, hotkey registration APIs
import AppKit              // NSView
```

### Views/ContentView.swift
```swift
import SwiftUI
```
Uses: MacroSession, HotkeyManager, all other views

### Views/ControlsView.swift
```swift
import SwiftUI
```
Uses: MacroSession

### Views/MacroListView.swift
```swift
import SwiftUI
```

### Views/EventListView.swift
```swift
import SwiftUI
import UniformTypeIdentifiers  // .json type
```
Uses: TimelineView, EventRow, EventDropDelegate

### Views/StatusBarView.swift
```swift
import SwiftUI
```
Uses: MacroSession

### Views/EventEditorView.swift
```swift
import SwiftUI
```
Uses: MacroEvent

### Views/PreferencesView.swift
```swift
import SwiftUI
import Carbon              // Key code constants (cmdKey, shiftKey, etc)
```
Uses: HotkeyConfig, KeybindCaptureView

### Views/KeybindCaptureView.swift
```swift
import SwiftUI
import Carbon              // Key code constants, key capture APIs
```

## Data Flow Diagram

```
MacroRecorderApp
    │
    ├─ AppDelegate
    │   └─ Accessibility permission check
    │
    └─ ContentView (Main Window)
        │
        ├─ StateObject: MacroSession
        │   ├─ EventRecorder
        │   │   └─ CGEventTap (system events)
        │   ├─ EventPlayer
        │   │   └─ CGEvent.post() (system output)
        │   ├─ savedMacros: [Macro] (UserDefaults)
        │   └─ currentMacro: Macro?
        │
        ├─ StateObject: HotkeyManager
        │   ├─ Global hotkey registration
        │   └─ onRecordingTriggered, onPlaybackTriggered
        │
        ├─ MacroListView
        │   ├─ Observes: session.savedMacros
        │   └─ Actions: load, export, delete
        │
        ├─ ControlsView
        │   ├─ Observes: session (isRecording, isPlaying)
        │   ├─ Bindings: playbackSpeed, playbackMode, loopCount
        │   └─ Actions: record, play, clear, save, settings
        │
        ├─ EventListView
        │   ├─ Observes: session.currentMacro.events
        │   ├─ Observes: session.player (currentEventIndex, isPlaying)
        │   ├─ TimelineView (visual representation)
        │   ├─ List (detailed event rows)
        │   └─ Actions: edit, delete, drag-drop
        │
        └─ StatusBarView
            ├─ Observes: session (recording/playing state)
            ├─ Observes: session.player (progress)
            └─ Display: status, event count, hotkey hints

Sheet Dialogs:
├─ SaveMacroDialog
│   └─ Callback: session.saveCurrentMacro(name:)
├─ EventEditorView
│   └─ Callback: session.updateEvent(_:)
└─ EventCreatorView
    └─ Callback: session.insertEvent(_:at:)

Settings Window:
└─ PreferencesView
    ├─ AppStorage for settings persistence
    ├─ UserDefaults for hotkey persistence
    └─ Notification: .hotkeysChanged
```

## Class Hierarchy & Protocols

```
ObservableObject (Combine)
├─ MacroSession
├─ EventRecorder
├─ EventPlayer
└─ HotkeyManager

Codable (Serialization)
├─ MacroEvent
├─ Macro
└─ HotkeyConfig

Identifiable (List Support)
├─ MacroEvent
└─ Macro

View (SwiftUI)
├─ MacroRecorderApp
├─ ContentView
├─ MacroListView / MacroListItem
├─ ControlsView
├─ EventListView / EventRow / TimelineView / EventDropDelegate
├─ StatusBarView
├─ EventEditorView
├─ EventCreatorView
├─ PreferencesView / GeneralPreferencesView / RecordingPreferencesView / 
│  HotkeyPreferencesView / AboutView / FeatureRow
├─ KeybindCaptureView
└─ SaveMacroDialog / EmptyStateView

NSViewRepresentable (SwiftUI-AppKit Bridge)
└─ KeybindCaptureHelper
    └─ makeNSView: KeyCaptureNSView

NSView (AppKit)
├─ AppDelegate (NSApplicationDelegate)
└─ KeyCaptureNSView

DropDelegate (Drag-Drop)
└─ EventDropDelegate
```

## State Management Pattern

```
Published State (Observable):

MacroSession:
  @Published var currentMacro: Macro?
  @Published var savedMacros: [Macro]
  @Published var isRecording: Bool
  @Published var isPlaying: Bool
  @Published var recorder.isRecording → observes → isRecording
  @Published var player.isPlaying → observes → isPlaying

EventRecorder:
  @Published var isRecording: Bool
  @Published var recordedEvents: [MacroEvent]

EventPlayer:
  @Published var isPlaying: Bool
  @Published var currentEventIndex: Int
  @Published var playbackProgress: Double
  @Published var currentLoop: Int

HotkeyManager:
  @Published var recordingHotkey: (keyCode, modifiers)
  @Published var playbackHotkey: (keyCode, modifiers)

─────────────────────────────────────────────────────

Local State (View):

ContentView:
  @State var playbackSpeed: Double
  @State var playbackMode: PlaybackMode
  @State var loopCount: Int
  @State var selectedMacro: Macro?
  @State var showingSaveDialog: Bool
  @State var macroName: String
  @State var showingImportExport: Bool

EventListView:
  @State var selectedEvent: MacroEvent?
  @State var showingEventEditor: Bool
  @State var showingEventCreator: Bool
  @State var draggedEventIndex: Int?

─────────────────────────────────────────────────────

Persistent State (UserDefaults/AppStorage):

@AppStorage:
  defaultPlaybackSpeed: Double
  defaultPlaybackMode: String
  showNotifications: Bool
  recordMouseMoves: Bool
  mouseMoveThreshold: Double

UserDefaults.standard:
  "SavedMacros" → [Macro] (JSON)
  "recordingHotkeyData" → HotkeyConfig (JSON)
  "playbackHotkeyData" → HotkeyConfig (JSON)
```

## Event Flow Examples

### Recording Event Flow

```
1. User clicks "Start Recording"
   ↓
2. ControlsView → session.startRecording()
   ↓
3. MacroSession → recorder.startRecording()
   ↓
4. EventRecorder.startRecording()
   ├─ Create CGEvent tap with eventMask
   ├─ Create run loop source
   ├─ Add to run loop
   ├─ Enable tap
   └─ @Published isRecording = true
   ↓
5. System events occur (mouse click, key press, etc)
   ↓
6. CGEvent tap callback invoked
   ├─ handleEvent(event:type:)
   ├─ Filter out hotkey events
   ├─ Throttle mouse moves
   ├─ Convert CGEvent to MacroEvent
   └─ Append to @Published recordedEvents
   ↓
7. Observers notified (Views update)
   ├─ ControlsView updates button state
   ├─ StatusBarView shows "Recording..."
   └─ EventListView refreshes (if populated)
   ↓
8. User clicks "Stop Recording"
   ↓
9. ControlsView → session.stopRecording()
   ↓
10. MacroSession.stopRecording()
    ├─ recorder.stopRecording()
    ├─ Create new Macro from recorded events
    ├─ Call macro.updateDelays()
    ├─ @Published currentMacro = macro
    └─ @Published isRecording = false
    ↓
11. Views update
    ├─ EventListView shows all events
    ├─ StatusBarView shows "Ready"
    └─ ControlsView buttons re-enabled
```

### Playback Event Flow

```
1. User sets speed, mode, and clicks "Play Macro"
   ↓
2. ControlsView → session.play(macro:mode:speed:)
   ↓
3. MacroSession.play()
   ├─ Validate macro has events
   └─ player.play(events:mode:speed:)
   ↓
4. EventPlayer.play()
   ├─ Store events, mode, speed
   ├─ @Published isPlaying = true
   ├─ currentEventIndex = 0
   ├─ currentLoop = 0
   ├─ Create async Task
   └─ Call performPlayback()
   ↓
5. performPlayback() async
   ├─ Switch on playbackMode
   └─ Call playOnce()
   ↓
6. playOnce() async
   ├─ For each event in events:
   │  ├─ Update @Published currentEventIndex
   │  ├─ Update @Published playbackProgress
   │  ├─ Sleep for delay / playbackSpeed
   │  ├─ Convert MacroEvent to CGEvent
   │  └─ cgEvent.post(tap: .cghidEventTap)
   ├─ If looping: increment @Published currentLoop
   └─ After all: @Published playbackProgress = 1.0
   ↓
7. Views observe and update
   ├─ EventListView shows current event (green highlight)
   ├─ TimelineView shows playhead position
   ├─ StatusBarView shows "Playing..." + loop counter + progress
   └─ ControlsView buttons update state
   ↓
8. User clicks "Stop Playback"
   ↓
9. ControlsView → session.stopPlayback()
   ↓
10. MacroSession.stopPlayback()
    └─ player.stop()
    ↓
11. EventPlayer.stop()
    ├─ playbackTask?.cancel()
    ├─ @Published isPlaying = false
    ├─ currentEventIndex = 0
    ├─ playbackProgress = 0.0
    └─ currentLoop = 0
    ↓
12. Views update
    ├─ EventListView clears highlight
    ├─ StatusBarView shows "Ready"
    └─ ControlsView buttons re-enabled
```

### Event Editing Flow

```
1. User clicks event in EventListView
   ↓
2. EventListView.onTapGesture
   ├─ @State selectedEvent = event
   └─ Highlight row
   ↓
3. User clicks Edit button (on hover)
   ↓
4. EventListView
   ├─ @State showingEventEditor = true
   └─ Present EventEditorView sheet
   ↓
5. EventEditorView onAppear
   ├─ Initialize @State values from event
   └─ Display form with delay, position, etc
   ↓
6. User modifies values
   ├─ Slider adjusts delay
   ├─ TextFields update position/keyCode
   └─ Live preview via slider
   ↓
7. User clicks "Save"
   ↓
8. EventEditorView.saveChanges()
   ├─ Validate inputs
   ├─ Create updated MacroEvent
   └─ Call onSave(updatedEvent)
   ↓
9. EventListView → session.updateEvent(updatedEvent)
   ↓
10. MacroSession.updateEvent(_:)
    ├─ Find event index by UUID
    ├─ Replace event in currentMacro.events
    ├─ @Published currentMacro = macro (triggers update)
    └─ Sheet dismissed
    ↓
11. EventListView observes change
    ├─ List rebuilds
    └─ Updated event displays new values
```

## Summary Statistics

```
Total Lines of Code (Logic):
├─ Views:             ~1,627 lines (8 files)
├─ Models:             ~191 lines (1 file)
├─ Services:          ~681 lines (4 files)
└─ Entry Point:        ~77 lines (1 file)
────────────────────────────
Total:              ~2,576 lines

File Count:
├─ Swift files:     13
├─ Configuration:    2 (Package.swift, Info.plist)
└─ Total project:   15

Key Metrics:
├─ Published properties: 12
├─ View components: 17
├─ Event types: 9
├─ Playback modes: 3
├─ Service classes: 4
└─ UI Modals: 3
```

