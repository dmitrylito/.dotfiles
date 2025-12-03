-- 1. DEFINE LEADER KEY FIRST (Must be at the very top!)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Ensure we are in VS Code
if vim.g.vscode then
  local vscode = require("vscode-neovim")

  -- 2. Visual Mode moving lines (J/K)
  vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
  vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

  -- 3. Clipboard: Copy to System Clipboard
  vim.keymap.set({ "n", "v" }, "<leader>y", '"+y')
  vim.keymap.set("n", "<leader>Y", '"+Y')

  -- 4. Clipboard: Delete without copying (Void register)
  vim.keymap.set({ "n", "v" }, "<leader>d", '"_d')

  -- 5. Navigation: Center screen on jumps
  -- Note: Ensure you removed the default VS Code binding for Ctrl+d
  -- in keybindings.json for this to work perfectly.
  vim.keymap.set({ "n", "v" }, "<C-d>", "<C-d>zz")
  vim.keymap.set({ "n", "v" }, "<C-u>", "<C-u>zz")

  -- 6. Search: Keep cursor centered
  vim.keymap.set("n", "n", "nzzzv")
  vim.keymap.set("n", "N", "Nzzzv")

  -- 7. Disable Ex Mode (Q)
  vim.keymap.set("n", "Q", "<nop>")

  -- 8. Quickfix Navigation (Using VS Code's native commands)
  -- This fixes the error because :cnext/:cprev don't work in VS Code
  vim.keymap.set("n", "<C-k>", function()
    vscode.action("editor.action.marker.next")
  end)
  vim.keymap.set("n", "<C-j>", function()
    vscode.action("editor.action.marker.prev")
  end)
  vim.keymap.set("n", "<leader>k", function()
    vscode.action("editor.action.marker.next")
  end)
  vim.keymap.set("n", "<leader>j", function()
    vscode.action("editor.action.marker.prev")
  end)

  -- 9. Clear highlighting on Escape
  vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")
end

-- Fallback options (VS Code ignores these, but good for safety)
vim.opt.clipboard = "unnamedplus"
