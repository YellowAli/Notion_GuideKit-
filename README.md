# GuideKit

![A GuideKit walkthrough: tap New event, tap Save, and the event appears](docs/demo.gif)

GuideKit is a Swift library for in-app walkthroughs that are checked against the real UI. A team tags controls through its shared components and adds a JSON file. Every walkthrough then doubles as a UI test.

The library is the point. The demo app only exists to exercise it. No LLM is used. Flows are plain data, which leaves that door open later.

## The problem

Many clubs I've been part of use Notion as their central hub, but most students find it hard to navigate at first. Despite Notion's benefits, members often give up quickly, or clubs switch to alternatives with fewer features.

Notion's built-in connectors and AI help, but they don't teach you how to use the app. It also becomes tiresome to ask the AI for every task.

An in-app walkthrough platform teaches: it points at the real control and waits for the person to tap it. The usual problem is that walkthroughs rot. A button gets renamed, the tour points at nothing, and nobody notices until a user does.

GuideKit makes that rot a test failure.

**Assumption:** a multi-team org would use this. The idea is this renderer/single engine architecture is easy to implement by teams, all they need are tags and JSON and they can quickly spin up walk throughs and tutorials.

## Add a tutorial to your feature

A team does four small things.

1. Tag the control. The shared button already takes an optional ID:

```swift
AppButton("Save", guideID: "calendar.save") { ... }
```

2. Report any state a step needs to check:

```swift
.guideFact("calendar.event.count", value: store.events.count)
```

3. Add `Resources/flows/create_event.json` to the feature package:

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

Then declare the folder on the feature's target in `Package.swift`:

```swift
resources: [.copy("Resources/flows")]
```

It must be `.copy`. With `.process`, SwiftPM flattens the folder, GuideKit can't find `flows`, and the feature reports a load error.

4. Wrap registration in the feature package. The `prepare` closure shows the right screen before a flow starts:

```swift
public enum CalendarGuide {
    @MainActor
    public static func feature(prepare: @escaping @MainActor () -> Void) -> GuideFeature {
        GuideFeature(namespace: "calendar", bundle: .module, prepare: prepare)
    }
}
```

The app creates one controller from every team's feature, and one host at the root (`Demo/GuideDemo/GuideDemoApp.swift`):

```swift
_controller = State(initialValue: GuideController(features: [
    EditorGuide.feature(prepare: {
        shell.selectedTab = .editor
        shell.blocks.closeMenus()
    }),
    CalendarGuide.feature(prepare: { shell.selectedTab = .calendar }),
]))
```

```swift
AppShell(shell: shell)
    .guideHost(controller, launcherBottomClearance: 120)
```

That is the whole adoption. The `?` button opens a menu of every registered flow. `launcherBottomClearance` is optional (84 points by default); raise it if the button would cover your bottom controls. A `prepare` closure should also reset any transient UI, such as an open menu, so a walkthrough begins from a known state. See `Demo/Packages/CalendarFeature/` for the real files.

A step has a `target`, a `say` line, an optional `pick` (`first` or `last` when several views share an ID), and a `completeWhen` check. The checks are `targetVisible`, `fact` with `equals` or `increasedBy`, and `tapped`. Flow IDs must start with the feature's namespace, and the validator checks this at load.

| Calendar flow, step 1 | Step 2 |
| --- | --- |
| ![Step 1 highlights New event](docs/screenshots/calendar-create-event-step1.png) | ![Step 2 highlights Save](docs/screenshots/calendar-create-event-step2.png) |

The dim blocks taps outside the highlighted hole. Taps inside the hole reach the real control, so the user does the real action.

## Architecture

```
  Feature package                          App root
  ---------------                          --------
  flows/*.json  --> GuideFeature --+
  AppButton(guideID:)              +-->  GuideController --> GuideRuntime
  .guideFact(key, value:)  ------> |      (@Observable)      (state machine,
                                          ^        |          no UI imports)
  .guideHost(controller)                  |        v
     collects target frames ------------ +   SpotlightOverlay + menu

  GuideKitCore     Flow model, JSON decoding, FlowValidator, GuideRuntime. No UI.
  GuideKit         SwiftUI: guideTarget, guideFact, guideHost, overlay, menu.
  GuideKitTesting  FlowTestDriver for XCUITest.
```

- A flow is data. `GuideRuntime` is a plain state machine, so it is unit-tested without a simulator.
- `guideTarget` records a view's frame with an anchor preference and sets its accessibility identifier. The host collects the frames at the root.
- If a step's target is not rendered within 5 seconds (a fixed constant), the walkthrough fails and says which flow, step and target.
- `FlowTestDriver` reads `allFlowIDs` from the app's status element, launches the app once per flow, and lets the app's own runtime drive it. It taps each step's current target on the real screen and fails the test if a flow does not finish.

```swift
func testEveryRegisteredFlowCompletes() {
    FlowTestDriver(testCase: self).runAll()
}
```

A new flow is covered by this test as soon as its JSON file exists. It needs no new test code.

## How it was built

I built this with Claude Code, using a process where I made the product decisions and independent agents built and checked the work.

1. **I defined the problem and the solution.** The problem came from my club: people ask AI to do simple tasks in Notion and never learn how. I proposed a mode that walks you through a task on the real interface.
2. **I used skills to work out the architecture.** Brainstorming and planning skills turned the idea into a design, and I pushed back on it as we went. That is where we dropped the LLM, removed a per-team manifest, and moved tagging into shared components. The result was a plan of nine tasks, each with exact interfaces and tests.
3. **Subagents built and reviewed each task.** One agent implemented a task from its brief alone. A separate agent then reviewed the diff without that agent's context, so it had no attachment to the choices made and treated the implementer's report as unverified. Findings went back for a fix and a focused re-review before the next task started.
4. **A final reviewer read the whole branch.** Reviewing tasks one at a time misses problems between them.

The independent reviews caught bugs that the tests had not:

- A timer from one step could fail the next step.
- Status changes did not reach SwiftUI views.
- Switching tabs erased the user's content.
- The `?` button covered Calendar's Save button.
- The project failed to build from a renamed folder, such as a GitHub ZIP download.

## Documentation

Every public type and member carries `///` documentation, and a DocC catalog lives at `Sources/GuideKit/GuideKit.docc/` (a landing page and a Getting Started article built from the demo code). To build it in Xcode, open the package and choose Product > Build Documentation.

For how it works and why it is built this way, start at [`docs/tdd/README.md`](docs/tdd/README.md): one technical design doc per feature, with a mental model, a diagram and an end-to-end trace.


## Tradeoffs

**Tags in shared components, not accessibility lookup.** Targets are found by an explicit ID, set through the shared component. An accessibility lookup would need no tagging, but labels change with copy and localization, and a rename would silently retarget a step. An explicit ID is stable and greppable. The cost is that a team must use the shared component, or tag the view by hand.

**Tags, not server-driven UI.** The screens stay ordinary SwiftUI. Nothing about the UI is described remotely, so teams keep their normal workflow. The cost is that flows ship with the app and cannot be changed without a release.

**No manifest.** There is no central list of targets or flows. Each feature package carries its own `flows/` folder. This avoids a shared file that every team has to edit. The cost is that nothing checks IDs across teams. The only checks are the namespace rule and the UI test that runs every flow.
