# MacroRecorder Analysis Index

## Complete Codebase Analysis for Window-Specific Recording Features

This directory contains three comprehensive analysis documents examining the MacroRecorder application structure and how to add window-specific recording capabilities.

---

## Documents Overview

### 1. START HERE: ANALYSIS_SUMMARY.md
**File Size**: 11 KB | **Lines**: 363
**Reading Time**: 10-15 minutes

High-level executive summary covering:
- What was analyzed
- Key findings about current architecture
- Core recording and playback mechanisms
- Important file locations with line numbers
- How to add window-specific recording (4-phase approach)
- Recommended next steps
- Quick reference to key code locations

**Best For**: Getting oriented, understanding the big picture, deciding next steps

**Key Sections**:
- Core Files You Need to Know
- How Event Recording Currently Works (4 steps)
- How to Add Window-Specific Recording (phases)
- Key Code Locations You'll Need

---

### 2. QUICK IMPLEMENTATION: WINDOW_TRACKING_QUICK_REFERENCE.md
**File Size**: 10 KB | **Lines**: 398
**Reading Time**: 15-20 minutes

Practical implementation guide focusing on:
- Top 5 files to modify (with exact priorities)
- 3 new files to create with class signatures
- Key macOS APIs to use (AX, AppKit, CoreGraphics)
- Implementation effort matrix (14 hours total)
- Backward compatibility strategy
- Testing checklist
- Performance optimization tips
- Common pitfalls to avoid
- File modification checklist

**Best For**: Planning implementation, starting to code, quick lookups

**Key Sections**:
- Most Important Files to Modify (EventRecorder, MacroEvent, etc.)
- New Files to Create (WindowHelper, WindowFilter, WindowTargeter)
- Key APIs to Use (with code examples)
- Implementation Priority & Effort
- Testing Checklist
- Example Implementation Flows

---

### 3. COMPREHENSIVE REFERENCE: WINDOW_RECORDING_ANALYSIS.md
**File Size**: 24 KB | **Lines**: 815
**Reading Time**: 45-60 minutes

Deep technical analysis covering:
- Complete project overview and file structure
- Detailed EventRecorder mechanism with code references
- MacroEvent data model details
- EventPlayer playback mechanism
- Session management and persistence
- Hotkey system architecture
- All UI components analyzed
- Current limitations for window-specific features
- Complete external APIs reference
- Data flow diagrams
- 3 different implementation approaches
- AX API integration points with examples
- Recommended phased approach
- File dependency map
- Critical code sections identified
- Testing strategy
- Performance considerations

**Best For**: Deep technical understanding, troubleshooting, API reference

**Key Sections**:
- Project Overview (architecture, dependencies)
- Event Recording Mechanism (lines 124-185 in EventRecorder.swift)
- Event Data Model (MacroEvent structure)
- Event Playback Mechanism
- Current Limitations (What's missing)
- External APIs & Frameworks Used
- Data Flow Diagram
- Key Architectural Patterns
- Entrypoints for Window-Specific Features (3 options)
- Accessibility Framework Integration Points
- Recommended Approach (phased)
- File Dependency Map
- Critical Code Sections for Modification
- Testing Strategy
- Performance Considerations

---

## Quick Navigation

### By Task

**I want to understand the app structure:**
1. Start with ANALYSIS_SUMMARY.md
2. Then read WINDOW_RECORDING_ANALYSIS.md sections 1-8

**I want to start implementing window recording:**
1. Read WINDOW_TRACKING_QUICK_REFERENCE.md
2. Use WINDOW_RECORDING_ANALYSIS.md as reference for APIs

**I want detailed technical information about a specific component:**
- Use WINDOW_RECORDING_ANALYSIS.md as comprehensive reference

**I want to know what to modify and in what order:**
1. Check WINDOW_TRACKING_QUICK_REFERENCE.md's "Most Important Files to Modify"
2. Use "Implementation Priority & Effort" table
3. Follow "Example Implementation Flow"

---

## Key Findings Summary

### Current Architecture
- **Language**: Swift 5.9+
- **Framework**: SwiftUI with Combine reactive patterns
- **Pattern**: MVVM with clear separation of concerns
- **Total Code**: ~3,100 lines across 15 Swift files

### Current Recording
- System-wide event capture via CGEvent tap
- Events stored with absolute screen coordinates only
- No window identification or filtering
- Playback posts events to system-wide HID tap

### Why It's Easy to Extend
- Clean MVVM architecture
- Codable protocol for serialization
- Optional fields for backward compatibility
- Existing accessibility permission infrastructure

### What Needs Adding
1. **Window tracking**: Capture focused window during recording
2. **Event metadata**: Store window info with each event
3. **Recording filter**: Option to record only specific app/window
4. **Playback awareness**: Focus window before playing events

---

## File Structure of MacroRecorder

```
/Users/jacklau/MacroRecorder/
├── MacroRecorder/
│   ├── Models/
│   │   └── MacroEvent.swift (190 lines) - Event model
│   ├── Services/
│   │   ├── EventRecorder.swift (195 lines) - Recording engine
│   │   ├── EventPlayer.swift (109 lines) - Playback engine
│   │   ├── MacroSession.swift (193 lines) - Coordinator
│   │   └── HotkeyManager.swift (228 lines) - Global hotkeys
│   ├── Views/
│   │   ├── ContentView.swift (247 lines) - Main window
│   │   ├── ControlsView.swift (166 lines) - Recording/playback controls
│   │   ├── EventListView.swift (433 lines) - Event display
│   │   ├── EventEditorView.swift (375 lines) - Event editing
│   │   ├── PreferencesView.swift (328 lines) - Settings
│   │   ├── MacroListView.swift (145 lines) - Saved macros
│   │   ├── StatusBarView.swift (93 lines) - Status bar
│   │   ├── StatusOverlayView.swift (163 lines) - Overlay window
│   │   └── KeybindCaptureView.swift (158 lines) - Hotkey capture
│   └── MacroRecorderApp.swift (85 lines) - App entry
├── ANALYSIS_SUMMARY.md (this analysis)
├── WINDOW_TRACKING_QUICK_REFERENCE.md (this analysis)
├── WINDOW_RECORDING_ANALYSIS.md (this analysis)
├── README.md (original docs)
├── CHANGELOG.md (version history)
└── QUICKSTART.md (user guide)
```

---

## Implementation Phases

| Phase | Effort | Priority | Files |
|-------|--------|----------|-------|
| 1: Model | 2 hrs | HIGH | MacroEvent.swift |
| 2: Recording | 4 hrs | HIGHEST | EventRecorder.swift + new helpers |
| 3: Playback | 2 hrs | MEDIUM | EventPlayer.swift |
| 4: UI | 3 hrs | MEDIUM | PreferencesView.swift, EventListView.swift |
| 5: Testing | 3 hrs | LOW | All |

**Total**: ~14 hours for complete implementation

---

## Key APIs You'll Need

### Event Capture
- `CGEvent.tapCreate()` - Create system event tap
- `CGEvent` properties - Access event data

### Window Detection
- `AXUIElementCreateSystemwide()` - Access system UI elements
- `AXUIElementCopyAttributeValue()` - Read element properties
- `NSRunningApplication` - Get application info

### Window Focus
- `NSRunningApplication.activate()` - Bring app to focus
- `NSWorkspace` - Application management

### Data Persistence
- `UserDefaults.standard` - Macro storage
- `JSONEncoder/Decoder` - Event serialization

---

## Common Questions Answered

**Q: How complex is adding window tracking?**
A: 14 hours of work spread across model, recording, playback, and UI. Moderate complexity.

**Q: Will old macros still work?**
A: Yes. WindowInfo field is optional. Old macros will have nil windowInfo and use absolute positioning.

**Q: Do I need additional permissions?**
A: No. The existing Accessibility permission covers AX API access.

**Q: Will performance be affected?**
A: Minimal if implemented correctly. Cache window info instead of querying on every event.

**Q: Can I do window-specific filtering?**
A: Yes. Phase 2 of implementation adds this via a WindowFilter class.

---

## References in Each Document

### ANALYSIS_SUMMARY.md
- Section: "Most Important Files & Locations" - Quick file reference table
- Section: "How Event Recording Currently Works" - 4-step explanation
- Section: "Key Code Locations You'll Need" - Exact line numbers

### WINDOW_TRACKING_QUICK_REFERENCE.md
- Section: "Most Important Files to Modify" - Detailed per-file guidance
- Section: "Key APIs to Use" - Code examples for all needed APIs
- Section: "Implementation Priority & Effort" - Timeline and effort estimates
- Section: "Common Pitfalls to Avoid" - What to watch out for

### WINDOW_RECORDING_ANALYSIS.md
- Section: "Entrypoints for Window-Specific Features" - 3 implementation options
- Section: "Accessibility Framework Integration Points" - Detailed AX API examples
- Section: "Critical Code Sections for Modification" - Exact line numbers
- Section: "Testing Strategy" - Unit, integration, and manual testing

---

## How to Use These Documents

**For Quick Overview (10 min)**:
- Read ANALYSIS_SUMMARY.md

**For Implementation Planning (30 min)**:
- Read ANALYSIS_SUMMARY.md
- Read WINDOW_TRACKING_QUICK_REFERENCE.md "Most Important Files to Modify"
- Read "Implementation Priority & Effort"

**For Implementation (Variable)**:
- Use WINDOW_TRACKING_QUICK_REFERENCE.md as your action guide
- Cross-reference with WINDOW_RECORDING_ANALYSIS.md for detailed API info
- Keep ANALYSIS_SUMMARY.md open for quick reference

**For Deep Understanding (1+ hour)**:
- Read WINDOW_RECORDING_ANALYSIS.md cover to cover
- Study the data flow diagrams
- Review the 3 implementation approaches

**For Troubleshooting**:
- Check "Common Pitfalls to Avoid" section
- Review API examples in WINDOW_RECORDING_ANALYSIS.md
- Check Testing Strategy section

---

## Summary

You have three documents covering the MacroRecorder codebase from multiple angles:

1. **ANALYSIS_SUMMARY.md** - Overview and orientation (start here)
2. **WINDOW_TRACKING_QUICK_REFERENCE.md** - Implementation guide (use while coding)
3. **WINDOW_RECORDING_ANALYSIS.md** - Technical reference (look up details)

Total analysis: ~2,000 lines covering:
- All 15 Swift files (~3,100 lines of app code)
- Event recording mechanism with exact line numbers
- Event model and data structures
- Playback mechanism
- All UI components
- Accessibility APIs
- 3 implementation approaches
- Testing strategy
- Performance analysis

Ready to start implementing? Begin with WINDOW_TRACKING_QUICK_REFERENCE.md!

---

**Generated**: November 14, 2025
**Analysis Coverage**: Complete MacroRecorder codebase (15 files, ~3,100 lines)
**Recommendation**: Implementation time ~14 hours for full window-specific recording feature
