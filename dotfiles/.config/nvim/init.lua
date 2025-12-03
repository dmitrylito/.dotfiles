-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

vim.g.clipboard = {
  name = "OSC 52",
  copy = {
    ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
    ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
  },
  paste = {
    ["+"] = function()
      return {}
    end, -- Return empty, don't wait for timeout
    ["*"] = function()
      return {}
    end,
  },
}

vim.opt.clipboard = "unnamedplus"
