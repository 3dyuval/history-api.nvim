local M = {}

local util = require("history-api.util")

-- SQL queries for Chromium-based browsers
-- Note: Chromium timestamps are in microseconds since Windows epoch (1601-01-01)
-- We need to subtract 11644473600 seconds to convert to Unix epoch
local HISTORY_QUERY = [[
  SELECT
    urls.title AS title,
    urls.url AS url,
    DATETIME(visits.visit_time/1000000 - 11644473600, 'unixepoch') AS date
  FROM visits
  INNER JOIN urls ON visits.url = urls.id
  ORDER BY visits.visit_time DESC
  LIMIT %d
]]

-- Get Chromium bookmarks from JSON file
function M.get_bookmarks(db_path, limit, browser_key)
  limit = limit or 1000
  browser_key = browser_key or "chromium"

  -- Bookmarks are in the same directory as the History database
  local history_dir = vim.fn.fnamemodify(db_path, ":h")
  local bookmarks_path = history_dir .. "/Bookmarks"

  -- Read and parse JSON file
  local bookmarks_data, err = util.read_json_file(bookmarks_path)
  if not bookmarks_data then
    return nil, err
  end

  -- Validate structure
  if not bookmarks_data.roots then
    return nil, "Invalid bookmarks file: missing 'roots' field"
  end

  local results = {}

  -- Recursive function to collect bookmarks
  local function collect_bookmarks(node, folder_path, depth)
    if depth > 50 then return end

    if node.type == "url" and node.url then
      table.insert(results, {
        folder = folder_path,
        title = node.name or "",
        url = node.url,
        date = util.chrome_timestamp_to_date(tonumber(node.date_added)),
        browser = browser_key,
      })
      return
    end

    if node.type == "folder" and node.children then
      local new_path = node.name
        and (folder_path ~= "" and folder_path .. "/" .. node.name or node.name)
        or folder_path

      for _, child in ipairs(node.children) do
        collect_bookmarks(child, new_path, depth + 1)
      end
    end
  end

  -- Process each root folder
  for _, root_name in ipairs({"bookmark_bar", "other", "synced"}) do
    local root = bookmarks_data.roots[root_name]
    if root then
      collect_bookmarks(root, "", 0)
    end
  end

  -- Sort by date descending
  table.sort(results, function(a, b) return a.date > b.date end)

  -- Apply limit
  if #results > limit then
    for i = #results, limit + 1, -1 do
      results[i] = nil
    end
  end

  return results
end

-- Get Chromium history
function M.get_history(db_path, limit, browser_key)
  limit = limit or 1000
  browser_key = browser_key or "chromium"
  local query = string.format(HISTORY_QUERY, limit)
  local results, err = util.query_db(db_path, query)

  if not results then
    return nil, err
  end

  -- Normalize the results
  local normalized = {}
  for _, row in ipairs(results) do
    table.insert(normalized, {
      title = row.title or "",
      url = row.url or "",
      date = row.date or "",
      browser = browser_key,
    })
  end

  return normalized
end

return M
