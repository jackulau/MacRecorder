# MacroRecorder - UI Quick Reference Guide

## Main Window Layout

```
┌────────────────────────────────────────────────────────────────────────┐
│ MacroRecorder                                          ⚙️  _ □ ✕       │
├──────────────┬─────────────────────────────────────────────────────────┤
│              │                                                          │
│ Saved Macros │    Start Recording   Clear    Save Macro   Settings  ⚙️  │
│              │    [● Stop] (Red)                                        │
│ ────────────── ────────────────────────────────────────────────────────│
│              │                                                          │
│ Macro 1      │    Play Macro [●]  Speed: 1.0x ────────────────────  │
│ 5 events     │    [● Stop] (Green)  Mode: [Once | Loop | Infinite]    │
│ Oct 30       │                      Count: 5 events (if Loop)          │
│              │ ────────────────────────────────────────────────────────│
│ ────────────── │ ◯─────────────────────────────────────────────────────│
│ Macro 2      │ │ EVENT TIMELINE (Events visualized as dots)            │
│ 12 events    │ ◯─────────────────────────────────────────────────────────│
│ Oct 29       │ ────────────────────────────────────────────────────────│
│              │ Event          Type         Position      Delay   [+]    │
│ ────────────── ────────────────────────────────────────────────────────│
│              │ 1   🖱️  Left Click      (1024, 768)    0.050s   📝 🗑️  │
│ [⋯ Import]   │ 2   ⌨️  Key Down        Key: 0         0.125s   📝 🗑️  │
│              │ 3   🖱️  Mouse Move     (1050, 770)    0.075s   📝 🗑️  │
│              │ ... (scrollable)                                        │
│              │ ────────────────────────────────────────────────────────│
│              │ ● Recording...  | 3 events | Loop 1/5 ▰▰▰░░░░░░░░░░   │
│              │ ⌘⇧/: Record    ⌘⇧P: Play                              │
└──────────────┴─────────────────────────────────────────────────────────┘
```

## View Hierarchy

```
MacroRecorderApp
├─ @main entry point
├─ AppDelegate
│  └─ Accessibility permission check
├─ WindowGroup
│  └─ ContentView
│     ├─ @StateObject MacroSession (session)
│     ├─ @StateObject HotkeyManager (hotkeyManager)
│     ├─ HSplitView
│     │  ├─ MacroListView (LEFT SIDEBAR, 200-300px)
│     │  │  ├─ Header "Saved Macros" + Import menu
│     │  │  └─ List of MacroListItem
│     │  │     └─ Context menu: Load, Export, Delete
│     │  │
│     │  └─ VStack (MAIN CONTENT, flexible)
│     │     ├─ ControlsView
│     │     │  ├─ Recording controls row
│     │     │  │  ├─ Start/Stop Recording [●]
│     │     │  │  ├─ Clear button
│     │     │  │  ├─ Save Macro button
│     │     │  │  └─ Settings button ⚙️
│     │     │  ├─ Divider
│     │     │  └─ Playback controls row
│     │     │     ├─ Play/Stop [●]
│     │     │     ├─ Speed slider (0.1x - 5.0x)
│     │     │     ├─ Playback Mode picker
│     │     │     └─ Loop count stepper (conditional)
│     │     │
│     │     ├─ Divider
│     │     ├─ EventListView
│     │     │  ├─ TimelineView (100px height)
│     │     │  │  ├─ Background track
│     │     │  │  ├─ Event dots (color-coded)
│     │     │  │  └─ Playhead (if playing)
│     │     │  ├─ Divider
│     │     │  ├─ Column headers + Add Event button
│     │     │  ├─ Divider
│     │     │  └─ ScrollViewReader
│     │     │     └─ List (EventRow x N)
│     │     │        ├─ Drag & drop support
│     │     │        └─ Hover menu (Edit, Delete)
│     │     │
│     │     ├─ Divider
│     │     └─ StatusBarView (30px height)
│     │        ├─ Status indicator (● + text)
│     │        ├─ Event count
│     │        ├─ Playback progress (if playing)
│     │        └─ Hotkey hints
│     │
│     ├─ Sheet: SaveMacroDialog
│     │  ├─ TextField for macro name
│     │  ├─ Cancel button
│     │  └─ Save button (disabled if empty)
│     │
│     ├─ Sheet: EventEditorView
│     │  ├─ Event type (read-only)
│     │  ├─ Delay slider + input
│     │  ├─ Position editor (if mouse event)
│     │  ├─ Key code display (if keyboard event)
│     │  ├─ Cancel button
│     │  └─ Save button
│     │
│     └─ Sheet: EventCreatorView
│        ├─ Event type picker (9 options)
│        ├─ Delay configuration
│        ├─ Conditional fields (position, key, scroll)
│        ├─ Cancel button
│        └─ Create button
│
└─ Settings (⌘,)
   └─ PreferencesView (500x400)
      ├─ Tab 1: General
      │  ├─ Default playback speed slider
      │  ├─ Default playback mode picker
      │  └─ Show notifications toggle
      │
      ├─ Tab 2: Recording
      │  ├─ Record mouse movements toggle
      │  └─ Mouse move threshold slider
      │
      ├─ Tab 3: Hotkeys
      │  ├─ Recording hotkey capture (KeybindCaptureView)
      │  ├─ Playback hotkey capture (KeybindCaptureView)
      │  ├─ Reset to defaults button
      │  └─ Instructions text
      │
      └─ Tab 4: About
         ├─ App icon + title
         ├─ Version (1.0.0)
         ├─ Description
         └─ Feature list
```

## Event Type Color & Icon Mapping

```
Type                Icon    Color       Usage
────────────────────────────────────────────────────
Left Mouse Down     🖱️      Blue        Start left click
Left Mouse Up       🖱️      Cyan        End left click
Right Mouse Down    🖱️      Blue        Start right click
Right Mouse Up      🖱️      Cyan        End right click
Mouse Move          💫     Purple      Cursor position
Mouse Drag          ⬌       Orange      Click + drag motion
Key Down            ⌨️      Green       Key press
Key Up              ⌨️      Mint        Key release
Scroll              ⚙️      Indigo      Mouse wheel
```

## Playback Mode States

```
┌─────────────────────────────────────────────┐
│ Playback Modes                              │
├─────────────────────────────────────────────┤
│ Once                                        │
│  ├─ Play events once                        │
│  ├─ Stop when complete                      │
│  └─ No loop counter                         │
│                                             │
│ Loop (with count)                           │
│  ├─ Play N times sequentially               │
│  ├─ Stepper shows count (1-1000)           │
│  ├─ Status: "Loop 1/5" "Loop 2/5" etc     │
│  └─ Stop after N loops                      │
│                                             │
│ Infinite                                    │
│  ├─ Loop continuously                       │
│  ├─ Status: "Loop 1" "Loop 2" etc          │
│  └─ Manual stop required                    │
└─────────────────────────────────────────────┘
```

## Keyboard Shortcuts Reference

```
┌──────────────────────────────────────────────────────┐
│ Keyboard Shortcuts                                   │
├──────────────────────────────────────────────────────┤
│ Local (In Application Window)                       │
│ ⌘R or Button    Start/Stop Recording                │
│ ⌘P or Button    Play/Stop Playback                  │
│ ⌘S              Save Macro                          │
│ ⌘,              Open Settings                       │
│ Return          Accept dialog/Save                  │
│ Escape          Cancel dialog/Close                 │
│                                                      │
│ Global (System-wide, Customizable)                 │
│ Cmd+Shift+/     Start/Stop Recording               │
│ Cmd+Shift+P     Play/Stop Playback                 │
│                                                      │
│ Settings Hotkey Customization                       │
│ Click button    Capture mode                        │
│ Press combo     Register new hotkey                 │
│ *Must include modifier key (Cmd/Shift/Opt/Ctrl)    │
└──────────────────────────────────────────────────────┘
```

## File Import/Export Format

```
JSON Structure (SaveMacro)
{
  "id": "UUID-string",
  "name": "Macro Name",
  "events": [
    {
      "id": "UUID-string",
      "type": "mouseLeftDown",
      "timestamp": 1698691234.567,
      "position": {"x": 1024.5, "y": 768.3},
      "keyCode": null,
      "flags": null,
      "scrollDeltaX": null,
      "scrollDeltaY": null,
      "delay": 0.125
    },
    ...
  ],
  "createdAt": "2025-10-30T12:34:56Z",
  "modifiedAt": "2025-10-30T12:45:00Z"
}
```

## Status Indicators

```
Recording State
    ● Recording...    [Red dot]
       ↓ Recording events in real-time

Playing State
    ● Playing...      [Green dot]
    Loop 2/5          [Shows current/total loops]
    ▰▰▰░░░░░░░░░    [Progress bar]

Ready State
    ● Ready           [Gray dot]
    3 events          [Event count]
```

## Event Editing Workflow

```
User Action          Component           Result
─────────────────────────────────────────────────────
Click event row   →  EventListView    →  Highlight event
                                        Show Edit button

Hover/Click Edit  →  EventEditorView  →  Sheet modal opens
                                        Show event details

Change delay      →  Slider/Input     →  Live preview (slider)

Click Save        →  Form validation  →  Update MacroEvent
                                        Update CurrentMacro
                                        Close sheet

Event list        →  EventListView    →  Refresh display
redraws              refresh

Drag-drop event   →  EventListView    →  Move event
                     EventDropDelegate  Recalculate delays
```

## UI Component Sizing Guide

```
Component                    Size              Notes
──────────────────────────────────────────────────────
Main Window               Min 800x600        Resizable
Split View Sidebar        200-300px width    Collapsible
Controls Height           ~60-80px           Two sections
Timeline Height           100px              Fixed
Event List Item Height    ~30px              Row height
Status Bar Height         30px               Fixed
Settings Window           500x400px          Fixed size
Event Editor Modal        450x400px          Fixed size
Event Creator Modal       500x500px          Fixed size
Save Dialog Modal         400x150px          Fixed size
Button Width              ~180px (labeled)   Min width
Slider Width              150px              Standard
Stepper Width             150px              Standard
Text Input Width          100px              For numbers
```

## Data Storage Locations

```
UserDefaults Keys
├─ "SavedMacros"
│  └─ [Macro] array (JSON encoded)
│
├─ "recordingHotkeyData"
│  └─ HotkeyConfig (JSON encoded)
│
├─ "playbackHotkeyData"
│  └─ HotkeyConfig (JSON encoded)
│
├─ "defaultPlaybackSpeed"
│  └─ Double (0.1 - 5.0)
│
├─ "defaultPlaybackMode"
│  └─ String ("once", "loop", "infinite")
│
├─ "showNotifications"
│  └─ Bool
│
├─ "recordMouseMoves"
│  └─ Bool
│
└─ "mouseMoveThreshold"
   └─ Double (0.01 - 1.0)

Export Files
└─ ~/Desktop/*.json    (Exported macros)
   Format: Pretty-printed, sorted keys
```

## Testing UI Functionality Checklist

```
Recording
  ☐ Click "Start Recording" button
  ☐ Perform mouse/keyboard actions
  ☐ Actions appear in event list with timestamps
  ☐ Click "Stop Recording"
  ☐ Events list shows all captured events
  ☐ Delays calculated correctly

Playback
  ☐ Select playback speed (test 0.1x, 1.0x, 5.0x)
  ☐ Select playback mode (Once, Loop, Infinite)
  ☐ Click "Play Macro"
  ☐ Events replay to system
  ☐ Timeline shows current event
  ☐ Progress bar updates
  ☐ Can stop playback mid-way

Event Editing
  ☐ Click event to select
  ☐ Click Edit button or double-click
  ☐ Modal opens with event details
  ☐ Modify delay, position, etc.
  ☐ Click Save
  ☐ Changes reflected in list

Macro Management
  ☐ Click "Save Macro" button
  ☐ Enter macro name
  ☐ Macro appears in left sidebar
  ☐ Click macro in sidebar to load
  ☐ Right-click/hover for Export/Delete
  ☐ Export creates JSON file
  ☐ Delete removes from list

Settings
  ☐ Click Settings button (gear icon)
  ☐ Switch between tabs
  ☐ General: Change playback defaults
  ☐ Recording: Toggle mouse moves, adjust threshold
  ☐ Hotkeys: Capture new hotkeys
  ☐ About: Displays version and features
  ☐ Changes persist after app restart

Import/Export
  ☐ Export macro to JSON file
  ☐ Click Import button in sidebar
  ☐ Select JSON file
  ☐ Macro loads and is available
  ☐ Can save imported macro under new name

Global Hotkeys
  ☐ Test default Cmd+Shift+/ to record
  ☐ Test default Cmd+Shift+P to play
  ☐ Customize hotkeys in Settings
  ☐ New hotkeys work system-wide
  ☐ Hotkey events filtered from recording
```

## Performance & Stability Indicators

```
Good Performance Signs
✓ Recording starts immediately
✓ Events list updates in real-time
✓ Playback smooth and responsive
✓ UI remains responsive during playback
✓ Settings apply immediately
✓ Import/export completes quickly
✓ No memory leaks with many events

Areas to Monitor
⚠ High CPU usage during long recordings
⚠ Memory growth with 1000+ events
⚠ Timeline rendering with many events
⚠ Hotkey responsiveness
⚠ Event loop smoothness
```

