-- User commands for history-api.nvim with Snacks picker integration
local M = {}

function M.setup()
  local has_snacks, Snacks = pcall(require, "snacks")
  if not has_snacks then
    vim.notify("history-api.nvim commands require snacks.nvim", vim.log.levels.WARN)
    return
  end

  local api = require("history-api")

  -- Browser Search: Combined history and bookmarks picker
  vim.api.nvim_create_user_command("BrowserSearch", function()
    local all_items = {}

    -- Get history
    local history, _ = api.retrieve.history("firefox", { limit = 300 })
    if history then
      for _, item in ipairs(history) do
        item.source = "History"
        table.insert(all_items, item)
      end
    end

    -- Get bookmarks
    local bookmarks, _ = api.retrieve.bookmarks("firefox", { limit = 200 })
    if bookmarks then
      for _, item in ipairs(bookmarks) do
        item.source = "Bookmark"
        table.insert(all_items, item)
      end
    end

    if #all_items == 0 then
      Snacks.notify.warn("No browser data found")
      return
    end

    -- Sort by date
    table.sort(all_items, function(a, b) return a.date > b.date end)

    -- Prepare for picker
    for _, item in ipairs(all_items) do
      item.text = string.format("%s [%s] %s %s",
        item.date, item.source, item.title or "", item.url)
    end

    Snacks.picker.pick({
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
          { string.format("%-20s", item.date or ""), "Number" },
          { " " },
          { string.format("%-10s", "[" .. (item.source or "?") .. "]"), "Keyword" },
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

  -- Browser Bookmarks: Bookmarks-only picker
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

  -- Browser History: History-only picker
  vim.api.nvim_create_user_command("BrowserHistory", function()
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
end

return M
