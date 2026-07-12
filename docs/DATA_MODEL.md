# SwipeMTW Data Model

## LearningCard

- `id`: Stable card identifier.
- `topic`: Primary learning category.
- `title`: Card headline.
- `summary`: Short feed description.
- `keyIdea`: Useful takeaway displayed directly in the feed.
- `example`: Optional concise example displayed in the feed.
- `content`: Complete lesson content for the future detail view.
- `estimatedMinutes`: Estimated lesson duration.
- `tags`: Search and discovery terms.
- `artworkName`: Optional bundled artwork asset name.

When `artworkName` is absent, the feed uses its default topic artwork treatment.

Typography, font sizes, spacing, and animation values are presentation concerns and remain in SwiftUI. User-selected topic theme colors are stored separately from card content.

## UserProgress

- `cardID`: Learning card associated with the progress.
- `liked`: Whether Like is selected.
- `saved`: Whether Save is selected.
- `disliked`: Whether Dislike is selected.
- `research`: Whether the card is marked for later research.
- `showAgain`: Whether the card is marked to resurface later.
- `viewCount`: Number of times the card has become current in the feed.
- `lastViewed`: Most recent date the card became current.
- `openCount`: Number of times the complete lesson was opened.
- `completedReadCount`: Number of lesson visits that reached a useful reading-time threshold.
- `totalReadSeconds`: Accumulated time spent in the complete lesson.
- `lastOpened`: Most recent date the complete lesson was opened.
- `learningStatus`: One of `new`, `viewed`, `understood`, `needsReview`, or `mastered`.
- `lastAssessment`: Most recent understanding response.
- `nextReviewDate`: Date when spaced repetition makes the card eligible for the feed again.

## SwipeMTWData.json

The app's durable learning data lives in one versioned JSON document:

- `schemaVersion`: Data-file format version used for safe future migrations.
- `cards`: Complete learning-card content loaded by the feed.
- `progress`: A dictionary keyed by card ID containing Like, Save, Research, Dislike, Show Again, and viewing state.
- `collectionOrder`: Independent ordered card-ID lists for Likes, Saved, and Research.
- `topicSymbols`: User-selected SF Symbol artwork keyed by the exact JSON topic name.
- `topicColors`: User-selected or automatically assigned hex theme color keyed by topic name.
- `analytics`: On-device totals for app time, session count, and learning time by topic.

On first launch, SwipeMTW creates `SwipeMTWData.json` in its Documents directory using the bundled cards and any progress previously stored in `UserDefaults`. On later launches, the existing document is loaded and is never replaced by bundled content.

Every progress change reads the current document, updates `progress`, and atomically writes the same file. This keeps Saved, Likes, and Research state alongside the learning content.

Reordering Likes, Saved, or Research updates only that collection's ID list, so each page can have a different learning priority.

The Settings importer accepts either a complete `SwipeMTWData.json` document or a plain JSON array of `LearningCard` objects. Content duplicates are detected using normalized topic plus normalized title before any write. The default skips duplicate content; users may instead import another copy, replace existing content while preserving its ID and actions, or review conflicts first.

For newly added cards, every uploaded ID is ignored. Cards receive sequential collision-free IDs beginning after the highest existing numeric ID and append to the library. A full data document's actions are remapped to the assigned IDs, while its priority order is ignored; new action IDs always append after the existing Likes, Saved, and Research order.

Clearing the library writes a valid empty document containing no cards, progress, or collection priorities. The app remains usable so a fresh JSON file can be imported immediately or after relaunching.

Topic appearance choices are independent of card IDs. One symbol and color apply consistently to every card sharing that topic and remain available across launches. New topics receive a stable, semantic starting color that avoids colors already assigned to nearby categories.

Analytics remains in the same local JSON file. It includes learning behavior generated inside SwipeMTW; no analytics data is sent to a server.

With local file sharing enabled, the document is available in Files under **On My iPhone → SwipeMTW → SwipeMTWData.json**.
