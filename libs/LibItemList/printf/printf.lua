--[[ printf
     Make there be printf() in Library.printf.*.

     You are assumed to know what this means, and to be clever enough to
     make local references.
     Also a dump function that drops things into a table.

]]--

Library = Library or {}

local addoninfo, printf = ...

local sformat = string.format
local smatch = string.match
local sgsub = string.gsub

local consoles = {}

Library.printf = printf

local html_safe_metatable = {
  __tostring = function(x) return x.s end
}

function printf.html_safe(s)
  local o = { s = s }
  setmetatable(o, html_safe_metatable)
  return o
end

function printf.console(console)
  local me = Inspect.Addon.Current()
  if console then
    consoles[me] = console
  end
  return consoles[me] or 'general'
end

function printf.sprintf(fmt, ...)
  local foo = function(...) return sformat(fmt or 'nil', ...) end
  local status, value = pcall(foo, ...)
  if status then
    return value
  else
    return 'Format "' .. (fmt or 'nil') .. '": ' .. value
  end
end

function printf.sprintfh(fmt, ...)
  local args = { ... }
  for i = 1, #args do
    if type(args[i]) == 'string' then
      args[i] = printf.escape_brackets(args[i])
    elseif type(args[i]) == 'table' then
      args[i] = tostring(args[i])
    end
  end
  return printf.sprintf(fmt, unpack(args))
end

function printf.printf(fmt, ...)
  return printf.cprintf(printf.console(), fmt, ...)
end

local bracket_conversion = {
  ['<'] = '&lt;',
  ['>'] = '&gt;',
}
function printf.escape_brackets(s)
  return sgsub(s, '[<>]', bracket_conversion)
end

function printf.cprintf_generic(console, suppress, html, fmt, ...)
  local text
  if html then
    text = printf.sprintfh(fmt, ...)
  else
    text = printf.sprintf(fmt, ...)
  end
  local status, value = pcall(Command.Console.Display, console, suppress, text, html)
  if status then
    return text
  else
    printf.printf("Display failed: %s", tostring(value))
    return status, value
  end
end

function printf.cprintf(console, fmt, ...)
  return printf.cprintf_generic(console, false, false, fmt, ...)
end

function printf.printfh(fmt, ...)
  return printf.cprintfh(printf.console(), fmt, ...)
end

function printf.cprintfh(console, fmt, ...)
  return printf.cprintf_generic(console, false, true, fmt, ...)
end

function printf.printfs(fmt, ...)
  return printf.cprintfs(printf.console(), fmt, ...)
end

function printf.cprintfs(console, fmt, ...)
  return printf.cprintf_generic(console, true, false, fmt, ...)
end

function printf.printfhs(fmt, ...)
  return printf.cprintfs(printf.console(), fmt, ...)
end

function printf.cprintfhs(console, fmt, ...)
  return printf.cprintf_generic(console, true, true, fmt, ...)
end
