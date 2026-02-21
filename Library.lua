local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local Library = {}

--================ DEFAULT SETTINGS =================--

local Default = {
    Title = "UI Window",
    Size = UDim2.fromOffset(700, 500),
    CornerRadius = 12,
    AnimationSpeed = 0.2,
    Draggable = true,
    Resizable = true,
    Keybind = Enum.KeyCode.RightShift,
    Modern = true,
    TweenStyle = Enum.EasingStyle.Quad,
    TweenDirection = Enum.EasingDirection.Out,
    Resize = {
        MinSize = Vector2.new(500, 350),
        MaxSize = Vector2.new(1200, 900)
    },
    Appearance = {
        Blur = false
    },
    Font = Enum.Font.Gotham,
    TextSize = 14,
    Colors = {
        Background = Color3.fromRGB(18,18,18),
        Topbar = Color3.fromRGB(24,24,24),
        Tab = Color3.fromRGB(32,32,32),
        TabActive = Color3.fromRGB(45,45,45),
        Element = Color3.fromRGB(32,32,32),
        ElementHover = Color3.fromRGB(45,45,45),
        Accent = Color3.fromRGB(0,170,255),
        Text = Color3.fromRGB(235,235,235),
        SubText = Color3.fromRGB(170,170,170),
        Error = Color3.fromRGB(255,100,100),
        Warn = Color3.fromRGB(255,170,0),
        Info = Color3.fromRGB(0,200,255)
    }
}

--======== UTILS (DeepCopy & Merge) ========

local function DeepCopy(tbl)
    local t = {}
    for k,v in pairs(tbl) do
        t[k] = typeof(v) == "table" and DeepCopy(v) or v
    end
    return t
end

local function Merge(default, custom)
    for k,v in pairs(custom or {}) do
        if typeof(v) == "table" and typeof(default[k]) == "table" then
            Merge(default[k], v)
        else
            default[k] = v
        end
    end
end

local function Corner(obj, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0,r)
    c.Parent = obj
end

--================ CREATE WINDOW ===================

function Library:CreateWindow(options)
    local Settings = DeepCopy(Default)
    Merge(Settings, options)

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Parent = PlayerGui

    if Settings.Appearance.Blur then
        local blur = Instance.new("BlurEffect")
        blur.Size = 12
        blur.Parent = Lighting
    end

    local Main = Instance.new("Frame")
    Main.Size = Settings.Size
    Main.Position = UDim2.fromScale(.5,.5)
    Main.AnchorPoint = Vector2.new(.5,.5)
    Main.BackgroundColor3 = Settings.Colors.Background
    Main.Parent = ScreenGui
    Corner(Main, Settings.CornerRadius)

    -- Topbar
    local Top = Instance.new("Frame")
    Top.Size = UDim2.new(1,0,0,40)
    Top.BackgroundColor3 = Settings.Colors.Topbar
    Top.Parent = Main
    Corner(Top, Settings.CornerRadius)

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.fromScale(1,1)
    Title.BackgroundTransparency = 1
    Title.Text = Settings.Title
    Title.TextColor3 = Settings.Colors.Text
    Title.Font = Settings.Font
    Title.TextSize = Settings.TextSize+2
    Title.Parent = Top

    -- Visible Toggle (Keybind)
    local Visible = true
    local function SetVisible(state)
        Visible = state
        if Settings.Modern then
            if state then
                Main.Visible = true
                Main.BackgroundTransparency = 1
                TweenService:Create(Main, TweenInfo.new(
                    Settings.AnimationSpeed, Settings.TweenStyle, Settings.TweenDirection
                ), { BackgroundTransparency = 0 }):Play()
            else
                local tween = TweenService:Create(Main, TweenInfo.new(
                    Settings.AnimationSpeed, Settings.TweenStyle, Settings.TweenDirection
                ), { BackgroundTransparency = 1 })
                tween:Play()
                tween.Completed:Wait()
                Main.Visible = false
            end
        else
            Main.Visible = state
        end
    end

    if Settings.Keybind then
        UIS.InputBegan:Connect(function(input,gp)
            if gp then return end
            if input.KeyCode == Settings.Keybind then
                SetVisible(not Visible)
            end
        end)
    end

    local Window = {}
    function Window:ToggleGUI()
        SetVisible(not Visible)
    end
    function Window:SetVisible(state)
        SetVisible(state)
    end

    -- DRAGGABLE
    if Settings.Draggable then
        local dragging = false
        local dragStart
        local startPos
        Top.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = Main.Position
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                Main.Position = startPos + UDim2.fromOffset(delta.X, delta.Y)
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = false
            end
        end)
    end

    -- RESIZE
    if Settings.Resizable then
        local Handle = Instance.new("Frame")
        Handle.Size = UDim2.fromOffset(16,16)
        Handle.Position = UDim2.new(1,-16,1,-16)
        Handle.BackgroundColor3 = Settings.Colors.Element
        Handle.Parent = Main
        Corner(Handle,4)

        local resizing = false
        local resizeStart
        local startSize

        Handle.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = true
                resizeStart = input.Position
                startSize = Main.Size
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if resizing and input.UserInputType == Enum.UserInputType.MouseMovement then
                local delta = input.Position - resizeStart
                local newX = math.clamp(
                    startSize.X.Offset + delta.X,
                    Settings.Resize.MinSize.X,
                    Settings.Resize.MaxSize.X
                )
                local newY = math.clamp(
                    startSize.Y.Offset + delta.Y,
                    Settings.Resize.MinSize.Y,
                    Settings.Resize.MaxSize.Y
                )
                Main.Size = UDim2.fromOffset(newX,newY)
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                resizing = false
            end
        end)
    end

    -- TABS
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1,0,0,35)
    TabBar.Position = UDim2.new(0,0,0,40)
    TabBar.BackgroundTransparency = 1
    TabBar.Parent = Main

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.Padding = UDim.new(0,5)
    TabLayout.Parent = TabBar

    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1,-10,1,-85)
    Content.Position = UDim2.new(0,5,0,75)
    Content.BackgroundTransparency = 1
    Content.Parent = Main

    local CurrentTab

    function Window:CreateTab(name)
        local Button = Instance.new("TextButton")
        Button.Size = UDim2.new(0,120,1,0)
        Button.Text = name
        Button.Font = Settings.Font
        Button.TextSize = Settings.TextSize
        Button.TextColor3 = Settings.Colors.Text
        Button.BackgroundColor3 = Settings.Colors.Tab
        Button.Parent = TabBar
        Corner(Button,6)

        local Scroll = Instance.new("ScrollingFrame")
        Scroll.Size = UDim2.fromScale(1,1)
        Scroll.CanvasSize = UDim2.new(0,0,0,0)
        Scroll.ScrollBarImageTransparency = .6
        Scroll.Visible = false
        Scroll.Parent = Content
        Scroll.BackgroundTransparency = 1

        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0,6)
        Layout.Parent = Scroll
        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Scroll.CanvasSize = UDim2.new(0,0,0,Layout.AbsoluteContentSize.Y+10)
        end)

        local function Switch()
            if CurrentTab then CurrentTab.Visible = false end
            Scroll.Visible = true
            CurrentTab = Scroll
        end
        Button.MouseButton1Click:Connect(Switch)

        if not CurrentTab then
            Switch()
        end

        local Tab = {}

        local function BaseFrame(height)
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1,-5,0,height or 40)
            Frame.BackgroundColor3 = Settings.Colors.Element
            Frame.Parent = Scroll
            Corner(Frame,6)
            return Frame
        end

        -- ================= BUTTON =================
        function Tab:CreateButton(text, callback)
            local element = {}

            local Frame = BaseFrame()
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.fromScale(1,1)
            Btn.BackgroundTransparency = 1
            Btn.Text = text
            Btn.Font = Settings.Font
            Btn.TextSize = Settings.TextSize
            Btn.TextColor3 = Settings.Colors.Text
            Btn.Parent = Frame

            Btn.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)

            function element:SetText(newText)
                Btn.Text = newText
            end

            function element:Remove()
                Frame:Destroy()
            end

            return element
        end

        -- ================= TOGGLE =================
        function Tab:CreateToggle(text, default, callback)
            local element = {}
            local state = default

            local Frame = BaseFrame()
            Frame.BackgroundColor3 = state and Settings.Colors.Accent or Settings.Colors.Element

            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1,0,1,0)
            Btn.BackgroundTransparency = 1
            Btn.Text = text
            Btn.TextColor3 = Settings.Colors.Text
            Btn.Font = Settings.Font
            Btn.TextSize = Settings.TextSize
            Btn.Parent = Frame

            local function Update(val)
                state = val
                Frame.BackgroundColor3 = state and Settings.Colors.Accent or Settings.Colors.Element
                if callback then callback(state) end
            end

            Btn.MouseButton1Click:Connect(function()
                Update(not state)
            end)

            function element:Set(val)
                Update(val)
            end

            function element:Get()
                return state
            end

            function element:Remove()
                Frame:Destroy()
            end

            return element
        end

        -- ================= SLIDER =================
        function Tab:CreateSlider(text, min, max, default, callback)
            local element = {}
            local value = default or min

            local Frame = BaseFrame(55)
            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1,0,0.5,0)
            Label.BackgroundTransparency = 1
            Label.Text = text.." : "..value
            Label.TextColor3 = Settings.Colors.Text
            Label.Font = Settings.Font
            Label.TextSize = Settings.TextSize
            Label.Parent = Frame

            local Bar = Instance.new("Frame")
            Bar.Size = UDim2.new(1,-20,0,6)
            Bar.Position = UDim2.new(0,10,0.7,0)
            Bar.BackgroundColor3 = Settings.Colors.ElementHover
            Bar.Parent = Frame
            Corner(Bar,6)

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((value-min)/(max-min),0,1,0)
            Fill.BackgroundColor3 = Settings.Colors.Accent
            Fill.Parent = Bar
            Corner(Fill,6)

            local connection
            Bar.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 then
                    connection = UIS.InputChanged:Connect(function(i)
                        if i.UserInputType == Enum.UserInputType.MouseMovement then
                            local percent = math.clamp(
                                (i.Position.X - Bar.AbsolutePosition.X)/Bar.AbsoluteSize.X,
                                0,1
                            )
                            value = math.floor(min + (max-min)*percent)
                            Fill.Size = UDim2.new(percent,0,1,0)
                            Label.Text = text.." : "..value
                            if callback then callback(value) end
                        end
                    end)
                end
            end)
            Bar.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 and connection then
                    connection:Disconnect()
                end
            end)

            function element:Set(val)
                value = math.clamp(val, min, max)
                local percent = (value - min)/(max - min)
                Fill.Size = UDim2.new(percent,0,1,0)
                Label.Text = text.." : "..value
            end

            function element:Get()
                return value
            end

            function element:Remove()
                Frame:Destroy()
            end

            return element
        end

        -- ================= TEXTBOX =================
        function Tab:CreateTextbox(text, callback)
            local element = {}

            local Frame = BaseFrame()
            local Box = Instance.new("TextBox")
            Box.Size = UDim2.fromScale(1,1)
            Box.BackgroundTransparency = 1
            Box.PlaceholderText = text
            Box.TextColor3 = Settings.Colors.Text
            Box.Font = Settings.Font
            Box.TextSize = Settings.TextSize
            Box.Parent = Frame

            Box.FocusLost:Connect(function()
                if callback then callback(Box.Text) end
            end)

            function element:SetText(val)
                Box.Text = val
            end

            function element:Get()
                return Box.Text
            end

            function element:Remove()
                Frame:Destroy()
            end

            return element
        end

        -- ================= DROPDOWN =================
        function Tab:CreateDropdown(text, items, returnIndex, callback)
            local element = {}

            local open = false
            local currentItems = items or {}
            local selectedIndex = 1
            local selectedValue = currentItems[1]

            local Frame = BaseFrame()
            local TitleLabel = Instance.new("TextLabel")
            TitleLabel.Size = UDim2.new(1,-10,0,20)
            TitleLabel.Position = UDim2.new(0,5,0,0)
            TitleLabel.BackgroundTransparency = 1
            TitleLabel.Text = text.." : "..tostring(selectedValue)
            TitleLabel.TextColor3 = Settings.Colors.Text
            TitleLabel.Font = Settings.Font
            TitleLabel.TextSize = Settings.TextSize
            TitleLabel.Parent = Frame

            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1,-10,0,20)
            Btn.Position = UDim2.new(0,5,0,20)
            Btn.BackgroundColor3 = Settings.Colors.ElementHover
            Btn.Text = "▼"
            Btn.TextColor3 = Settings.Colors.Text
            Btn.Font = Settings.Font
            Btn.TextSize = Settings.TextSize
            Btn.Parent = Frame
            Corner(Btn,4)

            local List = Instance.new("Frame")
            List.Position = UDim2.new(0,5,0,40)
            List.BackgroundColor3 = Settings.Colors.Element
            List.Visible = false
            List.Parent = Frame
            Corner(List,4)

            local function rebuild()
                List:ClearAllChildren()
                List.Size = UDim2.new(1,-10,0,#currentItems * 30)
                for i,v in ipairs(currentItems) do
                    local opt = Instance.new("TextButton")
                    opt.Size = UDim2.new(1,0,0,30)
                    opt.Position = UDim2.new(0,0,0,(i-1)*30)
                    opt.BackgroundColor3 = Settings.Colors.ElementHover
                    opt.Text = tostring(v)
                    opt.TextColor3 = Settings.Colors.Text
                    opt.Font = Settings.Font
                    opt.TextSize = Settings.TextSize
                    opt.Parent = List

                    opt.MouseButton1Click:Connect(function()
                        selectedIndex = i
                        selectedValue = v
                        TitleLabel.Text = text.." : "..tostring(v)
                        List.Visible = false
                        open = false
                        if callback then
                            if returnIndex then
                                callback(selectedIndex)
                            else
                                callback(selectedValue)
                            end
                        end
                    end)
                end
            end

            rebuild()

            Btn.MouseButton1Click:Connect(function()
                open = not open
                List.Visible = open
            end)

            function element:SetItems(newItems)
                currentItems = newItems or {}
                selectedIndex = 1
                selectedValue = currentItems[1]
                TitleLabel.Text = text.." : "..tostring(selectedValue)
                rebuild()
            end

            function element:SetText(newText)
                text = newText
                TitleLabel.Text = text.." : "..tostring(selectedValue)
            end

            function element:Set(val)
                for i,v in ipairs(currentItems) do
                    if v == val or i == val then
                        selectedIndex = i
                        selectedValue = v
                        TitleLabel.Text = text.." : "..tostring(v)
                        break
                    end
                end
            end

            function element:Get()
                if returnIndex then
                    return selectedIndex
                else
                    return selectedValue
                end
            end

            function element:Remove()
                Frame:Destroy()
            end

            return element
        end

        return Tab
    end

    return Window
end

return Library
