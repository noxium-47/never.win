local uis = game:GetService("UserInputService")
local rs  = game:GetService("RunService")

local v2  = Vector2.new
local v2z = Vector2.zero
local c3  = Color3.fromRGB
local c3h = Color3.fromHSV

local never = {
    drawings      = {{}, {}},
    images        = {},
    connections   = {},
    flags         = {},
    pointers      = {},
    groups        = {},
    loaded        = false,
    version       = "0.1.0",
}

-- ============================================================
-- UTILITY
-- ============================================================
local util = {}

do
    local function lerp(a, b, t)
        if typeof(a) == "number" then return a + (b - a) * t end
        return a:Lerp(b, t)
    end

    function util:Draw(class, offset, props, transient)
        transient = transient or false

        local draw = Drawing.new(class)
        local obj  = {}
        rawset(obj, "__exists", true)
        rawset(obj, "__offset", offset or v2z)
        rawset(obj, "__props",  props or {})
        rawset(obj, "children", {})

        local offsetLocked = true
        local lerpConn

        local function syncChildren()
            for _, child in ipairs(rawget(obj, "children")) do
                child.Position = obj.Position + child:GetOffset()
            end
        end

        local custom = {
            Parent = function(parent)
                table.insert(rawget(parent, "children"), obj)
            end,
            Group = function(name)
                never.groups[name] = never.groups[name] or {}
                table.insert(never.groups[name], obj)
            end,
        }

        setmetatable(obj, {
            __index = function(_, key)
                if rawget(obj, "__exists") then
                    return draw[key]
                end
            end,
            __newindex = function(_, key, value)
                if not rawget(obj, "__exists") then return end
                if custom[key] then
                    custom[key](value)
                    return
                end
                draw[key] = value
                if key == "Position" and offsetLocked then
                    syncChildren()
                end
            end,
        })

        rawset(obj, "Remove", function()
            if rawget(obj, "__exists") then
                draw:Remove()
                rawset(obj, "__exists", false)
            end
        end)
        rawset(obj, "GetType",   function() return class end)
        rawset(obj, "GetOffset", function() return rawget(obj, "__offset") end)
        rawset(obj, "SetOffset", function(noff)
            rawset(obj, "__offset", noff or v2z)
            if rawget(obj, "__props").Parent then
                obj.Position = rawget(obj, "__props").Parent.Position + obj:GetOffset()
            end
        end)
        rawset(obj, "DefaultTransparency", function()
            return rawget(obj, "__props").Transparency or 1
        end)
        rawset(obj, "Lerp", function(target, duration, cancelPrev)
            if not rawget(obj, "__exists") then return end

            local from = {}
            for k in pairs(target) do from[k] = obj[k] end

            if cancelPrev and lerpConn then
                lerpConn:Disconnect()
                lerpConn = nil
            end

            local elapsed = 0
            local conn
            conn = rs.Heartbeat:Connect(function(dt)
                if elapsed >= duration then
                    for k, v in pairs(target) do obj[k] = v end
                    conn:Disconnect()
                    if lerpConn == conn then lerpConn = nil end
                    return
                end
                local t = elapsed / duration
                for k, v in pairs(target) do obj[k] = lerp(from[k], v, t) end
                elapsed = math.clamp(elapsed + dt, 0, duration)
            end)
            lerpConn = conn
        end)

        if class == "Square" then
            obj.Filled = true
            obj.Thickness = 1
        elseif class == "Circle" or class == "Line" then
            obj.Thickness = 1
        end

        if class ~= "Image" and class ~= "Triangle" then
            obj.Color = c3(0, 0, 0)
        end

        obj.Visible = never.loaded

        for k, v in pairs(rawget(obj, "__props")) do
            if not custom[k] then obj[k] = v end
        end

        if rawget(obj, "__props").Parent then
            obj.Position = rawget(obj, "__props").Parent.Position + obj:GetOffset()
        end

        if not never.loaded and not transient then
            obj.Transparency = 0
        end

        table.insert(transient and never.drawings[2] or never.drawings[1],
            {obj, rawget(obj, "__props").Transparency or 1, class})

        return obj
    end

    function util:Screen() return workspace.CurrentCamera.ViewportSize end
    function util:Round(v) return v2(math.floor(v.X), math.floor(v.Y)) end

    function util:Over(draw)
        local p1, p2 = draw.Position, draw.Position + draw.Size
        local m = uis:GetMouseLocation()
        return m.X >= p1.X and m.Y >= p1.Y and m.X <= p2.X and m.Y <= p2.Y
    end

    function util:OverRect(p1, p2)
        local m = uis:GetMouseLocation()
        return m.X >= p1.X and m.Y >= p1.Y and m.X <= p2.X and m.Y <= p2.Y
    end

    function util:Image(obj, url)
        local data = never.images[url]
        if not data then
            data = game:HttpGet(url)
            never.images[url] = data
        end
        obj.Data = data
    end

    function util:Connect(signal, fn)
        local conn = signal:Connect(fn)
        table.insert(never.connections, conn)
        return conn
    end

    function util:Merge(a, b)
        local out = {}
        for _, v in ipairs(a) do table.insert(out, v) end
        for _, v in ipairs(b) do table.insert(out, v) end
        return out
    end

    function util:TextWidth(text)
        local t = Drawing.new("Text")
        t.Size = 13
        t.Font = Drawing.Fonts.Plex
        t.Text = text
        local w = t.TextBounds.X
        t:Remove()
        return w
    end

    util.shiftMap = {
        ["1"]="!", ["2"]="@", ["3"]="#", ["4"]="$", ["5"]="%",
        ["6"]="^", ["7"]="&", ["8"]="*", ["9"]="(", ["0"]=")",
        ["-"]="_", ["="]="+", [";"]=":", ["'"]="\"", ["\\"]="|",
        ["/"]="?", [","]="<", ["."]=">",
    }

    util.keyShort = {
        MouseButton1="MB1", MouseButton2="MB2", MouseButton3="MB3",
        Insert="INS", LeftAlt="LALT", LeftControl="LC",
        LeftShift="LS", RightAlt="RALT", RightControl="RC",
        RightShift="RS", CapsLock="CAPS", Return="RET", Backspace="BSP",
    }
end

-- ============================================================
-- THEME
-- ============================================================
local function makeTheme()
    return {
        accent   = c3(90, 120, 255),
        bg       = c3(18, 18, 22),
        panel    = c3(28, 28, 34),
        section  = c3(36, 36, 44),
        outline  = c3(8, 8, 10),
        outline2 = c3(52, 52, 62),
        text     = c3(240, 240, 245),
        subtext  = c3(150, 150, 165),
        danger   = c3(220, 60, 60),
    }
end

-- ============================================================
-- WINDOW
-- ============================================================
function never:New(info, theme)
    info  = info or {}
    theme = theme or makeTheme()

    local title = info.name or "never.win"
    local size  = typeof(info.size) == "Vector2" and info.size or v2(520, 480)

    local win = {
        theme       = theme,
        tabs        = {},
        current     = nil,
        floating    = {},  -- rna sections
        state       = {},  -- dropdown/keybind/colorpicker/textbox
        dragging    = false,
        dragStart   = v2z,
        fading      = false,
        connections = {},
    }

    local frame = util:Draw("Square", nil, {
        Size = size,
        Color = theme.panel,
        Group = "panel",
        Position = util:Round(util:Screen() / 2 - size / 2),
    })
    win.frame = frame

    local outline = util:Draw("Square", v2(-1, -1), {
        Size = size + v2(2, 2),
        Color = theme.outline,
        Group = "outline",
        Filled = false,
        Thickness = 2,
        Parent = frame,
    })

    local accentLine = util:Draw("Square", v2(0, 0), {
        Size = v2(size.X, 2),
        Color = theme.accent,
        Group = "accent",
        Parent = frame,
    })

    local titleText = util:Draw("Text", v2(8, 3), {
        Font = Drawing.Fonts.Plex,
        Size = 13,
        Outline = true,
        Color = theme.text,
        Text = title,
        Parent = frame,
    })

    local versionText = util:Draw("Text", v2(size.X - 8, 3), {
        Font = Drawing.Fonts.Plex,
        Size = 13,
        Outline = true,
        Color = theme.subtext,
        Text = "v" .. never.version,
        Center = true,
        Parent = frame,
    })

    -- Drag window
    util:Connect(uis.InputBegan, function(input)
        if not frame.Visible then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        if util:OverRect(frame.Position, frame.Position + v2(frame.Size.X, 20)) then
            win.dragStart = uis:GetMouseLocation() - frame.Position
            win.dragging = true
        end
    end)
    util:Connect(uis.InputEnded, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            win.dragging = false
        end
    end)
    util:Connect(uis.InputChanged, function(input)
        if win.dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            frame.Position = uis:GetMouseLocation() - win.dragStart
        end
    end)

    -- Outer body
    local body = util:Draw("Square", v2(6, 22), {
        Size = size - v2(12, 28),
        Color = theme.bg,
        Group = "panel",
        Parent = frame,
    })

    local bodyOutline = util:Draw("Square", v2(-1, -1), {
        Size = body.Size + v2(2, 2),
        Color = theme.outline,
        Group = "outline",
        Filled = false,
        Parent = body,
    })

    local tabBar = util:Draw("Square", v2(6, 0), {
        Size = v2(size.X - 12, 20),
        Color = theme.panel,
        Group = "panel",
        Parent = body,
    })

    local tabAccent = util:Draw("Square", v2z, {
        Size = v2(0, 1),
        Color = theme.accent,
        Group = "accent",
    })

    util:Connect(rs.RenderStepped, function()
        if not frame.Visible or not win.current then return end
        local tab = win.current.tabFrame
        tabAccent.Size = v2(tab.Size.X, 1)
        tabAccent.Position = tab.Position + v2(0, tab.Size.Y)
    end)

    local content = util:Draw("Square", v2(0, 20), {
        Size = body.Size - v2(0, 20),
        Color = theme.bg,
        Group = "panel",
        Parent = body,
    })

    -- ============================================================
    -- TAB
    -- ============================================================
    function win:Tab(info)
        info = info or {}
        local name = info.name or "tab"

        local tab = {
            name = name,
            instances = {},
            sections = {},
            sides = {{}, {}},
            active = false,
        }

        local offset = v2(0, 0)
        if #self.tabs > 0 then
            local prev = self.tabs[#self.tabs].tabFrame
            offset = prev:GetOffset() + v2(prev.Size.X + 2, 0)
        end

        local tabFrame = util:Draw("Square", offset, {
            Size = v2(util:TextWidth(name) + 14, 20),
            Color = theme.panel,
            Parent = tabBar,
        })

        local tabOutline = util:Draw("Square", v2(-1, -1), {
            Size = tabFrame.Size + v2(2, 2),
            Color = theme.outline2,
            Group = "outline",
            Filled = false,
            Parent = tabFrame,
        })

        local tabText = util:Draw("Text", v2(tabFrame.Size.X / 2, 3), {
            Font = Drawing.Fonts.Plex,
            Size = 13,
            Color = theme.text,
            Outline = true,
            Center = true,
            Text = name,
            Parent = tabFrame,
        })

        local tabHider = util:Draw("Square", v2(0, tabFrame.Size.Y), {
            Size = v2(tabFrame.Size.X, 1),
            Color = theme.panel,
            Group = "panel",
            Parent = tabFrame,
        })

        tab.tabFrame  = tabFrame
        tab.instances = {tabFrame, tabOutline, tabText, tabHider}

        table.insert(self.tabs, tab)

        function tab:Show()
            tabFrame.Color = theme.panel
            tabHider.Visible = true
            for _, s in ipairs(self.sections) do s:Show() end
            self.active = true
            self:Refresh()
        end

        function tab:Hide()
            tabFrame.Color = theme.bg
            tabHider.Visible = false
            for _, s in ipairs(self.sections) do s:Hide() end
            self.active = false
            self:Refresh()
        end

        function tab:Refresh()
            tabFrame.Color = self.active and theme.panel or theme.bg

            for sn, side in pairs(self.sides) do
                for i, s in ipairs(side) do
                    s:Update()

                    local y = 12
                    if i > 1 then
                        local prev = side[i-1].frame
                        y = y + prev:GetOffset().Y + prev.Size.Y
                    end

                    s.frame:SetOffset(v2(sn == 1 and 8 or content.Size.X / 2 + 4, y))
                end
            end

            for _, s in ipairs(self.sections) do s:Update() end
            tabFrame.Color = self.active and theme.panel or theme.bg
        end

        -- ============================================================
        -- SECTION
        -- ============================================================
        function tab:Section(info)
            info = info or {}
            local name      = info.name or "section"
            local side      = (info.side or "left"):lower()
            local floating  = info.rna or info.floating or false
            local autofill  = info.autofill or false

            if side ~= "left" and side ~= "right" then side = "left" end

            local sec = {
                name = name,
                side = side,
                floating = floating,
                autofill = autofill,
                scale = 0,
                instances = {},
                things = {
                    buttons = {}, toggles = {}, textboxes = {},
                    dropdowns = {}, sliders = {}, colorpickers = {},
                    keybinds = {}, lists = {},
                },
                frame = nil,
            }

            if floating then
                sec.frame = util:Draw("Square", v2(16, 16), {
                    Size = v2(228, 12),
                    Color = theme.section,
                    Group = "section",
                })
                table.insert(self.floating, sec)
            else
                sec.frame = util:Draw("Square", v2(side == "left" and 8 or content.Size.X/2 + 4, 16), {
                    Size = v2(content.Size.X / 2 - 12, 12),
                    Color = theme.section,
                    Group = "section",
                    Parent = content,
                })
            end

            local frameInline = util:Draw("Square", v2(-1, -1), {
                Size = sec.frame.Size + v2(2, 2),
                Color = theme.outline,
                Group = "outline",
                Filled = false,
                Parent = sec.frame,
            })

            local frameOuter = util:Draw("Square", v2(-2, -2), {
                Size = frameInline.Size + v2(2, 2),
                Color = theme.panel,
                Group = "panel",
                Filled = false,
                Parent = sec.frame,
            })

            local accentBar = util:Draw("Square", v2(0, 0), {
                Size = v2(8, 2),
                Color = theme.accent,
                Group = "accent",
                Parent = sec.frame,
            })

            local titleText = util:Draw("Text", v2(9, -7), {
                Font = Drawing.Fonts.Plex,
                Size = 13,
                Color = theme.text,
                Text = name,
                Parent = sec.frame,
            })

            local titleBold = util:Draw("Text", v2(1, 0), {
                Font = Drawing.Fonts.Plex,
                Size = 13,
                Color = theme.text,
                Text = name,
                Parent = titleText,
            })

            local accentBar2 = util:Draw("Square", v2(11 + #name * 7, 0), {
                Size = v2(sec.frame.Size.X - (11 + #name * 7), 2),
                Color = theme.accent,
                Group = "accent",
                Parent = sec.frame,
            })

            function sec:Show()
                for _, v in ipairs(self.instances) do
                    v.Visible = true
                    if v.Transparency ~= v:DefaultTransparency() and not win.fading then
                        v.Transparency = v:DefaultTransparency()
                    end
                end
            end

            function sec:Hide()
                for _, v in ipairs(self.instances) do v.Visible = false end
            end

            function sec:NextY()
                return self.scale > 0 and self.scale or 10
            end

            function sec:Grow(h)
                if self.scale == 0 then self.scale = 10 end
                self.scale = self.scale + h + 5
            end

            function sec:Update()
                local siblings = tab.sides[self.side == "left" and 1 or 2]
                local isLast = table.find(siblings, self) == #siblings

                local h = isLast and self.autofill and (content.Size.Y - (self.frame:GetOffset().Y + 5))
                    or (self.scale > 0 and self.scale or 10)

                sec.frame.Size = v2(self.floating and 228 or content.Size.X / 2 - 12, h)
                frameInline.Size = sec.frame.Size + v2(2, 2)
                frameOuter.Size = frameInline.Size + v2(2, 2)
                accentBar2.Size = v2(sec.frame.Size.X - (11 + #name * 7), 2)

                for _, l in ipairs(self.things.lists) do l:Update() end
                for _, group in ipairs({"buttons","dropdowns","sliders","textboxes","keybinds","colorpickers","toggles"}) do
                    for _, v in ipairs(self.things[group]) do v:Update() end
                end
            end

            function sec:SetFloatingPos(pos)
                if self.floating then self.frame.Position = pos end
            end

            if floating then
                sec:SetFloatingPos(v2(-2000, -2000))
            end

            sec.instances = {sec.frame, frameInline, frameOuter, titleText, titleBold, accentBar, accentBar2}

            if not floating then
                table.insert(self.sections, sec)
                table.insert(self.sides[side == "left" and 1 or 2], sec)
            end

            -- ============================================================
            -- ELEMENTS
            -- ============================================================
            function sec:Button(info)
                info = info or {}
                local name = info.name or "Button"
                local callback = info.callback or function() end

                local btn = {name = name, callback = callback}

                local frame = util:Draw("Square", v2(6, self:NextY()), {
                    Size = v2(sec.frame.Size.X - 12, 18),
                    Color = theme.panel,
                    Group = "panel",
                    Parent = sec.frame,
                })

                local outline = util:Draw("Square", v2(-1, -1), {
                    Size = frame.Size + v2(2, 2),
                    Color = theme.outline,
                    Group = "outline",
                    Filled = false,
                    Parent = frame,
                })

                local label = util:Draw("Text", v2(frame.Size.X / 2, 2), {
                    Font = Drawing.Fonts.Plex,
                    Size = 13,
                    Color = theme.text,
                    Outline = true,
                    Center = true,
                    Text = name,
                    Parent = frame,
                })

                function btn:Update()
                    frame.Size = v2(sec.frame.Size.X - 12, 18)
                    outline.Size = frame.Size + v2(2, 2)
                    label:SetOffset(v2(frame.Size.X / 2, 2))
                end

                util:Connect(uis.InputBegan, function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    if not win.frame.Visible or not tab.active then return end
                    if win:Blocked(sec) then return end
                    if util:OverRect(sec.frame.Position + v2(0, frame:GetOffset().Y),
                                     sec.frame.Position + v2(sec.frame.Size.X, frame:GetOffset().Y + 18)) then
                        btn.callback()
                    end
                end)

                sec.instances = util:Merge(sec.instances, {frame, outline, label})
                sec:Grow(18)
                table.insert(sec.things.buttons, btn)
                return btn
            end

            function sec:Toggle(info)
                info = info or {}
                local name    = info.name or "toggle"
                local default = info.default or false
                local cb      = info.callback or function() end
                local tip     = info.tooltip or info.tt or ""
                local flag    = info.flag
                local pointer = info.pointer or (tab.name .. sec.name .. name)

                local toggle = {
                    name = name, flag = flag, state = default,
                    callback = cb, tooltip = tip, pointer = pointer,
                }
                never.pointers[pointer] = toggle

                local frame = util:Draw("Square", v2(6, self:NextY() + 3), {
                    Size = v2(8, 8),
                    Parent = sec.frame,
                })

                local outline = util:Draw("Square", v2(-1, -1), {
                    Size = frame.Size + v2(2, 2),
                    Color = theme.outline,
                    Group = "outline",
                    Filled = false,
                    Parent = frame,
                })

                local label = util:Draw("Text", v2(13, -3), {
                    Font = Drawing.Fonts.Plex,
                    Size = 13,
                    Color = theme.text,
                    Outline = true,
                    Text = name,
                    Parent = frame,
                })

                function toggle:Get() return self.state end

                function toggle:Update()
                    frame.Color = self.state and theme.accent or theme.panel
                    if self.flag then never.flags[self.flag] = self.state end
                end

                function toggle:Set(state)
                    self.state = state
                    self:Update()
                    self.callback(self.state)
                end

                function toggle:Keybind(info2)
                    info2 = info2 or {}
                    info2.name = self.name
                    self.keybind = sec:_Keybind(info2, {v2(sec.frame.Size.X - 54, -1), v2z}, frame, false)
                    return self.keybind
                end

                toggle:Set(default)

                util:Connect(uis.InputBegan, function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    if not win.frame.Visible or not tab.active then return end
                    if win:Blocked(sec) then return end
                    if util:OverRect(sec.frame.Position + v2(0, frame:GetOffset().Y),
                                     sec.frame.Position + v2(sec.frame.Size.X, frame:GetOffset().Y + 17)) then
                        toggle:Set(not toggle.state)
                    end
                end)

                sec.instances = util:Merge(sec.instances, {frame, outline, label})
                sec:Grow(13)
                table.insert(sec.things.toggles, toggle)
                return toggle
            end

            function sec:Slider(info)
                info = info or {}
                local name = info.name or "slider"
                local min  = info.min or 0
                local max  = info.max or 100
                local def  = info.def or min
                local dec  = info.dec or 1
                local suf  = info.suf or ""
                local flag = info.flag
                local cb   = info.callback or function() end
                local pointer = info.pointer or (tab.name .. sec.name .. name)

                local slider = {
                    name = name, flag = flag, pointer = pointer,
                    value = def, min = min, max = max, suf = suf, dec = dec,
                    holding = false, callback = cb,
                }
                never.pointers[pointer] = slider

                local label = util:Draw("Text", v2(6, self:NextY() + 3), {
                    Font = Drawing.Fonts.Plex, Size = 13, Outline = true,
                    Color = theme.text, Text = name, Parent = sec.frame,
                })

                local pm = util:Draw("Text", v2(sec.frame.Size.X - 33, 0), {
                    Font = Drawing.Fonts.Plex, Size = 13, Outline = true,
                    Color = theme.text, Text = "- +", Parent = label,
                })

                local frame = util:Draw("Square", v2(0, 16), {
                    Size = v2(sec.frame.Size.X - 12, 10),
                    Color = theme.panel,
                    Group = "panel",
                    Parent = label,
                })

                local outline = util:Draw("Square", v2(-1, -1), {
                    Size = frame.Size + v2(2, 2),
                    Color = theme.outline,
                    Group = "outline",
                    Filled = false,
                    Parent = frame,
                })

                local bar = util:Draw("Square", v2(0, 0), {
                    Size = v2(0, frame.Size.Y),
                    Color = theme.accent,
                    Group = "accent",
                    Parent = frame,
                })

                local value = util:Draw("Text", v2(frame.Size.X / 2, -2), {
                    Font = Drawing.Fonts.Plex, Size = 13, Outline = true,
                    Color = theme.text, Center = true,
                    Text = tostring(def), Parent = frame,
                })

                function slider:Get() return self.value end

                function slider:Update()
                    frame.Size = v2(sec.frame.Size.X - 12, 10)
                    outline.Size = frame.Size + v2(2, 2)
                    value:SetOffset(v2(frame.Size.X / 2, -2))
                    pm:SetOffset(v2(sec.frame.Size.X - 33, 0))
                    value.Text = tostring(self.value) .. self.suf
                    local pct = 1 - (self.max - self.value) / (self.max - self.min)
                    bar.Size = v2(math.clamp(pct, 0, 1) * frame.Size.X, frame.Size.Y)
                    if self.flag then never.flags[self.flag] = self.value end
                end

                function slider:Set(v)
                    self.value = v
                    self:Update()
                    self.callback(self.value)
                end

                slider:Set(def)

                util:Connect(uis.InputBegan, function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    if not win.frame.Visible or not tab.active then return end
                    if win:Blocked(sec) then return end
                    local tl = sec.frame.Position + v2(0, label:GetOffset().Y)
                    if not util:OverRect(tl, tl + v2(sec.frame.Size.X, 29)) then return end

                    local plusMinus = sec.frame.Position + v2(sec.frame.Size.X - 33, label:GetOffset().Y)
                    if util:OverRect(plusMinus, plusMinus + v2(33, 14)) then
                        local mx = uis:GetMouseLocation().X
                        if mx < plusMinus.X + 16 then
                            slider:Set(math.clamp(slider.value - 1 / slider.dec, slider.min, slider.max))
                        else
                            slider:Set(math.clamp(slider.value + 1 / slider.dec, slider.min, slider.max))
                        end
                        return
                    end

                    slider.holding = true
                    local pct = math.clamp((uis:GetMouseLocation().X - bar.Position.X) / frame.Size.X, 0, 1)
                    local v = math.floor((slider.min + (slider.max - slider.min) * pct) * slider.dec) / slider.dec
                    slider:Set(math.clamp(v, slider.min, slider.max))
                end)

                util:Connect(uis.InputChanged, function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseMovement or not slider.holding then return end
                    local pct = math.clamp((uis:GetMouseLocation().X - bar.Position.X) / frame.Size.X, 0, 1)
                    local v = math.floor((slider.min + (slider.max - slider.min) * pct) * slider.dec) / slider.dec
                    slider:Set(math.clamp(v, slider.min, slider.max))
                end)

                util:Connect(uis.InputEnded, function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        slider.holding = false
                    end
                end)

                slider.instances = {label, frame, outline, bar, value, pm}
                sec.instances = util:Merge(sec.instances, slider.instances)
                sec:Grow(28)
                table.insert(sec.things.sliders, slider)
                return slider
            end

            function sec:Textbox(info)
                info = info or {}
                local name = info.name or "textbox"
                local def  = info.def or info.default or ""
                local cb   = info.callback or function() end
                local pointer = info.pointer or (tab.name .. sec.name .. name)

                local tb = {name = name, value = def, callback = cb, pointer = pointer, typing = false}
                never.pointers[pointer] = tb

                local frame = util:Draw("Square", v2(6, self:NextY()), {
                    Size = v2(sec.frame.Size.X - 12, 18),
                    Color = theme.panel,
                    Group = "panel",
                    Parent = sec.frame,
                })

                local outline = util:Draw("Square", v2(-1, -1), {
                    Size = frame.Size + v2(2, 2),
                    Color = theme.outline,
                    Group = "outline",
                    Filled = false,
                    Parent = frame,
                })

                local label = util:Draw("Text", v2(4, 2), {
                    Font = Drawing.Fonts.Plex, Size = 13, Outline = true,
                    Color = theme.text, Text = name, Parent = frame,
                })

                function tb:Get() return self.value end

                function tb:Update()
                    frame.Size = v2(sec.frame.Size.X - 12, 18)
                    outline.Size = frame.Size + v2(2, 2)
                    local max = math.floor(frame.Size.X / 7) - 3
                    local shown = self.value == "" and self.name or self.value
                    local sub = shown:sub(1, max)
                    label.Text = sub .. (#shown > max and "..." or "")
                    label.Color = self.value == "" and theme.subtext or theme.text
                end

                function tb:Set(v)
                    self.value = v
                    self:Update()
                    self.callback(v)
                end

                function tb:Start() self.typing = true; win.state.textbox = self end
                function tb:Stop()  self.typing = false; win.state.textbox = nil end

                tb:Set(def)

                util:Connect(uis.InputBegan, function(input)
                    if not win.frame.Visible or not tab.active then return end
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        if not win:Blocked(sec) and util:OverRect(
                            sec.frame.Position + v2(0, frame:GetOffset().Y),
                            sec.frame.Position + v2(sec.frame.Size.X, frame:GetOffset().Y + 18)) then
                            tb:Start()
                        else
                            tb:Stop()
                        end
                    elseif input.UserInputType == Enum.UserInputType.Keyboard and tb.typing then
                        local code = input.KeyCode
                        local k = uis:GetStringForKeyCode(code):lower()
                        if uis:IsKeyDown("LeftShift") or uis:IsKeyDown("RightShift") then
                            k = (k:len() == 1 and string.upper(k)) or util.shiftMap[k] or k
                        end
                        if code.Name == "Backspace" then
                            tb:Set(tb.value:sub(1, -2))
                        elseif k ~= "" and k:len() == 1 then
                            tb:Set(tb.value .. k)
                        end
                    end
                end)

                sec.instances = util:Merge(sec.instances, {frame, outline, label})
                sec:Grow(18)
                table.insert(sec.things.textboxes, tb)
                return tb
            end

            function sec:Keybind(info)
                return sec:_Keybind(info, {v2(sec.frame.Size.X - 54, self:NextY() + 2), v2(6, self:NextY())}, sec.frame, true)
            end

            function sec:_Keybind(info, offsets, parent, grow)
                info = info or {}
                local name = info.name or "key"
                local def  = info.def or "unset"
                local flag = info.flag
                local pointer = info.pointer or (tab.name .. sec.name .. name .. "Key")

                local kb = {
                    value = def, mode = "toggle", flag = flag,
                    pointer = pointer, name = name, binding = false,
                    instances = {}, menu = {},
                }
                never.pointers[pointer] = kb

                local frame = util:Draw("Square", offsets[1], {
                    Size = v2(48, 14),
                    Color = theme.panel,
                    Group = "panel",
                    Parent = parent,
                })

                local outline = util:Draw("Square", v2(-1, -1), {
                    Size = frame.Size + v2(2, 2),
                    Color = theme.outline,
                    Group = "outline",
                    Filled = false,
                    Parent = frame,
                })

                local label = util:Draw("Text", offsets[2], {
                    Font = Drawing.Fonts.Plex, Size = 13, Outline = true,
                    Color = theme.text, Text = grow and name or "", Parent = parent,
                })

                local shown = util:Draw("Text", v2(frame.Size.X / 2, -1), {
                    Font = Drawing.Fonts.Plex, Size = 13, Outline = true,
                    Color = theme.text, Center = true, Text = def, Parent = frame,
                })

                function kb:Get() return {self.value, self.mode} end

                function kb:Update()
                    shown.Text = util.keyShort[self.value] or tostring(self.value):upper()
                    if parent == sec.frame then
                        self:SetOffset(v2(sec.frame.Size.X - 54, offsets[1].Y))
                    end
                end

                function kb:Set(v)
                    self.value = v[1]
                    self.mode  = v[2]
                    self:Update()
                end

                function kb:Close()
                    for _, v in ipairs(self.menu) do v:Remove() end
                    self.menu = {}
                    win.state.keybind = nil
                end

                function kb:Open()
                    win:CloseFloating()
                    local mf = util:Draw("Square", v2(0, 15), {
                        Size = v2(60, 32),
                        Color = theme.bg,
                        Group = "bg",
                        ZIndex = 10000,
                        Parent = frame,
                    })

                    local mo = util:Draw("Square", v2(-1, -1), {
                        Size = mf.Size + v2(2, 2),
                        Color = theme.outline,
                        Group = "outline",
                        Filled = false,
                        ZIndex = 10000,
                        Parent = mf,
                    })

                    local modes = {}
                    for i, m in ipairs({"Toggle", "Hold"}) do
                        modes[i] = util:Draw("Text", v2(4, 3 + 14 * (i - 1)), {
                            Font = Drawing.Fonts.Plex, Size = 13, Outline = true,
                            Color = self.mode == m:lower() and theme.accent or theme.text,
                            Text = m, ZIndex = 10000, Parent = mf,
                        })
                    end

                    self.menu = {mf, mo, modes[1], modes[2]}
                    win.state.keybind = self
                end

                kb:Set({def, "toggle"})

                util:Connect(uis.InputBegan, function(input)
                    if not win.frame.Visible then return end
                    if not (tab.active or table.find(win.floating, sec)) then return end

                    local blocked = win:Blocked(sec)

                    if kb.binding then
                        if input.UserInputType == Enum.UserInputType.Keyboard then
                            kb.binding = false
                            if input.KeyCode ~= Enum.KeyCode.Escape then
                                kb:Set({input.KeyCode.Name, kb.mode})
                            else
                                kb:Set({"unset", kb.mode})
                            end
                        elseif input.UserInputType == Enum.UserInputType.MouseButton1
                            or input.UserInputType == Enum.UserInputType.MouseButton2 then
                            kb.binding = false
                            kb:Set({input.UserInputType.Name, kb.mode})
                        end
                        return
                    end

                    if input.UserInputType == Enum.UserInputType.MouseButton1
                        and not blocked and util:Over(frame) then
                        kb.binding = true
                        shown.Text = "..."
                    elseif input.UserInputType == Enum.UserInputType.MouseButton2
                        and not blocked and util:Over(frame) then
                        kb:Open()
                    elseif #kb.menu > 0 then
                        if util:Over(kb.menu[1]) then
                            local y = uis:GetMouseLocation().Y - kb.menu[1].Position.Y
                            kb.mode = y >= 22 and "hold" or "toggle"
                            kb.menu[3].Color = kb.mode == "toggle" and theme.accent or theme.text
                            kb.menu[4].Color = kb.mode == "hold" and theme.accent or theme.text
                        else
                            kb:Close()
                        end
                    end
                end)

                util:Connect(uis.InputEnded, function(input)
                    if kb.mode ~= "hold" or kb.binding then return end
                    local name = input.UserInputType == Enum.UserInputType.Keyboard
                        and input.KeyCode.Name or input.UserInputType.Name
                    if kb.value == name then
                        win.kbds = win.kbds or {}
                        table.remove(win.kbds, table.find(win.kbds, kb.pointer) or 0)
                    end
                end)

                kb.instances = {frame, outline, label, shown}
                sec.instances = util:Merge(sec.instances, kb.instances)
                if grow then sec:Grow(13) end
                table.insert(sec.things.keybinds, kb)
                return kb
            end

            function sec:Dropdown(info)
                info = info or {}
                local name    = info.name or "dropdown"
                local options = info.options or {"one","two"}
                local multi   = info.multi or false
                local def     = info.def or info.default or (multi and {options[1]} or options[1])
                local flag    = info.flag
                local cb      = info.callback or function() end
                local pointer = info.pointer or (tab.name .. sec.name .. name)

                local dd = {
                    name = name, options = options, multi = multi, value = def,
                    flag = flag, pointer = pointer, callback = cb, instances = {}, open = false,
                }
                never.pointers[pointer] = dd

                local label = util:Draw("Text", v2(6, self:NextY() + 3), {
                    Font = Drawing.Fonts.Plex, Size = 13, Outline = true,
                    Color = theme.text, Text = name, Parent = sec.frame,
                })

                local frame = util:Draw("Square", v2(0, 17), {
                    Size = v2(sec.frame.Size.X - 12, 18),
                    Color = theme.panel,
                    Group = "panel",
                    Parent = label,
                })

                local outline = util:Draw("Square", v2(-1, -1), {
                    Size = frame.Size + v2(2, 2),
                    Color = theme.outline,
                    Group = "outline",
                    Filled = false,
                    Parent = frame,
                })

                local value = util:Draw("Text", v2(4, 2), {
                    Font = Drawing.Fonts.Plex, Size = 13, Outline = true,
                    Color = theme.text, Text = tostring(def), Parent = frame,
                })

                function dd:Get() return self.value end

                function dd:label()
                    if not self.multi then return tostring(self.value) end
                    local t = {}
                    for _, v in ipairs(self.value) do table.insert(t, tostring(v)) end
                    return table.concat(t, ", ")
                end

                function dd:Update()
                    frame.Size = v2(sec.frame.Size.X - 12, 18)
                    outline.Size = frame.Size + v2(2, 2)
                    value.Text = self:label():sub(1, 30)
                    if self.flag then never.flags[self.flag] = self.value end
                end

                function dd:Set(v)
                    self.value = v
                    self:Update()
                    self.callback(self.value)
                end

                function dd:Close()
                    for _, v in ipairs(self.instances) do v:Remove() end
                    self.instances = {}
                    self.open = false
                    win.state.dropdown = nil
                end

                function dd:Open()
                    self:Close()
                    self.open = true

                    local list = util:Draw("Square", v2(0, 19), {
                        Size = v2(frame.Size.X, 2 + 16 * #self.options),
                        Color = theme.bg,
                        Group = "bg",
                        ZIndex = 10000,
                        Parent = frame,
                    })

                    local lo = util:Draw("Square", v2(-1, -1), {
                        Size = list.Size + v2(2, 2),
                        Color = theme.outline,
                        Group = "outline",
                        Filled = false,
                        ZIndex = 10000,
                        Parent = list,
                    })

                    self.instances = {list, lo}

                    for i, opt in ipairs(self.options) do
                        local isOn
                        if self.multi then
                            isOn = table.find(self.value, opt) ~= nil
                        else
                            isOn = self.value == opt
                        end

                        local optText = util:Draw("Text", v2(4, 2 + 16 * (i - 1)), {
                            Font = Drawing.Fonts.Plex, Size = 13, Outline = true,
                            Color = isOn and theme.accent or theme.text,
                            Text = tostring(opt),
                            ZIndex = 10000,
                            Parent = list,
                        })

                        table.insert(self.instances, optText)
                    end

                    win.state.dropdown = self
                end

                dd:Set(def)

                util:Connect(uis.InputBegan, function(input)
                    if input.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
                    if not win.frame.Visible or not tab.active then return end
                    if win:Blocked(sec) then return end

                    if self.open and #dd.instances > 1 then
                        if util:Over(dd.instances[1]) then
                            local y = uis:GetMouseLocation().Y - (dd.instances[1].Position.Y + 2)
                            local idx = math.floor(y / 16) + 1
                            if dd.options[idx] then
                                local opt = dd.options[idx]
                                if dd.multi then
                                    local cur = {}
                                    for _, v in ipairs(dd.value) do cur[v] = true end
                                    cur[opt] = not cur[opt]
                                    local arr = {}
                                    for _, v in ipairs(dd.options) do
                                        if cur[v] then table.insert(arr, v) end
                                    end
                                    dd:Set(arr)
                                else
                                    dd:Set(opt)
                                    dd:Close()
                                end
                            end
                        else
                            dd:Close()
                        end
                        return
                    end

                    if util:OverRect(sec.frame.Position + v2(0, label:GetOffset().Y),
                                     sec.frame.Position + v2(sec.frame.Size.X, label:GetOffset().Y + 35)) then
                        dd:Open()
                    end
                end)

                sec.instances = util:Merge(sec.instances, {label, frame, outline, value})
                sec:Grow(39)
                table.insert(sec.things.dropdowns, dd)
                return dd
            end
        end

        if not self.current then
            self:Select(name)
        end

        util:Connect(uis.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1
                and win.frame.Visible and util:Over(tabFrame) then
                win:Select(name)
            end
        end)

        self.tabs[#self.tabs].tabFrame = tabFrame
        return tab
    end

    function win:Select(name)
        if self.fading then return end
        for _, t in ipairs(self.tabs) do
            if t.name == name then
                t:Show()
                t:Refresh()
                self.current = t
            else
                t:Hide()
            end
        end
    end

    function win:Blocked(sec)
        local overlay = self.state.dropdown or self.state.keybind or self.state.colorpicker

        if overlay and overlay.instances and overlay.instances[1] then
            if util:Over(overlay.instances[1]) then return false end
        end

        for _, f in ipairs(self.floating) do
            if f ~= sec and util:Over(f.frame) then return true end
        end

        return false
    end

    function win:CloseFloating()
        if self.state.dropdown then self.state.dropdown:Close() end
        if self.state.keybind  then self.state.keybind:Close() end
        if self.state.colorpicker then self.state.colorpicker:Close() end
        if self.state.textbox  then self.state.textbox:Stop() end
    end

    function win:Fade()
        if self.fading then return end
        self.fading = true

        local all = util:Merge(self.frame.children, {})
        local stack = {}
        for _, v in ipairs(never.drawings[1]) do table.insert(stack, v[1]) end
        for _, v in ipairs(never.drawings[2]) do table.insert(stack, v[1]) end

        if self.frame.Visible then
            for _, v in ipairs(stack) do
                v.Lerp({Transparency = 0}, 0.2)
            end
            task.delay(0.22, function()
                for _, v in ipairs(stack) do v.Visible = false end
                self.fading = false
                uis.MouseIconEnabled = true
            end)
        else
            for _, v in ipairs(stack) do
                v.Visible = true
                v.Transparency = 0
                v.Lerp({Transparency = v:DefaultTransparency()}, 0.2)
            end
            task.delay(0.22, function() self.fading = false end)
            uis.MouseIconEnabled = false
        end

        self:CloseFloating()
    end

    function win:Init()
        for _, t in ipairs(self.tabs) do
            if not t.active then t:Hide() end
        end

        if self.current then self.current:Show(); self.current:Refresh() end

        for i, v in ipairs(never.drawings[1]) do v[1].ZIndex = i end

        never.loaded = true

        -- reveal
        local stack = {}
        for _, v in ipairs(never.drawings[1]) do table.insert(stack, v[1]) end
        for _, v in ipairs(never.drawings[2]) do table.insert(stack, v[1]) end
        for _, v in ipairs(stack) do
            v.Visible = true
            v.Transparency = 0
            v.Lerp({Transparency = v:DefaultTransparency()}, 0.2)
        end
    end

    function win:Unload()
        for _, v in ipairs(util:Merge(never.drawings[1], never.drawings[2])) do
            v[1]:Remove()
        end
        for _, c in ipairs(never.connections) do c:Disconnect() end
        never.loaded = false
    end

    function win:SetTheme(newTheme)
        self.theme = newTheme or self.theme
        for key, group in pairs(never.groups) do
            for _, obj in ipairs(group) do
                if self.theme[key] then
                    obj.Color = self.theme[key]
                end
            end
        end
        for _, t in ipairs(self.tabs) do t:Refresh() end
    end

    return win
end

return never, util
