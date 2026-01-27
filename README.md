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

   ```
## Screenshots

Professional preview of the app. Thumbnails are scaled for readability.

<div align="center">

<table>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.06.05 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.06.05 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.06.13 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.06.13 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.06.24 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.06.24 PM.png" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.06.54 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.06.54 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.07.27 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.07.27 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.08.22 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.08.22 PM.png" /></td>
  </tr>
</table>

</div>

> Full gallery: [docs/GALLERY.md](docs/GALLERY.md)


## Full Gallery

<div align="center">

<table>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.06.05 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.06.05 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.06.13 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.06.13 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.06.24 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.06.24 PM.png" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.06.54 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.06.54 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.07.27 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.07.27 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.08.22 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.08.22 PM.png" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.09.33 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.09.33 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.09.56 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.09.56 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.10.08 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.10.08 PM.png" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.14.20 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.14.20 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.14.40 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.14.40 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.14.45 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.14.45 PM.png" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.14.51 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.14.51 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.15.15 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.15.15 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.16.36 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.16.36 PM.png" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.16.47 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.16.47 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.16.55 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.16.55 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.17.14 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.17.14 PM.png" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.17.31 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.17.31 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.17.41 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.17.41 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.17.51 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.17.51 PM.png" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.18.18 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.18.18 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.18.59 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.18.59 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.21.12 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.21.12 PM.png" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.21.17 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.21.17 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.21.43 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.21.43 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.21.49 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.21.49 PM.png" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.22.59 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.22.59 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.23.11 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.23.11 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.23.21 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.23.21 PM.png" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.23.31 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.23.31 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.23.43 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.23.43 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.23.55 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.23.55 PM.png" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.24.14 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.24.14 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.24.19 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.24.19 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.24.24 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.24.24 PM.png" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.24.36 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.24.36 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.24.45 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.24.45 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 10.25.16 PM.png" width="260" alt="Screenshot 2026-01-27 at 10.25.16 PM.png" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 5.04.43 PM.png" width="260" alt="Screenshot 2026-01-27 at 5.04.43 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 5.06.00 PM.png" width="260" alt="Screenshot 2026-01-27 at 5.06.00 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 5.09.33 PM.png" width="260" alt="Screenshot 2026-01-27 at 5.09.33 PM.png" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 5.10.01 PM.png" width="260" alt="Screenshot 2026-01-27 at 5.10.01 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 5.10.32 PM.png" width="260" alt="Screenshot 2026-01-27 at 5.10.32 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 5.11.00 PM.png" width="260" alt="Screenshot 2026-01-27 at 5.11.00 PM.png" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 5.11.11 PM.png" width="260" alt="Screenshot 2026-01-27 at 5.11.11 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 5.11.49 PM.png" width="260" alt="Screenshot 2026-01-27 at 5.11.49 PM.png" /></td>
    <td><img src="screenshots/Screenshot 2026-01-27 at 5.13.30 PM.png" width="260" alt="Screenshot 2026-01-27 at 5.13.30 PM.png" /></td>
  </tr>
  <tr>
    <td><img src="screenshots/Screenshot 2026-01-27 at 9.54.31 PM.png" width="260" alt="Screenshot 2026-01-27 at 9.54.31 PM.png" /></td>
  </tr>
</table>

</div>
