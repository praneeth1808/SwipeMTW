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
- Feed, Saved, and Settings form the primary navigation.

## Current Step 2 Scope

Step 2 renders one static sample card. Feed navigation, gestures, actions, JSON loading, and persistence are intentionally deferred to their roadmap steps.

## Step 4 Feed Scope

- The feed owns every locally loaded card and displays one current card.
- A position indicator communicates the current card and total card count.
- Missing artwork uses the default topic treatment without leaving empty space.
- Card-changing gestures, detail navigation, and card actions remain inactive until their roadmap steps.
