# 04 Controller and modifiers

## Purpose

Connect SwiftUI to the runtime: turn view frames, facts and taps into events, and turn effects into something to show.

## Where it lives

- `Sources/GuideKit/Controller/`: `GuideController.swift`, `GuidePresentation.swift`, `GuideStatus.swift`
- `Sources/GuideKit/Modifiers/`: `GuideTarget.swift`, `GuideFact.swift`, `GuideFactConvertible.swift`, `GuideControllerEnvironment.swift`, `GuideHost.swift`
- `Sources/GuideKit/Testing/`: `GuideTestEnvironment.swift`, `GuideStatusElement.swift`

## How it works

**Tagging.** `.guideTarget(id)` publishes the view's bounds as an anchor preference (`GuideTargetKey`, which appends in tree order so `pick: last` means last in layout order), sets the accessibility identifier, and reports taps with a simultaneous gesture. `nil` leaves the view unchanged.

**Facts.** `.guideFact(key, value:)` reports on appear, on change and forgets on disappear.

**Host.** `.guideHost(controller, launcherBottomClearance:)` puts the controller in the environment and uses `overlayPreferenceValue` to receive all anchors. Inside a `GeometryReader` it resolves them to rects, calls `controller.updateTargets` whenever they change, and draws `SpotlightOverlay` and `GuideMenu`.

**Controller.** `GuideController` (main actor, `@Observable`) keeps frames and facts and a `GuideRuntime`. `send(_:)` passes an event to the runtime, performs each effect (`present` sets `presentation`; `dismiss` clears it and cancels timer tasks; `scheduleTimeout` starts a task that sleeps `defaultTimeout`, five seconds, then sends `.timeout(token:)`), then recomputes `status`. `start(flowID:)` ignores unknown IDs and does nothing while a flow is running; otherwise it calls the feature's `prepare` and sends `.start`. A target with no frames counts as absent.

**Test hooks.** With `GUIDEKIT_TEST=1` the host adds `GuideStatusElement`, which exposes `GuideStatus` as JSON. `GUIDEKIT_TEST_FLOW=<id>` starts that flow on first appear.

## Key decisions and why

- **Views register themselves; GuideKit never searches.** Rejected: looking elements up through the accessibility tree. Labels can be translated, duplicated or vague, and reading the tree in-process is unverified. Cost: views must be tagged.
- **Tags over server-driven UI.** Incrementally adoptable in an existing app, and the device owns the real state anyway.
- **`guideHost` takes a `GuideController`.** Rejected: `guideHost(features:)`. The app owns the controller, which tests and the shell can share.
- **Injectable `sleep`.** Unit tests replace `Task.sleep`, so timeout tests are instant.
- **Overlay on the root, in one coordinate space.** One host means no per-screen setup.

## Edge cases and limits

- **Same-key swap.** `forgetFact` runs when a reporting view disappears. If two views swap under one key, the outgoing disappear can remove the fact the incoming view reported, and it stays dropped until the next change. Known, deferred.
- Targets inside system sheets and popovers present above the root overlay and are not found. Demo menus are in-hierarchy for this reason. A per-presentation host is the future path.
- Off-screen or unrendered lazy rows have no frame; `.guideScrollContainer()` was deferred, so an off-screen target shows an unreachable hole (Exit still works).
- `guideFact` ignores key changes on the same view.
- `GUIDEKIT_TEST_FLOW` is not gated on `GUIDEKIT_TEST` (deferred minor).

## Tests

`Tests/GuideKitTests/Controller/GuideControllerTests.swift`: features and duplicates, `prepare` ordering, `pick`, frame clearing, injected-sleep timeout, status, observability, stale facts.
