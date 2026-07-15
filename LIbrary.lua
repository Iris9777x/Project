local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local HttpService       = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local Theme = {
	Accent        = Color3.fromRGB(101, 101, 201),
	AccentHover   = Color3.fromRGB(121, 121, 221),
	AccentDark    = Color3.fromRGB(51, 51, 101),
	AccentBg      = Color3.fromRGB(26, 26, 51),

	Background    = Color3.fromRGB(6, 6, 6),
	MenuBorder    = Color3.fromRGB(21, 21, 21),
	Topbar        = Color3.fromRGB(26, 26, 26),
	TopbarBorder  = Color3.fromRGB(51, 51, 51),

	OuterFill     = Color3.fromRGB(16, 16, 16),
	OuterBorder   = Color3.fromRGB(31, 31, 31),
	InnerFill     = Color3.fromRGB(36, 36, 36),
	InnerBorder   = Color3.fromRGB(66, 66, 66),
	InnerHover    = Color3.fromRGB(46, 46, 46),

	Section       = Color3.fromRGB(11, 11, 11),
	SectionBorder = Color3.fromRGB(31, 31, 31),

	Text          = Color3.fromRGB(201, 201, 201),
	TextDim       = Color3.fromRGB(151, 151, 151),
	TextBright    = Color3.fromRGB(255, 255, 255),
	Black         = Color3.fromRGB(0, 0, 0),

	Font          = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
	TextSize      = 10,
	TitleSize     = 15,
	SectionSize   = 14,

	CornerElement = UDim.new(0, 5),
	CornerMenu    = UDim.new(0, 10),
	CornerSmall   = UDim.new(0, 3),
}

local function create(class, props, children)
	local inst = Instance.new(class)
	for k, v in pairs(props or {}) do
		inst[k] = v
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	return inst
end

local function corner(radius)
	return create("UICorner", { CornerRadius = radius or Theme.CornerElement })
end

local function tween(inst, time, props, style, dir)
	local info = TweenInfo.new(time or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out)
	local t = TweenService:Create(inst, info, props)
	t:Play()
	return t
end

local function bordered(props)
	props = props or {}
	local z = props.ZIndex or 1
	local root = create("Frame", {
		BackgroundColor3 = props.Fill or Theme.OuterFill,
		Size = props.Size or UDim2.new(1, 0, 1, 0),
		Position = props.Position or UDim2.new(0, 0, 0, 0),
		ZIndex = z,
		BorderSizePixel = 0,
	}, { corner(props.Corner) })

	local border = create("Frame", {
		Name = "Border",
		BackgroundColor3 = props.Border or Theme.OuterBorder,
		Size = UDim2.new(1, 2, 1, 2),
		Position = UDim2.new(0, -1, 0, -1),
		ZIndex = z - 1,
		BorderSizePixel = 0,
		Parent = root,
	}, { corner(props.Corner) })

	local content = create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		ZIndex = z,
		Parent = root,
	})

	return { Root = root, Border = border, Content = content }
end

local function outline(parent, zindex)
	return create("Frame", {
		Name = "Outline",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		ZIndex = zindex or 100,
		Parent = parent,
	}, {
		corner(),
		create("UIStroke", { Transparency = 0.9, Thickness = 0.5, Color = Theme.TextBright }),
	})
end

local function label(props)
	return create("TextLabel", {
		BackgroundTransparency = 1,
		FontFace = Theme.Font,
		TextSize = props.TextSize or Theme.TextSize,
		TextColor3 = props.Color or Theme.Text,
		TextXAlignment = props.XAlign or Enum.TextXAlignment.Left,
		TextYAlignment = props.YAlign or Enum.TextYAlignment.Center,
		Text = props.Text or "",
		Size = props.Size or UDim2.new(1, 0, 1, 0),
		Position = props.Position or UDim2.new(0, 0, 0, 0),
		ZIndex = props.ZIndex or 14,
		ClipsDescendants = props.Clip ~= false,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = props.Parent,
	})
end

local ProGui = {}
ProGui.__index = ProGui
ProGui.Theme = Theme
ProGui.Flags = {}
ProGui._windows = {}
ProGui._accentObjects = {}

function ProGui:_bindAccent(inst, prop)
	table.insert(self._accentObjects, { inst = inst, prop = prop })
	inst[prop] = Theme.Accent
end

function ProGui:SetAccent(color)
	Theme.Accent = color
	for _, entry in ipairs(self._accentObjects) do
		if entry.inst and entry.inst.Parent then
			entry.inst[entry.prop] = color
		end
	end
end

local function fileApi()
	local w = (writefile or (syn and syn.write_file))
	local r = (readfile or (syn and syn.read_file))
	local l = (listfiles)
	local d = (delfile or (syn and syn.delete_file))
	local m = (makefolder)
	local i = (isfolder)
	local f = (isfile)
	if w and r and l then
		return { write = w, read = r, list = l, del = d, makefolder = m, isfolder = i, isfile = f }
	end
	return nil
end

local function mountScreenGui(name)
	local gui = create("ScreenGui", {
		Name = name or "ProGui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
		IgnoreGuiInset = true,
		DisplayOrder = 9999,
	})
	local ok = pcall(function()
		if syn and syn.protect_gui then syn.protect_gui(gui) end
		if gethui then
			gui.Parent = gethui()
		elseif get_hidden_gui then
			gui.Parent = get_hidden_gui()
		else
			gui.Parent = CoreGui
		end
	end)
	if not ok then
		gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
	end
	return gui
end

local function makeDraggable(frame, handle)
	handle = handle or frame
	local dragging, dragStart, startPos
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale, startPos.X.Offset + delta.X,
				startPos.Y.Scale, startPos.Y.Offset + delta.Y
			)
		end
	end)
end

function ProGui:_initNotifications(screen)
	self._notifyHolder = create("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -12),
		Size = UDim2.new(0, 240, 1, -24),
		ZIndex = 500,
		Parent = screen,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 6),
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})
end

function ProGui:Notify(opts)
	opts = opts or {}
	local title = opts.Title or "Notification"
	local text = opts.Text or ""
	local duration = opts.Duration or 4

	local outer = bordered({ Fill = Theme.OuterFill, Border = Theme.OuterBorder, ZIndex = 501 })
	outer.Root.Size = UDim2.new(1, 0, 0, 46)
	outer.Root.Parent = self._notifyHolder

	local inner = bordered({ Fill = Theme.InnerFill, Border = Theme.InnerBorder, ZIndex = 503 })
	inner.Root.Size = UDim2.new(1, 0, 1, 0)
	inner.Root.Parent = outer.Content

	local accent = create("Frame", {
		Size = UDim2.new(0, 3, 1, -8),
		Position = UDim2.new(0, 4, 0, 4),
		ZIndex = 505,
		BorderSizePixel = 0,
		Parent = inner.Content,
	}, { corner(UDim.new(1, 0)) })
	self:_bindAccent(accent, "BackgroundColor3")

	label({
		Parent = inner.Content, Text = title, Color = Theme.TextBright,
		TextSize = 12, ZIndex = 505,
		Position = UDim2.new(0, 12, 0, 4), Size = UDim2.new(1, -16, 0, 16),
	})
	label({
		Parent = inner.Content, Text = text, Color = Theme.TextDim, ZIndex = 505,
		Position = UDim2.new(0, 12, 0, 22), Size = UDim2.new(1, -16, 0, 18),
	})

	outer.Root.Position = UDim2.new(1, 260, 0, 0)
	tween(outer.Root, 0.25, { Position = UDim2.new(0, 0, 0, 0) })

	task.delay(duration, function()
		if outer.Root and outer.Root.Parent then
			tween(outer.Root, 0.25, { Position = UDim2.new(1, 260, 0, 0) })
			task.wait(0.26)
			outer.Root:Destroy()
		end
	end)
end

local Window = {}
Window.__index = Window

function ProGui:CreateWindow(opts)
	opts = opts or {}
	local screen = mountScreenGui(opts.Name or "ProGui")
	self:_initNotifications(screen)

	local content = create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = screen,
	})

	local size = opts.Size or UDim2.new(0, 560, 0, 380)
	local menu = create("Frame", {
		Name = "Menu",
		BackgroundColor3 = Theme.Background,
		Size = size,
		Position = opts.Position or UDim2.new(0.5, -math.floor(size.X.Offset / 2), 0.5, -math.floor(size.Y.Offset / 2)),
		BorderSizePixel = 0,
		Parent = content,
	}, { corner(Theme.CornerMenu) })

	create("Frame", {
		Name = "Border", ZIndex = 0, BackgroundColor3 = Theme.MenuBorder,
		Size = UDim2.new(1, 2, 1, 2), Position = UDim2.new(0, -1, 0, -1),
		BorderSizePixel = 0, Parent = menu,
	}, { corner(Theme.CornerMenu) })

	create("Frame", {
		Name = "Shadow", ZIndex = 0, BackgroundColor3 = Theme.Black,
		Size = UDim2.new(1, 6, 1, 6), Position = UDim2.new(0, -3, 0, -1),
		BackgroundTransparency = 0.8, BorderSizePixel = 0, Parent = menu,
	}, { corner(Theme.CornerMenu) })

	local topWrap = bordered({ Fill = Theme.Topbar, Border = Theme.TopbarBorder, ZIndex = 5 })
	topWrap.Root.Size = UDim2.new(1, -10, 0, 25)
	topWrap.Root.Position = UDim2.new(0, 5, 0, 5)
	topWrap.Root.Parent = menu

	label({
		Parent = topWrap.Content, Text = opts.Title or "ProGui",
		Color = Theme.TextBright, TextSize = Theme.TitleSize, ZIndex = 6,
		Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
	})
	label({
		Parent = topWrap.Content, Text = opts.Subtitle or "",
		Color = Theme.TextDim, XAlign = Enum.TextXAlignment.Right, ZIndex = 6,
		Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -28, 1, 0),
	})

	local eyeBtn = create("ImageButton", {
		Name = "Toggle", BackgroundTransparency = 1,
		Image = opts.EyeIcon or "rbxassetid://130003477074963",
		ImageColor3 = Theme.TextDim,
		Size = UDim2.new(0, 16, 0, 16), Position = UDim2.new(1, -21, 0.5, -8),
		ZIndex = 6, Parent = topWrap.Content,
	})
	eyeBtn.MouseEnter:Connect(function() tween(eyeBtn, 0.1, { ImageColor3 = Theme.TextBright }) end)
	eyeBtn.MouseLeave:Connect(function() tween(eyeBtn, 0.1, { ImageColor3 = Theme.TextDim }) end)

	local sideWrap = bordered({ Fill = Theme.Topbar, Border = Theme.TopbarBorder, ZIndex = 5 })
	sideWrap.Root.Size = UDim2.new(0, 40, 1, -40)
	sideWrap.Root.Position = UDim2.new(0, 5, 0, 35)
	sideWrap.Root.Parent = menu

	local tabList = create("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.new(0, 4, 0, 4), ZIndex = 6, Parent = sideWrap.Content,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 5),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local bottomList = create("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, -8, 0, 32),
		Position = UDim2.new(0, 4, 1, -36), ZIndex = 6, Parent = sideWrap.Content,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 5),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local pageHolder = create("Frame", {
		Name = "Pages", BackgroundTransparency = 1,
		Size = UDim2.new(1, -60, 1, -40),
		Position = UDim2.new(0, 50, 0, 35), ZIndex = 5, Parent = menu,
	})

	makeDraggable(menu, topWrap.Root)

	local self_w = setmetatable({
		Lib = self,
		Screen = screen,
		Menu = menu,
		TabList = tabList,
		BottomList = bottomList,
		PageHolder = pageHolder,
		Tabs = {},
		_activeTab = nil,
		_visible = true,
		_toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift,
		_configFolder = opts.ConfigFolder or ((opts.Title or "ProGui"):gsub("%s+", "") .. "/configs"),
	}, Window)

	eyeBtn.MouseButton1Click:Connect(function() self_w:Toggle() end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == self_w._toggleKey then
			self_w:Toggle()
		end
	end)

	table.insert(self._windows, self_w)
	return self_w
end

function Window:Toggle()
	self._visible = not self._visible
	self.Menu.Visible = self._visible
end

function Window:SetToggleKey(key)
	self._toggleKey = key
end

function Window:Notify(opts)
	return self.Lib:Notify(opts)
end

function Window:Destroy()
	self.Screen:Destroy()
	for i, w in ipairs(self.Lib._windows) do
		if w == self then table.remove(self.Lib._windows, i) break end
	end
end

local Tab = {}
Tab.__index = Tab

function Window:AddTab(opts)
	opts = opts or {}
	local parentList = opts.Bottom and self.BottomList or self.TabList

	local btnWrap = bordered({ Fill = Theme.OuterFill, Border = Theme.OuterBorder, ZIndex = 7 })
	btnWrap.Root.Size = UDim2.new(0, 28, 0, 28)
	btnWrap.Root.Parent = parentList

	local btn = create("ImageButton", {
		BackgroundTransparency = 1,
		Image = opts.Icon or "",
		ImageColor3 = Theme.TextDim,
		Size = UDim2.new(0, 16, 0, 16),
		Position = UDim2.new(0.5, -8, 0.5, -8),
		ZIndex = 9, Parent = btnWrap.Content,
	})

	local letter
	if not opts.Icon or opts.Icon == "" then
		btn.Image = ""
		letter = label({
			Parent = btnWrap.Content, Text = (opts.Name or "T"):sub(1, 1),
			XAlign = Enum.TextXAlignment.Center, ZIndex = 9,
			TextSize = 12, Size = UDim2.new(1, 0, 1, 0),
		})
		letter.TextColor3 = Theme.TextDim
	end

	local page = create("ScrollingFrame", {
		Name = (opts.Name or "Tab") .. "_page",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.TopbarBorder,
		Visible = false, ZIndex = 5, Parent = self.PageHolder,
	})

	local columns = create("Frame", {
		Name = "Columns", BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 5, Parent = page,
	})

	local colCount = opts.Columns or 2
	local colFrames = {}
	local colLayout = create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, 6),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = columns,
	})
	for i = 1, colCount do
		local col = create("Frame", {
			Name = "Column" .. i, BackgroundTransparency = 1,
			Size = UDim2.new(1 / colCount, -6 + (6 / colCount), 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = i, ZIndex = 5, Parent = columns,
		}, {
			create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }),
		})
		colFrames[i] = col
	end

	local tabObj = setmetatable({
		Window = self, Lib = self.Lib,
		Button = btn, ButtonWrap = btnWrap, Letter = letter, Page = page,
		Columns = colFrames, _nextCol = 1, Name = opts.Name,
	}, Tab)

	local function select()
		if self._activeTab == tabObj then return end
		if self._activeTab then
			local prev = self._activeTab
			prev.Page.Visible = false
			tween(prev.ButtonWrap.Root, 0.15, { BackgroundColor3 = Theme.OuterFill })
			tween(prev.Button, 0.15, { ImageColor3 = Theme.TextDim })
			if prev.Letter then tween(prev.Letter, 0.15, { TextColor3 = Theme.TextDim }) end
		end
		self._activeTab = tabObj
		page.Visible = true
		tween(btnWrap.Root, 0.15, { BackgroundColor3 = Theme.AccentBg })
		tween(btn, 0.15, { ImageColor3 = Theme.Accent })
		if letter then tween(letter, 0.15, { TextColor3 = Theme.TextBright }) end
	end

	btn.MouseButton1Click:Connect(select)
	tabObj.Select = select
	table.insert(self.Tabs, tabObj)
	if not self._activeTab and not opts.Bottom then select() end
	return tabObj
end

local Section = {}
Section.__index = Section

function Tab:AddSection(opts)
	opts = opts or {}
	local col = self.Columns[opts.Column or self._nextCol]
	if not opts.Column then
		self._nextCol = (self._nextCol % #self.Columns) + 1
	end

	local wrap = bordered({ Fill = Theme.Section, Border = Theme.SectionBorder, ZIndex = 8 })
	wrap.Root.Size = UDim2.new(1, 0, 0, 34)
	wrap.Root.AutomaticSize = Enum.AutomaticSize.Y
	wrap.Root.Parent = col

	label({
		Parent = wrap.Content, Text = opts.Name or "Section",
		Color = Theme.TextBright, TextSize = Theme.SectionSize, ZIndex = 9,
		XAlign = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 8, 0, 6), Size = UDim2.new(1, -16, 0, 18),
	})

	local elements = create("Frame", {
		Name = "Elements", BackgroundTransparency = 1,
		Size = UDim2.new(1, -14, 0, 0), Position = UDim2.new(0, 7, 0, 30),
		AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 9, Parent = wrap.Content,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", { PaddingBottom = UDim.new(0, 8) }),
	})

	return setmetatable({
		Tab = self, Lib = self.Lib, Root = wrap.Root, Holder = elements,
	}, Section)
end

function Section:_row(height)
	local outer = bordered({ Fill = Theme.OuterFill, Border = Theme.OuterBorder, ZIndex = 11 })
	outer.Root.Size = UDim2.new(1, 0, 0, height or 20)
	outer.Root.Parent = self.Holder

	local inner = bordered({ Fill = Theme.InnerFill, Border = Theme.InnerBorder, ZIndex = 13 })
	inner.Root.Size = UDim2.new(1, 0, 1, 0)
	inner.Root.Parent = outer.Content

	outline(outer.Content, 100)
	return { Wrap = outer.Root, Inner = inner.Root, Content = inner.Content }
end

local function registerFlag(lib, flag, value)
	if flag then lib.Flags[flag] = value end
end

function Section:AddLabel(opts)
	opts = opts or {}
	local row = self:_row(opts.Height or 20)
	local txt = label({
		Parent = row.Content, Text = opts.Text or "Label",
		Color = opts.Color or Theme.Text, ZIndex = 14,
		XAlign = opts.Center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(1, -12, 1, 0),
	})
	txt.TextWrapped = opts.Wrap or false
	if opts.Wrap then
		txt.TextYAlignment = Enum.TextYAlignment.Top
		row.Content.Parent.Parent.AutomaticSize = Enum.AutomaticSize.Y
	end
	return {
		SetText = function(_, t) txt.Text = t end,
		Instance = row.Wrap,
	}
end

function Section:AddButton(opts)
	opts = opts or {}
	local row = self:_row(20)
	label({
		Parent = row.Content, Text = opts.Name or "Button",
		ZIndex = 14, Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(1, -12, 1, 0),
	})
	local hit = create("TextButton", {
		BackgroundTransparency = 1, Text = "",
		Size = UDim2.new(1, 0, 1, 0), ZIndex = 16, Parent = row.Content,
	})
	hit.MouseEnter:Connect(function() tween(row.Inner, 0.12, { BackgroundColor3 = Theme.InnerHover }) end)
	hit.MouseLeave:Connect(function() tween(row.Inner, 0.12, { BackgroundColor3 = Theme.InnerFill }) end)
	hit.MouseButton1Click:Connect(function()
		tween(row.Inner, 0.08, { BackgroundColor3 = Theme.Accent })
		task.delay(0.12, function() tween(row.Inner, 0.12, { BackgroundColor3 = Theme.InnerFill }) end)
		if opts.Callback then task.spawn(opts.Callback) end
	end)
	return { Instance = row.Wrap, Fire = function() if opts.Callback then task.spawn(opts.Callback) end end }
end

function Section:AddToggle(opts)
	opts = opts or {}
	local state = opts.Default or false
	local row = self:_row(20)
	registerFlag(self.Lib, opts.Flag, state)

	label({
		Parent = row.Content, Text = opts.Name or "Toggle",
		ZIndex = 14, Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(1, -42, 1, 0),
	})

	local pill = create("ImageButton", {
		AutoButtonColor = false, ImageTransparency = 1,
		BackgroundColor3 = state and Theme.Accent or Theme.OuterBorder,
		Size = UDim2.new(0, 30, 0, 14), Position = UDim2.new(1, -32, 0.5, -7),
		ZIndex = 14, Parent = row.Content, BorderSizePixel = 0,
	}, { corner(UDim.new(1, 0)) })

	local dot = create("Frame", {
		BackgroundColor3 = Theme.TextBright, Size = UDim2.new(0, 12, 0, 12),
		Position = state and UDim2.new(1, -13, 0.5, -6) or UDim2.new(0, 1, 0.5, -6),
		ZIndex = 15, BorderSizePixel = 0, Parent = pill,
	}, { corner(UDim.new(1, 0)) })

	local api = {}
	local function apply(fire)
		tween(pill, 0.15, { BackgroundColor3 = state and Theme.Accent or Theme.OuterBorder })
		tween(dot, 0.15, { Position = state and UDim2.new(1, -13, 0.5, -6) or UDim2.new(0, 1, 0.5, -6) })
		registerFlag(self.Lib, opts.Flag, state)
		if fire and opts.Callback then task.spawn(opts.Callback, state) end
	end

	pill.MouseButton1Click:Connect(function()
		state = not state
		apply(true)
	end)

	function api:Set(v, silent) state = v and true or false; apply(not silent) end
	function api:Get() return state end
	api.Instance = row.Wrap
	return api
end

function Section:AddSlider(opts)
	opts = opts or {}
	local min = opts.Min or 0
	local max = opts.Max or 100
	local value = math.clamp(opts.Default or min, min, max)
	local decimals = opts.Decimals or 0
	local suffix = opts.Suffix or ""

	local function round(v)
		local m = 10 ^ decimals
		return math.floor(v * m + 0.5) / m
	end

	local row = self:_row(32)
	registerFlag(self.Lib, opts.Flag, value)

	label({
		Parent = row.Content, Text = opts.Name or "Slider",
		ZIndex = 14, Position = UDim2.new(0, 6, 0, 2), Size = UDim2.new(1, -60, 0, 14),
	})
	local valLabel = label({
		Parent = row.Content, Text = tostring(round(value)) .. suffix,
		Color = Theme.TextDim, XAlign = Enum.TextXAlignment.Right, ZIndex = 14,
		Position = UDim2.new(1, -56, 0, 2), Size = UDim2.new(0, 50, 0, 14),
	})

	local track = create("Frame", {
		BackgroundColor3 = Theme.OuterFill, BorderSizePixel = 0,
		Size = UDim2.new(1, -12, 0, 6), Position = UDim2.new(0, 6, 1, -12),
		ZIndex = 14, Parent = row.Content,
	}, { corner(UDim.new(1, 0)) })

	local fill = create("Frame", {
		Name = "Fill", BorderSizePixel = 0,
		Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
		ZIndex = 15, Parent = track,
	}, { corner(UDim.new(1, 0)) })
	self.Lib:_bindAccent(fill, "BackgroundColor3")

	local api = {}
	local function setFromScale(scale, fire)
		scale = math.clamp(scale, 0, 1)
		value = round(min + (max - min) * scale)
		local realScale = (value - min) / (max - min)
		tween(fill, 0.06, { Size = UDim2.new(realScale, 0, 1, 0) })
		valLabel.Text = tostring(value) .. suffix
		registerFlag(self.Lib, opts.Flag, value)
		if fire and opts.Callback then task.spawn(opts.Callback, value) end
	end

	local dragging = false
	local function update(input)
		local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
		setFromScale(rel, true)
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; update(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then update(input) end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
	end)

	function api:Set(v, silent) setFromScale((math.clamp(v, min, max) - min) / (max - min), not silent) end
	function api:Get() return value end
	api.Instance = row.Wrap
	return api
end

function Section:AddDropdown(opts)
	opts = opts or {}
	local options = opts.Options or {}
	local multi = opts.Multi or false
	local selected = multi and (opts.Default or {}) or (opts.Default or options[1])

	local row = self:_row(20)

	local function displayText()
		if multi then
			local n = 0
			for _ in pairs(selected) do n += 1 end
			return n == 0 and "None" or (n .. " selected")
		end
		return tostring(selected or "None")
	end

	label({
		Parent = row.Content, Text = opts.Name or "Dropdown",
		ZIndex = 14, Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(0.5, -6, 1, 0),
	})
	local valLabel = label({
		Parent = row.Content, Text = displayText(),
		Color = Theme.TextDim, XAlign = Enum.TextXAlignment.Right, ZIndex = 14,
		Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -20, 1, 0),
	})
	local arrow = label({
		Parent = row.Content, Text = "v", Color = Theme.TextDim,
		XAlign = Enum.TextXAlignment.Center, ZIndex = 14,
		Position = UDim2.new(1, -16, 0, 0), Size = UDim2.new(0, 14, 1, 0),
	})
	arrow.TextSize = 9

	local listWrap = bordered({ Fill = Theme.OuterFill, Border = Theme.OuterBorder, ZIndex = 60 })
	listWrap.Root.Size = UDim2.new(1, 0, 0, 0)
	listWrap.Root.Position = UDim2.new(0, 0, 1, 3)
	listWrap.Root.Visible = false
	listWrap.Root.ClipsDescendants = true
	listWrap.Root.Parent = row.Wrap

	local listCol = create("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, -4, 1, -4),
		Position = UDim2.new(0, 2, 0, 2), ZIndex = 61, Parent = listWrap.Content,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	local hit = create("TextButton", {
		BackgroundTransparency = 1, Text = "",
		Size = UDim2.new(1, 0, 1, 0), ZIndex = 20, Parent = row.Content,
	})

	local api = {}
	local optButtons = {}

	local function isSelected(opt)
		if multi then return selected[opt] == true end
		return selected == opt
	end

	local function refresh(fire)
		valLabel.Text = displayText()
		for opt, b in pairs(optButtons) do
			b.TextColor3 = isSelected(opt) and Theme.Accent or Theme.Text
		end
		registerFlag(self.Lib, opts.Flag, selected)
		if fire and opts.Callback then task.spawn(opts.Callback, selected) end
	end

	local open = false
	local function setOpen(o)
		open = o
		listWrap.Root.Visible = o
		tween(arrow, 0.15, { Rotation = o and 180 or 0 })
		local h = o and (#options * 18 + 4) or 0
		row.Wrap.ZIndex = o and 200 or 11
		tween(listWrap.Root, 0.15, { Size = UDim2.new(1, 0, 0, h) })
	end

	local function rebuild()
		for _, b in pairs(optButtons) do b:Destroy() end
		optButtons = {}
		for i, opt in ipairs(options) do
			local b = create("TextButton", {
				BackgroundColor3 = Theme.InnerFill, BorderSizePixel = 0,
				AutoButtonColor = false, Text = tostring(opt),
				FontFace = Theme.Font, TextSize = Theme.TextSize,
				TextColor3 = isSelected(opt) and Theme.Accent or Theme.Text,
				Size = UDim2.new(1, 0, 0, 16), ZIndex = 62,
				LayoutOrder = i, Parent = listCol,
			}, { corner() })
			b.MouseButton1Click:Connect(function()
				if multi then
					if selected[opt] then selected[opt] = nil else selected[opt] = true end
				else
					selected = opt
					setOpen(false)
				end
				refresh(true)
			end)
			optButtons[opt] = b
		end
	end

	hit.MouseButton1Click:Connect(function() setOpen(not open) end)
	rebuild()

	function api:Set(v, silent) selected = v; refresh(not silent) end
	function api:Get() return selected end
	function api:Refresh(newOpts, keep)
		options = newOpts or options
		if not keep then selected = multi and {} or options[1] end
		rebuild(); refresh(false)
	end
	api.Instance = row.Wrap
	return api
end

function Section:AddKeybind(opts)
	opts = opts or {}
	local key = opts.Default
	local row = self:_row(20)

	label({
		Parent = row.Content, Text = opts.Name or "Keybind",
		ZIndex = 14, Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(1, -66, 1, 0),
	})

	local box = create("TextButton", {
		BackgroundColor3 = Theme.AccentDark, BorderSizePixel = 0,
		AutoButtonColor = false, FontFace = Theme.Font, TextSize = Theme.TextSize,
		TextColor3 = Theme.Text,
		Text = key and key.Name or "None",
		Size = UDim2.new(0, 50, 0, 14), Position = UDim2.new(1, -54, 0.5, -7),
		ZIndex = 15, Parent = row.Content, ClipsDescendants = true,
	}, { corner(Theme.CornerSmall) })

	local api = {}
	local listening = false
	box.MouseButton1Click:Connect(function()
		listening = true
		box.Text = "..."
		box.TextColor3 = Theme.Accent
	end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			listening = false
			if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
				key = nil; box.Text = "None"
			else
				key = input.KeyCode; box.Text = key.Name
			end
			box.TextColor3 = Theme.Text
			registerFlag(self.Lib, opts.Flag, key and key.Name)
			if opts.Changed then task.spawn(opts.Changed, key) end
		elseif not listening and key and input.KeyCode == key and not gpe then
			if opts.Callback then task.spawn(opts.Callback) end
		end
	end)

	function api:Set(k, silent)
		if type(k) == "string" then k = Enum.KeyCode[k] end
		key = k; box.Text = k and k.Name or "None"
		registerFlag(self.Lib, opts.Flag, key and key.Name)
		if not silent and opts.Changed then task.spawn(opts.Changed, key) end
	end
	function api:Get() return key end
	api.Instance = row.Wrap
	return api
end

function Section:AddTextBox(opts)
	opts = opts or {}
	local row = self:_row(opts.Vertical and 40 or 20)
	registerFlag(self.Lib, opts.Flag, opts.Default or "")

	if opts.Vertical then
		label({
			Parent = row.Content, Text = opts.Name or "Input",
			ZIndex = 14, Position = UDim2.new(0, 6, 0, 2), Size = UDim2.new(1, -12, 0, 16),
		})
		local field = create("Frame", {
			BackgroundColor3 = Theme.AccentDark, BorderSizePixel = 0,
			Size = UDim2.new(1, -10, 0, 15), Position = UDim2.new(0, 5, 0, 22),
			ZIndex = 14, Parent = row.Content,
		}, { corner(Theme.CornerSmall) })
		local box = create("TextBox", {
			Name = "Input", BackgroundTransparency = 1,
			FontFace = Theme.Font, TextSize = Theme.TextSize, TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			PlaceholderText = opts.Placeholder or "", PlaceholderColor3 = Theme.TextDim,
			Text = opts.Default or "", ClearTextOnFocus = false,
			Size = UDim2.new(1, -10, 1, 0), Position = UDim2.new(0, 5, 0, 0),
			ZIndex = 15, Parent = field, ClipsDescendants = true,
		})
		box.FocusLost:Connect(function(enter)
			registerFlag(self.Lib, opts.Flag, box.Text)
			if opts.Callback then task.spawn(opts.Callback, box.Text, enter) end
		end)
		return {
			Set = function(_, t) box.Text = t end,
			Get = function() return box.Text end,
			Instance = row.Wrap,
		}
	end

	label({
		Parent = row.Content, Text = opts.Name or "Input",
		ZIndex = 14, Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(0.4, -6, 1, 0),
	})
	local box = create("TextBox", {
		BackgroundColor3 = Theme.AccentDark, BorderSizePixel = 0,
		FontFace = Theme.Font, TextSize = Theme.TextSize, TextColor3 = Theme.Text,
		PlaceholderText = opts.Placeholder or "", PlaceholderColor3 = Theme.TextDim,
		Text = opts.Default or "", ClearTextOnFocus = false,
		Size = UDim2.new(0.6, -10, 0, 14), Position = UDim2.new(0.4, 0, 0.5, -7),
		ZIndex = 15, Parent = row.Content, ClipsDescendants = true,
	}, { corner(Theme.CornerSmall), create("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }) })

	box.FocusLost:Connect(function(enter)
		registerFlag(self.Lib, opts.Flag, box.Text)
		if opts.Callback then task.spawn(opts.Callback, box.Text, enter) end
	end)

	return {
		Set = function(_, t) box.Text = t end,
		Get = function() return box.Text end,
		Instance = row.Wrap,
	}
end

function Section:AddColorPicker(opts)
	opts = opts or {}
	local color = opts.Default or Theme.Accent
	local h, s, v = color:ToHSV()
	local expanded = false

	local row = self:_row(20)

	label({
		Parent = row.Content, Text = opts.Name or "Color",
		ZIndex = 14, Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(1, -25, 0, 18),
	})

	local swatch = create("ImageButton", {
		AutoButtonColor = false, ImageTransparency = 1,
		BackgroundColor3 = color, BorderSizePixel = 0,
		Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -18, 0, 3),
		ZIndex = 15, Parent = row.Content,
	}, { corner(Theme.CornerSmall) })

	local satBox = create("Frame", {
		Name = "Saturation", BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0,
		Size = UDim2.new(1, -31, 0, 70), Position = UDim2.new(0, 5, 0, 23),
		ZIndex = 15, Visible = false, Parent = row.Content,
	}, {
		corner(UDim.new(0, 2)),
		create("UIGradient", {
			Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.new(1, 1, 1)),
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})
	local satWhite = create("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 1, 0), ZIndex = 15, Parent = satBox,
	}, {
		corner(UDim.new(0, 2)),
		create("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
			Rotation = 90,
		}),
	})
	local satHandle = create("Frame", {
		Size = UDim2.new(0, 5, 0, 5), BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0, ZIndex = 17, Parent = satWhite,
		Position = UDim2.new(s, -2, 1 - v, -2),
	}, { corner(UDim.new(1, 0)), create("UIStroke", { Thickness = 1, Color = Theme.Black }) })

	local hueBar = create("Frame", {
		Name = "Hue", BorderSizePixel = 0,
		Size = UDim2.new(0, 14, 0, 70), Position = UDim2.new(1, -16, 0, 23),
		ZIndex = 15, Visible = false, Parent = row.Content,
	}, {
		corner(UDim.new(0, 2)),
		create("UIGradient", {
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 0, 0)),
				ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255, 255, 0)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0, 255, 0)),
				ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0, 255, 255)),
				ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0, 0, 255)),
				ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255, 0, 255)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255, 0, 0)),
			}),
		}),
	})
	local hueHandle = create("Frame", {
		Size = UDim2.new(1, 2, 0, 3), BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0, ZIndex = 17, Parent = hueBar,
		Position = UDim2.new(0, -1, h, -1),
	}, { create("UIStroke", { Thickness = 1, Color = Theme.Black }) })

	local api = {}
	local function apply(fire)
		color = Color3.fromHSV(h, s, v)
		swatch.BackgroundColor3 = color
		satBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		satHandle.Position = UDim2.new(s, -2, 1 - v, -2)
		hueHandle.Position = UDim2.new(0, -1, h, -1)
		registerFlag(self.Lib, opts.Flag, { color.R, color.G, color.B })
		if fire and opts.Callback then task.spawn(opts.Callback, color) end
	end
	apply(false)

	local function setExpanded(o)
		expanded = o
		satBox.Visible = o
		hueBar.Visible = o
		row.Wrap.Size = UDim2.new(1, 0, 0, o and 98 or 20)
	end

	swatch.MouseButton1Click:Connect(function() setExpanded(not expanded) end)

	local function bindDrag(guiObj, onMove)
		local dragging = false
		guiObj.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
				dragging = true; onMove(input)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
			or input.UserInputType == Enum.UserInputType.Touch) then onMove(input) end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
		end)
	end

	bindDrag(satBox, function(input)
		s = math.clamp((input.Position.X - satBox.AbsolutePosition.X) / satBox.AbsoluteSize.X, 0, 1)
		v = 1 - math.clamp((input.Position.Y - satBox.AbsolutePosition.Y) / satBox.AbsoluteSize.Y, 0, 1)
		apply(true)
	end)
	bindDrag(hueBar, function(input)
		h = math.clamp((input.Position.Y - hueBar.AbsolutePosition.Y) / hueBar.AbsoluteSize.Y, 0, 1)
		apply(true)
	end)

	function api:Set(c, silent)
		if type(c) == "table" then c = Color3.new(c[1], c[2], c[3]) end
		h, s, v = c:ToHSV(); apply(not silent)
	end
	function api:Get() return color end
	api.Instance = row.Wrap
	return api
end

function Section:AddConsole(opts)
	opts = opts or {}
	local row = self:_row(opts.Height or 150)

	label({
		Parent = row.Content, Text = opts.Name or "Console",
		ZIndex = 14, Position = UDim2.new(0, 5, 0, 0), Size = UDim2.new(1, -10, 0, 18),
	})

	local screen = create("Frame", {
		BackgroundColor3 = Theme.Background, BorderSizePixel = 0,
		Size = UDim2.new(1, -10, 1, -28), Position = UDim2.new(0, 5, 0, 23),
		ZIndex = 14, Parent = row.Content,
	}, { corner(Theme.CornerSmall) })

	local scroll = create("ScrollingFrame", {
		Name = "Content", BackgroundTransparency = 1,
		Size = UDim2.new(1, -10, 1, -10), Position = UDim2.new(0, 5, 0, 5),
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.TopbarBorder,
		ZIndex = 15, Parent = screen,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	local order = 0
	local api = {}
	function api:Log(text, color)
		order += 1
		local line = create("TextLabel", {
			Name = "Message", BackgroundTransparency = 1, TextWrapped = true,
			FontFace = Theme.Font, TextSize = Theme.TextSize,
			TextColor3 = color or Theme.Text, TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = tostring(text), AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.new(1, 0, 0, 10), LayoutOrder = order, ZIndex = 15, Parent = scroll,
		})
		task.defer(function()
			scroll.CanvasPosition = Vector2.new(0, scroll.AbsoluteCanvasSize.Y)
		end)
		return line
	end
	function api:Clear()
		for _, c in ipairs(scroll:GetChildren()) do
			if c:IsA("TextLabel") then c:Destroy() end
		end
		order = 0
	end
	api.Instance = row.Wrap
	return api
end

function Section:AddDivider()
	local line = create("Frame", {
		BackgroundColor3 = Theme.OuterBorder, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1), ZIndex = 11, Parent = self.Holder,
	})
	return { Instance = line }
end

function Window:AddConfigTab(opts)
	opts = opts or {}
	local files = fileApi()
	local folder = opts.Folder or self._configFolder
	local tab = self:AddTab({ Name = "Settings", Icon = opts.Icon, Bottom = true, Columns = opts.Columns or 2 })

	if files then
		pcall(function()
			local parts = {}
			for part in folder:gmatch("[^/]+") do
				table.insert(parts, part)
				local path = table.concat(parts, "/")
				if files.makefolder and files.isfolder and not files.isfolder(path) then
					files.makefolder(path)
				end
			end
		end)
	end

	local function listConfigs()
		if not files or not files.list then return {} end
		local out = {}
		local ok, entries = pcall(files.list, folder)
		if ok and entries then
			for _, f in ipairs(entries) do
				local name = f:match("([^/\\]+)%.json$")
				if name then table.insert(out, name) end
			end
		end
		return out
	end

	local saveSection = tab:AddSection({ Name = "Save config", Column = 1 })
	local nameBox = saveSection:AddTextBox({ Name = "Config name", Placeholder = "name", Vertical = true })

	local manageSection = tab:AddSection({ Name = "Manage configs", Column = 1 })
	local configDropdown = manageSection:AddDropdown({ Name = "Config", Options = listConfigs() })

	local settingsSection = tab:AddSection({ Name = "Settings", Column = 2 })

	settingsSection:AddColorPicker({
		Name = "Highlight color",
		Default = Theme.Accent,
		Callback = function(c) self.Lib:SetAccent(c) end,
	})
	local toggleBind = settingsSection:AddKeybind({
		Name = "Toggle gui",
		Default = self._toggleKey,
		Changed = function(k) if k then self:SetToggleKey(k) end end,
	})
	settingsSection:AddButton({
		Name = "Terminate script",
		Callback = function()
			self:Destroy()
			if opts.OnTerminate then task.spawn(opts.OnTerminate) end
		end,
	})

	local function collect()
		return {
			flags = self.Lib.Flags,
			accent = { Theme.Accent.R, Theme.Accent.G, Theme.Accent.B },
		}
	end

	saveSection:AddButton({
		Name = "Save",
		Callback = function()
			local name = nameBox:Get()
			if name == "" then self:Notify({ Title = "Config", Text = "Enter a name first" }) return end
			if not files then self:Notify({ Title = "Config", Text = "File API unavailable" }) return end
			local ok = pcall(function()
				files.write(folder .. "/" .. name .. ".json", HttpService:JSONEncode(collect()))
			end)
			configDropdown:Refresh(listConfigs(), true)
			self:Notify({ Title = "Config", Text = ok and ("Saved " .. name) or "Save failed" })
		end,
	})

	manageSection:AddButton({
		Name = "Reload config list",
		Callback = function()
			configDropdown:Refresh(listConfigs(), true)
			self:Notify({ Title = "Config", Text = "List reloaded" })
		end,
	})
	manageSection:AddButton({
		Name = "Load config",
		Callback = function()
			local name = configDropdown:Get()
			if not name or not files then return end
			local ok, data = pcall(function()
				return HttpService:JSONDecode(files.read(folder .. "/" .. name .. ".json"))
			end)
			if ok and data then
				if opts.OnLoad then task.spawn(opts.OnLoad, data) end
				if data.accent then self.Lib:SetAccent(Color3.new(data.accent[1], data.accent[2], data.accent[3])) end
				self:Notify({ Title = "Config", Text = "Loaded " .. name })
			else
				self:Notify({ Title = "Config", Text = "Load failed" })
			end
		end,
	})
	manageSection:AddButton({
		Name = "Delete config",
		Callback = function()
			local name = configDropdown:Get()
			if not name or not files or not files.del then return end
			pcall(files.del, folder .. "/" .. name .. ".json")
			configDropdown:Refresh(listConfigs(), true)
			self:Notify({ Title = "Config", Text = "Deleted " .. name })
		end,
	})

	return tab
end

function ProGui:GetFlags()
	return self.Flags
end

function ProGui:GetFlag(name)
	return self.Flags[name]
end

return ProGui
