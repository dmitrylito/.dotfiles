-- keymaps --
Snacks.keymap.set("n", "<leader>ba", function()
  Snacks.dashboard()
  Snacks.bufdelete.all()
end, { desc = "Open Snacks Dashboard" })
-- 1. UNIVERSAL MAPPINGS (Work in both)
vim.keymap.set("i", "jj", "<ESC>", { silent = true })
-- System Clipboard
vim.keymap.set({ "n", "v" }, "<leader>d", '"_d')
-- Terminal Mode Escape (double-tap Esc)
vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { silent = true })

-- 2. VS CODE SPECIFIC MAPPINGS (Antigravity)
if vim.g.vscode then
  local vscode = require("vscode-neovim")

  -- Fix Jumps: Scroll down/up and center
  vim.keymap.set({ "n", "v" }, "<C-d>", "<C-d>zz")
  vim.keymap.set({ "n", "v" }, "<C-u>", "<C-u>zz")

  -- Navigation: Use VS Code's "Problems" panel
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

  -- Toggle Sidebar (File Tree)
  vim.keymap.set("n", "<leader>e", function()
    vscode.action("workbench.action.toggleSidebarVisibility")
  end)

  -- Clear Highlights
  vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>")

  vim.keymap.set("n", "<leader>t", function()
    vscode.action("workbench.action.terminal.toggleTerminal")
  end)
  -- 3. TERMINAL NEOVIM ONLY
else
  vim.keymap.set("i", "<M-n>", function()
    vim.lsp.inline_completion.select()
  end, { desc = "Next Inline Suggestion" })

  vim.keymap.set("i", "<M-p>", function()
    vim.lsp.inline_completion.select({ count = -1 })
  end, { desc = "Previous Inline Suggestion" })
end
