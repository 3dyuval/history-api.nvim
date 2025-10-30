-- Public facade for retrieving browser history and bookmarks
-- This module provides a clean API for end users
local M = {}

local state = require("history-api.state")

-- Get history from a specific browser
-- @param browser string: Browser key ("firefox", "chrome", etc.) or browser info table
-- @param opts table: Options { limit = number }
-- @return table|nil, string|nil: Results or (nil, error_message)
function M.history(browser, opts)
  opts = opts or {}

  -- If browser is a string, detect it first
  local browser_info
  if type(browser) == "string" then
    local detect = require("history-api.detect")
    local err
    browser_info, err = detect.detect(browser)
    if not browser_info then
      return nil, err or ("Browser not found: " .. browser)
    end
  else
    browser_info = browser
  end

  -- Get the provider for this browser
  local provider = state.get_provider(browser_info.browser)
  if not provider then
    return nil, "No provider available for: " .. browser_info.browser
  end

  return provider.get_history(browser_info.db_path, opts.limit or 1000)
end

-- Get bookmarks from a specific browser
-- @param browser string: Browser key ("firefox", "chrome", etc.) or browser info table
-- @param opts table: Options { limit = number }
-- @return table|nil, string|nil: Results or (nil, error_message)
function M.bookmarks(browser, opts)
  opts = opts or {}

  -- If browser is a string, detect it first
  local browser_info
  if type(browser) == "string" then
    local detect = require("history-api.detect")
    local err
    browser_info, err = detect.detect(browser)
    if not browser_info then
      return nil, err or ("Browser not found: " .. browser)
    end
  else
    browser_info = browser
  end

  -- Get the provider for this browser
  local provider = state.get_provider(browser_info.browser)
  if not provider then
    return nil, "No provider available for: " .. browser_info.browser
  end

  return provider.get_bookmarks(browser_info.db_path, opts.limit or 1000)
end

-- List all detected browsers
-- @return table: List of browser info tables
function M.browsers()
  local detect = require("history-api.detect")
  return detect.detect_all()
end

return M
