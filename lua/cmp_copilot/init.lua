local source = {}

source.new = function()
  return setmetatable({
    timer = vim.loop.new_timer()
  }, { __index = source })
end

source.get_trigger_characters = function()
  return { ' ' }
end

source.complete = function(self, params, callback)
  self.timer:stop()
  self.timer:start(0, 200, vim.schedule_wrap(function()
    local ready = true
    ready = ready and vim.g._copilot_completion
    ready = ready and vim.g._copilot_last_completion
    ready = ready and vim.g._copilot_completion.id == vim.g._copilot_last_completion.id
    ready = ready and vim.tbl_contains({ 'success', 'error' }, vim.g._copilot_last_completion.status)
    ready = ready and vim.g._copilot_last_completion.result
    ready = ready and vim.g._copilot_last_completion.result.completions
    ready = ready and #vim.g._copilot_last_completion.result.completions > 0
    if ready then
      self.timer:stop()

      if vim.g._copilot_last_completion.status == 'error' then
        return callback({ isIncomplete = true })
      end

      callback({
        isIncomplete = true,
        items = vim.tbl_map(function(item)
          item = vim.tbl_extend('force', {}, item)
          return {
            label = string.gsub(item.text, '^%s*', ''),
            textEdit = {
              range = {
                start = item.range.start,
                ['end'] = params.context.cursor,
              },
              newText = item.text,
            },
            documentation = {
              kind = 'markdown',
              value = table.concat({
                '```' .. vim.api.nvim_buf_get_option(0, 'filetype'),
                self:deindent(item.text),
                '```'
              }, '\n'),
            },
          }
        end, vim.g._copilot_last_completion.result.completions)
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

