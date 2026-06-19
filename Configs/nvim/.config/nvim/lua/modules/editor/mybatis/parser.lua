local M = {}

function M.trim(text)
  return (text:gsub("^%s+", ""):gsub("%s+$", ""))
end

function M.regex_escape(text)
  return (text:gsub("([\\%^%$%(%)%%%.%[%]%*%+%-%?%|{}])", "\\%1"))
end

function M.normalize_java_type_name(type_name)
  if not type_name or type_name == "" then
    return nil
  end

  local normalized = M.trim(type_name)
  normalized = normalized:gsub("['\"]", "")
  normalized = normalized:gsub("/", ".")
  normalized = normalized:gsub("%.java$", "")
  normalized = normalized:gsub("%[%]$", "")

  if normalized == "" then
    return nil
  end

  return normalized
end

function M.mapper_namespace_pattern(namespace)
  return string.format("namespace\\s*=\\s*['\"]%s['\"]", M.regex_escape(namespace))
end

function M.statement_id_pattern(statement_id)
  return string.format("<(select|insert|update|delete)\\b[^>]*\\bid\\s*=\\s*['\"]%s['\"]", M.regex_escape(statement_id))
end

function M.statement_ref_from_text(text)
  local namespace, statement_id = text:match("session%.[%w_]+%s*%(%s*\"([%w_%.]+)%.([%w_]+)\"")
  if namespace and statement_id then
    return namespace, statement_id
  end

  namespace, statement_id = text:match("\"([%w_%.]+)%.([%w_]+)\"")
  if namespace and statement_id then
    return namespace, statement_id
  end

  return nil, nil
end

function M.namespace_looks_like_package(namespace)
  namespace = M.normalize_java_type_name(namespace)
  if not namespace then
    return false
  end

  local last = namespace:match("([%w_]+)$")
  if not last then
    return false
  end

  return last:match("^[a-z]") ~= nil
end

function M.best_java_usage_match(items, token, method)
  if vim.tbl_isempty(items) then
    return nil
  end

  local best = items[1]
  local best_score = -1

  for _, item in ipairs(items) do
    local score = 0
    local text = item.text or ""
    if text:find(token, 1, true) then
      score = score + 10
    end
    if text:find("session%.select", 1, false) then
      score = score + 20
    end
    if text:find(method .. "(", 1, true) then
      score = score + 5
    end
    if score > best_score then
      best_score = score
      best = item
    end
  end

  return best
end

return M
