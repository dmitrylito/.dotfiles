return {
  {
    "mfussenegger/nvim-lint",
    ft = { "python" },
    config = function()
      local lint = require("lint")

      -- Route mypy through fc-dmypy: the mypy DAEMON (fast, ~sub-second warm)
      -- with the django-stubs plugin, so Django's dynamic ORM (reverse relations,
      -- pk, custom managers) resolves — which pyright cannot do. The wrapper loads
      -- docker/envs so django.setup() works on the host and filters output to the
      -- current file. Output format flags live in ~/.config/fleetchaser-mypy.ini,
      -- so no CLI args are passed.
      lint.linters.mypy.cmd = vim.fn.expand("~/.local/bin/fc-dmypy")
      lint.linters.mypy.args = {}

      lint.linters_by_ft = { python = { "mypy" } }

      local grp = vim.api.nvim_create_augroup("fc_nvim_lint", { clear = true })
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
        group = grp,
        pattern = "*.py",
        callback = function()
          require("lint").try_lint()
        end,
      })

      -- Lint the buffer that triggered plugin load (its BufReadPost already fired).
      if vim.bo.filetype == "python" then
        lint.try_lint()
      end
    end,
  },
}
