------------
-- Resty ENV
-- OpenResty module for working with ENV variables.
--
-- @module resty.env
-- @author mikz
-- @license Apache License Version 2.0

local _M = {
  _VERSION = '0.1'
}

local getenv = os.getenv

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
  env[name] = value
  return previous
end

--- Reset local cache.
function _M.reset()
  _M.env = {}
  cached = {}
  return _M
end

return _M.reset()
