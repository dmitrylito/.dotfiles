-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

vim.opt.guicursor = "n-v-c-t-sm:block,i-ci-ve:ver25,r-cr-o:hor20"

local clipboard_cache = { {}, "v" } -- Initialize empty

if vim.env.SSH_TTY or vim.env.SSH_CONNECTION or vim.env.TMUX then
  vim.g.clipboard = {
    name = "OSC 52 (Cached)",
    copy = {
      ["+"] = function(lines, type)
        require("vim.ui.clipboard.osc52").copy("+")(lines)
        clipboard_cache = { lines, type }
      end,
      ["*"] = function(lines, type)
        require("vim.ui.clipboard.osc52").copy("*")(lines)
        clipboard_cache = { lines, type }
      end,
    },
    paste = {
      ["+"] = function()
        return clipboard_cache
      end,
      ["*"] = function()
        return clipboard_cache
      end,
    },
  }
else
  vim.opt.clipboard = "unnamedplus"
end

vim.opt.clipboard = "unnamedplus"

vim.opt.colorcolumn = "100"
vim.opt.swapfile = false
