return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
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
      },
      setup = {
        copilot = function()
          vim.lsp.inline_completion.enable(true)
        end,
      },
    },
  },
}
