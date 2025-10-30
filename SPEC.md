# history-api.nvim - Specification

This document defines the behavior and interfaces of the history-api.nvim plugin using a 2-level hierarchy:
- **Level 1**: Stories with interfaces and internal interactions
- **Level 2**: Exposed methods with Gherkin scenarios

---

## Type Definitions

```lua
BrowserInfo = {
  browser: string,      -- Browser key (e.g., "firefox", "chrome")
  name: string,         -- Display name (e.g., "Firefox")
  db_path: string,      -- Path to database file
  profile_dir: string   -- Path to browser profile directory
}

HistoryItem = {
  title: string,        -- Page title
  url: string,          -- Page URL
  date: string,         -- Visit date (ISO 8601 format)
  browser: string       -- Browser key
}

BookmarkItem = {
  folder: string,       -- Bookmark folder name
  title: string,        -- Bookmark title
  url: string,          -- Bookmark URL
  date: string,         -- Date added (ISO 8601 format)
  browser: string       -- Browser key
}
```

---

## Story 1: Installing the Plugin

### Interfaces

**Public:**
- `setup(opts)` - Initialize the plugin

**Internal Interactions:**
```
setup()
  → state.set_config()              # Store user configuration
  → state.register_provider()       # Register firefox & chromium providers
  → detect.add_custom_browsers()    # If custom browsers provided
```

### Exposed Methods

#### Method: `setup(opts)`

**Purpose:** Initialize the history-api plugin with optional configuration

**Signature:**
```lua
function setup(opts?: table): void
```

**Scenarios:**

```gherkin
Scenario: Install with default configuration
  When I call setup()
  Then firefox and chromium providers are registered
  And default browser detection paths are used

Scenario: Install with custom Firefox path
  When I call setup({ browsers = { firefox = { profile_dirs = {"/custom/path"} } } })
  Then firefox detection uses "/custom/path"
  And default paths are overridden

Scenario: Install with custom browser
  When I call setup({ browsers = { my_browser = { name = "My Browser", profile_dirs = {"~/my-browser"}, db_file = "history.db" } } })
  Then chromium provider handles "my_browser"
  And I can query it via retrieve.history("my_browser")

Scenario: Setup fails without sqlite.lua
  Given sqlite.lua is not installed
  When I call setup()
  Then an error is raised mentioning "sqlite.lua" with installation URL
```

---

## Story 2: Implementing User Command to Query a Provider

### Interfaces

**Public:**
- `retrieve.history(browser, opts)` - Get history from a browser
- `retrieve.bookmarks(browser, opts)` - Get bookmarks from a browser
- `retrieve.browsers()` - List all detected browsers

**Internal Interactions:**
```
retrieve.history(browser_key)
  → detect.detect(browser_key)        # Validate browser exists
  → state.get_provider(browser_key)   # Get SQL provider
  → provider.get_history(db_path)     # Query database
  → util.query_db(db_path, sql)       # Execute via sqlite.lua
```

### Exposed Methods

#### Method: `retrieve.history(browser, opts)`

**Purpose:** Retrieve browsing history from a specific browser

**Signature:**
```lua
function retrieve.history(
  browser: string | BrowserInfo,
  opts?: { limit?: number }
): (HistoryItem[] | nil, string | nil)
```

**Scenarios:**

```gherkin
Scenario: Get Firefox history with default limit
  When I call retrieve.history("firefox")
  Then I receive history items (title, url, date, browser)
  And at most 1000 items, ordered by date descending

Scenario: Get Firefox history with custom limit
  When I call retrieve.history("firefox", { limit = 50 })
  Then I receive exactly 50 items, ordered by date descending

Scenario: Query using browser string vs object
  When I call retrieve.history("chrome", { limit = 100 })
  Then browser is detected automatically

  When I call retrieve.history(detect.detect("firefox"), { limit = 100 })
  Then browser detection is skipped

Scenario: Handle missing browser or provider
  When I call retrieve.history() with invalid browser
  Then I receive (nil, error_message)

  Examples:
    | browser           | error_pattern      |
    | "firefox"         | "not found"        |
    | "unknown_browser" | "No provider"      |

Scenario: Create user command to list recent history
  When I create :FirefoxHistory command
  Then executing it shows 20 recent entries as "date - title"

  Example implementation:
    local history, err = api.retrieve.history("firefox", { limit = 20 })
    if not history then return print("Error: " .. err) end
    for _, item in ipairs(history) do
      print(string.format("%s - %s", item.date, item.title))
    end
```

#### Method: `retrieve.bookmarks(browser, opts)`

**Purpose:** Retrieve bookmarks from a specific browser

**Signature:**
```lua
function retrieve.bookmarks(
  browser: string | BrowserInfo,
  opts?: { limit?: number }
): (BookmarkItem[] | nil, string | nil)
```

**Scenarios:**

```gherkin
Scenario: Get Firefox bookmarks
  When I call retrieve.bookmarks("firefox", { limit = 100 })
  Then I receive bookmark items (folder, title, url, date, browser)
  And items are ordered by date descending

Scenario: Handle Chromium bookmark limitation
  When I call retrieve.bookmarks("chrome")
  Then I receive (nil, error about JSON file storage)
  And error mentions Bookmarks file location

Scenario: Create user command to search bookmarks
  When I create :SearchBookmarks command with keyword argument
  Then executing it filters bookmarks by title

  Example implementation:
    local bookmarks, err = api.retrieve.bookmarks("firefox")
    if not bookmarks then return print("Error: " .. err) end
    for _, item in ipairs(bookmarks) do
      if item.title:lower():match(keyword:lower()) then
        print(string.format("[%s] %s - %s", item.folder, item.title, item.url))
      end
    end
```

#### Method: `retrieve.browsers()`

**Purpose:** List all detected browsers on the system

**Signature:**
```lua
function retrieve.browsers(): BrowserInfo[]
```

**Scenarios:**

```gherkin
Scenario: List all detected browsers
  Given Firefox is at ~/.mozilla/firefox
  And Chrome is at ~/.config/google-chrome
  When I call retrieve.browsers()
  Then I receive 2 browser info objects (Firefox and Chrome)

Scenario: No browsers detected
  When I call retrieve.browsers() with no browsers installed
  Then I receive an empty list

Scenario: Create user command to show detected browsers
  When I create :ListBrowsers command
  Then executing it displays browser names and database paths

  Example implementation:
    local browsers = api.retrieve.browsers()
    if #browsers == 0 then return print("No browsers detected") end
    print("Detected browsers:")
    for _, browser in ipairs(browsers) do
      print(string.format("  %s: %s", browser.name, browser.db_path))
    end
```

---

## Story 3: Advanced User Command - Interactive History Picker

### Interfaces

**Public:**
- `retrieve.history(browser, opts)` - Get history from browser
- `retrieve.browsers()` - List all browsers

**Internal Interactions:**
```
User Command (Snacks Picker Integration)
  → retrieve.browsers()              # Get all available browsers
  → retrieve.history(browser, opts)  # For each browser
  → Aggregate results into picker
  → User selects item
  → Open URL with xdg-open/open
```

### Exposed Methods

**Note:** This story reuses methods from Story 2 but demonstrates advanced Snacks picker integration.

**Scenarios:**

```gherkin
Scenario: Create Snacks picker for browser history
  When I create a Snacks picker with history items
  Then I can fuzzy search and press Enter to open URLs

  Key integration points:
    • Get data: api.retrieve.history("firefox", { limit = 500 })
    • Transform: item.text = date + title + url
    • Format: Return array of {text, highlight_group} tuples
    • Confirm: vim.fn.system({ "xdg-open", item.url })

Scenario: Add custom keybindings for URL actions
  When I create a picker with custom keybindings
  Then I can perform multiple actions on URLs
  And <C-y> yanks URLs to clipboard
  And <C-i> inserts URLs into current buffer at cursor

  Key integration points:
    • win.input.keys: { ["<C-y>"] = { "yank_url", ... }, ["<C-i>"] = { "insert_url", ... } }
    • actions.yank_url: Get selected items, yank URLs, notify user
    • actions.insert_url: Get selected items, insert at cursor, close picker
    • Multi-selection: picker:selected({ fallback = true })
    • Buffer insertion: vim.api.nvim_put(lines, "c", true, true)

Scenario: Aggregate history from multiple browsers
  When I create a picker showing all browser history
  Then I see combined results sorted by date with browser tags

  Key integration points:
    • Loop: for _, browser in ipairs(api.retrieve.browsers())
    • Tag: item.browser_name = browser.name
    • Sort: table.sort(all_history, fn(a,b) a.date > b.date)
    • Format: Show date, browser name, title, URL columns
```

### Full Implementation Examples

See [examples/snacks-picker.lua](examples/snacks-picker.lua) for complete working code.

---

## Story 4: Multi-Browser Bookmarks Picker

### Interfaces

**Public:**
- `retrieve.bookmarks(browser, opts)` - Get bookmarks from browser
- `retrieve.browsers()` - List all browsers

**Internal Interactions:**
```
User Command (Snacks Picker Integration)
  → retrieve.browsers()                  # Get all available browsers
  → filter browsers with bookmark support # Firefox only (Chromium uses JSON)
  → retrieve.bookmarks(browser, opts)    # For each supported browser
  → Aggregate results into picker
  → User selects item
  → Open URL with xdg-open/open
```

### Exposed Methods

**Note:** This story demonstrates bookmark aggregation across browsers with folder-based organization.

**Scenarios:**

```gherkin
Scenario: Create Snacks picker for all browser bookmarks
  When I create a Snacks picker for bookmarks from all browsers
  Then I see bookmarks from Firefox (Chromium excluded)
  And I can fuzzy search by folder, title, or URL
  And I can use <C-y> to yank URLs or <C-i> to insert them

  Key integration points:
    • Filter: Skip browsers where retrieve.bookmarks() returns error
    • Tag: item.browser_name = browser.name
    • Sort: By folder, then by title
    • Format: Show date, browser, folder, title, URL columns
    • Actions: yank_url and insert_url for productivity

Scenario: Handle Chromium bookmarks limitation gracefully
  Given Firefox and Chrome are both installed
  When I create an all-bookmarks picker
  Then Firefox bookmarks are shown
  And Chrome bookmarks are silently skipped (JSON storage)
  And no error notification is displayed

Scenario: Group bookmarks by folder
  When I create a bookmarks picker with folder grouping
  Then bookmarks are organized by folder name
  And I can see which browser each bookmark came from

  Key integration points:
    • Group: Collect folders from all browsers
    • Sort: table.sort(bookmarks, fn(a,b) a.folder < b.folder)
    • Format: Highlight folder column differently per browser

Scenario: Search and filter bookmarks
  When I fuzzy search in the bookmarks picker
  Then results match against folder, title, and URL
  And I can select multiple bookmarks to open
```

### Full Implementation Examples

See [examples/snacks-picker.lua](examples/snacks-picker.lua) for complete working code.

---

## Internal API Reference (Not Public)

These are internal modules that users should not directly interact with:

### `detect.lua` (Internal)
- `detect.detect_all()` - Scan for all browsers
- `detect.detect(browser_key)` - Detect specific browser
- `detect.detect_first()` - Get first available browser
- `detect.add_custom_browsers(browsers)` - Override/add browsers

### `state.lua` (Internal)
- `state.register_provider(key, provider)` - Register browser provider
- `state.get_provider(key)` - Get provider for browser
- `state.set_config(config)` - Store user configuration

### `util.lua` (Internal)
- `util.query_db(db_path, sql)` - Execute SQL on database
  - Creates temp copy, executes via sqlite.lua, cleans up, returns results

### `providers/*.lua` (Internal)
Each provider implements:
- `get_history(db_path, limit)` - Returns normalized history
- `get_bookmarks(db_path, limit)` - Returns normalized bookmarks

---

## Error Handling Convention

All public methods return `(result | nil, error | nil)`:
- **Success:** `(result_data, nil)`
- **Failure:** `(nil, error_message)`

### Special Cases:
- **Database locked** → Creates temp copy automatically
- **Database missing** → Returns `"Browser not found: <browser>"`
- **Invalid SQL** → Returns `"Database query failed: <details>"`

---

## Testing Examples

```lua
-- Test: Setup with defaults
local api = require("history-api")
api.setup()
-- Verify: Providers registered, default paths configured

-- Test: Get Firefox history
local history, err = api.retrieve.history("firefox", { limit = 10 })
assert(history or err, "Returns result or error")
if history then
  assert(#history <= 10 and history[1].url, "Respects limit, has required fields")
end

-- Test: Browser not found
local result, err = api.retrieve.history("nonexistent")
assert(result == nil and err:match("not found"), "Returns nil with error message")

-- Test: List browsers
local browsers = api.retrieve.browsers()
assert(type(browsers) == "table", "Returns table")
```
