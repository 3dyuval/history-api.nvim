# history-api.nvim

A Neovim plugin that provides a unified, facade-based API for accessing browser history and bookmarks from all major browsers.

## Features

- **Clean Facade API**: Simple, intuitive public interface
- **Pluggable Architecture**: Provider-based system for different browsers
- **Browser Detection**: Automatically detects installed browsers with Nerd Font icons
- **Customizable**: Override detection logic and add custom browsers
- **Multiple Browsers**: Built-in support for 8 major browsers
  -  Firefox
  -  Zen Browser
  -  Google Chrome
  -  Chromium
  -  Microsoft Edge
  -  Brave
  -  Opera
  -  Vivaldi
- **Snacks Picker Integration**: Optional built-in commands for quick access

## Dependencies

- [sqlite.lua](https://github.com/kkharji/sqlite.lua) - Required for database access

## Installation

### Using [lazy.nvim](https://github.com/folke/lazy.nvim)

```lua
{
  dir = "~/proj/history-api.nvim",
  name = "history-api",
  dependencies = {
    "kkharji/sqlite.lua",
  },
  config = function()
    require("history-api").setup({
      -- Optional: Override browser detection paths
      browsers = {
        firefox = {
          profile_dirs = { "~/.mozilla/firefox", "/custom/path" },
          profile_glob = "*.default*",
          db_file = "places.sqlite",
        },
      },
    })
  end,
}
```

## Usage

### Basic Usage (Recommended)

```lua
local api = require("history-api")

-- Get history from Firefox
local history, err = api.retrieve.history("firefox", { limit = 100 })
if history then
  for _, item in ipairs(history) do
    print(item.date, item.title, item.url)
  end
end

-- Get bookmarks from Firefox
local bookmarks, err = api.retrieve.bookmarks("firefox", { limit = 100 })

-- List all detected browsers
local browsers = api.retrieve.browsers()
for _, browser in ipairs(browsers) do
  print(browser.name, browser.db_path)
end
```

### Advanced Usage

```lua
local api = require("history-api")

-- Detect a specific browser first, then use it
local firefox = api.detect.detect("firefox")
if firefox then
  local history, err = api.retrieve.history(firefox, { limit = 100 })
  -- Process history...
end

-- Get first available browser
local browser = api.detect.detect_first()
if browser then
  print("Using browser:", browser.name)
end
```

### Custom Browser Detection

```lua
require("history-api").setup({
  browsers = {
    -- Override Firefox paths
    firefox = {
      profile_dirs = { "/custom/firefox/path" },
    },
    -- Add a custom browser
    my_custom_browser = {
      name = "My Custom Browser",
      profile_dirs = { "~/custom/browser" },
      db_file = "history.db",
    },
  },
})
```

## API Reference

### Main Module (`init.lua`)

- `setup(opts)` - Initialize the plugin with optional configuration
- `retrieve` - Public facade for retrieving data (see below)
- `detect` - Browser detection utilities (see below)

### Retrieve API (Public Facade)

- `retrieve.history(browser, opts)` - Get history from a browser
  - `browser`: String (browser key like "firefox") or browser info table
  - `opts`: Table with optional `limit` field
  - Returns: `(results, error)`

- `retrieve.bookmarks(browser, opts)` - Get bookmarks from a browser
  - `browser`: String (browser key) or browser info table
  - `opts`: Table with optional `limit` field
  - Returns: `(results, error)`

- `retrieve.browsers()` - List all detected browsers
  - Returns: Array of browser info tables

### Detect API

- `detect.detect_all()` - Returns a list of all detected browsers
- `detect.detect(browser_key)` - Detects a specific browser
- `detect.detect_first()` - Returns the first detected browser
- `detect.add_custom_browsers(browsers)` - Add or override browser configurations

### Data Structures

**Browser Info:**
```lua
{
  browser = "firefox",             -- Browser key
  name = "Firefox",                -- Display name
  db_path = "/path/to/db",         -- Database file path
  profile_dir = "/path/to/profile" -- Profile directory
}
```

**History Item:**
```lua
{
  title = "Page Title",
  url = "https://example.com",
  date = "2025-10-30 12:00:00",
  browser = "firefox"
}
```

**Bookmark Item (Firefox only):**
```lua
{
  folder = "Folder Name",
  title = "Bookmark Title",
  url = "https://example.com",
  date = "2025-10-30 12:00:00",
  browser = "firefox"
}
```

## Browser Support

### Firefox
- **History**: ✅ Supported
- **Bookmarks**: ✅ Supported
- **Database**: `places.sqlite`
- **Location**: `~/.mozilla/firefox/*.default*/`

### Chromium/Chrome/Brave
- **History**: ✅ Supported
- **Bookmarks**:  ✅ Supported
- **Database**: `History`
- **Locations**:
  - Chrome: `~/.config/google-chrome/Default/`
  - Chromium: `~/.config/chromium/Default/`
  - Brave: `~/.config/BraveSoftware/Brave-Browser/Default/`

## Architecture

The plugin follows a clean facade pattern with pluggable providers:

```
history-api.nvim/
├── lua/history-api/
│   ├── init.lua                    # Main entry point with setup()
│   ├── retrieve.lua                # Public facade API
│   ├── detect.lua                  # Browser detection (internal)
│   ├── state.lua                   # State management (internal)
│   ├── util.lua                    # Shared utilities (internal)
│   └── providers/
│       ├── firefox.lua             # Firefox provider implementation
│       └── chromium.lua            # Chromium provider implementation
└── README.md
```

### Design Principles

1. **Facade Pattern**: `retrieve.lua` provides a clean public API
2. **Provider Pattern**: Browsers implement a common interface in `providers/`
3. **Extensibility**: Users can add custom browsers via `setup()`
4. **Separation of Concerns**: Detection, retrieval, and providers are decoupled

## Technical Details

- **Thread Safety**: The plugin creates temporary copies of database files to avoid locking issues when browsers are running
- **Timestamps**: Automatically converts browser-specific timestamp formats to ISO 8601
- **Error Handling**: All functions return `(result, error)` tuples for proper error handling

### Default Browser Paths (Linux)

All browsers are auto-detected at these standard locations:

| Browser | Icon | Profile Path | Database |
|---------|------|--------------|----------|
| Firefox | 󰈹 | `~/.mozilla/firefox/*.default*/` | `places.sqlite` |
| Zen | 󰆧 | `~/.zen/*.[Dd]efault*/` | `places.sqlite` |
| Chrome | 󰊯 | `~/.config/google-chrome/Default/` | `History` |
| Chromium |  | `~/.config/chromium/Default/` | `History` |
| Edge | 󰇩 | `~/.config/microsoft-edge/Default/` | `History` |
| Brave | 󰖟 | `~/.config/BraveSoftware/Brave-Browser/Default/` | `History` |
| Opera | 󰙯 | `~/.config/opera/Default/` | `History` |
| Vivaldi | 󰖬 | `~/.config/vivaldi/Default/` | `History` |

**Note:** Zen Browser also supports Flatpak installs at `~/.var/app/app.zen_browser.zen/zen/`

## License

MIT
