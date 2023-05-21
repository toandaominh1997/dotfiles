local status_ok, configs = pcall(require, "nvim-treesitter.configs")
if not status_ok then
	return
end

configs.setup({
	ensure_installed = { 
    "c",
    "cpp",
    "css",
    "dockerfile",
    "lua", 
    "python", 
    "javascript", 
    "typescript", 
    "go", 
    "java",
    "json",
    "kotlin",
    "rust",
    "scala",
    "sql",
    "vim", 
    "yaml",
    "terraform",
    "toml",
    "starlark"
  },
  sync_install = false,
  auto_install = true,

	ignore_install = { "" }, -- List of parsers to ignore installing
	highlight = {
		enable = true, 
		disable = { "lua" }, 
    disable = function(lang, buf)
        local max_filesize = 100 * 1024 -- 100 KB
        local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
        if ok and stats and stats.size > max_filesize then
            return true
        end
    end,
    additional_vim_regex_highlighting = false,
	},
})
