-- ArabLib (مكتبة يوسف)
local ArabLib = {}
ArabLib.__index = ArabLib

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- الألوان الافتراضية
ArabLib.Theme = {
    Background = Color3.fromRGB(25,25,25),
    Tab = Color3.fromRGB(35,35,35),
    Button = Color3.fromRGB(50,50,50),
    ToggleOn = Color3.fromRGB(0, 200, 0),
    ToggleOff = Color3.fromRGB(200, 0, 0),
    Text = Color3.fromRGB(255,255,255)
}

-- إنشاء نافذة
function ArabLib:CreateWindow(title)
    local ScreenGui = Instance.new("ScreenGui", game:GetService("CoreGui"))

    local Frame = Instance.new("Frame")
    Frame.Size = UDim2.new(0, 500, 0, 350)
    Frame.Position = UDim2.new(0.3, 0, 0.3, 0)
    Frame.BackgroundColor3 = self.Theme.Background
    Frame.Active = true
    Frame.Draggable = true
    Frame.Parent = ScreenGui

    local Title = Instance.new("TextLabel")
    Title.Text = title
    Title.Size = UDim2.new(1, 0, 0, 40)
    Title.BackgroundColor3 = self.Theme.Tab
    Title.TextColor3 = self.Theme.Text
    Title.Font = Enum.Font.SourceSansBold
    Title.TextSize = 20
    Title.Parent = Frame

    local TabsFolder = Instance.new("Folder", Frame)
    TabsFolder.Name = "Tabs"

    return Frame, TabsFolder
end

-- إضافة Tab
function ArabLib:AddTab(window, name)
    local TabButton = Instance.new("TextButton")
    TabButton.Text = name
    TabButton.Size = UDim2.new(0, 100, 0, 30)
    TabButton.BackgroundColor3 = self.Theme.Button
    TabButton.TextColor3 = self.Theme.Text
    TabButton.Parent = window.Tabs

    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1, -120, 1, -50)
    Content.Position = UDim2.new(0, 110, 0, 50)
    Content.BackgroundTransparency = 1
    Content.Visible = false
    Content.Parent = window

    TabButton.MouseButton1Click:Connect(function()
        for _, tab in pairs(window.Tabs:GetChildren()) do
            if tab:IsA("TextButton") then
                tab.BackgroundColor3 = self.Theme.Button
            end
        end
        for _, c in pairs(window:GetChildren()) do
            if c:IsA("Frame") and c ~= Content then
                c.Visible = false
            end
        end
        TabButton.BackgroundColor3 = Color3.fromRGB(100,100,100)
        Content.Visible = true
    end)

    return Content
end

-- إضافة زر
function ArabLib:AddButton(parent, text, callback)
    local Button = Instance.new("TextButton")
    Button.Text = text
    Button.Size = UDim2.new(0, 200, 0, 40)
    Button.Position = UDim2.new(0, 10, 0, #parent:GetChildren()*45)
    Button.BackgroundColor3 = self.Theme.Button
    Button.TextColor3 = self.Theme.Text
    Button.Parent = parent

    Button.MouseButton1Click:Connect(function()
        callback()
    end)
end

-- إضافة Toggle
function ArabLib:AddToggle(parent, text, default, callback)
    local Toggle = Instance.new("TextButton")
    Toggle.Text = text .. " : " .. (default and "تشغيل" or "إيقاف")
    Toggle.Size = UDim2.new(0, 220, 0, 40)
    Toggle.Position = UDim2.new(0, 10, 0, #parent:GetChildren()*45)
    Toggle.BackgroundColor3 = default and self.Theme.ToggleOn or self.Theme.ToggleOff
    Toggle.TextColor3 = self.Theme.Text
    Toggle.Parent = parent

    local state = default
    Toggle.MouseButton1Click:Connect(function()
        state = not state
        Toggle.Text = text .. " : " .. (state and "تشغيل" or "إيقاف")
        Toggle.BackgroundColor3 = state and self.Theme.ToggleOn or self.Theme.ToggleOff
        callback(state)
    end)
end

-- إشعار
function ArabLib:MakeNotification(text)
    local Notify = Instance.new("TextLabel")
    Notify.Text = text
    Notify.Size = UDim2.new(0, 200, 0, 40)
    Notify.Position = UDim2.new(0.5, -100, 0, 20)
    Notify.BackgroundColor3 = self.Theme.Tab
    Notify.TextColor3 = self.Theme.Text
    Notify.Parent = game.CoreGui

    game:GetService("TweenService"):Create(
        Notify,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {BackgroundTransparency = 0}
    ):Play()

    task.delay(3, function()
        Notify:Destroy()
    end)
end

-- تغيير الثيم
function ArabLib:SetTheme(colors)
    for k,v in pairs(colors) do
        if self.Theme[k] then
            self.Theme[k] = v
        end
    end
end

return ArabLib
