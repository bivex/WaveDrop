# WaveDrop

Native macOS application for converting WAV audio files to MP3 format with an elegant drag-and-drop interface.

![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-blue.svg)
![macOS](https://img.shields.io/badge/macOS-14.0+-999.svg)

## Features

- **Drag & Drop** — Simply drop WAV files onto the app window
- **Batch Conversion** — Convert multiple files simultaneously (up to 3 in parallel)
- **Quality Selection** — Choose from 128/192/256/320 kbps bitrates
- **Live Progress** — Real-time conversion progress with per-file status
- **Native macOS UI** — Built with SwiftUI, supports Dark/Light mode
- **Keyboard Shortcuts** — Cmd+O (open), Cmd+K (clear), Cmd+Enter (convert)

## Tech Stack

- **Language:** Swift 6+
- **UI:** SwiftUI
- **Audio:** AVFoundation
- **Encoding:** FFmpeg (embedded)
- **Concurrency:** Combine + Swift Concurrency (async/await)

## Project Structure

```
WaveDrop/
├── App/
│   └── WaveDropApp.swift          # App entry point, menu commands
├── Models/
│   └── AudioFile.swift            # Audio file model with metadata
├── ViewModels/
│   └── ConverterViewModel.swift   # Core business logic, conversion orchestration
├── Views/
│   ├── ContentView.swift          # Main app container
│   ├── DropZoneView.swift         # Drag-and-drop target
│   ├── FileListView.swift         # File queue table
│   ├── FileRowView.swift          # Individual file row with status
│   ├── SettingsView.swift         # Bitrate and output folder settings
│   ├── ConversionProgressView.swift  # Progress indicator and result view
│   ├── ToastView.swift            # Toast notification
│   └── FolderPicker.swift         # Output folder picker sheet
├── Services/
│   ├── FFmpegService.swift        # FFmpeg process management & progress
│   ├── FileService.swift          # File open dialogs, metadata read, Finder reveal
│   └── AudioMetadataService.swift # AVFoundation metadata extraction
├── Utilities/
│   ├── Constants.swift            # App-wide constants
│   └── Extensions.swift           # Notification names, URLTransferable
├── Resources/
│   ├── Info.plist                 # App metadata and permissions
│   └── WaveDrop.entitlements      # Sandbox entitlements
└── project.yml                    # XcodeGen project specification
```

## Screenshot

![WaveDrop UI](docs/screenshot.png)

## Build Instructions

### Prerequisites

- macOS 14.0 (Sonoma) or later
- Xcode 15.0 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (optional, for project generation)

### Option 1: Using XcodeGen (Recommended)

1. Install XcodeGen:
   ```bash
   brew install xcodegen
   ```

2. Generate the Xcode project:
   ```bash
   cd WaveDrop
   xcodegen generate
   ```

3. Open `WaveDrop.xcodeproj` in Xcode:
   ```bash
   open WaveDrop.xcodeproj
   ```

4. Build and run (⌘R)

### Option 2: Manual Setup

1. Open Xcode → Create New Project → macOS → App
2. Set product name to `WaveDrop`, interface to SwiftUI, language to Swift
3. Set deployment target to macOS 14.0
4. Delete auto-generated source files
5. Add the source files from the `WaveDrop/` folders with the matching groups
6. Configure `Info.plist` from `Resources/Info.plist`
7. Embed the `ffmpeg` binary in `Resources/ffmpeg` (see below)
8. Build and run

### FFmpeg Binary Setup

The app expects an FFmpeg binary at:
```
WaveDrop/Resources/ffmpeg
```

To embed FFmpeg:

1. Download a static build for macOS:
   ```bash
   curl -L "https://evermeet.cx/ffmpeg/getrelease/zip" -o /tmp/ffmpeg.zip
   ```

2. Extract and place in Resources:
   ```bash
   unzip /tmp/ffmpeg.zip -d WaveDrop/Resources/
   mv WaveDrop/Resources/ffmpeg WaveDrop/Resources/ffmpeg
   ```

3. Ensure the binary is executable:
   ```bash
   chmod +x WaveDrop/Resources/ffmpeg
   ```

4. In Xcode, add `WaveDrop/Resources/ffmpeg` to "Copy Bundle Resources" build phase

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd + O` | Open WAV files |
| `Cmd + K` | Clear file queue |
| `Cmd + Enter` | Start conversion |

## Architecture

The app follows **MVVM** architecture:

- **Models** — `AudioFile` represents a queued audio file with status, progress, and metadata
- **ViewModels** — `ConverterViewModel` orchestrates the entire conversion pipeline:
  1. File validation (WAV extension check)
  2. Metadata reading (AVFoundation duration lookup)
  3. FFmpeg process spawning (up to 3 concurrent)
  4. Progress tracking & status updates
- **Views** — Declarative SwiftUI views with `@EnvironmentObject` for state
- **Services** — Singleton services for FFmpeg execution, file dialogs, and metadata

## Error Handling

| Error | UI |
|-------|----|
| Invalid file format | Toast notification |
| Corrupted WAV | File row red badge + message |
| FFmpeg not found | Alert on conversion start |
| Permission denied | Toast notification |
| Disk full | File row error status |

## Future Enhancements (v2)

- [ ] FLAC → MP3
- [ ] AIFF → MP3
- [ ] AAC export
- [ ] Audio normalization
- [ ] Silence trimming
- [ ] Metadata editor (ID3 tags)
- [ ] Drag result out of app

## License

MIT
