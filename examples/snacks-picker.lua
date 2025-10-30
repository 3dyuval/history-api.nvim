-- Full implementation examples for Snacks picker integration with history-api.nvim
-- These are referenced in SPEC.md Stories 3 and 4

local api = require("history-api")
local Snacks = require("snacks")

-- Example 1: Basic Firefox History Picker
vim.api.nvim_create_user_command("BrowserHistory", function()
  -- Get history from Firefox
  local history, err = api.retrieve.history("firefox", { limit = 500 })
  if not history then
    Snacks.notify.error("Error: " .. err)
    return
  end

  -- Transform items for picker format
  for _, item in ipairs(history) do
    item.text = string.format("%s %s %s", item.date, item.title or "", item.url)
  end

  Snacks.picker.pick({
    win = { title = "Firefox History" },
    finder = function() return history end,
    format = function(item)
      return {
        { string.format("%-20s", item.date or ""), "Number" },
        { " " },
        { string.format("%-70s", item.title or ""), "Function" },
        { " " },
        { item.url or "", "Comment" },
      }
    end,
    confirm = function(picker, _)
      local items = picker:selected({ fallback = true })
      for _, item in pairs(items) do
        vim.fn.system({ "xdg-open", item.url })
      end
      picker:close()
    end,
  })
end, {})

-- Example 2: History Picker with Custom Keybindings (Yank and Insert URLs)
vim.api.nvim_create_user_command("BrowserHistoryWithActions", function()
  local history, err = api.retrieve.history("firefox", { limit = 500 })
  if not history then
    Snacks.notify.error("Error: " .. err)
    return
  end

  for _, item in ipairs(history) do
    item.text = string.format("%s %s %s", item.date, item.title or "", item.url)
  end

  Snacks.picker.pick({
    win = {
      title = "Firefox History",
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
        Snacks.notify.info("Yanked " .. #urls .. " URL(s)")
      end,
      insert_url = function(picker, _)
        local items = picker:selected({ fallback = true })
        local urls = {}
        for _, item in pairs(items) do
          table.insert(urls, item.url)
        end
        picker:close()
        -- Insert URLs at cursor position
        vim.api.nvim_put(urls, "c", true, true)
        Snacks.notify.info("Inserted " .. #urls .. " URL(s)")
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

-- Example 3: Multi-Browser History Aggregation with Full Actions
vim.api.nvim_create_user_command("AllBrowserHistory", function()
  local all_history = {}

  -- Collect from all browsers
  for _, browser in ipairs(api.retrieve.browsers()) do
    local history, err = api.retrieve.history(browser, { limit = 100 })
    if history then
      -- Tag each item with browser name
      for _, item in ipairs(history) do
        item.browser_name = browser.name
      end
      vim.list_extend(all_history, history)
    end
  end

  if #all_history == 0 then
    Snacks.notify.warn("No browser history found")
    return
  end

  -- Sort by date
  table.sort(all_history, function(a, b)
    return a.date > b.date
  end)

  -- Prepare for picker
  for _, item in ipairs(all_history) do
    item.text = string.format("%s [%s] %s %s",
      item.date, item.browser_name, item.title or "", item.url)
  end

  Snacks.picker.pick({
    win = {
      title = "All Browser History",
      input = {
        keys = {
          ["<C-y>"] = { "yank_url", desc = "Yank URLs", mode = { "n", "i" } },
          ["<C-i>"] = { "insert_url", desc = "Insert URLs at cursor", mode = { "n", "i" } },
        }
      }
    },
    finder = function() return all_history end,
    format = function(item)
      return {
        { string.format("%-20s", item.date or ""), "Number" },
        { " " },
        { string.format("%-10s", "[" .. (item.browser_name or "?") .. "]"), "Keyword" },
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
        Snacks.notify.info("Yanked " .. #urls .. " URL(s)")
      end,
      insert_url = function(picker, _)
        local items = picker:selected({ fallback = true })
        local urls = {}
        for _, item in pairs(items) do
          table.insert(urls, item.url)
        end
        picker:close()
        vim.api.nvim_put(urls, "c", true, true)
        Snacks.notify.info("Inserted " .. #urls .. " URL(s)")
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

-- Example 4: Firefox Bookmarks Picker
vim.api.nvim_create_user_command("BrowserBookmarks", function()
  local bookmarks, err = api.retrieve.bookmarks("firefox", { limit = 500 })
  if not bookmarks then
    Snacks.notify.error("Error: " .. err)
    return
  end

  for _, item in ipairs(bookmarks) do
    item.text = string.format("%s %s %s %s",
      item.date, item.folder or "", item.title or "", item.url)
  end

  Snacks.picker.pick({
    win = { title = "Firefox Bookmarks" },
    finder = function() return bookmarks end,
    format = function(item)
      return {
        { string.format("%-20s", item.date or ""), "Number" },
        { " " },
        { string.format("%-15s", item.folder or ""), "Keyword" },
        { " " },
        { string.format("%-60s", item.title or ""), "Function" },
        { " " },
        { item.url or "", "Comment" },
      }
    end,
    confirm = function(picker, _)
      local items = picker:selected({ fallback = true })
      for _, item in pairs(items) do
        vim.fn.system({ "xdg-open", item.url })
      end
      picker:close()
    end,
  })
end, {})

-- Example 5: Multi-Browser Bookmarks Aggregation (Story 4)
vim.api.nvim_create_user_command("AllBrowserBookmarks", function()
  local all_bookmarks = {}

  -- Collect bookmarks from all browsers
  for _, browser in ipairs(api.retrieve.browsers()) do
    local bookmarks, err = api.retrieve.bookmarks(browser, { limit = 200 })
    if bookmarks then
      -- Tag each item with browser name
      for _, item in ipairs(bookmarks) do
        item.browser_name = browser.name
      end
      vim.list_extend(all_bookmarks, bookmarks)
    end
    -- Silently skip browsers that don't support bookmarks (e.g., Chromium)
  end

  if #all_bookmarks == 0 then
    Snacks.notify.warn("No bookmarks found in any browser")
    return
  end

  -- Sort by folder, then by title
  table.sort(all_bookmarks, function(a, b)
    if a.folder == b.folder then
      return (a.title or "") < (b.title or "")
    end
    return (a.folder or "") < (b.folder or "")
  end)

  -- Prepare for picker
  for _, item in ipairs(all_bookmarks) do
    item.text = string.format("%s [%s] %s %s %s",
      item.date, item.browser_name, item.folder or "", item.title or "", item.url)
  end

  Snacks.picker.pick({
    win = {
      title = "All Browser Bookmarks",
      input = {
        keys = {
          ["<C-y>"] = { "yank_url", desc = "Yank URLs", mode = { "n", "i" } },
          ["<C-i>"] = { "insert_url", desc = "Insert URLs at cursor", mode = { "n", "i" } },
        }
      }
    },
    finder = function() return all_bookmarks end,
    format = function(item)
      return {
        { string.format("%-20s", item.date or ""), "Number" },
        { " " },
        { string.format("%-10s", "[" .. (item.browser_name or "?") .. "]"), "Keyword" },
        { " " },
        { string.format("%-15s", item.folder or ""), "Type" },
        { " " },
        { string.format("%-50s", item.title or ""), "Function" },
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
        Snacks.notify.info("Yanked " .. #urls .. " URL(s)")
      end,
      insert_url = function(picker, _)
        local items = picker:selected({ fallback = true })
        local urls = {}
        for _, item in pairs(items) do
          table.insert(urls, item.url)
        end
        picker:close()
        vim.api.nvim_put(urls, "c", true, true)
        Snacks.notify.info("Inserted " .. #urls .. " URL(s)")
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

-- Example 6: Bookmarks Picker with Folder Grouping and Custom Actions
vim.api.nvim_create_user_command("AllBrowserBookmarksGrouped", function()
  local all_bookmarks = {}

  -- Collect bookmarks from all browsers
  for _, browser in ipairs(api.retrieve.browsers()) do
    local bookmarks, err = api.retrieve.bookmarks(browser, { limit = 200 })
    if bookmarks then
      for _, item in ipairs(bookmarks) do
        item.browser_name = browser.name
      end
      vim.list_extend(all_bookmarks, bookmarks)
    end
  end

  if #all_bookmarks == 0 then
    Snacks.notify.warn("No bookmarks found")
    return
  end

  -- Sort by folder, then by date
  table.sort(all_bookmarks, function(a, b)
    if a.folder == b.folder then
      return a.date > b.date
    end
    return (a.folder or "") < (b.folder or "")
  end)

  -- Prepare for picker
  for _, item in ipairs(all_bookmarks) do
    item.text = string.format("%s [%s] %s %s %s",
      item.date, item.browser_name, item.folder or "", item.title or "", item.url)
  end

  Snacks.picker.pick({
    win = {
      title = "All Browser Bookmarks (Grouped by Folder)",
      input = {
        keys = {
          ["<C-y>"] = { "yank_url", desc = "Yank URLs", mode = { "n", "i" } },
          ["<C-f>"] = { "filter_folder", desc = "Filter by folder", mode = { "n", "i" } },
        }
      }
    },
    finder = function() return all_bookmarks end,
    format = function(item)
      return {
        { string.format("%-20s", item.date or ""), "Number" },
        { " " },
        { string.format("%-10s", "[" .. (item.browser_name or "?") .. "]"), "Keyword" },
        { " " },
        { string.format("%-15s", item.folder or ""), "Type" },
        { " " },
        { string.format("%-50s", item.title or ""), "Function" },
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
        Snacks.notify.info("Yanked " .. #urls .. " URL(s)")
      end,
      filter_folder = function(picker, _)
        local current = picker:current()
        if current and current.folder then
          -- Update the pattern to filter by folder
          picker:filter(current.folder)
        end
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
