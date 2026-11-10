# Modarraj — "Midnight Stadium" Design Specification
> Version 1.0 · 2026-11-10 · Arabic-first · Dark-first

---

## 1. Overview

**Design Direction:** Midnight Stadium  
**Tagline:** Dark-first identity, polished light theme.  
**Reference:** Apple Sports / FotMob / Linear / Stripe-level polish — restraint, precision, generous spacing, one confident accent, motion that feels expensive.

**Non-Negotiable Rules:**
- NO green anywhere — not in success states, win badges, pitch field backgrounds, or any semantic color
- NO glassmorphism (BackdropFilter blur is banned)
- NO particles, no animated gradients over large areas
- NO per-frame layout work
- NO neon/glow excess, NO Matrix aesthetic, NO clip-art
- NO hardcoded colors, text styles, spacing outside design tokens

---

## 2. Color Tokens

### 2.1 Dark Theme — "Midnight Stadium Dark"

| Token | Hex | Usage |
|-------|-----|-------|
| `bg` | `#0A0F1E` | Scaffold background |
| `surface` | `#111830` | Card, bottom-sheet surface |
| `elevated` | `#17203F` | Elevated cards, drawers |
| `raised` | `#1E2950` | Pressed state, overlays |
| `border` | `#223056` | 1px dividers, hairlines |
| `textPrimary` | `#F4F6FB` | Headlines, scores |
| `textSecondary` | `#A9B4D0` | Supporting text |
| `textMuted` / `textTertiary` | `#8392B3` | Timestamps, labels |
| `primary` (electric blue) | `#3D7BFF` | CTAs, selected nav, indicators |
| `primaryContainer` | `#172A66` | Primary chip bg, selected chip |
| `onPrimary` | `#FFFFFF` | Text on primary buttons |
| `live` (red-orange) | `#FF4D3D` | Live badge, live dot, live score |
| `warning` (amber) | `#FFB020` | Warnings, postponed state |
| `info` (ice-blue) | `#7FB2FF` | Info banners, secondary actions |
| `danger` | `#FF6B6B` | Errors, destructive actions |
| `success` | `#7FB2FF` | (ice-blue, never green!) Positive states |

### 2.2 Light Theme — "Midnight Stadium Light"

| Token | Hex | Usage |
|-------|-----|-------|
| `bg` | `#F4F6FB` | Scaffold background |
| `surface` | `#FFFFFF` | Card surface |
| `elevated` | `#FFFFFF` + soft shadow | Elevated surface |
| `border` | `#E3E8F3` | 1px dividers |
| `textPrimary` | `#0B1226` | Headlines, scores |
| `textSecondary` | `#4A5878` | Supporting text |
| `textMuted` / `textTertiary` | `#5F6C8A` | Timestamps, labels |
| `primary` | `#1F5FE0` | CTAs, selected nav |
| `primaryContainer` | `#E6EEFF` | Chip bg, selected |
| `live` | `#D4342A` | Live badge |
| `warning` | `#B26A00` | Postponed |
| `info` | `#1F5FE0` | Info |
| `success` | `#1F5FE0` | Positive (never green!) |

### 2.3 Signature Gradient (use SPARINGLY)
```
Dark:  LinearGradient([#2B3FD6, #0F1B5C], begin: topLeft, end: bottomRight)
Light: LinearGradient([#1F5FE0, #172A66], begin: topLeft, end: bottomRight)
```
Allowed uses: hero match card header, primary CTA, avatar rings, selected state underline.
**NOT allowed:** full-screen backgrounds, repeated cards, list items.

### 2.4 Form Result Indicators (W/D/L)
- **W (Win):** `primary` blue tonal — `#172A66` bg / `#3D7BFF` text (dark), `#E6EEFF` / `#1F5FE0` (light)
- **D (Draw):** neutral — `surface` bg / `textMuted` text
- **L (Loss):** `live` red — `#FF4D3D` bg `0x33` alpha / `#FF4D3D` text (dark), `#D4342A` (light)
> Never use green for W. Primary blue is the win color.

---

## 3. Typography Scale

Font: **Cairo** (variable, bundled at `assets/fonts/`). Arabic-first, full RTL.

| Role | Method | Size | Line H | Weight | Notes |
|------|--------|------|--------|--------|-------|
| `display` | `AppTypography.display` | 34sp | 1.17 (40) | w800 | Hero titles |
| `headline` | `AppTypography.headline` | 24sp | 1.33 (32) | w700 | Section headers |
| `title` | `AppTypography.title` | 18sp | 1.44 (26) | w700 | Card titles |
| `body` | `AppTypography.body` | 15sp | 1.60 (24) | w500 | Match rows, text |
| `label` | `AppTypography.label` | 13sp | 1.38 (18) | w600 | Badges, chips |
| `caption` | `AppTypography.caption` | 12sp | 1.33 (16) | w500 | Timestamps, meta |
| `score` | `AppTypography.score` | 28sp | 1.14 | w800 | Scores (tabular figures) |

---

## 4. Motion Tokens

| Token | Duration | Usage |
|-------|----------|-------|
| `instant` | 90ms | State pops, toggles |
| `fast` | 140ms | Icon swaps, badge in |
| `base` | 240ms | Chip select, fade |
| `slow` | 380ms | Card expand, page transition |
| `page` | 320ms | Screen-to-screen |
| `pulse` | 1400ms | Live dot breathing |

**Curves:**
- `standard`: `easeOutCubic` (Curves.easeOutCubic) — most transitions
- `emphasized`: `Cubic(0.2, 0, 0, 1)` — Material 3 emphasized easing
- `spring`: `easeOutBack` with max 4% overshoot — selection pops only

**Reduced Motion:** Always respect `MediaQuery.disableAnimations`. Use `AppMotion.isReducedMotion(context)` to skip/shorten animations.

---

## 5. Spacing & Layout

**Base grid:** 4dp unit, 8dp multiplier.

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 4dp | Icon-label gaps |
| `sm` | 8dp | Inner card padding |
| `md` | 12dp | Between items |
| `lg` | 16dp | Card padding, section margins |
| `xl` | 24dp | Screen horizontal padding |
| `xxl` | 32dp | Hero section padding |

**Breakpoints:**
- Compact: < 600dp (phones)
- Medium: 600–839dp (large phones, small tablets)
- Expanded: ≥ 840dp (tablets, foldables)

---

## 6. Corner Radii

| Token | Value | Usage |
|-------|-------|-------|
| `xs` | 6dp | Badges, chips (small) |
| `sm` | 8dp | Small cards, inputs |
| `md` | 12dp | Match cards |
| `lg` | 16dp | Hero card |
| `xl` | 24dp | Sheets, large panels |
| `pill` | 999dp | Full-pill chips, buttons |

---

## 7. Elevation Model

**Dark theme:** Elevation = tonal surface steps (no shadows).
- Level 0: `bg #0A0F1E`
- Level 1: `surface #111830`
- Level 2: `elevated #17203F`
- Level 3: `raised #1E2950`

**Light theme:** Elevation = layered soft shadows.
- Level 0: `bg #F4F6FB`
- Level 1: `surface #FFFFFF` + `BoxShadow(color: #0B122612, blurRadius: 8, offset: (0, 2))`
- Level 2: `elevated #FFFFFF` + `BoxShadow(color: #0B122618, blurRadius: 16, offset: (0, 4))`

---

## 8. Component States

Each interactive component must implement ALL states:

| State | Dark | Light |
|-------|------|-------|
| Default | `surface` bg | `surface` bg |
| Hover | `elevated` bg | `elevated` bg |
| Pressed | `raised` bg | `border` bg |
| Selected | `primaryContainer` bg + `primary` border | `primaryContainer` + `primary` border |
| Disabled | opacity 0.38 | opacity 0.38 |
| Loading | Shimmer on `elevated` | Shimmer on `elevated` |
| Error | `danger` border 1px | `danger` border 1px |

---

## 9. Theme Presets

Small deltas on base; all must be WCAG AA compliant.

| Preset | Key Change | Available |
|--------|-----------|-----------|
| `default_dark` | Midnight Stadium base | ✅ |
| `default_light` | Midnight Stadium light | ✅ |
| `ramadan` | Warm gold #D4A017 accent + deep indigo bg #0C0A1E | Season only |
| `champions_league` | Starry navy bg #060D1E + periwinkle #8B9CF4 primary | Season only |
| `classico` | Dual accent: team A red / team B blue split | Match only |
| `golden` | Amber #D97706 accent + warm near-black #12100A bg | Season only |

---

## 10. System UI

- **Edge-to-edge:** `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)`
- **Status bar:** transparent, icon brightness follows theme (dark icons on light, light icons on dark)
- **Navigation bar:** transparent, icon brightness follows theme
- **Launch background:** solid `#0A0F1E` (dark) — no logo on launch screen
- **Notification accent:** `#3D7BFF` (primary blue)

---

## 11. Accessibility

| Requirement | Rule |
|------------|------|
| Contrast text | ≥ 4.5:1 (WCAG AA) for all `textPrimary`/`textSecondary`/`textMuted` on their backgrounds |
| Contrast UI | ≥ 3:1 for borders, icons, shapes |
| Tap targets | ≥ 48 × 48dp for all interactive elements |
| Semantics | `Semantics(label: ...)` on scores, match status, event icons |
| RTL | `EdgeInsetsDirectional`, directional icons mirrored, `TextDirection.rtl` |
| Text scale | No overflow at `textScaler = 1.3×` |

---

## 12. Do / Don't

✅ **DO:**
- Use `context.colors.X` for every color reference
- Use `AppTypography.X()` for every text style
- Use `AppMotion.X` for every duration/curve
- Use `AppRadii.X` for every radius
- Apply `const` wherever the analyzer allows
- Use `Semantics` on interactive/data widgets
- Use `EdgeInsetsDirectional` for padding/margin

❌ **DON'T:**
- Use any shade of green (hue 80–160°) anywhere
- Use `BackdropFilter` / blur effects
- Use hardcoded `Color(0xFFXXXXXX)` outside design system files
- Use `TextStyle(fontSize: X)` outside `AppTypography`
- Use `EdgeInsets.only(left:...)` — use `EdgeInsetsDirectional.only(start:...)` instead
- Animate gradients over large screen areas
- Use `MediaQuery.of(context)` where `.paddingOf` / `.viewPaddingOf` variant exists
- Nest `SafeArea` widgets

---

## 13. File Structure (Design System)

```
lib/core/theme/
  app_colors.dart        — Color tokens + AppThemeColors ThemeExtension
  app_typography.dart    — TextStyle factory methods
  app_motion.dart        — Duration/Curve tokens + reduced motion helper
  app_radii.dart         — Corner radius tokens
  app_spacing.dart       — Spacing scale (NEW)
  app_theme.dart         — ThemeData factories + presets
  theme_extensions.dart  — BuildContext extensions
```

