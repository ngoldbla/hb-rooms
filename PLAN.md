# Plan: Fix Mobile Admin Dropdown Width Issue

## Problem Analysis

### Root Cause
iOS Safari (and some other mobile browsers) calculate native `<select>` element width based on the **selected option's text length**, not the longest option or CSS width properties. This is a fundamental limitation of native select elements that cannot be reliably fixed with CSS alone.

### Why Previous Fixes Failed
- `w-full` and `min-w-full` are ignored by iOS Safari's intrinsic sizing
- The width changes dynamically as users select different options
- "Office Spaces" (short text) = narrow dropdown
- "Email Templates" (longer text) = wider dropdown

## Proposed Solution: Custom Mobile Navigation

Replace the native `<select>` element with a custom button-triggered dropdown that provides:
1. **Consistent width**: Full-width button that doesn't shrink
2. **Better UX**: Shows current selection clearly with visual feedback
3. **Grouped options**: Display groups with visual hierarchy
4. **Accessibility**: Proper ARIA attributes and keyboard navigation

### Design Specification

**Mobile Navigation (< 768px)**:
```
┌────────────────────────────────────────┐
│  📍 Office Spaces                   ▼  │  <- Full-width button
└────────────────────────────────────────┘

When clicked, displays dropdown panel:
┌────────────────────────────────────────┐
│ PEOPLE                                 │
│   Users                                │
│   Contracts                            │
├────────────────────────────────────────┤
│ SPACES                                 │
│   Rooms                                │
│   Desks                                │
│   Amenities                            │
│ ✓ Office Spaces                        │  <- Current selection highlighted
├────────────────────────────────────────┤
│ CONFIGURATION                          │
│   Settings                             │
│   Email Templates                      │
└────────────────────────────────────────┘
```

## Implementation Steps

### Step 1: Create Custom Mobile Nav Component
Location: `lib/overbooked_web/live/live_helpers.ex`

Replace `admin_nav_mobile/1` with a custom dropdown component that:
- Uses a `<button>` element (respects width CSS)
- Shows currently selected page name
- Toggles visibility of options panel on click
- Closes on outside click (using `phx-click-away`)
- Navigates via `navigate` on option click

### Step 2: Style the Component
- Match existing app styling (rounded-md, shadow-sm, border-gray-300)
- Group headers in uppercase, muted color
- Current selection with checkmark and highlight
- Smooth open/close transitions
- Ensure touch targets are at least 44px

### Step 3: Maintain Accessibility
- `aria-expanded` on trigger button
- `aria-haspopup="listbox"`
- `role="listbox"` on options container
- `role="option"` on each option
- `aria-selected` on current selection
- Keyboard support (Escape to close)

## Alternative Considered: Consolidating Admin Sections

The user mentioned being open to reorganizing if it means denser choices. Current structure:

| Group | Items | Could Consolidate? |
|-------|-------|-------------------|
| People | Users, Contracts | Keep separate - distinct functions |
| Spaces | Rooms, Desks, Amenities, Office Spaces | Could merge Rooms+Desks as "Resources" |
| Configuration | Settings, Email Templates | Keep separate - distinct functions |

**Recommendation**: Keep current structure. 8 navigation items is reasonable, and the custom dropdown handles it well. Consolidation would reduce clarity and require more clicks to access specific features.

## Files to Modify

1. `lib/overbooked_web/live/live_helpers.ex`
   - Replace `admin_nav_mobile/1` function (lines 119-175)
   - Add helper function for nav item labels

## Testing Checklist
- [ ] Width stays consistent across all admin pages on iOS Safari
- [ ] Dropdown opens and closes smoothly
- [ ] Clicking outside closes dropdown
- [ ] Navigation works correctly
- [ ] Current page is highlighted
- [ ] Works on Android Chrome
- [ ] Works on desktop (hidden, uses tablet/desktop nav)
- [ ] Accessible via keyboard
