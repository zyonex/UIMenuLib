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
    Resize = { MinSize = Vector2.new(500, 350), MaxSize = Vector2.new(1200, 900) },
    Appearance = { Blur = false },
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
    local CloseCallbacks = {}
    local OpenCallbacks = {}

    local function SetVisible(state)
        Visible = state
        if Settings.Modern then
            if state then
                Main.Visible = true
                Main.BackgroundTransparency = 1
                TweenService:Create(Main, TweenInfo.new(
                    Settings.AnimationSpeed, Settings.TweenStyle, Settings.TweenDirection
                ), { BackgroundTransparency = 0 }):Play()
                -- Fire open callbacks
                for _, cb in ipairs(OpenCallbacks) do
                    pcall(cb)
                end
            else
                local tween = TweenService:Create(Main, TweenInfo.new(
                    Settings.AnimationSpeed, Settings.TweenStyle, Settings.TweenDirection
                ), { BackgroundTransparency = 1 })
                tween:Play()
                tween.Completed:Wait()
                Main.Visible = false
                -- Fire close callbacks
                for _, cb in ipairs(CloseCallbacks) do
                    pcall(cb)
                end
            end
        else
            Main.Visible = state
            if state then
                for _, cb in ipairs(OpenCallbacks) do pcall(cb) end
            else
                for _, cb in ipairs(CloseCallbacks) do pcall(cb) end
            end
        end
    end

    if Settings.Keybind then
        UIS.InputBegan:Connect(function(input,gp)
            if gp then return end
            if input.KeyCode == Settings.Keybind then SetVisible(not Visible) end
        end)
    end

    local Window = {}
    function Window:ToggleGUI() SetVisible(not Visible) end
    function Window:SetVisible(state) SetVisible(state) end
    function Window:OnClose(cb) if typeof(cb)=="function" then table.insert(CloseCallbacks,cb) end end
    function Window:OnOpen(cb) if typeof(cb)=="function" then table.insert(OpenCallbacks,cb) end end
    function Window:SetTitle(txt) Title.Text = txt end
    function Window:Destroy() ScreenGui:Destroy() end

    -- DRAGGABLE
    if Settings.Draggable then
        local dragging = false
        local dragStart
        local startPos
        Top.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then
                dragging = true
                dragStart = input.Position
                startPos = Main.Position
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if dragging and input.UserInputType==Enum.UserInputType.MouseMovement then
                local delta = input.Position - dragStart
                Main.Position = startPos + UDim2.fromOffset(delta.X, delta.Y)
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then dragging=false end
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
        local resizing=false
        local resizeStart
        local startSize
        Handle.InputBegan:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then
                resizing=true
                resizeStart=input.Position
                startSize=Main.Size
            end
        end)
        UIS.InputChanged:Connect(function(input)
            if resizing and input.UserInputType==Enum.UserInputType.MouseMovement then
                local delta = input.Position - resizeStart
                local newX = math.clamp(startSize.X.Offset+delta.X, Settings.Resize.MinSize.X, Settings.Resize.MaxSize.X)
                local newY = math.clamp(startSize.Y.Offset+delta.Y, Settings.Resize.MinSize.Y, Settings.Resize.MaxSize.Y)
                Main.Size = UDim2.fromOffset(newX,newY)
            end
        end)
        UIS.InputEnded:Connect(function(input)
            if input.UserInputType==Enum.UserInputType.MouseButton1 then resizing=false end
        end)
    end

    -- TABS
    local TabBar = Instance.new("Frame")
    TabBar.Size = UDim2.new(1,0,0,35)
    TabBar.Position = UDim2.new(0,0,0,40)
    TabBar.BackgroundTransparency=1
    TabBar.Parent=Main

    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.Padding = UDim.new(0,5)
    TabLayout.Parent = TabBar

    local Content = Instance.new("Frame")
    Content.Size = UDim2.new(1,-10,1,-85)
    Content.Position = UDim2.new(0,5,0,75)
    Content.BackgroundTransparency=1
    Content.Parent=Main

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
        Scroll.BackgroundTransparency=1

        local Layout = Instance.new("UIListLayout")
        Layout.Padding = UDim.new(0,6)
        Layout.Parent = Scroll
        Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Scroll.CanvasSize = UDim2.new(0,0,0,Layout.AbsoluteContentSize.Y+10)
        end)

        local function Switch()
            if CurrentTab then CurrentTab.Visible = false end
            Scroll.Visible=true
            CurrentTab = Scroll
        end
        Button.MouseButton1Click:Connect(Switch)
        if not CurrentTab then Switch() end

        local Tab = {}
        local Elements = {}

        -- SEARCH BAR
        local SearchBarFrame = Instance.new("Frame")
        SearchBarFrame.Size = UDim2.new(1,0,0,40)
        SearchBarFrame.BackgroundTransparency=1
        SearchBarFrame.Parent=Scroll

        local SearchBox = Instance.new("TextBox")
        SearchBox.Size=UDim2.new(1,0,1,0)
        SearchBox.PlaceholderText="Search..."
        SearchBox.Text=""
        SearchBox.Font=Settings.Font
        SearchBox.TextSize=Settings.TextSize
        SearchBox.TextColor3=Settings.Colors.Text
        SearchBox.BackgroundColor3=Settings.Colors.Element
        SearchBox.Parent=SearchBarFrame
        Corner(SearchBox,6)

        local function UpdateSearch()
            local query = string.lower(SearchBox.Text)
            for _,el in ipairs(Elements) do
                local text = el._label and string.lower(el._label.Text) or ""
                if query=="" or string.find(text, query) then
                    if el._frame then el._frame.Visible=true end
                else
                    if el._frame then el._frame.Visible=false end
                end
            end
        end

        SearchBox:GetPropertyChangedSignal("Text"):Connect(UpdateSearch)

        -- ELEMENT BASE
        local function BaseFrame(height)
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1,-5,0,height or 40)
            Frame.BackgroundColor3 = Settings.Colors.Element
            Frame.Parent = Scroll
            Corner(Frame,6)
            return Frame
        end

        -- ================= BUTTON =================
        function Tab:CreateButton(text,callback)
            local element = {}
            local Frame = BaseFrame()
            local Btn = Instance.new("TextButton")
            Btn.Size=UDim2.fromScale(1,1)
            Btn.BackgroundTransparency=1
            Btn.Text=text
            Btn.Font=Settings.Font
            Btn.TextSize=Settings.TextSize
            Btn.TextColor3=Settings.Colors.Text
            Btn.Parent=Frame
            Btn.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)

            element._frame = Frame
            element._label = Btn
            table.insert(Elements,element)

            function element:SetText(newText)
                Btn.Text=newText
            end
            function element:Remove()
                Frame:Destroy()
            end
            function element:Hide() Frame.Visible=false end
            function element:Show() Frame.Visible=true end
            function element:Disable() Btn.Active=false Btn.TextColor3=Settings.Colors.SubText end
            function element:Enable() Btn.Active=true Btn.TextColor3=Settings.Colors.Text end
            function element:SetColor(color) Frame.BackgroundColor3=color end
            return element
        end

        -- ================= TOGGLE =================
        function Tab:CreateToggle(text,default,callback)
            local element={}
            local state = default
            local Frame = BaseFrame()
            local Btn = Instance.new("TextButton")
            Btn.Size=UDim2.new(1,0,1,0)
            Btn.BackgroundTransparency=1
            Btn.Text=text
            Btn.TextColor3=Settings.Colors.Text
            Btn.Font=Settings.Font
            Btn.TextSize=Settings.TextSize
            Btn.Parent=Frame

            local function Update(val)
                state = val
                Frame.BackgroundColor3 = state and Settings.Colors.Accent or Settings.Colors.Element
                if callback then callback(state) end
            end

            Btn.MouseButton1Click:Connect(function() Update(not state) end)

            element._frame=Frame
            element._label=Btn
            table.insert(Elements,element)

            function element:Set(val) Update(val) end
            function element:Toggle() Update(not state) end
            function element:Get() return state end
            function element:Remove() Frame:Destroy() end
            function element:Hide() Frame.Visible=false end
            function element:Show() Frame.Visible=true end
            function element:Disable() Btn.Active=false Btn.TextColor3=Settings.Colors.SubText end
            function element:Enable() Btn.Active=true Btn.TextColor3=Settings.Colors.Text end
            function element:SetColor(color) Frame.BackgroundColor3=color end
            return element
        end

        -- ================= SLIDER =================
        function Tab:CreateSlider(text,min,max,default,callback)
            local element={}
            local value = default or min
            local Frame = BaseFrame(30)
            local Label = Instance.new("TextLabel")
            Label.Size=UDim2.fromScale(1,1)
            Label.BackgroundTransparency=1
            Label.Text=text.." : "..tostring(value)
            Label.Font=Settings.Font
            Label.TextSize=Settings.TextSize
            Label.TextColor3=Settings.Colors.Text
            Label.Parent=Frame

            local SliderBar = Instance.new("Frame")
            SliderBar.Size=UDim2.new(1,0,0,4)
            SliderBar.Position=UDim2.new(0,0,1,-6)
            SliderBar.BackgroundColor3=Settings.Colors.SubText
            SliderBar.Parent=Frame

            local Fill = Instance.new("Frame")
            Fill.Size=UDim2.new((value-min)/(max-min),0,1,0)
            Fill.BackgroundColor3=Settings.Colors.Accent
            Fill.Parent=SliderBar

            local dragging=false
            SliderBar.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1 then
                    dragging=true
                    local function move(mouse)
                        local x = math.clamp(mouse.X - SliderBar.AbsolutePosition.X,0,SliderBar.AbsoluteSize.X)
                        value = min + (x/SliderBar.AbsoluteSize.X)*(max-min)
                        Fill.Size=UDim2.new((value-min)/(max-min),0,1,0)
                        Label.Text=text.." : "..string.format("%.2f",value)
                        if callback then callback(value) end
                    end
                    move(UIS:GetMouseLocation())
                    local moveCon
                    moveCon=UIS.InputChanged:Connect(function(i)
                        if i.UserInputType==Enum.UserInputType.MouseMovement then move(i.Position) end
                    end)
                    UIS.InputEnded:Connect(function(i)
                        if i.UserInputType==Enum.UserInputType.MouseButton1 then
                            dragging=false
                            moveCon:Disconnect()
                        end
                    end)
                end
            end)

            element._frame=Frame
            element._label=Label
            table.insert(Elements,element)

            function element:Set(val)
                value=math.clamp(val,min,max)
                Fill.Size=UDim2.new((value-min)/(max-min),0,1,0)
                Label.Text=text.." : "..string.format("%.2f",value)
            end
            function element:Get() return value end
            function element:SetStep(step) value=math.floor(value/step)*step element:Set(value) end
            function element:Remove() Frame:Destroy() end
            function element:Hide() Frame.Visible=false end
            function element:Show() Frame.Visible=true end
            function element:Disable() SliderBar.Active=false end
            function element:Enable() SliderBar.Active=true end
            function element:SetColor(color) Fill.BackgroundColor3=color end
            return element
        end

        -- ================= TEXTBOX =================
        function Tab:CreateTextbox(text,callback)
            local element={}
            local Frame = BaseFrame(40)
            local Box = Instance.new("TextBox")
            Box.Size=UDim2.new(1,0,1,0)
            Box.PlaceholderText=text
            Box.Text=""
            Box.Font=Settings.Font
            Box.TextSize=Settings.TextSize
            Box.TextColor3=Settings.Colors.Text
            Box.BackgroundColor3=Settings.Colors.Element
            Box.Parent=Frame
            Corner(Box,6)

            Box.FocusLost:Connect(function()
                if callback then callback(Box.Text) end
            end)

            element._frame=Frame
            element._label=Box
            table.insert(Elements,element)

            function element:SetText(val) Box.Text=val end
            function element:Get() return Box.Text end
            function element:Clear() Box.Text="" end
            function element:Remove() Frame:Destroy() end
            function element:Hide() Frame.Visible=false end
            function element:Show() Frame.Visible=true end
            function element:Disable() Box.Active=false Box.TextColor3=Settings.Colors.SubText end
            function element:Enable() Box.Active=true Box.TextColor3=Settings.Colors.Text end
            function element:SetColor(color) Box.BackgroundColor3=color end
            return element
        end

        -- ================= DROPDOWN =================
        function Tab:CreateDropdown(text,items,returnIndex,callback)
            local element={}
            local Frame = BaseFrame()
            local Label = Instance.new("TextLabel")
            Label.Size=UDim2.fromScale(1,1)
            Label.Text=text
            Label.Font=Settings.Font
            Label.TextSize=Settings.TextSize
            Label.TextColor3=Settings.Colors.Text
            Label.Parent=Frame

            local DropdownFrame = Instance.new("Frame")
            DropdownFrame.Size=UDim2.new(1,0,0,0)
            DropdownFrame.Position=UDim2.new(0,0,0,40)
            DropdownFrame.BackgroundColor3=Settings.Colors.Element
            DropdownFrame.Parent=Frame
            Corner(DropdownFrame,6)

            local Open = false
            local OptionFrames = {}

            local function ToggleDrop()
                Open = not Open
                DropdownFrame.Size=Open and UDim2.new(1,0,0,#items*30) or UDim2.new(1,0,0,0)
            end

            Label.MouseButton1Click = Instance.new("TextButton")
            Label.MouseButton1Click.Size = UDim2.new(1,0,1,0)
            Label.MouseButton1Click.BackgroundTransparency=1
            Label.MouseButton1Click.Text=""
            Label.MouseButton1Click.Parent = Label
            Label.MouseButton1Click.MouseButton1Click:Connect(ToggleDrop)

            local Current
            local function Select(v,i)
                Current = returnIndex and i or v
                Label.Text=text..": "..v
                if callback then callback(Current) end
            end

            local function UpdateOptions()
                for _,f in ipairs(OptionFrames) do f:Destroy() end
                OptionFrames={}
                for i,v in ipairs(items) do
                    local btn = Instance.new("TextButton")
                    btn.Size=UDim2.new(1,0,0,30)
                    btn.Position=UDim2.new(0,0,0,(i-1)*30)
                    btn.BackgroundColor3=Settings.Colors.Element
                    btn.Text=v
                    btn.Font=Settings.Font
                    btn.TextSize=Settings.TextSize
                    btn.TextColor3=Settings.Colors.Text
                    btn.Parent=DropdownFrame
                    btn.MouseButton1Click:Connect(function() Select(v,i) ToggleDrop() end)
                    table.insert(OptionFrames,btn)
                end
            end
            UpdateOptions()

            element._frame=Frame
            element._label=Label
            table.insert(Elements,element)

            function element:SetItems(t) items=t UpdateOptions() end
            function element:SetText(t) Label.Text=t end
            function element:Set(v) Select(v) end
            function element:Get() return Current end
            function element:SelectRandom()
                if #items>0 then Select(items[math.random(#items)],math.random(#items)) end
            end
            function element:Search(query)
                query=string.lower(query)
                for i,v in ipairs(OptionFrames) do
                    v.Visible = string.find(string.lower(v.Text),query) ~= nil
                end
            end
            function element:Remove() Frame:Destroy() end
            function element:Hide() Frame.Visible=false end
            function element:Show() Frame.Visible=true end
            function element:Disable() Label.Active=false Label.TextColor3=Settings.Colors.SubText end
            function element:Enable() Label.Active=true Label.TextColor3=Settings.Colors.Text end
            function element:SetColor(color) Frame.BackgroundColor3=color end
            return element
        end

        function Tab:Rename(newName) Button.Text=newName end
        function Tab:SetVisible(state) Scroll.Visible=state end
        function Tab:Search(query)
            SearchBox.Text=query
            for _,el in ipairs(Elements) do
                local text = el._label and string.lower(el._label.Text) or ""
                if query=="" or string.find(text,query) then
                    if el._frame then el._frame.Visible=true end
                else
                    if el._frame then el._frame.Visible=false end
                end
            end
        end

        return Tab
    end

    return Window
end

return Library
