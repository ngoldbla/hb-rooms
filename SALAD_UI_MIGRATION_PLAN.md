# SaladUI Wholesale Migration Plan

> **Project:** Hatchbridge Rooms (Overbooked)
> **Current Stack:** Phoenix 1.7.14 + LiveView 0.20.17 + Tailwind CSS + AlpineJS
> **Target:** SaladUI v1.0.0-beta (shadcn-inspired Phoenix components)
> **Branch:** `claude/upgrade-salad-ui-7UcQL`

---

## Executive Summary

This document details a **wholesale migration** from the current custom component library to SaladUI. The migration affects:

- **991 lines** in `live_helpers.ex` (46+ components)
- **445 lines** in `live_form_helpers.ex` (13 form components)
- **33 LiveView pages/components**
- **60+ modal instances**
- **302+ lines** of layout templates

### Prerequisites (COMPLETED)

| Requirement | Status | Version |
|-------------|--------|---------|
| Phoenix | ✅ Done | 1.7.14 |
| LiveView | ✅ Done | 0.20.17 |
| Ecto | ✅ Done | 3.11+ |
| phoenix_html | ✅ Done | 4.0 |

---

## Phase 1: Foundation Setup

**Goal:** Install SaladUI and verify it works alongside existing components.

### 1.1 Add Dependencies

```elixir
# mix.exs - add to deps
{:salad_ui, "~> 1.0.0-beta.3"}
```

### 1.2 Initialize SaladUI

```bash
mix deps.get
mix salad.init --as-lib
```

This will:
- Modify `tailwind.config.js` with SaladUI plugin
- Add CSS custom properties to `assets/css/app.css`
- Create component stubs (or use library mode)

### 1.3 Application Setup

Add to `lib/overbooked/application.ex` children:

```elixir
{TwMerge.Cache, []}
```

### 1.4 Keep Heroicons

Override SaladUI's default Lucide icons by creating a wrapper or configuring the icon component to use Heroicons. SaladUI's icon component can be customized.

### 1.5 Verification Test

Create a simple test page that renders one SaladUI component to verify setup:

```elixir
# In any LiveView
<SaladUI.Button.button>Test Button</SaladUI.Button.button>
```

### Files Modified (Phase 1)
- `mix.exs`
- `lib/overbooked/application.ex`
- `tailwind.config.js`
- `assets/css/app.css`

---

## Phase 2: Component Module Structure

**Goal:** Create the import/alias structure for SaladUI components.

### 2.1 Create Components Module

Create `lib/overbooked_web/components/ui.ex`:

```elixir
defmodule OverbookedWeb.Components.UI do
  @moduledoc """
  SaladUI component imports for use across the application.
  """

  defmacro __using__(_) do
    quote do
      # SaladUI Components
      import SaladUI.Button
      import SaladUI.Input
      import SaladUI.Textarea
      import SaladUI.Select
      import SaladUI.Checkbox
      import SaladUI.Switch
      import SaladUI.Badge
      import SaladUI.Progress
      import SaladUI.Alert
      import SaladUI.Dialog
      import SaladUI.DropdownMenu
      import SaladUI.Tabs
      import SaladUI.Table
      import SaladUI.Card
      import SaladUI.Sheet
      import SaladUI.Form
      import SaladUI.Label
      import SaladUI.Separator
      import SaladUI.Tooltip

      # Keep custom components that have no SaladUI equivalent
      import OverbookedWeb.Components.Custom
    end
  end
end
```

### 2.2 Create Custom Components Module

Create `lib/overbooked_web/components/custom.ex` for components we're keeping:

```elixir
defmodule OverbookedWeb.Components.Custom do
  @moduledoc """
  Custom components with no SaladUI equivalent.
  """
  use Phoenix.Component

  # Move these from live_helpers.ex:
  # - card_list/1 (responsive card/table hybrid)
  # - live_table/1 (LiveComponent table)
  # - relative_time/1
  # - from_to_datetime/1
  # - icon/1 (Heroicons wrapper)
end
```

### 2.3 Update LiveView Helper

Modify `lib/overbooked_web.ex` to include new components:

```elixir
defp html_helpers do
  quote do
    # ... existing imports ...
    use OverbookedWeb.Components.UI
  end
end
```

---

## Phase 3: Simple Components Migration

**Goal:** Replace low-risk components with direct SaladUI equivalents.

### 3.1 Badge Component

| Current | SaladUI | Notes |
|---------|---------|-------|
| `.badge/1` | `SaladUI.Badge.badge/1` | Color mapping needed |

**Current variants:** `:default`, `:success`, `:warning`, `:danger`, `:gray`

**SaladUI variants:** `default`, `secondary`, `destructive`, `outline`

**Migration:**
```elixir
# Before
<.badge variant={:success}>Active</.badge>

# After
<.badge variant="default">Active</.badge>  # or create color mapping
```

**Files affected:** 8 files use `.badge`

### 3.2 Button Component

| Current | SaladUI | Notes |
|---------|---------|-------|
| `.button/1` | `SaladUI.Button.button/1` | Variant + size mapping |

**Current variants:** `:primary`, `:secondary`, `:danger`, `:white`
**Current sizes:** `:base`, `:small`, `:narrow`

**SaladUI variants:** `default`, `destructive`, `outline`, `secondary`, `ghost`, `link`
**SaladUI sizes:** `default`, `sm`, `lg`, `icon`

**Mapping:**
```elixir
:primary   → "default"
:secondary → "secondary"
:danger    → "destructive"
:white     → "outline"
```

**Special case:** Current button supports `patch` attribute for link behavior. SaladUI button is pure button. Need to handle this with conditional rendering or keep a wrapper.

**Files affected:** 25+ files use `.button`

### 3.3 Progress Bar

| Current | SaladUI |
|---------|---------|
| `.progress_bar/1` | `SaladUI.Progress.progress/1` |

Direct replacement with same API.

### 3.4 Spinner

Keep custom or use SaladUI's built-in button loading state.

---

## Phase 4: Form Components Migration

**Goal:** Replace all form inputs with SaladUI equivalents.

### 4.1 Component Mapping

| Current (LiveFormHelpers) | SaladUI | Status |
|---------------------------|---------|--------|
| `text_input/1` | `SaladUI.Input.input/1` | Direct |
| `email_input/1` | `input type="email"` | Direct |
| `password_input/1` | `input type="password"` | Direct |
| `number_input/1` | `input type="number"` | Direct |
| `date_input/1` | `input type="date"` | Direct |
| `time_input/1` | `input type="time"` | Direct |
| `datetime_local_input/1` | `input type="datetime-local"` | Direct |
| `search_input/1` | `input type="search"` | Direct |
| `telephone_input/1` | `input type="tel"` | Direct |
| `url_input/1` | `input type="url"` | Direct |
| `textarea/1` | `SaladUI.Textarea.textarea/1` | Direct |
| `select/1` | `SaladUI.Select` | Complex - different API |
| `checkbox/1` | `SaladUI.Checkbox.checkbox/1` | Direct |
| `checkbox_group/1` | Custom implementation | Keep custom |
| `radio/1` | `SaladUI.RadioGroup` | Needs wrapper |
| `switch/1` | `SaladUI.Switch.switch/1` | Direct |
| `error/1` | `SaladUI.Form.form_message/1` | Direct |

### 4.2 Form Pattern Change

**Current pattern:**
```heex
<.form :let={f} for={@changeset} phx-submit="save">
  <.text_input form={f} field={:name} label="Name" />
</.form>
```

**SaladUI pattern:**
```heex
<.form :let={f} for={@changeset} phx-submit="save">
  <.form_item>
    <.form_label>Name</.form_label>
    <.input field={f[:name]} type="text" />
    <.form_message field={f[:name]} />
  </.form_item>
</.form>
```

**Decision needed:** Create adapter that mimics current API, or update all form call sites?

**Recommendation:** Create a compatibility layer in `custom.ex` that wraps SaladUI components with the current API. This allows gradual migration.

### 4.3 Select Component (Complex)

SaladUI Select has a very different structure:

```heex
<.select>
  <.select_trigger>
    <.select_value placeholder="Select..." />
  </.select_trigger>
  <.select_content>
    <.select_item value="opt1">Option 1</.select_item>
    <.select_item value="opt2">Option 2</.select_item>
  </.select_content>
</.select>
```

**Strategy:** Keep current `select/1` as custom component OR create wrapper that transforms options list to SaladUI structure.

### Files Affected (Phase 4)
- `live_form_helpers.ex` → refactor/replace
- 25+ LiveView files with forms
- All admin pages
- User settings pages
- Booking forms

---

## Phase 5: Modal → Dialog Migration

**Goal:** Replace custom modal with SaladUI Dialog.

### 5.1 Current Modal Architecture

```elixir
# Current modal features:
- Focus trap via focus_wrap
- Escape key handling (phx-key="escape")
- Backdrop click to close
- Animated show/hide (fade-in, fade-in-scale)
- patch/navigate on close
- Slots: :title, :confirm, :cancel
- Confirm slot attributes: patch, size, form, type, variant, disabled
```

### 5.2 SaladUI Dialog Structure

```heex
<.dialog>
  <.dialog_trigger>
    <.button>Open</.button>
  </.dialog_trigger>
  <.dialog_content>
    <.dialog_header>
      <.dialog_title>Title</.dialog_title>
      <.dialog_description>Description</.dialog_description>
    </.dialog_header>
    <!-- Content here -->
    <.dialog_footer>
      <.button variant="outline">Cancel</.button>
      <.button>Confirm</.button>
    </.dialog_footer>
  </.dialog_content>
</.dialog>
```

### 5.3 Migration Strategy

**Option A: Create Compatibility Wrapper**

Create `modal/1` component that wraps SaladUI Dialog but maintains current API:

```elixir
def modal(assigns) do
  ~H"""
  <.dialog open={@show}>
    <.dialog_content>
      <.dialog_header>
        <.dialog_title><%= render_slot(@title) %></.dialog_title>
      </.dialog_header>
      <%= render_slot(@inner_block) %>
      <.dialog_footer>
        <%= for cancel <- @cancel do %>
          <.button variant="outline" phx-click={@on_cancel}>
            <%= render_slot(cancel) %>
          </.button>
        <% end %>
        <%= for confirm <- @confirm do %>
          <.button phx-click={@on_confirm} {assigns_to_attributes(confirm)}>
            <%= render_slot(confirm) %>
          </.button>
        <% end %>
      </.dialog_footer>
    </.dialog_content>
  </.dialog>
  """
end
```

**Option B: Full Migration**

Update all 60+ modal call sites to use new Dialog API.

**Recommendation:** Option A - Create wrapper to minimize disruption, then gradually migrate individual modals if desired.

### 5.4 Modal Usage Locations (60+ instances)

**Admin Pages:**
- `admin_users_live.ex` - 3 modals (add, edit, delete)
- `admin_rooms_live.ex` - 3 modals per resource type
- `admin_desks_live.ex` - 3 modals
- `admin_amenities_live.ex` - 3 modals
- `admin_spaces_live.ex` - 3 modals
- `admin_contracts_live.ex` - 2 modals
- `admin_settings_live.ex` - 2 modals
- `admin_email_templates_live.ex` - 1 modal

**Row Components (LiveComponent with inline modals):**
- `resource_row_component.ex` - 3 modals per row
- `amenity_row_component.ex` - 2 modals per row
- `contract_row_component.ex` - 1 modal per row
- `space_row_component.ex` - 3 modals per row

**User Pages:**
- `home_live.ex` - 2 modals
- `spaces_live.ex` - 1 modal (checkout)
- `contracts_live.ex` - 1 modal

**JS Functions to Replace:**
- `show_modal/1` → SaladUI's built-in trigger or custom JS
- `hide_modal/1` → Dialog's close mechanism

---

## Phase 6: Tab System Migration

**Goal:** Replace both tab systems with SaladUI Tabs.

### 6.1 Admin Navigation Tabs

**Current implementation:** 3-tier responsive system
- Mobile: Horizontal scrollable chips
- Tablet: Vertical sidebar
- Desktop: Horizontal tabs

**SaladUI approach:** Use Tabs + Sheet combination

```heex
<!-- Desktop/Tablet -->
<.tabs default_value="users" orientation="vertical" class="hidden sm:flex">
  <.tabs_list>
    <.tabs_trigger value="users">Users</.tabs_trigger>
    <.tabs_trigger value="rooms">Rooms</.tabs_trigger>
    <!-- ... -->
  </.tabs_list>
</.tabs>

<!-- Mobile -->
<.sheet>
  <.sheet_trigger>
    <.button variant="outline" size="icon">
      <.icon name={:bars_3} />
    </.button>
  </.sheet_trigger>
  <.sheet_content side="left">
    <!-- Navigation items -->
  </.sheet_content>
</.sheet>
```

**Decision:** The current admin navigation is complex with grouping (Users, Resources→Rooms/Desks/Amenities, etc.). May need custom implementation using SaladUI primitives.

### 6.2 Section Tabs

**Current:** Pills-style sub-navigation

```heex
<.section_tabs active_tab={@active_tab} tabs={[
  %{id: :admin_rooms, label: "Rooms", path: route},
  %{id: :admin_desks, label: "Desks", path: route}
]}/>
```

**SaladUI:**
```heex
<.tabs default_value={@active_tab}>
  <.tabs_list>
    <.tabs_trigger value="rooms" as_child>
      <.link navigate={route}>Rooms</.link>
    </.tabs_trigger>
  </.tabs_list>
</.tabs>
```

### Files Affected (Phase 6)
- `live_helpers.ex` (admin_tabs, section_tabs, nav_chip, nav_link, desktop_tab)
- All 9 admin pages
- `live.html.heex` layout

---

## Phase 7: Dropdown Migration

**Goal:** Replace custom dropdown with SaladUI DropdownMenu.

### 7.1 Current Dropdown

```heex
<.dropdown id="user-dropdown">
  <:img src={avatar_url} />
  <:title>User Name</:title>
  <:subtitle>user@email.com</:subtitle>
  <:link navigate={settings_path}>Settings</:link>
  <:link href={logout_path} method={:delete}>Log out</:link>
</.dropdown>
```

### 7.2 SaladUI DropdownMenu

```heex
<.dropdown_menu>
  <.dropdown_menu_trigger>
    <.button variant="ghost">
      <img src={avatar_url} />
      <span>User Name</span>
    </.button>
  </.dropdown_menu_trigger>
  <.dropdown_menu_content>
    <.dropdown_menu_label>user@email.com</.dropdown_menu_label>
    <.dropdown_menu_separator />
    <.dropdown_menu_item>
      <.link navigate={settings_path}>Settings</.link>
    </.dropdown_menu_item>
    <.dropdown_menu_item>
      <.link href={logout_path} method={:delete}>Log out</.link>
    </.dropdown_menu_item>
  </.dropdown_menu_content>
</.dropdown_menu>
```

### Files Affected
- `live_helpers.ex` (dropdown, show_dropdown, hide_dropdown)
- `live.html.heex` (user dropdown in sidebar)

---

## Phase 8: Table Components

**Goal:** Style tables with SaladUI Table components.

### 8.1 Static Table

**Current:** Custom `.table/1` component

**SaladUI:**
```heex
<.table>
  <.table_header>
    <.table_row>
      <.table_head>Column</.table_head>
    </.table_row>
  </.table_header>
  <.table_body>
    <.table_row :for={item <- @items}>
      <.table_cell><%= item.name %></.table_cell>
    </.table_row>
  </.table_body>
</.table>
```

### 8.2 Live Table (Keep Custom)

The `live_table/1` component renders LiveComponent rows. This pattern doesn't have a SaladUI equivalent. Keep as custom component but apply SaladUI table styling.

### 8.3 Card List (Keep Custom)

No SaladUI equivalent for the responsive card/table hybrid. Keep as custom component.

---

## Phase 9: Layout & Navigation

**Goal:** Migrate layout to use SaladUI components while keeping functionality.

### 9.1 Current Layout Structure

```
live.html.heex (302 lines)
├── Alpine x-data="{ sidebarOpen: false }"
├── Mobile backdrop (x-show, x-transition)
├── Mobile sidebar drawer (x-transition, @keydown.escape)
├── Desktop sidebar
├── Mobile header (hamburger)
├── Flash messages
└── Main content
```

### 9.2 Migration Options

**Option A: Keep AlpineJS**
- Least disruptive
- Continue using x-show, x-transition
- Just update component styling

**Option B: Replace with SaladUI Sheet**
```heex
<.sidebar_provider>
  <.sheet>
    <.sheet_trigger class="lg:hidden">
      <.button variant="ghost" size="icon">
        <.icon name={:bars_3} />
      </.button>
    </.sheet_trigger>
    <.sheet_content side="left">
      <!-- Mobile nav -->
    </.sheet_content>
  </.sheet>

  <.sidebar class="hidden lg:flex">
    <!-- Desktop nav -->
  </.sidebar>

  <main>
    <%= @inner_content %>
  </main>
</.sidebar_provider>
```

**Option C: Replace with Phoenix.LiveView.JS**
- Remove AlpineJS dependency
- Use `JS.toggle()`, `JS.show()`, `JS.hide()` with transitions
- Native to Phoenix, no extra library

**Recommendation:** Option A for initial migration (keep Alpine), then Option C as follow-up to remove Alpine dependency.

### 9.3 Flash Messages → Alert

```heex
# Before
<.flash kind={:info} title="Success" flash={@flash} />

# After
<.alert :if={info = Phoenix.Flash.get(@flash, :info)}>
  <.alert_title>Info</.alert_title>
  <.alert_description><%= info %></.alert_description>
</.alert>
```

---

## Phase 10: Calendar/Schedule Pages

**Goal:** Update calendar UI to use SaladUI styling while preserving functionality.

### 10.1 Calendar Components Analysis

**Files:**
- `calendar_live.ex` - Core calendar (weekly/monthly views)
- `schedule_weekly_live.ex` - Weekly schedule page
- `schedule_monthly_live.ex` - Monthly schedule page
- `booking_form_live.ex` - Booking form LiveComponent

### 10.2 Calendar-Specific Components Used

| Component | Current | Migration |
|-----------|---------|-----------|
| Resource selector | Custom dropdown | SaladUI Select |
| Navigation buttons | `.button` | SaladUI Button |
| Date display | Custom | Keep (no equivalent) |
| Time grid | Custom CSS | Keep (no equivalent) |
| Booking cards | Custom | Keep with updated styling |
| Recurring toggle | Custom form | SaladUI Switch + Form |
| Day selector | Custom checkboxes | SaladUI Checkbox or ToggleGroup |
| Booking info modal | `.modal` | SaladUI Dialog |

### 10.3 Calendar Grid (No Migration Needed)

The calendar grid is custom HTML/CSS:
- Weekly: 7-column grid with hourly rows
- Monthly: Day cells with booking badges
- Time slots: 15-minute increments

**Keep as-is.** Just update colors to match SaladUI theme.

### 10.4 Booking Form Migration

Current form uses:
- `text_input` → SaladUI Input
- `date_input` → SaladUI Input type="date"
- `time_input` → SaladUI Input type="time" (or keep custom time_select)
- `select` → SaladUI Select
- `checkbox` → SaladUI Checkbox
- `switch` → SaladUI Switch

**Recurring booking UI:**
```heex
# Pattern toggle
<.switch field={f[:recurring]} label="Repeat" />

# Pattern select (when recurring enabled)
<.select field={f[:pattern]}>
  <.select_trigger>
    <.select_value placeholder="Select pattern" />
  </.select_trigger>
  <.select_content>
    <.select_item value="daily">Daily</.select_item>
    <.select_item value="weekly">Weekly</.select_item>
    <.select_item value="biweekly">Bi-weekly</.select_item>
    <.select_item value="monthly">Monthly</.select_item>
  </.select_content>
</.select>

# Days of week (for weekly pattern)
<.toggle_group type="multiple" value={@selected_days}>
  <.toggle_group_item value="1">M</.toggle_group_item>
  <.toggle_group_item value="2">T</.toggle_group_item>
  <!-- ... -->
</.toggle_group>
```

### 10.5 Calendar Migration Steps

1. Update buttons to SaladUI Button
2. Update resource selector to SaladUI Select
3. Update booking info modal to SaladUI Dialog
4. Update booking form inputs to SaladUI Form components
5. Keep calendar grid structure, update CSS variables for theming
6. Keep booking card styling, update to use SaladUI colors

---

## Phase 11: Cleanup & Removal

### 11.1 Files to Remove/Refactor

| File | Action |
|------|--------|
| `live_helpers.ex` | Refactor - keep only custom components |
| `live_form_helpers.ex` | Remove - replaced by SaladUI |

### 11.2 Components to Keep in Custom

- `card_list/1` - No SaladUI equivalent
- `live_table/1` - LiveComponent pattern
- `relative_time/1` - Formatting helper
- `from_to_datetime/1` - Formatting helper
- `icon/1` - Heroicons wrapper (or integrate with SaladUI)
- `checkbox_group/1` - If SaladUI doesn't have equivalent

### 11.3 AlpineJS Decision

**If keeping:** No changes needed
**If removing:** Replace x-data/x-show with Phoenix.LiveView.JS

### 11.4 CSS Cleanup

- Remove custom component CSS that's replaced by SaladUI
- Keep calendar-specific CSS
- Update CSS custom properties to match SaladUI theme

---

## Implementation Order

### Wave 1: Foundation (Low Risk)
1. Phase 1: Foundation Setup
2. Phase 2: Component Module Structure
3. Phase 3: Simple Components (Badge, Button, Progress)

### Wave 2: Forms (Medium Risk)
4. Phase 4: Form Components

### Wave 3: Interactive Components (Higher Risk)
5. Phase 5: Modal → Dialog
6. Phase 6: Tab System
7. Phase 7: Dropdown

### Wave 4: Structure (Medium Risk)
8. Phase 8: Table Components
9. Phase 9: Layout & Navigation

### Wave 5: Calendar (Medium Risk)
10. Phase 10: Calendar/Schedule Pages

### Wave 6: Cleanup
11. Phase 11: Cleanup & Removal

---

## Testing Strategy

### Per-Phase Testing

| Phase | Test Focus |
|-------|------------|
| 1-2 | App compiles, single component renders |
| 3 | Visual regression on badges, buttons |
| 4 | All forms submit correctly, validation works |
| 5 | Modals open/close, form submission through modal |
| 6 | Navigation works, active states correct |
| 7 | Dropdowns open/close, links work |
| 8 | Tables render, sorting works (if applicable) |
| 9 | Mobile/desktop layout, sidebar toggle |
| 10 | Booking creation, calendar navigation |

### Manual QA Checklist

- [ ] User can log in
- [ ] User can view/create/edit/delete bookings
- [ ] User can browse rooms/desks/spaces
- [ ] Admin can manage all resources
- [ ] Admin can view analytics
- [ ] Admin can edit settings
- [ ] Mobile layout works on iOS Safari
- [ ] Mobile layout works on Android Chrome
- [ ] All modals open and close correctly
- [ ] All forms submit and show validation errors
- [ ] Flash messages appear and auto-dismiss

---

## Rollback Strategy

### Per-Phase Rollback

Each phase should be a separate commit or set of commits. If issues arise:

1. **Identify failing phase**
2. **Git revert** the phase commits
3. **Investigate** root cause
4. **Fix and re-apply** or adjust approach

### Parallel Components Strategy

During migration, keep both old and new components available:

```elixir
# Old component (temporary prefix)
def legacy_button(assigns), do: ...

# New component (SaladUI)
def button(assigns), do: ...
```

This allows gradual migration without breaking existing pages.

---

## File Impact Summary

### High Impact (Major Changes)
- `lib/overbooked_web/live/live_helpers.ex` - ~70% rewrite
- `lib/overbooked_web/live/live_form_helpers.ex` - Remove or 100% rewrite
- `lib/overbooked_web/templates/layout/live.html.heex` - Layout restructure

### Medium Impact (Moderate Changes)
- All 9 admin LiveView pages - component call updates
- All 4 row components - modal/form updates
- `calendar_live.ex` - form and button updates
- `booking_form_live.ex` - form component updates
- User pages (home, spaces, contracts) - modal/form updates

### Low Impact (Minor Changes)
- Auth pages - form styling only
- `router.ex` - no changes
- Context modules - no changes
- JS hooks - no changes (keep charts.js, flash.js, focus.js)

---

## Open Questions

1. **Select Component:** Create wrapper for current API or migrate all call sites?
2. **Form Pattern:** Compatibility layer or full migration?
3. **AlpineJS:** Keep for now or remove as part of migration?
4. **Icon System:** Create Heroicons adapter for SaladUI or keep separate icon component?
5. **Admin Navigation:** Use SaladUI Tabs or keep custom due to complexity?

---

## Estimated Effort

| Phase | Effort | Risk |
|-------|--------|------|
| 1-2: Foundation | 1 day | Low |
| 3: Simple Components | 1 day | Low |
| 4: Form Components | 2-3 days | Medium |
| 5: Modal → Dialog | 2-3 days | High |
| 6: Tab System | 2 days | Medium |
| 7: Dropdown | 1 day | Low |
| 8: Tables | 1 day | Low |
| 9: Layout | 2 days | Medium |
| 10: Calendar | 2 days | Medium |
| 11: Cleanup | 1 day | Low |

**Total: ~15-18 days** (not including framework upgrade, which is done)

---

*Created: 2024-12-22*
*Status: Planning - Awaiting Approval*
