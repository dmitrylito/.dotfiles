-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")
-- Auto-open Snacks dashboard when the last normal buffer is closed
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function(args)
    vim.diagnostic.enable(false)
  end,
})

-- Enable mouse scrolling in terminal mode
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("terminal_scroll", { clear = true }),
  callback = function()
    vim.keymap.set("t", "<ScrollWheelUp>", [[<C-\><C-o><ScrollWheelUp>]], { buffer = true, silent = true })
    vim.keymap.set("t", "<ScrollWheelDown>", [[<C-\><C-o><ScrollWheelDown>]], { buffer = true, silent = true })
  end,
})
