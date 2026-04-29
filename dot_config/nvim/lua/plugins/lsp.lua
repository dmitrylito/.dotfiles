return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Native Copilot support via LSP
        copilot = {},
        -- Ruff handles linting and formatting with extreme speed
        ruff = {
          keys = {
            {
              "<leader>co",
              function()
                vim.lsp.buf.code_action({
                  apply = true,
                  context = {
                    only = { "source.organizeImports" },
                    diagnostics = {},
                  },
                })
              end,
              desc = "Organize Imports",
            },
          },
        },
        -- Basedpyright for superior type checking and Django support
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "basic",
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
                -- Let Ruff handle these
                reportUnusedImport = false,
                reportUnusedVariable = false,
              },
            },
          },
        },
      },
      setup = {
        -- Enable native inline completion (ghost text) for Neovim 0.12+
        copilot = function()
          vim.lsp.inline_completion.enable(true)
        end,
      },
    },
  },
}
