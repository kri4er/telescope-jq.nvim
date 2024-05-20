-- local telescope_jq = require('telescope_jq')
local telescope_jq = require('telescope_jq')

return require('telescope').register_extension({
    exports = {
        telescope_jq = telescope_jq.list_keys,
    },
})

