local M = {}

local util = require("history-api.util")

-- SQL queries for Firefox
local HISTORY_QUERY = [[
  SELECT
    b.title AS title,
    b.url AS url,
    DATETIME(a.visit_date/1000000, 'unixepoch') AS date
  FROM moz_historyvisits AS a
  JOIN moz_places AS b ON b.id = a.place_id
  ORDER BY a.visit_date DESC
  LIMIT %d
]]

local BOOKMARKS_QUERY = [[
  SELECT
    c.title AS folder,
    a.title AS title,
    b.url AS url,
    DATETIME(a.dateAdded/1000000, 'unixepoch') AS date
  FROM moz_bookmarks AS a
  JOIN moz_places AS b ON a.fk = b.id
  JOIN moz_bookmarks AS c ON a.parent = c.id
  WHERE b.url IS NOT NULL
  ORDER BY a.dateAdded DESC
  LIMIT %d
]]

-- Get Firefox history
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
      browser = "firefox",
    })
  end

  return normalized
end

-- Get Firefox bookmarks
function M.get_bookmarks(db_path, limit)
  limit = limit or 1000
  local query = string.format(BOOKMARKS_QUERY, limit)
  local results, err = util.query_db(db_path, query)

  if not results then
    return nil, err
  end

  -- Normalize the results
  local normalized = {}
  for _, row in ipairs(results) do
    table.insert(normalized, {
      folder = row.folder or "",
      title = row.title or "",
      url = row.url or "",
      date = row.date or "",
      browser = "firefox",
    })
  end

  return normalized
end

return M
