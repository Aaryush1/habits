# Atomic Habits Tracker - Design System

## Design Philosophy

**"Scientific Minimalism with Warmth"**

This app is for someone serious about self-improvement—data-driven, intentional, seeking clarity. The design reflects the "atomic" concept: discrete elements that compound into larger wholes. Visual language emphasizes small, satisfying completions building toward meaningful change.

The aesthetic draws from:
- Premium research journals and scientific notation
- Luxury productivity tools
- Data visualization that reveals patterns, not just numbers

---

## Color System

### Core Palette (Dark Theme)

```dart
// Primary Backgrounds
static const Color backgroundPrimary = Color(0xFF0D0D0F);    // Deep charcoal, not pure black
static const Color backgroundSecondary = Color(0xFF161619);  // Card surfaces
static const Color backgroundTertiary = Color(0xFF1E1E22);   // Elevated elements
static const Color backgroundQuaternary = Color(0xFF28282D); // Input fields, wells

// Accent Colors
static const Color accentGold = Color(0xFFE8A838);           // Primary accent - satisfaction, achievement
static const Color accentGoldMuted = Color(0xFFB8862D);      // Hover states
static const Color accentGoldSubtle = Color(0x33E8A838);     // 20% opacity backgrounds

// Semantic Colors
static const Color completionGreen = Color(0xFF7DB87D);      // Full completion
static const Color completionGreenSubtle = Color(0x337DB87D);
static const Color twoMinuteBlue = Color(0xFF6B9BD2);        // 2-minute rule completion
static const Color twoMinuteBlueSubtle = Color(0x336B9BD2);
static const Color skippedGray = Color(0xFF5A5A62);          // Intentionally skipped
static const Color missedCoral = Color(0xFFD4726A);          // Missed/needs attention
static const Color missedCoralSubtle = Color(0x33D4726A);

// Text Hierarchy
static const Color textPrimary = Color(0xFFF5F5F7);          // Headlines, primary content
static const Color textSecondary = Color(0xFFB0B0B8);        // Body text, descriptions
static const Color textTertiary = Color(0xFF6E6E78);         // Captions, hints
static const Color textInverse = Color(0xFF0D0D0F);          // Text on light backgrounds

// Borders & Dividers
static const Color borderSubtle = Color(0xFF2A2A30);
static const Color borderMedium = Color(0xFF3A3A42);
static const Color borderFocus = Color(0xFFE8A838);
```

### Habit Colors (User-Selectable)

```dart
static const List<Color> habitPalette = [
  Color(0xFFE8A838), // Gold
  Color(0xFF7DB87D), // Sage
  Color(0xFF6B9BD2), // Sky
  Color(0xFFD4726A), // Coral
  Color(0xFFB088D4), // Lavender
  Color(0xFF5BC0BE), // Teal
  Color(0xFFE07B53), // Tangerine
  Color(0xFFC9B1FF), // Periwinkle
];
```

### Heatmap Gradient

```dart
// 5-level intensity for heatmaps (0%, 25%, 50%, 75%, 100%)
static const List<Color> heatmapGradient = [
  Color(0xFF1E1E22), // No activity
  Color(0xFF2D3B2D), // Low
  Color(0xFF3D5A3D), // Medium-low
  Color(0xFF5A8A5A), // Medium-high
  Color(0xFF7DB87D), // High/complete
];
```

---

## Typography

### Font Families

**Display Font**: Fraunces
- Used for: Screen titles, large numbers, identity statements
- Character: Soft serif with optical sizing, feels personal and warm
- Weights: 400 (regular), 600 (semibold)

**Body Font**: DM Sans
- Used for: All body text, buttons, labels, navigation
- Character: Geometric, modern, highly legible at small sizes
- Weights: 400 (regular), 500 (medium), 600 (semibold), 700 (bold)

**Monospace**: JetBrains Mono
- Used for: Statistics, numbers, time displays
- Character: Technical precision, data-forward

### Type Scale

```dart
// Display (Fraunces)
static const TextStyle displayLarge = TextStyle(
  fontFamily: 'Fraunces',
  fontSize: 32,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.5,
  height: 1.2,
);

static const TextStyle displayMedium = TextStyle(
  fontFamily: 'Fraunces',
  fontSize: 24,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.3,
  height: 1.3,
);

static const TextStyle displaySmall = TextStyle(
  fontFamily: 'Fraunces',
  fontSize: 20,
  fontWeight: FontWeight.w400,
  letterSpacing: -0.2,
  height: 1.3,
);

// Headlines (DM Sans)
static const TextStyle headlineLarge = TextStyle(
  fontFamily: 'DM Sans',
  fontSize: 18,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.2,
  height: 1.4,
);

static const TextStyle headlineMedium = TextStyle(
  fontFamily: 'DM Sans',
  fontSize: 16,
  fontWeight: FontWeight.w600,
  letterSpacing: -0.1,
  height: 1.4,
);

static const TextStyle headlineSmall = TextStyle(
  fontFamily: 'DM Sans',
  fontSize: 14,
  fontWeight: FontWeight.w600,
  letterSpacing: 0,
  height: 1.4,
);

// Body (DM Sans)
static const TextStyle bodyLarge = TextStyle(
  fontFamily: 'DM Sans',
  fontSize: 16,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
  height: 1.5,
);

static const TextStyle bodyMedium = TextStyle(
  fontFamily: 'DM Sans',
  fontSize: 14,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
  height: 1.5,
);

static const TextStyle bodySmall = TextStyle(
  fontFamily: 'DM Sans',
  fontSize: 12,
  fontWeight: FontWeight.w400,
  letterSpacing: 0.1,
  height: 1.5,
);

// Labels (DM Sans)
static const TextStyle labelLarge = TextStyle(
  fontFamily: 'DM Sans',
  fontSize: 14,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.1,
  height: 1.4,
);

static const TextStyle labelMedium = TextStyle(
  fontFamily: 'DM Sans',
  fontSize: 12,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.2,
  height: 1.4,
);

static const TextStyle labelSmall = TextStyle(
  fontFamily: 'DM Sans',
  fontSize: 10,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.3,
  height: 1.4,
);

// Data/Statistics (JetBrains Mono)
static const TextStyle dataLarge = TextStyle(
  fontFamily: 'JetBrains Mono',
  fontSize: 32,
  fontWeight: FontWeight.w500,
  letterSpacing: -1,
  height: 1.1,
);

static const TextStyle dataMedium = TextStyle(
  fontFamily: 'JetBrains Mono',
  fontSize: 20,
  fontWeight: FontWeight.w500,
  letterSpacing: -0.5,
  height: 1.2,
);

static const TextStyle dataSmall = TextStyle(
  fontFamily: 'JetBrains Mono',
  fontSize: 14,
  fontWeight: FontWeight.w400,
  letterSpacing: 0,
  height: 1.3,
);
```

---

## Spacing System

8px base unit with consistent scale:

```dart
static const double space2 = 2;
static const double space4 = 4;
static const double space8 = 8;
static const double space12 = 12;
static const double space16 = 16;
static const double space20 = 20;
static const double space24 = 24;
static const double space32 = 32;
static const double space40 = 40;
static const double space48 = 48;
static const double space64 = 64;

// Screen padding
static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 20);
static const EdgeInsets cardPadding = EdgeInsets.all(16);
static const EdgeInsets listItemPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
```

---

## Border Radius

```dart
static const double radiusSmall = 6;
static const double radiusMedium = 10;
static const double radiusLarge = 14;
static const double radiusXLarge = 20;
static const double radiusFull = 999; // Pills, circles
```

---

## Elevation & Shadows

Subtle, layered approach for dark theme:

```dart
// Card shadow (used sparingly)
static List<BoxShadow> cardShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.3),
    blurRadius: 12,
    offset: Offset(0, 4),
  ),
];

// Elevated element (FAB, modals)
static List<BoxShadow> elevatedShadow = [
  BoxShadow(
    color: Colors.black.withOpacity(0.4),
    blurRadius: 24,
    offset: Offset(0, 8),
  ),
];

// Glow effect for primary actions
static List<BoxShadow> accentGlow = [
  BoxShadow(
    color: accentGold.withOpacity(0.3),
    blurRadius: 16,
    spreadRadius: -2,
  ),
];
```

---

## Components

### 1. Habit Card (Today View)

```
┌─────────────────────────────────────────────────────────┐
│  ┌────┐                                                 │
│  │ ◯  │  Meditate                           ○ ○ ○ ○ ● ◉ │
│  │    │  7:00 AM · Living room                 6 days   │
│  └────┘                                                 │
│         "I am someone who finds peace daily"            │
└─────────────────────────────────────────────────────────┘

- Left: Circular completion indicator (tap target 48x48)
  - Empty circle: Not done
  - Filled circle: Complete
  - Half-filled: 2-minute version
  - Dash: Skipped
- Habit color shown as left border accent (4px)
- Mini streak visualization (last 6 days as dots)
- Identity statement in italic, muted
- Implementation intention as caption
```

**Completion Animation**:
- Tap triggers satisfying "pop" animation
- Circle fills with habit color
- Subtle haptic feedback
- Confetti particles on streak milestones (7, 30, 60, 90, 365)

### 2. Streak Indicator

```
┌─────────────────────────┐
│  🔥 23                  │
│  Current Streak         │
│                         │
│  ○ ○ ○ ● ● ● ●          │
│  M T W T F S S          │
└─────────────────────────┘

- Large number in dataLarge style
- Fire icon only for streaks > 7 days
- Weekly dot visualization below
- Color intensity increases with streak length
```

### 3. Heatmap Cell

```
┌────┐
│    │  12x12dp cells
│    │  2dp gap
└────┘

- 4dp border radius
- Color from heatmapGradient based on completion %
- Tap reveals tooltip with date and habits completed
```

### 4. Habit Stack Visualization

```
      ┌─────────┐
      │  Wake   │
      └────┬────┘
           │
           ▼
      ┌─────────┐
      │  Bed    │
      └────┬────┘
           │
           ▼
    ┌──────┴──────┐
    ▼             ▼
┌─────────┐  ┌─────────┐
│ Meditate│  │ Journal │
└─────────┘  └─────────┘

- Vertical flow with connecting lines
- Branching supported
- Active habit highlighted with gold border
- Completed habits have green check overlay
- Drag handles for reordering
```

### 5. Analytics Stat Card

```
┌─────────────────────────┐
│  87%                    │
│  Completion Rate        │
│  ──────────────────     │
│  ▲ 12% vs last month    │
└─────────────────────────┘

- Large metric in dataMedium
- Label in labelSmall, textTertiary
- Thin progress bar or spark line
- Trend indicator with color (green up, coral down)
```

### 6. Bottom Navigation

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│   ◉        ⊞        ☰        📊        ⚙        │
│  Today  Scorecard  Habits  Analytics  Settings          │
│                                                         │
└─────────────────────────────────────────────────────────┘

- 64dp height
- Active state: Gold accent, filled icon
- Inactive: textTertiary
- No elevation, uses borderSubtle top border
- Subtle background blur on scroll
```

### 7. Floating Action Button

```
     ┌───────────┐
     │    +      │
     │   habit   │
     └───────────┘

- Pill shape, not circle
- Gold background with glow
- Text + icon for clarity
- Bottom-right position, 16dp from edges
- Hides on scroll down, shows on scroll up
```

### 8. Form Inputs

```
┌─────────────────────────────────────────┐
│  Habit Name                             │
│  ─────────────────────────────────────  │
│  Morning meditation                     │
└─────────────────────────────────────────┘

- Label above in labelMedium
- Underline style, not bordered box
- Focus state: Gold underline
- Error state: Coral underline + message
- 48dp minimum height for tap target
```

### 9. Chip / Tag

```
┌──────────────┐
│  ● Morning   │
└──────────────┘

- Pill shape (radiusFull)
- Category color as dot prefix
- backgroundTertiary fill
- Used for categories, filters, day selection
```

### 10. Modal / Bottom Sheet

```
┌─────────────────────────────────────────────────────────┐
│  ━━━                                                    │
│                                                         │
│  Skip this habit?                                       │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  Reason (optional)                               │   │
│  │  ___________________________________________    │   │
│  └─────────────────────────────────────────────────┘   │
│                                                         │
│  ┌─────────────────┐  ┌─────────────────┐              │
│  │     Cancel      │  │      Skip       │              │
│  └─────────────────┘  └─────────────────┘              │
│                                                         │
└─────────────────────────────────────────────────────────┘

- Drag handle centered at top
- radiusXLarge on top corners only
- backgroundSecondary fill
- Content padding: 24dp
```

---

## Icons

Using a consistent icon set (recommend Phosphor Icons for their optical balance):

**Navigation**:
- Today: `calendar-check`
- Scorecard: `grid-four`
- Habits: `list-bullets`
- Analytics: `chart-line-up`
- Settings: `gear`

**Actions**:
- Add: `plus`
- Edit: `pencil-simple`
- Delete: `trash`
- Archive: `archive-box`
- Notification: `bell`
- Stack/Link: `link-simple`
- Export: `export`

**Status**:
- Complete: `check-circle`
- 2-minute: `clock`
- Skipped: `minus-circle`
- Streak: `flame`
- Trend up: `trend-up`
- Trend down: `trend-down`

**Size**: 24dp default, 20dp in compact contexts

---

## Motion & Animation

### Principles
- **Purposeful**: Every animation communicates state change
- **Quick**: 200-300ms for most transitions
- **Satisfying**: Completions feel rewarding

### Timing Curves

```dart
static const Curve defaultCurve = Curves.easeOutCubic;
static const Curve bouncyCurve = Curves.elasticOut;
static const Curve snappyCurve = Curves.easeOutQuart;

static const Duration fast = Duration(milliseconds: 150);
static const Duration normal = Duration(milliseconds: 250);
static const Duration slow = Duration(milliseconds: 400);
```

### Key Animations

**Habit Completion**:
```
1. Scale down to 0.95 (50ms)
2. Scale up to 1.05 with color fill (150ms, bouncyCurve)
3. Settle to 1.0 (100ms)
4. Checkmark draws in (200ms)
5. Streak dots ripple update (staggered, 50ms each)
```

**Page Transitions**:
- Horizontal slide for peer navigation (bottom nav)
- Vertical slide-up for modals/details
- Fade for tab content within screens

**List Items**:
- Staggered fade-in on load (50ms delay per item, max 5)
- Swipe-to-reveal actions
- Drag-and-drop with shadow elevation

**Charts**:
- Draw-in animation on first load
- Smooth interpolation on data change
- Heatmap cells fade in by row

---

## Screen Layouts

### 1. Home / Today

```
┌─────────────────────────────────────────┐
│  Friday, January 31                     │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │  4/6 Complete           67%     │   │
│  │  ████████████░░░░░░             │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Morning                                │
│  ─────────────────────────────────────  │
│  ┌─────────────────────────────────┐   │
│  │ ◯  Wake up at 6am      ● ● ● ● │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ ◉  Meditate 10min      ● ● ○ ● │   │
│  └─────────────────────────────────┘   │
│  ┌─────────────────────────────────┐   │
│  │ ◯  Exercise            ● ○ ● ● │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Evening                                │
│  ─────────────────────────────────────  │
│  ┌─────────────────────────────────┐   │
│  │ ◉  Read 30 pages       ● ● ● ● │   │
│  └─────────────────────────────────┘   │
│                                         │
│                          ┌───────────┐  │
│                          │  + habit  │  │
│                          └───────────┘  │
│                                         │
├─────────────────────────────────────────┤
│  ◉ Today   ⊞   ☰   📊   ⚙  │
└─────────────────────────────────────────┘
```

### 2. Scorecard

```
┌─────────────────────────────────────────┐
│  Scorecard                    This Week │
│                                      ▼  │
│                                         │
│         M   T   W   T   F   S   S       │
│        ───────────────────────────      │
│  Wake  [●] [●] [●] [●] [○] [○] [ ]      │
│  Med   [●] [●] [◐] [●] [○] [○] [ ]      │
│  Gym   [●] [─] [●] [─] [●] [○] [ ]      │
│  Read  [●] [●] [●] [●] [●] [○] [ ]      │
│  Jrnl  [●] [●] [●] [●] [○] [○] [ ]      │
│                                         │
│  Legend:                                │
│  ● Complete  ◐ 2-min  ─ Skip  ○ Miss    │
│                                         │
├─────────────────────────────────────────┤
│  ◉ Today   ⊞   ☰   📊   ⚙  │
└─────────────────────────────────────────┘
```

### 3. Analytics Dashboard

```
┌─────────────────────────────────────────┐
│  Analytics                              │
│                                         │
│  ┌───────────┐  ┌───────────┐          │
│  │    23     │  │    87%    │          │
│  │  Best     │  │ Complete  │          │
│  │  Streak   │  │   Rate    │          │
│  │  ▲ 5      │  │  ▲ 12%    │          │
│  └───────────┘  └───────────┘          │
│                                         │
│  This Week                              │
│  ┌─────────────────────────────────┐   │
│  │     📈 Completion Trend         │   │
│  │    ╱╲    ╱╲                     │   │
│  │   ╱  ╲  ╱  ╲  ╱                 │   │
│  │  ╱    ╲╱    ╲╱                  │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Activity                               │
│  ┌─────────────────────────────────┐   │
│  │  [GitHub-style heatmap]         │   │
│  │  ░░▓▓██░░▓▓██░░▓▓██░░▓▓██      │   │
│  │  ░░▓▓██░░▓▓██░░▓▓██░░▓▓██      │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Best Days        Habits by Rate        │
│  ┌───────────┐   ┌───────────────┐     │
│  │ 1. Mon 94%│   │ Read     98%  │     │
│  │ 2. Wed 89%│   │ Meditate 87%  │     │
│  │ 3. Fri 85%│   │ Exercise 72%  │     │
│  └───────────┘   └───────────────┘     │
│                                         │
├─────────────────────────────────────────┤
│  ◉ Today   ⊞   ☰   📊   ⚙  │
└─────────────────────────────────────────┘
```

### 4. Habit Detail

```
┌─────────────────────────────────────────┐
│  ←  Meditate                      ⋮     │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │        🔥 23 Day Streak         │   │
│  │     ○ ○ ● ● ● ● ● ● ● ◉        │   │
│  │                                 │   │
│  │  "I am someone who finds        │   │
│  │   peace through stillness"      │   │
│  └─────────────────────────────────┘   │
│                                         │
│  Implementation                         │
│  ─────────────────────────────────────  │
│  🕐  7:00 AM                            │
│  📍  Living room                        │
│  ⚡  2-min: Sit and breathe 3x          │
│                                         │
│  Schedule                               │
│  ─────────────────────────────────────  │
│  Daily                                  │
│                                         │
│  In Stack                               │
│  ─────────────────────────────────────  │
│  After: Wake up → [Meditate] → Exercise │
│                                         │
│  Statistics                             │
│  ─────────────────────────────────────  │
│  ┌─────────────────────────────────┐   │
│  │  Total: 156  │  Rate: 87%       │   │
│  │  Best: 45    │  Avg/wk: 6.2     │   │
│  └─────────────────────────────────┘   │
│                                         │
│  ┌─────────────────────────────────┐   │
│  │        View Full Analytics       │   │
│  └─────────────────────────────────┘   │
│                                         │
├─────────────────────────────────────────┤
│  ◉ Today   ⊞   ☰   📊   ⚙  │
└─────────────────────────────────────────┘
```

---

## Accessibility

- All interactive elements minimum 48x48dp
- Color is never the only indicator (icons + color)
- Text contrast ratios meet WCAG AA (4.5:1 minimum)
- Support for bold text and larger font sizes
- Semantic labels for screen readers
- Focus indicators visible (gold outline)

---

## Implementation Notes

### Flutter Packages Required

```yaml
dependencies:
  google_fonts: ^6.0.0      # For Fraunces, DM Sans, JetBrains Mono
  fl_chart: ^0.66.0         # Charts and heatmaps
  phosphor_flutter: ^2.0.0  # Icon set
  flutter_animate: ^4.0.0   # Animation helpers
  haptic_feedback: ^0.5.0   # Tactile responses
```

### Theme Setup

Create a unified `AppTheme` class that combines:
- `ColorScheme` from color constants
- `TextTheme` from typography definitions
- Component themes (Card, Button, Input, etc.)

Use `ThemeExtension` for custom properties like habit colors and chart colors.

---

*Design System Version: 1.0*
*Last Updated: 2026-01-31*
