local status_ok, bufferline = pcall(require, "bufferline")
if not status_ok then
  return
end

bufferline.setup {
  options = {
    mode = "buffers",
    numbers = "both",
    themable = true,

    indicator = {
      icon = "▎",
      style="icon",
    },
    always_show_bufferline = true,
  },
}
