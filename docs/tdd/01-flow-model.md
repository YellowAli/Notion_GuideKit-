# 01 Flow model

## Purpose

Define a walkthrough as plain, serializable data: what to point at, what to say, and how to know the person did it.

## Where it lives

`Sources/GuideKitCore/Flow.swift` holds `Flow`, `Step`, `Pick`, `Check`, and `FactValue`.

## How it works

- A `Flow` has an `id`, a `title` (the menu text) and ordered `steps`.
- A `Step` has a `target` (a guide ID), a `say` line, an optional `pick` (default `first`) and one `completeWhen` `Check`.
- A `Check` is one of `targetVisible`, `factEquals`, `factIncreased` or `tapped`. In JSON each is a distinct object shape (`{"targetVisible": ...}`, `{"fact": ..., "equals": ...}`, `{"fact": ..., "increasedBy": ...}`, `{"tapped": true}`), decoded by hand in `Check.init(from:)`.
- A `FactValue` is a bool, integer or string. It decodes by trying those types in that order.
- `Pick` chooses between several views sharing one ID, in tree order.

## Key decisions and why

- **Check on the result, not the tap.** Prefer `targetVisible` and facts; `tapped` is the weakest proof and exists for taps with no observable effect. Rejected: completing every step on tap. Cost: a tap that does nothing would advance the tour past a broken screen.
- **Flows are JSON data.** Teams edit a file and need no Swift. This also keeps the format open for tooling later. Rejected: flows as Swift code. Cost: no compile-time checking, which `FlowValidator` and the UI test replace.
- **No `instance:` for repeated targets; use `pick`.** Rejected: indexed instances. Cost if wrong: a small API addition later.
- **Tap-only steps.** Text entry is a non-goal for now.

## Edge cases and limits

- An unknown check shape, or a `fact` with neither `equals` nor `increasedBy`, fails decoding.
- A non-integer number fails to decode as a `FactValue`.
- `Step.pick` is omitted from JSON when absent and defaults to `first`.

## Tests

`Tests/GuideKitCoreTests/FlowDecodingTests.swift`: all four checks decode, `pick` defaults to `first`, unknown check throws, round trip.
