# iOS Technical Test

Build an iOS application in Swift that displays listings from the local API server included in this repository.

## What We Are Evaluating

This exercise is meant to show how you work on a small but realistic product slice:

- product judgment and scope management
- Swift and iOS fundamentals
- architecture and testability
- accessibility and UX quality
- your ability to spot ambiguity and make sensible decisions

Depth matters more than breadth. If you need to make tradeoffs, document them clearly.

## Deliverables

Your submission must include:

- a runnable iOS app on the `main` branch
- a `REFLECTION.md` file at the repository root
- a short note in `REFLECTION.md` describing any assumptions you made about the API or prompt

## Review Process

Shortlisted submissions are followed by a 60-minute debrief.

In that conversation, we will ask you to explain your tradeoffs, walk through implementation choices in more detail, and describe how you would handle one small follow-up change.

## Getting Started

A local API server is included in the `server/` directory. Start it before running the iOS app:

```bash
cd server
swift run
```

The server runs on `http://localhost:8080`.

### Reference Runtime

The reference environment for the core assignment is iPhone in the iOS Simulator.

Using `localhost` works directly in the simulator because it shares the host machine loopback interface. If you want to run your app on a physical device, you may make the base URL configurable, but device support is not required for evaluation.

> The `server/` directory is part of the test fixture and must not be modified in your submission.

### HTTP and App Transport Security

The starter project already includes the `NSAllowsLocalNetworking` App Transport Security exception required to call the local HTTP server from the simulator.

You do not need to edit `Info.plist` for the default setup. If you choose to change how the app connects to the server, update the configuration accordingly.

## API Overview

Available endpoints:

- `GET /listings` — listing feed envelope with `items`, `total`, `page`, `limit`, `has_more`
- `GET /categories` — listing categories
- `GET /listings?page=1&limit=20` — paginated listings
- `GET /listings?query=<term>` — search listings

The full API contract is available in `server/swagger.yaml`.

Image URLs in the response are server-relative paths (e.g. `/images/ad-small/...`). Prepend the server base URL to construct a full URL.

`GET /listings` always returns the same JSON shape, whether you use pagination or not.

The feed is already returned by the API in display order: urgent items first, then newest first.

## Core Requirements

### List Screen

- Display a list of listings
- Each item must show: image, category, title, price, and an urgent indicator when applicable
- The UI should preserve the order returned by the API
- A category filter must be available
- Missing images and failed image loads must be handled gracefully

### Detail Screen

- Tapping a listing opens a detail view
- The detail view should present the information returned by the API in a way that feels complete and readable

### Required Product Quality

- Loading states are visible
- Error states are visible and recoverable
- Empty states are intentional

## Accessibility

At a minimum:

- interactive elements have meaningful accessibility labels
- images are labelled or marked decorative
- Dynamic Type is respected

## Testing Expectations

Include a small but non-trivial set of automated tests — aim for at least three to five cases that each cover a distinct, meaningful behaviour.

Good examples include filtering, decoding, request building, API/client behavior, or view model state changes.

We care more about choosing a few valuable cases than maximizing coverage. A single smoke test is not enough; exhaustive coverage is not expected.

Tests should be deterministic and should not require the local server to be running.

## Technical Constraints

- Language: Swift
- UI: SwiftUI preferred
- UIKit is acceptable, but if you choose UIKit we expect awareness of SwiftUI/UIKit interoperability
- No storyboards or `.xib` files
- No external libraries in the iOS app
- Deployment target: iOS 16+
- Required runtime: iPhone in the iOS Simulator
- Git history should show meaningful progress, not a single dump commit

## AI Usage

The use of AI tools is allowed.

Your `REFLECTION.md` must cover:

- which tools you used and for what
- at least one concrete AI suggestion you rejected, corrected, or rewrote
- the architectural decisions you owned yourself
- any ambiguity you found in the prompt or API and how you handled it

We are evaluating judgment, not just output.

## Optional Bonus Work

Bonus work is fully optional.

A submission can be strong without any bonus work if the core requirements are implemented well.

If you choose to do bonus work, pick at most one option. We care more about one well-executed extension than extra scope.

### Pagination

- load incrementally with the paginated endpoint
- avoid duplicates across pages
- handle loading, error, and retry states

### Search

- implement real-time search
- debounce user input
- cancel in-flight requests when the query changes
- handle empty and error states

### Draft a Classified Ad

- create a local draft for a new classified ad
- persist the draft across app relaunches
- restore the last in-progress draft when the app reopens
- allow the draft to be discarded or reset
- no backend call is required for this option

### iPad Support

- adapt the experience so it feels intentional on iPad, not just stretched from iPhone
- revisit layout, navigation, and spacing where needed
- preserve loading, error, and empty states on iPad as well

## Review Notes

If you notice something imperfect in the starter package, do not freeze. State your assumption, choose a sensible direction, and keep moving.

Good luck.
