local conf = require('telescope.config').values
local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local finders = require('telescope.finders')
local previewers = require('telescope.previewers')
local utils = require('telescope.previewers.utils')
local plenary = require('plenary')
local log = require('plenary.log').new {
    plugin = 'telescope_jq',
    level = 'info',
}


local M = {}


---@param args string[]
---@return string[]
M._make_jq_command = function(args)
    local job_opts = {
        command = 'jq',
        args = vim.tbl_flatten { args },
    }
    log.info('Running job', job_opts)
    local job = plenary.job:new(job_opts):sync()
    log.info('Ran job', vim.inspect(job))
    return job
end

M._convertDotsToBrackets = function(str)
  -- Split the string using dots as delimiters
  log.info("LOGME: converting string: " .. str)
  --local parts = string.split(str, ".")
  local parts = vim.split(str, ".", {plain=true})
  log.info("LOGME: parts: " .. table.concat(parts, " - "))
  -- Iterate through each part
  for i, part in ipairs(parts) do
      log.info("LOGME: part: " .. part)
      -- Check if the part is a number
      if tonumber(part, 10) ~= nil then
          -- Wrap the number in brackets
          parts[i] = "[" .. part .. "]"
      end
  end

  -- Join the parts back together with dots
  return table.concat(parts, ".")
end

M.list_keys = function(opts)
    pickers
        .new(opts, {
            finder = finders.new_dynamic({
                fn = function()
                    local current_buf = vim.api.nvim_get_current_buf()
                    local buf_name = vim.api.nvim_buf_get_name(current_buf)
                    local f_name = vim.api.nvim_buf_get_name(0)

                    log.info('getting data from buf', current_buf)
                    return M._make_jq_command { '-r', 'paths | join(".")', 'json_array.json' }
                end,
                entry_maker = function(entry)
                    log.info('Calling entry maker:', entry)
                    local jq_comm = M._convertDotsToBrackets(entry)
                    log.info('Entry maked with:', jq_comm)

                    return {
                        value = jq_comm,
                        display = entry,
                        ordinal = entry,
                    }
                end,
            }),

            sorter = conf.generic_sorter(opts),
            previewer = previewers.new_buffer_previewer({
                title = 'Volume Details',
                define_preview = function(self, entry)
                    log.info('select preview for entry:', entry)
                    local selector =  M._make_jq_command { '.' .. entry.value, 'json_array.json' }
                    log.info('got selector results:', selector)
                    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, selector)
                    utils.highlighter(self.state.bufnr, 'markdown')
                end,
                attach_mappings = function(prompt_bufnr)
                    actions.select_default:replace(function()
                        actions.close(prompt_bufnr)
                    end)
                    return true
                end,
            }),
        })
        :find()
end

return M
