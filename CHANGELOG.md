# Changelog

## v0.17

- Randomized cards within the For You interest groups instead of preserving JSON order.
- Moved the compact feed options control to the true top-right edge.
- Added synchronized learning actions to the bottom of the opened lesson.
- Added subtle carousel depth and spring feedback for selected actions.
- Completed final spacing, touch-target, accessibility, and documentation polish.

## v0.15

- Persisted per-card actions, view counts, and last-viewed dates locally.
- Added shared Feed, Saved, Research, and Settings tabs.
- Added persistent appearance, feed mode, and topic-interest preferences.
- Added compact feed options for For You, Random, and Surprise Me.
- Stabilized Xcode executable previews by avoiding recursive multi-card style rendering.
- Removed a Swift concurrency warning from progress-store initialization.
- Top-aligned the feed card so its header no longer leaves a large blank area above it.

## v0.11

- Added the vertical Learning Action Rail.
- Added mutually exclusive Like and Dislike actions.
- Added independent Save, Research, and Show Again actions.
- Added immediate per-card selected states held in memory until persistence is implemented.

## v0.6

- Added tap-to-open navigation from the feed to a full lesson.
- Added complete lesson content, full examples, tags, and reading metadata to the detail view.
- Extracted reusable topic artwork and theme presentation.

## v0.5

- Added vertical swipe navigation between loaded learning cards.
- Added gesture thresholds and first/last-card boundary resistance.
- Added a moving vertical carousel transition between neighboring cards.
- Added distinct default accents and symbols for the sample topics.
- Removed visible card numbering for a continuous feed experience.
- Limited feed previews so full lesson content remains reserved for the detail view.

## v0.4

- Added a dedicated feed view and feed view model.
- Connected all loaded cards to feed state while displaying the current card.
- Added a default artwork treatment and card-position indicator.
- Expanded the first card as a long-content fixture for feed layout and scrolling review.

## v0.3

- Added three bundled learning cards in `cards.json`.
- Added an offline JSON card loader with readable failure states.
- Connected the static sample presentation to locally loaded data.
- Expanded card content with a key idea, optional example, reading time, tags, and optional artwork name.

## v0.2

- Added the `LearningCard` model.
- Added a sample partition-pruning card.
- Replaced the starter screen with a static sample-card presentation.

## v0.1

- Initial SwiftUI project.
