local M = {}

local util = require("history-api.util")

-- Helper function to create browser config with OS-specific paths
local function make_browser(config)
	local os = util.get_os()
	return {
		name = config.name,
		icon = config.icon,
		profile_dirs = config.paths[os] or config.paths.linux or {},
		profile_glob = config.profile_glob,
		db_file = config.db_file,
	}
end

-- Browser profile configurations with OS-specific paths
M.BROWSERS = {
	firefox = make_browser({
		name = "Firefox",
		icon = "󰈹", -- nf-md-firefox
		db_file = "places.sqlite",
		profile_glob = "*.default*",
		paths = {
			macos = { "~/Library/Application Support/Firefox/Profiles" },
			linux = { "~/.mozilla/firefox" },
			windows = { "%APPDATA%/Mozilla/Firefox/Profiles" },
		},
	}),

	zen = make_browser({
		name = "Zen Browser",
		icon = "",
		db_file = "places.sqlite",
		profile_glob = "*.[Dd]efault*",
		paths = {
			macos = { "~/.zen" },
			linux = { "~/.zen", "~/.var/app/app.zen_browser.zen/zen" },
			windows = { "%APPDATA%/Zen Browser" },
		},
	}),

	chrome = make_browser({
		name = "Google Chrome",
		icon = "󰊭",
		db_file = "History",
		paths = {
			macos = { "~/Library/Application Support/Google/Chrome/Default" },
			linux = { "~/.config/google-chrome/Default" },
			windows = { "%LOCALAPPDATA%/Google/Chrome/User Data/Default" },
		},
	}),

	chromium = make_browser({
		name = "Chromium",
		icon = "󰊯",
		db_file = "History",
		paths = {
			macos = { "~/Library/Application Support/Chromium/Default" },
			linux = { "~/.config/chromium/Default" },
			windows = { "%LOCALAPPDATA%/Chromium/User Data/Default" },
		},
	}),

	edge = make_browser({
		name = "Microsoft Edge",
		icon = "󰇩", -- nf-md-microsoft_edge
		db_file = "History",
		paths = {
			macos = { "~/Library/Application Support/Microsoft Edge/Default" },
			linux = { "~/.config/microsoft-edge/Default" },
			windows = { "%LOCALAPPDATA%/Microsoft/Edge/User Data/Default" },
		},
	}),

	brave = make_browser({
		name = "Brave",
		icon = "󰖟",
		db_file = "History",
		paths = {
			macos = { "~/Library/Application Support/BraveSoftware/Brave-Browser/Default" },
			linux = { "~/.config/BraveSoftware/Brave-Browser/Default" },
			windows = { "%LOCALAPPDATA%/BraveSoftware/Brave-Browser/User Data/Default" },
		},
	}),

	opera = make_browser({
		name = "Opera",
		icon = "", -- nf-md-opera
		db_file = "History",
		paths = {
			macos = { "~/Library/Application Support/com.operasoftware.Opera/Default" },
			linux = { "~/.config/opera/Default", "~/.opera" }, -- includes legacy
			windows = { "%APPDATA%/Opera Software/Opera Stable/Default" },
		},
	}),

	vivaldi = make_browser({
		name = "Vivaldi",
		icon = "󰖟",
		db_file = "History",
		paths = {
			macos = { "~/Library/Application Support/Vivaldi/Default" },
			linux = { "~/.config/vivaldi/Default" },
			windows = { "%LOCALAPPDATA%/Vivaldi/User Data/Default" },
		},
	}),
}

return M