local Players      = game:GetService("Players")
local UIS          = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService  = game:GetService("HttpService")
local RunService   = game:GetService("RunService")

local Player = Players.LocalPlayer

local function new(class, props, children)
    local inst = Instance.new(class)
    local parent = props and props.Parent
    for k, v in pairs(props or {}) do
        if k ~= "Parent" then inst[k] = v end
    end
    for _, c in ipairs(children or {}) do c.Parent = inst end
    if parent then inst.Parent = parent end
    return inst
end

local function corner(r) return new("UICorner", {CornerRadius = UDim.new(0, r)}) end
local function stroke(c, t, tr)
    return new("UIStroke", {Color = c or Color3.new(1,1,1), Thickness = t or 1, Transparency = tr or 0})
end
local function pad(n)
    return new("UIPadding", {
        PaddingTop = UDim.new(0, n), PaddingBottom = UDim.new(0, n),
        PaddingLeft = UDim.new(0, n), PaddingRight = UDim.new(0, n),
    })
end
local function vlist(gap, order)
    return new("UIListLayout", {
        Padding = UDim.new(0, gap or 6),
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = order or Enum.SortOrder.LayoutOrder,
    })
end

local function fontOf(weight)
    return Font.new("rbxasset://fonts/families/BuilderSans.json", weight, Enum.FontStyle.Normal)
end

local orderCounters = setmetatable({}, {__mode = "k"})
local function nextOrder(body)
    local n = (orderCounters[body] or 0) + 1
    orderCounters[body] = n
    return n
end

local Theme = {
    Background  = Color3.fromRGB(13, 15, 21),
    Surface     = Color3.fromRGB(22, 25, 33),
    SurfaceAlt  = Color3.fromRGB(28, 32, 42),
    Element     = Color3.fromRGB(31, 35, 46),
    Outline     = Color3.fromRGB(42, 48, 62),
    Muted       = Color3.fromRGB(150, 158, 175),
    Text        = Color3.fromRGB(236, 241, 250),
    Accent      = Color3.fromRGB(74, 146, 255),
    AccentHover = Color3.fromRGB(96, 165, 255),
    Danger      = Color3.fromRGB(240, 90, 102),
    Success     = Color3.fromRGB(82, 197, 148),
    Warning     = Color3.fromRGB(238, 182, 73),
}

local Library = {}
Library.__index = Library

Library.Flags             = {}
Library.OnUnloadCallbacks = {}
Library.Open              = false
Library.Minimized         = false
Library.Unloaded          = false
Library.Window            = nil
Library.Version           = "noir-1.0"

function Library:GetTheme() return Theme end

function Library:RegisterFlag(flag, getter, setter, default)
    if type(flag) ~= "string" or flag == "" then return end
    self.Flags[flag] = {get = getter, set = setter, default = default}
end

local ScreenGui = new("ScreenGui", {
    Name           = "NOIR",
    ResetOnSpawn   = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    DisplayOrder   = 100,
})
ScreenGui.Parent = Player:WaitForChild("PlayerGui")
Library.ScreenGui = ScreenGui

local NotifyHolder

function Library:Notify(cfg)
    cfg = cfg or {}
    local title    = cfg.Title   or "Notification"
    local content  = cfg.Content or ""
    local ntype    = string.lower(tostring(cfg.Type or "info"))
    local duration = tonumber(cfg.Duration) or 4

    if not NotifyHolder or not NotifyHolder.Parent then
        NotifyHolder = new("Frame", {
            Name = "NotifyHolder",
            AnchorPoint = Vector2.new(1, 0),
            Position = UDim2.new(1, -16, 0, 16),
            Size = UDim2.fromOffset(300, 500),
            BackgroundTransparency = 1,
            Parent = ScreenGui,
        }, {
            new("UIListLayout", {
                Padding = UDim.new(0, 8),
                SortOrder = Enum.SortOrder.LayoutOrder,
                HorizontalAlignment = Enum.HorizontalAlignment.Right,
            }),
        })
    end

    local color = Theme.Accent
    if ntype == "success" then color = Theme.Success
    elseif ntype == "warning" then color = Theme.Warning
    elseif ntype == "error" then color = Theme.Danger end

    local card = new("Frame", {
        Name = "Notify",
        Size = UDim2.new(1, 0, 0, 62),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = NotifyHolder,
    }, {corner(8), stroke(Theme.Outline, 1, 0.5)})

    new("Frame", {
        Size = UDim2.new(0, 3, 1, -16),
        Position = UDim2.fromOffset(0, 8),
        BackgroundColor3 = color,
        BorderSizePixel = 0,
        Parent = card,
    }, {corner(2)})

    new("TextLabel", {
        Position = UDim2.fromOffset(12, 8),
        Size = UDim2.new(1, -20, 0, 18),
        BackgroundTransparency = 1,
        Text = tostring(title),
        FontFace = fontOf(Enum.FontWeight.Bold),
        TextSize = 14,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = card,
    })

    new("TextLabel", {
        Position = UDim2.fromOffset(12, 27),
        Size = UDim2.new(1, -20, 0, 28),
        BackgroundTransparency = 1,
        Text = tostring(content),
        FontFace = fontOf(Enum.FontWeight.Medium),
        TextSize = 12,
        TextWrapped = true,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Top,
        Parent = card,
    })

    local scale = new("UIScale", {Scale = 0.9, Parent = card})
    TweenService:Create(scale, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Scale = 1}):Play()

    task.delay(math.max(1, duration), function()
        if not card.Parent then return end
        TweenService:Create(scale, TweenInfo.new(0.2), {Scale = 0.9}):Play()
        task.wait(0.22)
        if card.Parent then card:Destroy() end
    end)
end

function Library:KeySystem(cfg)
    cfg = cfg or {}
    local title       = cfg.Title       or "Access"
    local subtitle    = cfg.Subtitle    or ""
    local placeholder = cfg.Placeholder or "Paste your key"
    local keyButton   = cfg.KeyButton   or "Get key"
    local note        = cfg.Note        or ""
    local keyLink     = cfg.KeyLink     or ""
    local validate    = cfg.Validate

    local resolved, success = false, false
    local busy = false

    local root = new("Frame", {
        Name = "KeySystem",
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = Color3.new(0, 0, 0),
        BackgroundTransparency = 0.45,
        BorderSizePixel = 0,
        ZIndex = 70,
        Parent = ScreenGui,
    })

    local panel = new("Frame", {
        Name = "Panel",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(410, 300),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ZIndex = 71,
        Parent = root,
    }, {corner(12), stroke(Theme.Outline, 1, 0.35)})

    local logoFrame = new("Frame", {
        Name = "LogoFrame",
        Size = UDim2.fromOffset(52, 52),
        Position = UDim2.new(0, 24, 0, 24),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        ZIndex = 72,
        Parent = panel,
    }, {corner(12)})

    new("TextLabel", {
        Name = "Title",
        Position = UDim2.new(0, 90, 0, 28),
        Size = UDim2.new(1, -114, 0, 22),
        BackgroundTransparency = 1,
        Text = tostring(title),
        FontFace = fontOf(Enum.FontWeight.ExtraBold),
        TextSize = 18,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 72,
        Parent = panel,
    })

    new("TextLabel", {
        Name = "Subtitle",
        Position = UDim2.new(0, 90, 0, 50),
        Size = UDim2.new(1, -114, 0, 18),
        BackgroundTransparency = 1,
        Text = tostring(subtitle),
        FontFace = fontOf(Enum.FontWeight.SemiBold),
        TextSize = 13,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 72,
        Parent = panel,
    })

    local box = new("Frame", {
        Name = "InputBox",
        Position = UDim2.new(0, 24, 0, 100),
        Size = UDim2.new(1, -48, 0, 40),
        BackgroundColor3 = Theme.Element,
        BorderSizePixel = 0,
        ZIndex = 72,
        Parent = panel,
    }, {corner(8), stroke(Theme.Outline, 1, 0.5)})

    local input = new("TextBox", {
        Position = UDim2.new(0, 12, 0, 0),
        Size = UDim2.new(1, -24, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = placeholder,
        PlaceholderColor3 = Theme.Muted,
        FontFace = fontOf(Enum.FontWeight.Medium),
        TextSize = 13,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        ZIndex = 73,
        Parent = box,
    })

    local submit = new("TextButton", {
        Name = "Submit",
        Position = UDim2.new(0, 24, 0, 152),
        Size = UDim2.new(1, -48, 0, 36),
        BackgroundColor3 = Theme.Accent,
        AutoButtonColor = false,
        Text = "",
        ZIndex = 72,
        Parent = panel,
    }, {corner(8)})

    local submitLabel = new("TextLabel", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "Unlock",
        FontFace = fontOf(Enum.FontWeight.Bold),
        TextSize = 14,
        TextColor3 = Color3.new(1, 1, 1),
        ZIndex = 73,
        Parent = submit,
    })
    submitLabel:SetAttribute("NoTheme", true)

    local link = new("TextButton", {
        Name = "Link",
        Position = UDim2.new(0, 24, 0, 196),
        Size = UDim2.new(1, -48, 0, 28),
        BackgroundTransparency = 1,
        Text = tostring(keyButton),
        FontFace = fontOf(Enum.FontWeight.SemiBold),
        TextSize = 13,
        TextColor3 = Theme.Accent,
        ZIndex = 72,
        Parent = panel,
    })

    local status = new("TextLabel", {
        Name = "Status",
        Position = UDim2.new(0, 24, 1, -46),
        Size = UDim2.new(1, -48, 0, 18),
        BackgroundTransparency = 1,
        Text = tostring(note),
        FontFace = fontOf(Enum.FontWeight.Medium),
        TextSize = 12,
        TextColor3 = Theme.Muted,
        TextWrapped = true,
        ZIndex = 72,
        Parent = panel,
    })

    submit.MouseEnter:Connect(function()
        TweenService:Create(submit, TweenInfo.new(0.15), {BackgroundColor3 = Theme.AccentHover}):Play()
    end)
    submit.MouseLeave:Connect(function()
        TweenService:Create(submit, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
    end)

    link.Activated:Connect(function()
        if keyLink ~= "" then
            pcall(function() game:GetService("GuiService"):OpenBrowserWindow(keyLink) end)
        end
    end)

    local function attempt()
        if busy then return end
        local key = input.Text
        if type(key) ~= "string" or key == "" then
            status.Text = "Enter a key first."
            status.TextColor3 = Theme.Danger
            return
        end
        busy = true
        submitLabel.Text = "Checking..."
        local ok, message = validate(key)
        busy = false
        submitLabel.Text = "Unlock"
        if ok then
            success = true
            resolved = true
            status.Text = "Access granted."
            status.TextColor3 = Theme.Success
        else
            status.Text = tostring(message or "Invalid key.")
            status.TextColor3 = Theme.Danger
        end
    end

    submit.Activated:Connect(attempt)
    input.FocusLost:Connect(function(enter) if enter then attempt() end end)

    while not resolved do task.wait(0.05) end

    TweenService:Create(root, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
    TweenService:Create(panel, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
    task.wait(0.28)
    root:Destroy()

    return success
end

function Library:SetOpen(open)
    self.Open = open and true or false
    if self.Window and self.Window.Frame then
        self.Window.Frame.Visible = self.Open and not self.Minimized
    end
    if self.MinimizedBubble then
        self.MinimizedBubble.Visible = not self.Open and self.Minimized
    end
    if self.MobileToggle then
        self.MobileToggle.Visible = not self.Open and not self.Minimized
    end
end

function Library:SetMinimized(value)
    value = value and true or false
    self.Minimized = value
    if self.Window and self.Window.Frame then
        self.Window.Frame.Visible = not value and self.Open
    end
    if self.MinimizedBubble then
        self.MinimizedBubble.Visible = value
    end
    if self.MobileToggle then
        self.MobileToggle.Visible = not self.Open and not value
    end
end

function Library:CreateWindow(cfg)
    cfg = cfg or {}
    local title    = cfg.Title    or "NOIR"
    local subtitle = cfg.Subtitle or ""

    if self.Window then return self.Window end

    local Window = {Tabs = {}, ActiveTab = nil, Title = title}
    self.Window = Window

    local main = new("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(660, 470),
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = ScreenGui,
    }, {corner(10), stroke(Theme.Outline, 1, 0.4), new("UIScale", {Scale = 1})})
    Window.Frame = main

    local topBar = new("Frame", {
        Name = "TopBar",
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Parent = main,
    }, {corner(10)})
    new("Frame", {
        Position = UDim2.new(0, 0, 1, -1),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Theme.Outline,
        BorderSizePixel = 0,
        Parent = topBar,
    })

    local brand = new("Frame", {
        Name = "Brand",
        Size = UDim2.new(1, -110, 1, 0),
        BackgroundTransparency = 1,
        Parent = topBar,
    })

    new("Frame", {
        Name = "LogoFrame",
        Position = UDim2.new(0, 12, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.fromOffset(42, 42),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = brand,
    }, {corner(10)})

    new("TextLabel", {
        Name = "Title",
        Position = UDim2.fromOffset(64, 10),
        Size = UDim2.new(1, -72, 0, 20),
        BackgroundTransparency = 1,
        Text = tostring(title),
        FontFace = fontOf(Enum.FontWeight.ExtraBold),
        TextSize = 16,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = brand,
    })

    new("TextLabel", {
        Name = "Subtitle",
        Position = UDim2.fromOffset(64, 30),
        Size = UDim2.new(1, -72, 0, 16),
        BackgroundTransparency = 1,
        Text = tostring(subtitle),
        FontFace = fontOf(Enum.FontWeight.SemiBold),
        TextSize = 12,
        TextColor3 = Theme.Muted,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = brand,
    })

    local controls = new("Frame", {
        Name = "Controls",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -12, 0, 0),
        Size = UDim2.fromOffset(80, 58),
        BackgroundTransparency = 1,
        Parent = topBar,
    })

    local minimizeBtn = new("TextButton", {
        Name = "MinimizeButton",
        Position = UDim2.new(0, 0, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = Theme.Element,
        AutoButtonColor = false,
        Text = "",
        Parent = controls,
    }, {corner(8)})
    new("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(12, 2),
        BackgroundColor3 = Theme.Muted,
        BorderSizePixel = 0,
        Parent = minimizeBtn,
    }, {corner(1)})

    local closeBtn = new("TextButton", {
        Name = "CloseButton",
        Position = UDim2.new(0, 40, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        Size = UDim2.fromOffset(30, 30),
        BackgroundColor3 = Theme.Element,
        AutoButtonColor = false,
        Text = "×",
        FontFace = fontOf(Enum.FontWeight.Bold),
        TextSize = 18,
        TextColor3 = Theme.Muted,
        Parent = controls,
    }, {corner(8)})

    local dragging, dragStart, dragOrigin
    local function overControls(pos)
        local p, s = controls.AbsolutePosition, controls.AbsoluteSize
        return pos.X >= p.X and pos.X <= p.X + s.X and pos.Y >= p.Y and pos.Y <= p.Y + s.Y
    end

    topBar.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        if overControls(input.Position) then return end
        dragging = true
        dragStart = input.Position
        dragOrigin = main.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end)

    UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local d = input.Position - dragStart
        main.Position = UDim2.new(
            dragOrigin.X.Scale, dragOrigin.X.Offset + d.X,
            dragOrigin.Y.Scale, dragOrigin.Y.Offset + d.Y)
    end)

    local sidebar = new("Frame", {
        Name = "Sidebar",
        Position = UDim2.fromOffset(0, 58),
        Size = UDim2.new(0, 152, 1, -58),
        BackgroundTransparency = 1,
        Parent = main,
    }, {pad(8), vlist(4)})

    local content = new("Frame", {
        Name = "Content",
        Position = UDim2.fromOffset(152, 58),
        Size = UDim2.new(1, -152, 1, -58),
        BackgroundTransparency = 1,
        Parent = main,
    })

    local bubble = new("TextButton", {
        Name = "MinimizedBubble",
        AnchorPoint = Vector2.new(0, 0),
        Position = UDim2.fromOffset(24, 24),
        Size = UDim2.fromOffset(68, 68),
        BackgroundColor3 = Theme.Accent,
        AutoButtonColor = false,
        Text = "",
        Visible = false,
        Parent = ScreenGui,
    }, {corner(16), stroke(Theme.Outline, 1, 0.4)})
    self.MinimizedBubble = bubble

    local mobile = new("TextButton", {
        Name = "MobileToggle",
        AnchorPoint = Vector2.new(0, 1),
        Position = UDim2.new(0, 20, 1, -100),
        Size = UDim2.fromOffset(60, 60),
        BackgroundColor3 = Theme.Accent,
        AutoButtonColor = false,
        Text = "",
        Visible = false,
        Parent = ScreenGui,
    }, {corner(16), stroke(Theme.Outline, 1, 0.4)})
    self.MobileToggle = mobile

    bubble.Activated:Connect(function()
        Library:SetMinimized(false)
        Library:SetOpen(true)
    end)
    mobile.Activated:Connect(function()
        Library:SetOpen(true)
    end)
    minimizeBtn.Activated:Connect(function()
        Library:SetMinimized(not Library.Minimized)
    end)
    closeBtn.Activated:Connect(function()
        Library:SetOpen(not Library.Open)
    end)

    function Window:Tab(tabCfg)
        tabCfg = tabCfg or {}
        local name = tabCfg.Name or "Tab"

        local Tab = {Name = name, Window = Window, _sectionIndex = 0}

        local page = new("Frame", {
            Name = name .. "Page",
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Visible = false,
            Parent = content,
        })
        Tab.Page = page

        local function makeColumn(colName, pos)
            return new("ScrollingFrame", {
                Name = colName,
                Position = pos,
                Size = UDim2.new(0.5, -10, 1, -8),
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ScrollBarThickness = 3,
                ScrollBarImageColor3 = Theme.Outline,
                ScrollBarImageTransparency = 0.4,
                CanvasSize = UDim2.new(),
                AutomaticCanvasSize = Enum.AutomaticSize.Y,
                Parent = page,
            }, {vlist(8), pad(4)})
        end

        Tab.LeftColumn  = makeColumn("Left",  UDim2.fromOffset(4, 4))
        Tab.RightColumn = makeColumn("Right", UDim2.new(0.5, 6, 0, 4))

        local button = new("TextButton", {
            Name = name .. "Button",
            Size = UDim2.new(1, 0, 0, 34),
            BackgroundColor3 = Theme.Element,
            BackgroundTransparency = 0.35,
            AutoButtonColor = false,
            Text = "",
            Parent = sidebar,
        }, {corner(8)})
        Tab.Button = button

        local label = new("TextLabel", {
            Name = "Label",
            Position = UDim2.fromOffset(12, 0),
            Size = UDim2.new(1, -20, 1, 0),
            BackgroundTransparency = 1,
            Text = name,
            FontFace = fontOf(Enum.FontWeight.SemiBold),
            TextSize = 13,
            TextColor3 = Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = button,
        })
        Tab.Label = label

        local accent = new("Frame", {
            Name = "Accent",
            Position = UDim2.fromOffset(0, 6),
            Size = UDim2.new(0, 2, 1, -12),
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Visible = false,
            Parent = button,
        }, {corner(1)})

        button.Activated:Connect(function() Window:SelectTab(Tab) end)

        table.insert(Window.Tabs, Tab)

        if #Window.Tabs == 1 then
            Window:SelectTab(Tab)
        end

        return Tab
    end

    function Window:SelectTab(tab)
        for _, t in ipairs(self.Tabs) do
            local active = (t == tab)
            t.Page.Visible = active
            TweenService:Create(t.Button, TweenInfo.new(0.15), {
                BackgroundTransparency = active and 0 or 0.35,
            }):Play()
            TweenService:Create(t.Label, TweenInfo.new(0.15), {
                TextColor3 = active and Theme.Text or Theme.Muted,
            }):Play()
            local accentBar = t.Button:FindFirstChild("Accent")
            if accentBar then accentBar.Visible = active end
        end
        self.ActiveTab = tab
    end

    Library.Window = Window
    Library.Open = true
    Library.Minimized = false
    main.Visible = true

    return Window
end

local SectionMethods = {}

local function controlRow(parent, height, order)
    return new("Frame", {
        Size = UDim2.new(1, 0, 0, height),
        BackgroundColor3 = Theme.Element,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        LayoutOrder = order,
        Parent = parent,
    }, {corner(7), stroke(Theme.Outline, 1, 0.6)})
end

local function iconDot(parent, x, y, size, color)
    return new("Frame", {
        Position = UDim2.fromOffset(x, y),
        Size = UDim2.fromOffset(size, size),
        BackgroundColor3 = color or Theme.Muted,
        BackgroundTransparency = 0.35,
        BorderSizePixel = 0,
        Parent = parent,
    }, {corner(size / 2)})
end

function SectionMethods:Toggle(cfg)
    cfg = cfg or {}
    local order = nextOrder(self.Body)
    local value = cfg.Default and true or false

    local row = controlRow(self.Body, 34, order)
    iconDot(row, 10, 9, 16)

    new("TextLabel", {
        Position = UDim2.fromOffset(34, 0),
        Size = UDim2.new(1, -110, 1, 0),
        BackgroundTransparency = 1,
        Text = cfg.Name or "Toggle",
        FontFace = fontOf(Enum.FontWeight.SemiBold),
        TextSize = 13,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local switch = new("Frame", {
        Name = "Switch",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(34, 18),
        BackgroundColor3 = Theme.Outline,
        BorderSizePixel = 0,
        Parent = row,
    }, {corner(9)})

    local knob = new("Frame", {
        Name = "Knob",
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = switch,
    }, {corner(7)})

    local hit = new("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        Parent = row,
    })

    local control = {Section = self, Body = self.Body, Flag = cfg.Flag}

    local function paint(v)
        TweenService:Create(switch, TweenInfo.new(0.15), {
            BackgroundColor3 = v and Theme.Accent or Theme.Outline,
        }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), {
            Position = v and UDim2.new(0, 18, 0.5, 0) or UDim2.new(0, 2, 0.5, 0),
        }):Play()
    end

    function control:Get() return value end

    function control:Set(v, silent)
        v = v and true or false
        if value == v and not silent then return end
        value = v
        paint(v)
        if self._sub then self._sub.Container.Visible = v end
        if not silent and type(cfg.Callback) == "function" then
            local ok, err = pcall(cfg.Callback, v)
            if not ok then warn("[NOIR] Toggle callback error: " .. tostring(err)) end
        end
    end

    hit.Activated:Connect(function() control:Set(not value) end)

    function control:SubOptions()
        if self._sub then return self._sub end
        local subOrder = nextOrder(self.Body)
        local sub = new("Frame", {
            Name = "SubOptions",
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            BackgroundTransparency = 1,
            LayoutOrder = subOrder,
            Visible = value,
            Parent = self.Body,
        }, {vlist(4)})
        self._sub = setmetatable({Body = sub, Parent = self, Container = sub}, {__index = SectionMethods})
        return self._sub
    end

    control:Set(value, true)
    Library:RegisterFlag(cfg.Flag,
        function() return value end,
        function(v) control:Set(v, true) end,
        value)

    return control
end

function SectionMethods:Slider(cfg)
    cfg = cfg or {}
    local order = nextOrder(self.Body)
    local min  = tonumber(cfg.Min) or 0
    local max  = tonumber(cfg.Max) or 100
    local inc  = tonumber(cfg.Increment) or 1
    if inc <= 0 then inc = 1 end
    local value = math.clamp(tonumber(cfg.Default) or min, min, max)

    local row = controlRow(self.Body, 46, order)

    new("TextLabel", {
        Position = UDim2.fromOffset(12, 6),
        Size = UDim2.new(1, -70, 0, 16),
        BackgroundTransparency = 1,
        Text = cfg.Name or "Slider",
        FontFace = fontOf(Enum.FontWeight.SemiBold),
        TextSize = 13,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local valueLabel = new("TextLabel", {
        Name = "Value",
        Position = UDim2.new(1, -60, 0, 6),
        Size = UDim2.fromOffset(50, 16),
        BackgroundTransparency = 1,
        Text = tostring(value),
        FontFace = fontOf(Enum.FontWeight.SemiBold),
        TextSize = 12,
        TextColor3 = Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = row,
    })

    local track = new("Frame", {
        Name = "Track",
        Position = UDim2.new(0, 12, 1, -18),
        Size = UDim2.new(1, -24, 0, 6),
        BackgroundColor3 = Theme.Outline,
        BorderSizePixel = 0,
        Parent = row,
    }, {corner(3)})

    local fill = new("Frame", {
        Name = "Fill",
        Size = UDim2.new(0, 0, 1, 0),
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Parent = track,
    }, {corner(3)})

    local knob = new("Frame", {
        Name = "Knob",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BorderSizePixel = 0,
        Parent = track,
    }, {corner(7), stroke(Theme.Accent, 2, 0)})

    local hit = new("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        Parent = row,
    })

    local function apply(v, fire)
        v = math.clamp(v, min, max)
        v = min + math.floor((v - min) / inc + 0.5) * inc
        v = math.clamp(v, min, max)
        value = v

        local alpha = (max == min) and 0 or (v - min) / (max - min)
        fill.Size = UDim2.new(alpha, 0, 1, 0)
        knob.Position = UDim2.new(alpha, 0, 0.5, 0)
        valueLabel.Text = (v % 1 == 0) and string.format("%d", v) or string.format("%.2f", v)

        if fire and type(cfg.Callback) == "function" then
            local ok, err = pcall(cfg.Callback, v)
            if not ok then warn("[NOIR] Slider callback error: " .. tostring(err)) end
        end
    end

    local dragging = false
    local function updateFromInput(input)
        local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / math.max(1, track.AbsoluteSize.X), 0, 1)
        apply(min + (max - min) * rel, true)
    end

    hit.InputBegan:Connect(function(input)
        if input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        dragging = true
        updateFromInput(input)
    end)

    UIS.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then return end
        updateFromInput(input)
    end)

    UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                if type(cfg.Callback) == "function" then pcall(cfg.Callback, value) end
            end
        end
    end)

    apply(value, false)

    local control = {Section = self, Flag = cfg.Flag}
    function control:Get() return value end
    function control:Set(v) apply(v, true) end

    Library:RegisterFlag(cfg.Flag,
        function() return value end,
        function(v) apply(v, true) end,
        value)

    return control
end

function SectionMethods:Dropdown(cfg)
    cfg = cfg or {}
    local order = nextOrder(self.Body)
    local options = cfg.Options or {}
    local value = cfg.Default or options[1]
    local open = false

    local row = controlRow(self.Body, 34, order)
    iconDot(row, 10, 9, 16)

    new("TextLabel", {
        Position = UDim2.fromOffset(34, 0),
        Size = UDim2.new(1, -140, 1, 0),
        BackgroundTransparency = 1,
        Text = cfg.Name or "Dropdown",
        FontFace = fontOf(Enum.FontWeight.SemiBold),
        TextSize = 13,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = row,
    })

    local valueLabel = new("TextLabel", {
        Name = "Value",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -30, 0.5, 0),
        Size = UDim2.new(0.5, 0, 1, 0),
        BackgroundTransparency = 1,
        Text = tostring(value),
        FontFace = fontOf(Enum.FontWeight.SemiBold),
        TextSize = 12,
        TextColor3 = Theme.Accent,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextTruncate = Enum.TextTruncate.AtEnd,
        Parent = row,
    })

    local arrow = new("TextLabel", {
        Name = "Arrow",
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -10, 0.5, 0),
        Size = UDim2.fromOffset(14, 14),
        BackgroundTransparency = 1,
        Text = "▾",
        FontFace = fontOf(Enum.FontWeight.Bold),
        TextSize = 12,
        TextColor3 = Theme.Muted,
        Parent = row,
    })

    local hit = new("TextButton", {
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        Parent = row,
    })

    local listOrder = nextOrder(self.Body)
    local list = new("Frame", {
        Name = "Options",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundColor3 = Theme.SurfaceAlt,
        BorderSizePixel = 0,
        LayoutOrder = listOrder,
        Visible = false,
        Parent = self.Body,
    }, {corner(7), stroke(Theme.Outline, 1, 0.5), vlist(2), pad(4)})

    local control = {Section = self, Flag = cfg.Flag, Options = options}
    local buttons = {}

    local function paintSelection()
        for opt, btn in pairs(buttons) do
            btn.BackgroundTransparency = (opt == value) and 0.1 or 1
            btn.TextColor3 = (opt == value) and Theme.Text or Theme.Muted
        end
        valueLabel.Text = tostring(value)
    end

    for _, opt in ipairs(options) do
        local btn = new("TextButton", {
            Name = tostring(opt),
            Size = UDim2.new(1, 0, 0, 26),
            BackgroundColor3 = Theme.Element,
            BackgroundTransparency = 1,
            AutoButtonColor = false,
            Text = tostring(opt),
            FontFace = fontOf(Enum.FontWeight.SemiBold),
            TextSize = 12,
            TextColor3 = Theme.Muted,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = list,
        }, {corner(5), pad(8)})
        buttons[opt] = btn

        btn.MouseEnter:Connect(function()
            if opt ~= value then
                TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 0.6}):Play()
            end
        end)
        btn.MouseLeave:Connect(function()
            if opt ~= value then
                TweenService:Create(btn, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
            end
        end)
        btn.Activated:Connect(function()
            control:Set(opt)
            open = false
            list.Visible = false
            arrow.Text = "▾"
        end)
    end

    local function setOpen(v)
        open = v
        list.Visible = v
        arrow.Text = v and "▴" or "▾"
    end

    hit.Activated:Connect(function() setOpen(not open) end)

    function control:Get() return value end
    function control:Set(v, silent)
        if v == nil then return end
        value = v
        paintSelection()
        if not silent and type(cfg.Callback) == "function" then
            local ok, err = pcall(cfg.Callback, v)
            if not ok then warn("[NOIR] Dropdown callback error: " .. tostring(err)) end
        end
    end

    paintSelection()

    Library:RegisterFlag(cfg.Flag,
        function() return value end,
        function(v) control:Set(v, true) end,
        value)

    return control
end

local TabMethods = {}

function TabMethods:Section(cfg)
    cfg = cfg or {}
    local side = tostring(cfg.Side or "Left")
    local column = (side == "Right") and self.RightColumn or self.LeftColumn

    local order = self._sectionIndex
    self._sectionIndex += 1

    local container = new("Frame", {
        Name = cfg.Name or "Section",
        Size = UDim2.new(1, -8, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = order,
        Parent = column,
    }, {vlist(6)})

    local header = new("Frame", {
        Name = "Header",
        Size = UDim2.new(1, 0, 0, 24),
        BackgroundTransparency = 1,
        LayoutOrder = 0,
        Parent = container,
    })
    iconDot(header, 2, 4, 14, Theme.Accent)
    new("TextLabel", {
        Position = UDim2.fromOffset(24, 0),
        Size = UDim2.new(1, -24, 1, 0),
        BackgroundTransparency = 1,
        Text = cfg.Name or "Section",
        FontFace = fontOf(Enum.FontWeight.Bold),
        TextSize = 13,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = header,
    })

    local body = new("Frame", {
        Name = "Body",
        Size = UDim2.new(1, 0, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        LayoutOrder = 1,
        Parent = container,
    }, {vlist(6)})

    return setmetatable({
        Container = container,
        Body      = body,
        Header    = header,
        Tab       = self,
        Name      = cfg.Name,
    }, {__index = SectionMethods})
end

local fs = {
    write  = type(writefile)  == "function" and writefile  or nil,
    read   = type(readfile)   == "function" and readfile   or nil,
    isfile = type(isfile)     == "function" and isfile     or nil,
    isdir  = type(isfolder)   == "function" and isfolder   or nil,
    mkdir  = type(makefolder) == "function" and makefolder or nil,
    list   = type(listfiles)  == "function" and listfiles  or nil,
    delete = type(delfile)    == "function" and delfile    or nil,
}
local FOLDER = "NOIR"
local memoryStore = {}

local function ensureFolder()
    if fs.isdir and fs.mkdir then
        pcall(function()
            if not fs.isdir(FOLDER) then fs.mkdir(FOLDER) end
        end)
    end
end

local function configPath(scope, name)
    return FOLDER .. "/" .. tostring(scope) .. "_" .. tostring(name) .. ".json"
end

local function snapshot()
    local data = {}
    for flag, entry in pairs(Library.Flags) do
        local ok, v = pcall(entry.get)
        if ok and (type(v) == "boolean" or type(v) == "number" or type(v) == "string") then
            data[flag] = v
        end
    end
    return data
end

local function restore(data)
    if type(data) ~= "table" then return end
    for flag, v in pairs(data) do
        local entry = Library.Flags[flag]
        if entry then pcall(entry.set, v) end
    end
end

function Library:AddConfigSections(tab, cfg)
    cfg = cfg or {}
    local scope = tostring(cfg.Scope or "default")

    local section = tab:Section({Name = "Config", Side = cfg.Side or "Right"})

    local nameBox = new("Frame", {
        Size = UDim2.new(1, 0, 0, 34),
        BackgroundColor3 = Theme.Element,
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        LayoutOrder = nextOrder(section.Body),
        Parent = section.Body,
    }, {corner(7), stroke(Theme.Outline, 1, 0.6)})

    local nameInput = new("TextBox", {
        Position = UDim2.fromOffset(12, 0),
        Size = UDim2.new(1, -24, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "Config name",
        PlaceholderColor3 = Theme.Muted,
        FontFace = fontOf(Enum.FontWeight.Medium),
        TextSize = 13,
        TextColor3 = Theme.Text,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        Parent = nameBox,
    })

    local function save()
        local name = nameInput.Text
        if name == nil or name == "" then
            Library:Notify({Title = "Config", Content = "Enter a config name.", Type = "warning", Duration = 3})
            return
        end
        local payload = HttpService:JSONEncode(snapshot())
        local ok = false
        if fs.write then
            ensureFolder()
            ok = pcall(fs.write, configPath(scope, name), payload)
        else
            memoryStore[scope .. "_" .. name] = payload
            ok = true
        end
        Library:Notify({
            Title = "Config",
            Content = ok and ("Saved " .. name) or "Could not save config.",
            Type = ok and "success" or "error",
            Duration = 3,
        })
    end

    local function load()
        local name = nameInput.Text
        if name == "" then
            Library:Notify({Title = "Config", Content = "Enter a config name.", Type = "warning", Duration = 3})
            return
        end
        local body
        if fs.read then
            local ok, data = pcall(fs.read, configPath(scope, name))
            if ok then body = data end
        else
            body = memoryStore[scope .. "_" .. name]
        end
        if not body then
            Library:Notify({Title = "Config", Content = "Config not found.", Type = "error", Duration = 3})
            return
        end
        local ok, decoded = pcall(HttpService.JSONDecode, HttpService, body)
        if not ok or type(decoded) ~= "table" then
            Library:Notify({Title = "Config", Content = "Config is corrupted.", Type = "error", Duration = 3})
            return
        end
        restore(decoded)
        Library:Notify({Title = "Config", Content = "Loaded " .. name, Type = "success", Duration = 3})
    end

    local function remove()
        local name = nameInput.Text
        if name == "" then return end
        if fs.delete then
            pcall(fs.delete, configPath(scope, name))
        else
            memoryStore[scope .. "_" .. name] = nil
        end
        Library:Notify({Title = "Config", Content = "Deleted " .. name, Type = "info", Duration = 3})
    end

    local function button(label, order, cb, color)
        local b = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = color or Theme.Element,
            BackgroundTransparency = 0.1,
            AutoButtonColor = false,
            Text = label,
            FontFace = fontOf(Enum.FontWeight.SemiBold),
            TextSize = 13,
            TextColor3 = Theme.Text,
            LayoutOrder = order,
            Parent = section.Body,
        }, {corner(7), stroke(Theme.Outline, 1, 0.6)})
        b.Activated:Connect(cb)
        return b
    end

    button("Save config",   nextOrder(section.Body), save,   Theme.Accent)
    button("Load config",   nextOrder(section.Body), load)
    button("Delete config", nextOrder(section.Body), remove, Theme.Danger)

    return section
end

function Library:OnUnload(fn)
    if type(fn) == "function" then
        table.insert(self.OnUnloadCallbacks, fn)
    end
end

function Library:Unload()
    if self.Unloaded then return end
    self.Unloaded = true
    self.Open = false

    for _, fn in ipairs(self.OnUnloadCallbacks) do
        local ok, err = pcall(fn)
        if not ok then warn("[NOIR] Unload callback error: " .. tostring(err)) end
    end
    table.clear(self.OnUnloadCallbacks)

    if ScreenGui then
        pcall(function() ScreenGui:Destroy() end)
    end
end

return Library
