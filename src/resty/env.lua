------------
-- Resty ENV
-- OpenResty module for working with ENV variables.
--
-- @module resty.env
-- @author mikz
-- @license Apache License Version 2.0

local _M = {
  _VERSION = '0.2'
}

local getenv = os.getenv
local ffi = require('ffi')
ffi.cdef([=[
int setenv(const char*, const char*, int);
]=])

local C = ffi.C

local function setenv(name, value, overwrite)
  local overwrite_flag = overwrite and 1 or 0

  if C.setenv(name, value, overwrite_flag) == -1 then
    return nil, C.strerror(ffi.errno())
  else
    return value
  end
end

local cached = {}

local function fetch(name)
  local value

  if cached[name] then
    value = _M.env[name]
  else
    value = getenv(name)

    ngx.log(ngx.DEBUG, 'env: ', name, ' = ', value)
    _M.env[name] = value

    cached[name] = true
  end

  return value
end

--- Return the raw value from ENV. Uses local cache.
-- @tparam string name name of the environment variable
function _M.get(name)
  return _M.env[name] or fetch(name)
end

local value_mapping = {
  [''] = false
}

--- Return value from ENV.
--- Returns false if it is empty. Uses @{get} internally.
-- @tparam string name name of the environment variable
function _M.value(name)
  local value = _M.get(name)
  local mapped = value_mapping[value]

  if mapped == nil then
    return value
  else
    return mapped
  end
end

local env_mapping = {
  ['true'] = true,
  ['false'] = false,
  ['1'] = true,
  ['0'] = false,
  [''] = false
}

--- Returns true/false from ENV variable.
--- Converts 0 to false and 1 to true.
-- @tparam string name name of the environment variable
function _M.enabled(name)
  return env_mapping[_M.get(name)]
end

--- Sets value to the local cache.
-- @tparam string name name of the environment variable
-- @tparam string value value to be cached
-- @see resty.env.get
function _M.set(name, value)
  local env = _M.env
  local previous = env[name]

  local ok, err = setenv(name, value, true)

  if ok then
    env[name] = value
    cached[name] = nil
  end

  return previous
end

--- Reset local cache.
function _M.reset()
  _M.env = {}
  cached = {}
  return _M
end

return _M.reset()
