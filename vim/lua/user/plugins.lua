local fn = vim.fn

-- Automatically install packer
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
if fn.empty(fn.glob(install_path)) > 0 then
	PACKER_BOOTSTRAP = fn.system({
		"git",
		"clone",
		"--depth",
		"1",
		"https://github.com/wbthomason/packer.nvim",
		install_path,
	})
	print("Installing packer close and reopen Neovim...")
	vim.cmd([[packadd packer.nvim]])
end

-- Autocommand that reloads neovim whenever you save the plugins.lua file
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost plugins.lua source <afile> | PackerSync
  augroup end
]])

-- Use a protected call so we don't error out on first use
local status_ok, packer = pcall(require, "packer")
if not status_ok then
	return
end

-- Have packer use a popup window
packer.init({
	display = {
		open_fn = function()
			return require("packer.util").float({ border = "rounded" })
		end,
	},
})

return packer.startup(function(use)
  use { "wbthomason/packer.nvim" }

  use { "windwp/nvim-autopairs" }

  use { "kyazdani42/nvim-web-devicons" }

  use { "christoomey/vim-tmux-navigator" }

  -- Colorschemes
  use { "folke/tokyonight.nvim" }
  use { "lunarvim/darkplus.nvim" }
  use { 'navarasu/onedark.nvim' }

  -- Indent 
  use { "lukas-reineke/indent-blankline.nvim" }
  -- Comment
  use { "numToStr/Comment.nvim" }
  use { "JoosepAlviste/nvim-ts-context-commentstring" }

  -- Telescope
  use { "nvim-telescope/telescope.nvim", requires = { {'nvim-lua/plenary.nvim'} } }

  -- Syntax
  use { "nvim-treesitter/nvim-treesitter" }
  use { "kylechui/nvim-surround" }

  -- Cmp
  use { "hrsh7th/nvim-cmp" } -- The completion plugin
  use { "hrsh7th/cmp-buffer" } -- buffer completions
  use { "hrsh7th/cmp-path" } -- path completions
	use { "saadparwaiz1/cmp_luasnip" } -- snippet completions
	use { "hrsh7th/cmp-nvim-lsp" }
	use { "hrsh7th/cmp-nvim-lua" }

  -- Snippets
  use { "L3MON4D3/LuaSnip" } --snippet engine
  use { "rafamadriz/friendly-snippets" } -- a bunch of snippets to use

  -- LSP
	use { "neovim/nvim-lspconfig" } -- enable LSP
  use { "williamboman/mason.nvim" } -- simple to use language server installer
  use { "williamboman/mason-lspconfig.nvim" }
	use { "jose-elias-alvarez/null-ls.nvim" } -- for formatters and linters
  use { "RRethy/vim-illuminate" }

  -- Statusline
  use { "nvim-lualine/lualine.nvim" }
  use { "kyazdani42/nvim-tree.lua" }
  use { "akinsho/bufferline.nvim" }
  use { 'romgrk/barbar.nvim' }

  -- Dashboard 
  use { 'glepnir/dashboard-nvim', event = 'VimEnter', requires = {'nvim-tree/nvim-web-devicons'} }

  -- Extension
  use { 'echasnovski/mini.nvim' }

  -- leap
  use { 'ggandor/leap.nvim' }

  if PACKER_BOOTSTRAP then
		require("packer").sync()
	end
  -- Improve startup time 
  use 'lewis6991/impatient.nvim'

end)
