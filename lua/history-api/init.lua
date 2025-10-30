-- Main entry point for history-api.nvim
local M = {}

local state = require("history-api.state")

-- Default configuration
local defaults = {
  -- Custom browser detection overrides
  -- Example:
  -- browsers = {
  --   firefox = {
  --     profile_dirs = { "~/.mozilla/firefox" },
  --     profile_glob = "*.default*",
  --     db_file = "places.sqlite",
  --   },
  -- }
  browsers = {},

  -- Whether to create user commands (BrowserSearch, BrowserBookmarks, BrowserHistory)
  -- Requires snacks.nvim
  create_commands = false,
}

-- Initialize the plugin
function M.setup(opts)
  opts = opts or {}

  -- Merge user config with defaults
  local config = vim.tbl_deep_extend("force", defaults, opts)
  state.set_config(config)

  -- Register built-in providers
  local firefox_provider = require("history-api.providers.firefox")
  local chromium_provider = require("history-api.providers.chromium")

  state.register_provider("firefox", firefox_provider)
  state.register_provider("chromium", chromium_provider)
  state.register_provider("chrome", chromium_provider)
  state.register_provider("brave", chromium_provider)

  -- If user provides custom browser configs, update detection
  if opts.browsers and next(opts.browsers) then
    local detect = require("history-api.detect")
    detect.add_custom_browsers(opts.browsers)
  end

  -- Optionally create user commands for Snacks picker integration
  if opts.create_commands then
    local commands = require("history-api.commands")
    commands.setup()
  end
end

-- Re-export public API for convenience
M.retrieve = require("history-api.retrieve")
M.detect = require("history-api.detect")

return M
