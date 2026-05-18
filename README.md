# Powderseek iOS

Native SwiftUI companion app for [Powderseek](https://github.com/hengxu07/powderseek) — an AI-powered ski and snowboard trip planner.

## Features

- **Chat interface** — ask in plain English, get a confident resort recommendation with honest trade-offs
- **SSE streaming** — responses stream token-by-token using `URLSession.bytes`, same as the web app
- **Trip form** — set dates, origin airport, skill level, and budget before sending your first message
- **Resort chips** — tappable pills appear below assistant messages; tap to open the resort detail sheet
- **Resort detail sheet** — 7-day snow bar chart, terrain breakdown (beginner/intermediate/advanced/expert mix), mountain stats, terrain and vibe tags
- **Ski-only banner** — orange warning when a resort doesn't allow snowboarding (Alta, Deer Valley)
- **Closed-season banner** — blue warning when a resort is outside its operating window
- **Session persistence** — conversation session ID stored in `UserDefaults` so context survives app restarts

## Architecture

The app follows SwiftUI MVVM:

| Layer | Files |
|---|---|
| Models | `ChatMessage.swift`, `Resort.swift`, `TripInput.swift` |
| Services | `APIClient.swift` — URLSession, SSE streaming, REST calls |
| ViewModels | `ChatViewModel.swift` — `@MainActor ObservableObject`, resort name map, session management |
| Views | `ChatView`, `MessageBubble`, `TripInputSheet`, `ResortChips`, `ResortDetailSheet` |

Key Swift concepts used:
- `AsyncThrowingStream<String, Error>` for SSE streaming
- `URLSession.bytes(for:).lines` to iterate server-sent events
- `AttributedString(markdown:)` for bold/italic rendering in chat bubbles
- `sheet(item:)` with a custom `Identifiable` wrapper for the resort detail sheet
- `@MainActor` to keep all UI updates on the main thread without manual `DispatchQueue.main`

## Backend

Connects to the same Railway-hosted FastAPI backend as the web app.

| Environment | URL |
|---|---|
| Debug (simulator) | `http://127.0.0.1:8000` |
| Release | `https://web-production-56f6d.up.railway.app` |

Switching is handled by a `#if DEBUG` compile-time flag in `APIClient.swift` — no manual changes needed.

## Local setup

1. Clone the repo and open `Powderseek/Powderseek.xcodeproj` in Xcode
2. Run the Powderseek backend locally (`uvicorn app.main:app --reload` from the [main repo](https://github.com/hengxu07/powderseek))
3. Select an iPhone simulator and hit Run

For production backend, build in Release configuration or temporarily swap the `#if DEBUG` flag.

## Requirements

- Xcode 15+
- iOS 17+ deployment target
- Swift 5.9+
