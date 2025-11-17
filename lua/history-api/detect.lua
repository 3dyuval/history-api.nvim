local M = {}

local util = require("history-api.util")
local browsers = require("history-api.browsers")

-- Enabled browsers filter (nil = all browsers enabled)
local enabled_browsers = nil

-- =============================================================================
-- INTERNAL FUNCTIONS
-- =============================================================================

-- Detect a specific browser
local function detect_browser(browser_key, config)
	for _, profile_dir in ipairs(config.profile_dirs) do
		if util.dir_exists(profile_dir) then
			local db_path
			if config.profile_glob then
				-- Firefox-style: search with glob pattern
				local found = vim.fn.globpath(profile_dir, config.profile_glob .. "/" .. config.db_file)
				if found and found ~= "" then
					db_path = vim.split(found, "\n")[1]
				end
			else
				-- Chromium-style: direct path
				db_path = vim.fn.expand(profile_dir .. "/" .. config.db_file)
			end

			if db_path and util.file_exists(db_path) then
				return {
					browser = browser_key,
					name = config.name,
					icon = config.icon,
					db_path = db_path,
					profile_dir = vim.fn.expand(profile_dir),
				}
			end
		end
	end
	return nil
end

-- =============================================================================
-- PUBLIC API - User-facing functions
-- =============================================================================

-- Detect all available browsers
function M.detect_all()
	local detected = {}
	for key, config in pairs(browsers.BROWSERS) do
		-- Skip if not in enabled list
		if enabled_browsers and not vim.tbl_contains(enabled_browsers, key) then
			goto continue
		end

		local result = detect_browser(key, config)
		if result then
			table.insert(detected, result)
		end

		::continue::
	end
	return detected
end

-- Detect a specific browser by key
function M.detect(browser_key)
	local config = browsers.BROWSERS[browser_key]
	if not config then
		return nil, "Unknown browser: " .. browser_key
	end
	return detect_browser(browser_key, config)
end

-- Get the first available browser
function M.detect_first()
	local detected = M.detect_all()
	if #detected > 0 then
		return detected[1]
	end
	return nil
end

-- Add custom browser configurations
-- This allows users to override detection logic or add new browsers
function M.add_custom_browsers(custom_browsers)
	for key, config in pairs(custom_browsers) do
		browsers.BROWSERS[key] = vim.tbl_deep_extend("force", browsers.BROWSERS[key] or {}, config)
	end
end

-- Set which browsers to detect
-- Pass nil or empty table to detect all browsers
-- Example: { "firefox", "zen", "chrome" }
function M.set_enabled_browsers(browser_list)
	enabled_browsers = browser_list
end

return M