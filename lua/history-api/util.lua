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

-- Read and parse a JSON file
function M.read_json_file(file_path)
  local file, err = io.open(file_path, 'r')
  if not file then
    return nil, "Failed to open file: " .. (err or "unknown error")
  end

  local content = file:read('*a')
  file:close()

  if not content or content == "" then
    return nil, "File is empty"
  end

  local success, result = pcall(vim.fn.json_decode, content)
  if not success then
    return nil, "Failed to parse JSON: " .. tostring(result)
  end

  return result
end

-- Convert Chrome timestamp (microseconds since Windows epoch) to date string
function M.chrome_timestamp_to_date(microseconds)
  if not microseconds or microseconds == 0 then
    return ""
  end

  -- Convert Chrome timestamp (microseconds since Windows epoch 1601-01-01)
  -- to Unix timestamp (seconds since Unix epoch 1970-01-01)
  local unix_timestamp = (microseconds / 1000000) - 11644473600

  -- Format as YYYY-MM-DD HH:MM:SS
  return os.date("%Y-%m-%d %H:%M:%S", unix_timestamp)
end

return M
