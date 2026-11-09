# Getting Started

Add a verified walkthrough to a feature in five steps, then run it as a test.

## Overview

The examples come from the demo app in this repository, where a Calendar feature gets a "Create an event" walkthrough. Each team does the same thing for its own screens; nobody edits a central file.

### Tag the controls

Mark each view a step points at with `guideTarget(_:)`. IDs are dotted lowercase, such as `calendar.save`. The modifier records the view's frame and sets its accessibility identifier, so UI tests find the same view.

If you have a shared component library, give its controls an optional ID so features can opt in. The demo's `AppButton` does this:

```swift
AppButton("Save", guideID: "calendar.save") { ... }
```

Inside the component the ID goes straight to `.guideTarget(guideID)`. Passing `nil` leaves the view unchanged.

### Report a fact

Some steps finish when state changes, such as "the event count went up by one". Publish that state with `guideFact(_:value:)`:

```swift
.guideFact("calendar.event.count", value: store.events.count)
```

Supported values are `Bool`, `Int` and `String` (see ``GuideFactConvertible``). The fact is reported when the view appears, updated whenever the value changes, and forgotten when the view disappears.

### Write a flow

A flow is a JSON file in the feature package at `Resources/flows/`. Its ID must start with the feature's namespace.

```json
{
  "id": "calendar.create_event",
  "title": "Create an event",
  "steps": [
    { "target": "calendar.new_event", "say": "Tap New event.", "completeWhen": { "targetVisible": "calendar.save" } },
    { "target": "calendar.save", "say": "Tap Save to add the event.", "completeWhen": { "fact": "calendar.event.count", "increasedBy": 1 } }
  ]
}
```

Each step names a `target`, a `say` line and a `completeWhen` check. See ``Check`` for the available checks and ``Step`` for the optional `pick` field.

### Register the feature

Declare the folder on the feature's target in `Package.swift`. It must be `.copy`: with `.process`, SwiftPM flattens the folder and the feature reports a load error.

```swift
resources: [.copy("Resources/flows")]
```

Then wrap registration so the app does not need to know about your bundle. The `prepare` closure runs before a flow starts and should show the right screen and reset transient UI:

```swift
public enum CalendarGuide {
    @MainActor
    public static func feature(prepare: @escaping @MainActor () -> Void) -> GuideFeature {
        GuideFeature(namespace: "calendar", bundle: .module, prepare: prepare)
    }
}
```

### Add the host

The app creates one ``GuideController`` from every feature and attaches one `guideHost(_:launcherBottomClearance:)` at the root of the view hierarchy:

```swift
let controller = GuideController(features: [
    EditorGuide.feature(prepare: {
        shell.selectedTab = .editor
        shell.blocks.closeMenus()
    }),
    CalendarGuide.feature(prepare: { shell.selectedTab = .calendar }),
])

AppShell(shell: shell)
    .guideHost(controller, launcherBottomClearance: 120)
```

A `?` button now lists every registered flow. Raise `launcherBottomClearance` if the button would cover other bottom controls.

### Run flows as tests

In a UI test target that depends on `GuideKitTesting`, one test covers every registered flow, including ones added later:

```swift
import XCTest
import GuideKitTesting

final class AllFlowsUITests: XCTestCase {
    func testEveryRegisteredFlowCompletes() {
        FlowTestDriver(testCase: self).runAll()
    }
}
```

`FlowTestDriver` launches the app once per flow with the `GUIDEKIT_TEST` environment enabled, taps each step's target and fails with the runtime's message if a step cannot complete, for example:

```
`editor.add_todo` step 1: target `editor.add_block_button` not found
```
