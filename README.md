# telescope-jq.nvim
Hello there fellow neovim user! Same as you I'm actively using neovim and jq tool in my work-life.
Sadly using jq in terminal or even `tmux` is not enough. Something more interactive 
felt better for times to process unknown structure of json document.

Best options I could fine is to connect great usability of 
[telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) with 
`jq` and its powerful language.


## Main features
There are two functions that plugin supports as of now:

* search for keys invoke or map: `lua require("telescope_jq").live_query({file_name = vim.fn.expand('%')})`
* use live query to get jq output on the right pane: `lua require("telescope_jq").list_keys({file_name = vim.fn.expand('%')})`

Here are some example screenshots:

* TODO.

## Installation
Please install plugin using your neovim plugin manager:

#### Packer
```lua
  use {
	  'nvim-telescope/telescope.nvim', tag = '0.1.6',
      requires = {
          {'nvim-lua/plenary.nvim'},
          {'kri4er/telescope-jq.nvim'}
      }
  }
```

If you plan to develop locally, pull the repository and put complete local path to folder 
with plugin and invoke the function or mapping.

## What is next?
- [ ] Open jq output in another buffer
- [ ] For `Live Query` mode, only update output when it command output is valid(not nil)
- [ ] Support prompt list highlighting
- [ ] Allow configuration of commands used and overall configuration
- [ ] Proper telescope plugin registration
- [ ] Keybindings to swap between Live Query mode and Keys fuzzy search(keymapping to pick telescope searcher)
