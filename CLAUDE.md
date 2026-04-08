# KiS Extensions — AI Report Writer feature rules

## Context
This is an existing iOS app called "KiS Extensions" used by Emirates cabin
crew. I am adding a NEW feature: an offline AI-powered KiS incident report
writer using Apple Foundation Models.

## Scope discipline (critical)
- Do NOT modify existing files outside the ReportWriter feature folder
  unless I explicitly ask.
- Do NOT refactor existing code.
- Do NOT change the existing app's theme, fonts, or navigation unless asked.
- If you need to integrate with existing code (e.g., add a navigation entry),
  ASK FIRST and show me the exact change before applying it.

## Feature: AI Report Writer
Offline iOS app feature for writing KiS incident reports using on-device AI.
MUST work in airplane mode. Deployment target iOS 26+.

## Non-negotiables
- SwiftUI + SwiftData only for new code. No UIKit, no Storyboards.
- Use Apple Foundation Models (`import FoundationModels`) for ALL AI work.
  NEVER suggest OpenAI, Anthropic API, MLX, llama.cpp, or any cloud model.
  This feature is 100% offline.
- All structured AI output uses `@Generable` types. Never parse raw strings.
- No emojis in report output. No #, @, *, <, >, or ALL CAPS.
- Every Swift file uses `// MARK: -` section headers.
- Emirates brand: navy primary, gold accent, SF Pro font.

## Folder structure (all new files go here)
ReportWriter/
├── Models/      — @Generable types and SwiftData models for this feature
├── Services/    — KiSAgent, CategoryTree
├── Views/       — SwiftUI views for this feature
├── Categories/  — generated category data (do not edit by hand)
└── Resources/   — feature-specific assets

## Stage discipline
Work only on the stage I specify. Do not jump ahead.
Always show me a build plan before writing code.
After each stage, run Build and report any errors before stopping.
If a question arises during the stage, stop and ask — do not guess.
