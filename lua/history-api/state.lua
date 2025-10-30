-- Internal state management for providers and configuration
local M = {}

-- Provider registry
M.providers = {}

-- Configuration
M.config = {
  -- Users can override browser detection paths here
  browsers = {},
}

-- Register a provider for a browser type
function M.register_provider(browser_key, provider)
  M.providers[browser_key] = provider
end

-- Get a provider for a browser type
function M.get_provider(browser_key)
  return M.providers[browser_key]
end

-- Set user configuration
function M.set_config(config)
  M.config = vim.tbl_deep_extend("force", M.config, config)
end

return M
