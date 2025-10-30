-- User commands for history-api.nvim with Snacks picker integration
local M = {}

function M.setup()
  -- Check for Snacks picker (only needed for picker functionality, not notifications)
  local has_snacks, snacks_picker = pcall(require, "snacks.picker")
  if not has_snacks then
    vim.notify("history-api.nvim commands require snacks.nvim picker", vim.log.levels.WARN)
    return
  end

  local api = require("history-api")

  -- Browser Search: Combined history and bookmarks picker
  vim.api.nvim_create_user_command("BrowserSearch", function()
    -- Detect first available browser from enabled_browsers list
    local browser_info = api.detect.detect_first()
    if not browser_info then
      vim.notify("No browsers detected. Check your enabled_browsers configuration.", vim.log.levels.ERROR)
      return
    end

    local all_items = {}

    -- Get history
    local history, err = api.retrieve.history(browser_info, { limit = 300 })
    if not history then
      vim.notify("Failed to get history: " .. (err or "unknown error"), vim.log.levels.ERROR)
      return
    end
    for _, item in ipairs(history) do
      item.source = "H"
      item.icon = browser_info.icon or ""
      table.insert(all_items, item)
    end

    -- Get bookmarks
    local bookmarks, err = api.retrieve.bookmarks(browser_info, { limit = 200 })
    if not bookmarks then
      vim.notify("Failed to get bookmarks: " .. (err or "unknown error"), vim.log.levels.WARN)
    else
      for _, item in ipairs(bookmarks) do
        item.source = "B"
        item.icon = browser_info.icon or ""
        table.insert(all_items, item)
      end
    end

    if #all_items == 0 then
      vim.notify("No browser data found", vim.log.levels.WARN)
      return
    end

    -- Sort by date
    table.sort(all_items, function(a, b) return a.date > b.date end)

    -- Prepare for picker
    for _, item in ipairs(all_items) do
      item.text = string.format("%s %s [%s] %s %s",
        item.icon, item.date, item.source, item.title or "", item.url)
    end

    snacks_picker.pick({
      win = {
        title = "Browser Search",
        input = {
          keys = {
            ["<C-y>"] = { "yank_url", desc = "Yank URLs", mode = { "n", "i" } },
            ["<C-i>"] = { "insert_url", desc = "Insert URLs at cursor", mode = { "n", "i" } },
          }
        }
      },
      finder = function() return all_items end,
      format = function(item)
        return {
          { item.icon or "", "Special" },
          { " " },
          { string.format("%-20s", item.date or ""), "Number" },
          { " " },
          { string.format("%-3s", "[" .. (item.source or "?") .. "]"), "Keyword" },
          { " " },
          { string.format("%-60s", item.title or ""), "Function" },
          { " " },
          { item.url or "", "Comment" },
        }
      end,
      actions = {
        yank_url = function(picker, _)
          local items = picker:selected({ fallback = true })
          local urls = {}
          for _, item in pairs(items) do
            table.insert(urls, item.url)
          end
          vim.fn.setreg(vim.v.register, table.concat(urls, '\n'))
          vim.notify("Yanked " .. #urls .. " URL(s)", vim.log.levels.INFO)
        end,
        insert_url = function(picker, _)
          local items = picker:selected({ fallback = true })
          local urls = {}
          for _, item in pairs(items) do
            table.insert(urls, item.url)
          end
          picker:close()
          vim.api.nvim_put(urls, "c", true, true)
          vim.notify("Inserted " .. #urls .. " URL(s)", vim.log.levels.INFO)
        end,
      },
      confirm = function(picker, _)
        local items = picker:selected({ fallback = true })
        for _, item in pairs(items) do
          vim.fn.system({ "xdg-open", item.url })
        end
        picker:close()
      end,
    })
  end, {})

  -- Browser Bookmarks: Bookmarks-only picker
  vim.api.nvim_create_user_command("BrowserBookmarks", function()
    -- Detect first available browser from enabled_browsers list
    local browser_info = api.detect.detect_first()
    if not browser_info then
      vim.notify("No browsers detected. Check your enabled_browsers configuration.", vim.log.levels.ERROR)
      return
    end

    local bookmarks, err = api.retrieve.bookmarks(browser_info, { limit = 500 })
    if not bookmarks then
      vim.notify("Error: " .. (err or "unknown error"), vim.log.levels.ERROR)
      return
    end

    for _, item in ipairs(bookmarks) do
      item.icon = browser_info.icon or ""
      item.text = string.format("%s %s %s %s %s",
        item.icon, item.date, item.folder or "", item.title or "", item.url)
    end

    snacks_picker.pick({
      win = {
        title = "Browser Bookmarks",
        input = {
          keys = {
            ["<C-y>"] = { "yank_url", desc = "Yank URLs", mode = { "n", "i" } },
            ["<C-i>"] = { "insert_url", desc = "Insert URLs at cursor", mode = { "n", "i" } },
          }
        }
      },
      finder = function() return bookmarks end,
      format = function(item)
        return {
          { item.icon or "", "Special" },
          { " " },
          { string.format("%-20s", item.date or ""), "Number" },
          { " " },
          { string.format("%-15s", item.folder or ""), "Keyword" },
          { " " },
          { string.format("%-60s", item.title or ""), "Function" },
          { " " },
          { item.url or "", "Comment" },
        }
      end,
      actions = {
        yank_url = function(picker, _)
          local items = picker:selected({ fallback = true })
          local urls = {}
          for _, item in pairs(items) do
            table.insert(urls, item.url)
          end
          vim.fn.setreg(vim.v.register, table.concat(urls, '\n'))
          vim.notify("Yanked " .. #urls .. " URL(s)", vim.log.levels.INFO)
        end,
        insert_url = function(picker, _)
          local items = picker:selected({ fallback = true })
          local urls = {}
          for _, item in pairs(items) do
            table.insert(urls, item.url)
          end
          picker:close()
          vim.api.nvim_put(urls, "c", true, true)
          vim.notify("Inserted " .. #urls .. " URL(s)", vim.log.levels.INFO)
        end,
      },
      confirm = function(picker, _)
        local items = picker:selected({ fallback = true })
        for _, item in pairs(items) do
          vim.fn.system({ "xdg-open", item.url })
        end
        picker:close()
      end,
    })
  end, {})

  -- Browser History: History-only picker
  vim.api.nvim_create_user_command("BrowserHistory", function()
    -- Detect first available browser from enabled_browsers list
    local browser_info = api.detect.detect_first()
    if not browser_info then
      vim.notify("No browsers detected. Check your enabled_browsers configuration.", vim.log.levels.ERROR)
      return
    end

    local history, err = api.retrieve.history(browser_info, { limit = 500 })
    if not history then
      vim.notify("Error: " .. (err or "unknown error"), vim.log.levels.ERROR)
      return
    end

    for _, item in ipairs(history) do
      item.icon = browser_info.icon or ""
      item.text = string.format("%s %s %s %s", item.icon, item.date, item.title or "", item.url)
    end

    snacks_picker.pick({
      win = {
        title = "Browser History",
        input = {
          keys = {
            ["<C-y>"] = { "yank_url", desc = "Yank URLs", mode = { "n", "i" } },
            ["<C-i>"] = { "insert_url", desc = "Insert URLs at cursor", mode = { "n", "i" } },
          }
        }
      },
      finder = function() return history end,
      format = function(item)
        return {
          { item.icon or "", "Special" },
          { " " },
          { string.format("%-20s", item.date or ""), "Number" },
          { " " },
          { string.format("%-70s", item.title or ""), "Function" },
          { " " },
          { item.url or "", "Comment" },
        }
      end,
      actions = {
        yank_url = function(picker, _)
          local items = picker:selected({ fallback = true })
          local urls = {}
          for _, item in pairs(items) do
            table.insert(urls, item.url)
          end
          vim.fn.setreg(vim.v.register, table.concat(urls, '\n'))
          vim.notify("Yanked " .. #urls .. " URL(s)", vim.log.levels.INFO)
        end,
        insert_url = function(picker, _)
          local items = picker:selected({ fallback = true })
          local urls = {}
          for _, item in pairs(items) do
            table.insert(urls, item.url)
          end
          picker:close()
          vim.api.nvim_put(urls, "c", true, true)
          vim.notify("Inserted " .. #urls .. " URL(s)", vim.log.levels.INFO)
        end,
      },
      confirm = function(picker, _)
        local items = picker:selected({ fallback = true })
        for _, item in pairs(items) do
          vim.fn.system({ "xdg-open", item.url })
        end
        picker:close()
      end,
    })
  end, {})
end

return M
