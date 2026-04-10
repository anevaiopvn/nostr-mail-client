# NIP-XX

## Avatar Derivation

`draft` `standard` `ui`

## Abstract

This NIP standardizes a deterministic method for deriving avatar from a user's pubkey.
This ensures consistent visual identity across all Nostr clients.

## Motivation

Currently, Nostr clients generate avatar colors inconsistently. Some use platform-dependent hash
functions, leading to the same pubkey displaying different colors on different clients. Others
use varying algorithms or color palettes, fragmenting the user experience.

Standardizing avatar color derivation:
- Ensures **consistent identity** across clients
- Provides **predictable, reproducible** colors
- Allows clients to display avatars before fetching metadata

## Algorithm

### Step 1: Derive an Index

Given a 64-character lowercase hex pubkey:

1. Extract the **6 characters starting at index 29** (the middle of the pubkey)
2. Parse this substring as a base-16 (hex) integer
3. Compute the index as `parsed_value MODULO palette_length`

### Step 2: Select a Color

Use the derived index to select a color from a **standardized palette** of harmonious colors.

### Reference Palette

The following 20-color palette is designed to provide visually distinct, accessible colors that
work well on both light and dark backgrounds. Each color has a predefined text color chosen for
optimal contrast:

| Index | Hex       | Preview          | Text Color |
|-------|-----------|------------------|------------|
| 0     | `#7C3AED` | Purple (Nostr)   | `#FFFFFF`  |
| 1     | `#6366F1` | Indigo           | `#FFFFFF`  |
| 2     | `#3B82F6` | Blue             | `#FFFFFF`  |
| 3     | `#0EA5E9` | Sky              | `#FFFFFF`  |
| 4     | `#06B6D4` | Cyan             | `rgba(0,0,0,0.87)` |
| 5     | `#14B8A6` | Teal             | `rgba(0,0,0,0.87)` |
| 6     | `#10B981` | Emerald          | `rgba(0,0,0,0.87)` |
| 7     | `#22C55E` | Green            | `rgba(0,0,0,0.87)` |
| 8     | `#84CC16` | Lime             | `rgba(0,0,0,0.87)` |
| 9     | `#EAB308` | Yellow           | `rgba(0,0,0,0.87)` |
| 10    | `#F59E0B` | Amber            | `rgba(0,0,0,0.87)` |
| 11    | `#F97316` | Orange           | `rgba(0,0,0,0.87)` |
| 12    | `#EF4444` | Red              | `rgba(0,0,0,0.87)` |
| 13    | `#EC4899` | Pink             | `rgba(0,0,0,0.87)` |
| 14    | `#D946EF` | Fuchsia          | `rgba(0,0,0,0.87)` |
| 15    | `#A855F7` | Violet           | `rgba(0,0,0,0.87)` |
| 16    | `#8B5CF6` | Light Purple     | `#FFFFFF`  |
| 17    | `#6366F1` | Periwinkle       | `#FFFFFF`  |
| 18    | `#06B6D4` | Aqua             | `rgba(0,0,0,0.87)` |
| 19    | `#14B8A6` | Mint             | `rgba(0,0,0,0.87)` |

> **Note**: These colors are derived from the Tailwind CSS palette. Text colors are chosen to
> ensure a contrast ratio of at least 4.5:1 (WCAG AA).

## Example

Given:
- Pubkey: `a1b2c3d4e5f678901234567890abcde7af92ab0c1d2e3f4a5b6c7d8e9f0a1b2c3d`
- Palette: 20 colors (as defined above)

1. Extract chars at index 29-34: `7af92a`
2. Parse as hex: `0x7AF92A` = 8059178
3. Compute modulo: `8059178 % 20` = 18
4. Select palette color at index 18: `#06B6D4` (Aqua)

## Implementation Notes

### Initials Display

When no profile picture is available, clients should display a **single initial** on the colored
background. The initial should be derived from:
1. `display_name` field in metadata — the human-readable name the user chose to display
2. `name` field in metadata — the short identifier
3. Hex character at index 28 of the pubkey, mapped to a letter (fallback)

For case (3), the character at index 28 of the pubkey (hex `0-9`, `a-f`, values 0-15) should be
mapped to a letter `A-P` (0 → `A`, 1 → `B`, ... `a` → `K`, ... `f` → `P`). This ensures
the fallback is always a letter and never a digit. Index 28 is chosen because it lies in the
middle of the pubkey, which is not affected by vanity mining.

Only the **first character** of the selected field should be displayed, **always uppercase** for
consistency across clients. This ensures consistent proportions and legibility regardless of
avatar size. The initial should be centered within the avatar circle.

### Text Color

The text color is **predefined for each palette color** (see table above). No runtime luminance
calculation is needed — clients should simply use the text color associated with the selected
palette index.

### Profile Pictures

When a `picture` URL is available in metadata, it should be displayed instead of the
colored avatar. The derived color may be used as a placeholder while loading or as a fallback
if the image fails to load.

## Rationale

### Why the middle characters?

Using characters from the middle of the pubkey (indices 28-34) ensures fair distribution because:

1. **Vanity mining**: Users commonly mine keys to have specific prefixes (e.g., `000abc...`) or
   suffixes (e.g., `...000`). If the beginning or end were used, many vanity users would share
   the same avatar color.
2. **Nobody mines the middle**: Vanity mining targets the beginning and end of pubkeys because
   those are what humans see (e.g., in `npub1...`). The middle is untouched in practice.

### Why a fixed palette?

Random hex-to-RGB conversion can produce:
- Very dark or very light colors that are hard to read
- Muddy, unappealing colors
- Inconsistent visual experience

A curated palette ensures:
- Colors are always visually distinct and pleasant
- Consistent contrast for text overlays
- Alignment with modern UI design standards

### Why 20 colors?

20 provides enough variety to distinguish users while keeping the palette manageable.
The modulo operation distributes users evenly across the palette.
