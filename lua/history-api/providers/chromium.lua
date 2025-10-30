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

-- Chromium stores bookmarks in a JSON file, not in the SQLite database
-- For now, we'll return an error with a helpful message
function M.get_bookmarks(db_path, limit)
  return nil, "Chromium-based browsers store bookmarks in a JSON file, not in the History database. " ..
             "The bookmarks file is typically located at 'Bookmarks' in the same directory."
end

-- Get Chromium history
function M.get_history(db_path, limit)
  limit = limit or 1000
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
      browser = "chromium",
    })
  end

  return normalized
end

return M
