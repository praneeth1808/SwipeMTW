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
- For You strictly filters to selected interests.
- Random ignores interests and reshuffles due cards from every topic.
- Surprise Me uses every topic and starts outside selected interests when possible.
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
- Every imported card appends with a newly generated sequential ID; uploaded IDs never replace or block content.
- Imported action cards always appear at the bottom of Likes, Saved, and Research without changing existing top priorities.
- Import has no card-count limit; the result shows the assigned ID range and total library size.
- Settings provides a confirmed Clear All Cards & Actions operation while keeping an empty JSON ready for import.
- Newly imported topics appear in Interests immediately.
- The feed shuffles a fresh cycle before reaching its last card and repeats indefinitely.
- A new cycle avoids repeating the same card at the boundary when multiple cards exist.
- A bounded buffer preserves recent backward navigation without unbounded memory growth.

## Step 27 Topic Artwork and Library Summary

- Settings generates one artwork row for every unique topic in the live JSON.
- Every topic can choose from about 120 categorized and searchable SF Symbols.
- A selected topic symbol updates feed banners, opened lessons, and collection rows.
- Artwork selections persist in `SwipeMTWData.json` by topic name.
- The final Settings section shows the live total card count and topic-category count.

## Step 28 Topic Themes and Learning Analytics

- Each live JSON topic can choose both an SF Symbol and a theme color.
- Automatic colors begin from familiar topic families (for example, learning uses violet, data uses blue, and engineering uses teal), then select an unused sufficiently distinct alternative when needed.
- The topic color consistently controls its logo, top artwork treatment, labels, lesson blocks, and collection-row accents.
- Learning Analytics opens from Settings so Feed, Likes, Saved, Research, and Settings remain the five direct tabs.
- The dashboard emphasizes actionable learning signals: unique cards visited, lessons opened/read, library coverage, lesson time, total app time, topic focus, and unread learning backlog.
- Career Signals identify the strongest focus area, the least-covered topic, and the next useful queue action rather than adding decorative vanity metrics.
- Analytics is stored only in the user's local `SwipeMTWData.json` file.
- A confirmed Reset Statistics action clears visits, reads, and timing while preserving cards, learning actions, collection priorities, symbols, and colors.

## Step 29 Learning System and Scalable Library

- Every card progresses through New, Viewed, Understood, Needs Review, and Mastered states.
- The lesson ends with one understanding choice: Review Again, Mostly Understood, or Mastered.
- Review Again returns in about one day; Mostly Understood returns in about three days and then seven days; Mastered returns in about 28 days.
- Scheduled future cards stay out of the feed until due. When nothing is due, the feed shows the next review time.
- Card Library opens from Settings and searches titles, summaries, and tags across the full library.
- Filters cover topic, tag, learning status, action, reading time, newest, least/most viewed, and recently opened.
- Imports detect content duplicates using normalized topic plus title before changing the local file.
- Skip Duplicate Content is the safe default. Import as Another Copy, Replace Existing Content, and Review Conflicts remain explicit alternatives.

## Step 30 Markdown Card Content

- JSON strings render Markdown directly; content authors do not manage separate Markdown files.
- Opened lessons display a clear hierarchy for headings, paragraphs, lists, quotes, dividers, links, and code blocks.
- Bold, italic, and inline code remain visible in both lessons and compact feed previews.
- Feed and collection rows remove block markers such as `##` while retaining their readable text.
- Invalid or incomplete Markdown falls back to partially parsed or plain text instead of hiding content.

## Step 31 Feed Modes and Interest Controls

- For You is the focused mode and pauses with clear guidance when no interests are selected.
- Random and Surprise Me remain usable with zero selected interests because both use every topic.
- Interests provide Select All and Clear All shortcuts plus a live selected-count summary.
- Libraries with more than eight topics show topic search; an empty search result gets an explicit message.
- Mode descriptions and interest footers explain immediately whether the current mode uses the saved interest choices.
