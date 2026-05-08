-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here
vim.g.mapleader = " "

vim.g.maplocalleader = " "

vim.opt.clipboard = "unnamedplus"

vim.opt.mouse = "a"

vim.opt.mousescroll = "ver:1,hor:1"

-- Add hyprlang filetype detection
vim.filetype.add({
  pattern = {
    [".*/hypr/.*%.conf"] = "hyprlang",
  },
})

vim.g.ai_cmp = false

vim.g.root_spec = { { ".git", "lua", "package.json" }, "cwd" }

vim.g.lazyvim_python_lsp = "basedpyright"
