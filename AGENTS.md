# KiS Extensions — project rules

## Context
This is an iOS app called "KiS Extensions" used by Emirates cabin crew.
The app is a dashboard launcher for several self-contained mini-apps:
- **Allocate Positions** — trip import + crew position allocation
- **Flight Planner** — read-only trip browsing (its own lens on SavedTrip)
- **Settings** — app-wide preferences

Deployment target iOS 26+. All new code targets this baseline.

## Mini-app isolation
- Each mini-app has its own `NavigationStack` (own back stack).
- Each mini-app lives in its own `Views/<MiniApp>/` folder.
- **Allocate Positions** owns `SavedTrip` writes (import, delete, re-allocate).
- **Flight Planner** reads `SavedTrip` only — no imports, no deletes.
- Do not cross mini-app boundaries without asking first.

## Non-negotiables
- SwiftUI + SwiftData only for new code. No UIKit, no Storyboards.
- Every Swift file uses `// MARK: -` section headers.
- Emirates brand: navy primary, gold accent, SF Pro font.
- No emojis, `#`, `@`, `*`, `<`, `>`, or ALL CAPS in user-facing copy.

## Change discipline
- Do NOT refactor existing code outside the current stage's scope.
- Do NOT modify files outside the mini-app I'm working on unless I ask.
- If you need to touch shared code (AppState, schema, routing), ASK FIRST
  and show me the exact change before applying it.

## Stage discipline
- Work only on the stage I specify. Do not jump ahead.
- Always show me a build plan before writing code.
- After each stage, run Build and report any errors before stopping.
- If a question arises during the stage, stop and ask — do not guess.
