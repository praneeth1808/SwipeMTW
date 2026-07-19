# Changelog

## v0.32

- Made For You strictly use selected interests.
- Made Random ignore interests and shuffle due cards from every topic.
- Made Surprise Me ignore filtering while starting outside selected interests when possible.
- Added Select All and Clear All interest controls with persisted empty selection.
- Added selected-topic counts, topic search for larger libraries, and mode-aware guidance.
- Added a dedicated empty-feed message when For You has no selected interests.

## v0.31

- Added native Markdown rendering for text stored directly in card JSON strings.
- Added block styling for headings, unordered and ordered lists, quotes, dividers, and fenced code.
- Added inline styling for bold, italic, links, and inline code.
- Applied compact Markdown rendering to feed cards, Card Library, Likes, Saved, and Research.
- Kept malformed Markdown readable through safe partial parsing and plain-text fallback.

## v0.30

- Added persisted New, Viewed, Understood, Needs Review, and Mastered learning states.
- Added an end-of-lesson understanding check with Review Again, Mostly Understood, and Mastered responses.
- Added spaced-repetition scheduling at approximately 1, 3–7, and 28 days based on understanding.
- Added a caught-up feed state with the next scheduled review date.
- Added a global Card Library with title search and topic, tag, status, action, reading-time, and sort filters.
- Added normalized topic-and-title duplicate detection before JSON import.
- Added Skip Duplicate Content, Import as Another Copy, Replace Existing Content, and Review Conflicts choices.
- Added learning-loop and reviews-due metrics to Learning Analytics.
- Migrated existing local JSON documents safely to schema version 5.

## v0.29

- Added persisted topic colors alongside each topic's selected symbol.
- Added a simple semantic color chooser that avoids used and visually close colors.
- Applied topic colors to feed artwork, lesson accents, and collection rows.
- Added on-device tracking for lesson opens, completed reads, lesson time, topic time, app time, and sessions.
- Added a Learning Analytics dashboard inside Settings with coverage, topic-focus charts, backlog, and career-development prompts.
- Added a confirmed Reset Statistics action that preserves cards, actions, ordering, and topic appearance.
- Migrated existing JSON files safely to schema version 4 with default analytics fields.

## v0.28

- Added dynamic artwork settings for every unique topic in the live JSON.
- Added about 120 categorized and searchable SF Symbol choices per topic.
- Persisted topic artwork selections in `SwipeMTWData.json` schema version 3.
- Applied selected artwork across the feed, lessons, and collection rows.
- Added live total-card and topic-category counts at the end of Settings.

## v0.27

- Ignored every uploaded card ID and generated new sequential collision-free IDs.
- Allowed repeated imports of the same file to append another complete batch.
- Remapped imported actions to generated IDs while retaining bottom-only collection ordering.
- Added a confirmed Clear All Cards & Actions operation.
- Kept an empty valid JSON document and functional Settings/import flow after clearing.

## v0.26

- Clarified that import has no 50-card limit and duplicate IDs are intentionally skipped.
- Added the resulting total library count to import results.
- Added actionable unique-ID examples when every imported card collides.

## v0.25

- Ignored imported collection-priority arrays so imports cannot reorder existing lists.
- Appended newly imported Like, Save, and Research IDs after every existing priority.
- Preserved the exact existing top order in Likes, Saved, and Research.

## v0.24

- Changed JSON import to strictly additive behavior.
- Skipped matching card IDs instead of replacing existing card content.
- Preserved all existing actions and collection priorities during every import.
- Merged imported progress and order only for genuinely new card IDs.
- Updated import results to report added and skipped counts clearly.

## v0.23

- Reloaded available interest options from the live JSON whenever Settings opens.
- Applied interest toggles directly to the active feed instead of relying only on indirect observation.
- Made For You, Random, and Surprise Me all respect selected-interest filtering.
- Kept imported and externally edited JSON topics synchronized with Settings choices.

## v0.22

- Changed For You from interest prioritization to strict selected-topic filtering.
- Kept the filter active across every repeated randomized feed cycle.
- Clarified that Random uses all topics and Surprise Me intentionally explores outside interests.

## v0.21

- Added Import & Merge JSON in Settings for full data documents and plain card arrays.
- Merged cards by stable ID while preserving all existing action progress and priorities.
- Refreshed topic-interest choices immediately after importing new topics.
- Changed the feed to continuous randomized cycles that repeat without reaching an end.
- Avoided immediate cycle-boundary duplicates when multiple cards are available.

## v0.20

- Added independently persisted priority ordering for Likes, Saved, and Research.
- Added Edit-mode drag reordering with list auto-scroll support.
- Kept Edit visible for every nonempty collection, including a one-card Saved list.
- Migrated schema-version 1 JSON documents to schema version 2 without losing cards or actions.
- Added direct JSON preview, sharing/export, and a selectable full path in Settings.
- Added in-app guidance for revealing the JSON's containing folder in Files.

## v0.19

- Added a versioned `SwipeMTWData.json` document in the app's Files-visible Documents directory.
- Seeded the document from bundled cards only when no existing file is present.
- Migrated legacy Like, Save, Research, Dislike, Show Again, and viewing progress on first creation.
- Moved all subsequent card-progress reads and atomic writes to the shared JSON document.
- Added the document location and filename to Settings.
- Enabled opening the app's local documents through the iOS Files provider.

## v0.18

- Added a Likes tab beside Saved using the shared collection layout.
- Kept Likes synchronized with Like and Dislike actions across feed and lesson views.
- Added full-lesson navigation and an empty state for liked cards.

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
