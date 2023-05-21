
local status_ok, dash = pcall(require, "dashboard")
if not status_ok then
  return
end

dash.setup {
  theme = 'Hyper'
}
