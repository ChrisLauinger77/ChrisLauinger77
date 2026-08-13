return {
    {
        "folke/snacks.nvim",
        keys = {
            {
                "<leader>ac",
                function()
                    Snacks.terminal.toggle("codex", {
                        cwd = LazyVim.root(),
                        win = {
                            position = "right",
                            width = 0.4,
                        },
                    })
                end,
                desc = "Codex",
            },
        },
    },
}
