# 07 Test driver

## Purpose

Run every registered walkthrough as an automated UI test, so a stale flow fails CI.

## Where it lives

`Sources/GuideKitTesting/FlowTestDriver.swift` (iOS only), the status element in `Sources/GuideKit/GuideStatus.swift`, `GuideStatus` in the same file, and the app's tests in `Demo/GuideDemoUITests/AllFlowsUITests.swift`.

## How it works

1. `launch` starts the app with `GUIDEKIT_TEST=1` (the host then exposes the `guidekit.status` element) and, for a run, `GUIDEKIT_TEST_FLOW=<id>`.
2. `allFlowIDs()` launches once and reads `allFlowIDs` from the status JSON; `runAll()` fails if there are none.
3. `drive(flowID:)` loops on the decoded `GuideStatus`:
   - `waiting`: find the element whose accessibility ID is `target` (the last match for `pick: last`), attach a screenshot, tap its center, then wait for the status to change.
   - `completed`: attach a final screenshot and return.
   - `failed`: fail the test with the runtime's message, which names flow, step and target.
4. The app's own runtime decides whether a tap completed the step; the driver never judges it.

## Key decisions and why

- **Drive the real runtime** instead of re-implementing checks in the test. Rejected: a second evaluator in the test target. Cost: duplicated rules that drift apart.
- **Status as an accessibility element carrying JSON**, readable from the UI test process. Rejected: shared files or a socket. They need extra setup in the app.
- **One launch per flow** so each starts from a known state.
- **Waiting on a changed status string** is equivalent to waiting on a step or state change, because `GuideStatus` changes only on those transitions.
- **Regression demo.** Renaming a guide ID made `editor.add_heading` and `editor.add_todo` fail with their step and target while other flows still passed.

## Edge cases and limits

- Only taps are driven; there are no text-entry steps.
- `pick: last` with several matching views is unit-tested but has no UI test.
- A tap can land while a frame is still settling (deferred).
- Failures name the first problem only, because the walkthrough exits when it fails.

## Tests

`Demo/GuideDemoUITests/AllFlowsUITests.swift` (8 tests): `testEveryRegisteredFlowCompletes` (all 5 flows), blocked outside taps, Exit, menu start, New event then Save without a walkthrough, block survives tab switching, and two tests that start a flow with a menu already open.
