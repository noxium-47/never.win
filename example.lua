local never = loadstring(game:HttpGet("https://raw.githubusercontent.com/noxium-47/never.win/refs/heads/main/lib.luau"))()

local win = never:New({
    name = "Shuffle an Egg",
    size = UDim2.fromOffset(620, 460),
    keybind = Enum.KeyCode.RightShift,
})

local main = win:Tab({ name = "Main" })
local auto = win:Tab({ name = "Auto" })

local a = auto:Section({ name = "Steal", side = "left" })

a:Toggle({
    name = "Auto Steal",
    default = false,
    pointer = "AutoSteal",
    callback = function(v)
        print("AutoSteal:", v)
    end,
})

a:Slider({
    name = "Range",
    min = 5, max = 100, default = 20,
    pointer = "StealRange",
    callback = function(v)
        print("range:", v)
    end,
})

a:Button({
    name = "Grab Now",
    callback = function()
        print("grab")
    end,
})

a:Keybind({
    name = "Panic",
    default = "F1",
    pointer = "PanicKey",
    callback = function(k)
        print("bound:", k)
    end,
})

local b = auto:Section({ name = "Eggs", side = "right" })

b:Toggle({ name = "Auto Skip", pointer = "AutoSkip" })
b:Textbox({ name = "Player name", pointer = "TargetName" })
b:Dropdown({
    name = "Speed mode",
    options = { "Normal", "Fast", "Ludicrous" },
    default = "Normal",
    pointer = "SpeedMode",
    callback = function(v) print("mode:", v) end,
})

-- читать значения
task.spawn(function()
    while task.wait(0.5) do
        print("AutoSteal:", never.pointers.AutoSteal:get())
    end
end)

-- toggle UI вручную
never.keybind = Enum.KeyCode.RightShift  -- уже встроено

-- unload
-- win:Unload()
