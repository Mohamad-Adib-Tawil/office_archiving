# Office Archiving App

A powerful, professional-grade Flutter application designed to bring order and efficiency to document management. Office Archiving allows users to create a structured digital library for all their files, featuring robust search, an integrated PDF editor, and seamless external integration.

---

## Features

- **🏗️ Hierarchical Organization:** Create sections and categories to organize files logically.
- **📁 Multi-Format Support:** Store and view images, PDFs, Excel spreadsheets, Word documents, text files, and more.
- **🔍 Advanced Search:** Quickly find files or sections by name.
- **✏️ Integrated PDF Editor:** Annotate, highlight, draw, and sign PDFs without leaving the app.
- **📤 Open Externally:** Open files in their default external applications with a single tap.
- **🗂️ Full CRUD Operations:** Create, read, update, and delete sections or files with ease.
- **🎨 Modern UI:** Built with Flutter for a smooth, responsive cross-platform experience.

---

## Supported File Types

- **Images:** `.jpg`, `.jpeg`, `.png`, `.gif`, `.bmp`, `.webp`
- **Documents:** `.pdf`, `.doc`, `.docx`, `.txt`
- **Spreadsheets:** `.xls`, `.xlsx`, `.csv`
- **Presentations:** `.ppt`, `.pptx` (viewing with external app)
- **Other:** Any file type can be stored and opened externally.

---

## Technology Stack

- **Framework:** Flutter (Dart)
- **State Management:**  Bloc Cubit
- **PDF Editing:** `flutter_pdfview` 
- **File Picking:** `file_picker`
- **File Storage:** Local (`path_provider`) & Optional Cloud Firestore integration
- **Database:** Local: `sqflite` 

---

## Installation

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- An IDE (Android Studio, VS Code) with Flutter plugin installed
- For Android: Android SDK and an emulator/device
- For iOS: macOS with Xcode (for iOS builds)

### Steps
1. **Clone the repository**
   ```bash
   git clone https://github.com/Mohamad-Adib-Tawil/office_archiving.git
   cd office_archiving