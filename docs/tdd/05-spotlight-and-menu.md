# 05 Spotlight and menu

## Purpose

Show the person where to act: dim everything except the target, explain the step, and offer a way to start and to quit.

## Where it lives

`Sources/GuideKit/Overlay/SpotlightOverlay.swift`, `Sources/GuideKit/Overlay/TooltipPlacement.swift`, `Sources/GuideKit/Menu/GuideMenu.swift`.

## How it works

**Spotlight.** While `controller.presentation` is non-nil it draws a dark `Path` with an even-odd rounded cutout at the target frame (padded), a pulsing ring (a still ring under Reduce Motion), and a tooltip card. The dim uses `.contentShape(path, eoFill: true)`, so it takes every tap except those in the hole; taps in the hole reach the real control, and taps elsewhere shake the card. The card shows "Step n of m", the `say` text and an Exit button that calls `controller.cancel()`. Each new step is announced to VoiceOver.

**Placement.** `TooltipPlacement.compute` picks the side of the hole with more room inside the safe area. If that side is shorter than `minimumHeight` it grows over the hole, because a reachable Exit matters more than an unobstructed target. With no hole it uses the whole safe area.

**Menu.** `GuideMenu` shows a `?` button (hidden while a flow is active) that opens a panel with "Walk me through: <title>" for each flow, calling `controller.start(flowID:)`. If the status becomes `failed`, a card says the walkthrough could not continue, with an OK button. The detailed reason is printed in debug builds and stays in `status`.

## Key decisions and why

- **Block outside taps.** The user chose that only the highlighted control responds. Cost: no off-script recovery, so a failure ends the guide.
- **Exit is always reachable.** Hence the minimum card height and the fact the card may overlap the hole on very short screens.
- **Dim hidden from accessibility; UI tests tap coordinates.** A dim layer should not be a VoiceOver stop.
- **Placement is pure geometry** so it is unit-tested without a simulator.
- **Launcher clearance is a `guideHost` parameter**, default 84 points. Rejected: moving the launcher. Cost if wrong: the launcher may need to move.

## Edge cases and limits

- Rotation tracking is unverified.
- The `?` can overlap the trailing end of the lowest open block-menu rows (deferred).
- VoiceOver can still reach controls behind the dim (deferred).
- The menu panel does not scroll with many flows.

## Tests

`Tests/GuideKitTests/Overlay/TooltipPlacementTests.swift` (8 placement cases). UI tests in `Demo/GuideDemoUITests/AllFlowsUITests.swift`: `testTapOutsideHoleIsBlocked`, `testExitEndsWalkthrough`, `testMenuStartsWalkthrough`.
