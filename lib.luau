local uis = game:GetService("UserInputService")
local rs = game:GetService("RunService")
local ts = game:GetService("TweenService")
local plrs = game:GetService("Players")
local txt = game:GetService("TextService")

local lplr = plrs.LocalPlayer

local v2 = Vector2.new
local c3 = Color3.fromRGB

local cloneref = cloneref or function(i) return i end
local gethui = gethui or function() return game:GetService("CoreGui") end
local protect = protect_gui or protectgui or function(g) return g end

local never = {
    connections = {},
    flags = {},
    pointers = {},
    version = "0.1.0",
    accent = c3(120, 100, 240),
    bg = c3(8, 8, 13),
    panel = c3(20, 22, 27),
    section = c3(26, 28, 36),
    outline = c3(45, 48, 58),
    text = c3(255, 255, 255),
    subtext = c3(140, 140, 150),
}

local gui = Instance.new("ScreenGui")
protect(gui)
gui.Name = "neverwin_" .. tostring(math.random(1e6, 9e6))
gui.IgnoreGuiInset = true
gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
gui.ResetOnSpawn = false
gui.Parent = gethui()

local function addConn(sig, fn)
    local c = sig:Connect(fn)
    table.insert(never.connections, c)
    return c
end

local function tween(obj, info, props)
    local t = ts:Create(obj, info or TweenInfo.new(0.15), props)
    t:Play()
    return t
end

local function isOver(frame)
    if not frame or not frame.Parent then return false end
    local m = uis:GetMouseLocation()
    local p = frame.AbsolutePosition
    local s = frame.AbsoluteSize
    return m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y
end

local function make(class, props, parent)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    if parent then o.Parent = parent end
    return o
end

local function corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 6)
    c.Parent = obj
    return c
end

local function stroke(obj, col, trans, thick)
    local s = Instance.new("UIStroke")
    s.Color = col or never.outline
    s.Transparency = trans or 0.5
    s.Thickness = thick or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = obj
    return s
end

local function text(parent, props)
    return make("TextLabel", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Font = Enum.Font.GothamMedium,
        TextColor3 = never.text,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Text = "",
        TextTransparency = 0,
        Parent = parent,
    }, nil)
end

local function drag(handle, target)
    local dragging = false
    local start, startPos
    addConn(handle.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            start = input.Position
            startPos = target.Position
            local endConn
            endConn = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    endConn:Disconnect()
                end
            end)
        end
    end)
    addConn(uis.InputChanged, function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - start
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

function never:New(info)
    info = info or {}
    local title = info.name or "never.win"
    local size = info.size or UDim2.fromOffset(620, 460)
    local keybind = info.keybind or Enum.KeyCode.RightShift

    local win = {
        tabs = {},
        current = nil,
        open = true,
        flags = never.flags,
        pointers = never.pointers,
    }

    local root = make("Frame", {
        Name = "root",
        Parent = gui,
        AnchorPoint = v2(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = size,
        BackgroundColor3 = never.bg,
        BackgroundTransparency = 0.05,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Active = true,
    })
    corner(root, 12)

    local shadow = stroke(root, c3(0, 0, 0), 0.6, 2)

    local topbar = make("Frame", {
        Parent = root,
        Size = UDim2.new(1, 0, 0, 44),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    })

    local titleLbl = text(topbar, {
        Parent = topbar,
        Position = UDim2.fromOffset(18, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        Font = Enum.Font.GothamBold,
        TextSize = 15,
        Text = title,
    })

    local versionLbl = text(topbar, {
        Parent = topbar,
        AnchorPoint = v2(1, 0.5),
        Position = UDim2.new(1, -18, 0.5, 0),
        Size = UDim2.fromOffset(80, 16),
        TextXAlignment = Enum.TextXAlignment.Right,
        TextSize = 11,
        TextColor3 = never.subtext,
        Text = "v" .. never.version,
    })

    local divider = make("Frame", {
        Parent = root,
        Position = UDim2.new(0, 12, 0, 44),
        Size = UDim2.new(1, -24, 0, 1),
        BackgroundColor3 = never.outline,
        BackgroundTransparency = 0.5,
        BorderSizePixel = 0,
    })

    local sidebar = make("Frame", {
        Parent = root,
        Position = UDim2.new(0, 0, 0, 45),
        Size = UDim2.new(0, 170, 1, -45),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    })

    local content = make("Frame", {
        Parent = root,
        Position = UDim2.new(0, 170, 0, 45),
        Size = UDim2.new(1, -170, 1, -45),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    })

    local contentStroke = stroke(content, never.outline, 0.5, 1)
    contentStroke.Parent = content

    local tabList = make("Frame", {
        Parent = sidebar,
        Position = UDim2.new(0, 8, 0, 8),
        Size = UDim2.new(1, -16, 1, -16),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    })

    local tabLayout = make("UIListLayout", {
        Parent = tabList,
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 4),
    })

    local function setVisible(v)
        win.open = v
        root.Visible = v
    end

    addConn(uis.InputBegan, function(input)
        if input.KeyCode == keybind then
            setVisible(not win.open)
        end
    end)

    drag(topbar, root)

    function win:Tab(tabInfo)
        tabInfo = tabInfo or {}
        local name = tabInfo.name or "tab"

        local tab = { name = name, sections = {}, sides = {{}, {}}, active = false }

        local btn = make("Frame", {
            Parent = tabList,
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = never.section,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
        })
        corner(btn, 6)

        local btnStroke = stroke(btn, never.outline, 1, 1)

        local btnLbl = text(btn, {
            Parent = btn,
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -24, 1, 0),
            Text = name,
            TextTransparency = 0.5,
        })

        local tabPage = make("Frame", {
            Parent = content,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Visible = false,
        })

        local leftScroll = make("ScrollingFrame", {
            Parent = tabPage,
            Position = UDim2.fromOffset(8, 8),
            Size = UDim2.new(0.5, -12, 1, -16),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        })

        local leftLayout = make("UIListLayout", {
            Parent = leftScroll,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
        })

        local rightScroll = make("ScrollingFrame", {
            Parent = tabPage,
            Position = UDim2.new(0.5, 4, 0, 8),
            Size = UDim2.new(0.5, -12, 1, -16),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 0,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
        })

        local rightLayout = make("UIListLayout", {
            Parent = rightScroll,
            SortOrder = Enum.SortOrder.LayoutOrder,
            Padding = UDim.new(0, 6),
        })

        tab.btn = btn
        tab.page = tabPage

        function tab:Show()
            tabPage.Visible = true
            tab.active = true
            tween(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.5 })
            tween(btnLbl, TweenInfo.new(0.15), { TextTransparency = 0 })
            tween(btnStroke, TweenInfo.new(0.15), { Transparency = 0.5 })
        end

        function tab:Hide()
            tabPage.Visible = false
            tab.active = false
            tween(btn, TweenInfo.new(0.15), { BackgroundTransparency = 1 })
            tween(btnLbl, TweenInfo.new(0.15), { TextTransparency = 0.5 })
            tween(btnStroke, TweenInfo.new(0.15), { Transparency = 1 })
        end

        local click = make("TextButton", {
            Parent = btn,
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
        })

        addConn(click.MouseButton1Click, function()
            win:Select(name)
        end)

        function tab:Section(sinfo)
            sinfo = sinfo or {}
            local sname = sinfo.name or "section"
            local side = sinfo.side == "right" and "right" or "left"

            local sec = { name = sname, side = side, elements = {} }

            local parentScroll = side == "left" and leftScroll or rightScroll
            local parentLayout = side == "left" and leftLayout or rightLayout

            local secFrame = make("Frame", {
                Parent = parentScroll,
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.Y,
            })

            local secLabel = text(secFrame, {
                Parent = secFrame,
                Position = UDim2.fromOffset(6, 0),
                Size = UDim2.new(1, -12, 0, 14),
                TextSize = 11,
                TextColor3 = never.subtext,
                Text = sname:upper(),
                TextTransparency = 0.3,
            })

            local body = make("Frame", {
                Parent = secFrame,
                Position = UDim2.fromOffset(0, 18),
                Size = UDim2.new(1, 0, 0, 0),
                BackgroundColor3 = never.section,
                BackgroundTransparency = 0.35,
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.Y,
            })
            corner(body, 8)
            local bodyStroke = stroke(body, never.outline, 0.5, 1)

            local bodyPad = make("UIPadding", {
                Parent = body,
                PaddingTop = UDim.new(0, 6),
                PaddingBottom = UDim.new(0, 6),
                PaddingLeft = UDim.new(0, 6),
                PaddingRight = UDim.new(0, 6),
            })

            local bodyList = make("UIListLayout", {
                Parent = body,
                SortOrder = Enum.SortOrder.LayoutOrder,
                Padding = UDim.new(0, 4),
            })

            local function sizeToContent()
                local h = bodyList.AbsoluteContentSize.Y + 12
                body.Size = UDim2.new(1, 0, 0, h)
                secFrame.Size = UDim2.new(1, 0, 0, h + 18)
            end

            addConn(bodyList:GetPropertyChangedSignal("AbsoluteContentSize"), sizeToContent)
            task.defer(sizeToContent)

            local function register(el)
                table.insert(sec.elements, el)
            end

            function sec:Toggle(cfg)
                cfg = cfg or {}
                local name = cfg.name or "toggle"
                local default = cfg.default or false
                local cb = cfg.callback or function() end
                local pointer = cfg.pointer or (tab.name .. sname .. name)
                local state = { value = default, callback = cb, name = name }

                never.pointers[pointer] = state

                local row = make("Frame", {
                    Parent = body,
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                })

                local lbl = text(row, {
                    Parent = row,
                    Position = UDim2.fromOffset(8, 0),
                    Size = UDim2.new(1, -60, 1, 0),
                    Text = name,
                })

                local track = make("Frame", {
                    Parent = row,
                    AnchorPoint = v2(1, 0.5),
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.fromOffset(30, 18),
                    BackgroundColor3 = c3(10, 13, 21),
                    BorderSizePixel = 0,
                })
                corner(track, 9)
                local trackStroke = stroke(track, never.outline, 0.5, 1)

                local knob = make("Frame", {
                    Parent = track,
                    AnchorPoint = v2(0.5, 0.5),
                    Position = UDim2.new(0.3, 0, 0.5, 0),
                    Size = UDim2.fromOffset(14, 14),
                    BackgroundColor3 = c3(255, 255, 255),
                    BackgroundTransparency = 0.5,
                    BorderSizePixel = 0,
                })
                corner(knob, 7)

                local function setUI(v, animate)
                    local info = animate and TweenInfo.new(0.15) or TweenInfo.new(0)
                    if v then
                        tween(track, info, { BackgroundColor3 = never.accent, BackgroundTransparency = 0 })
                        tween(knob, info, { Position = UDim2.new(0.7, 0, 0.5, 0), BackgroundTransparency = 0 })
                    else
                        tween(track, info, { BackgroundColor3 = c3(10, 13, 21), BackgroundTransparency = 0 })
                        tween(knob, info, { Position = UDim2.new(0.3, 0, 0.5, 0), BackgroundTransparency = 0.5 })
                    end
                end

                local function setValue(v, fire)
                    state.value = v
                    setUI(v, true)
                    if fire ~= false then
                        state.callback(v)
                    end
                end

                setUI(default, false)

                local btn = make("TextButton", {
                    Parent = row,
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = "",
                })

                addConn(btn.MouseButton1Click, function()
                    setValue(not state.value)
                end)

                addConn(btn.MouseEnter, function()
                    tween(lbl, TweenInfo.new(0.15), { TextTransparency = 0 })
                end)

                addConn(btn.MouseLeave, function()
                    tween(lbl, TweenInfo.new(0.15), { TextTransparency = 0.15 })
                end)

                state.set = setValue
                state.get = function() return state.value end
                state.setValue = setValue

                register(state)
                return state
            end

            function sec:Slider(cfg)
                cfg = cfg or {}
                local name = cfg.name or "slider"
                local min = cfg.min or 0
                local max = cfg.max or 100
                local default = cfg.default or cfg.def or min
                local rounding = cfg.rounding or cfg.dec or 1
                local suffix = cfg.suffix or cfg.suf or ""
                local cb = cfg.callback or function() end
                local pointer = cfg.pointer or (tab.name .. sname .. name)

                local state = { value = default, callback = cb, name = name }
                never.pointers[pointer] = state

                local row = make("Frame", {
                    Parent = body,
                    Size = UDim2.new(1, 0, 0, 34),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                })

                local lbl = text(row, {
                    Parent = row,
                    Position = UDim2.fromOffset(8, 0),
                    Size = UDim2.new(1, -60, 0, 14),
                    Text = name,
                    TextSize = 12,
                })

                local valueLbl = text(row, {
                    Parent = row,
                    AnchorPoint = v2(1, 0),
                    Position = UDim2.new(1, -8, 0, 0),
                    Size = UDim2.fromOffset(60, 14),
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextSize = 12,
                    TextColor3 = never.subtext,
                    Text = tostring(default) .. suffix,
                })

                local track = make("Frame", {
                    Parent = row,
                    Position = UDim2.fromOffset(8, 20),
                    Size = UDim2.new(1, -16, 0, 6),
                    BackgroundColor3 = c3(15, 17, 22),
                    BorderSizePixel = 0,
                })
                corner(track, 3)

                local fill = make("Frame", {
                    Parent = track,
                    Size = UDim2.new(0, 0, 1, 0),
                    BackgroundColor3 = never.accent,
                    BorderSizePixel = 0,
                })
                corner(fill, 3)

                local knob = make("Frame", {
                    Parent = track,
                    AnchorPoint = v2(0.5, 0.5),
                    Position = UDim2.new(0, 0, 0.5, 0),
                    Size = UDim2.fromOffset(12, 12),
                    BackgroundColor3 = c3(255, 255, 255),
                    BorderSizePixel = 0,
                })
                corner(knob, 6)

                local function pct(v)
                    return math.clamp((v - min) / (max - min), 0, 1)
                end

                local function update(v)
                    local p = pct(v)
                    fill.Size = UDim2.new(p, 0, 1, 0)
                    knob.Position = UDim2.new(p, 0, 0.5, 0)
                    valueLbl.Text = tostring(v) .. suffix
                end

                local function setValue(v, fire)
                    v = math.clamp(v, min, max)
                    if rounding > 0 then
                        v = math.floor(v * rounding) / rounding
                    else
                        v = math.floor(v)
                    end
                    state.value = v
                    update(v)
                    if fire ~= false then
                        state.callback(v)
                    end
                end

                setValue(default, false)

                local holding = false

                local function fromMouse()
                    local abs = track.AbsolutePosition
                    local sz = track.AbsoluteSize
                    local mx = uis:GetMouseLocation().X
                    local p = math.clamp((mx - abs.X) / sz.X, 0, 1)
                    setValue(min + (max - min) * p)
                end

                local hit = make("TextButton", {
                    Parent = row,
                    Position = UDim2.fromOffset(0, 14),
                    Size = UDim2.new(1, 0, 0, 20),
                    BackgroundTransparency = 1,
                    Text = "",
                })

                addConn(hit.InputBegan, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        holding = true
                        fromMouse()
                    end
                end)

                addConn(uis.InputChanged, function(input)
                    if not holding then return end
                    if input.UserInputType == Enum.UserInputType.MouseMovement
                        or input.UserInputType == Enum.UserInputType.Touch then
                        fromMouse()
                    end
                end)

                addConn(uis.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        holding = false
                    end
                end)

                state.set = setValue
                state.get = function() return state.value end
                state.setValue = setValue

                register(state)
                return state
            end

            function sec:Button(cfg)
                cfg = cfg or {}
                local name = cfg.name or "button"
                local cb = cfg.callback or function() end
                local state = { name = name, callback = cb }

                local btn = make("Frame", {
                    Parent = body,
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = c3(15, 17, 22),
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                })
                corner(btn, 6)
                local bStroke = stroke(btn, never.outline, 0.5, 1)

                local lbl = text(btn, {
                    Parent = btn,
                    Size = UDim2.fromScale(1, 1),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    Text = name,
                })

                local hit = make("TextButton", {
                    Parent = btn,
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = "",
                })

                addConn(hit.MouseButton1Click, function()
                    state.callback()
                end)

                addConn(hit.MouseEnter, function()
                    tween(btn, TweenInfo.new(0.15), { BackgroundColor3 = never.accent, BackgroundTransparency = 0.65 })
                    tween(bStroke, TweenInfo.new(0.15), { Transparency = 0.2 })
                end)

                addConn(hit.MouseLeave, function()
                    tween(btn, TweenInfo.new(0.15), { BackgroundColor3 = c3(15, 17, 22), BackgroundTransparency = 0 })
                    tween(bStroke, TweenInfo.new(0.15), { Transparency = 0.5 })
                end)

                register(state)
                return state
            end

            function sec:Textbox(cfg)
                cfg = cfg or {}
                local name = cfg.name or "textbox"
                local default = cfg.default or cfg.def or ""
                local cb = cfg.callback or function() end
                local pointer = cfg.pointer or (tab.name .. sname .. name)

                local state = { value = default, callback = cb, name = name }
                never.pointers[pointer] = state

                local box = make("Frame", {
                    Parent = body,
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = c3(15, 17, 22),
                    BorderSizePixel = 0,
                })
                corner(box, 6)
                local bStroke = stroke(box, never.outline, 0.5, 1)

                local input = make("TextBox", {
                    Parent = box,
                    Position = UDim2.fromOffset(10, 0),
                    Size = UDim2.new(1, -20, 1, 0),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Font = Enum.Font.GothamMedium,
                    TextSize = 13,
                    TextColor3 = never.text,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    PlaceholderText = name,
                    PlaceholderColor3 = never.subtext,
                    Text = default,
                    ClearTextOnFocus = false,
                })

                addConn(input.FocusLost, function()
                    state.value = input.Text
                    state.callback(input.Text)
                    tween(bStroke, TweenInfo.new(0.15), { Transparency = 0.5 })
                end)

                addConn(input.Focused, function()
                    tween(bStroke, TweenInfo.new(0.15), { Transparency = 0, Color = never.accent })
                end)

                state.get = function() return state.value end
                state.set = function(v)
                    state.value = v
                    input.Text = v
                    state.callback(v)
                end
                state.setValue = state.set

                register(state)
                return state
            end

            function sec:Dropdown(cfg)
                cfg = cfg or {}
                local name = cfg.name or "dropdown"
                local options = cfg.options or cfg.values or { "one", "two" }
                local default = cfg.default or cfg.def or options[1]
                local multi = cfg.multi or false
                local cb = cfg.callback or function() end
                local pointer = cfg.pointer or (tab.name .. sname .. name)

                local state = { value = default, options = options, multi = multi, callback = cb, name = name, open = false }
                never.pointers[pointer] = state

                local btn = make("Frame", {
                    Parent = body,
                    Size = UDim2.new(1, 0, 0, 28),
                    BackgroundColor3 = c3(15, 17, 22),
                    BorderSizePixel = 0,
                })
                corner(btn, 6)
                local bStroke = stroke(btn, never.outline, 0.5, 1)

                local lbl = text(btn, {
                    Parent = btn,
                    Position = UDim2.fromOffset(10, 0),
                    Size = UDim2.new(1, -40, 1, 0),
                    Text = tostring(default),
                })

                local arrow = text(btn, {
                    Parent = btn,
                    AnchorPoint = v2(1, 0.5),
                    Position = UDim2.new(1, -10, 0.5, 0),
                    Size = UDim2.fromOffset(12, 12),
                    TextXAlignment = Enum.TextXAlignment.Right,
                    TextSize = 10,
                    TextColor3 = never.subtext,
                    Text = "v",
                })

                local list = make("Frame", {
                    Parent = gui,
                    BackgroundColor3 = never.panel,
                    BackgroundTransparency = 0,
                    BorderSizePixel = 0,
                    Visible = false,
                    Size = UDim2.fromOffset(140, 0),
                    AutomaticSize = Enum.AutomaticSize.Y,
                })
                corner(list, 8)
                stroke(list, never.outline, 0.4, 1)

                local listPad = make("UIPadding", {
                    Parent = list,
                    PaddingTop = UDim.new(0, 6),
                    PaddingBottom = UDim.new(0, 6),
                    PaddingLeft = UDim.new(0, 4),
                    PaddingRight = UDim.new(0, 4),
                })

                local listLayout = make("UIListLayout", {
                    Parent = list,
                    SortOrder = Enum.SortOrder.LayoutOrder,
                    Padding = UDim.new(0, 2),
                })

                local itemBtns = {}

                local function label()
                    if not multi then return tostring(state.value) end
                    local t = {}
                    for _, v in pairs(state.value) do table.insert(t, tostring(v)) end
                    return #t > 0 and table.concat(t, ", ") or "none"
                end

                local function isOn(opt)
                    if multi then
                        if typeof(state.value) == "table" then
                            return state.value[opt] or table.find(state.value, opt) ~= nil
                        end
                        return false
                    end
                    return state.value == opt
                end

                local function refresh()
                    lbl.Text = label()
                    for opt, item in pairs(itemBtns) do
                        if isOn(opt) then
                            item.lbl.TextColor3 = never.accent
                        else
                            item.lbl.TextColor3 = never.text
                        end
                    end
                end

                local function buildList()
                    for _, c in ipairs(list:GetChildren()) do
                        if c:IsA("TextButton") then c:Destroy() end
                    end
                    itemBtns = {}

                    for i, opt in ipairs(options) do
                        local item = make("TextButton", {
                            Parent = list,
                            Size = UDim2.new(1, 0, 0, 24),
                            BackgroundTransparency = 1,
                            Text = "",
                            LayoutOrder = i,
                        })

                        local itemLbl = text(item, {
                            Parent = item,
                            Position = UDim2.fromOffset(8, 0),
                            Size = UDim2.new(1, -16, 1, 0),
                            Text = tostring(opt),
                            TextSize = 12,
                        })

                        addConn(item.MouseEnter, function()
                            tween(itemLbl, TweenInfo.new(0.15), { TextTransparency = 0 })
                        end)

                        addConn(item.MouseLeave, function()
                            tween(itemLbl, TweenInfo.new(0.15), { TextTransparency = 0.15 })
                        end)

                        addConn(item.MouseButton1Click, function()
                            if multi then
                                if typeof(state.value) ~= "table" then state.value = {} end
                                if isOn(opt) then
                                    if typeof(state.value) == "table" then
                                        for k, v in pairs(state.value) do
                                            if v == opt then state.value[k] = nil end
                                        end
                                        if state.value[opt] then state.value[opt] = nil end
                                    end
                                else
                                    state.value[opt] = true
                                    table.insert(state.value, opt)
                                end
                            else
                                state.value = opt
                                list.Visible = false
                                state.open = false
                            end
                            refresh()
                            state.callback(state.value)
                        end)

                        itemBtns[opt] = { frame = item, lbl = itemLbl }
                    end
                end

                buildList()
                refresh()

                local function positionList()
                    local abs = btn.AbsolutePosition
                    local sz = btn.AbsoluteSize
                    list.Position = UDim2.fromOffset(abs.X, abs.Y + sz.Y + 4)
                    list.Size = UDim2.fromOffset(sz.X, listLayout.AbsoluteContentSize.Y + 12)
                end

                local hit = make("TextButton", {
                    Parent = btn,
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = "",
                })

                addConn(hit.MouseButton1Click, function()
                    state.open = not state.open
                    if state.open then
                        positionList()
                        list.Visible = true
                    else
                        list.Visible = false
                    end
                end)

                addConn(uis.InputBegan, function(input)
                    if not state.open then return end
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        or input.UserInputType == Enum.UserInputType.Touch then
                        if not isOver(list) and not isOver(btn) then
                            state.open = false
                            list.Visible = false
                        end
                    end
                end)

                state.get = function() return state.value end
                state.set = function(v)
                    state.value = v
                    refresh()
                    state.callback(v)
                end
                state.setValue = state.set
                state.setValues = function(v)
                    options = v
                    buildList()
                    refresh()
                end

                register(state)
                return state
            end

            function sec:Keybind(cfg)
                cfg = cfg or {}
                local name = cfg.name or "keybind"
                local default = cfg.default or cfg.def or "None"
                local cb = cfg.callback or function() end
                local pointer = cfg.pointer or (tab.name .. sname .. name)

                local state = { value = default, callback = cb, name = name, binding = false }
                never.pointers[pointer] = state

                local row = make("Frame", {
                    Parent = body,
                    Size = UDim2.new(1, 0, 0, 26),
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                })

                local lbl = text(row, {
                    Parent = row,
                    Position = UDim2.fromOffset(8, 0),
                    Size = UDim2.new(1, -70, 1, 0),
                    Text = name,
                })

                local keyBox = make("Frame", {
                    Parent = row,
                    AnchorPoint = v2(1, 0.5),
                    Position = UDim2.new(1, -8, 0.5, 0),
                    Size = UDim2.fromOffset(55, 20),
                    BackgroundColor3 = c3(15, 17, 22),
                    BorderSizePixel = 0,
                })
                corner(keyBox, 5)
                local kStroke = stroke(keyBox, never.outline, 0.5, 1)

                local keyLbl = text(keyBox, {
                    Parent = keyBox,
                    Size = UDim2.fromScale(1, 1),
                    TextXAlignment = Enum.TextXAlignment.Center,
                    TextSize = 12,
                    Text = tostring(default),
                })

                local hit = make("TextButton", {
                    Parent = keyBox,
                    Size = UDim2.fromScale(1, 1),
                    BackgroundTransparency = 1,
                    Text = "",
                })

                addConn(hit.MouseButton1Click, function()
                    state.binding = true
                    keyLbl.Text = "..."
                    tween(kStroke, TweenInfo.new(0.15), { Color = never.accent, Transparency = 0 })
                end)

                addConn(uis.InputBegan, function(input)
                    if not state.binding then return end
                    local keyName
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        keyName = input.KeyCode.Name
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        keyName = "MB1"
                    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
                        keyName = "MB2"
                    elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
                        keyName = "MB3"
                    end
                    if keyName then
                        state.binding = false
                        state.value = keyName
                        keyLbl.Text = keyName
                        tween(kStroke, TweenInfo.new(0.15), { Color = never.outline, Transparency = 0.5 })
                        state.callback(keyName)
                    end
                end)

                state.get = function() return state.value end
                state.set = function(v)
                    state.value = v
                    keyLbl.Text = v
                    state.callback(v)
                end
                state.setValue = state.set

                register(state)
                return state
            end

            function sec:Label(cfg)
                cfg = cfg or {}
                local content = cfg.text or cfg.name or ""
                local wrap = cfg.wrap or false

                local lbl = text(body, {
                    Parent = body,
                    Size = UDim2.new(1, 0, 0, wrap and 0 or 20),
                    Text = content,
                    TextSize = 12,
                    TextWrapped = wrap,
                    AutomaticSize = wrap and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
                    TextXAlignment = Enum.TextXAlignment.Left,
                })

                local pad = make("UIPadding", {
                    Parent = lbl,
                    PaddingLeft = UDim.new(0, 6),
                    PaddingRight = UDim.new(0, 6),
                    PaddingTop = UDim.new(0, 2),
                    PaddingBottom = UDim.new(0, 2),
                })

                register({ name = "label", text = content, frame = lbl })
                return lbl
            end

            return sec
        end

        table.insert(win.tabs, tab)

        if not win.current then
            win:Select(name)
        end

        return tab
    end

    function win:Select(name)
        for _, t in ipairs(self.tabs) do
            if t.name == name then
                t:Show()
                self.current = t
            else
                t:Hide()
            end
        end
    end

    function win:Toggle()
        setVisible(not self.open)
    end

    function win:SetOpen(v)
        setVisible(v and true or false)
    end

    function win:SetAccent(col)
        never.accent = col
    end

    function win:Unload()
        for _, c in ipairs(never.connections) do
            pcall(function() c:Disconnect() end)
        end
        gui:Destroy()
    end

    win.root = root
    win.gui = gui

    return win
end

return never
