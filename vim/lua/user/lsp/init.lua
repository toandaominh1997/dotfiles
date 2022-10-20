local status_ok, _ = pcall(require, "lspconfig")
if not status_of then
    return
end

require("user.lsp.handlers").setup()
require "user.lsp.null-ls"
