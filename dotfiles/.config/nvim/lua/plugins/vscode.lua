-- Only run this if we are inside VS Code / Antigravity
if not vim.g.vscode then
  return {}
end

return {
  -- Disable UI plugins that conflict with VS Code's UI
  { "folke/snacks.nvim", enabled = false }, -- VS Code handles dashboard/indent
  { "folke/noice.nvim", enabled = false }, -- VS Code handles cmdline
  { "nvim-lualine/lualine.nvim", enabled = false }, -- VS Code has a status bar
  { "williamboman/mason.nvim", enabled = false }, -- VS Code handles tools
  { "neovim/nvim-lspconfig", enabled = false }, -- VS Code handles LSP
  { "nvim-treesitter/nvim-treesitter", enabled = false }, -- VS Code handles syntax
}
