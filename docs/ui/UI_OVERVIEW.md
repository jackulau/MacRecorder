# MacroRecorder - Comprehensive UI Overview

## Executive Summary
MacroRecorder is a native macOS application built with **SwiftUI** that enables users to record and playback mouse and keyboard events. The application provides a clean, intuitive interface with advanced editing capabilities, global hotkeys, and multiple playback modes.

---

## 1. Technology Stack

### Core Framework
- **Primary UI Framework**: SwiftUI (100% SwiftUI-based)
- **Platform**: macOS 13.0+ (minimum system version)
- **Language**: Swift
- **Build System**: Swift Package Manager (SPM)
- **Architecture**: Event-driven with reactive patterns

### Key Technologies
- **AppKit**: NSApplication, NSAlert, NSEvent, NSWorkspace (system integration)
- **Core Graphics (Quartz)**: CGEvent, CGEventTap (event recording/playback)
- **Carbon**: Event hotkey registration and management
- **Combine**: Reactive state management with @Published properties
- **Foundation**: UserDefaults for persistence, Codable for serialization

### Additional Frameworks
- **ApplicationServices**: Accessibility permissions and AXIsProcessTrustedWithOptions
- **UniformTypeIdentifiers**: File type handling (.json for import/export)

---

## 2. Application Entry Point & Structure

### Main App File
**Location**: `/Users/jacklau/MacroRecorder/MacroRecorder/MacroRecorderApp.swift`

```swift
@main
struct MacroRecorderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    // Window group with ContentView
    // Custom menu commands for recording/playback/saving
    // Settings/Preferences window
}
```

### Key Startup Features
- **AppDelegate Integration**: Handles accessibility permission checks on launch
- **Menu Bar Commands**: Custom menu with keyboard shortcuts (⌘R, ⌘P, ⌘S)
- **Settings Window**: Access via ⌘, (Command+Comma)
- **App Termination**: Closes when last window is closed

---

## 3. Main Window & View Structure

### Window Hierarchy
```
MacroRecorderApp (Main App)
├── WindowGroup
│   └── ContentView (Main Window)
│       ├── HSplitView (Horizontal Split)
│       │   ├── LEFT: MacroListView (Sidebar)
│       │   └── RIGHT: VStack (Main Content)
│       │       ├── ControlsView (Recording & Playback Controls)
│       │       ├── EventListView (Events + Timeline)
│       │       │   ├── TimelineView (Visual Timeline)
│       │       │   └── List (Detailed Event List)
│       │       └── StatusBarView (Status & Info)
│       └── Sheets (Modals)
│           ├── SaveMacroDialog
│           ├── EventEditorView
│           └── EventCreatorView
└── Settings
    └── PreferencesView (Tab-based settings)
```

### Main Window Dimensions
- **Minimum Size**: 800x600 pixels
- **Split View**:
  - Left Sidebar: 200-300px width
  - Main Content: Flexible

---

## 4. View Components & Their Files

### 4.1 ContentView.swift
**Purpose**: Main container and orchestrator of the application

**Key Features**:
- Manages macro recording/playback workflow
- HSplitView layout (sidebar + main content)
- Dialog management (Save Macro, Import/Export)
- Hotkey setup and coordination
- State management for playback settings

**Key State Variables**:
- `currentMacro`: Currently loaded/edited macro
- `playbackSpeed`: Speed multiplier (0.1x - 5.0x)
- `playbackMode`: Once, Loop (count), or Infinite
- `loopCount`: Number of repetitions for loop mode

**Embedded Views**:
- MacroListView, ControlsView, EventListView, StatusBarView

---

### 4.2 ControlsView.swift
**Purpose**: Primary user interaction controls

**UI Sections**:

1. **Recording Controls** (Top Section)
   - Start/Stop Recording button (blue/red toggle)
   - Clear button (clears current macro)
   - Save Macro button
   - Settings button (gear icon)

2. **Playback Controls** (Bottom Section)
   - Play/Stop button (green)
   - Playback Speed slider (0.1x - 5.0x)
   - Playback Mode picker (Once, Loop, Infinite)
   - Loop count stepper (1-1000)

**Key Interactions**:
- Button states update based on recording/playback state
- Speed slider disabled during playback
- Mode selector updates reactive binding

---

### 4.3 MacroListView.swift
**Purpose**: Sidebar showing all saved macros

**UI Elements**:
- Header with "Saved Macros" title
- Menu button for import functionality
- List of MacroListItem components

**MacroListItem Features**:
- Macro name, event count, modification date
- Hover menu with Load/Export/Delete actions
- Context menu support
- Selection highlighting

**Interactions**:
- Select to view macro details
- Load macro (load saved macro into editor)
- Export macro (save as JSON)
- Delete macro (with confirmation)

---

### 4.4 EventListView.swift
**Purpose**: Display and manage recorded events

**Sub-Components**:

1. **TimelineView** (Top 100px)
   - Visual representation of all events
   - Color-coded event types
   - Playhead indicator during playback
   - Current event highlight (green)

2. **Event List Header**
   - Column labels: Event, Type, Position, Delay
   - Add Event button

3. **Detailed Event List**
   - EventRow components (one per event)
   - Drag-and-drop reordering
   - Current event highlighting
   - Hover menus (Edit/Delete)

4. **EventRow Features**:
   - Index number
   - Event icon (color-coded by type)
   - Type name (Left Click, Key Down, etc.)
   - Position or key information
   - Delay in seconds (3 decimal places)
   - Edit/Delete buttons on hover

**Event Color Scheme**:
- Left Click/Right Click: Blue
- Mouse Release: Cyan
- Mouse Move: Purple
- Mouse Drag: Orange
- Key Down: Green
- Key Up: Mint
- Scroll: Indigo

---

### 4.5 StatusBarView.swift
**Purpose**: Bottom status bar with real-time information

**Display Sections**:
1. **Status Indicator** (Left)
   - Recording indicator (red dot + "Recording...")
   - Playing indicator (green dot + "Playing...")
   - Ready indicator (gray dot + "Ready")

2. **Event Count** (Center)
   - Shows total events in current macro
   - Only visible when macro is loaded

3. **Playback Progress** (Center-Right)
   - Loop counter (e.g., "Loop 1/5" or "Loop 3" for infinite)
   - Progress bar
   - Only visible during playback

4. **Hotkey Hints** (Right)
   - ⌘⇧/ for Recording
   - ⌘⇧P for Playback

---

### 4.6 EventEditorView.swift
**Purpose**: Sheet modal for editing individual events

**Features**:
- Event type display (read-only)
- Delay slider and text input (0-10 seconds)
- Position editor (X, Y coordinates) for mouse events
- Key code display for keyboard events
- Comprehensive form layout

**Dialog**:
- Size: 450x400 pixels
- Cancel and Save buttons with keyboard shortcuts

---

### 4.7 EventCreatorView.swift
**Purpose**: Sheet modal for creating new events

**Features**:
- Event type picker (9 event types)
- Delay configuration (slider + text input)
- Conditional fields based on event type:
  - Mouse position (X, Y) with "Use Current Mouse Position" button
  - Key code for keyboard events
  - Scroll delta (X, Y) for scroll events
- Form validation

**Dialog**:
- Size: 500x500 pixels
- Cancel and Create buttons

---

### 4.8 PreferencesView.swift
**Purpose**: Tab-based settings/preferences window

**Tab 1: General**
- Default playback speed slider
- Default playback mode picker
- Show notifications toggle

**Tab 2: Recording**
- Record mouse movements toggle
- Mouse move threshold slider (0.01-1.0s)
- Description: "Minimum delay between mouse move events"

**Tab 3: Hotkeys**
- Recording hotkey capture
- Playback hotkey capture
- Reset to defaults button
- Instructions for hotkey configuration

**Tab 4: About**
- App icon (record circle)
- Version info (1.0.0)
- Description
- Feature list with icons
- Copyright info

**Dialog**:
- Size: 500x400 pixels
- Tab navigation

---

### 4.9 KeybindCaptureView.swift
**Purpose**: Custom control for capturing keyboard shortcuts

**Components**:
1. **HotkeyConfig** (Data Structure)
   - keyCode: UInt32
   - modifiers: UInt32 (cmdKey, shiftKey, optionKey, controlKey)
   - displayString property for UI

2. **KeybindCaptureView** (SwiftUI View)
   - Label for hotkey action
   - Button showing current hotkey
   - Capture mode button (state-dependent styling)
   - Cancel button during capture

3. **KeybindCaptureHelper** (NSViewRepresentable)
   - Bridges SwiftUI to NSView

4. **KeyCaptureNSView** (NSView)
   - Handles low-level key capture
   - Requires modifier keys (Cmd, Shift, Option, or Control)
   - onKeyCapture callback

**Key Mappings**:
- Comprehensive key code to symbol mapping
- Support for A-Z, 0-9, function keys, special keys
- Unicode symbols (⌘, ⇧, ⌥, ⌃, ↩, ⇥, ⌫, ⎋)

---

## 5. Model Data Structures

### MacroEvent.swift
**Enum**: `EventType` (9 types)
```
- mouseLeftDown, mouseLeftUp
- mouseRightDown, mouseRightUp
- mouseMove, mouseDrag
- keyDown, keyUp
- scroll
```

**Struct**: `MacroEvent` (Codable, Identifiable)
- `id`: UUID
- `type`: EventType
- `timestamp`: TimeInterval
- `position`: CGPoint? (mouse coordinates)
- `keyCode`: UInt16? (keyboard key code)
- `flags`: UInt64? (modifier flags)
- `scrollDeltaX`, `scrollDeltaY`: Double? (scroll amounts)
- `delay`: TimeInterval (time since previous event)

**Methods**:
- `from(cgEvent:)`: Convert CGEvent to MacroEvent
- `toCGEvent()`: Convert back to CGEvent for playback

**Struct**: `Macro` (Codable, Identifiable)
- `id`: UUID
- `name`: String
- `events`: [MacroEvent]
- `createdAt`: Date
- `modifiedAt`: Date
- `updateDelays()`: Recalculate timing

---

## 6. Service Layer

### MacroSession.swift
**Purpose**: Central orchestrator for recording, playback, and persistence

**Published Properties**:
- `currentMacro`: Macro?
- `savedMacros`: [Macro]
- `isRecording`: Bool
- `isPlaying`: Bool

**Key Methods**:
- `startRecording()`, `stopRecording()`, `clearCurrentMacro()`
- `play()`, `stopPlayback()`
- `saveCurrentMacro()`, `deleteMacro()`, `loadMacro()`
- Event editing: `updateEvent()`, `insertEvent()`, `removeEvent()`, `moveEvent()`
- Persistence: `saveMacros()`, `loadMacros()`
- Import/Export: `exportMacro()`, `importMacro()`

**Storage**: UserDefaults (key: "SavedMacros")

---

### EventRecorder.swift
**Purpose**: Captures mouse and keyboard events from system

**Published Properties**:
- `isRecording`: Bool
- `recordedEvents`: [MacroEvent]

**Key Features**:
- CGEvent tap creation and management
- Event filtering:
  - Excludes hotkey events
  - Throttles mouse moves (100ms minimum)
- Hotkey tracking for filtering
- Accessibility permission checking

**Event Mask**: Captures 10 event types (left/right mouse, move, drag, key, scroll)

---

### EventPlayer.swift
**Purpose**: Plays back recorded events to the system

**Published Properties**:
- `isPlaying`: Bool
- `currentEventIndex`: Int
- `playbackProgress`: Double (0.0 - 1.0)
- `currentLoop`: Int

**PlaybackMode** (Enum):
- `once`: Single playback
- `count(Int)`: Play N times
- `infinite`: Loop indefinitely

**Key Features**:
- Async/await based playback
- Speed adjustment (delay / playbackSpeed)
- Loop counter tracking
- Task cancellation support

---

### HotkeyManager.swift
**Purpose**: Manages global keyboard shortcuts

**Published Properties**:
- `recordingHotkey`: (keyCode: UInt32, modifiers: UInt32)
- `playbackHotkey`: (keyCode: UInt32, modifiers: UInt32)

**Key Methods**:
- `registerHotkeys()`: Install global hotkey handlers
- `unregisterHotkeys()`: Remove handlers
- `reloadHotkeys()`: Reload from UserDefaults

**Default Hotkeys**:
- Recording: Cmd+Shift+/ (keyCode: 0x2C)
- Playback: Cmd+Shift+P (keyCode: 0x23)

**Callbacks**:
- `onRecordingTriggered`
- `onPlaybackTriggered`

---

## 7. Key UI Features & Workflows

### 7.1 Recording Workflow
1. User clicks "Start Recording" or presses Cmd+Shift+/
2. EventRecorder installs CGEvent tap
3. System events captured in real-time
4. Hotkey events and rapid mouse moves filtered out
5. User clicks "Stop Recording"
6. Events automatically loaded into CurrentMacro
7. Delays calculated between events

### 7.2 Playback Workflow
1. User selects playback speed and mode
2. Clicks "Play Macro" or presses Cmd+Shift+P
3. EventPlayer begins async playback loop
4. Events played with adjusted delays
5. Timeline shows current event
6. Progress bar updates
7. Loop counter increments (if looping)
8. User can stop playback at any time

### 7.3 Event Editing Workflow
1. User clicks event in list or hovers to access Edit button
2. EventEditorView opens as sheet
3. User modifies delay, position, or other parameters
4. Click Save to update event
5. CurrentMacro is immediately updated

### 7.4 Save & Load Workflow
1. User records macro and clicks "Save Macro"
2. SaveMacroDialog prompts for macro name
3. Macro saved to UserDefaults
4. Macro appears in left sidebar list
5. User can load any saved macro
6. User can export as JSON file

### 7.5 Settings Workflow
1. User clicks Settings button (gear icon)
2. PreferencesView opens (500x400 window)
3. User adjusts settings across 4 tabs
4. Changes saved to UserDefaults in real-time
5. For hotkeys: NewHotkeyConfig values immediately saved

---

## 8. Configuration & Resources

### Info.plist
**Bundle Information**:
- Bundle Identifier: `com.macrorecorder.app`
- Version: 1.0
- Minimum System: macOS 13.0
- Executable: MacroRecorder

**Permissions**:
- AppleScriptEnabled: true
- NSAppleEventsUsageDescription: For playback control
- No specific Accessibility permission key (runtime prompt only)

### Package.swift
**Swift Version**: 5.9+
**Platform**: macOS 13.0+
**Target**: MacroRecorder (executable)
**Resources**: Resources folder processing

---

## 9. File Structure Overview

```
MacroRecorder/
├── Views/ (8 files)
│   ├── ContentView.swift (Main container)
│   ├── ControlsView.swift (Recording/Playback controls)
│   ├── MacroListView.swift (Saved macros sidebar)
│   ├── EventListView.swift (Event list + timeline)
│   ├── StatusBarView.swift (Status indicator)
│   ├── EventEditorView.swift (Event editing modal)
│   ├── KeybindCaptureView.swift (Hotkey capture)
│   └── PreferencesView.swift (Settings tabs)
│
├── Models/
│   └── MacroEvent.swift (EventType, MacroEvent, Macro)
│
├── Services/ (4 files)
│   ├── MacroSession.swift (Main orchestrator)
│   ├── EventRecorder.swift (Event capture)
│   ├── EventPlayer.swift (Event playback)
│   └── HotkeyManager.swift (Global hotkeys)
│
├── Controllers/ (empty)
├── Utilities/ (empty)
├── Resources/ (empty)
│
├── MacroRecorderApp.swift (Entry point)
└── Info.plist (Configuration)
```

---

## 10. User Interface Standards

### Color Scheme
- **Accent Color**: System accent color (typically blue)
- **Event Type Colors**: 
  - Blue: Mouse clicks
  - Cyan: Mouse releases
  - Purple: Mouse movement
  - Orange: Mouse drag/scroll
  - Green: Key down
  - Mint: Key up
  - Indigo: Scroll

### Button Styles
- **Primary Actions**: `.borderedProminent` (blue/green/red)
- **Secondary Actions**: `.borderless`
- **State Indicators**: Color change on state (red while recording)

### Typography
- **Titles**: `.title` font
- **Headlines**: `.headline`
- **Body Text**: `.body`
- **Secondary Info**: `.caption`, `.caption2` with secondary foreground color
- **Technical Info**: Monospaced font for coordinates, delays, key codes

### Layout Patterns
- **Padding**: Standard 8-20pt
- **Spacing**: 5-15pt between components
- **Corner Radius**: 4-6pt for buttons and inputs
- **Dividers**: Used to separate major sections

---

## 11. Accessibility & User Experience

### Keyboard Shortcuts
- ⌘R: Start/Stop Recording (also in Controls menu)
- ⌘P: Play/Stop Playback (also in Controls menu)
- ⌘S: Save Macro
- ⌘,: Open Settings
- Cmd+Shift+/: Global recording hotkey (customizable)
- Cmd+Shift+P: Global playback hotkey (customizable)

### Help Text
- Tooltips on buttons (`.help()` modifier)
- Status bar showing current mode and hotkeys
- Preferences tab with detailed instructions
- Empty state message when no macro loaded

### Error Handling
- Accessibility permission prompt on launch if missing
- JSON import/export error handling
- Event editing form validation
- Hotkey capture requires modifier keys

---

## 12. Data Persistence & Import/Export

### Local Storage
- **Format**: UserDefaults with JSON encoding
- **Key**: "SavedMacros" for macro list
- **Hotkey Keys**: "recordingHotkeyData", "playbackHotkeyData"
- **Other Settings**: AppStorage for preferences

### Import/Export
- **Format**: JSON files (UniformTypeIdentifiers.json)
- **Pretty printed** for readability
- **Sorted keys** for consistency
- **Date encoding**: ISO 8601 format

---

## 13. State Management & Reactivity

### Published Properties (Combine)
- All major state is @Published in service classes
- Views use @ObservedObject to observe services
- @State for local view state
- @Binding for parent-child communication
- @AppStorage for persistent user settings

### Notifications
- Custom notification names for menu commands
- .hotkeysChanged for preference updates
- Notification-driven hotkey setup

---

## 14. Performance Considerations

### Event Recording
- Mouse move throttling (100ms minimum between events)
- Configurable mouse move threshold in preferences (0.01-1.0s)
- Lightweight CGEvent tap implementation

### Event Playback
- Async/await for non-blocking playback
- Task cancellation for stop/pause
- Adjustable speed reduces delays (faster = shorter delays)

### UI Updates
- Only updates during active recording/playback
- Timeline rebuilds on event changes
- Scroll reader auto-scrolls to current event

---

## Summary

MacroRecorder is a well-architected SwiftUI application with:
- **Clean separation of concerns**: Views, Models, Services
- **Reactive architecture**: Combine-based state management
- **Rich UI components**: Multiple specialized views for different tasks
- **System integration**: CGEvent tapping, hotkey registration, accessibility
- **User-friendly design**: Intuitive controls, helpful feedback, customizable settings
- **Data persistence**: UserDefaults storage with JSON export/import
- **Comprehensive event editing**: Full event manipulation with drag-drop support

The application provides professional-grade macro recording and playback with an accessible, modern UI built entirely with SwiftUI.
