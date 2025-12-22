# UIkit to SaladUI Migration Blueprint

> **Project:** Hatchbridge Rooms (Overbooked)  
> **Current Stack:** Phoenix 1.6.6 + LiveView 0.18 + Tailwind CSS + AlpineJS  
> **Target:** SaladUI v1.0.0-beta (shadcn-inspired Phoenix components)

---

## 🚀 Phoenix/LiveView Upgrade Status (In Progress)

> [!IMPORTANT]
> **Framework upgrade is underway on branch:** `upgrade/phoenix-1.7`
> 
> **Files Modified:**
> - `mix.exs` - Updated Phoenix ~> 1.7.14, LiveView ~> 0.20.17
> - `config/config.exs` - New error handling format
> - `lib/overbooked_web.ex` - Verified routes, layouts, html helper
> - `lib/overbooked_web/controllers/error_html.ex` - NEW
> - `lib/overbooked_web/controllers/error_json.ex` - NEW
> - `lib/overbooked_web/components/layouts.ex` - NEW
> - `lib/overbooked_web/components/layouts/*` - Copied templates
> - `lib/overbooked_web/live/live_helpers.ex` - Replaced `live_patch`
>
> **Next Steps:** Run `mix deps.get` and fix compilation errors

---

## Executive Summary

This document outlines the systematic transition from the current custom component library (`live_helpers.ex` + `live_form_helpers.ex`) to SaladUI standard components. The migration involves **~60 custom components** across 2 main files plus inline HEEx templates.

### Current State Analysis

| File | Lines | Components | Purpose |
|------|-------|------------|---------|
| `live_helpers.ex` | 984 | 46+ | UI components (modal, dropdown, button, table, tabs, etc.) |
| `live_form_helpers.ex` | 445 | 13 | Form inputs (text, select, checkbox, date, time, etc.) |
| Layout templates | 302+ | ~10 | Sidebar, navigation, mobile drawer |

### Key Challenges Identified

1. **LiveView Version Gap**: Project uses LiveView 0.18, SaladUI targets newer versions
2. **AlpineJS Dependency**: Current code heavily uses Alpine.js (`x-data`, `x-show`, `x-transition`)  
3. **Custom Modal System**: Complex modal with focus trap, escape handling, patch/navigate support
4. **Custom Form Components**: Tight integration with Ecto changesets and Phoenix.HTML.Form

---

## Phase 1: Foundation Setup ⚠️ HIGH RISK

### 1.1 Dependency Installation

```elixir
# mix.exs
{:salad_ui, "~> 1.0.0-beta.3"}
```

### 1.2 Configuration Setup

```bash
# Initialize SaladUI in project
mix salad.init --as-lib

# This will:
# - Add tailwind.config.js modifications
# - Copy CSS custom properties
# - Setup TwMerge.Cache in application.ex
```

### 1.3 LiveView Compatibility Check ❌ BLOCKER

| Requirement | Current | Required | Gap |
|-------------|---------|----------|-----|
| LiveView | 0.18.x | 0.20+ | **Upgrade needed** |
| Phoenix | 1.6.6 | 1.7+ | **Upgrade needed** |
| Ecto | 3.10+ | 3.10+ | ✅ Compatible |

> [!CAUTION]
> **SaladUI v1.x requires Phoenix 1.7+ and LiveView 0.20+**. The current project uses Phoenix 1.6.6 and LiveView 0.18. This is the primary blocker for this migration.

### 1.4 Migration Options

#### Option A: Full Framework Upgrade (Recommended)
- Upgrade Phoenix 1.6 → 1.7+
- Upgrade LiveView 0.18 → 0.20+
- Then adopt SaladUI
- **Est. effort:** 2-3 weeks

#### Option B: Use SaladUI v0.14 (Legacy)
- SaladUI v0.14 may work with older LiveView
- Limited component set
- Less maintained
- **Est. effort:** 1 week + compatibility testing

#### Option C: Partial Adoption
- Keep existing components for complex patterns
- Use SaladUI only for simple components (Badge, Card, Alert)
- **Est. effort:** 1-2 weeks

---

## Phase 2: Component Mapping

### 2.1 Direct Replacements (Low Risk) ✅

These components have near-identical SaladUI equivalents:

| Current Component | SaladUI Equivalent | Notes |
|-------------------|-------------------|-------|
| `.badge/1` | `SaladUI.Badge.badge/1` | Color props differ slightly |
| `.spinner/1` | Built into buttons | Use `loading` prop |
| `.progress_bar/1` | `SaladUI.Progress.progress/1` | API matches closely |
| `.button/1` | `SaladUI.Button.button/1` | Variants: `default`, `destructive`, `outline`, etc. |
| `.header/1` | Custom layout | No direct equivalent |
| `.page/1` | Custom layout | No direct equivalent |

### 2.2 Moderate Adaptations (Medium Risk) ⚠️

| Current | SaladUI | Migration Notes |
|---------|---------|-----------------|
| `.flash/1` | `SaladUI.Alert.alert/1` | Different dismissal pattern |
| `.dropdown/1` | `SaladUI.DropdownMenu` | Different slot structure |
| `.tabs/1` | `SaladUI.Tabs` | Different API, uses JS hooks |
| `.icon/1` | `SaladUI.Icon.icon/1` | Uses Lucide icons vs Heroicons |
| `.table/1` | `SaladUI.Table` | Similar structure |

### 2.3 Complex Migrations (High Risk) 🚨

| Current | Issue | SaladUI Alternative |
|---------|-------|---------------------|
| `.modal/1` | Custom focus trap, patch support, escape handling | `SaladUI.Dialog` - requires refactoring all modal calls |
| `.card_list/1` | Responsive card/table hybrid | No equivalent - keep custom or build new |
| `.live_table/1` | LiveComponent row rendering | No equivalent - keep custom |
| `admin_tabs/1` | Complex responsive nav | `SaladUI.Tabs` + `SaladUI.Sheet` combination |
| Layout sidebar | AlpineJS-driven mobile drawer | `SaladUI.Sidebar` or `SaladUI.Sheet` |

---

## Phase 3: Form Components Migration

### 3.1 Form Input Mapping

| Current (`LiveFormHelpers`) | SaladUI Equivalent | Status |
|-----------------------------|-------------------|--------|
| `text_input/1` | `SaladUI.Input.input/1` | ✅ Direct mapping |
| `password_input/1` | `SaladUI.Input.input/1` (type="password") | ✅ Direct mapping |
| `textarea/1` | `SaladUI.Textarea.textarea/1` | ✅ Direct mapping |
| `select/1` | `SaladUI.Select` | ⚠️ More complex API |
| `checkbox/1` | `SaladUI.Checkbox.checkbox/1` | ✅ Direct mapping |
| `checkbox_group/1` | Custom implementation needed | ❌ No equivalent |
| `switch/1` | `SaladUI.Switch.switch/1` | ✅ Direct mapping |
| `date_input/1` | `SaladUI.Input.input/1` (type="date") | ✅ Direct mapping |
| `time_select/1` | Custom implementation needed | ❌ No equivalent |
| `datetime_local_input/1` | `SaladUI.Input.input/1` (type="datetime-local") | ✅ Direct mapping |
| `telephone_input/1` | `SaladUI.Input.input/1` (type="tel") | ✅ Direct mapping |
| `error_tag/1` | `SaladUI.Form.form_message/1` | ✅ Direct mapping |

### 3.2 Form Integration Pattern

```elixir
# Current pattern
<.form :let={f} for={@changeset} phx-submit="save">
  <.text_input form={f} field={:name} />
  <.error_tag form={f} field={:name} />
</.form>

# SaladUI pattern
<.form :let={f} for={@changeset} phx-submit="save">
  <.form_item>
    <.form_label>Name</.form_label>
    <.input field={f[:name]} />
    <.form_message field={f[:name]} />
  </.form_item>
</.form>
```

---

## Phase 4: Layout & Navigation

### 4.1 Current Layout Structure

```
live.html.heex (302 lines)
├── Mobile backdrop (Alpine: x-show, x-transition)
├── Mobile sidebar drawer (Alpine: x-transition, @keydown.escape)
├── Desktop sidebar (hidden on mobile)
├── LayoutComponent (LiveComponent)
├── Mobile header (hamburger menu)
├── Flash messages
└── Main content area
```

### 4.2 SaladUI Sidebar Component

SaladUI provides a built-in Sidebar component that could replace the current implementation:

```elixir
# Example SaladUI Sidebar usage
<.sidebar_provider>
  <.sidebar>
    <.sidebar_header>
      <img src="/images/logo.svg" />
    </.sidebar_header>
    <.sidebar_content>
      <.sidebar_group>
        <.sidebar_group_content>
          <.sidebar_menu>
            <.sidebar_menu_item>
              <.sidebar_menu_button navigate="/home">
                <.icon name="home" /> Home
              </.sidebar_menu_button>
            </.sidebar_menu_item>
          </.sidebar_menu>
        </.sidebar_group_content>
      </.sidebar_group>
    </.sidebar_content>
  </.sidebar>
  <.sidebar_inset>
    <!-- Main content -->
  </.sidebar_inset>
</.sidebar_provider>
```

### 4.3 Navigation Migration

| Current | Target |
|---------|--------|
| `admin_tabs/1` | `SaladUI.Tabs` for desktop, `SaladUI.Sheet` for mobile |
| `admin_nav_mobile/1` (chips) | Keep as custom or use `SaladUI.Toggle_group` |
| `section_tabs/1` | `SaladUI.Tabs` with `tabs_list/1` |
| `nav_chip/1` | Custom - no direct equivalent |

---

## Phase 5: Icon System Migration

### 5.1 Current: Heroicons

```elixir
# Current usage
<.icon name={:home} outlined={true} class="w-6 h-6" />

# Implementation
apply(Heroicons.Outline, @name, [Map.to_list(@rest)])
```

### 5.2 Target: Lucide Icons (SaladUI default)

SaladUI uses Lucide icons by default. Options:

1. **Replace with Lucide** - Update all icon references
2. **Keep Heroicons** - Override SaladUI icon component
3. **Hybrid** - Support both libraries

```elixir
# SaladUI Lucide usage
<.icon name="home" class="w-6 h-6" />
```

### 5.3 Icon Name Mapping (Partial)

| Heroicons | Lucide |
|-----------|--------|
| `:home` | `"home"` |
| `:calendar` | `"calendar"` |
| `:cog` | `"settings"` |
| `:users` | `"users"` |
| `:x` | `"x"` |
| `:search` | `"search"` |
| `:presentation_chart_bar` | `"presentation"` |
| `:desktop_computer` | `"monitor"` |
| `:office_building` | `"building-2"` |
| `:document_text` | `"file-text"` |
| `:chart_bar` | `"bar-chart"` |
| `:cube` | `"box"` |

---

## Risk Assessment Matrix

| Component | Risk | Effort | Priority | Notes |
|-----------|------|--------|----------|-------|
| Phoenix/LiveView Upgrade | 🔴 HIGH | HIGH | P0 | Blocker for migration |
| Modal System | 🔴 HIGH | HIGH | P1 | Used in 15+ places |
| Form Components | 🟡 MEDIUM | MEDIUM | P2 | 20+ forms across app |
| Navigation/Layout | 🟡 MEDIUM | MEDIUM | P2 | AlpineJS dependency |
| Icon System | 🟢 LOW | LOW | P3 | Find-replace possible |
| Badge/Button | 🟢 LOW | LOW | P4 | Direct replacements |

---

## Implementation Checklist

### Phase 0: Pre-requisites
- [ ] **Evaluate LiveView upgrade path** (0.18 → 0.20+)
- [ ] **Evaluate Phoenix upgrade path** (1.6 → 1.7+)
- [ ] Create upgrade branch and test compatibility
- [ ] Run full test suite after upgrades
- [ ] Document breaking changes

### Phase 1: Foundation
- [ ] Add SaladUI dependency to mix.exs
- [ ] Run `mix salad.init --as-lib`
- [ ] Add TwMerge.Cache to application.ex
- [ ] Verify CSS integration with Tailwind
- [ ] Test single SaladUI component renders correctly

### Phase 2: Simple Components
- [ ] Migrate `.badge/1` → `SaladUI.Badge`
- [ ] Migrate `.button/1` → `SaladUI.Button`
- [ ] Migrate `.progress_bar/1` → `SaladUI.Progress`
- [ ] Update all call sites (grep for each component)
- [ ] Remove old component definitions

### Phase 3: Form Components
- [ ] Create compatibility layer or adapter
- [ ] Migrate text inputs
- [ ] Migrate select components
- [ ] Migrate checkbox/switch components
- [ ] Migrate date/time components
- [ ] Update error display pattern
- [ ] Test all forms end-to-end

### Phase 4: Complex Components
- [ ] Migrate `.modal/1` → `SaladUI.Dialog`
  - [ ] Update all modal invocations
  - [ ] Handle patch/navigate differences
  - [ ] Test keyboard navigation
  - [ ] Test focus management
- [ ] Migrate `.dropdown/1` → `SaladUI.DropdownMenu`
- [ ] Migrate `.flash/1` → `SaladUI.Alert` (or Toast)
- [ ] Migrate tables (`.table/1`, `.live_table/1`)

### Phase 5: Layout & Navigation
- [ ] Decide: Keep Alpine.js or migrate to SaladUI Sheet/Sidebar
- [ ] Migrate sidebar layout
- [ ] Migrate mobile drawer
- [ ] Migrate admin navigation tabs
- [ ] Test responsive behavior on all devices

### Phase 6: Cleanup
- [ ] Remove unused components from `live_helpers.ex`
- [ ] Remove unused components from `live_form_helpers.ex`
- [ ] Remove AlpineJS if fully migrated
- [ ] Update CLAUDE.md documentation
- [ ] Run full regression test

---

## Tricky Elements Deep Dive

### 1. Modal Component (HIGHEST COMPLEXITY) 🚨

**Current implementation** (`live_helpers.ex:545-625`):
- Custom focus trap via `focus_wrap`
- JS-driven show/hide with transitions
- Supports both `patch` and `navigate` return paths
- Escape key handling
- Complex slot system: `:title`, `:confirm`, `:cancel`

**Challenges:**
- SaladUI `Dialog` has different API
- Focus management differs
- Transition timing may not match
- Button slot attributes need remapping

**Migration Strategy:**
1. Create adapter component wrapping SaladUI.Dialog
2. Map slot attributes to SaladUI equivalents
3. Test each modal usage site
4. Consider keeping custom modal for complex cases

### 2. Card List Component (UNIQUE) 🚨

**Current implementation** (`live_helpers.ex:774-813`):
- Renders as cards on mobile (vertical)
- Renders as table on desktop (horizontal)
- Same data, different presentations

**Challenge:** No SaladUI equivalent exists.

**Strategy:** Keep custom or rebuild using:
- `SaladUI.Card` for mobile view
- `SaladUI.Table` for desktop view
- Wrap in responsive container

### 3. AlpineJS Dependency 🚨

**Current usage in `live.html.heex`:**
```html
<div x-data="{ sidebarOpen: false }">
  <div x-show="sidebarOpen" x-transition:enter="..." @click="sidebarOpen = false">
  <button @click="sidebarOpen = true">
```

**Options:**
1. **Keep Alpine.js** - Coexist with SaladUI (adds ~15kb)
2. **Replace with LiveView JS** - Use `Phoenix.LiveView.JS` commands
3. **Use SaladUI Sheet/Sidebar** - Built-in mobile drawer

### 4. Icon System Mismatch

**Current:** Heroicons (outline/solid variants)
**SaladUI Default:** Lucide icons

**Strategy:**
1. Create icon mapping module
2. Override SaladUI icon component to use Heroicons
3. Or migrate all icon references to Lucide names

---

## File-by-file Impact Analysis

| File | Impact | Changes Required |
|------|--------|------------------|
| `live_helpers.ex` | 🔴 MAJOR | ~50% rewrite, many components deprecated |
| `live_form_helpers.ex` | 🟡 MODERATE | ~60% rewrite, new form patterns |
| `live.html.heex` | 🟡 MODERATE | Layout restructure, remove Alpine.js |
| `app.html.heex` | 🟢 MINOR | CSS/JS imports |
| `root.html.heex` | 🟢 MINOR | CSS/JS imports |
| `*_live.ex` files (25+) | 🟡 MODERATE | Update component calls |
| `*_row_component.ex` (4) | 🟢 MINOR | Table cell updates |
| Email templates (12) | ⚪ NONE | No component usage |

---

## Rollback Plan

If migration causes issues:

1. Keep `live_helpers.ex` and `live_form_helpers.ex` intact
2. Add SaladUI components with different names (e.g., `.salad_button`)
3. Gradually migrate page by page
4. Remove old components only after full verification

---

## Timeline Estimate

| Phase | Duration | Dependencies |
|-------|----------|--------------|
| Pre-requisites (upgrade) | 1-2 weeks | None |
| Phase 1: Foundation | 2-3 days | Pre-requisites complete |
| Phase 2: Simple components | 1 week | Phase 1 |
| Phase 3: Form components | 1 week | Phase 1 |
| Phase 4: Complex components | 1-2 weeks | Phases 2, 3 |
| Phase 5: Layout | 1 week | Phase 4 |
| Phase 6: Cleanup | 2-3 days | All above |

**Total Estimated Time:** 5-8 weeks (including framework upgrades)

---

## Current Progress

- [x] Analyze current component library
- [x] Research SaladUI component availability
- [x] Identify compatibility blockers (LiveView version)
- [x] Create component mapping
- [x] Document tricky elements
- [x] Create implementation checklist
- [ ] **NEXT:** Decide on migration approach (full upgrade vs partial adoption)
- [ ] Begin Phoenix/LiveView upgrade if proceeding

---

*Last Updated: 2024-12-21*
*Status: Planning Complete - Awaiting Decision on Approach*
