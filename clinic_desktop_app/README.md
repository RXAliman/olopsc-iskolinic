# OLOPSC IskoLinic — Clinic Desktop App

A **Flutter Windows desktop application** for managing a school clinic's patient records, visitations, inventory, and analytics. Built with offline-first CRDT sync for multi-device support.

**Package name:** `olopsc_iskolinic`
**Target platform:** Windows (uses `sqflite_common_ffi`)
**Database:** Local SQLite via `sqflite_common_ffi`, stored at `%APPDATA%/com.olopsc/OLOPSC Iskolinic/clinic.db`
**Database version:** 5

---

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Project Structure](#project-structure)
- [Startup / Wiring (main.dart)](#startup--wiring-maindart)
- [Models](#models)
- [Database Schema & Migrations](#database-schema--migrations)
- [Providers (State Management)](#providers-state-management)
- [CRDT Sync System](#crdt-sync-system)
- [Screens](#screens)
- [Constants](#constants)
- [Formatters](#formatters)
- [Theme](#theme)
- [Key Dependencies](#key-dependencies)
- [Text Field Constraints](#text-field-constraints)
- [Conventions & Patterns](#conventions--patterns)

---

## Architecture Overview

```
┌──────────────────────────────────────────────────────────┐
│                    Flutter UI (Screens)                  │
│ Dashboard │ PatientList │ PatientDetail │ Analytics │ ...│
└────────────────────┬─────────────────────────────────────┘
                     │ reads/writes via
┌────────────────────▼─────────────────────────────────────┐
│               Providers (ChangeNotifier)                 │
│  PatientProvider │ InventoryProvider │ AnalyticsProvider │
│                  │ SyncProvider      │                   │
└────────┬─────────┴───────────────────┬───────────────────┘
         │                             │
┌────────▼──────────┐        ┌─────────▼───────────┐
│  DatabaseHelper   │        │  CRDT Sync Layer    │
│  (SQLite FFI)     │        │  SyncClient (WS)    │
│                   │◄──────►│  SyncIsolate        │
│  clinic.db        │        │  HLC, NodeId        │
└───────────────────┘        │  DataCompactor      │
                             └─────────────────────┘
                                       │
                              ┌────────▼────────┐
                              │  Relay Server   │
                              │  (WebSocket)    │
                              │  Render.com     │
                              └─────────────────┘
```

The app follows a **Provider + Repository** pattern:
- **Screens** consume providers via `context.read<T>()` / `context.watch<T>()`
- **Providers** (`ChangeNotifier`) hold all business logic, pagination state, and CRDT clock management
- **DatabaseHelper** is a singleton that handles all raw SQLite operations
- **CRDT layer** handles distributed sync via WebSocket relay

---

## Project Structure

```
lib/
├── main.dart                     # App entry, provider wiring
├── constants/
│   ├── symptoms.dart             # Predefined symptom lists (Traumatic, Medical, Behavioral)
│   └── supplies.dart             # Predefined clinic supplies list
├── crdt/
│   ├── hlc.dart                  # Hybrid Logical Clock implementation
│   ├── node_id.dart              # Persistent unique node identifier
│   ├── sync_client.dart          # WebSocket sync client with heartbeat & reconnect
│   ├── sync_isolate.dart         # Background CRDT merge processing
│   └── data_compactor.dart       # Tombstone cleanup (90-day threshold)
├── formatters/
│   └── uppercase_text.dart       # TextInputFormatter that uppercases input
├── models/
│   ├── patient.dart              # Patient data model with CRDT fields
│   ├── visitation.dart           # Visitation data model with CRDT fields
│   └── stock_batch.dart          # Inventory stock batch model
├── providers/
│   ├── patient_provider.dart     # Core provider: patients, visitations, pagination, CRDT writes
│   ├── inventory_provider.dart   # Inventory CRUD, FEFO deduction
│   ├── analytics_provider.dart   # Monthly symptom/supply analytics
│   └── sync_provider.dart        # Sync lifecycle management, connection state
├── screens/
│   ├── dashboard_screen.dart     # Main dashboard with summary cards, quick actions, today's visits
│   ├── patient_list_screen.dart  # Paginated patient table with search
│   ├── patient_detail_screen.dart# Full patient detail dialog with visitation history
│   ├── patient_form_screen.dart  # Add/edit patient dialog
│   ├── visitation_form_screen.dart # Add/edit visitation dialog
│   ├── inventory_screen.dart     # Stock management UI
│   └── analytics_screen.dart     # Monthly charts (symptoms, supplies, visits)
├── services/
│   ├── database_helper.dart      # SQLite singleton with all queries
│   └── mock_data_generator.dart  # Test data seeder (disabled in prod)
└── theme/
    └── app_theme.dart            # App-wide theme, colors, gradients, glass card style
```

---

## Startup / Wiring (main.dart)

The app initializes in this order:

1. `sqfliteFfiInit()` — Initialize FFI for Windows SQLite
2. `PatientProvider.initCrdt()` — Load/generate the node ID and HLC clock
3. `PatientProvider.loadPatients()` — Load the first page of patients
4. `SyncProvider.init(patientProvider, wsUrl: '...')` — Connect to relay server
5. `patientProvider.setOnLocalWrite(() => syncProvider.pushChanges())` — Wire auto-push
6. `InventoryProvider.loadInventory()` — Load stock batches
7. `patientProvider.setInventoryProvider(inventoryProvider)` — Wire auto-deduct

All providers are registered via `MultiProvider`:
- `PatientProvider` — `.value()` (pre-initialized)
- `AnalyticsProvider` — `.create()` (lazy)
- `SyncProvider` — `.value()` (pre-initialized)
- `InventoryProvider` — `.value()` (pre-initialized)

---

## Models

### Patient (`models/patient.dart`)

| Field            | Type       | Notes                                      |
|------------------|------------|--------------------------------------------|
| `id`             | `String`   | UUID v4, primary key                       |
| `firstName`      | `String`   | Required, max 30 chars                     |
| `lastName`       | `String`   | Required, max 30 chars                     |
| `middleName`     | `String`   | Optional, max 30 chars                     |
| `extension`      | `String`   | Name suffix (Jr., Sr., I-III, or custom max 5 chars) |
| `patientName`    | `String`   | Computed: `"lastName, firstName middleName ext"` |
| `idNumber`       | `String`   | Student/employee ID, max 16 chars          |
| `address`        | `String`   | Optional, max 150 chars                    |
| `guardianName`   | `String`   | Optional, max 65 chars                     |
| `guardianContact`| `String`   | Optional, max 20 chars                     |
| `createdAt`      | `DateTime` | ISO 8601 string in DB                      |
| `updatedAt`      | `DateTime` | ISO 8601 string in DB                      |
| `hlc`            | `String`   | Packed HLC for CRDT ordering               |
| `nodeId`         | `String`   | Origin node ID                             |
| `isDeleted`      | `bool`     | Soft-delete flag (stored as `INTEGER 0/1`) |

Methods: `toMap()`, `fromMap()`, `copyWith()`, `toSyncMap()`, `fromSyncMap()`

### Visitation (`models/visitation.dart`)

| Field          | Type           | Notes                                        |
|----------------|----------------|----------------------------------------------|
| `id`           | `String`       | UUID v4, primary key                         |
| `patientId`    | `String`       | FK → `patients.id`                           |
| `dateTime`     | `DateTime`     | Visit timestamp                              |
| `symptoms`     | `List<String>` | Stored as `\|`-delimited string in DB        |
| `suppliesUsed` | `List<String>` | Stored as `\|`-delimited string in DB        |
| `treatment`    | `String`       | Free-text "Other Intervention Details", max 150 chars |
| `remarks`      | `String`       | Free-text notes, max 150 chars               |
| `hlc`          | `String`       | Packed HLC                                   |
| `nodeId`       | `String`       | Origin node ID                               |
| `isDeleted`    | `bool`         | Soft-delete flag                             |

Methods: `toMap()`, `fromMap()`, `copyWith()`, `toSyncMap()`, `fromSyncMap()`

### StockBatch (`models/stock_batch.dart`)

| Field            | Type       | Notes                    |
|------------------|------------|--------------------------|
| `id`             | `String`   | UUID v4, primary key     |
| `itemName`       | `String`   | Supply name              |
| `quantity`        | `int`      | Current batch quantity   |
| `expirationDate` | `DateTime` | Expiry for FEFO ordering |
| `createdAt`      | `DateTime` | When batch was added     |

Methods: `toMap()`, `fromMap()`, `copyWith()`
**Note:** StockBatch is NOT synced via CRDT — it's local-only.

---

## Database Schema & Migrations

**File:** `services/database_helper.dart`
**Current version:** 5

### Tables

#### `patients`
```sql
CREATE TABLE patients (
  id TEXT PRIMARY KEY,
  firstName TEXT NOT NULL,
  lastName TEXT NOT NULL,
  middleName TEXT NOT NULL DEFAULT '',
  extension TEXT NOT NULL DEFAULT '',
  patientName TEXT NOT NULL,
  idNumber TEXT NOT NULL,
  address TEXT,
  guardianName TEXT,
  guardianContact TEXT,
  createdAt TEXT NOT NULL,
  updatedAt TEXT NOT NULL,
  hlc TEXT NOT NULL DEFAULT '',
  nodeId TEXT NOT NULL DEFAULT '',
  isDeleted INTEGER NOT NULL DEFAULT 0
)
-- Index: idx_patients_hlc ON patients (hlc)
```

#### `visitations`
```sql
CREATE TABLE visitations (
  id TEXT PRIMARY KEY,
  patientId TEXT NOT NULL,
  dateTime TEXT NOT NULL,
  symptoms TEXT,
  suppliesUsed TEXT,
  treatment TEXT,
  remarks TEXT,
  hlc TEXT NOT NULL DEFAULT '',
  nodeId TEXT NOT NULL DEFAULT '',
  isDeleted INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (patientId) REFERENCES patients (id)
)
-- Index: idx_visitations_hlc ON visitations (hlc)
```

#### `stock_batches`
```sql
CREATE TABLE stock_batches (
  id TEXT PRIMARY KEY,
  itemName TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 0,
  expirationDate TEXT NOT NULL,
  createdAt TEXT NOT NULL
)
-- Index: idx_stock_item ON stock_batches (itemName, expirationDate)
```

#### `meta`
```sql
CREATE TABLE meta (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)
```
Used for: `nodeId` (persistent node identity), `lastSyncHlc` (sync watermark).

### Migration History

| Version | Changes |
|---------|---------|
| 1 | Initial schema: `patients`, `visitations` |
| 2 | Added `suppliesUsed` column to visitations; dropped `emergency_alerts` |
| 3 | Added CRDT columns (`hlc`, `nodeId`, `isDeleted`) to patients & visitations; created `meta` table and HLC indexes |
| 4 | Created `stock_batches` table for inventory |
| 5 | Added `firstName`, `lastName`, `middleName`, `extension` columns to patients (with try-catch for idempotency); migrated existing `patientName` to `firstName` |

### Key DB Methods

**Patient CRUD:** `insertPatient`, `getPatients`, `getPatientsPaginated`, `getPatientCount`, `searchPatientsPaginated`, `searchPatientCount`, `getPatient(id)`, `updatePatient`, `deletePatient` (soft-delete with HLC), `searchPatients`

**Visitation CRUD:** `insertVisitation`, `updateVisitation`, `getVisitationsForPatient`, `getVisitationsPaginated`, `getVisitationCountForPatient`, `getVisitationsForMonth`, `getTodayVisitCount`, `getTodayVisitationsPaginated` (JOIN with patient name)

**CRDT Sync:** `getPatientChangesSince(hlc)`, `getVisitationChangesSince(hlc)`, `upsertPatientFromRemote`, `upsertVisitationFromRemote`

**Inventory:** `insertStockBatch`, `getStockBatchesForItem`, `getInventorySummary`, `getAllStockBatches`, `deductStock` (FEFO)

**Maintenance:** `compactTombstones(daysThreshold)`, `clearAllData`

---

## Providers (State Management)

### PatientProvider (`providers/patient_provider.dart`)

The **central provider** managing patients, visitations, pagination, and CRDT clock.

**State:**
- `_patients` — current page of patients (`List<Patient>`)
- `_totalPatients` — total patient count
- `_currentPage` / `_pageSize` (10) — patient list pagination
- `_searchQuery` — active search filter
- `_selectedPatient` — currently viewed patient
- `_visitations` — current page of selected patient's visits
- `_currentVisitPage` / `_visitPageSize` (10) — visit pagination
- `_todayVisits` — count of today's visits
- `_dashboardVisitPage` / `_dashboardVisitPageSize` (3) — dashboard visit pagination
- `_dashboardVisits` — paginated today's visits with patient names (`List<Map>`)
- `_clock` / `_nodeId` — HLC state
- `_onLocalWrite` — callback to trigger sync push after writes
- `_inventoryProvider` — reference for auto-deducting supplies

**Key Methods:**
- `initCrdt()` — Initialize HLC clock and node ID
- `loadPatients()` — Load current page (respects search query)
- `setSearchQuery(query)` — Filter + reset to page 0
- `refreshAll()` — Reload patients, today's visits, and selected patient's visits
- `addPatient(patient)` — Insert with HLC, reload, auto-push
- `updatePatient(patient)` — Update with HLC, reload, auto-push
- `deletePatient(id)` — Soft-delete with HLC, clamp page, reload, auto-push
- `selectPatient(patient)` — Set selected patient, load visits
- `addVisitation(...)` — Insert with HLC, auto-deduct supplies from inventory, reload today's visits, auto-push
- `updateVisitation(visit)` — Update with HLC, reload
- `deleteVisitation(visit)` — Soft-delete with HLC
- `loadTodayVisits()` — Count + load paginated dashboard visits
- `onSyncComplete(changedIds)` — Granular refresh after sync merge
- Pagination: `goToPage`, `nextPage`, `previousPage`, `firstPage`, `lastPage`
- Visit pagination: `goToVisitPage`, `nextVisitPage`, `prevVisitPage`, `firstVisitPage`, `lastVisitPage`
- Dashboard visit pagination: `goToDashboardVisitPage`, `nextDashboardVisitPage`, etc.

**Auto-push pattern:** Every write method calls `_autoPush()` which debounces (200ms) and then calls `_onLocalWrite?.call()` which triggers `SyncProvider.pushChanges()`.

### SyncProvider (`providers/sync_provider.dart`)

Manages the WebSocket sync lifecycle.

**State:** `_connectionState` (`SyncConnectionState`: disconnected/connecting/connected)

**Key Methods:**
- `init(patientProvider, {wsUrl})` — Create SyncClient, wire callbacks, run DataCompactor, auto-connect
- `connect()` / `disconnect()` — Manual connection control
- `forceSync()` — Disconnect + reconnect (manual refresh trigger)
- `pushChanges()` — Delegate to SyncClient

### InventoryProvider (`providers/inventory_provider.dart`)

Manages clinic supply stock batches.

**State:**
- `_summary` — `Map<String, int>` aggregated item → total quantity
- `_batches` — `List<StockBatch>` all batches with qty > 0

**Key Methods:**
- `loadInventory()` — Reload summary + batches
- `addStock({itemName, quantity, expirationDate})` — Add new batch
- `deductStock(itemName, qty)` — FEFO deduction
- `batchesForItem(itemName)` — Get batches for specific item

### AnalyticsProvider (`providers/analytics_provider.dart`)

Monthly analytics for symptoms and supplies used.

**State:** `_selectedYear`, `_selectedMonth`, `_symptomCounts`, `_supplyCounts`, `_totalVisits`

**Key Methods:**
- `loadAnalytics()` — Count symptom/supply occurrences for selected month
- `setMonth(year, month)` / `previousMonth()` / `nextMonth()` — Navigation

---

## CRDT Sync System

### Hybrid Logical Clock (`crdt/hlc.dart`)

Packed format: `<timestamp_hex_13>:<counter_hex_4>:<nodeId>`
Example: `018e1a2b3c4d5:0000:a1b2c3d4-...`

- `send()` — Increment for local write: `max(wall-clock, timestamp)` with counter bump
- `receive(remote)` — Merge with remote clock: result > both
- `pack()` / `unpack()` — Serialize to lexically orderable string
- Comparison operators: `>`, `<`, `>=`, `<=`, `==`

### Node ID (`crdt/node_id.dart`)

UUID v4 generated once on first launch, persisted in `meta` table as key `nodeId`.

### Sync Client (`crdt/sync_client.dart`)

WebSocket client connecting to relay server at `wss://olopsc-iskolinic.onrender.com/ws`.

**Features:**
- **Heartbeat:** Ping every 3 minutes (prevents Render timeout)
- **Exponential backoff reconnect:** 1s → 2s → 4s → ... → max 30s
- **Chunked sync:** Batches of 50 records
- **Auto-push:** Triggered after every local write (debounced 200ms)

**Protocol messages:**
| Type | Direction | Purpose |
|------|-----------|---------|
| `ping` | Client → Server | Heartbeat |
| `pong` | Server → Client | Heartbeat ack |
| `sync_request` | Client → Server | Request changes since HLC |
| `sync_response` | Server → Client | Historical data (batched, with `hasMore` flag) |
| `sync_ack` | Client → Server | Acknowledge batch, request next |
| `sync_push` | Both | Push local changes, broadcast to peers |

**Flow:**
1. On connect → `_requestSync()` sends `sync_request` with `sinceHlc`, then `pushChanges()`
2. Server responds with `sync_response` batches → merged via `SyncIsolate`
3. Each batch ack'd with `sync_ack` until `hasMore: false`
4. On local write → `pushChanges()` sends `sync_push` for patients then visitations
5. Remote `sync_push` received → ignore own echoes → merge via `SyncIsolate`

### Sync Isolate (`crdt/sync_isolate.dart`)

Processes CRDT merges on the main isolate but with microtask-friendly batching (yields every 10 records).

**Merge logic:** For each remote record, calls `DatabaseHelper.upsertPatientFromRemote` / `upsertVisitationFromRemote` which only applies the change if `remoteHlc > localHlc`.

Returns `SyncResult` with sets of changed patient/visitation IDs → triggers `PatientProvider.onSyncComplete()`.

### Data Compactor (`crdt/data_compactor.dart`)

Runs on startup. Permanently removes tombstoned records (`isDeleted = 1`) older than 90 days.

---

## Screens

### DashboardScreen (`screens/dashboard_screen.dart`)
- **Main app screen** with sidebar navigation to all other screens
- **Summary cards:** Total patients, today's visits, sync status
- **Quick Actions:** Record Visitation, Add Patient, Analytics, Refresh (calls `refreshAll()` + `forceSync()`)
- **Today's Visits list:** Paginated (3 per page), shows patient name, time, symptoms, treatment
  - Clicking a visit opens `PatientDetailScreen`
  - Shows **"Add Missing Treatment Details"** `TextButton.icon` if both `treatment` and `suppliesUsed` are empty, which opens `VisitationFormScreen` in edit mode
- **Sidebar navigation:** Dashboard, Patients, Analytics, Inventory

### PatientListScreen (`screens/patient_list_screen.dart`)
- **Paginated table** of all patients (10 per page)
- **Search bar** filters by name or ID number
- **Refresh button** (IconButton) beside "Add Patient" — calls `refreshAll()` + `forceSync()`
- Clicking a patient opens `PatientDetailScreen`

### PatientDetailScreen (`screens/patient_detail_screen.dart`)
- **Fullscreen dialog** showing patient info + paginated visitation history
- **Actions:** Edit patient, delete patient, add visit
- **Visitation tiles:** Show date, symptoms, treatment (with supplies inline), remarks
  - Each visitation can be **edited** (opens `VisitationFormScreen` with existing data) or **deleted**
- Treatment display format: `"Treatment: Supply1, Supply2, Treatment Text"`

### PatientFormScreen (`screens/patient_form_screen.dart`)
- **Dialog** for creating/editing patients
- Fields: First Name, Last Name, Middle Name, Extension (dropdown + custom), ID Number, Address, Guardian Name, Guardian Contact
- All text fields use `UpperCaseTextFormatter`
- Extension dropdown options: None, JR., SR., I, II, III, Others (shows custom text field)

### VisitationFormScreen (`screens/visitation_form_screen.dart`)
- **Dialog** for creating/editing visitations
- **Patient autocomplete** (searches DB, top 10 results) — auto-fills when `patientId` or `visitation` is passed
  - Falls back to async DB lookup if patient not found in memory (shows loading spinner)
  - When `patientId != null`, the patient name field is read-only
- **Symptom chips:** Grouped into Traumatic, Medical, Behavioral sections with show/hide toggle
- **Supply chips:** Clinic supplies with show/hide toggle
- **Free text:** Other Intervention Details, Remarks
- **Edit mode:** Pre-fills all fields from existing `Visitation`

### AnalyticsScreen (`screens/analytics_screen.dart`)
- Monthly symptom frequency chart and supply usage chart
- Month navigation (prev/next)

### InventoryScreen (`screens/inventory_screen.dart`)
- Stock batch management with add/deduct functionality
- FEFO (First-Expired, First-Out) deduction strategy

---

## Constants

### Symptoms (`constants/symptoms.dart`)

```dart
kTraumaticSymptoms = ['Wound', 'Sprain', 'Burn', 'Sunburn', 'Nose Bleed', 'Callus', 'Deltoid']
kMedicalSymptoms = ['Headache', 'Abdominal Pain', 'General Pain', 'NFW/Dizzy', 'Menstrual Pain',
  'Fever', 'Asthma', 'LBM', 'Toothache/Oral Pain', 'Nasal', 'Cough', 'Cold', 'Vomit',
  'Sore Throat', 'Eczema', 'Hypogastric Pain', 'Allergy', 'Rashes', 'Acidic', 'Due Meds Given']
kBehavioralSymptoms = ['Panic Attacks']
kSymptomsList = [...kTraumaticSymptoms, ...kMedicalSymptoms, ...kBehavioralSymptoms]
```

### Supplies (`constants/supplies.dart`)

```dart
kSuppliesList = ['Bandage', 'Cotton Balls', 'Alcohol', 'Betadine', 'Gauze', 'Medical Tape',
  'Band-Aid', 'Thermometer Cover', 'Disposable Gloves', 'Face Mask', 'Ice Pack', 'Hot Compress',
  'Tongue Depressor', 'Syringe', 'Saline Solution', 'Hydrogen Peroxide', 'Eye Drops', 'Ear Drops',
  'Paracetamol', 'Ibuprofen', 'Mefenamic Acid', 'Antacid', 'ORS Sachet', 'Antihistamine',
  'Ointment', 'Nasal Spray', 'Cough Syrup', 'Vitamin C']
```

---

## Formatters

### UpperCaseTextFormatter (`formatters/uppercase_text.dart`)

A `TextInputFormatter` that converts all input to uppercase. Applied to all patient form text fields (names, ID, address, guardian info).

---

## Theme

### AppTheme (`theme/app_theme.dart`)

- Uses `google_fonts` (likely Inter or similar)
- Dark-mode-ready design with glass card effects
- Key colors: `AppTheme.accent`, `AppTheme.danger`, `AppTheme.textPrimary`, `AppTheme.textSecondary`, `AppTheme.textMuted`, `AppTheme.dividerColor`, `AppTheme.cardLight`
- Key styles: `AppTheme.accentGradient`, `AppTheme.glassCard()`, `AppTheme.lightTheme`

---

## Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `provider` | ^6.1.2 | State management |
| `sqflite_common_ffi` | ^2.3.4+4 | SQLite for Windows desktop |
| `path_provider` | ^2.1.5 | App data directory |
| `path` | ^1.9.1 | Path manipulation |
| `fl_chart` | ^0.70.2 | Charts in analytics screen |
| `google_fonts` | ^6.2.1 | Typography |
| `intl` | ^0.20.2 | Date formatting |
| `uuid` | ^4.5.1 | ID generation |
| `audioplayers` | ^6.1.0 | Sound effects (if any) |
| `qr_flutter` | ^4.1.0 | QR code generation |
| `web_socket_channel` | ^3.0.2 | WebSocket for CRDT sync |

---

## Text Field Constraints

| Field | Max Length | Screen |
|-------|-----------|--------|
| First Name | 30 | PatientFormScreen |
| Last Name | 30 | PatientFormScreen |
| Middle Name | 30 | PatientFormScreen |
| Extension (Others) | 5 | PatientFormScreen |
| ID Number | 16 | PatientFormScreen |
| Address | 150 | PatientFormScreen |
| Guardian Name | 65 | PatientFormScreen |
| Guardian Contact | 20 | PatientFormScreen |
| Other Intervention Details | 150 | VisitationFormScreen |
| Remarks | 150 | VisitationFormScreen |

All enforced via both `maxLength` property and `LengthLimitingTextInputFormatter`. Character counters are hidden (`counterText: ''`).

---

## Conventions & Patterns

1. **Soft Deletes:** All patient and visitation records use `isDeleted` flag (0/1). Queries always filter `WHERE isDeleted = 0`. Tombstones are compacted after 90 days.

2. **CRDT Writes:** Every write (add/update/delete) stamps the record with a new HLC via `_tick()` and the local `_nodeId`. This enables last-writer-wins conflict resolution during sync.

3. **Auto-Push:** After every local write, `_autoPush()` debounces (200ms) then calls `SyncProvider.pushChanges()` which sends changes to the relay server.

4. **Auto-Deduct:** When a visitation is added with supplies, each supply is auto-deducted (1 unit, FEFO) from `InventoryProvider`.

5. **Pagination:** All list views are paginated. Patient list: 10/page. Dashboard visits: 3/page. Patient detail visits: 10/page.

6. **Uppercase Input:** All patient text fields use `UpperCaseTextFormatter` to normalize text to uppercase.

7. **Treatment Display:** Treatment and supplies are shown inline: `"Treatment: Supply1, Supply2, Treatment Text"` (supplies first, then treatment text if non-empty).

8. **Patient Name Format:** Computed as `"lastName, firstName middleName extension"` trimmed of extra whitespace.

9. **List Serialization:** `symptoms` and `suppliesUsed` are stored in SQLite as pipe-delimited strings (`|`), parsed on read via `split('|')`.

10. **Sync Relay:** The WebSocket relay server is hosted on Render at `wss://olopsc-iskolinic.onrender.com/ws`. The protocol supports chunked sync, heartbeats, and bidirectional push.

11. **Database Path:** `%APPDATA%/com.olopsc/OLOPSC Iskolinic/clinic.db` (via `getApplicationSupportDirectory()`)

12. **Assets:** `assets/app-icon-white.png`, `assets/app-icon-colored.png`
