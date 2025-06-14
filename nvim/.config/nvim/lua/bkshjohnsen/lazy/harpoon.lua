return {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    dependencies = { "nvim-lua/plenary.nvim" },


    config = function()
        local harpoon = require("harpoon")
        -- REQUIRED
        harpoon:setup()
        -- REQUIRED

        vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
        vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)

        vim.keymap.set("n", "<A-b>", function() harpoon:list():select(1) end)
        vim.keymap.set("n", "<A-n>", function() harpoon:list():select(2) end)
        vim.keymap.set("n", "<A-m>", function() harpoon:list():select(3) end)
        vim.keymap.set("n", "<A-,>", function() harpoon:list():select(4) end)
        vim.keymap.set("n", "•", function() harpoon:list():select(1) end)
        vim.keymap.set("n", "Ω", function() harpoon:list():select(2) end)
        vim.keymap.set("n", "é", function() harpoon:list():select(3) end)
        vim.keymap.set("n", "", function() harpoon:list():select(4) end)

        -- Toggle previous & next buffers stored within Harpoon list
        vim.keymap.set("n", "<C-A-P>", function() harpoon:list():prev() end)
        vim.keymap.set("n", "<C-A-N>", function() harpoon:list():next() end)
    end
}
