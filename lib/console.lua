local console = {}

console.graphic = {
  copy = function(...)
    if not component.gpu then return end
    component.gpu.copy(...)
  end,
  getResolution = function() return 80,25 end,
  setBG = function(...)
    if not component.gpu then return end
    component.gpu.setBackground(...)
  end,
  setFG = function(...)
    if not component.gpu then return end
    component.gpu.setForeground(...)
  end,
  fill = function(x, y, w, h)
    if not component.gpu then return end
    component.gpu.fill(x, y, w, h, " ")
  end,
  drawText = function(...)
    if not component.gpu then return end
    component.gpu.set(...)
  end
}
local w, h = console.graphic.getResolution()

-- table serialize function
function console.Serialize(o, depth)
  local function ser(o, depth, ind)
    ind = ind or 1
    depth = depth or 3
    depth = depth - 1
    local indn = 0
    local indent = ""
    while indn < ind do
      indent = indent .. "  "
      indn = indn + 1
    end
    local retstr = ""
    if type(o) == "number" then
      retstr = retstr .. o .. ""
    elseif type(o) == "boolean" then
      retstr = retstr .. tostring(o)
    elseif type(o) == "string" then
      retstr = retstr .. string.format("%q", o) .. ""
    elseif type(o) == "table" then
      if depth <= 0 then
        return "<" .. type(o) .. ">"
      end
      retstr = retstr .. "{\n"
      for k, v in pairs(o) do
        retstr = retstr .. indent .. "" .. k .. "="
        retstr = retstr .. ser(v, depth, ind + 1)
        retstr = retstr .. ",\n"
      end
      retstr = retstr .. indent:sub(1, indent:len() - 2) .. "}"
    else
      retstr = retstr .. "<" .. type(o) .. ">"
    end
    return retstr
  end
  return ser(o, depth)
end
-- array to string / string to array
function console.ArrayToStr(tabl)
  local retval = ""
  for i = 1, #tabl do
    retval = retval .. tabl[i]
  end
  return retval
end
function console.StrToArray(str)
  local retval = {}
  for i = 1, #str do
    table.insert(retval, str:sub(i, i))
  end
  return retval
end
-- line output
function console.lineout(str, line)
  console.graphic.fill(1, line, w, 1)
  console.graphic.drawText(1, line, str)
end
function console.lineoutoff(str, line, offs)
  offs = offs or 1
  console.graphic.fill(offs, line, w, 1)
  console.graphic.drawText(offs, line, str)
end
-- history buffer
console.history = {
  --  history system
  mem = {}, -- output lines history
  cmdmem = {}, -- command history
  size = h * 10, -- history size (10 screens)
  viewheight = h - 1, -- height of viewport
  viewbottom = 1, -- current viewport bottom line
  prevbottom = 1, -- previous view bottom
  recallptr = 1, -- pointer for line recall fuction
  printoffset = 1, -- print offset x-axis
  lnum = 1, -- line number accumulator
  scrspeed = 5, -- scroll speed
  scrdir = 0 -- scroll direction
}
function console.history.PrintAll()
  -- reprint viewport
  if next(console.history.mem) == nil then
    return
  end
  for i = 1, console.history.viewheight - 1 do
    local bot = console.history.viewbottom - (i - 1)
    if bot <= 0 then
      return
    end
    local toprint = console.history.mem[bot]
    local cpos = console.history.viewheight - (i - 1)
    console.lineoutoff(toprint, cpos, console.history.printoffset)
  end
end
function console.history.Update()
  -- update viewport
  if next(console.history.mem) == nil then
    return
  end
  if console.history.scrdir == 0 then
    console.history.PrintAll()
  elseif console.history.scrdir > 0 then
    -- user scrolled up
    console.graphic.copy(1, 2, w, h - console.history.scrspeed - 2, 0, console.history.scrspeed)
    for i = 1, console.history.scrspeed do
      local bot = (console.history.viewbottom - console.history.viewheight + 1 + console.history.scrspeed) - (i - 1)
      if bot <= 0 then
        return
      end
      local toprint = console.history.mem[bot]
      local cpos = 1 + console.history.scrspeed - (i - 1)
      console.lineoutoff(toprint, cpos, console.history.printoffset)
    end
  elseif console.history.scrdir < 0 then
    -- user scrolled down
    console.graphic.copy(
      1,
      2 + console.history.scrspeed,
      w,
      h - console.history.scrspeed - 2,
      0,
      -console.history.scrspeed
    )
    for i = 1, console.history.scrspeed do
      local bot = console.history.viewbottom - (i - 1)
      if bot <= 0 then
        return
      end
      local toprint = console.history.mem[bot]
      local cpos = console.history.viewheight - (i - 1)
      console.lineoutoff(toprint, cpos, console.history.printoffset)
    end
  end
  console.history.scrdir = 0 -- reset
end
function console.history.ScrollEnd()
  console.history.prevbottom = console.history.viewbottom
  console.history.viewbottom = #console.history.mem
  console.history.PrintAll() -- reprint history
end
function console.history.ScrollTop()
  console.history.prevbottom = console.history.viewbottom
  console.history.viewbottom = h - 2
  console.history.PrintAll() -- reprint history
end
function console.history.ScrollUp(scr)
  scr = scr or 1
  if #console.history.mem < console.history.viewheight then
    return
  end
  console.history.prevbottom = console.history.viewbottom
  console.history.viewbottom = console.history.viewbottom - scr
  console.history.scrdir = 1
  if console.history.viewbottom <= console.history.viewheight - 1 then
    console.history.scrdir = 0
    console.history.viewbottom = console.history.viewheight - 1
  end
  console.history.Update() -- print out history
end
function console.history.ScrollDown(scr)
  scr = scr or 1
  console.history.prevbottom = console.history.viewbottom
  console.history.viewbottom = console.history.viewbottom + scr
  console.history.scrdir = -1
  if console.history.viewbottom >= #console.history.mem then
    console.history.scrdir = 0
    console.history.viewbottom = #console.history.mem
  end
  console.history.Update() -- print out history
end
function console.history.MoveRecall(pos)
  if next(console.history.cmdmem) == nil then
    return
  end
  pos = pos or 0
  console.history.recallptr = console.history.recallptr + pos
  if console.history.recallptr >= #console.history.cmdmem then
    console.history.recallptr = #console.history.cmdmem
  elseif console.history.recallptr <= 1 then
    console.history.recallptr = 1
  end
end
function console.history.ResetRecall()
  console.history.recallptr = #console.history.cmdmem
end
function console.history.Recall()
  if next(console.history.cmdmem) == nil then
    return ""
  end
  return console.history.cmdmem[console.history.recallptr]
end
function console.history.Add(str)
  str = " " .. tostring(console.history.lnum) .. "  | " .. str
  table.insert(console.history.mem, str)
  console.history.viewbottom = #console.history.mem
  console.history.recallptr = #console.history.cmdmem + 1
  console.history.Update()
  console.history.lnum = console.history.lnum + 1
end
function console.history.AddInp(str)
  table.insert(console.history.cmdmem, str)
  console.history.Add(str)
end
-- input buffer
console.input = {
  buffer = {}, -- input buffer
  col = 1, -- current input column
  printoffset = 1 -- print offset
}
function console.input.Print()
  -- print input
  local out = console.ArrayToStr(console.input.buffer)
  console.lineoutoff(out, h, console.input.printoffset)
end
function console.input.SetPrintOffset(offs)
  console.input.printoffset = offs
end
function console.input.Append(str)
  -- append to input buffer
  table.insert(console.input.buffer, str)
  console.input.Print()
end
function console.input.Insert(str, pos)
  -- insert in input buffer
  pos = pos or console.input.col
  table.insert(console.input.buffer, pos, str)
  console.input.Print()
end
function console.input.SetPos(pos)
  -- set cursor position
  pos = pos or #console.input.buffer
  if pos < 1 then
    pos = 1
  end
  if pos > #console.input.buffer then
    pos = #console.input.buffer + 1
  end
  console.input.col = pos
end
function console.input.MovePos(mov)
  -- move cursor position
  local pos = console.input.col + mov
  console.input.SetPos(pos)
end
function console.input.GetCharAtPos()
  return console.input.buffer[console.input.col]
end
function console.input.GetString()
  return console.ArrayToStr(console.input.buffer)
end

function console.input.Tokenize()
  input = console.ArrayToStr(console.input.buffer)
  local args = {}
  local current = ""
  local in_quote = false
  local quote_char = nil
  local escaped = false
  for i = 1, #input do
    local c = input:sub(i, i)
    if escaped then
      current = current .. c
      escaped = false
    elseif c == "\\" then
      escaped = true
    elseif in_quote then
      if c == quote_char then
        in_quote = false
        quote_char = nil
      else
        current = current .. c
      end
    elseif c == '"' or c == "'" then
      in_quote = true
      quote_char = c
    elseif c:match("%s") then
      if #current > 0 then
        table.insert(args, current)
        current = ""
      end
    else
      current = current .. c
    end
  end
  if #current > 0 then
    table.insert(args, current)
  end
  return args
end

function console.input.DelChar()
  table.remove(console.input.buffer, console.input.col)
  console.input.Print()
end
function console.input.Clear()
  console.input.buffer = {}
  console.input.col = 1
  console.input.Print()
end
function console.input.SetBuffer(str)
  console.input.buffer = console.StrToArray(str)
  console.input.col = #console.input.buffer + 1
  console.input.Print()
end
-- print function
function console.print(str)
  if type(str) == "table" then
    str = console.Serialize(str)
  else
    str = tostring(str)
  end
  local prev = 1
  for w in string.gmatch(str, "()\n") do
    console.history.Add(str:sub(prev, w - 1))
    prev = w + 1
  end
  console.history.Add(str:sub(prev))
end
print = console.print

function console.loop(handler)
  local w, h = console.graphic.getResolution()
  local cx, cy = (w / 2), (h / 2)

  -- screen clear
  console.graphic.fill(1, 2, w, h)
  -- print os header
  console.graphic.setFG(0x000000)
  console.graphic.setBG(0xFFFFFF)
  console.graphic.fill(1, 1, w, 1)
  console.graphic.drawText(1, 1, "  " .. _osname .. " " .. _osversion)
  console.graphic.setFG(0xFFFFFF)
  console.graphic.setBG(0x000000)
  -- console init
  local console_header = "#> "
  local blinkon = true
  local hist = console.history
  local inp = console.input
  console.lineout(console_header, h)
  inp.SetPrintOffset(#console_header + 1)

  -- console loop start
  while true do
    local evt = table.pack(computer.pullSignal(0.4))
    if evt[1] == "key_down" then
      -- command
      if evt[4] == 28 then -- enter key
        hist.AddInp(inp.GetString()) -- add input to history
        console.lineout(console_header, h)
        -- parse command --
        local cmd = inp.Tokenize() -- ou inp.GetString() si tu veux la chaine -- get string
        handler("input_prompt", cmd)
        inp.Clear() -- clear input buffer
      elseif evt[4] == 14 then -- backspace
        if inp.col > 1 then
          inp.MovePos(-1)
          inp.DelChar()
          hist.ResetRecall()
        end
      elseif evt[4] == 200 then -- up key
        hist.MoveRecall(-1)
        inp.SetBuffer(hist.Recall())
      elseif evt[4] == 208 then -- down key
        hist.MoveRecall(1)
        inp.SetBuffer(hist.Recall())
      elseif evt[4] == 203 then -- left key
        inp.MovePos(-1)
      elseif evt[4] == 205 then --  right key
        inp.MovePos(1)
      elseif evt[4] == 199 then -- home
        inp.MovePos(-99999)
      elseif evt[4] == 207 then -- end
        inp.MovePos(99999)
      elseif evt[3] ~= 0 then -- printable keys
        local char = string.char(evt[3])
        inp.Insert(char)
        inp.MovePos(1)
      end
    elseif evt[1] == "scroll" then
      if evt[5] > 0 then -- scroll up
        hist.ScrollUp(hist.scrspeed)
      elseif evt[5] < 0 then -- scroll down
        hist.ScrollDown(hist.scrspeed)
      end
    elseif evt[1] == "clipboard" then
      for char in string.gmatch(evt[3], ".") do
        inp.Insert(char)
        inp.MovePos(1)
      end
    else
      handler(evt[1], table.move(evt, 2, #evt, 1, {}))
    end
    if blinkon then -- cursor blink
      local posx = console.input.col + console.input.printoffset - 1
      console.graphic.setBG(0xFFFFFF)
      console.graphic.fill(posx, h, 1, 1)
      console.graphic.setBG(0x000000)
      blinkon = false
    else
      inp.Print()
      blinkon = true
    end
  end
end

return console
