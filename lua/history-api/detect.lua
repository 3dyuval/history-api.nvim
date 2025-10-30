local M = {}

-- Enabled browsers filter (nil = all browsers enabled)
local enabled_browsers = nil

-- Browser profile configurations
local BROWSERS = {
	firefox = {
		name = "Firefox",
		icon = "󰈹", -- nf-md-firefox
		profile_dirs = {
			"~/.mozilla/firefox",
		},
		profile_glob = "*.default*",
		db_file = "places.sqlite",
	},
	zen = {
		name = "Zen Browser",
		icon = "",
		profile_dirs = {
			"~/.zen",
			"~/.var/app/app.zen_browser.zen/zen", -- Flatpak
		},
		profile_glob = "*.[Dd]efault*",
		db_file = "places.sqlite",
	},
	chrome = {
		name = "Google Chrome",
		icon = "󰊭",
		profile_dirs = {
			"~/.config/google-chrome/Default",
		},
		db_file = "History",
	},
	chromium = {
		name = "Chromium",
		icon = "󰊯",
		profile_dirs = {
			"~/.config/chromium/Default",
		},
		db_file = "History",
	},
	edge = {
		name = "Microsoft Edge",
		icon = "󰇩", -- nf-md-microsoft_edge
		profile_dirs = {
			"~/.config/microsoft-edge/Default",
		},
		db_file = "History",
	},
	brave = {
		name = "Brave",
		icon = "󰖟",
		profile_dirs = {
			"~/.config/BraveSoftware/Brave-Browser/Default",
		},
		db_file = "History",
	},
	opera = {
		name = "Opera",
		icon = "", -- nf-md-opera
		profile_dirs = {
			"~/.config/opera/Default",
			"~/.opera", -- Legacy
		},
		db_file = "History",
	},
	vivaldi = {
		name = "Vivaldi",
		icon = "󰖟",
		profile_dirs = {
			"~/.config/vivaldi/Default",
		},
		db_file = "History",
	},
}

-- Check if a file exists
local function file_exists(path)
	local expanded = vim.fn.expand(path)
	local stat = vim.loop.fs_stat(expanded)
	return stat ~= nil and stat.type == "file"
end

-- Check if a directory exists
local function dir_exists(path)
	local expanded = vim.fn.expand(path)
	local stat = vim.loop.fs_stat(expanded)
	return stat ~= nil and stat.type == "directory"
end

-- Detect a specific browser
local function detect_browser(browser_key, config)
	for _, profile_dir in ipairs(config.profile_dirs) do
		if dir_exists(profile_dir) then
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

			if db_path and file_exists(db_path) then
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

-- Detect all available browsers
function M.detect_all()
	local detected = {}
	for key, config in pairs(BROWSERS) do
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
	local config = BROWSERS[browser_key]
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
		BROWSERS[key] = vim.tbl_deep_extend("force", BROWSERS[key] or {}, config)
	end
end

-- Set which browsers to detect
-- Pass nil or empty table to detect all browsers
-- Example: { "firefox", "zen", "chrome" }
function M.set_enabled_browsers(browsers)
	enabled_browsers = browsers
end

return M
