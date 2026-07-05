# Medical Request Voice App

A cross-platform Flutter application that enables healthcare staff to create medical supply request forms using voice or manual entry. Designed for offline operation with support for Arabic and English speech recognition.

## Features

- **Import Master Item List**: Load a Microsoft Word (.docx) file containing medical supply items into the local SQLite database
- **Voice & Text Search**: Find items using speech recognition (Arabic/English) or keyboard text input with fuzzy matching
- **Request Form Builder**: Add items to a request table with quantities (voice/keyboard) and notes (Arabic/English voice)
- **Edit, Reorder, Delete**: Full management of request items — edit names/quantities/notes, drag to reorder, or remove items
- **Export to Word**: Generate a formatted Word (.docx) document with bordered table, header info, and item details
- **Draft Saving**: Requests auto-save as drafts; resume editing at any time
- **Request History**: View all past requests with status indicators (Draft, Exported, Submitted)
- **Offline Operation**: All data stored locally in SQLite — no internet connection required
- **Arabic & English Speech**: Switch between Arabic and English voice input for search, quantities, and notes
- **Voice Quantity Entry**: Say numbers in Arabic (واحد, عشرون) or English (one, twenty) to set item quantities

## Architecture

The application follows **Clean Architecture** principles with the **Flutter BLoC** pattern for state management.

### Project Structure

```
lib/
├── core/
│   ├── constants/          # App-wide constants (DB name, table names)
│   ├── database/           # SQLite database helper and initialization
│   ├── services/           # Speech recognition service wrapper
│   ├── theme/              # Material 3 theme configuration
│   ├── utils/              # Fuzzy matcher, number parser, DOCX utilities
│   └── widgets/            # Shared UI components (voice button, empty state, request item card)
├── features/
│   ├── home/               # Dashboard with quick actions
│   ├── import/             # DOCX file import screen
│   ├── items/              # Item browsing and search
│   │   ├── data/           # Medical item repository
│   │   ├── domain/         # Medical item entity
│   │   └── presentation/   # Items BLoC and screen
│   ├── request/            # Request form editing
│   │   ├── data/           # Request repository
│   │   ├── domain/         # Medical request and request item entities
│   │   └── presentation/   # Request BLoC and screen
│   └── history/            # Request history
│       └── presentation/   # History BLoC and screen
└── main.dart               # App entry point with MultiBlocProvider
```

### Key Technical Details

- **State Management**: Flutter BLoC with separate blocs for items, request editing, and history
- **Database**: SQLite via sqflite with three tables: medical_items, requests, request_items
- **Speech Recognition**: speech_to_text package with SpeechListenOptions for locale switching
- **DOCX Processing**: Custom XML generation using archive and xml packages (OOXML format)
- **Fuzzy Matching**: Levenshtein distance algorithm combined with SQL LIKE queries for robust item search
- **Number Parsing**: Custom parsers for Arabic and English number words (zero through thousand)
- **File Export**: Generates properly structured .docx files with bordered tables and alternating row colors

## Setup and Installation

### Prerequisites

- Flutter SDK 3.24.5 or later (Dart 3.5.4+)
- Android Studio / VS Code with Flutter extensions
- For Android: Android SDK with minimum API 21
- For iOS: Xcode 15+, CocoaPods

### Install Dependencies

```bash
cd medical_request_app
flutter pub get
```

### Run the App

```bash
flutter run
```

### Build Release

```bash
flutter build apk --release    # Android
flutter build ios --release    # iOS
```

## Database Schema

### medical_items

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | Auto-increment ID |
| itemName | TEXT | Name of the medical item |
| category | TEXT | Item category (optional) |
| createdAt | TEXT | ISO timestamp |
| updatedAt | TEXT | ISO timestamp |

### requests

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | Auto-increment ID |
| title | TEXT | Request title |
| date | TEXT | Request date |
| department | TEXT | Department name |
| requester | TEXT | Requester name |
| signature | TEXT | Signature info |
| status | TEXT | draft / exported / submitted |
| createdAt | TEXT | ISO timestamp |

### request_items

| Column | Type | Description |
|--------|------|-------------|
| id | INTEGER PK | Auto-increment ID |
| requestId | INTEGER FK | References requests.id |
| itemId | INTEGER | References medical_items.id (nullable) |
| itemName | TEXT | Item name (snapshot) |
| quantity | INTEGER | Requested quantity |
| notes | TEXT | Additional notes |
| orderIndex | INTEGER | Display order |

## Usage Guide

### 1. Import Items

From the Dashboard, tap **Import Items** to load a Word document containing your medical supply list. The app parses the document and extracts item names. Choose between replacing all existing items or adding to the current list.

### 2. Browse and Search Items

Tap **Browse Items** to view all imported medical supplies. Use the search bar with text or voice input (tap the microphone icon) to find specific items. Fuzzy matching helps find items even with partial or misspelled names.

### 3. Create a Request

Tap **New Request** to start a new medical supply request. Fill in the header information (title, department, requester) and then search for items to add. Each item can have:

- **Quantity**: Set via +/- buttons, keyboard, or voice (say "five" or "خمسة")
- **Notes**: Add notes via keyboard or voice in Arabic or English

### 4. Edit and Reorder

Long-press and drag items to reorder them. Tap the edit icon to modify item names, or the delete icon to remove items from the request.

### 5. Export and Share

When the request is complete, tap the export button to generate a Word document. The exported file includes a formatted bordered table with all request details and can be shared directly from the app.

## Voice Input

The app supports voice input in multiple contexts:

| Context | Arabic Locale | English Locale |
|---------|--------------|----------------|
| Item Search | ar_SA | en_US |
| Quantity Entry | ar_SA | en_US |
| Notes | ar_SA | en_US |

### Supported Number Words

**Arabic**: صفر، واحد، اثنان، ثلاثة، أربعة، خمسة، ستة، سبعة، ثمانية، تسعة، عشرة، أحد عشر، اثنا عشر، عشرون، ثلاثون، أربعون، خمسون، ستون، سبعون، ثمانون، تسعون، مئة، مئتان، ثلاث مئة، ألف

**English**: zero through thousand, including compound numbers (twenty-one, one hundred, etc.)

## Theme and UX

- Material 3 design with medical-blue primary color (#1976D2)
- Large touch targets (56px minimum button height)
- Rounded corners (12px border radius)
- Clear, readable fonts (18px button text, 22px app bar titles)
- Animated microphone button with pulse effect during voice input
- High-contrast status chips for request states
- Arabic and English localization support

## Dependencies

| Package | Purpose |
|---------|---------|
| flutter_bloc | State management (BLoC pattern) |
| equatable | Value equality for entities/states |
| sqflite | Local SQLite database |
| path_provider | File system paths |
| speech_to_text | Speech recognition |
| file_picker | Document file selection |
| share_plus | Share exported files |
| archive | ZIP/DOCX archive handling |
| xml | XML generation for DOCX |
| intl | Date formatting |
| uuid | Unique ID generation |
| permission_handler | Runtime permissions |

## License

This project is proprietary software. All rights reserved.
