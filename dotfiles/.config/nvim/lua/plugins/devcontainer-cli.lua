return {
  "arnaupv/nvim-devcontainer-cli",
  opts = {
    setup_environment_repo = "https://github.com/dmitrylito/setup-environment.git",
    nvim_dotfiles_repo = "https://github.com/dmitrylito/nvimconf.git",
    nvim_dotfiles_install_command = "cd ~/nvim_dotfiles/ && mkdir -p ~/.config/nvim && cp -r . ~/.config/nvim",
    keys = {
    -- stylua: ignore
      {
        "<leader>cdu",
        ":DevcontainerUp<cr>",
        desc = "Up the DevContainer",
      },
      {
        "<leader>cdc",
        ":DevcontainerConnect<cr>",
        desc = "Connect to DevContainer",
      },
    },
  },
}
