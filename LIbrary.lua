--[=[
	ProGui — UI Library for Roblox executors
	Rebuilt from a Gui2Lua dump into a clean, deduplicated, reusable library.

	Every visual element from the original GUI (double-bordered frames, toggles,
	sliders, dropdowns, keybinds, colorpickers, notifications) is now a single
	factory function instead of thousands of copy-pasted Instance.new calls.

	Usage:
		local ProGui = loadstring(game:HttpGet("<url>/ProGui.lua"))()
		local Window = ProGui:CreateWindow({ Title = "Project Auto", Subtitle = "projectauto.xyz" })
		local Tab    = Window:AddTab({ Name = "Main", Icon = "rbxassetid://..." })
		local Section= Tab:AddSection({ Name = "Combat" })
		Section:AddToggle({ Name = "God Mode", Default = false, Callback = function(v) end })

	See example.lua for a full showcase.
]=]

--// Services
local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

--============================================================================--
--  THEME  — every color / size token extracted from the original GUI
--============================================================================--
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
	InnerHover    = Color3.fromRGB(41, 41, 41),

	Section       = Color3.fromRGB(11, 11, 11),
	SectionBorder = Color3.fromRGB(31, 31, 31),

	Text          = Color3.fromRGB(201, 201, 201),
	TextDim       = Color3.fromRGB(151, 151, 151),
	TextBright    = Color3.fromRGB(255, 255, 255),
	Black         = Color3.fromRGB(0, 0, 0),

	Font          = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
	TextSize      = 10,
	TitleSize     = 15,

	CornerElement = UDim.new(0, 5),
	CornerMenu    = UDim.new(0, 10),
}

--============================================================================--
--  LOW-LEVEL HELPERS  — the building blocks the whole library shares
--============================================================================--
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

-- The signature "double-bordered inset" panel used everywhere in the original.
-- Returns { Root, Border, Content } so callers only ever touch .Content.
local function bordered(props)
	props = props or {}
	local root = create("Frame", {
		BackgroundColor3 = props.Fill or Theme.OuterFill,
		Size = props.Size or UDim2.new(1, 0, 1, 0),
		Position = props.Position or UDim2.new(0, 0, 0, 0),
		ZIndex = props.ZIndex or 1,
		BorderSizePixel = 0,
	}, { corner(props.Corner) })

	create("Frame", {
		Name = "Border",
		BackgroundColor3 = props.Border or Theme.OuterBorder,
		Size = UDim2.new(1, 2, 1, 2),
		Position = UDim2.new(0, -1, 0, -1),
		ZIndex = (props.ZIndex or 1) - 1,
		BorderSizePixel = 0,
		Parent = root,
	}, { corner(props.Corner) })

	local content = create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		ZIndex = props.ZIndex or 1,
		Parent = root,
	})

	return { Root = root, Content = content }
end

-- White hairline stroke overlay ("Outline") drawn on top of elements.
local function outline(parent, zindex)
	local o = create("Frame", {
		Name = "Outline",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, -2, 1, -2),
		Position = UDim2.new(0, 1, 0, 1),
		ZIndex = zindex or 100,
		Parent = parent,
	}, {
		corner(),
		create("UIStroke", {
			Transparency = 0.9,
			Thickness = 0.5,
			Color = Theme.TextBright,
		}),
	})
	return o
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

--============================================================================--
--  LIBRARY ROOT
--============================================================================--
local ProGui = {}
ProGui.__index = ProGui
ProGui.Theme = Theme
ProGui.Flags = {}          -- flag -> current value (for config saving)
ProGui._windows = {}

local function mountScreenGui(name)
	local gui = create("ScreenGui", {
		Name = name or "ProGui",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Global,
		IgnoreGuiInset = true,
	})
	-- Executors: try the safest parent available.
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

--============================================================================--
--  DRAGGING
--============================================================================--
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

--============================================================================--
--  NOTIFICATIONS
--============================================================================--
function ProGui:_initNotifications(screen)
	self._notifyHolder = create("Frame", {
		Name = "Notifications",
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -12, 1, -12),
		Size = UDim2.new(0, 250, 1, -24),
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

	local panel = bordered({ Fill = Theme.OuterFill, Border = Theme.OuterBorder, ZIndex = 501 })
	panel.Root.Size = UDim2.new(1, 0, 0, 46)
	panel.Root.BackgroundTransparency = 1
	panel.Root.Parent = self._notifyHolder

	local inner = bordered({ Fill = Theme.InnerFill, Border = Theme.Accent, ZIndex = 503 })
	inner.Root.Size = UDim2.new(1, 0, 1, 0)
	inner.Root.Parent = panel.Content

	local accent = create("Frame", {
		BackgroundColor3 = Theme.Accent,
		Size = UDim2.new(0, 3, 1, -8),
		Position = UDim2.new(0, 4, 0, 4),
		ZIndex = 505,
		BorderSizePixel = 0,
		Parent = inner.Content,
	}, { corner(UDim.new(1, 0)) })

	label({
		Parent = inner.Content, Text = title, Color = Theme.TextBright,
		TextSize = 12, ZIndex = 505,
		Position = UDim2.new(0, 12, 0, 4), Size = UDim2.new(1, -16, 0, 16),
	})
	label({
		Parent = inner.Content, Text = text, Color = Theme.TextDim, ZIndex = 505,
		Position = UDim2.new(0, 12, 0, 22), Size = UDim2.new(1, -16, 0, 18),
	})

	-- slide/fade in
	panel.Root.Position = UDim2.new(1, 0, 0, 0)
	tween(panel.Root, 0.25, { Position = UDim2.new(0, 0, 0, 0) })

	task.delay(duration, function()
		if panel.Root and panel.Root.Parent then
			tween(panel.Root, 0.25, { Position = UDim2.new(1, 20, 0, 0) })
			task.wait(0.26)
			panel.Root:Destroy()
		end
	end)
end

--============================================================================--
--  WINDOW
--============================================================================--
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

	-- Root menu panel (double bordered + shadow), size from original: 500x300
	local size = opts.Size or UDim2.new(0, 500, 0, 300)
	local menu = create("Frame", {
		Name = "Menu",
		BackgroundColor3 = Theme.Background,
		Size = size,
		Position = opts.Position or UDim2.new(0.5, -250, 0.5, -150),
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
		Size = UDim2.new(1, 5, 1, 5), Position = UDim2.new(0, -2, 0, -2),
		BackgroundTransparency = 0.8, BorderSizePixel = 0, Parent = menu,
	}, { corner(Theme.CornerMenu) })

	-- Topbar
	local topWrap = bordered({
		Fill = Theme.Topbar, Border = Theme.TopbarBorder, ZIndex = 5,
	})
	topWrap.Root.Size = UDim2.new(1, -10, 0, 25)
	topWrap.Root.Position = UDim2.new(0, 5, 0, 5)
	topWrap.Root.Parent = menu

	label({
		Parent = topWrap.Content, Text = opts.Title or "ProGui",
		TextSize = Theme.TitleSize, ZIndex = 6,
		Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
	})
	label({
		Parent = topWrap.Content, Text = opts.Subtitle or "",
		Color = Theme.TextDim, XAlign = Enum.TextXAlignment.Right, ZIndex = 6,
		Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -28, 1, 0),
	})

	local closeBtn = create("TextButton", {
		Name = "Close", BackgroundTransparency = 1, Text = "✕",
		FontFace = Theme.Font, TextSize = 14, TextColor3 = Theme.TextDim,
		Size = UDim2.new(0, 18, 0, 18), Position = UDim2.new(1, -20, 0, 3),
		ZIndex = 7, Parent = topWrap.Content,
	})
	closeBtn.MouseEnter:Connect(function() tween(closeBtn, 0.1, { TextColor3 = Color3.fromRGB(255, 80, 80) }) end)
	closeBtn.MouseLeave:Connect(function() tween(closeBtn, 0.1, { TextColor3 = Theme.TextDim }) end)

	-- Tab sidebar (left column, from original: 35px wide)
	local sideWrap = bordered({
		Fill = Theme.Topbar, Border = Theme.TopbarBorder, ZIndex = 5,
	})
	sideWrap.Root.Size = UDim2.new(0, 35, 1, -40)
	sideWrap.Root.Position = UDim2.new(0, 5, 0, 35)
	sideWrap.Root.Parent = menu

	local tabList = create("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, -6, 1, -6),
		Position = UDim2.new(0, 3, 0, 3), ZIndex = 6, Parent = sideWrap.Content,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 5),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	-- Tab content area (right of sidebar)
	local pageHolder = create("Frame", {
		Name = "Pages", BackgroundTransparency = 1,
		Size = UDim2.new(1, -55, 1, -40),
		Position = UDim2.new(0, 45, 0, 35), ZIndex = 5, Parent = menu,
	})

	makeDraggable(menu, topWrap.Root)

	local self_w = setmetatable({
		Lib = self,
		Screen = screen,
		Menu = menu,
		TabList = tabList,
		PageHolder = pageHolder,
		Tabs = {},
		_activeTab = nil,
		_toggleKey = opts.ToggleKey or Enum.KeyCode.RightShift,
	}, Window)

	closeBtn.MouseButton1Click:Connect(function()
		self_w:Toggle()
	end)

	-- global toggle keybind
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
	self.Menu.Visible = not self.Menu.Visible
end

function Window:Notify(opts)
	return self.Lib:Notify(opts)
end

function Window:Destroy()
	self.Screen:Destroy()
end

--============================================================================--
--  TAB
--============================================================================--
local Tab = {}
Tab.__index = Tab

function Window:AddTab(opts)
	opts = opts or {}

	-- Tab button (icon) in the sidebar
	local btnWrap = bordered({ Fill = Theme.OuterFill, Border = Theme.OuterBorder, ZIndex = 7 })
	btnWrap.Root.Size = UDim2.new(0, 27, 0, 27)
	btnWrap.Root.Parent = self.TabList

	local btn = create("ImageButton", {
		BackgroundTransparency = 1,
		Image = opts.Icon or "",
		ImageColor3 = Theme.TextDim,
		Size = UDim2.new(0, 16, 0, 16),
		Position = UDim2.new(0.5, -8, 0.5, -8),
		ZIndex = 9, Parent = btnWrap.Content,
	})
	-- fallback text if no icon provided
	if not opts.Icon or opts.Icon == "" then
		btn.Image = ""
		local t = label({
			Parent = btnWrap.Content, Text = (opts.Name or "T"):sub(1, 1),
			XAlign = Enum.TextXAlignment.Center, ZIndex = 9,
			TextSize = 12, Size = UDim2.new(1, 0, 1, 0),
		})
		t.TextColor3 = Theme.TextDim
		btn._letter = t
	end

	-- Page (scrolling column of sections)
	local page = create("ScrollingFrame", {
		Name = (opts.Name or "Tab") .. "_page",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		Visible = false, ZIndex = 5, Parent = self.PageHolder,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	local tabObj = setmetatable({
		Window = self, Lib = self.Lib,
		Button = btn, ButtonWrap = btnWrap, Page = page, Name = opts.Name,
	}, Tab)

	local function select()
		if self._activeTab == tabObj then return end
		if self._activeTab then
			self._activeTab.Page.Visible = false
			tween(self._activeTab.ButtonWrap.Root, 0.15, { BackgroundColor3 = Theme.OuterFill })
			tween(self._activeTab.Button, 0.15, { ImageColor3 = Theme.TextDim })
			if self._activeTab.Button._letter then
				tween(self._activeTab.Button._letter, 0.15, { TextColor3 = Theme.TextDim })
			end
		end
		self._activeTab = tabObj
		page.Visible = true
		tween(btnWrap.Root, 0.15, { BackgroundColor3 = Theme.AccentBg })
		tween(btn, 0.15, { ImageColor3 = Theme.Accent })
		if btn._letter then tween(btn._letter, 0.15, { TextColor3 = Theme.TextBright }) end
	end

	btn.MouseButton1Click:Connect(select)
	table.insert(self.Tabs, tabObj)
	if not self._activeTab then select() end
	return tabObj
end

--============================================================================--
--  SECTION  — a titled container that holds elements
--============================================================================--
local Section = {}
Section.__index = Section

function Tab:AddSection(opts)
	opts = opts or {}

	local wrap = bordered({ Fill = Theme.Section, Border = Theme.SectionBorder, ZIndex = 8 })
	wrap.Root.Size = UDim2.new(1, -3, 0, 30)   -- height grows via AutomaticSize
	wrap.Root.AutomaticSize = Enum.AutomaticSize.Y
	wrap.Root.Parent = self.Page

	-- Title bar
	label({
		Parent = wrap.Content, Text = opts.Name or "Section",
		Color = Theme.TextBright, TextSize = 11, ZIndex = 9,
		Position = UDim2.new(0, 8, 0, 4), Size = UDim2.new(1, -16, 0, 16),
	})

	local elements = create("Frame", {
		Name = "Elements", BackgroundTransparency = 1,
		Size = UDim2.new(1, -10, 0, 0), Position = UDim2.new(0, 5, 0, 24),
		AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 9, Parent = wrap.Content,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 5), SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		create("UIPadding", { PaddingBottom = UDim.new(0, 6) }),
	})

	return setmetatable({
		Tab = self, Lib = self.Lib, Root = wrap.Root, Holder = elements,
	}, Section)
end

--============================================================================--
--  ELEMENT BASE  — every control sits inside this double-bordered row
--============================================================================--
-- Returns { Wrap, Content } where Content is Theme.InnerFill inner frame.
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

--============================================================================--
--  LABEL
--============================================================================--
function Section:AddLabel(opts)
	opts = opts or {}
	local row = self:_row(opts.Height or 20)
	local txt = label({
		Parent = row.Content, Text = opts.Text or "Label",
		ZIndex = 14, Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(1, -12, 1, 0),
	})
	return {
		SetText = function(_, t) txt.Text = t end,
		Instance = row.Wrap,
	}
end

--============================================================================--
--  BUTTON
--============================================================================--
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
	hit.MouseEnter:Connect(function() tween(row.Content.Parent, 0.12, { BackgroundColor3 = Theme.InnerHover }) end)
	hit.MouseLeave:Connect(function() tween(row.Content.Parent, 0.12, { BackgroundColor3 = Theme.InnerFill }) end)
	hit.MouseButton1Click:Connect(function()
		tween(row.Content.Parent, 0.08, { BackgroundColor3 = Theme.Accent })
		task.wait(0.08)
		tween(row.Content.Parent, 0.12, { BackgroundColor3 = Theme.InnerFill })
		if opts.Callback then task.spawn(opts.Callback) end
	end)
	return { Instance = row.Wrap }
end

--============================================================================--
--  TOGGLE  — pill 30x14 with 12x12 dot, from original
--============================================================================--
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

	function api:Set(v) state = v and true or false; apply(true) end
	function api:Get() return state end
	api.Instance = row.Wrap
	return api
end

--============================================================================--
--  SLIDER
--============================================================================--
function Section:AddSlider(opts)
	opts = opts or {}
	local min   = opts.Min or 0
	local max   = opts.Max or 100
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

	-- track
	local track = create("Frame", {
		BackgroundColor3 = Theme.OuterFill, BorderSizePixel = 0,
		Size = UDim2.new(1, -12, 0, 6), Position = UDim2.new(0, 6, 1, -12),
		ZIndex = 14, Parent = row.Content,
	}, { corner(UDim.new(1, 0)) })

	local fill = create("Frame", {
		Name = "Fill", BackgroundColor3 = Theme.Accent, BorderSizePixel = 0,
		Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
		ZIndex = 15, Parent = track,
	}, { corner(UDim.new(1, 0)) })

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

	function api:Set(v) setFromScale((math.clamp(v, min, max) - min) / (max - min), true) end
	function api:Get() return value end
	api.Instance = row.Wrap
	return api
end

--============================================================================--
--  DROPDOWN
--============================================================================--
function Section:AddDropdown(opts)
	opts = opts or {}
	local options = opts.Options or {}
	local multi = opts.Multi or false
	local selected = multi and (opts.Default or {}) or (opts.Default or (options[1]))

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
		Parent = row.Content, Text = "▼", Color = Theme.TextDim,
		XAlign = Enum.TextXAlignment.Center, ZIndex = 14,
		Position = UDim2.new(1, -16, 0, 0), Size = UDim2.new(0, 14, 1, 0),
	})
	arrow.TextSize = 8

	-- expandable list rendered inside the row's outer wrapper
	local listWrap = bordered({ Fill = Theme.OuterFill, Border = Theme.OuterBorder, ZIndex = 60 })
	listWrap.Root.Size = UDim2.new(1, 0, 0, 0)
	listWrap.Root.Position = UDim2.new(0, 0, 1, 3)
	listWrap.Root.Visible = false
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

	local function refresh()
		valLabel.Text = displayText()
		for opt, b in pairs(optButtons) do
			b.TextColor3 = isSelected(opt) and Theme.Accent or Theme.Text
		end
		registerFlag(self.Lib, opts.Flag, selected)
		if opts.Callback then task.spawn(opts.Callback, selected) end
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
					selected[opt] = not selected[opt] or nil
				else
					selected = opt
					setOpen(false)
				end
				refresh()
			end)
			optButtons[opt] = b
		end
	end

	hit.MouseButton1Click:Connect(function() setOpen(not open) end)
	rebuild()

	function api:Set(v) selected = v; refresh() end
	function api:Get() return selected end
	function api:Refresh(newOpts) options = newOpts or options; rebuild() end
	api.Instance = row.Wrap
	return api
end

--============================================================================--
--  KEYBIND
--============================================================================--
function Section:AddKeybind(opts)
	opts = opts or {}
	local key = opts.Default
	local row = self:_row(20)

	label({
		Parent = row.Content, Text = opts.Name or "Keybind",
		ZIndex = 14, Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(1, -80, 1, 0),
	})

	local box = create("TextButton", {
		BackgroundColor3 = Theme.OuterFill, BorderSizePixel = 0,
		AutoButtonColor = false, FontFace = Theme.Font, TextSize = Theme.TextSize,
		TextColor3 = Theme.TextDim,
		Text = key and key.Name or "...",
		Size = UDim2.new(0, 60, 0, 14), Position = UDim2.new(1, -66, 0.5, -7),
		ZIndex = 15, Parent = row.Content,
	}, { corner() })

	local listening = false
	box.MouseButton1Click:Connect(function()
		listening = true
		box.Text = "..."
		box.TextColor3 = Theme.Accent
	end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			listening = false
			if input.KeyCode == Enum.KeyCode.Escape then
				key = nil; box.Text = "..."
			else
				key = input.KeyCode; box.Text = key.Name
			end
			box.TextColor3 = Theme.TextDim
			registerFlag(self.Lib, opts.Flag, key)
			if opts.Changed then task.spawn(opts.Changed, key) end
		elseif not listening and key and input.KeyCode == key and not gpe then
			if opts.Callback then task.spawn(opts.Callback) end
		end
	end)

	return {
		Set = function(_, k) key = k; box.Text = k and k.Name or "..." end,
		Get = function() return key end,
		Instance = row.Wrap,
	}
end

--============================================================================--
--  TEXTBOX
--============================================================================--
function Section:AddTextBox(opts)
	opts = opts or {}
	local row = self:_row(20)

	label({
		Parent = row.Content, Text = opts.Name or "Input",
		ZIndex = 14, Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(0.4, -6, 1, 0),
	})

	local box = create("TextBox", {
		BackgroundColor3 = Theme.OuterFill, BorderSizePixel = 0,
		FontFace = Theme.Font, TextSize = Theme.TextSize, TextColor3 = Theme.Text,
		PlaceholderText = opts.Placeholder or "", PlaceholderColor3 = Theme.TextDim,
		Text = opts.Default or "", ClearTextOnFocus = false,
		Size = UDim2.new(0.6, -10, 0, 14), Position = UDim2.new(0.4, 0, 0.5, -7),
		ZIndex = 15, Parent = row.Content,
	}, { corner(), create("UIPadding", { PaddingLeft = UDim.new(0, 5), PaddingRight = UDim.new(0, 5) }) })

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

--============================================================================--
--  COLORPICKER
--============================================================================--
function Section:AddColorPicker(opts)
	opts = opts or {}
	local color = opts.Default or Color3.fromRGB(101, 101, 201)
	local h, s, v = color:ToHSV()

	local row = self:_row(20)

	label({
		Parent = row.Content, Text = opts.Name or "Color",
		ZIndex = 14, Position = UDim2.new(0, 6, 0, 0), Size = UDim2.new(1, -40, 1, 0),
	})

	local preview = create("TextButton", {
		BackgroundColor3 = color, BorderSizePixel = 0, Text = "", AutoButtonColor = false,
		Size = UDim2.new(0, 28, 0, 14), Position = UDim2.new(1, -34, 0.5, -7),
		ZIndex = 15, Parent = row.Content,
	}, { corner() })

	-- popup panel
	local panel = bordered({ Fill = Theme.OuterFill, Border = Theme.OuterBorder, ZIndex = 70 })
	panel.Root.Size = UDim2.new(0, 160, 0, 130)
	panel.Root.Position = UDim2.new(1, -160, 1, 3)
	panel.Root.Visible = false
	panel.Root.Parent = row.Wrap

	-- Saturation/Value square
	local satBox = create("ImageLabel", {
		Image = "rbxassetid://4155801252", -- white->transparent gradient sat/val map
		BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0,
		Size = UDim2.new(1, -14, 0, 90), Position = UDim2.new(0, 7, 0, 7),
		ZIndex = 71, Parent = panel.Content,
	}, { corner() })
	local satCursor = create("Frame", {
		BackgroundColor3 = Theme.TextBright, BorderSizePixel = 0,
		Size = UDim2.new(0, 4, 0, 4), AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 72, Parent = satBox,
	}, { corner(UDim.new(1, 0)) })

	-- Hue bar
	local hueBar = create("Frame", {
		BorderSizePixel = 0, Size = UDim2.new(1, -14, 0, 10),
		Position = UDim2.new(0, 7, 0, 104), ZIndex = 71, Parent = panel.Content,
	}, {
		corner(),
		create("UIGradient", {
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255,0,0)),
				ColorSequenceKeypoint.new(0.17, Color3.fromRGB(255,255,0)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(0,255,0)),
				ColorSequenceKeypoint.new(0.50, Color3.fromRGB(0,255,255)),
				ColorSequenceKeypoint.new(0.67, Color3.fromRGB(0,0,255)),
				ColorSequenceKeypoint.new(0.83, Color3.fromRGB(255,0,255)),
				ColorSequenceKeypoint.new(1.00, Color3.fromRGB(255,0,0)),
			}),
		}),
	})
	local hueCursor = create("Frame", {
		BackgroundColor3 = Theme.TextBright, BorderSizePixel = 0,
		Size = UDim2.new(0, 2, 1, 2), Position = UDim2.new(h, -1, 0, -1),
		ZIndex = 72, Parent = hueBar,
	})

	local function apply(fire)
		color = Color3.fromHSV(h, s, v)
		preview.BackgroundColor3 = color
		satBox.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
		satCursor.Position = UDim2.new(s, 0, 1 - v, 0)
		hueCursor.Position = UDim2.new(h, -1, 0, -1)
		registerFlag(self.Lib, opts.Flag, color)
		if fire and opts.Callback then task.spawn(opts.Callback, color) end
	end
	apply(false)

	local function bindDrag(guiObj, onMove)
		local dragging = false
		guiObj.InputBegan:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then
				dragging = true; onMove(input)
			end
		end)
		UserInputService.InputChanged:Connect(function(input)
			if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then onMove(input) end
		end)
		UserInputService.InputEnded:Connect(function(input)
			if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
		end)
	end

	bindDrag(satBox, function(input)
		s = math.clamp((input.Position.X - satBox.AbsolutePosition.X) / satBox.AbsoluteSize.X, 0, 1)
		v = 1 - math.clamp((input.Position.Y - satBox.AbsolutePosition.Y) / satBox.AbsoluteSize.Y, 0, 1)
		apply(true)
	end)
	bindDrag(hueBar, function(input)
		h = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
		apply(true)
	end)

	preview.MouseButton1Click:Connect(function()
		panel.Root.Visible = not panel.Root.Visible
		row.Wrap.ZIndex = panel.Root.Visible and 200 or 11
	end)

	return {
		Set = function(_, c) h, s, v = c:ToHSV(); apply(true) end,
		Get = function() return color end,
		Instance = row.Wrap,
	}
end

--============================================================================--
--  DIVIDER
--============================================================================--
function Section:AddDivider()
	local line = create("Frame", {
		BackgroundColor3 = Theme.OuterBorder, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 1), ZIndex = 11, Parent = self.Holder,
	})
	return { Instance = line }
end

--============================================================================--
--  CONFIG  (flag get/set helpers)
--============================================================================--
function ProGui:GetFlags()
	return self.Flags
end

function ProGui:GetFlag(name)
	return self.Flags[name]
end

return ProGui
