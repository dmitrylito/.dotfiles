return {
  "folke/snacks.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    -- 1. From snacks-animated-scrolling-off.lua
    scroll = { enabled = false },

    -- 2. From snacks-indent.lua
    indent = {
      enabled = true,
      only_scope = false,
      scope = {
        enabled = true,
        only_current = true,
      },
    },

    -- 3. From snacks-dashboard.lua
    dashboard = {
      pane_gap = 10,
      width = 68,
      show_recent_files = true,
      sections = {
        { section = "header" },
        {
          pane = 2,
          section = "terminal",
          cmd = "colorscript -e square",
          height = 5,
          padding = { 3, 1 },
          align = "left",
        },
        { section = "keys", gap = 1, padding = 3 },
        { pane = 2, icon = " ", title = "Recent Files", section = "recent_files", indent = 2, padding = 2 },
        { pane = 2, icon = " ", title = "Projects", section = "projects", indent = 2, padding = 2 },
        {
          pane = 2,
          icon = " ",
          title = "Git Status",
          section = "terminal",
          enabled = function()
            return Snacks.git.get_root() ~= nil
          end,
          cmd = "git status --short --branch --renames",
          height = 5,
          padding = 1,
          ttl = 5 * 60,
          indent = 5,
        },
        { section = "startup" },
      },
    },

    -- 4. From your original snacks.lua (Picker settings)
    picker = {
      layouts = {
        default = {
          reverse = true,
          layout = {
            box = "horizontal",
            width = 0.95,
            height = 0.95,
            {
              box = "vertical",
              border = "rounded",
              title = "{title} {live} {flags}",
              { win = "list", border = "none" },
              { win = "input", height = 1, border = "top" },
            },
            {
              win = "preview",
              title = "{preview}",
              border = "rounded",
              width = 0.65,
            },
          },
        },
      },
      sources = {
        files = { follow = true, hidden = true, ignored = true },
        explorer = {
          hidden = true,
          follow = true,
          layout = { auto_hide = { "input" }, layout = { width = 0.2 } },
        },
      },
    },

    -- Enable explorer if you are using it
    explorer = {},
  },
  -- Keep your keymaps here or in config/keymaps.lua
  keys = {
    {
      "<leader>ba",
      function()
        Snacks.dashboard()
        Snacks.bufdelete.all()
      end,
      desc = "Dashboard & Close All",
    },
  },
}
