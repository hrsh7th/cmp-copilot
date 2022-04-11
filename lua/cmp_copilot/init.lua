local source = {}

source.new = function()
  return setmetatable({
    timer = vim.loop.new_timer()
  }, { __index = source })
end

source.get_keyword_pattern = function()
  return '.'
end

source.complete = function(self, params, callback)
  vim.fn['copilot#Complete'](function(result)
    callback({
      isIncomplete = true,
      items = vim.tbl_map(function(item)
        local prefix = string.sub(params.context.cursor_before_line, item.range.start.character + 1, item.position.character)
        return {
          label = prefix .. item.displayText,
          textEdit = {
            range = item.range,
            newText = item.text,
          },
          documentation = {
            kind = 'markdown',
            value = table.concat({
              '```' .. vim.api.nvim_buf_get_option(0, 'filetype'),
              self:deindent(item.text),
              '```'
            }, '\n'),
          }
        }
      end, (result or {}).completions or {})
    })
  end, function()
    callback({
      isIncomplete = true,
      items = {},
    })
  end)
end

source.deindent = function(_, text)
  local indent = string.match(text, '^%s*')
  if not indent then
    return text
  end
  return string.gsub(string.gsub(text, '^' .. indent, ''), '\n' .. indent, '\n')
end

return source

