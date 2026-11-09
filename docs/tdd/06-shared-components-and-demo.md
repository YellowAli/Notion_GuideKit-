# 06 Shared components and demo

## Purpose

Show that separate teams can adopt GuideKit with no changes to the library, and keep tagging out of product code.

## Where it lives

- `Demo/Packages/DesignSystem/Sources/DesignSystem/`: `Theme.swift` (with `Hairline`), `AppButton.swift`, `AppMenuRow.swift`
- `Demo/Packages/EditorFeature/Sources/EditorFeature/`: `BlockStore.swift`, `EditorView.swift`, `EditorGuide.swift`, `Resources/flows/`
- `Demo/Packages/CalendarFeature/Sources/CalendarFeature/`: same shape
- `Demo/GuideDemo/`: `GuideDemoApp.swift`, `AppShell.swift` (with `ShellModel` and `DemoTab`)
- `Demo/project.yml` (XcodeGen source of `Demo/GuideDemo.xcodeproj`)

## How it works

`AppButton` and `AppMenuRow` take an optional `guideID` and forward it to `.guideTarget`. Product code writes `AppButton("Save", guideID: "calendar.save")`. Each feature package exposes a `Guide` enum (`EditorGuide`, `CalendarGuide`) that builds a `GuideFeature` from its own bundle. `GuideDemoApp` creates one controller from both and `AppShell` is the single host's content. Each feature's `prepare` selects its tab; the Editor's also closes menus.

## Key decisions and why

- **Tagging in shared components.** Rejected: calling `.guideTarget` everywhere. Cost: components need an extra parameter. One-off controls still call `.guideTarget` directly.
- **Each team is its own package** depending only on GuideKit and DesignSystem. That is the reuse proof; the Calendar step changed nothing in `Sources/` or `DesignSystem`.
- **Hand-built tab bar instead of `TabView`.** Anchor preferences through the UIKit-backed `TabView` were unverified, and failure would break every flow. Cost: about 20 lines.
- **Content lives in `ShellModel`** so it survives tab switches while only the visible screen is mounted.
- **XcodeGen.** The project is generated and committed; `project.yml` uses a folder source, so moving files needs only regeneration.
- **Notion-style, not Notion.** No logo or wordmark; the app says it is an unofficial concept demo. Fit with Notion is inferred from public reporting only.

## Edge cases and limits

- `AppButton` maps a few symbol names to accessibility labels, which puts editor copy in DesignSystem (deferred).
- An open New event form is lost on tab switch (deferred).
- `DesignSystem` has no tests.

## Tests

`Demo/Packages/EditorFeature/Tests/` (6 tests on `BlockStore`) and `Demo/Packages/CalendarFeature/Tests/` (2 on `EventStore`). Flows are covered by the UI tests in `07-test-driver.md`.
