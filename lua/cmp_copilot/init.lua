local source = {}

source.new = function()
  return setmetatable({}, { __index = source })
end

source.get_trigger_characters = function()
  return { ' ' }
end

source.complete = function(self, _, callback)
  vim.fn['copilot#Schedule']()
  local timer = vim.loop.new_timer()
  timer:start(200, 200, vim.schedule_wrap(function()
    local ok = true
    ok = ok and vim.g._copilot_completion
    ok = ok and vim.g._copilot_last_completion
    ok = ok and vim.g._copilot_completion.id == vim.g._copilot_last_completion.id
    ok = ok and vim.b._copilot_completion
    ok = ok and vim.b._copilot_completion.text
    ok = ok and #vim.b._copilot_completion.text > 0
    if ok then
      timer:close()
      callback({
        isIncomplete = true,
        items = vim.tbl_map(function(item)
          return {
            label = string.gsub(item.text, '^%s*', ''),
            insertTextFormat = 2,
            documentation = {
              kind = 'markdown',
              value = table.concat({ '```' .. vim.api.nvim_buf_get_option(0, 'filetype'), self:deindent(item.text), '```' }, '\n'),
            },
            textEdit = {
              range = {
                start = item.range.start,
                ['end'] = item.range['end'],
              },
              newText = string.gsub(item.text, '%$', '\\$'),
            }
          }
        end, { vim.b._copilot_completion })
      })
    end
  end))
end

source.deindent = function(_, text)
  local indent = string.match(text, '^%s*')
  if not indent then
    return text
  end
  return string.gsub(string.gsub(text, '^' .. indent, ''), '\n' .. indent, '\n')
end

return source

