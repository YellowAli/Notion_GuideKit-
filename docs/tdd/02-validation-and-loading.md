# 02 Validation and loading

## Purpose

Get flows from a feature's bundle into the app, rejecting structural mistakes early and loudly.

## Where it lives

- `Sources/GuideKitCore/Validation/FlowValidator.swift` (`FlowValidator`, `FlowValidationError`)
- `Sources/GuideKit/Registration/GuideFeature.swift`

## How it works

1. `GuideFeature(namespace:bundle:prepare:)` lists `*.json` in the bundle's `flows` subdirectory, sorted by path.
2. Each file is decoded to a `Flow`, then checked with `FlowValidator.validate([flow], namespace:)`.
3. A file that fails to decode or validate adds a message to `loadErrors` and contributes no flow. A second file reusing an already-loaded flow ID is also an error.
4. Loaded flows are sorted by ID. If there are errors, the initializer calls `assertionFailure` (debug builds only) with all messages.
5. `prepare` is kept to run before any of this feature's flows start.

`FlowValidator` returns all problems, not just the first: empty flow, malformed or duplicate flow ID, flow ID outside the namespace, empty `say`, malformed target or fact ID, and an increment of zero or less.

## Key decisions and why

- **Structure only.** The validator cannot know which targets exist. A misspelled target surfaces as a named runtime failure, such as target `calendar.new_evnt` not found, and the UI test catches it. Rejected: a per-team manifest listing every ID. Cost: one more file to keep in sync per team, which the user declined.
- **Namespaces on flow IDs only.** Targets and facts may belong to other teams, so only flow IDs must start with the feature's namespace.
- **`.copy`, not `.process`.** `.process` flattens the folder, so `flows` is not found. The missing-folder case is reported as a load error that tells the author to use `resources: [.copy("Resources/flows")]`.
- **Fail the build visibly in debug, survive in release.** Release builds keep the flows that did load.

## Edge cases and limits

- An empty `flows` folder or no folder: one load error, no flows.
- IDs must match `^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$`. A trailing-newline quirk of this pattern is a known deferred minor.
- `GuideController` takes the first feature's flow when two register the same ID.

## Tests

`Tests/GuideKitCoreTests/Validation/FlowValidatorTests.swift` (each error class, all errors reported, one-based step text). Load behavior is covered in `Tests/GuideKitTests/Controller/GuideControllerTests.swift` (valid flows kept when another file is malformed, duplicate IDs, missing folder).
