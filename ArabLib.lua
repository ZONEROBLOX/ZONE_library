-- ArabLib Full (ModuleScript)
-- مكتبة متكاملة تشبه SP Hub
-- Author: Yusuf (ArabLib)
-- Usage: local splib = require(path_to_ArabLib)()

local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local DEFAULTS = {
    Name = "SP Library v2",
    SubTitle = "by ArabLib",
    Setting = true,
    Toggle = true,
    Icon = "rbxassetid://83114982417764",
    RainbowMainFrame = false,
    RainbowTitle = false,
    RainbowSubTitle = false,
    ToggleIcon = "rbxassetid://83114982417764",
    CloseCallback = nil,
    Theme = {
        Background = Color3.fromRGB(20,20,20),
        Main = Color3.fromRGB(36, 36, 36),
        Accent = Color3.fromRGB(0, 170, 255),
        TextColor = Color3.fromRGB(240,240,240),
        Stroke = Color3.fromRGB(45,45,45)
    },
    Scale = 1
}

local ArabLib = {}
ArabLib.__index = ArabLib

-- internal storage for saves (supports exploit writefile/readfile if available)
local Storage = {}
local STORAGE_FILE = "ArabLib_Settings.json"

local function safeReadFile(path)
    if (isfile and readfile and isfile(path)) then
        local content = readfile(path)
        return content
    end
    return nil
end
local function safeWriteFile(path, content)
    if (writefile) then
        pcall(function() writefile(path, content) end)
        return true
    end
    return false
end

-- load storage from file or memory
pcall(function()
    local raw = safeReadFile(STORAGE_FILE)
    if raw then
        local ok, t = pcall(function() return HttpService:JSONDecode(raw) end)
        if ok and type(t)=="table" then Storage = t end
    end
end)

local function persistStorage()
    local ok, encoded = pcall(function() return HttpService:JSONEncode(Storage) end)
    if ok then pcall(function() safeWriteFile(STORAGE_FILE, encoded) end) end
end

-- helper
local function new(class, props)
    local obj = Instance.new(class)
    for k,v in pairs(props or {}) do
        if k ~= "Parent" then
            pcall(function() obj[k] = v end)
        else
            obj.Parent = v
        end
    end
    return obj
end

local function applyUICorner(inst, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius or UDim.new(0,6)
    c.Parent = inst
    return c
end

-- default assets
local DEFAULT_ICON = DEFAULTS.Icon

-- API skeleton
function ArabLib.new()
    local self = setmetatable({}, ArabLib)
    self.Windows = {}
    self.Theme = DEFAULTS.Theme
    self.Scale = DEFAULTS.Scale
    self.IconCache = {}
    return self
end

-- utility: get icon value (allow asset id or url)
function ArabLib:GetIcon(input)
    if not input then return DEFAULT_ICON end
    return tostring(input)
end

function ArabLib:SetTheme(tbl)
    for k,v in pairs(tbl) do
        self.Theme[k] = v
    end
    -- apply to open windows
    for _,w in pairs(self.Windows) do
        if w and w.ApplyTheme then pcall(w.ApplyTheme, w) end
    end
end

function ArabLib:SetScale(num)
    self.Scale = tonumber(num) or 1
    for _,w in pairs(self.Windows) do
        if w and w.ApplyScale then pcall(w.ApplyScale, w) end
    end
end

function ArabLib:Destroy()
    for _,w in pairs(self.Windows) do
        if w and w.Destroy then pcall(w.Destroy, w) end
    end
    self.Windows = {}
end

-- Notification
function ArabLib:MakeNotification(config)
    config = config or {}
    local Title = config.Name or "Notification"
    local Content = config.Content or "Hello"
    local Image = config.Image or DEFAULT_ICON
    local Time = config.Time or 4

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ArabLib_Notification"
    ScreenGui.Parent = game:GetService("CoreGui")

    local Frame = new("Frame", {
        Size = UDim2.new(0, 300, 0, 80),
        Position = UDim2.new(1, -320, 0, 20 + (#game:GetService("CoreGui"):GetChildren() * 90)),
        BackgroundColor3 = self.Theme.Main,
        Parent = ScreenGui
    })
    applyUICorner(Frame, UDim.new(0,8))

    local Icon = new("ImageLabel", {
        Size = UDim2.new(0,50,0,50),
        Position = UDim2.new(0,10,0,15),
        BackgroundTransparency = 1,
        Image = self:GetIcon(Image),
        Parent = Frame
    })

    local TitleLbl = new("TextLabel", {
        Text = Title,
        Size = UDim2.new(1, -70, 0, 22),
        Position = UDim2.new(0,70,0,12),
        BackgroundTransparency = 1,
        TextColor3 = self.Theme.TextColor,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        Parent = Frame
    })

    local ContentLbl = new("TextLabel", {
        Text = Content,
        Size = UDim2.new(1, -80, 0, 40),
        Position = UDim2.new(0,70,0,30),
        BackgroundTransparency = 1,
        TextColor3 = self.Theme.TextColor,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = Frame
    })

    -- show tween
    Frame.BackgroundTransparency = 1
    TweenService:Create(Frame, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {BackgroundTransparency = 0}):Play()

    delay(Time, function()
        pcall(function() Frame:Destroy(); ScreenGui:Destroy() end)
    end)
end

-- Dialog
function ArabLib:Dialog(config)
    config = config or {}
    local Title = config.Title or "Confirm"
    local Text = config.Text or "Are you sure?"
    local Options = config.Options or {{"Yes"},{"No"}}

    local gui = Instance.new("ScreenGui")
    gui.Parent = game:GetService("CoreGui")
    gui.Name = "ArabLib_Dialog"

    local overlay = new("Frame", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 0.5, BackgroundColor3 = Color3.new(0,0,0), Parent = gui})

    local box = new("Frame", {Size = UDim2.new(0, 420, 0, 200), Position = UDim2.new(0.5,-210,0.5,-100), BackgroundColor3 = self.Theme.Main, Parent = gui})
    applyUICorner(box, UDim.new(0,10))

    local titleLbl = new("TextLabel", {Text = Title, Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1, TextColor3 = self.Theme.TextColor, Font = Enum.Font.GothamBold, TextSize = 18, Parent = box})
    local textLbl = new("TextLabel", {Text = Text, Size = UDim2.new(1,-20,0,90), Position = UDim2.new(0,10,0,50), BackgroundTransparency = 1, TextColor3 = self.Theme.TextColor, TextWrapped=true, Font = Enum.Font.Gotham, TextSize=14, Parent = box})

    local buttonsFrame = new("Frame", {Size = UDim2.new(1,0,0,50), Position = UDim2.new(0,0,1,-50), BackgroundTransparency = 1, Parent = box})

    for i,opt in ipairs(Options) do
        local name = opt[1] or tostring(i)
        local cb = opt[2]
        local btn = new("TextButton", {Text = name, Size = UDim2.new(0,120,0,36), Position = UDim2.new(0, 10 + (i-1)*130, 0,7), BackgroundColor3 = self.Theme.Accent, TextColor3 = Color3.new(1,1,1), Parent = buttonsFrame})
        applyUICorner(btn)
        btn.MouseButton1Click:Connect(function()
            pcall(function() if type(cb)=="function" then cb() end end)
            gui:Destroy()
        end)
    end
end

-- Window / Tab / Section API
local WindowClass = {}
WindowClass.__index = WindowClass

local TabClass = {}
TabClass.__index = TabClass

local SectionClass = {}
SectionClass.__index = SectionClass

-- internal function to create base UI
local function buildBaseWindow(self, config)
    config = config or {}
    local Gui = Instance.new("ScreenGui")
    Gui.Name = config.Name or DEFAULTS.Name
    Gui.ResetOnSpawn = false
    Gui.Parent = game:GetService("CoreGui")

    local mainFrame = new("Frame", {Size = UDim2.new(0,600* (self.Scale or 1), 0,420*(self.Scale or 1)), Position = UDim2.new(0.15,0,0.15,0), BackgroundColor3 = self.Theme.Background, Parent = Gui})
    applyUICorner(mainFrame, UDim.new(0,12))

    local top = new("Frame", {Size = UDim2.new(1,0,0,48*(self.Scale or 1)), BackgroundColor3 = self.Theme.Main, Parent = mainFrame})
    applyUICorner(top, UDim.new(0,12))

    local title = new("TextLabel", {Text = config.Name or DEFAULTS.Name, Size = UDim2.new(0.6,0,1,0), BackgroundTransparency = 1, TextColor3 = self.Theme.TextColor, Font = Enum.Font.GothamBold, TextSize = 20*(self.Scale or 1), Parent = top})
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Position = UDim2.new(0,16*(self.Scale or 1),0,0)

    local subtitle = new("TextLabel", {Text = config.SubTitle or DEFAULTS.SubTitle, Size = UDim2.new(0.3,0,1,0), BackgroundTransparency = 1, TextColor3 = self.Theme.TextColor, Font = Enum.Font.Gotham, TextSize = 14*(self.Scale or 1), Parent = top})
    subtitle.Position = UDim2.new(0.6,0,0,0)
    subtitle.TextXAlignment = Enum.TextXAlignment.Right
    subtitle.TextYAlignment = Enum.TextYAlignment.Center

    local side = new("Frame", {Size = UDim2.new(0,140*(self.Scale or 1),1,0), Position = UDim2.new(0,0,0,48*(self.Scale or 1)), BackgroundColor3 = self.Theme.Main, Parent = mainFrame})
    applyUICorner(side, UDim.new(0,10))

    local content = new("Frame", {Size = UDim2.new(1, -140*(self.Scale or 1), 1, -48*(self.Scale or 1)), Position = UDim2.new(0,140*(self.Scale or 1),0,48*(self.Scale or 1)), BackgroundTransparency = 1, Parent = mainFrame})

    local tabsList = new("ScrollingFrame", {Size = UDim2.new(1,0,1,0), BackgroundTransparency = 1, ScrollBarThickness = 6, Parent = side})
    tabsList.CanvasSize = UDim2.new(0,0,0,0)

    return {
        Gui = Gui,
        MainFrame = mainFrame,
        Top = top,
        Title = title,
        Subtitle = subtitle,
        Side = side,
        Content = content,
        TabsList = tabsList
    }
end

function WindowClass:ApplyTheme()
    local w = self
    local t = w.Lib.Theme
    if w._base then
        w._base.MainFrame.BackgroundColor3 = t.Background
        w._base.Top.BackgroundColor3 = t.Main
        w._base.Side.BackgroundColor3 = t.Main
        w._base.Title.TextColor3 = t.TextColor
        w._base.Subtitle.TextColor3 = t.TextColor
    end
    -- apply to children
end
function WindowClass:ApplyScale()
    local w = self
    local s = w.Lib.Scale
    if w._base then
        local mf = w._base.MainFrame
        mf.Size = UDim2.new(0,600 * s,0,420 * s)
        w._base.Top.Size = UDim2.new(1,0,0,48 * s)
        w._base.Side.Size = UDim2.new(0,140*s,1,0)
        w._base.Title.TextSize = 20 * s
        w._base.Subtitle.TextSize = 14 * s
    end
end

function WindowClass:Destroy()
    if self._base and self._base.Gui then
        self._base.Gui:Destroy()
    end
    if type(self.Config.CloseCallback) == "function" then
        pcall(self.Config.CloseCallback)
    end
end

-- create window API
function ArabLib:MakeWindow(config)
    config = config or {}
    local wobj = setmetatable({}, WindowClass)
    wobj.Lib = self
    wobj.Config = config
    wobj._base = buildBaseWindow(self, config)

    wobj.Tabs = {}

    -- toggle behaviour
    if config.Toggle then
        -- add a small toggle button top-right
        local btn = new("ImageButton", {Size=UDim2.new(0,36,0,36), Position = UDim2.new(1,-44,0,6), BackgroundTransparency = 1, Parent = wobj._base.Top})
        btn.Image = self:GetIcon(config.ToggleIcon or DEFAULT_ICON)
        btn.Name = "ToggleBtn"
        btn.MouseButton1Click:Connect(function()
            wobj._base.MainFrame.Visible = not wobj._base.MainFrame.Visible
        end)
    end

    -- settings button
    if config.Setting then
        local sbtn = new("TextButton", {Text = "⚙", Size = UDim2.new(0,36,0,36), Position = UDim2.new(1,-88,0,6), BackgroundTransparency = 0.6, Parent = wobj._base.Top})
        applyUICorner(sbtn, UDim.new(0,6))
        sbtn.MouseButton1Click:Connect(function() -- simple: open settings dialog
            self:Dialog({Title = "Settings", Text = "لا توجد إعدادات متقدمة حاليا", Options = {{"اغلاق"}}})
        end)
    end

    -- API functions
    function wobj:MakeTab(tabConfig)
        tabConfig = tabConfig or {}
        local tab = setmetatable({}, TabClass)
        tab.Lib = self.Lib
        tab.Window = self
        tab.Config = tabConfig
        tab.Sections = {}

        -- create tab button in side
        local btn = new("TextButton", {Text = tabConfig.Name or "Tab", Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1, TextColor3 = self.Lib.Theme.TextColor, Parent = self._base.TabsList})
        applyUICorner(btn)
        btn.BackgroundColor3 = Color3.fromRGB(0,0,0)

        -- create content frame
        local frame = new("ScrollingFrame", {Size = UDim2.new(1,0,1,0), CanvasSize = UDim2.new(0,0,0,0), ScrollBarThickness = 6, BackgroundTransparency = 1, Parent = self._base.Content})
        frame.Visible = false

        btn.MouseButton1Click:Connect(function()
            -- hide others
            for _,t in pairs(self._base.Content:GetChildren()) do
                if t:IsA("ScrollingFrame") then t.Visible = false end
            end
            frame.Visible = true
        end)

        tab._base = {Button = btn, Frame = frame}

        function tab:AddSection(name)
            local section = setmetatable({}, SectionClass)
            section.Lib = self.Lib
            section.Tab = self
            section.Name = name or "Section"

            local container = new("Frame", {Size = UDim2.new(1,-20,0,0), Position = UDim2.new(0,10,0,0), BackgroundTransparency = 1, Parent = frame})
            applyUICorner(container, UDim.new(0,6))

            -- dynamic layout
            local uiList = new("UIListLayout", {Parent = container, Padding = UDim.new(0,8)})

            function section:AddButton(opts)
                opts = opts or {}
                local btn = new("TextButton", {Text = opts.Name or "Button", Size = UDim2.new(1,0,0,40), BackgroundColor3 = self.Lib.Theme.Accent, TextColor3 = Color3.new(1,1,1), Parent = container})
                applyUICorner(btn, UDim.new(0,6))
                btn.MouseButton1Click:Connect(function() if type(opts.Callback)=="function" then pcall(opts.Callback) end end)
                return btn
            end

            function section:AddToggle(opts)
                opts = opts or {}
                local containerToggle = new("Frame", {Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1, Parent = container})
                local lbl = new("TextLabel", {Text = opts.Name or "Toggle", Size = UDim2.new(0.8,0,1,0), BackgroundTransparency = 1, TextColor3 = self.Lib.Theme.TextColor, Parent = containerToggle})
                local btn = new("TextButton", {Text = opts.Default and "On" or "Off", Size = UDim2.new(0.18,0,0.8,0), Position = UDim2.new(0.82,0,0.1,0), BackgroundColor3 = opts.Default and Color3.fromRGB(0,180,0) or Color3.fromRGB(180,0,0), Parent = containerToggle})
                applyUICorner(btn, UDim.new(0,6))
                local state = opts.Default or false
                btn.MouseButton1Click:Connect(function()
                    state = not state
                    btn.Text = state and "On" or "Off"
                    btn.BackgroundColor3 = state and Color3.fromRGB(0,180,0) or Color3.fromRGB(180,0,0)
                    if type(opts.Callback)=="function" then pcall(opts.Callback, state) end
                end)
                return {Set = function(v) state = v; btn.Text = state and "On" or "Off"; btn.BackgroundColor3 = state and Color3.fromRGB(0,180,0) or Color3.fromRGB(180,0,0) end}
            end

            function section:AddSlider(opts)
                opts = opts or {}
                local minv = opts.Min or 0
                local maxv = opts.Max or 100
                local inc = opts.Increment or 1
                local default = opts.Default or minv

                local frameS = new("Frame", {Size = UDim2.new(1,0,0,60), BackgroundTransparency = 1, Parent = container})
                local nameLbl = new("TextLabel", {Text = opts.Name or "Slider", Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1, TextColor3 = self.Lib.Theme.TextColor, Parent = frameS})
                local barBg = new("Frame", {Size = UDim2.new(1,0,0,12), Position = UDim2.new(0,0,0,24), BackgroundColor3 = Color3.fromRGB(50,50,50), Parent = frameS})
                applyUICorner(barBg, UDim.new(0,6))
                local barFill = new("Frame", {Size = UDim2.new((default-minv)/(maxv-minv),0,1,0), BackgroundColor3 = self.Lib.Theme.Accent, Parent = barBg})
                applyUICorner(barFill, UDim.new(0,6))

                local valueLbl = new("TextLabel", {Text = tostring(default) .. (opts.ValueName and (" "..opts.ValueName) or ""), Size = UDim2.new(1,0,0,14), Position = UDim2.new(0,0,0,38), BackgroundTransparency = 1, TextColor3 = self.Lib.Theme.TextColor, Font=Enum.Font.Gotham, TextSize=14, Parent = frameS})

                local dragging = false
                barBg.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
                end)
                barBg.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                        local rel = math.clamp((input.Position.X - barBg.AbsolutePosition.X)/barBg.AbsoluteSize.X, 0, 1)
                        local rawVal = minv + rel * (maxv - minv)
                        local stepped = math.floor(rawVal / inc + 0.5) * inc
                        barFill.Size = UDim2.new((stepped-minv)/(maxv-minv),0,1,0)
                        valueLbl.Text = tostring(stepped) .. (opts.ValueName and (" "..opts.ValueName) or "")
                        if type(opts.Callback)=="function" then pcall(opts.Callback, stepped) end
                    end
                end)

                return {Set = function(v) local rel = math.clamp((v-minv)/(maxv-minv),0,1); barFill.Size = UDim2.new(rel,0,1,0); valueLbl.Text = tostring(v) end}
            end

            function section:AddColorpicker(opts)
                opts = opts or {}
                local default = opts.Default or Color3.new(1,0,0)
                local frameC = new("Frame", {Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1, Parent = container})
                local lbl = new("TextLabel", {Text = opts.Name or "Color", Size = UDim2.new(0.6,0,1,0), BackgroundTransparency = 1, TextColor3 = self.Lib.Theme.TextColor, Parent = frameC})
                local preview = new("Frame", {Size = UDim2.new(0.28,0,0.8,0), Position = UDim2.new(0.70,0,0.1,0), BackgroundColor3 = default, Parent = frameC})
                applyUICorner(preview, UDim.new(0,6))
                -- clicking opens a simple palette
                preview.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 then
                        -- create small palette
                        local gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
                        local box = new("Frame", {Size = UDim2.new(0,220,0,160), Position = UDim2.new(0.5,-110,0.5,-80), BackgroundColor3 = self.Lib.Theme.Main, Parent = gui})
                        applyUICorner(box)
                        local colors = {Color3.fromRGB(255,0,0), Color3.fromRGB(0,255,0), Color3.fromRGB(0,0,255), Color3.fromRGB(255,255,0), Color3.fromRGB(255,0,255), Color3.fromRGB(0,255,255), Color3.fromRGB(255,255,255), Color3.fromRGB(0,0,0)}
                        for i,c in ipairs(colors) do
                            local btn = new("TextButton", {Size = UDim2.new(0,40,0,40), Position = UDim2.new(0,10 + (i-1)%4 * 50, 0, 10 + math.floor((i-1)/4) * 50), BackgroundColor3 = c, Parent = box})
                            btn.MouseButton1Click:Connect(function()
                                preview.BackgroundColor3 = c
                                if type(opts.Callback)=="function" then pcall(opts.Callback, c) end
                                gui:Destroy()
                            end)
                        end
                        local close = new("TextButton", {Text = "اغلاق", Size = UDim2.new(0,60,0,26), Position = UDim2.new(0.5,-30,1,-36), Parent = box})
                        applyUICorner(close)
                        close.MouseButton1Click:Connect(function() gui:Destroy() end)
                    end
                end)
                return {Set = function(c) preview.BackgroundColor3 = c end}
            end

            function section:AddLabel(text)
                local lbl = new("TextLabel", {Text = text or "Label", Size = UDim2.new(1,0,0,22), BackgroundTransparency = 1, TextColor3 = self.Lib.Theme.TextColor, Parent = container})
                return {Set = function(t) lbl.Text = t end}
            end

            function section:AddImageLabel(opts)
                opts = opts or {}
                local frameI = new("Frame", {Size = UDim2.new(1,0,0,80), BackgroundTransparency = 1, Parent = container})
                local img = new("ImageLabel", {Size = UDim2.new(0,80,0,80), BackgroundTransparency = 1, Image = self.Lib:GetIcon(opts.Image or DEFAULT_ICON), Parent = frameI})
                local lbl = new("TextLabel", {Text = opts.Name or "Image", Size = UDim2.new(1,0,0,22), Position = UDim2.new(0,90,0,0), BackgroundTransparency = 1, TextColor3 = self.Lib.Theme.TextColor, Parent = frameI})
                return {Set = function(n) lbl.Text = n end}
            end

            function section:AddDiscordInvite(opts)
                opts = opts or {}
                local frameD = new("Frame", {Size = UDim2.new(1,0,0,50), BackgroundTransparency = 1, Parent = container})
                local logo = new("ImageLabel", {Size = UDim2.new(0,40,0,40), BackgroundTransparency = 1, Image = self.Lib:GetIcon(opts.Logo or DEFAULT_ICON), Parent = frameD})
                local lbl = new("TextLabel", {Text = opts.Name or "Discord", Size = UDim2.new(1,0,0,20), Position = UDim2.new(0,50,0,0), BackgroundTransparency = 1, TextColor3 = self.Lib.Theme.TextColor, Parent = frameD})
                local btn = new("TextButton", {Text = "Join", Size = UDim2.new(0,70,0,26), Position = UDim2.new(1,-80,0,12), Parent = frameD})
                applyUICorner(btn)
                btn.MouseButton1Click:Connect(function()
                    pcall(function()
                        -- try to open discord link (not guaranteed inside Roblox)
                        local invite = opts.Invite or ""
                        if invite ~= "" and setclipboard then setclipboard(invite) end
                    end)
                end)
                return {Set = function(n) lbl.Text = n end}
            end

            function section:AddParagraph(title, content)
                local tit = new("TextLabel", {Text = title or "Paragraph", Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1, TextColor3 = self.Lib.Theme.TextColor, Font = Enum.Font.GothamBold, Parent = container})
                local cont = new("TextLabel", {Text = content or "Content", Size = UDim2.new(1,0,0,60), BackgroundTransparency = 1, TextColor3 = self.Lib.Theme.TextColor, TextWrapped = true, Parent = container})
                return {Set = function(t,c) tit.Text = t; cont.Text = c end}
            end

            function section:AddTextbox(opts)
                opts = opts or {}
                local frameT = new("Frame", {Size = UDim2.new(1,0,0,60), BackgroundTransparency = 1, Parent = container})
                local name = new("TextLabel", {Text = opts.Name or "Input", Size = UDim2.new(1,0,0,18), BackgroundTransparency = 1, TextColor3 = self.Lib.Theme.TextColor, Parent = frameT})
                local box = new("TextBox", {Text = opts.Default or "", Size = UDim2.new(1,-10,0,30), Position = UDim2.new(0,5,0,24), BackgroundColor3 = Color3.fromRGB(50,50,50), TextColor3 = self.Lib.Theme.TextColor, Parent = frameT})
                applyUICorner(box)
                box.FocusLost:Connect(function(enter)
                    if type(opts.Callback) == "function" then pcall(opts.Callback, box.Text) end
                    if opts.TextDisappear then box.Text = "" end
                end)
                return {Set = function(v) box.Text = v end}
            end

            function section:AddBind(opts)
                opts = opts or {}
                local frameB = new("Frame", {Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1, Parent = container})
                local name = new("TextLabel", {Text = opts.Name or "Bind", Size = UDim2.new(0.6,0,1,0), BackgroundTransparency = 1, TextColor3 = self.Lib.Theme.TextColor, Parent = frameB})
                local keyBtn = new("TextButton", {Text = tostring(opts.Default or Enum.KeyCode.E), Size = UDim2.new(0.38,0,0.8,0), Position = UDim2.new(0.62,0,0.1,0), Parent = frameB})
                applyUICorner(keyBtn)
                local current = opts.Default or Enum.KeyCode.E
                keyBtn.MouseButton1Click:Connect(function()
                    keyBtn.Text = "Press Key..."
                    local conn
                    conn = UserInputService.InputBegan:Connect(function(inp,gp)
                        if not gp and inp.KeyCode then
                            current = inp.KeyCode
                            keyBtn.Text = tostring(current)
                            pcall(function() if type(opts.Callback)=="function" then opts.Callback() end end)
                            conn:Disconnect()
                        end
                    end)
                end)
                -- listen for bind
                UserInputService.InputBegan:Connect(function(inp,gp)
                    if not gp and inp.KeyCode == current then
                        if type(opts.Callback) == "function" then pcall(opts.Callback) end
                    end
                end)
                return {Set = function(k) current = k; keyBtn.Text = tostring(k) end}
            end

            function section:AddDropdown(opts)
                opts = opts or {}
                local frameD = new("Frame", {Size = UDim2.new(1,0,0,40), BackgroundTransparency = 1, Parent = container})
                local name = new("TextLabel", {Text = opts.Name or "Dropdown", Size = UDim2.new(0.6,0,1,0), BackgroundTransparency = 1, TextColor3 = self.Lib.Theme.TextColor, Parent = frameD})
                local cur = opts.Default or (opts.Options and opts.Options[1]) or ""
                local btn = new("TextButton", {Text = tostring(cur), Size = UDim2.new(0.38,0,0.8,0), Position = UDim2.new(0.62,0,0.1,0), Parent = frameD})
                applyUICorner(btn)
                local menu
                btn.MouseButton1Click:Connect(function()
                    if menu and menu.Parent then menu:Destroy(); menu = nil; return end
                    menu = new("Frame", {Size = UDim2.new(0,200,0,150), Position = UDim2.new(0,0,0,0), BackgroundColor3 = self.Lib.Theme.Main, Parent = game:GetService("CoreGui")})
                    applyUICorner(menu)
                    local y=10
                    for i,optv in ipairs(opts.Options or {}) do
                        local item = new("TextButton", {Text = tostring(optv), Size = UDim2.new(1,-20,0,28), Position = UDim2.new(0,10,0,y), BackgroundTransparency = 0, TextColor3 = self.Lib.Theme.TextColor, Parent = menu})
                        y = y + 34
                        applyUICorner(item)
                        item.MouseButton1Click:Connect(function()
                            btn.Text = tostring(optv)
                            if type(opts.Callback) == "function" then pcall(opts.Callback, optv) end
                            menu:Destroy(); menu = nil
                        end)
                    end
                end)
                return {Refresh = function(list, multi) opts.Options = list; end, Select = function(v) btn.Text = v end, Set = function(v) btn.Text = v end}
            end

            -- finalize
            table.insert(self.Sections, section)
            return section
        end

        table.insert(self.Tabs, tab)
        return tab
    end

    -- expose dialog from window
    function wobj:Dialog(cfg) self.Lib:Dialog(cfg) end

    table.insert(self.Lib.Windows, wobj)
    return wobj
end

-- Return library factory
return function()
    return ArabLib.new()
end
