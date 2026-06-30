# <img width="24" alt="app-icon-white" src="https://github.com/user-attachments/assets/06d1dc8f-b749-4581-a11f-0dcbbec3d40d" /> OLOPSC ISKOLINIC

<img width="1600" alt="OLOPSC-ISKOLINIC-HEADER" src="https://github.com/user-attachments/assets/d86da463-53d0-4e83-aaea-ad266b1c6cbe" />

Precursor to the <a href="https://github.com/RXAliman/iskolinic">ISKOLINIC main repository</a>. A Computer Science Thesis project by the ISKOLINIC Team actively used by the Our Lady of Perpetual Succor College (OLOPSC) School Health Services.

## The ISKOLINIC Team

<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/349a114e-7dfe-4242-a271-3f48b27d7d3e" width="150" height="150">
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/e62abce2-0b2c-4d5d-b306-e0233a76f64c" width="150" height="150">
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/d727dd28-39f2-4f38-81f6-c6906d3763ff" width="150" height="150">
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/b6bc9053-9cdc-4993-9147-5d7a81b8c958" width="150" height="150">
    </td>
  </tr>
  <tr>
    <td align="center">
      <b>Rovic Aliman</b><br>
      <sub>Developer</sub>
    </td>
    <td align="center">
      <b>Amparito Orticio</b><br>
      <sub>Researcher</sub>
    </td>
    <td align="center">
      <b>Marvin Uneta</b><br>
      <sub>Researcher</sub>
    </td>
    <td align="center">
      <b>Aiza Caballero</b><br>
      <sub>Researcher</sub>
    </td>
  </tr>
</table>

## ISKOLINIC: System Overview

ISKOLINIC is a **School-Based Health Management System (SHMS)** developed as a Computer Science thesis project in partnership with the Our Lady of Perpetual Succor College (OLOPSC) School Health Services unit.

### What the System Does

ISKOLINIC is composed of two main components:

1. **Desktop Application (Flutter/Windows):** Used by clinic staff to manage the following:
   - **Patient Registry** — a roster of students and employees who visit the clinic.
   - **Visitation Records** — per-visit logs capturing the patient, date and time, presenting symptoms, treatment given, supplies consumed, and clinical remarks.
   - **Inventory Management** — tracking consumable medical supplies using a First-Expired, First-Out (FEFO) stock batch model.
   - **Custom Symptoms** — a clinic-defined list of chief complaints selectable during visit logging.
   - **Analytics** — dashboards summarizing visit counts, department breakdowns, and supply usage.

2. **Relay Server (Dart/Shelf):** A lightweight WebSocket server deployed to the cloud (e.g., Render) that acts as a synchronization hub between desktop nodes. It does not perform any business logic — it only brokers CRDT state between connected clients.

### Design Philosophy: Offline-First

ISKOLINIC is designed to function **fully without an internet connection**. All data is stored locally in a SQLite database on each desktop machine. The relay server is only needed to propagate changes to other clinic terminals. If the relay server is unavailable, the application continues to work — changes are simply queued and pushed when connectivity is restored.

This offline-first design is the primary motivation for adopting a CRDT-based synchronization strategy, described in detail below.

## ISKOLINIC CRDT Architecture & Walkthrough

This section provides a comprehensive walkthrough of the Conflict-free Replicated Data Type (CRDT) implementation in ISKOLINIC. It covers the foundational concepts, the specific type of CRDT used, the algorithms powering it, and the system architecture.

### 1. Foundational Concepts: What is a CRDT?

In distributed systems where multiple devices (nodes) can operate offline and independently modify data, keeping everyone's database in sync is a major challenge. Traditional databases use *write-time coordination* — meaning a write cannot be committed until all (or a quorum of) nodes agree on the new state. This requires constant network connectivity and introduces latency.

A **Conflict-free Replicated Data Type (CRDT)** solves this mathematically. It is a data structure designed so that:
1. Replicas can be updated locally **without requiring locks, consensus, or write-time coordination** with other nodes.
2. It is always possible to mathematically resolve conflicts when replicas eventually synchronize.
3. All nodes are guaranteed to converge to the exact same state eventually (**Eventual Consistency**).

> **Important clarification for ISKOLINIC:** "Without coordination" in CRDT theory means without *locking or consensus protocols* — not without any network infrastructure. ISKOLINIC uses a central **relay server as a message broker** to transport state between nodes (a star topology). The relay never decides which data is correct; that decision is made identically and independently on every node by the same deterministic merge rule. Nodes remain fully operational offline; the relay is only needed for multi-node convergence.

### 2. ISKOLINIC's CRDT Type: LWW-Register (Last-Write-Wins Register)

ISKOLINIC implements a **State-based CRDT**, specifically a **collection of LWW-Registers (Last-Write-Wins Registers)**, one per database record, organized as an **LWW-Register Map** at the table level.

- **State-based (CvRDT):** Instead of sending individual operations (like "set field X to value Y"), the system exchanges the actual full current state — the complete database row. The merge function then decides which version to keep.
- **LWW-Register (per record):** Each database row is treated as a single register. The register's *value* is the entire row state (all fields, including `isDeleted`). The register's *timestamp* is the single `hlc` field. When two nodes have different versions of the same record, the one with the higher HLC unconditionally overwrites the other — no field-level merging occurs.
- **LWW-Register Map (per table):** Each database table is a `Map<UUID, LWW-Register>`, where the UUID is the record's `id`. New records are inserts into the map; updates overwrite the register at that key if the incoming HLC is higher.
- **Tombstone deletion:** When a record is deleted, it is not removed from the map. Instead, `isDeleted` is set to `1` and a new, higher HLC is written — making the deletion itself a *write* to the register. This tombstone value then propagates to all nodes and wins over any older live state via the same LWW rule.

> **Why not LWW-Element-Set?** The canonical LWW-Element-Set (Shapiro et al., 2011) maintains *two separate timestamps per element* — one for the most recent add operation and one for the most recent remove operation — and resolves membership by comparing them. ISKOLINIC uses a **single HLC per record** that covers both live state and deletion. This simpler design is an LWW-Register, where the tombstone (`isDeleted = 1`) is just a value the register can hold, not a separate tracking structure.

Every core model in ISKOLINIC (`Patient`, `Visitation`, `InventoryItem`, `StockBatch`, `CustomSymptom`) includes these mandatory CRDT fields:
- `hlc`: The single Hybrid Logical Clock timestamp representing the last write to this register (any field change or deletion).
- `nodeId`: The unique identifier of the node that produced this version of the register.
- `isDeleted`: A field *within* the register's value — the tombstone flag for soft-deletion.

### 3. The Algorithm: Hybrid Logical Clocks (HLC)

To determine which write is the "Last Write," we need a reliable clock. Relying purely on physical device clocks (wall-clock time) is dangerous because device clocks can drift, be manually changed, or be completely wrong. 

ISKOLINIC uses a **Hybrid Logical Clock (HLC)** (`lib/crdt/hlc.dart`), which combines physical time with a logical counter:
1. **Timestamp:** The physical time in milliseconds since epoch.
2. **Counter:** A logical incrementer that breaks ties if multiple events happen in the same physical millisecond.
3. **Node ID:** A unique UUID generated for the specific clinic installation (`lib/crdt/node_id.dart`). This acts as the absolute final tie-breaker if both the timestamp and counter are identical.

**How HLC works in ISKOLINIC:**
- **Local Write:** `HLC.send()` gets the current physical time. If the physical time is greater than the previous HLC, it uses the physical time and resets the counter to `0`. If physical time is lagging (or updates happen too fast), it keeps the old timestamp and increments the counter.
- **Remote Receive:** `HLC.receive(remote)` takes the maximum of the local physical time, the local HLC, and the incoming remote HLC, incrementing the counter if necessary. This pushes all clocks forward, ensuring causality is preserved even if device clocks are wildly out of sync.

**The `pack()` format and lexical ordering:**

HLC values are serialized to a plain string for storage in SQLite using a carefully designed format:
```
<13-char hex timestamp>:<4-char hex counter>:<nodeId>
// Example: 019733a1c2f:0000:a1b2c3d4-...
```
The timestamp and counter are zero-padded hexadecimal numbers. This padding is the key insight: because both components are fixed-width, SQLite's plain text comparison (`WHERE hlc > ?`) produces the **correct chronological ordering** without any custom SQL functions. The system exploits lexical sort order to implement distributed clock comparison entirely within standard SQLite queries.

### 4. Architecture and Codebase Walkthrough

#### A. Local Writes & Provider Layer
When a user adds or updates a record (e.g., a Patient), the action goes through the `PatientProvider` (`lib/providers/patient_provider.dart`).
1. The provider generates a new HLC tick (`_tick()`).
2. The record is updated with the new `hlc` and the local `nodeId`.
3. The change is saved locally via SQLite (`DatabaseHelper`).
4. A debounced `_autoPush()` triggers the `SyncProvider` to broadcast the change to the relay server.

#### B. The Merge Engine (`DatabaseHelper`)
The conflict resolution mathematically occurs during the SQLite upsert (`lib/services/database_helper.dart`). For example, in `upsertPatientFromRemote(Patient remote)`:
```dart
final localHlc = HLC.unpack(existing.first['hlc']);
final remoteHlc = HLC.unpack(remote.hlc);

if (remoteHlc > localHlc) {
  // Remote is newer, overwrite local state
  await db.update('patients', remote.toMap(), ...);
}
// Else, local is newer or equal, silently ignore the remote payload.
```
Because `HLC` implements standard `Comparable`, `remoteHlc > localHlc` checks the physical time first, then the logical counter, and finally the Node ID.

#### C. Relay Server & Sync Client (`SyncClient`)
- **Connection:** The desktop app maintains a WebSocket connection (`lib/crdt/sync_client.dart`) to the Dart relay server (`olopsc_iskolinic_relay_server/bin/server.dart`).
- **Batched Sync:** To prevent memory limits and WebSocket max payload errors, data is synced in batches of 50 records per message.
- **In-Memory Relay:** The relay server acts as a stateless router. It keeps an in-memory map of records, applying the exact same `remoteHlc > existingHlc` logic to hold the most recent state. When a new node connects, it sends a `sync_request` with its `lastPushHlc` marker (the highest HLC this node has *sent*), and the server streams down everything newer.
- **`lastPushHlc` vs. server cursor:** The client tracks `lastPushHlc` in its local SQLite `meta` table — the highest HLC it has successfully *pushed*. The server independently tracks what each client has *received*. This distinction ensures delta-sync is correct in both directions even after a partial sync or a dropped connection.
- **"Time Traveler" sanity check:** Before accepting any incoming record, `SyncClient` validates that its HLC timestamp is not more than **24 hours in the future** (`now + 86,400,000 ms`). Records from a node with a badly misconfigured system clock are silently dropped to prevent a single bad device from poisoning the entire cluster's ordering.

#### D. Cooperative Merge Processing (`SyncIsolate`)
Merging hundreds of records with SQLite lookups would cause the Flutter UI to freeze (jank). `SyncIsolate` (`lib/crdt/sync_isolate.dart`) is designed to prevent this, but it is important to note its exact mechanism: it is **not** a true OS-level background thread (`Isolate.spawn`). Instead, it uses **cooperative yielding** — every 10 records it calls `await Future.delayed(Duration.zero)`, which yields control back to the Flutter event loop long enough to process a frame before resuming. This achieves smooth UI without the overhead of a separate memory-isolated thread.
- The `SyncClient` receives a JSON payload.
- It passes the batch to `SyncIsolate.mergeBatch()`.
- Merge runs record-by-record with periodic yields, keeping the UI responsive.
- It returns a `SyncResult` containing only the `Set<String>` of IDs that **actually changed** (i.e., where `remoteHlc > localHlc` was true). Records that lost the LWW comparison are not included.
- The UI Providers listen to these changed IDs and selectively rebuild the UI only if a currently visible record was modified — avoiding expensive full-list reloads after every sync.
- **Orphaned visitation handling:** If a `visitation` record arrives before its parent `patient` record (a race condition possible in chunked sync), the `FOREIGN KEY` constraint would cause a crash. The merge engine catches this specific exception and silently skips the orphaned record. The next sync cycle will naturally insert it once the parent patient record has arrived.

#### E. Data Compaction (`DataCompactor`)
Because tombstones (`isDeleted = 1`) are kept to guarantee that deletions propagate correctly to all nodes, the database would slowly bloat over time. `DataCompactor` (`lib/crdt/data_compactor.dart`) runs once on startup via `SyncProvider.init()` to hard-delete ancient tombstones.

The cutoff is computed as an HLC value representing `now - 90 days`. Any tombstoned record whose `hlc` is lexically less than this cutoff string is permanently removed:
```dart
final cutoff = HLC(
  timestamp: DateTime.now().subtract(Duration(days: 90)).millisecondsSinceEpoch,
  counter: 0, nodeId: '',
).pack();
// Then: DELETE FROM patients WHERE isDeleted = 1 AND hlc < cutoff
```
By 90 days, the system assumes all offline nodes have reconnected and received the deletion.

> **Scope note:** In the current implementation, `compactTombstones` only hard-deletes from the `patients` and `visitations` tables. Tombstones in `inventory`, `inventory_stocks`, and `custom_symptoms` are **not** currently compacted, meaning deleted supply records accumulate indefinitely. This is a known limitation.
