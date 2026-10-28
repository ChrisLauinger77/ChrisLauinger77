local function agent_terminal(command)
    Snacks.terminal.toggle(command, {
        cwd = LazyVim.root(),
        win = {
            position = "right",
            width = 0.4,
        },
    })
end

return {
    {
        "folke/snacks.nvim",
        keys = {
            {
                "<leader>ac",
                function() agent_terminal("codex") end,
                desc = "Codex",
            },
            {
                "<leader>al",
                function() agent_terminal("claude") end,
                desc = "Claude Code",
            },
        },
    },
}
