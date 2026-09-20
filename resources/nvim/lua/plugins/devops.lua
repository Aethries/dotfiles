-- ==============================================================================
-- DevOps Tooling: Docker, Kubernetes, Helm, and Terraform (Native Only)
-- ==============================================================================

return {
  -- Helm & Kubernetes templates syntax
  {
    "towolf/vim-helm",
    ft = "helm",
  },

  -- Filetype detection & indentation helpers for Cloud Native
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, {
          "dockerfile",
          "terraform",
          "hcl",
        })
      end
    end,
  },
}
