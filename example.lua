local never, util = loadstring(game:HttpGet("https://raw.githubusercontent.com/noxium-47/never.win/refs/heads/main/lib.luau"))()

local win = never:New({
    name = "never.win | full demo",
    size = Vector2.new(600, 500),
})

-- ===== TABS =====
local Tabs = {
    Main    = win:Tab({ name = "Main" }),
    Inputs  = win:Tab({ name = "Inputs" }),
    Config  = win:Tab({ name = "Config" }),
}

-- ===== MAIN =====
local left = Tabs.Main:Section({ name = "Buttons", side = "left" })

left:Button({ name = "Simple button", callback = function()
    print("clicked")
end })

left:Button({ name = "Button with notify", callback = function()
    print("notify")
end })

left:Button({ name = "Kill all", callback = function()
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        if p ~= game:GetService("Players").LocalPlayer and p.Character then
            p.Character:BreakJoints()
        end
    end
end })

local left2 = Tabs.Main:Section({ name = "Toggles", side = "left" })

left2:Toggle({ name = "God mode", default = false, pointer = "GodMode",
    callback = function(v) print("GodMode:", v) end })

left2:Toggle({ name = "Infinite jump", default = false, pointer = "InfJump",
    callback = function(v) print("InfJump:", v) end })

left2:Toggle({ name = "Speed hack", default = false, pointer = "SpeedHack",
    callback = function(v)
        local hum = game:GetService("Players").LocalPlayer.Character
            and game:GetService("Players").LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v and 100 or 16 end
    end })

local right = Tabs.Main:Section({ name = "Info", side = "right" })

right:Button({ name = "Print players", callback = function()
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        print(p.Name, p.UserId)
    end
end })

right:Button({ name = "Print position", callback = function()
    local c = game:GetService("Players").LocalPlayer.Character
    local r = c and c:FindFirstChild("HumanoidRootPart")
    print(r and tostring(r.Position) or "no char")
end })

-- ===== INPUTS =====
local sliders = Tabs.Inputs:Section({ name = "Sliders", side = "left" })

sliders:Slider({ name = "WalkSpeed", min = 16, max = 500, def = 16, dec = 1,
    pointer = "WalkSpeed", callback = function(v)
        local c = game:GetService("Players").LocalPlayer.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if hum then hum.WalkSpeed = v end
    end })

sliders:Slider({ name = "JumpPower", min = 50, max = 500, def = 50, dec = 1,
    pointer = "JumpPower", callback = function(v)
        local c = game:GetService("Players").LocalPlayer.Character
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        if hum then hum.JumpPower = v end
    end })

sliders:Slider({ name = "Field of view", min = 70, max = 120, def = 70, dec = 1,
    pointer = "FOV", callback = function(v)
        workspace.CurrentCamera.FieldOfView = v
    end })

local textboxes = Tabs.Inputs:Section({ name = "Textboxes", side = "left" })

textboxes:Textbox({ name = "Player name", def = "", pointer = "PlayerName",
    callback = function(v) print("typed:", v) end })

textboxes:Textbox({ name = "Amount", def = "10", pointer = "Amount",
    callback = function(v) print("amount:", tonumber(v)) end })

textboxes:Button({ name = "Teleport to player", callback = function()
    local target = never.pointers.PlayerName:Get()
    local plr = game:GetService("Players"):FindFirstChild(target)
    if plr and plr.Character then
        local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
        local myHrp = game:GetService("Players").LocalPlayer.Character
            and game:GetService("Players").LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp and myHrp then
            myHrp.CFrame = hrp.CFrame + Vector3.new(0, 3, 0)
        end
    end
end })

local dropdowns = Tabs.Inputs:Section({ name = "Dropdowns", side = "right" })

dropdowns:Dropdown({ name = "Speed mode", options = {"Normal", "Fast", "Ludicrous"},
    def = "Normal", pointer = "SpeedMode", callback = function(v)
        print("mode:", v)
    end })

dropdowns:Dropdown({ name = "Target player", options = (function()
    local t = {}
    for _, p in ipairs(game:GetService("Players"):GetPlayers()) do
        table.insert(t, p.Name)
    end
    return t
end)(), def = "", pointer = "TargetPlayer", callback = function(v)
    print("target:", v)
end })

dropdowns:Dropdown({ name = "Multi select", options = {"A","B","C","D"},
    multi = true, def = {"A"}, pointer = "MultiDD", callback = function(v)
        print("multi:", table.concat(v, ","))
    end })

local keys = Tabs.Inputs:Section({ name = "Keybinds", side = "right" })

keys:Keybind({ name = "Menu toggle", def = "RightShift", pointer = "MenuKey" })
keys:Keybind({ name = "Panic", def = "F1", pointer = "PanicKey" })
keys:Keybind({ name = "Fly", def = "F", pointer = "FlyKey" })

keys:Toggle({ name = "Keybind toggle demo", default = false, pointer = "KbDemo" })
    :Keybind({ name = "Kb Demo", def = "K", pointer = "KbDemoKey" })

-- ===== CONFIG =====
local cfg = Tabs.Config:Section({ name = "Actions", side = "left" })

cfg:Button({ name = "Print all pointers", callback = function()
    for name, ptr in pairs(never.pointers) do
        local ok, v = pcall(function() return ptr:Get() end)
        print(name, ok and tostring(v) or "err")
    end
end })

cfg:Button({ name = "Print all flags", callback = function()
    for k, v in pairs(never.flags) do
        print(k, tostring(v))
    end
end })

cfg:Button({ name = "Toggle UI", callback = function() win:Fade() end })
cfg:Button({ name = "Unload", callback = function() win:Unload() end })

local themeSec = Tabs.Config:Section({ name = "Themes", side = "right" })

themeSec:Button({ name = "Blue (default)", callback = function()
    win:SetTheme({
        accent = Color3.fromRGB(90, 120, 255),
        bg = Color3.fromRGB(18, 18, 22),
        panel = Color3.fromRGB(28, 28, 34),
        section = Color3.fromRGB(36, 36, 44),
        outline = Color3.fromRGB(8, 8, 10),
        outline2 = Color3.fromRGB(52, 52, 62),
        text = Color3.fromRGB(240, 240, 245),
        subtext = Color3.fromRGB(150, 150, 165),
    })
end })

themeSec:Button({ name = "Blood", callback = function()
    win:SetTheme({
        accent = Color3.fromRGB(200, 40, 40),
        bg = Color3.fromRGB(20, 8, 10),
        panel = Color3.fromRGB(34, 12, 14),
        section = Color3.fromRGB(48, 16, 18),
        outline = Color3.fromRGB(0, 0, 0),
        outline2 = Color3.fromRGB(70, 20, 22),
        text = Color3.fromRGB(255, 230, 230),
        subtext = Color3.fromRGB(180, 120, 120),
    })
end })

themeSec:Button({ name = "Matrix", callback = function()
    win:SetTheme({
        accent = Color3.fromRGB(40, 220, 80),
        bg = Color3.fromRGB(6, 14, 6),
        panel = Color3.fromRGB(10, 22, 10),
        section = Color3.fromRGB(14, 30, 14),
        outline = Color3.fromRGB(0, 0, 0),
        outline2 = Color3.fromRGB(20, 50, 20),
        text = Color3.fromRGB(200, 255, 200),
        subtext = Color3.fromRGB(120, 180, 120),
    })
end })

themeSec:Button({ name = "Void", callback = function()
    win:SetTheme({
        accent = Color3.fromRGB(160, 60, 255),
        bg = Color3.fromRGB(10, 5, 20),
        panel = Color3.fromRGB(16, 9, 30),
        section = Color3.fromRGB(22, 12, 40),
        outline = Color3.fromRGB(0, 0, 0),
        outline2 = Color3.fromRGB(45, 25, 75),
        text = Color3.fromRGB(230, 210, 255),
        subtext = Color3.fromRGB(150, 120, 190),
    })
end })

-- ===== INIT =====
win:Init()

-- ===== MENU TOGGLE =====
game:GetService("UserInputService").InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        win:Fade()
    end
end)

-- ===== MAIN LOOP =====
task.spawn(function()
    while task.wait(0.5) do
        if never.pointers.SpeedHack and never.pointers.SpeedHack:Get() then
            local c = game:GetService("Players").LocalPlayer.Character
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            if hum then hum.WalkSpeed = 100 end
        end
        if never.pointers.GodMode and never.pointers.GodMode:Get() then
            local c = game:GetService("Players").LocalPlayer.Character
            local hum = c and c:FindFirstChildOfClass("Humanoid")
            if hum then hum.MaxHealth = math.huge; hum.Health = math.huge end
        end
    end
end)

print("[never.win] demo loaded")
