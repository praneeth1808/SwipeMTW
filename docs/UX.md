# SwipeMTW UX Direction

## Feed

The feed uses a familiar, content-first vertical layout:

- A compact header preserves space for learning.
- Optional topic artwork occupies a small upper banner and fades into the content surface.
- The default appearance is mostly white with dark, accessible text.
- If artwork is absent, a subtle topic-colored pattern fills the banner.
- Topic, title, summary, key idea, and example carry more visual weight than artwork.
- The entire lesson surface opens the full lesson; there is no dedicated open button.
- Like, Save, Research, Show Again, and Dislike appear as separate controls on the right.
- Feed, Likes, Saved, Research, and Settings form the primary navigation.

## Current Step 2 Scope

Step 2 renders one static sample card. Feed navigation, gestures, actions, JSON loading, and persistence are intentionally deferred to their roadmap steps.

## Step 4 Feed Scope

- The feed owns every locally loaded card and displays one current card.
- Card position and total count remain hidden to preserve a continuous feed experience.
- Missing artwork uses the default topic treatment without leaving empty space.
- Card-changing gestures, detail navigation, and card actions remain inactive until their roadmap steps.

## Step 5 Swipe Scope

- Swipe up advances to the next card.
- Swipe down returns to the previous card.
- Short or mostly horizontal drags do not change cards.
- The first and last cards resist movement beyond the available feed.
- The current and neighboring cards move together as a vertical carousel.
- Sample topics use distinct semantic accents while preserving the same layout.
- Feed previews remain concise so internal scrolling does not compete with card navigation.
- The complete lesson remains available to the future detail view.

## Step 6 Lesson Detail Scope

- Tapping anywhere on the visible Feed Card opens the Lesson Detail.
- A drag continues to navigate the carousel without opening the lesson.
- The detail displays the complete lesson, Key Idea, Example, duration, and tags.
- A close control returns to the same Feed Card.
- Learning Actions remain deferred to their individual roadmap steps.

## Steps 7–11 Learning Actions

- Like, Save, Research, Show Again, and Dislike form the vertical Learning Action Rail.
- Action buttons remain separate from tap-to-open and card swiping.
- Like and Dislike are mutually exclusive.
- Save, Research, and Show Again toggle independently.
- Research marks content for the future Research screen without making a network request.
- Show Again records resurfacing intent without immediately reordering the feed.
- Step 12 persists selected states locally across launches.

## Steps 12–15 Library and Preferences

- Card actions, view counts, and last-viewed dates persist locally across launches.
- Likes, Saved, and Research tabs update from the shared card progress state.
- Selecting a collection row opens the complete Lesson Detail.
- Settings provides System, Light, and Dark appearance modes.
- Feed modes include For You, Random, and Surprise Me.
- Every feed mode strictly filters to selected interests.
- For You and Random reshuffle matching cards; Surprise Me chooses a random matching card first.
- Surprise Me starts with a topic outside selected interests when possible.
- A compact header menu changes feed mode or opens interests without occupying a large top area.

## Steps 16–17 Motion and Final Polish

- The current and neighboring cards subtly scale as they move through the vertical carousel.
- Learning actions use a short spring response when their selected state changes.
- The feed options control is anchored to the top-right edge with a full 44-point touch target.
- Opening a lesson reveals a persistent bottom action bar with the same state as the feed rail.
- Feed content begins at the top rather than being vertically centered by the action rail.
- Default and interest-prioritized feeds avoid presenting cards in source-file order.

## Step 18 Local Data File

- SwipeMTW creates one user-visible JSON document when none exists.
- Existing documents remain authoritative across later launches and app upgrades.
- Card content and all per-card learning actions share the same document.
- The Settings screen identifies the Files app location and filename.
- Invalid or unsupported documents show an error instead of being silently overwritten.

## Step 19 Collection Priorities and File Access

- Likes, Saved, and Research each provide standard Edit-mode drag reordering.
- Holding a reorder handle near an edge scrolls longer lists while dragging.
- Each collection order persists independently in `SwipeMTWData.json`.
- Settings can preview the live JSON, share or save a copy, and display a selectable full system path.

## Step 20 Import and Continuous Feed

- Settings imports and merges a full SwipeMTW document or a plain card-array JSON file.
- Imported cards with new IDs append; matching IDs are skipped without modifying existing content or actions.
- Imported action cards always appear at the bottom of Likes, Saved, and Research without changing existing top priorities.
- Newly imported topics appear in Interests immediately.
- The feed shuffles a fresh cycle before reaching its last card and repeats indefinitely.
- A new cycle avoids repeating the same card at the boundary when multiple cards exist.
- A bounded buffer preserves recent backward navigation without unbounded memory growth.
