return {
  -- Navigate seamlessly between Neovim and tmux panes
  {
    "alexghergh/nvim-tmux-navigation",
    keys = {
      {
        "<C-h>",
        "<Cmd>NvimTmuxNavigateLeft<cr>",
        desc = "Navigate left",
      },
      {
        "<C-j>",
        "<Cmd>NvimTmuxNavigateDown<cr>",
        desc = "Navigate down",
      },
      {
        "<C-k>",
        "<Cmd>NvimTmuxNavigateUp<cr>",
        desc = "Navigate up",
      },
      {
        "<C-l>",
        "<Cmd>NvimTmuxNavigateRight<cr>",
        desc = "Navigate right",
      },
    },
    config = true,
  },
  --
  --Adds a line in nvim, makes it skiny
  --
  {
    "xiyaowong/virtcolumn.nvim",
  },
  --
  -- Center the cursor vertically when navigating
  --
  {
    "arnamak/stay-centered.nvim",
    opts = {
      enable = true,
      cursorline = true,
      disable_on_mouse = true,
      skip_filetypes = { "sidekick_terminal", "snacks_terminal" },
    },
  },
  --
  -- Enable blink.cmp plugin for enhanced completion navigation
  --
  {
    "saghen/blink.cmp",
    opts = function(_, opts)
      opts.keymap = opts.keymap or {}
      opts.keymap.preset = "enter"
      opts.keymap["<Tab>"] = {
        function(cmp)
          if vim.lsp.inline_completion and vim.lsp.inline_completion.get() then
            return true
          end
        end,
        "fallback",
      }
    end,
  },
  --
  -- Configure conform.nvim to use shfmt for zsh files
  --
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        zsh = { "shfmt" },
      },
    },
  },

  { "folke/lazy.nvim", version = false },

  {
    "LazyVim/LazyVim",
    version = false,
    opts = {
      news = {
        lazyvim = false,
        neovim = false,
      },
    },
  },

  {
    "MagicDuck/grug-far.nvim",
    config = function()
      require("grug-far").setup({})
    end,
  },

  {
    "folke/sidekick.nvim",
    opts = {
      copiloot = {
        status = {
          enabled = false
        },
      }
      cli = {
        win = {
          config = function(terminal)
            -- Terminal scroll is handled globally in autocmds.lua
          end,
        },
        mux = {
          backend = "tmux",
          enabled = true,
          dump = 5000, -- Increase scrollback dump for better history
        },
        -- tools = {
        --   gemini = { native_scroll = true },
        --   claude = { native_scroll = true },
        --   codex = {
        --     cmd = { "codex" },
        --     native_scroll = true,
        --   },
        -- },
      },
    },
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      latex = { enabled = false },
    },
  },
}
