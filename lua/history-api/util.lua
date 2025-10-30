-- Internal utilities shared across providers
local M = {}

-- Check for sqlite.lua dependency
local ok, sqlite = pcall(require, "sqlite.db")
if not ok then
  error("history-api.nvim depends on sqlite.lua (https://github.com/kkharji/sqlite.lua)")
end

-- Copy a file (needed because browsers may lock their databases)
local function file_copy(src, dst)
  local fsrc, serr = io.open(src, 'rb')
  if serr or not fsrc then
    return nil, serr
  end
  local data = fsrc:read('*a')
  fsrc:close()

  local fdst, derr = io.open(dst, 'w')
  if derr or not fdst then
    return nil, derr
  end
  fdst:write(data)
  fdst:close()
  return true
end

-- Create a temporary copy of the database
local function create_temp_copy(db_path)
  local temp_path = vim.fn.tempname()
  local success, err = file_copy(db_path, temp_path)
  if not success then
    return nil, "Failed to copy database: " .. (err or "unknown error")
  end
  return temp_path
end

-- Execute a query on a database
function M.query_db(db_path, sql_query)
  local temp_db, err = create_temp_copy(db_path)
  if not temp_db then
    return nil, err
  end

  local success, result = pcall(function()
    local db = sqlite.new(temp_db):open()
    local rows = db:eval(sql_query)
    db:close()
    return rows
  end)

  -- Clean up temp file
  vim.fn.delete(temp_db)

  if not success then
    return nil, "Database query failed: " .. tostring(result)
  end

  return result
end

return M
