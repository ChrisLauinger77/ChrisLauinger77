return {
    {
        "mason-org/mason.nvim",
        opts = {
            ensure_installed = {
                "clangd",
                "clang-format",
                "lua-language-server",
                "stylua",
                "bash-language-server",
                "shfmt",
                "json-lsp",
                "yaml-language-server",
                "marksman",
                "prettier",
                "codelldb",
            },
        },
    },
}