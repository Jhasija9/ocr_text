# 📱 OCR Text Scanner (iOS App)

An iOS app built with **SwiftUI** that leverages camera input and OCR (Optical Character Recognition) to scan documents, extract text, auto-fill form fields, and upload the data securely to an S3-compatible backend.

---

## 🚀 Features

- 📷 **Live Camera Scanning** using native iOS camera
- 🧠 **OCR Text Extraction** from document images
- 📝 **Form Auto-Fill** using scanned text
- ☁️ **S3 Upload** integration for storing extracted data
- 📂 **Form Sections & View Management** with SwiftUI
- 🔒 Secure architecture with support for app entitlements and data handling

---

## 🛠 Tech Stack

- **Swift / SwiftUI**
- **Vision Framework** for OCR (iOS)
- **AVFoundation** for camera handling
- **Amazon S3** for cloud upload (via `S3Manager.swift`)
- **Modular SwiftUI Views** for clean UI organization

---

## 📁 Folder Structure

```
OCR_Scanner/
├── CameraView.swift          # Live camera feed using AVCaptureSession
├── ContentView.swift         # App entry view
├── FormField.swift           # Custom text input logic
├── FormSection.swift         # Displays auto-filled fields
├── ImageScanType.swift       # Enum for scan contexts (ID, Form, etc.)
├── S3Manager.swift           # Handles upload to AWS S3
├── DatabaseManager.swift     # Local or remote DB sync logic
├── OCR_ScannerApp.swift      # Main App entry point
├── Assets.xcassets/          # Image & icon assets
└── OCR_Scanner.entitlements  # iOS entitlements for camera, etc.
```

---

## 🧪 How It Works

1. User scans a document using the camera
2. OCR detects and extracts text from the image
3. Text is parsed and auto-filled into appropriate form fields
4. Data is sent to S3 or stored locally for review

---

## 📸 Screenshots

> *(Add screenshots here once uploaded to GitHub)*

```md
<img src="https://your-screenshot-link" width="300" />
```

---

## 🧑‍💻 Getting Started

### Prerequisites

- macOS with Xcode 14+
- iPhone or iOS simulator (iOS 15+)
- AWS credentials (if using S3)

### Installation

```bash
1. Open OCR_Scanner.xcodeproj in Xcode
2. Connect your iOS device or use the simulator
3. Build & run the app
```

Optional: Configure AWS keys in `S3Manager.swift`

---

## 📜 Notes

- **Camera permissions** required
- **OCR** uses Apple’s built-in **Vision** framework
- Designed to handle multiple document formats

---

## 📄 License

MIT License. Feel free to fork and contribute!

---

## 🙌 Contributions

Pull requests are welcome. For major changes, open an issue first to discuss what you'd like to change.
