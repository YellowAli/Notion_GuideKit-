# ``GuideKit``

Walkthroughs that point at real controls and double as UI tests.

## Overview

GuideKit shows an in-app walkthrough as a dimmed screen with a spotlight on the control the person should use next, and a tooltip that says what to do. Each step finishes when the app itself proves the person did it (a target appeared, a fact changed, or the target was tapped), not when a timer runs out.

A flow is plain JSON owned by the team that owns the screen. Because the runtime verifies every step against the live UI, the same flows can be driven by `FlowTestDriver` as XCUITests: a renamed button or a removed screen turns into a test failure that names the flow, the step and the target.

The SwiftUI layer adds three `View` modifiers (they are extensions, so they have no pages of their own): `guideTarget(_:)` tags a control, `guideFact(_:value:)` reports app state, and `guideHost(_:launcherBottomClearance:)` hosts the walkthrough UI once at the root. <doc:GettingStarted> shows each one.

The package ships three libraries:

- `GuideKitCore` is the flow model, the validator and the ``GuideRuntime`` state machine. It imports no UI framework.
- `GuideKit` is the SwiftUI layer: the modifiers, ``GuideController``, ``GuideFeature`` and the overlay.
- `GuideKitTesting` is `FlowTestDriver` for UI test targets.

To run flows as UI tests, add the `GuideKitTesting` library to a UI test target and use its `FlowTestDriver`.

New to the library? Start with <doc:GettingStarted>.

## Topics

### Essentials

- <doc:GettingStarted>

### Tag the UI

- ``GuideFactConvertible``

### Describe a walkthrough

- ``Flow``
- ``Step``
- ``Pick``
- ``Check``
- ``FactValue``
- ``FlowValidator``
- ``FlowValidationError``

### Register and host walkthroughs

- ``GuideFeature``
- ``GuideController``

### Observe progress

- ``GuidePresentation``
- ``GuideStatus``

### Drive the state machine directly

- ``GuideRuntime``
- ``GuideState``
- ``GuideEvent``
- ``GuideEffect``
- ``GuideFailure``
