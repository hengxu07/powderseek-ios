# Powderseek iOS — Architecture

## Stack

| Layer | Technology | Notes |
|---|---|---|
| UI | SwiftUI | iOS 17+, MVVM pattern |
| Async / streaming | URLSession + AsyncThrowingStream | SSE streaming token-by-token |
| State management | ObservableObject + @Published | @MainActor for thread safety |
| Persistence | UserDefaults | Session ID survives app restarts |
| Backend | FastAPI on Railway | Shared with the web app |

---

## High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      iOS App (SwiftUI)                       │
│                                                              │
│  Views                                                       │
│  ┌───────────────────────────────────────────────────────┐   │
│  │  ContentView                                          │   │
│  │    └─ ChatView                                        │   │
│  │         ├─ MessageBubble        (per message)         │   │
│  │         ├─ ResortChips          (below assistant msg) │   │
│  │         ├─ TripInputSheet       (calendar sheet)      │   │
│  │         └─ ResortDetailSheet    (resort info sheet)   │   │
│  └───────────────────────────────────────────────────────┘   │
│                         │ @EnvironmentObject                 │
│  ┌──────────────────────▼────────────────────────────────┐   │
│  │  ChatViewModel  (@MainActor ObservableObject)         │   │
│  │                                                       │   │
│  │  @Published  messages, isStreaming, resorts, trip     │   │
│  │  sessionId   (UserDefaults — persists across restarts)│   │
│  │  resortNameMap  (name/slug lookup built from /resorts)│   │
│  │  resortSlugs(in:) — scans **bold** text for chips     │   │
│  └──────────────────────┬────────────────────────────────┘   │
│                         │                                    │
│  ┌──────────────────────▼────────────────────────────────┐   │
│  │  APIClient                                            │   │
│  │                                                       │   │
│  │  fetchResorts()       → GET /resorts                  │   │
│  │  fetchResortDetail()  → GET /resort/{slug}            │   │
│  │  streamChat()         → POST /chat  (SSE)             │   │
│  │    returns AsyncThrowingStream<String, Error>         │   │
│  │    URLSession.bytes(for:).lines → parse SSE events    │   │
│  │    yields "text" chunks, finishes on "done"/"error"   │   │
│  └──────────────────────┬────────────────────────────────┘   │
└─────────────────────────┼────────────────────────────────────┘
                          │ HTTPS / SSE
┌─────────────────────────▼────────────────────────────────────┐
│              FastAPI Backend  (Railway)                      │
│  POST /chat · GET /resorts · GET /resort/{slug}              │
└──────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### App launch
1. `PowerseekApp` injects `ChatViewModel` as an `@EnvironmentObject`
2. `ChatViewModel.loadResorts()` calls `GET /resorts` and builds `resortNameMap` (name → slug)

### Sending a message
1. User types in `ChatView` input bar and taps send
2. `ChatViewModel.send(text:)` appends a user bubble and an empty streaming assistant bubble
3. `APIClient.streamChat()` opens a `URLSession.bytes` connection to `POST /chat`
4. SSE lines arrive as `data: {"type":"text","content":"..."}` — each chunk is appended to the last message
5. On `"done"` the stream closes; `isStreaming` is set to false and the bubble stops animating

### Resort chips
1. After streaming completes, `resortSlugs(in: message.content)` scans for `**bold**` resort names
2. Bold spans are matched against `resortNameMap` with progressive fallback (exact → first token → first N words)
3. Matched slugs render as tappable `ResortChips` below the assistant bubble

### Resort detail sheet
1. User taps a chip → `selectedResort` is set → `sheet(item:)` presents `ResortDetailSheet`
2. Sheet's `.task` calls `APIClient.fetchResortDetail(slug:)` → `GET /resort/{slug}`
3. Detail renders: snow stat cards, 7-day bar chart, terrain breakdown bar, mountain stats, tag cloud

---

## View Breakdown

| View | Responsibility |
|---|---|
| `ChatView` | Message list, input bar, sheet triggers |
| `MessageBubble` | Renders `AttributedString(markdown:)` for bold/italic in chat |
| `ResortChips` | Horizontal row of tappable slug pills |
| `TripInputSheet` | Form for dates, origin airport, skill level, budget |
| `ResortDetailSheet` | Full resort info: snow chart, terrain, stats, tags |
| `SnowBarChart` | 7-day bar chart using GeometryReader for proportional scaling |
| `DifficultyBar` | Stacked terrain breakdown (beginner/intermediate/advanced/expert) |
| `TagCloud` | Horizontally scrolling tag capsules |

---

## Key Swift Patterns

- **`AsyncThrowingStream`** — bridges URLSession's async byte stream into a typed async sequence the ViewModel can `for try await` over
- **`URLSession.bytes(for:).lines`** — iterates SSE lines without buffering the full response
- **`@MainActor`** — all ViewModel mutations happen on the main thread; no manual `DispatchQueue.main`
- **`AttributedString(markdown:)`** — renders Claude's `**bold**` resort names natively in SwiftUI `Text`
- **`sheet(item:)`** with a custom `Identifiable` wrapper (`ResortSlug`) — avoids retroactive String conformance

---

## Environment Configuration

Switching between local and production backend is handled by a compile-time flag in `APIClient.swift`:

```swift
#if DEBUG
static let baseURL = "http://127.0.0.1:8000"   // local FastAPI
#else
static let baseURL = "https://web-production-56f6d.up.railway.app"
#endif
```

---

## Directory Structure

```
Powderseek/
└── Powderseek/
    ├── PowerseekApp.swift          — app entry point, injects ChatViewModel
    ├── Models/
    │   ├── ChatMessage.swift
    │   ├── Resort.swift            — ResortSummary, ResortDetail, ForecastDay
    │   └── TripInput.swift
    ├── Services/
    │   └── APIClient.swift         — URLSession, SSE streaming, REST calls
    ├── ViewModels/
    │   └── ChatViewModel.swift     — @MainActor ObservableObject, session, chip detection
    └── Views/
        ├── ContentView.swift
        ├── ChatView.swift
        ├── MessageBubble.swift
        ├── ResortChips.swift
        ├── TripInputSheet.swift
        └── ResortDetailSheet.swift — SnowBarChart, DifficultyBar, TagCloud sub-views
```
