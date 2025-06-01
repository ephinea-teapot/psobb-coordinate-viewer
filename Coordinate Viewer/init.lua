-- imports
local core_mainmenu = require("core_mainmenu")
local cfg = require("Coordinate Viewer.configuration")
local lib_theme_loaded, lib_theme = pcall(require, "Theme Editor.theme")
local lib_characters = require("solylib.characters")

local ttf = require("Coordinate Viewer.ttf")

-- options
local optionsLoaded, options = pcall(require, "Coordinate Viewer.options")
local optionsFileName = "addons/Coordinate Viewer/options.lua"
local firstPresent = true
local ConfigurationWindow

if optionsLoaded then
  options.configurationEnableWindow = options.configurationEnableWindow == nil and true or
      options.configurationEnableWindow
  options.enable = options.enable == nil and true or options.enable
  options.EnableWindow = options.EnableWindow == nil and true or options.EnableWindow
  options.useCustomTheme = options.useCustomTheme == nil and false or options.useCustomTheme
  options.NoTitleBar = options.NoTitleBar or ""
  options.NoResize = options.NoResize or ""
  options.Transparent = options.Transparent == nil and false or options.Transparent
  options.fontScale = options.fontScale or 1.0
  options.X = options.X or 100
  options.Y = options.Y or 100
  options.Width = options.Width or 150
  options.Height = options.Height or 80
  options.Changed = options.Changed or false
  options.HighContrast = options.HighContrast == nil and false or options.HighContrast
else
  options = {
    configurationEnableWindow = true,
    enable = true,
    EnableWindow = true,
    useCustomTheme = false,
    NoTitleBar = "",
    NoResize = "",
    Transparent = false,
    fontScale = 1.0,
    X = 100,
    Y = 100,
    Width = 150,
    Height = 80,
    Changed = false,
    HighContrast = false,
  }
end


local function SaveOptions(options)
  local file = io.open(optionsFileName, "w")
  if file ~= nil then
    io.output(file)

    io.write("return {\n")
    io.write(string.format("  configurationEnableWindow = %s,\n", tostring(options.configurationEnableWindow)))
    io.write(string.format("  enable = %s,\n", tostring(options.enable)))
    io.write("\n")
    io.write(string.format("  EnableWindow = %s,\n", tostring(options.EnableWindow)))
    io.write(string.format("  useCustomTheme = %s,\n", tostring(options.useCustomTheme)))
    io.write(string.format("  NoTitleBar = \"%s\",\n", options.NoTitleBar))
    io.write(string.format("  NoResize = \"%s\",\n", options.NoResize))
    io.write(string.format("  Transparent = %s,\n", tostring(options.Transparent)))
    io.write(string.format("  fontScale = %s,\n", tostring(options.fontScale)))
    io.write(string.format("  X = %s,\n", tostring(options.X)))
    io.write(string.format("  Y = %s,\n", tostring(options.Y)))
    io.write(string.format("  Width = %s,\n", tostring(options.Width)))
    io.write(string.format("  Height = %s,\n", tostring(options.Height)))
    io.write(string.format("  Changed = %s,\n", tostring(options.Changed)))
    io.write(string.format("  HighContrast = %s,\n", tostring(options.HighContrast)))
    io.write("}\n")

    io.close(file)
  end
end

local function Text(str)
  if options.HighContrast then
    imgui.TextColored(0, 1, 0, 1, str)
  else
    imgui.Text(0, 1, 0, 1, str)
  end
end

local function printCoordinates(coordinateSummary, X, Y, Z)
  Text(string.format("%s: (%.0f, %.0f, %.0f)", coordinateSummary, X, Y, Z))
end

-- player data
local _PlayerArray = 0x00A94254
local _PlayerIndex = 0x00A9C4F4

-- shows your coordinates
local showCoordinates = function()
  local playerIndex = pso.read_u32(_PlayerIndex)
  local playerAddr = pso.read_u32(_PlayerArray + 4 * playerIndex)

  if playerAddr ~= 0 then
    -- raw coords
    local X = pso.read_f32(playerAddr + 0x38) -- left/right
    local Y = pso.read_f32(playerAddr + 0x3C) -- up/down
    local Z = pso.read_f32(playerAddr + 0x40) -- out/in

    local floor = lib_characters.GetPlayerFloor(playerAddr)
    local result = ttf.directionToTeleportZone(floor, X, Z)

    Text(string.format("FloorID : %i", floor))
    printCoordinates("Pos", X, Y, Z)
    if type(result) == 'table' then
      local dx = result.dx
      local dy = 0
      local dz = result.dy
      printCoordinates("To TP", dx, dy, dz)
    elseif result == true then
      imgui.TextColored(1, 0, 0, 1, "On Teleporter!")
    end

    -- show placeholder if the pointer is null
  else
    if options.HighContrast then
      imgui.TextColored(0, 1, 0, 1, "Unable to get coordinates")
    else
      imgui.Text("Unable to get coordinates")
    end
  end
end

-- config setup and drawing
local function present()
  if options.configurationEnableWindow then
    ConfigurationWindow.open = true
    options.configurationEnableWindow = false
  end

  ConfigurationWindow.Update()
  if ConfigurationWindow.changed then
    ConfigurationWindow.changed = false
    SaveOptions(options)
  end

  if options.enable == false then
    return
  end

  if lib_theme_loaded and options.useCustomTheme then
    lib_theme.Push()
  end

  if options.Transparent == true then
    imgui.PushStyleColor("WindowBg", 0.0, 0.0, 0.0, 0.0)
  end

  if options.EnableWindow then
    if firstPresent or options.Changed then
      options.Changed = false

      imgui.SetNextWindowPos(options.X, options.Y, "Always")
      imgui.SetNextWindowSize(options.Width, options.Height, "Always");
    end

    if imgui.Begin("Coordinate Viewer", nil, { options.NoTitleBar, options.NoResize }) then
      imgui.SetWindowFontScale(options.fontScale)
      showCoordinates();
    end
    imgui.End()
  end

  if options.Transparent == true then
    imgui.PopStyleColor()
  end

  if lib_theme_loaded and options.useCustomTheme then
    lib_theme.Pop()
  end

  if firstPresent then
    firstPresent = false
  end
end


local function init()
  ConfigurationWindow = cfg.ConfigurationWindow(options, lib_theme_loaded)

  local function mainMenuButtonHandler()
    ConfigurationWindow.open = not ConfigurationWindow.open
  end

  core_mainmenu.add_button("Coordinate Viewer", mainMenuButtonHandler)

  if lib_theme_loaded == false then
    print("Coordinate Viewer : lib_theme couldn't be loaded")
  end

  return {
    name = "Coordinate Viewer",
    version = "1.2.0",
    author = "Seth Clydesdale",
    description = "Displays your X, Y, and Z coordinates.",
    present = present
  }
end

return {
  __addon = {
    init = init
  }
}
