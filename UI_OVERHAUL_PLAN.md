# UI Overhaul Plan: Glassmorphism & Apple Design

## Goal
Transform the current dark/gradient UI into a modern, clean, Apple-inspired "Glass" interface using `BackdropFilter`, semi-transparent layers, and refined typography.

## Design System

### 1. Colors (`AppColors`)
- **Background**: Dynamic mesh gradient (Aurora style).
- **Glass Layers**:
  - `glassLow`: opacity 0.1, blur 10px (Subtle)
  - `glassMedium`: opacity 0.2, blur 20px (Cards/Content)
  - `glassHigh`: opacity 0.3, blur 30px (NavBars/Modals)
  - `glassBorder`: opacity 0.1 (White)
- **Primary**: Retain Cyan/Teal but possibly adjust saturation for vibrancy against glass.

### 2. Components

#### `GlassContainer`
A generic container that applies:
- `ClipRRect` (rounded corners)
- `BackdropFilter` (blur)
- `Container` with gradient/color opacity
- `Border` (thin white/light)

#### `GlassScaffold`
A wrapper widget that:
- Places the **Mesh Gradient** background.
- Places the `Scaffold` with `backgroundColor: Colors.transparent`.
- Handles `extendBody: true` for glass bottom nav bars.

#### `GlassAppBar`
- Transparent background.
- Blurred content behind it.
- Large title support (Cupertino style).

### 3. Typography
- Use `GoogleFonts.manrope` but tune weights.
- Headlines: Bold/Black.
- Body: Regular/Medium.

## File Changes

### Core
- [ ] `app/lib/core/theme/app_colors.dart`: Add glass constants.
- [ ] `app/lib/core/theme/app_theme.dart`: Update `ThemeData` to be transparent-friendly.
- [ ] `app/lib/presentation/widgets/glass_container.dart`: Create new widget.
- [ ] `app/lib/presentation/widgets/glass_scaffold.dart`: Create new widget.
- [ ] `app/lib/presentation/widgets/mesh_gradient_background.dart`: Create background visual.

### Screens
- [ ] `app/lib/presentation/auth/pages/login_page.dart`: Apply GlassScaffold + Glass Cards.
- [ ] `app/lib/presentation/home/home_page.dart`: Glass BottomNav, Glass ListItems.
- [ ] `app/lib/presentation/chat/chat_page.dart`: Glass Bubbles, Glass Input, Wallpapers.

## Implementation Steps

1.  **Setup Styles**: Define colors and theme.
2.  **Build Core Widgets**: `GlassContainer`, `GlassScaffold`.
3.  **Refactor Screens**: Go screen by screen replacing standard widgets with Glass variants.
