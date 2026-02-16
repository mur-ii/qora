# 📊 Performance Summary Feature — Flutter Hotel Booking App

## 🎯 Goal

Build a **Performance Summary** feature that records how users perform hotel search and booking flows.

The data will be used to compare usability between **GUI (Graphical User Interface)** and **VUI (Voice User Interface)**.

All data is stored **locally (offline-first)**.

---

## 🧰 Tech Stack

Use the following:

- **Framework:** Flutter
- **State Management:** flutter_bloc (BLoC Architecture)
- **Local Storage:** Hive
- **Serialization:** hive_generator + build_runner
- **Export Data:** csv + path_provider

Do not use any storage other than Hive.

---

## 📦 Data Model

Create a model named:

```
PerformanceSummary
```

Required fields:

| Field | Type |
|-------|------|
| sessionId | String |
| startTime | DateTime |
| endTime | DateTime |
| durationInSeconds | int |
| interactionMethod | enum (GUI, VUI) |
| totalClicks | int |
| totalVoiceCommands | int |
| errorsCount | int |
| taskCompleted | bool |
| searchedLocation | String |
| selectedHotelName | String? |
| bookingSuccess | bool |
| createdAt | DateTime |

---

## 🧠 Session Tracking Flow

### When the user starts hotel search

Dispatch:

```
StartSession
```

### During interaction

Dispatch based on user actions:

```
AddClick
AddVoiceCommand
AddError
```

### When task/booking ends

Dispatch:

```
CompleteTask
EndSession
```

Duration is calculated automatically from:

```
startTime → endTime
```

---

## 🧱 BLoC Architecture

### Event

Create:

```
PerformanceEvent
```

Required events:

- StartSession
- AddClick
- AddVoiceCommand
- AddError
- CompleteTask
- EndSession
- LoadAllSessions

---

### State

Create:

```
PerformanceState
```

Required states:

- Initial
- Loading
- SessionActive
- SessionSaved
- LoadedSessions
- ErrorState

---

### Bloc

Create:

```
PerformanceBloc
```

Responsibilities:

- Manage the active session
- Compute duration
- Save to Hive
- Load history
- Compute simple analytics

---

## 💾 Local Storage

Use Hive box:

```
performance_box
```

Each session is saved as an object.

---

## 📱 Summary UI Page

Create:

```
PerformanceSummaryPage
```

Display:

### Summary Statistics

- Total Sessions
- Average Duration
- Total Errors
- Booking Success Rate (%)
- GUI vs VUI Usage Comparison

### Session History

Card list showing:

- Interaction Method
- Duration
- Success/Failure Status
- Search Location
- Hotel Name

Design style:

✅ Modern  
✅ Minimal  
✅ Professional Card UI  

---

## 📈 Automatic Analytics

Compute:

- Average Duration
- Completion Rate
- Error Rate
- GUI vs VUI usage count
- Booking Success Rate

---

## 🔄 Integration with Booking Flow

Example usage:

### Start Session

```dart
context.read<PerformanceBloc>().add(
  StartSession(method: InteractionMethod.GUI),
);
```

### User clicks a button

```dart
context.read<PerformanceBloc>().add(AddClick());
```

### User uses voice

```dart
context.read<PerformanceBloc>().add(AddVoiceCommand());
```

### Booking completed

```dart
context.read<PerformanceBloc>().add(CompleteTask());
context.read<PerformanceBloc>().add(EndSession());
```

---

## 📤 CSV Export

Add a button:

```
Export to CSV
```

Requirements:

- File saved on device
- Can be opened in Excel / SPSS
- Export all session data

Use packages:

```
csv
path_provider
```

---

## 📁 Folder Structure

Use the existing features module pattern in this project:

```
lib/
  features/
    performance/
      data/
      models/
      bloc/
      repository/
      pages/
      widgets/
```

---

## 🧪 Code Quality

The code must be:

- Null-safe
- Clean architecture friendly
- Modular
- Easy to extend
- Production ready
- Following Flutter + BLoC best practices

---

## 🚀 Expected Output

Implementation should include:

1. Hive model + adapter
2. Full PerformanceBloc implementation
3. Repository
4. PerformanceSummaryPage UI
5. CSV export function
6. Example integration in booking flow
7. pubspec.yaml dependencies

---

## ✅ Important Note

This feature is used for the research comparison:

```
GUI vs VUI Hotel Booking Experience
```

Data accuracy and consistency are required.

---

## 🎉 Done

Implement the feature per the spec above with clean, production-ready code.
