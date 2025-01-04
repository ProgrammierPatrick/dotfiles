vim.g.mapleader = " "
vim.g.maplocalleader = vim.g.mapleader -- leader bound to buffer. Always use global leader!

-- system flags
ARM32 = vim.loop.os_uname().machine == "armv6l"
WIN = vim.fn.has 'win32' == 1

vim.opt.number = true -- line numbers
vim.opt.showmode = false -- disable "-- insert --" text on the bottom. Integrated to status bar anyway.
vim.opt.cmdheight = 0 -- hide command line completely. Status line is enough.
vim.opt.clipboard = "unnamedplus" -- use OS clipboard
vim.opt.breakindent = false -- does not indents wrapped lines.
vim.opt.undofile = false -- Only keep undos as long as neovim is running
vim.opt.ignorecase = true -- search: ignore case
vim.opt.smartcase = true  -- search: enable when uppercase letter found
vim.opt.hlsearch = true -- create search highlights
vim.opt.signcolumn = "yes" -- sign column: used for information and breakpoints. Show always to prevent flickering of text.
vim.opt.updatetime = 1000 -- ms. Auto-save for recovery after updatetime when stopped pressing keys
vim.opt.timeoutlen =  500 -- ms. Time to wait for additional keys in key sequence
vim.opt.splitright = true
vim.opt.splitbelow = true
vim.opt.list = true -- show trailing whitespace
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }
vim.opt.inccommand = "split" -- TODO explore: tjdev: Preview substitutions live, as you type!
vim.opt.scrolloff = 5 -- keep cursor away from top and bottom border
vim.opt.tabstop = 4 -- one tab is 4 spaces
vim.opt.shiftwidth = 4 -- each indent is 4 spaces
vim.opt.expandtab = true -- use spaces only

-- somehow this slows down text editing on VERY bad CPUs
if not ARM32 then
    vim.opt.cursorline = true -- highlight current line. Theme required to make this bearable!
end

-- Clear search highlight
vim.keymap.set("n", "<Esc>", "<cmd>noh<CR>")

-- Diagnostic keymaps
vim.keymap.set('n', '<d', vim.diagnostic.goto_prev, { desc = 'Go to previous [D]iagnostic message' })
vim.keymap.set('n', '>d', vim.diagnostic.goto_next, { desc = 'Go to next [D]iagnostic message' })
vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Show diagnostic [E]rror messages' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- Terminal
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- Yanking flash animation
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})


-- NeoVIM Lua editing
local function get_selected_text(mode, mark1, mark2)
    local l1, c1, l2, c2 = mark1[2], mark1[3], mark2[2], mark2[3]
    if l1 > l2 or l1 == l2 and c1 > c2 then l1, c1, l2, c2 = l2, c2, l1, c1 end
    local lines = vim.fn.getline(l1, l2)
    if mode == "line" then
        -- do nothing, use all lines
    elseif mode == "char" then
        lines[1] = string.sub(lines[1], c1)
        lines[#lines] = string.sub(lines[#lines], 1, c2)
    elseif mode == "block" then
        for _, line in ipairs(lines) do
            line = string.sub(lines[1], c1, c2)
        end
    else
        print("ERROR: unknown mode", mode)
        return ""
    end
    return table.concat(lines, "\n")
end

function Execute_selected_lua(mode, is_visual)
    local pos1, pos2
    if is_visual then
        pos1, pos2 = vim.fn.getpos("."), vim.fn.getpos("v")
    else
        pos1, pos2 = vim.fn.getpos("'["), vim.fn.getpos("']")
    end
    -- <leader>ll will move cursor to l, thus selecting one char. In this case, use whole line.
    if pos1[2] == pos2[2] and pos1[3] == pos2[3] then mode = "line" end
    local text = get_selected_text(mode, pos1, pos2)
    local chunk = loadstring(text)
    if not chunk then print("Error compiling chunk!"); return end
    local ret = chunk()
    if ret then print(ret) end
    -- TODO: read on how to use treesitter to check if chunk is expression, which allows automatic result extraction.
end

vim.keymap.set("n", "<leader>l", function()
    vim.o.operatorfunc = "v:lua.Execute_selected_lua"
    return "g@"
end, {expr = true, desc = "Execute selected [L]ua code"})
vim.keymap.set("v", "<leader>l", function() Execute_selected_lua("char", true) end, {desc = "Execute selected [L]ua code" })
vim.keymap.set("x", "<leader>l", function() Execute_selected_lua("line", true) end, {desc = "Execute selected [L]ua code" })

-- init package manager
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    vim.fn.system { "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath }
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({

    -- theme
    {
        "navarasu/onedark.nvim",
        enabled = true,
        lazy = false, priority = 1000, -- in case other packages read this
        opts = { style = "darker" },
        config = function(_, opts)
            require("onedark").setup(opts)
            vim.cmd.colorscheme "onedark"
        end,
    },

    -- general utils
    { "vladdoster/remember.nvim", opts = {}, }, -- remember cursor position in each file
    { -- gcc for commenting out/in lines
        "numToStr/Comment.nvim",
        keys = { { "gc", mode = { "n", "x", "v" } } }, -- arm32: load on key press
        event = not ARM32 and "VeryLazy" or nil,       -- others: load at startup
        opts = {}
    },
    "xiyaowong/transparent.nvim", -- hide background color. Useful for terminals, which have semi transparent blacks!. Control using :Transparent*
    {
        "echasnovski/mini.nvim",
        dependencies = { "lewis6911/gitsigns.nvim" },
        event = "VeryLazy",
        config = function()
            require("mini.ai").setup { n_lines = 500 } -- [v]isual: [a]round, [i]nside [n]ext, etc
            require("mini.surround").setup() -- [s]urround [a]dd/[d]elete/[r]eplace
            require("mini.statusline").setup {
                use_icons = false, -- icons require nerdfont
            }
            if not ARM32 then
                require("mini.cursorword").setup() -- highlight word under cursor
            end
            -- require("mini.pairs").setup() -- auto add closing parens like in vsc*de disabled due to being too bad.
            MiniStatusline.section_location = function() return "%2l:%-2v" end
            MiniStatusline.section_diagnostics = function() return "" end -- hide E3 W2 H3 part. This is the number of LSP errors, warnings, etc
        end,
    },
    { "windwp/nvim-autopairs", event = "InsertEnter", opts = { }, },
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        config = function()
            local which_key = require("which-key")
            which_key.setup()
            which_key.register {
                ["<leader>c"] = { name = "[C]ode", _ = "which_key_ignore" },
                ["<leader>d"] = { name = "[D]ocument", _ = "which_key_ignore" },
                ["<leader>r"] = { name = "[R]ename", _ = "which_key_ignore" },
                ["<leader>s"] = { name = "[S]earch", _ = "which_key_ignore" },
                ["<leader>w"] = { name = "[W]orkspace", _ = "which_key_ignore" },
                ["<leader>p"] = { name = "[P]Panels", _ = "which_key_ignore" },
            }
        end,
    },

    -- copilot autocomplete (requires active GitHub subscription). Activate with :Copilot setup
    "github/copilot.vim",

    -- panel style plugins
    { -- file browser
        "nvim-neo-tree/neo-tree.nvim",
        keys = { -- lazy load on these key maps
            { "<leader>pf", "<cmd>Neotree toggle left focus<cr>", desc = "[P]anel [F]iles (neo-tree)" },
            { "<leader>ps", "<cmd>Neotree toggle git_status left focus<cr>", desc = "[P]anel: git [S]tatus (neo-tree)" },
        },
        branch = "v3.x",
        dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" },
        opts = {
            close_if_last_window = true,
            default_component_configs = {
                icon = {
                    folder_closed = "●",
                    folder_open = "▶",
                    folder_empty = "◌",
                }
            }
        },
    },

    { -- git status editor and git tree browser
        "NeogitOrg/neogit",
        keys = {
            { "<leader>pg", "<cmd>Neogit kind=vsplit<cr>", desc = "[P]anel ([G]it neogit)"}
        },
        dependencies = { "sindrets/diffview.nvim", "nvim-lua/plenary.nvim", "nvim-telescope/telescope.nvim" },
        opts = {
            graph_style = "unicode",
        },
    },
    { -- diff side by side view
        "sindrets/diffview.nvim",
        keys = {
            { "<leader>gg", "<cmd>DiffviewOpen<cr>", desc = "[G]oto [G]it diff (diffview)"}
        }
    },
    { -- Adds git related signs to the gutter, as well as utilities for managing changes
        'lewis6991/gitsigns.nvim',
        opts = {
            signs = {
                -- add = { text = '+' },
                -- change = { text = '~' },
                -- delete = { text = '_' },
                -- topdelete = { text = '‾' },
                -- changedelete = { text = '~' },
            }
        },
    },

    -- telescope: fuzzy finder
    {
        "nvim-telescope/telescope.nvim",
        event = "VeryLazy",
        branch = "0.1.x",
        dependencies = {
            "nvim-lua/plenary.nvim",
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
                config = function()
                    if WIN then
                        local cmake_path = [[;C:\Program Files\Microsoft Visual Studio\2022\Community\Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin]]
                        vim.fn.setenv("PATH", vim.fn.getenv("PATH") .. cmake_path)
                    end
                end,
            },
            "nvim-telescope/telescope-ui-select.nvim", -- replace nvim system vim.ui.select() dialog with telescope
            -- requires nerdfont: "nvim-tree/nvim-web-devicons",
        },
        config = function()
            require("telescope").setup {
                extensions = {
                    ["ui-select"] = {
                        require("telescope.themes").get_dropdown(),
                    }
                },
            }

            pcall(require('telescope').load_extension, 'fzf')
            pcall(require('telescope').load_extension, 'ui-select')

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
        end,
    },

    {
        "neovim/nvim-lspconfig",
        enabled = not ARM32,
        dependencies = {
            -- Automatically install LSPs and related binary tools to stdpath for neovim
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "WhoIsSethDaniel/mason-tool-installer.nvim",

            -- widget showing update
            {
                "j-hui/fidget.nvim",
                event = "VeryLazy",
                opts = {
                    -- notification = { window = { align = "top" } },
                },
            },
        },
        config = function()
            -- setup custom file type associations
            vim.filetype.add {
                extension = {
                    vert = "glsl", tesc = "glsl", tese = "glsl", geom = "glsl", frag = "glsl", comp = "glsl",
                }
            }

            -- called every time an LSP attaches to a buffer. Init LSP-related stuff here
            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
                callback = function(event)
                    --
                    -- helper lambda to init key bindings for correct buffer
                    local map = function(keys, func, desc)
                        vim.keymap.set("n", keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
                    end

                    -- main LSP-based navigation
                    map("gd", require("telescope.builtin").lsp_definitions, "[G]oto [D]efinition")
                    map("gr", require("telescope.builtin").lsp_references, "[G]oto [R]eferences")
                    map("gI", require("telescope.builtin").lsp_implementations, "[G]oto [I]mplementation")
                    map("<leader>D", require("telescope.builtin").lsp_type_definitions, "Type [D]definitions")
                    map("<leader>ds", require("telescope.builtin").lsp_document_symbols, "[D]ocument [S]ymbols")
                    map("<leader>ws", require("telescope.builtin").lsp_dynamic_workspace_symbols, "[W]orkspace [S]ymbols")
                    map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
                    map("<leader>ca", vim.lsp.buf.code_action, "[C]ode [A]ction")
                    map("K", vim.lsp.buf.hover, "Hover Documentation")
                    map("gD", vim.lsp.buf.declaration, "[G]oto [D]eclaration")

                    -- When cursor stops moving, show references
                    local client = vim.lsp.get_client_by_id(event.data.client_id)
                    if client and client.server_capabilities.documentHighlightProvider then
                        vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                            buffer = event.buf,
                            callback = vim.lsp.buf.document_highlight,
                        })

                        vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
                            buffer = event.buf,
                            callback = vim.lsp.buf.clear_references,
                        })
                    end
                end
            })

            -- NVim by itself cannot do anything with LSP messages. Add capabilites with plugins
            local capabilities = vim.lsp.protocol.make_client_capabilities()

            -- provide LSP-based completion to neovim
            capabilities = vim.tbl_deep_extend("force", capabilities, require("cmp_nvim_lsp").default_capabilities())

            -- docs for server settings are in :h lspconfig-all
            local servers = {
                lua_ls = {
                    settings = {
                        Lua = {
                            completion = {
                                callSnippet = "Replace",
                            },
                            workspace = {
                                checkThirdParty = false,
                                library = vim.api.nvim_get_runtime_file("", true),
                            },
                        },
                    },
                },
                yamlls = {
                    settings = {
                        yaml = {
                            schemas = {
                                ["https://raw.githubusercontent.com/compose-spec/compose-spec/master/schema/compose-spec.json"] = "docker-compose.yml"
                            },
                        },
                    },
                },
                clangd = {}, -- C / C++ highlighting (requires compile_definitions.json, genenated by e.g. cmake)
                glsl_analyzer = {}, -- OpenGL Shading Language
                rust_analyzer = {},
                pyright = {},
                bashls = {},
            }

            -- remember: mason provides us the language server binaries. Check state with :Mason
            require("mason").setup()

            -- Mason package list. Use server names for convenience
            local ensure_installed = vim.tbl_keys(servers)
            vim.list_extend(ensure_installed, {
                "stylua", -- lua formatter
                "shellcheck" -- bash tips and best practices. used by bashls.
            })

            require("mason-tool-installer").setup { ensure_installed = ensure_installed }

            -- connects Mason packages to the corresponding lspconfig languages
            require("mason-lspconfig").setup {
                handlers = {
                    function(server_name)
                        local server = servers[server_name] or {}
                        server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
                        require("lspconfig")[server_name].setup(server)
                    end,
                },
            }
        end,
    },

    { -- autocompletion plugin
        'hrsh7th/nvim-cmp',
        event = 'InsertEnter',
        enabled = not ARM32,
        dependencies = {
            -- Snippet Engine & its associated nvim-cmp source
            {
                'L3MON4D3/LuaSnip',
                build = (function()
                    -- Build Step is needed for regex support in snippets
                    if WIN or vim.fn.executable 'make' == 0 then
                        return
                    end
                    return 'make install_jsregexp'
                end)(),
            },
            'saadparwaiz1/cmp_luasnip',
            'hrsh7th/cmp-nvim-lsp',
            'hrsh7th/cmp-path',

            -- If you want to add a bunch of pre-configured snippets,
            --    you can use this plugin to help you. It even has snippets
            --    for various frameworks/libraries/etc. but you will have to
            --    set up the ones that are useful for you.
            -- 'rafamadriz/friendly-snippets',
        },
        config = function()
            -- See `:help cmp`
            local cmp = require 'cmp'
            local luasnip = require 'luasnip'
            luasnip.config.setup {}

            cmp.setup {
                snippet = {
                    expand = function(args)
                        luasnip.lsp_expand(args.body)
                    end,
                },
                completion = {
                --     -- menu: popup menu while typing symbol
                --     -- menuone: always show popup menu, even when only one match
                --     -- preview: show documentation besides preview window
                --
                --     -- completeopt = 'menu,menuone,noinsert', -- suggested by kickstart
                --     -- completeopt = "menu,preview", -- default value by nvim: show menu and put doc to the right. Nothing in parens.
                    completeopt = "menuone",
                },
                formatting = { expandable_indicator = false }, -- hide ugly ~ in menu
                matching = { disallow_fuzzy_matching = false, },
                view = { docs = { auto_open = true } }, -- TODO not sure what this does
                window = { completion = { scrolloff = 1 } },
                experimental = { ghost_text = true }, -- show preview of selection at cursor

                -- For an understanding of why these mappings were
                -- chosen, you will need to read `:help ins-completion`
                --
                -- No, but seriously. Please read `:help ins-completion`, it is really good!
                mapping = cmp.mapping.preset.insert {
                    -- Select the [n]ext item
                    ['<C-n>'] = cmp.mapping.select_next_item(),
                    -- Select the [p]revious item
                    ['<C-p>'] = cmp.mapping.select_prev_item(),

                    -- Accept ([y]es) the completion.
                    --  This will auto-import if your LSP supports it.
                    --  This will expand snippets if the LSP sent a snippet.
                    -- ['<C-y>'] = cmp.mapping.confirm { select = true },
                    ['<CR>'] = cmp.mapping.confirm { select = true },
                    ['<tab>'] = cmp.mapping.confirm { select = true },

                    -- Manually trigger a completion from nvim-cmp.
                    --  Generally you don't need this, because nvim-cmp will display
                    --  completions whenever it has completion options available.
                    ['<C-Space>'] = cmp.mapping.complete {},

                    -- Think of <c-l> as moving to the right of your snippet expansion.
                    --  So if you have a snippet that's like:
                    --  function $name($args)
                    --    $body
                    --  end
                    --
                    -- <c-l> will move you to the right of each of the expansion locations.
                    -- <c-h> is similar, except moving you backwards.
                    ['<C-l>'] = cmp.mapping(function()
                        if luasnip.expand_or_locally_jumpable() then
                            luasnip.expand_or_jump()
                        end
                    end, { 'i', 's' }),
                    ['<C-h>'] = cmp.mapping(function()
                        if luasnip.locally_jumpable(-1) then
                            luasnip.jump(-1)
                        end
                    end, { 'i', 's' }),
                },
                sources = {
                    {
                        name = 'nvim_lsp',
                        -- Filter out Text completions
                        entry_filter = function(entry, _)
                            -- kind table: https://github.com/neovim/neovim/blob/master/runtime/lua/vim/lsp/protocol.lua
                            local text_kind = 1
                            return entry:get_kind() ~= text_kind
                        end,
                    },
                    { name = 'luasnip' },
                    { name = 'path' },
                },
            }
        end,
    },

    { -- Highlight, edit, and navigate code
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        enabled = not ARM32, -- treesitter is too slow for poor old raspi, use old vim regex highlighting instead :(
        config = function()
            -- [[ Configure Treesitter ]] See `:help nvim-treesitter`

            ---@diagnostic disable-next-line: missing-fields
            require('nvim-treesitter.configs').setup {
                auto_install = true,
                highlight = {
                    enable = true,
                },
                indent = { enable = true },
            }
        end,
    },
})
