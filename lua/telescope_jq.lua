local conf = require('telescope.config').values
local pickers = require('telescope.pickers')
local actions = require('telescope.actions')
local action_state = require('telescope.actions.state')
local finders = require('telescope.finders')
local previewers = require('telescope.previewers')
local sorters = require('telescope.sorters')
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
  local parts = vim.split(str, ".", {plain=true})
  for i, part in ipairs(parts) do
      if tonumber(part, 10) ~= nil then
          parts[i] = "[" .. part .. "]"
      end
  end

  -- Join the parts back together with dots
  return table.concat(parts, ".")
end

local has_jq_program = function(picker_name, program)
  if vim.fn.executable(program) == 1 then
    return true
  end

  utils.notify(picker_name, {
    msg = string.format(
      "'jq', or similar alternative, is a required dependency for the %s picker. "
        .. "Visit https://jqlang.github.io/jq/download for installation instructions.",
      picker_name
    ),
    level = "ERROR",
  })
  return false
end

M.live_query = function(opts)
    if not has_jq_program("live_jq", 'jq') then
        return
    end

    local query_entry_maker = function(entry)
        --log.info('Calling entry maker:', entry)
        local jq_comm = M._convertDotsToBrackets(entry)
        --log.info('Entry maked with:', jq_comm)

        return {
            value = jq_comm,
            display = entry,
            ordinal = entry,
        }
    end

    local live_grepper = finders.new_job(function(prompt)
        if not prompt or prompt == "" then
            prompt = '.'
        end

        log.info('live finder with prompt:', prompt)
        --local output = M._make_jq_command { '"', prompt, '"', opts.file_name}
        local output = M._make_jq_command { prompt, opts.file_name}
        --local output = nil
        if output then
            local filename = "/tmp/live_jq.json"
            local f = io.open(filename, "w")
            if f then
                local str_to_write = table.concat(output, "")
                log.info("Writing shit: " .. str_to_write)
                f:write(str_to_write)
                f:flush()
                io.close(f)
            else
                log.warn("Failed to open file: " .. filename)
            end
        end
        return {'jq', '-r', 'paths | join(".")', '/tmp/live_jq.json'}
    end, query_entry_maker, 100, nil)
    pickers
    .new(opts, {
        prompt_title = "Live Query",
        finder = live_grepper,
        sorter = sorters.highlighter_only(opts),
        previewer = previewers.new_buffer_previewer({
            title = 'Selected Query',
            define_preview = function(self, entry)
                --TODO: use system indepedent tmp file
                local selector =  M._make_jq_command { '.' .. entry.value, '/tmp/live_jq.json' }
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, selector)
                utils.highlighter(self.state.bufnr, 'markdown')
            end,
            attach_mappings = function(prompt_bufnr)
                --TODO: allow mode switch between two pickers: Live Query picker and key search
                actions.select_default:replace(function()
                    actions.close(prompt_bufnr)
                end)
                return true
            end,
        }),
    })
    :find()
end

M.list_keys = function(opts)
    pickers
        .new(opts, {
            finder = finders.new_dynamic({
                fn = function()
                    return M._make_jq_command { '-r', 'paths | join(".")', opts.file_name }
                end,
                entry_maker = function(entry)
                    log.info('Calling entry maker:', entry)
                    local jq_comm = M._convertDotsToBrackets(entry)

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
                    local selector =  M._make_jq_command { '.' .. entry.value, opts.file_name }
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
