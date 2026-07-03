return {
  {
    "mfussenegger/nvim-lint",
    ft = { "python" },
    config = function()
      local lint = require("lint")

      -- Route mypy through the fleetchaser wrapper: it loads docker/envs/* and
      -- sets BIGTABLE_EMULATOR_HOST to a dead local port so the django-stubs mypy
      -- plugin can run django.setup() on the host. mypy resolves Django's dynamic
      -- ORM (reverse relations, pk, custom managers) that pyright cannot.
      lint.linters.mypy.cmd = vim.fn.expand("~/.local/bin/fc-mypy")

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
