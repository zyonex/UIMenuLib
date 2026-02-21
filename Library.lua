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
	
	Keybind = Enum.KeyCode.RightShift, -- nil disables
	Modern = true, -- enables tween animations

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

--================ UTIL =================--

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

--================ WINDOW =================--

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

	--================ GLOBAL KEYBIND =================--

	local Visible = true

	local function SetVisible(state)
		Visible = state

		if Settings.Modern then
			if state then
				Main.Visible = true
				Main.BackgroundTransparency = 1
				TweenService:Create(Main, TweenInfo.new(
					Settings.AnimationSpeed,
					Settings.TweenStyle,
					Settings.TweenDirection
					), {
						BackgroundTransparency = 0
					}):Play()
			else
				local tween = TweenService:Create(Main, TweenInfo.new(
					Settings.AnimationSpeed,
					Settings.TweenStyle,
					Settings.TweenDirection
					), {
						BackgroundTransparency = 1
					})
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

	function Window:ToggleGUI()
		SetVisible(not Visible)
	end

	function Window:SetVisible(state)
		SetVisible(state)
	end

	--================ DRAG =================--

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

	--================ RESIZE =================--

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

	--================ TABS =================--

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

	local Window = {}

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
			if CurrentTab then
				CurrentTab.Visible = false
			end
			Scroll.Visible = true
			CurrentTab = Scroll
		end

		Button.MouseButton1Click:Connect(Switch)

		if not CurrentTab then
			Switch()
		end

		local Tab = {}

		local function Base(height)
			local Frame = Instance.new("Frame")
			Frame.Size = UDim2.new(1,-5,0,height or 40)
			Frame.BackgroundColor3 = Settings.Colors.Element
			Frame.Parent = Scroll
			Corner(Frame,6)
			return Frame
		end

		function Tab:CreateButton(text,callback)
			local Frame = Base()
			local Btn = Instance.new("TextButton")
			if Settings.Modern then
				Btn.MouseEnter:Connect(function()
					TweenService:Create(Frame, TweenInfo.new(Settings.AnimationSpeed),
						{BackgroundColor3 = Settings.Colors.ElementHover}
					):Play()
				end)

				Btn.MouseLeave:Connect(function()
					TweenService:Create(Frame, TweenInfo.new(Settings.AnimationSpeed),
						{BackgroundColor3 = Settings.Colors.Element}
					):Play()
				end)
			end
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
		end

		function Tab:CreateToggle(text,default,callback)
			local state = default
			local Frame = Base()
			Frame.BackgroundColor3 = state and Settings.Colors.Accent or Settings.Colors.Element

			local Btn = Instance.new("TextButton")
			Btn.Size = UDim2.fromScale(1,1)
			Btn.BackgroundTransparency = 1
			Btn.Text = text
			Btn.TextColor3 = Settings.Colors.Text
			Btn.Font = Settings.Font
			Btn.TextSize = Settings.TextSize
			Btn.Parent = Frame
			
			local function Update(val)
				state = val

				if Settings.Modern then
					TweenService:Create(Frame, TweenInfo.new(Settings.AnimationSpeed),
						{BackgroundColor3 = state and Settings.Colors.Accent or Settings.Colors.Element}
					):Play()
				else
					Frame.BackgroundColor3 = state and Settings.Colors.Accent or Settings.Colors.Element
				end

				if callback then callback(state) end
			end
			Btn.MouseButton1Click:Connect(function()
				state = not state
				Frame.BackgroundColor3 = state and Settings.Colors.Accent or Settings.Colors.Element
				if callback then callback(state) end
			end)
		end

		function Tab:CreateSlider(text,min,max,default,callback)
			local value = default or min
			local Frame = Base(55)

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
			
			local con
			Bar.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					con = UIS.InputChanged:Connect(function(i)
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
				if input.UserInputType == Enum.UserInputType.MouseButton1 then
					con:Disconnect()
				end
			end)
		end

		function Tab:CreateTextbox(text,callback)
			local Frame = Base()
			local Box = Instance.new("TextBox")
			Box.Size = UDim2.fromScale(1,1)
			Box.BackgroundTransparency = 1
			Box.PlaceholderText = text
			Box.TextColor3 = Settings.Colors.Text
			Box.Font = Settings.Font
			Box.TextSize = Settings.TextSize
			Box.Parent = Frame
			Box.Text = ""
			Box.FocusLost:Connect(function()
				if callback then callback(Box.Text) end
			end)
		end

		return Tab
	end

	--================ ADVANCED CONSOLE =================--

	function Window:EnableConsole(opts)

		opts = opts or {}
		local Height = opts.Height or 200

		local Console = Instance.new("Frame")
		Console.Size = UDim2.new(1,-10,0,Height)
		Console.Position = UDim2.new(0,5,1,-(Height+5))
		Console.BackgroundColor3 = Settings.Colors.Element
		Console.Parent = Main
		Corner(Console,8)

		local Output = Instance.new("ScrollingFrame")
		Output.Size = UDim2.new(1,-10,1,-40)
		Output.Position = UDim2.new(0,5,0,5)
		Output.CanvasSize = UDim2.new(0,0,0,0)
		Output.BackgroundTransparency = 1
		Output.Parent = Console

		local Layout = Instance.new("UIListLayout")
		Layout.Parent = Output

		Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			Output.CanvasSize = UDim2.new(0,0,0,Layout.AbsoluteContentSize.Y+5)
			Output.CanvasPosition = Vector2.new(0,Layout.AbsoluteContentSize.Y)
		end)

		local Input = Instance.new("TextBox")
		Input.Size = UDim2.new(1,-10,0,30)
		Input.Position = UDim2.new(0,5,1,-35)
		Input.PlaceholderText = "Enter command..."
		Input.BackgroundColor3 = Settings.Colors.Background
		Input.TextColor3 = Settings.Colors.Text
		Input.Font = Settings.Font
		Input.TextSize = Settings.TextSize
		Input.Parent = Console
		Corner(Input,6)

		local Commands = {}
		local History = {}
		local Index = 0

		local function Print(text,color,tag)
			local Label = Instance.new("TextLabel")
			Label.BackgroundTransparency = 1
			Label.TextWrapped = true
			Label.TextXAlignment = Enum.TextXAlignment.Left
			Label.Size = UDim2.new(1,-5,0,20)
			Label.Font = Settings.Font
			Label.TextSize = Settings.TextSize
			Label.TextColor3 = color
			Label.Text = "["..os.date("%X").."] "..(tag and "["..tag.."] " or "")..text
			Label.Parent = Output
			task.wait()
			Label.Size = UDim2.new(1,-5,0,Label.TextBounds.Y+4)
		end

		function Window:ConsoleWrite(t) Print(t,Settings.Colors.Text) end
		function Window:ConsoleInfo(t) Print(t,Settings.Colors.Info,"INFO") end
		function Window:ConsoleWarn(t) Print(t,Settings.Colors.Warn,"WARN") end
		function Window:ConsoleError(t) Print(t,Settings.Colors.Error,"ERROR") end

		function Window:BindConsoleCommand(name,cb)
			Commands[string.lower(name)] = cb
		end

		Commands["help"] = function()
			for n,_ in pairs(Commands) do
				Print(" - "..n,Settings.Colors.SubText)
			end
		end

		Commands["clear"] = function()
			for _,v in pairs(Output:GetChildren()) do
				if v:IsA("TextLabel") then v:Destroy() end
			end
		end

		Input.FocusLost:Connect(function(enter)
			if not enter then return end
			local text = Input.Text
			Input.Text = ""
			if text == "" then return end

			table.insert(History,text)
			Index = #History+1

			Print("> "..text,Settings.Colors.Accent)

			local args = {}
			for word in string.gmatch(text,"%S+") do
				table.insert(args,word)
			end

			local cmd = string.lower(args[1] or "")
			table.remove(args,1)

			if Commands[cmd] then
				local success,err = pcall(function()
					Commands[cmd](args)
				end)
				if not success then
					Print(err,Settings.Colors.Error,"ERROR")
				end
			else
				Print("Unknown command.",Settings.Colors.Error,"ERROR")
			end
		end)

		UIS.InputBegan:Connect(function(input,gp)
			if gp then return end
			if Input:IsFocused() then
				if input.KeyCode == Enum.KeyCode.Up then
					Index = math.clamp(Index-1,1,#History)
					Input.Text = History[Index] or ""
				elseif input.KeyCode == Enum.KeyCode.Down then
					Index = math.clamp(Index+1,1,#History)
					Input.Text = History[Index] or ""
				end
			end
		end)

		Print("Advanced Console Initialized.",Settings.Colors.SubText,"SYSTEM")
	end

	return Window
end
