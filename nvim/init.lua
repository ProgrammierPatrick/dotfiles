vim.g.mapleader = " "
vim.g.maplocalleader = vim.g.mapleader -- leader bound to buffer. Always use global leader!

-- system flags
ARM32 = vim.loop.os_uname().machine == "armv6l"
WIN = vim.fn.has 'win32' == 1

vim.o.number = true
vim.o.relativenumber = false
vim.o.signcolumn =
"yes"                           -- sign column: used for information and breakpoints. Show always to prevent flickering of text.

vim.o.scrolloff = 5             -- keep cursor away from top and bottom border
vim.o.cursorline = not ARM32    -- highlight current line. Disabled on rpi because very slow
vim.o.clipboard = "unnamedplus" -- use OS clipboard

vim.o.tabstop = 4               -- one tab is 4 spaces
vim.o.shiftwidth = 4            -- each indent is 4 spaces
vim.o.expandtab = true          -- use spaces only
vim.o.inccommand = "split"      -- TODO explore: tjdev: Preview substitutions live, as you type!
vim.opt.updatetime = 1000       -- ms. Auto-save for recovery after updatetime when stopped pressing keys
vim.opt.timeoutlen = 500        -- ms. Time to wait for additional keys in key sequence
vim.opt.splitright = true
vim.opt.splitbelow = true

vim.o.list = true -- show trailing whitespace
vim.o.listchars = "tab:»»,trail:·,nbsp:␣"

local packs = {}

-- Theme
packs[#packs + 1] = { src = "https://github.com/bluz71/vim-moonfly-colors" }

-- Small Utils
packs[#packs + 1] = { src = "https://github.com/vladdoster/remember.nvim" }   -- remember cursor position in each file
packs[#packs + 1] = { src = "https://github.com/xiyaowong/transparent.nvim" } -- hide background color. Useful for terminals, which have semi transparent blacks!. Control using :Transparent*
packs[#packs + 1] = { src = "https://github.com/j-hui/fidget.nvim" }          -- widget showing update
packs[#packs + 1] = { src = "https://github.com/windwp/nvim-autopairs" }
packs[#packs + 1] = { src = "https://github.com/lewis6991/gitsigns.nvim"} -- color highlight for changed lines

-- Mini Packages
packs[#packs + 1] = { src = "https://github.com/nvim-mini/mini.nvim" }

-- Help
packs[#packs + 1] = { src = "https://github.com/folke/which-key.nvim" }

-- LSP
packs[#packs + 1] = { src = "https://github.com/neovim/nvim-lspconfig" }
packs[#packs + 1] = { src = "https://github.com/williamboman/mason.nvim" }
packs[#packs + 1] = { src = "https://github.com/williamboman/mason-lspconfig.nvim" }

-- Editors
packs[#packs + 1] = { src = "https://github.com/nvim-lua/plenary.nvim" } -- dependency for neotree, telescope
packs[#packs + 1] = { src = "https://github.com/MunifTanjim/nui.nvim" }  -- dependency for neotree
packs[#packs + 1] = { src = "https://github.com/nvim-neo-tree/neo-tree.nvim" }
packs[#packs + 1] = { src = "https://github.com/NeogitOrg/neogit" }
packs[#packs + 1] = { src = "https://github.com/nvim-telescope/telescope.nvim" }
packs[#packs + 1] = { src = "https://github.com/nvim-telescope/telescope-ui-select.nvim" }

vim.pack.add(packs)

require "neo-tree".setup {}

vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Clear search highlight
vim.keymap.set("n", "<Esc>", vim.cmd.nohlsearch, { silent = true, desc = "Clear search highlight" })

-- Exit Terminal
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Yanking flash animation
vim.api.nvim_create_autocmd('TextYankPost', {
    desc = 'Highlight when yanking (copying) text',
    group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
    callback = function()
        vim.highlight.on_yank()
    end,
})

require "nvim-autopairs".setup()

---------
-- Theme

vim.cmd.colorscheme "moonfly"

-----------------------
-- Configure Mini Utils

require "mini.ai".setup { n_lines = 500 } -- [v]isual: [a]round, [i]nside, [n]ext, etc
require "mini.surround".setup()           -- [s]urround [a]dd/[d]elete/[r]eplace

require "mini.icons".setup { style = "ascii" }

vim.o.showmode = false
vim.o.cmdheight = 0 -- hide command line completely. Status line is enough.
require "mini.statusline".setup()

require "mini.statusline".section_location = function() return "%2l:%-2v" end
require "mini.statusline".section_diagnostics = function() return "" end -- hide E3 W2 H3 part. This is the number of LSP errors, warnings, etc

if not ARM32 then
    require("mini.cursorword").setup() -- highlight word under cursor
end

----------------------------
-- Which-Key Help Wizard
require "which-key".setup {
    icons = { mappings = false }
}
-- require "which-key".register {
--     { "<leader>c", group = "[C]ode" }, { "<leader>c_", hidden = true },
--     { "<leader>d", group = "[D]ocument" }, { "<leader>d_", hidden = true },
--     { "<leader>p", group = "[P]Panels" }, { "<leader>p_", hidden = true },
--     { "<leader>r", group = "[R]ename" }, { "<leader>r_", hidden = true },
--     { "<leader>s", group = "[S]earch" }, { "<leader>s_", hidden = true },
--     { "<leader>w", group = "[W]orkspace" }, { "<leader>w_", hidden = true },
-- }
--

------
-- LSP
local mason_lsp = {
    "lua_ls",
    "bashls", -- dependency: dnf install nodejs-npm
    "shellcheck",
    "pyright",
}
require "mason".setup()
require "mason-lspconfig".setup {
    ensure_installed = mason_lsp,
}
vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            workspace = {
                library = vim.api.nvim_get_runtime_file("", true)
            }
        }
    }
})
vim.lsp.config("shellcheck", {})
vim.lsp.enable(mason_lsp)

vim.o.winborder = "rounded" -- border around C-w d and S-K popups

vim.keymap.set("n", "<leader>lf", vim.lsp.buf.format, { desc = "Format Document" })
vim.keymap.set("n", "<leader>ls", ":update<CR>:source<CR>", { desc = "Source Document (for config edit)" })
vim.keymap.set("n", "<leader>d", vim.diagnostic.open_float, { desc = "show [d]iagnostics" })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-------
-- Editors
require "neo-tree".setup {
    close_if_last_window = true,
    default_component_configs = {
        icon = {
            default = "",
            folder_closed = "●",
            folder_open = "▶",
            folder_empty = "◌",
            folder_empty_open = "◌",
            use_filtered_colors = false
        }
    }
}

vim.keymap.set("n", "<leader>pf", "<cmd>Neotree toggle left focus<cr>", { desc = "[P]anel [F]iles (neo-tree)" })
vim.keymap.set("n", "<leader>ps", "<cmd>Neotree toggle git_status left focus<cr>", { desc = "[P]anel: git [S]tatus (neo-tree)" })
vim.keymap.set("n", "<leader>pg", "<cmd>Neogit kind=vsplit<cr>", { desc = "[P]anel ([G]it neogit)" })

require "telescope".load_extension("ui-select")

local map = function(keys, func, desc) vim.keymap.set("n", keys, func, { desc = "[F]ind " .. desc }) end
map("<leader>ff", "<cmd>Telescope find_files hidden=true<cr>", "[F]iles")
map("<leader>fa", "<cmd>Telescope find_files hidden=true no_ignore=true<cr>", "[A]ll files")
map("<leader>fr", "<cmd>Telescope oldfiles<cr>", "[R]ecent files")
map("<leader>fb", "<cmd>Telescope buffers<cr>", "[B]uffers (also see <leader><tab>)")
vim.keymap.set("n", "<leader><tab>",
"<cmd>Telescope buffers sort_mru=true ignore_current_buffer=true<cr>",
{desc = "Quick Switch buffers. Will preselect the last used buffers."})
map("<leader>fh", "<cmd>Telescope help_tags<cr>", "[H]elp")
map("<leader>fc", "<cmd>Telescope commands<cr>", "[C]ommands")
map("<leader>fk", "<cmd>Telescope keymaps<cr>", "[K]eymaps")
map("<leader>fgf", "<cmd>Telescope git_files<cr>", "[G]it files")
map("<leader><leader>", "<cmd>Telescope git_files<cr>", "[G]it files")
map("<leader>fgs", "<cmd>Telescope git_status<cr>", "[G]it [S]tatus")
map("<leader>fgc", "<cmd>Telescope git_commits<cr>", "[G]it [C]ommits")
map("<leader>ft", "<cmd>Telescope builtin<cr>", "[T]elescope builtin modes")
map("<leader>fd", "<cmd>Telescope diagnostics<cr>", "[D]iagnostics")

local builtin = require "telescope.builtin"
vim.keymap.set("n", "<leader>/", function()
    builtin.current_buffer_fuzzy_find(require("telescope.themes").get_dropdown {
        winblend = 10,
        previewer = false,
    })
end, { desc = "[/] Fuzzily search in current buffer" })

vim.keymap.set('n', '<leader>fn', function()
    builtin.find_files { cwd = vim.fn.stdpath 'config' }
end, { desc = '[F]ind [N]eovim files' })
vim.keymap.set('n', '<leader>fN', "<cmd>edit $MYVIMRC<CR>", { desc = '[F]ind [N]eovim init.lua' })
