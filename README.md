# MacroRecorder v1.0.3 for macOS

A powerful, professional-grade macro recorder for macOS that allows you to record and playback mouse and keyboard events with precision, window-specific recording, and advanced automation features.

## Features

### ✨ New in v1.0.3

- **Window-Specific Recording**
  - Record events only within a specific window
  - Window selection with live preview thumbnails
  - Automatic window focus detection
  - Window-relative coordinate tracking

- **Ghost Actions**
  - Send events to background windows without focusing
  - Non-intrusive automation
  - Perfect for multi-window workflows

- **Advanced UI Features**
  - Multi-selection with Shift+Click and Cmd+Click
  - Status overlay showing recording/playback state
  - Window preview on hover in picker
  - Performance optimizations for 10,000+ events

- **Comprehensive Event Recording**
  - Mouse clicks (left and right)
  - Mouse movements and drags
  - Keyboard key presses
  - Scroll wheel events
  - Precise position tracking
  - Window focus events

- **Flexible Playback**
  - Adjustable playback speed (0.1x to 5x)
  - Multiple playback modes:
    - Play once
    - Loop a specific number of times
    - Infinite loop
  - Real-time playback progress visualization

- **Event Management**
  - Edit event delays
  - Modify event positions
  - Insert new events
  - Delete unwanted events
  - Visual timeline representation

- **User-Friendly Interface**
  - Clean, modern macOS-native UI
  - Event list with detailed information
  - Timeline visualization
  - Sidebar for saved macros

- **Global Hotkeys**
  - `⌘⇧/` - Start/Stop recording
  - `⌘⇧P` - Play/Stop playback
  - `⌘S` - Save current macro

- **Macro Management**
  - Save and load macros
  - Import/Export macros as JSON
  - Organize multiple macros
  - Persistent storage

## Requirements

- macOS 12.0 (Monterey) or later
- Xcode 14.0 or later (for building from source)
- Accessibility permissions (required for event recording and playback)

## Installation

### Building from Source

1. Clone or download this repository
2. Open Terminal and navigate to the project directory:
   ```bash
   cd /path/to/MacroRecorder
   ```

3. Open the project in Xcode:
   ```bash
   open MacroRecorder.xcodeproj
   ```

   Or if you prefer Swift Package Manager, you can build with:
   ```bash
   swift build
   ```

4. Build and run the application (⌘R in Xcode)

### First Launch

On first launch, MacroRecorder will request accessibility permissions:

1. A system dialog will appear asking for accessibility access
2. Click "Open System Preferences"
3. Enable MacroRecorder in: System Preferences → Security & Privacy → Privacy → Accessibility
4. Restart the application

## Usage

### Recording a Macro

1. Click "Start Recording" or press `⌘⇧/`
2. Perform the mouse and keyboard actions you want to record
3. Click "Stop Recording" or press `⌘⇧/` again
4. Review the recorded events in the event list
5. Click "Save Macro" or press `⌘S` to save

### Playing Back a Macro

1. Load a saved macro from the sidebar or ensure you have a recorded macro
2. Adjust playback settings:
   - Set playback speed (slider)
   - Choose playback mode (Once/Loop/Infinite)
   - Set loop count if using Loop mode
3. Click "Play Macro" or press `⌘⇧P`
4. Watch the timeline and status bar for playback progress

### Editing Events

1. Select an event from the event list
2. Click the pencil icon or right-click and select "Edit"
3. Modify:
   - Delay (time before this event)
   - Position (X, Y coordinates for mouse events)
4. Click "Save" to apply changes

### Managing Macros

- **Save**: Click "Save Macro" after recording
- **Load**: Click on a macro in the sidebar
- **Export**: Right-click a macro → Export (saves as JSON)
- **Import**: Click the ellipsis menu in sidebar → Import Macro
- **Delete**: Right-click a macro → Delete

## Project Structure

```
MacroRecorder/
├── MacroRecorder/
│   ├── Models/
│   │   └── MacroEvent.swift          # Event and Macro data models
│   ├── Services/
│   │   ├── EventRecorder.swift       # Records system events
│   │   ├── EventPlayer.swift         # Plays back recorded events
│   │   ├── MacroSession.swift        # Session management
│   │   └── HotkeyManager.swift       # Global hotkey handling
│   ├── Views/
│   │   ├── ContentView.swift         # Main application view
│   │   ├── ControlsView.swift        # Recording/playback controls
│   │   ├── EventListView.swift       # Event list and timeline
│   │   ├── EventEditorView.swift     # Event editing dialog
│   │   ├── MacroListView.swift       # Saved macros sidebar
│   │   ├── StatusBarView.swift       # Status bar
│   │   └── PreferencesView.swift     # Settings/preferences
│   ├── MacroRecorderApp.swift        # App entry point
│   └── Info.plist                    # App configuration
└── README.md
```

## Architecture

### Core Components

1. **EventRecorder**: Uses CGEvent tap to capture system-wide mouse and keyboard events
2. **EventPlayer**: Replays recorded events using CGEvent posting
3. **MacroSession**: Manages recording/playback state and macro persistence
4. **HotkeyManager**: Registers and handles global keyboard shortcuts
5. **MacroEvent**: Codable model for event serialization

### Event Flow

```
Recording:
System Event → CGEvent Tap → EventRecorder → MacroEvent → MacroSession

Playback:
MacroSession → MacroEvent → EventPlayer → CGEvent Post → System
```

## Technical Details

### Event Types Supported

- **Mouse Events**:
  - Left mouse down/up
  - Right mouse down/up
  - Mouse move
  - Mouse drag
  - Scroll wheel

- **Keyboard Events**:
  - Key down
  - Key up
  - Modifier keys (⌘, ⌥, ⌃, ⇧)

### Performance Optimizations

- Mouse move events are throttled to prevent excessive recording
- Events are processed asynchronously to prevent UI blocking
- Efficient event storage using Swift's Codable protocol
- Timeline visualization uses computed positions for smooth rendering

### Data Persistence

- Macros are stored in UserDefaults as JSON
- Export functionality saves macros as human-readable JSON files
- Import validates JSON structure before loading

## Preferences

Access preferences via MacroRecorder → Preferences or `⌘,`

### General
- Default playback speed
- Default playback mode
- Notification settings

### Recording
- Mouse movement recording toggle
- Mouse move threshold (reduces recording size)

### Hotkeys
- View current global hotkeys
- (Customization coming in future update)

## Troubleshooting

### Events Not Recording

- Ensure accessibility permissions are granted
- Check System Preferences → Security & Privacy → Privacy → Accessibility
- Restart the application after granting permissions

### Playback Not Working

- Verify accessibility permissions
- Check that the macro contains events
- Ensure no other application is blocking event posting

### Hotkeys Not Working

- Verify no other application is using the same hotkey combination
- Check if the application is in the foreground
- Restart the application

## Known Limitations

- Some protected applications (e.g., system dialogs) may not respond to playback
- Hotkey customization not yet available
- Maximum tested macro size: ~10,000 events

## Future Enhancements

- [ ] Customizable hotkeys
- [ ] Macro editing in timeline view
- [ ] Conditional playback (if/else logic)
- [ ] Variable delays and random intervals
- [ ] Screenshot-based event positioning
- [ ] Macro templates library
- [ ] Cloud sync for macros
- [ ] AppleScript integration

## Security & Privacy

MacroRecorder:
- Only records events while explicitly recording
- Does not transmit any data over the network
- Stores macros locally on your device
- Requires explicit accessibility permissions
- Is fully open-source for transparency

## License

This project is provided as-is for educational and personal use.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Support

For issues, questions, or feature requests, please open an issue on the GitHub repository.

---

**Note**: This application requires accessibility permissions to function. These permissions allow the app to monitor and control your mouse and keyboard. Only grant these permissions if you trust the application and understand the implications.
