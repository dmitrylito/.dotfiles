return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- The "*" key applies these settings to EVERY language server
        ["*"] = {
          capabilities = {
            positionEncodings = { "utf-16" },
          },
        },
      },
    },
  },
}
