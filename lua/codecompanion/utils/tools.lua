--[[
	Utility functions for tools
--]]
local M = {}

---Build a shell command from the given arguments
---@param args string[]
---@return string[]
function M.build_shell_command(args)
  if vim.fn.has("win32") == 1 then
    -- Parameter quoting rules on Windows are complicated, because
    -- Windows programs only receive one big string with all arguments
    -- which they or msvcrt split back into argv. libuv used by NeoVim
    -- tries to be helpful, but ends up sending literal quotes to cmd.exe
    -- (programs get `"C:\file.txt"` with quotes instead of `C:\file.txt`)
    -- or not literal enough to powershell (literal empty arguments `""` get
    -- lost along the way)
    --
    -- What does work, it spelling out command invocations in a batch file
    -- and letting cmd.exe figure things out. This way, libuv only gets
    -- involved in running `cmd.exe /c "temp.bat"`
    --
    -- This does have the slight downside that if the LLM wants to run cmd
    -- `for ... %i ...` commands, they will fail, but this can be worked
    -- around with prompting.
    local fname = vim.fn.tempname() .. ".bat"
    local file = io.open(fname, "w")
    if file then
      file:write("@echo off", "\n")
      file:write(table.concat(args, " "), "\n")
      file:close()
      return {
        "cmd.exe",
        "/c",
        fname
      }
    else
      return {
        "cmd.exe",
        "/c",
        table.concat(args, " ")
      }
    end
  else
    return {
      "sh",
      "-c",
      table.concat(args, " "),
    }
  end
end

---Strip any ANSI color codes which don't render in the chat buffer
---@param tbl table
---@return table
function M.strip_ansi(tbl)
  for i, v in ipairs(tbl) do
    tbl[i] = v:gsub("\027%[[0-9;]*%a", "")
  end
  return tbl
end

return M
