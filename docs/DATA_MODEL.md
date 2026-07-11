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

Typography, font sizes, raw colors, spacing, and animation values are presentation concerns and remain in SwiftUI rather than card JSON.

## UserProgress

- `cardID`: Learning card associated with the progress.
- `liked`: Whether Like is selected.
- `saved`: Whether Save is selected.
- `disliked`: Whether Dislike is selected.
- `research`: Whether the card is marked for later research.
- `showAgain`: Whether the card is marked to resurface later.
- `viewCount`: Number of times the card has become current in the feed.
- `lastViewed`: Most recent date the card became current.

Progress is encoded locally in `UserDefaults` and restored when the app launches.
