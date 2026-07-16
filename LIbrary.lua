local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local RunService        = game:GetService("RunService")
local CoreGui           = game:GetService("CoreGui")
local HttpService       = game:GetService("HttpService")
local GuiService        = game:GetService("GuiService")

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

	SectionOuterB = Color3.fromRGB(26, 26, 26),
	Section       = Color3.fromRGB(21, 21, 21),
	SectionBorder = Color3.fromRGB(48, 48, 48),
	PageBorder    = Color3.fromRGB(41, 41, 41),
	Divider       = Color3.fromRGB(151, 151, 151),

	Text          = Color3.fromRGB(201, 201, 201),
	TextDim       = Color3.fromRGB(151, 151, 151),
	TabInactive   = Color3.fromRGB(101, 101, 101),
	TabActive     = Color3.fromRGB(201, 201, 201),
	TextBright    = Color3.fromRGB(255, 255, 255),
	Black         = Color3.fromRGB(0, 0, 0),

	Font          = Font.new("rbxasset://fonts/families/Ubuntu.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
	TextSize      = 11,
	TitleSize     = 14,
	SectionSize   = 13,

	CornerElement = UDim.new(0, 5),
	CornerMenu    = UDim.new(0, 10),
	CornerSmall   = UDim.new(0, 4),
}

-- Central spacing grid. Every gap/padding/height in the library references this
-- table so the whole UI stays on one rhythm and can be retuned from one place.
local Layout = {
	RowH        = 24,   -- default control row height
	SliderH     = 34,   -- slider row (label + track)
	DropH       = 42,   -- dropdown bar row (label + closed bar)
	Gap         = 6,    -- gap between elements inside a section
	Pad         = 7,    -- section inner horizontal padding
	PadTop      = 27,   -- first element offset (below title + divider)
	SectionGap  = 7,    -- gap between stacked sections
	ColGap      = 7,    -- gap between columns
	PagePad     = 6,    -- inset inside the page panel
	TitleH      = 21,   -- section title band height
	SideW       = 35,   -- sidebar width
}

-- Tween durations. Kept short so the interface reads as instant; hover/press
-- micro-interactions use Fast, state changes use Base, settles use Slow.
local Anim = {
	Fast = 0.08,
	Base = 0.12,
	Slow = 0.16,
}

local Icons = {
	Eye      = "rbxassetid://130003477074963",
	Info     = "rbxassetid://14179359804",
	Gear     = "rbxassetid://14179228816",
	Location = "rbxassetid://14179041224",
	Settings = "rbxassetid://89833573786776",
	Cursor   = "rbxassetid://126503880099777",
	Chevron  = "rbxassetid://129817406781405",
	Lock     = "rbxassetid://117626470163415",
	Pin      = "rbxassetid://101812386473600",
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

-- Forces an element to scale about its own centre so UIScale animations
-- (press/bounce) grow evenly on every side instead of from the top-left.
local function centerAnchor(inst)
	if inst:GetAttribute("_centered") then return end
	inst:SetAttribute("_centered", true)
	-- Elements already anchored elsewhere (e.g. a 0.5,0.5 slider handle) are
	-- left as-is; re-centering them would shift their position by half a size.
	if inst.AnchorPoint.X ~= 0 or inst.AnchorPoint.Y ~= 0 then return end
	local pos, size = inst.Position, inst.Size
	inst.AnchorPoint = Vector2.new(0.5, 0.5)
	inst.Position = UDim2.new(
		pos.X.Scale + size.X.Scale / 2, pos.X.Offset + size.X.Offset / 2,
		pos.Y.Scale + size.Y.Scale / 2, pos.Y.Offset + size.Y.Offset / 2
	)
end

-- Ensures a UIScale on inst and plays a subtle press-then-bounce animation.
-- The element is re-anchored to its centre so the bounce is symmetrical.
local function pressBounce(inst, downScale)
	centerAnchor(inst)
	local ui = inst:FindFirstChildOfClass("UIScale")
	if not ui then
		ui = Instance.new("UIScale")
		ui.Scale = 1
		ui.Parent = inst
	end
	downScale = downScale or 0.92
	tween(ui, Anim.Fast, { Scale = downScale }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	task.delay(Anim.Fast, function()
		if ui.Parent then
			tween(ui, 0.22, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end
	end)
end

-- Subtle hover lift: the control eases a couple of pixels upward on hover and
-- settles back on leave. Position is captured lazily so callers don't need to
-- pass it in, and the base is stored on an attribute to survive repeat hovers.
local function hoverLift(inst, amount)
	amount = amount or 2
	-- Settle the anchor up front so the lift baseline matches whatever a later
	-- pressBounce would use, avoiding a one-frame jump on the first click.
	centerAnchor(inst)
	local function baseY()
		local stored = inst:GetAttribute("_liftBaseY")
		if stored == nil then
			stored = inst.Position.Y.Offset
			inst:SetAttribute("_liftBaseY", stored)
		end
		return stored
	end
	inst.MouseEnter:Connect(function()
		local p = inst.Position
		tween(inst, Anim.Fast, { Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, baseY() - amount) })
	end)
	inst.MouseLeave:Connect(function()
		local p = inst.Position
		tween(inst, Anim.Base, { Position = UDim2.new(p.X.Scale, p.X.Offset, p.Y.Scale, baseY()) })
	end)
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
		create("UIStroke", { Transparency = 0.97, Thickness = 0.5, Color = Theme.TextBright }),
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
ProGui.Icons = Icons
ProGui.Flags = {}
ProGui._windows = {}
ProGui._accentObjects = {}

local function shade(color, factor)
	return Color3.new(color.R * factor, color.G * factor, color.B * factor)
end

local function accentShade(name)
	if name == "dark" then return shade(Theme.Accent, 0.5) end
	if name == "bg" then return shade(Theme.Accent, 0.259) end
	return Theme.Accent
end

function ProGui:_bindAccent(inst, prop, variant)
	table.insert(self._accentObjects, { inst = inst, prop = prop, variant = variant })
	inst[prop] = accentShade(variant)
end

function ProGui:SetAccent(color)
	Theme.Accent = color
	Theme.AccentDark = shade(color, 0.5)
	Theme.AccentBg = shade(color, 0.259)
	Theme.AccentHover = shade(color, 1.2)
	for _, entry in ipairs(self._accentObjects) do
		if entry.inst and entry.inst.Parent then
			entry.inst[entry.prop] = accentShade(entry.variant)
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

-- ---------------------------------------------------------------------------
-- Context menu
--
-- A single reusable right-click popup lives per-window. Callers describe menu
-- entries as plain data (a list of { Label, Icon?, Callback?, Divider? }) so new
-- actions are added by pushing another table entry — no bespoke UI code. Entries
-- can be given as a static list or a function returning one (evaluated per open,
-- so menus can reflect current state). Nil/false entries are skipped, letting
-- callers conditionally include actions inline.
-- ---------------------------------------------------------------------------

local CONTEXT_W = 150
local CONTEXT_ITEM_H = 22

local function resolveContextItems(items, ...)
	if type(items) == "function" then items = items(...) end
	local out = {}
	for _, it in ipairs(items or {}) do
		if it then table.insert(out, it) end
	end
	return out
end

function ProGui:_initContextMenu(screen)
	-- Full-screen catcher: one transparent button under the popup closes it on
	-- any outside click without each menu wiring its own global input listener.
	local holder = create("TextButton", {
		Name = "ContextLayer", Text = "", AutoButtonColor = false,
		BackgroundTransparency = 1, Visible = false,
		Size = UDim2.new(1, 0, 1, 0), ZIndex = 600, Parent = screen,
	})
	local panel = bordered({ Fill = Theme.Topbar, Border = Theme.TopbarBorder, ZIndex = 602 })
	panel.Root.Size = UDim2.new(0, CONTEXT_W, 0, 0)
	panel.Root.AutomaticSize = Enum.AutomaticSize.Y
	panel.Root.Visible = false
	panel.Root.Parent = holder
	outline(panel.Content, 601)

	local list = create("Frame", {
		Name = "Items", BackgroundTransparency = 1,
		Size = UDim2.new(1, -6, 0, 0), Position = UDim2.new(0, 3, 0, 3),
		AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 603, Parent = panel.Content,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
	})

	self._context = { Holder = holder, Panel = panel.Root, List = list }
	holder.MouseButton1Click:Connect(function() self:_hideContextMenu() end)
	holder.MouseButton2Click:Connect(function() self:_hideContextMenu() end)
end

function ProGui:_hideContextMenu()
	local ctx = self._context
	if not ctx then return end
	ctx.Holder.Visible = false
	ctx.Panel.Visible = false
end

-- Opens the shared popup at (x, y) built from `items`. Anchors so the menu never
-- spills off the right/bottom edge of the screen.
function ProGui:_showContextMenu(items, x, y)
	local ctx = self._context
	if not ctx then return end
	for _, c in ipairs(ctx.List:GetChildren()) do
		if not c:IsA("UIListLayout") then c:Destroy() end
	end

	local order = 0
	local count = 0
	for _, item in ipairs(items) do
		order += 1
		if item.Divider then
			create("Frame", {
				Name = "Divider", BorderSizePixel = 0, BackgroundColor3 = Theme.TopbarBorder,
				Size = UDim2.new(1, -8, 0, 1), Position = UDim2.new(0, 4, 0, 0),
				LayoutOrder = order, ZIndex = 603, Parent = ctx.List,
			})
		else
			count += 1
			local entry = create("TextButton", {
				Name = "Item", AutoButtonColor = false, BackgroundColor3 = Theme.Topbar,
				BackgroundTransparency = 1, BorderSizePixel = 0, Text = "",
				Size = UDim2.new(1, 0, 0, CONTEXT_ITEM_H), LayoutOrder = order,
				ZIndex = 603, Parent = ctx.List,
			}, { corner(Theme.CornerSmall) })

			local hasIcon = item.Icon and item.Icon ~= ""
			if hasIcon then
				create("ImageLabel", {
					BackgroundTransparency = 1, Image = item.Icon, ImageColor3 = Theme.TextDim,
					Size = UDim2.new(0, 12, 0, 12), Position = UDim2.new(0, 7, 0.5, -6),
					ZIndex = 604, Parent = entry,
				})
			end
			label({
				Parent = entry, Text = tostring(item.Label or "Action"),
				Color = item.Color or Theme.Text, ZIndex = 604,
				Position = UDim2.new(0, hasIcon and 24 or 9, 0, 0), Size = UDim2.new(1, hasIcon and -28 or -13, 1, 0),
			})

			entry.MouseEnter:Connect(function()
				tween(entry, Anim.Fast, { BackgroundTransparency = 0 })
			end)
			entry.MouseLeave:Connect(function()
				tween(entry, Anim.Fast, { BackgroundTransparency = 1 })
			end)
			entry.MouseButton1Click:Connect(function()
				self:_hideContextMenu()
				if item.Callback then task.spawn(item.Callback) end
			end)
		end
	end

	if count == 0 then return end

	-- Clamp to screen so the popup is always fully visible.
	local screenSize = ctx.Holder.AbsoluteSize
	local estH = count * CONTEXT_ITEM_H + (order - 1) * 2 + 6
	if x + CONTEXT_W > screenSize.X then x = screenSize.X - CONTEXT_W - 4 end
	if y + estH > screenSize.Y then y = math.max(4, screenSize.Y - estH - 4) end

	ctx.Panel.Position = UDim2.new(0, x, 0, y)
	ctx.Holder.Visible = true
	ctx.Panel.Visible = true

	-- Grow-in from the anchor for a light, quick reveal.
	local scale = ctx.Panel:FindFirstChildOfClass("UIScale") or create("UIScale", { Parent = ctx.Panel })
	ctx.Panel.AnchorPoint = Vector2.new(0, 0)
	scale.Scale = 0.9
	tween(scale, Anim.Base, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

-- Wires right-click on `inst` to open the shared menu. `itemsProvider` is the
-- data list (or a function returning one) described in the section comment.
function ProGui:_attachContextMenu(inst, itemsProvider)
	-- InputBegan (not MouseButton2Click) so this works on any GuiObject, not just
	-- GuiButtons — callers can attach a menu to a plain Frame's .Instance.
	inst.InputBegan:Connect(function(input)
		if input.UserInputType ~= Enum.UserInputType.MouseButton2 then return end
		local items = resolveContextItems(itemsProvider)
		if #items == 0 then return end
		local inset = GuiService:GetGuiInset()
		local m = UserInputService:GetMouseLocation() + inset
		self:_showContextMenu(items, m.X, m.Y)
	end)
end

local Window = {}
Window.__index = Window

function ProGui:CreateWindow(opts)
	opts = opts or {}
	local screen = mountScreenGui(opts.Name or "ProGui")
	self:_initNotifications(screen)
	self:_initContextMenu(screen)

	local content = create("Frame", {
		Name = "Content",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = screen,
	})

	local size = opts.Size or UDim2.new(0, 500, 0, 300)
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
		Color = Theme.Text, TextSize = Theme.TitleSize, ZIndex = 6,
		Position = UDim2.new(0, 5, 0, 0), Size = UDim2.new(0.5, 0, 1, 0),
	})
	label({
		Parent = topWrap.Content, Text = opts.Subtitle or "",
		Color = Theme.TextDim, XAlign = Enum.TextXAlignment.Right, ZIndex = 6,
		Position = UDim2.new(0.5, 0, 0, 0), Size = UDim2.new(0.5, -29, 1, 0),
	})

	-- The eye keeps a fixed anchored position; the hover is a pure scale+colour
	-- pulse via a dedicated UIScale, so it never drifts off its resting spot.
	local eyeBtn = create("ImageButton", {
		Name = "Toggle", BackgroundTransparency = 1,
		Image = opts.EyeIcon or Icons.Eye,
		ImageColor3 = Theme.TextDim,
		AnchorPoint = Vector2.new(1, 0.5),
		Size = UDim2.new(0, 15, 0, 15), Position = UDim2.new(1, -6, 0.5, 0),
		ZIndex = 6, Parent = topWrap.Content,
	}, { create("UIScale", { Scale = 1 }) })
	local eyeScale = eyeBtn:FindFirstChildOfClass("UIScale")
	eyeBtn.MouseEnter:Connect(function()
		tween(eyeBtn, Anim.Fast, { ImageColor3 = Theme.TextBright })
		tween(eyeScale, Anim.Fast, { Scale = 1.15 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)
	eyeBtn.MouseLeave:Connect(function()
		tween(eyeBtn, Anim.Base, { ImageColor3 = Theme.TextDim })
		tween(eyeScale, Anim.Base, { Scale = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end)
	eyeBtn.MouseButton1Down:Connect(function()
		tween(eyeScale, Anim.Fast, { Scale = 0.85 }, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end)
	eyeBtn.MouseButton1Up:Connect(function()
		tween(eyeScale, Anim.Base, { Scale = 1.15 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end)

	local sideWrap = bordered({ Fill = Theme.Topbar, Border = Theme.TopbarBorder, ZIndex = 5 })
	sideWrap.Root.Size = UDim2.new(0, Layout.SideW, 1, -40)
	sideWrap.Root.Position = UDim2.new(0, 5, 0, 35)
	sideWrap.Root.Parent = menu

	local tabList = create("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -38),
		Position = UDim2.new(0, 0, 0, 7), ZIndex = 6, Parent = sideWrap.Content,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 7),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	-- Bottom tab group sits above the sidebar floor with a little breathing room
	-- so the settings icon reads as vertically centred in its band, not dropped.
	local bottomList = create("Frame", {
		BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 28),
		Position = UDim2.new(0, 0, 1, -33), ZIndex = 6, Parent = sideWrap.Content,
	}, {
		create("UIListLayout", {
			Padding = UDim.new(0, 7),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	})

	-- Bottom divider above the bottom tab group (gradient fade like the source).
	create("Frame", {
		Name = "Divider", ZIndex = 7, BorderSizePixel = 0,
		BackgroundColor3 = Theme.TextDim,
		Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -37),
		Parent = sideWrap.Content,
	}, {
		create("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.65),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})

	local pageWrap = bordered({ Fill = Theme.OuterFill, Border = Theme.PageBorder, ZIndex = 5 })
	pageWrap.Root.Size = UDim2.new(1, -50, 1, -40)
	pageWrap.Root.Position = UDim2.new(0, 45, 0, 35)
	pageWrap.Root.Parent = menu
	outline(pageWrap.Content, 100)

	local pageHolder = create("Frame", {
		Name = "Pages", BackgroundTransparency = 1,
		Size = UDim2.new(1, -8, 1, -8),
		Position = UDim2.new(0, 4, 0, 4), ZIndex = 6, Parent = pageWrap.Content,
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

-- Public, fully data-driven context-menu hook. Pass any GuiButton and a list
-- (or a function returning one) of { Label, Icon?, Callback?, Color?, Divider? }
-- entries; right-clicking the element opens the shared themed popup. New actions
-- are added by appending table entries — no UI code required.
function Window:AttachContextMenu(inst, items)
	self.Lib:_attachContextMenu(inst, items)
end

-- Opens a context menu programmatically at the current mouse position.
function Window:ShowContextMenu(items)
	local resolved = resolveContextItems(items)
	if #resolved == 0 then return end
	local m = UserInputService:GetMouseLocation() + GuiService:GetGuiInset()
	self.Lib:_showContextMenu(resolved, m.X, m.Y)
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

	-- Tabs are a bare 20x20 icon; the active tab is shown by icon color only.
	local tabFrame = create("Frame", {
		Name = (opts.Name or "Tab") .. "_tab",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Parent = parentList,
	})

	local btn = create("ImageButton", {
		Name = "Button", ScaleType = Enum.ScaleType.Fit,
		BackgroundTransparency = 1,
		Image = opts.Icon or "",
		ImageColor3 = Theme.TabInactive,
		Size = UDim2.new(0, 20, 0, 20),
		Position = UDim2.new(0.5, -10, 0, 0),
		ZIndex = 9, Parent = tabFrame,
	})

	local letter
	if not opts.Icon or opts.Icon == "" then
		btn.Image = ""
		letter = label({
			Parent = tabFrame, Text = (opts.Name or "T"):sub(1, 1),
			XAlign = Enum.TextXAlignment.Center, ZIndex = 9,
			TextSize = 12, Size = UDim2.new(1, 0, 1, 0),
		})
		letter.TextColor3 = Theme.TabInactive
	end

	local page = create("ScrollingFrame", {
		Name = (opts.Name or "Tab") .. "_page",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent, ScrollBarImageTransparency = 0.35,
		Visible = false, ZIndex = 5, Parent = self.PageHolder,
	})
	self.Lib:_bindAccent(page, "ScrollBarImageColor3")

	local columns = create("Frame", {
		Name = "Columns", BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 5, Parent = page,
	})

	local colCount = opts.Columns or 2
	local colFrames = {}
	create("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		Padding = UDim.new(0, Layout.ColGap),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = columns,
	})
	-- Each column takes an equal share of the row minus the inter-column gaps,
	-- so two columns always leave exactly one ColGap of breathing room between.
	local colOffset = -Layout.ColGap * (colCount - 1) / colCount
	for i = 1, colCount do
		local col = create("Frame", {
			Name = "Column" .. i, BackgroundTransparency = 1,
			Size = UDim2.new(1 / colCount, colOffset, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = i, ZIndex = 5, Parent = columns,
		}, {
			create("UIListLayout", { Padding = UDim.new(0, Layout.SectionGap), SortOrder = Enum.SortOrder.LayoutOrder }),
		})
		colFrames[i] = col
	end

	local tabObj = setmetatable({
		Window = self, Lib = self.Lib,
		Button = btn, Frame = tabFrame, Letter = letter, Page = page,
		Columns = colFrames, _nextCol = 1, Name = opts.Name,
		_bottom = opts.Bottom or false, _pinned = false, _bindKey = nil,
		_baseOrder = #(parentList:GetChildren()), _extraContext = {},
	}, Tab)
	tabFrame.LayoutOrder = tabObj._baseOrder

	local function select()
		if self._activeTab == tabObj then return end
		if self._activeTab then
			local prev = self._activeTab
			prev._active = false
			prev.Page.Visible = false
			tween(prev.Button, Anim.Base, { ImageColor3 = Theme.TabInactive })
			if prev.Letter then tween(prev.Letter, Anim.Base, { TextColor3 = Theme.TabInactive }) end
		end
		self._activeTab = tabObj
		tabObj._active = true
		page.Visible = true
		tween(btn, Anim.Base, { ImageColor3 = Theme.TabActive })
		if letter then tween(letter, Anim.Base, { TextColor3 = Theme.TabActive }) end
	end

	-- Hover: idle tabs ease gently from gray toward the active tone, back on leave.
	btn.MouseEnter:Connect(function()
		if tabObj._active then return end
		tween(btn, Anim.Slow, { ImageColor3 = Theme.Text })
		if letter then tween(letter, Anim.Slow, { TextColor3 = Theme.Text }) end
	end)
	btn.MouseLeave:Connect(function()
		if tabObj._active then return end
		tween(btn, Anim.Slow, { ImageColor3 = Theme.TabInactive })
		if letter then tween(letter, Anim.Slow, { TextColor3 = Theme.TabInactive }) end
	end)

	btn.MouseButton1Click:Connect(function()
		pressBounce(btn, 0.92)
		select()
	end)
	tabObj.Select = select

	-- Small pin dot in the corner, shown only while the tab is pinned. Pinning
	-- floats the tab to the top of its group via LayoutOrder.
	local pinDot = create("Frame", {
		Name = "Pin", BackgroundColor3 = Theme.TextBright, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(1, 0), Size = UDim2.new(0, 4, 0, 4),
		Position = UDim2.new(1, -2, 0, 1), ZIndex = 11, Visible = false, Parent = tabFrame,
	}, { corner(UDim.new(1, 0)) })
	self.Lib:_bindAccent(pinDot, "BackgroundColor3")

	function tabObj:SetPinned(v)
		self._pinned = v and true or false
		pinDot.Visible = self._pinned
		tabFrame.LayoutOrder = self._pinned and -1000 + self._baseOrder or self._baseOrder
	end

	-- Right-click actions. The first four are built-in; anything registered via
	-- tab:AddContextAction(...) is appended, so callers extend the menu with data.
	local function contextItems()
		local items = {
			{
				Label = tabObj._pinned and "Unpin tab" or "Pin tab", Icon = Icons.Pin,
				Callback = function() tabObj:SetPinned(not tabObj._pinned) end,
			},
			{
				Label = "Add keybind", Icon = Icons.Gear,
				Callback = function() tabObj:_listenBind() end,
			},
			{
				Label = "Copy identifier",
				Callback = function()
					local id = tostring(tabObj.Name or "tab")
					if setclipboard then pcall(setclipboard, id) end
					self:Notify({ Title = "Copied", Text = id })
				end,
			},
			{ Divider = true },
			{ Label = "Select tab", Callback = select },
		}
		for _, extra in ipairs(tabObj._extraContext) do
			table.insert(items, extra)
		end
		return items
	end
	self.Lib:_attachContextMenu(btn, contextItems)

	-- Optional per-tab keybind that selects the tab (and shows the window if
	-- hidden). Listens for the next key press after "Add keybind" is chosen.
	function tabObj:_listenBind()
		self._listening = true
		self.Window:Notify({ Title = "Keybind", Text = "Press a key for " .. tostring(self.Name) })
	end
	UserInputService.InputBegan:Connect(function(input, gpe)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if tabObj._listening then
			tabObj._listening = false
			if input.KeyCode == Enum.KeyCode.Escape then
				tabObj._bindKey = nil
			else
				tabObj._bindKey = input.KeyCode
				self:Notify({ Title = "Keybind", Text = tostring(input.KeyCode.Name) .. " → " .. tostring(tabObj.Name) })
			end
		elseif not gpe and tabObj._bindKey and input.KeyCode == tabObj._bindKey then
			if not self._visible then self:Toggle() end
			select()
		end
	end)

	-- Data-driven extension point: push another entry onto the tab's menu.
	function tabObj:AddContextAction(item)
		table.insert(self._extraContext, item)
	end

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

	-- One crisp border ring (a single UIStroke) keeps every corner perfectly
	-- merged and the outline uniformly visible at any size — the old stacked
	-- border frames drifted at the corners because their radius didn't scale.
	local root = create("Frame", {
		Name = "Section", BackgroundColor3 = Theme.Section, BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 34), AutomaticSize = Enum.AutomaticSize.Y,
		ZIndex = 9, Parent = col,
	}, {
		corner(),
		create("UIStroke", { Thickness = 1, Color = Theme.SectionBorder, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
	})

	label({
		Parent = root, Text = opts.Name or "Section",
		Color = Theme.Text, TextSize = Theme.SectionSize, ZIndex = 10,
		XAlign = Enum.TextXAlignment.Center,
		Position = UDim2.new(0, 0, 0, 0), Size = UDim2.new(1, 0, 0, Layout.TitleH),
	})

	create("Frame", {
		Name = "Divider", BorderSizePixel = 0, BackgroundColor3 = Theme.Divider,
		Size = UDim2.new(1, -2, 0, 1), Position = UDim2.new(0, 1, 0, Layout.TitleH),
		ZIndex = 10, Parent = root,
	}, {
		create("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.6),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})

	local elements = create("Frame", {
		Name = "Elements", BackgroundTransparency = 1,
		Size = UDim2.new(1, -Layout.Pad * 2, 0, 0), Position = UDim2.new(0, Layout.Pad, 0, Layout.PadTop),
		AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 10, Parent = root,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, Layout.Gap), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding", { PaddingBottom = UDim.new(0, Layout.Pad + 1) }),
	})

	return setmetatable({
		Tab = self, Lib = self.Lib, Root = root, Holder = elements, Name = opts.Name,
	}, Section)
end

function Section:_row(height)
	local outer = bordered({ Fill = Theme.OuterFill, Border = Theme.OuterBorder, ZIndex = 11 })
	outer.Root.Size = UDim2.new(1, 0, 0, height or Layout.RowH)
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
	local row = self:_row(opts.Height or Layout.RowH)
	local txt = label({
		Parent = row.Content, Text = opts.Text or "Label",
		Color = opts.Color or Theme.Text, ZIndex = 14,
		XAlign = opts.Center and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left,
		Position = UDim2.new(0, 8, 0, opts.Wrap and 5 or 0),
		Size = UDim2.new(1, -16, opts.Wrap and 0 or 1, 0),
	})
	if opts.Wrap then
		txt.TextWrapped = true
		txt.TextYAlignment = Enum.TextYAlignment.Top
		txt.AutomaticSize = Enum.AutomaticSize.Y
		local function resize()
			row.Wrap.Size = UDim2.new(1, 0, 0, txt.AbsoluteSize.Y + 10)
		end
		txt:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize)
		task.defer(resize)
	end
	return {
		SetText = function(_, t) txt.Text = t end,
		Instance = row.Wrap,
	}
end

function Section:AddButton(opts)
	opts = opts or {}
	local row = self:_row(Layout.RowH)
	label({
		Parent = row.Content, Text = opts.Name or "Button",
		ZIndex = 14, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -46, 1, 0),
	})

	local box = create("ImageButton", {
		Name = "Button", AutoButtonColor = false, ScaleType = Enum.ScaleType.Fit,
		Image = Icons.Cursor, ImageColor3 = Theme.TextBright,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 32, 0, 15), Position = UDim2.new(1, -40, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		ZIndex = 15, Parent = row.Content,
	}, { corner(Theme.CornerSmall) })
	self.Lib:_bindAccent(box, "BackgroundColor3")
	hoverLift(box)

	local function fire()
		pressBounce(box)
		tween(box, Anim.Fast, { BackgroundColor3 = Theme.AccentHover })
		task.delay(Anim.Base, function() tween(box, Anim.Base, { BackgroundColor3 = Theme.Accent }) end)
		if opts.Callback then task.spawn(opts.Callback) end
	end
	box.MouseButton1Click:Connect(fire)
	return { Instance = row.Wrap, Fire = fire }
end

function Section:AddToggle(opts)
	opts = opts or {}
	local state = opts.Default or false
	local row = self:_row(Layout.RowH)
	registerFlag(self.Lib, opts.Flag, state)

	label({
		Parent = row.Content, Text = opts.Name or "Toggle",
		ZIndex = 14, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -46, 1, 0),
	})

	local locked = opts.Locked or false

	local pill = create("ImageButton", {
		Name = "Toggle", AutoButtonColor = false, ImageTransparency = 1,
		BackgroundColor3 = state and Theme.Accent or Theme.AccentBg,
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(0, 30, 0, 14), Position = UDim2.new(1, -38, 0.5, 0),
		ZIndex = 14, Parent = row.Content, BorderSizePixel = 0,
	}, { corner(UDim.new(1, 0)) })
	self.Lib:_bindAccent(pill, "BackgroundColor3", state and "accent" or "bg")
	hoverLift(pill)

	local dot = create("Frame", {
		Name = "Dot", BackgroundColor3 = state and Theme.TextBright or Theme.TextDim,
		Size = UDim2.new(0, 12, 0, 12),
		Position = state and UDim2.new(1, -13, 0.5, -6) or UDim2.new(0, 1, 0.5, -6),
		ZIndex = 15, BorderSizePixel = 0, Parent = pill,
	}, { corner(UDim.new(1, 0)) })

	local lock = create("ImageLabel", {
		Name = "Lock", BackgroundTransparency = 1, Image = Icons.Lock,
		ImageColor3 = Theme.TextBright, Visible = locked,
		Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(0.5, -7, 0.5, -7),
		ZIndex = 16, Parent = pill,
	})

	local api = {}
	local function bindEntry()
		for _, e in ipairs(self.Lib._accentObjects) do
			if e.inst == pill then e.variant = state and "accent" or "bg" return end
		end
	end
	local function apply(fire)
		bindEntry()
		tween(pill, Anim.Base, { BackgroundColor3 = state and Theme.Accent or Theme.AccentBg })
		tween(dot, Anim.Base, {
			Position = state and UDim2.new(1, -13, 0.5, -6) or UDim2.new(0, 1, 0.5, -6),
			BackgroundColor3 = state and Theme.TextBright or Theme.TextDim,
		})
		registerFlag(self.Lib, opts.Flag, state)
		if fire and opts.Callback then task.spawn(opts.Callback, state) end
	end

	pill.MouseButton1Click:Connect(function()
		if locked then return end
		state = not state
		apply(true)
	end)

	function api:Set(v, silent) state = v and true or false; apply(not silent) end
	function api:Get() return state end
	function api:SetLocked(v) locked = v; lock.Visible = v end
	api.Instance = row.Wrap
	return api
end

function Section:AddSlider(opts)
	opts = opts or {}
	local min = opts.Min or 0
	local max = opts.Max or 100
	if max <= min then max = min + 1 end -- guard against a zero-width range (NaN)
	local value = math.clamp(opts.Default or min, min, max)
	local decimals = opts.Decimals or 0
	local suffix = opts.Suffix or ""

	local function round(v)
		local m = 10 ^ decimals
		return math.floor(v * m + 0.5) / m
	end

	local row = self:_row(Layout.SliderH)
	registerFlag(self.Lib, opts.Flag, value)

	label({
		Parent = row.Content, Text = opts.Name or "Slider",
		ZIndex = 14, Position = UDim2.new(0, 8, 0, 3), Size = UDim2.new(1, -64, 0, 14),
	})
	local function fmt(v)
		if decimals > 0 then return string.format("%." .. decimals .. "f", v) end
		return tostring(v)
	end

	-- Editable value: a TextBox so users can type an exact number. Suffix is
	-- shown in a separate label so it never gets in the way of parsing input.
	local valBox = create("TextBox", {
		Name = "Value", BackgroundTransparency = 1, ClearTextOnFocus = false,
		FontFace = Theme.Font, TextSize = Theme.TextSize, TextColor3 = Theme.TextDim,
		TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 14,
		Text = fmt(round(value)) .. suffix,
		Position = UDim2.new(1, -58, 0, 3), Size = UDim2.new(0, 50, 0, 14),
		Parent = row.Content,
	})

	local track = create("Frame", {
		Name = "Slider", BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(1, -16, 0, 6), Position = UDim2.new(0, 8, 1, -9),
		ZIndex = 14, Parent = row.Content,
	}, { corner(UDim.new(1, 0)) })
	self.Lib:_bindAccent(track, "BackgroundColor3", "bg")

	local fill = create("Frame", {
		Name = "Fill", BorderSizePixel = 0,
		Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
		ZIndex = 15, Parent = track,
	}, { corner(UDim.new(1, 0)) })
	self.Lib:_bindAccent(fill, "BackgroundColor3")

	local handle = create("Frame", {
		Name = "Handle", BackgroundColor3 = Theme.TextBright, BorderSizePixel = 0,
		Size = UDim2.new(0, 10, 0, 10), AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
		ZIndex = 16, Parent = track,
	}, { corner(UDim.new(1, 0)) })

	local api = {}
	local function setFromScale(scale, fire)
		scale = math.clamp(scale, 0, 1)
		value = round(min + (max - min) * scale)
		local realScale = (value - min) / (max - min)
		tween(fill, Anim.Fast, { Size = UDim2.new(realScale, 0, 1, 0) })
		tween(handle, Anim.Fast, { Position = UDim2.new(realScale, 0, 0.5, 0) })
		valBox.Text = fmt(value) .. suffix
		registerFlag(self.Lib, opts.Flag, value)
		if fire and opts.Callback then task.spawn(opts.Callback, value) end
	end

	-- Typed input: strip the suffix, clamp, and snap to the slider.
	valBox.FocusLost:Connect(function()
		local raw = valBox.Text:gsub("[^%-%d%.]", "")
		local num = tonumber(raw)
		if num then
			setFromScale((math.clamp(num, min, max) - min) / (max - min), true)
		else
			valBox.Text = fmt(value) .. suffix
		end
	end)

	local dragging = false
	-- Press feedback: the handle dips a couple of pixels smaller on grab, then
	-- springs straight back to full size. A quick "give" instead of a swell.
	local function pressPulse()
		tween(handle, Anim.Fast, { Size = UDim2.new(0, 7, 0, 7) })
		task.delay(Anim.Fast, function()
			tween(handle, 0.18, { Size = UDim2.new(0, 10, 0, 10) }, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
		end)
	end
	local function update(input)
		local rel = (input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X
		setFromScale(rel, true)
	end
	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true; pressPulse(); update(input)
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
		or input.UserInputType == Enum.UserInputType.Touch) then update(input) end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
		or input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
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

	local row = self:_row(Layout.DropH)

	local function displayText()
		if multi then
			local parts = {}
			for i, opt in ipairs(options) do
				if selected[opt] then table.insert(parts, tostring(opt)) end
			end
			return #parts == 0 and "none" or table.concat(parts, ", ")
		end
		return tostring(selected or "none")
	end

	label({
		Parent = row.Content, Text = opts.Name or "Dropdown",
		ZIndex = 14, Position = UDim2.new(0, 8, 0, 3), Size = UDim2.new(1, -16, 0, 15),
	})

	local bar = create("TextButton", {
		Name = "Dropdown", AutoButtonColor = false, Text = "",
		BackgroundColor3 = Theme.AccentDark, BorderSizePixel = 0,
		Size = UDim2.new(1, -16, 0, 16), Position = UDim2.new(0, 8, 0, 24),
		ZIndex = 14, Parent = row.Content,
	}, { corner(Theme.CornerSmall) })
	self.Lib:_bindAccent(bar, "BackgroundColor3", "dark")

	local valLabel = label({
		Parent = bar, Text = displayText(), Color = Theme.Text, ZIndex = 15,
		Position = UDim2.new(0, 7, 0, 0), Size = UDim2.new(1, -24, 1, 0),
	})
	local arrow = create("ImageLabel", {
		Name = "Button", BackgroundTransparency = 1, Image = Icons.Chevron,
		ImageColor3 = Theme.Text, Size = UDim2.new(0, 11, 0, 11),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -9, 0.5, 0), ZIndex = 15, Parent = bar,
	})

	-- Option list is a ScrollingFrame so a long list stays compact: it grows only
	-- up to a capped height, then an accent-tinted scrollbar takes over. The bar
	-- is hidden until there's actually overflow, so short lists look clean.
	local OPT_H, OPT_GAP, LIST_PAD = 18, 3, 4
	local MAX_VISIBLE = opts.MaxVisible or 6

	local listWrap = bordered({ Fill = Theme.InnerFill, Border = Theme.InnerBorder, ZIndex = 205 })
	listWrap.Root.Size = UDim2.new(1, -16, 0, 0)
	listWrap.Root.Position = UDim2.new(0, 8, 0, 44)
	listWrap.Root.Visible = false
	listWrap.Root.ClipsDescendants = true
	listWrap.Root.Parent = row.Content

	local listScroll = create("ScrollingFrame", {
		Name = "Options", BackgroundTransparency = 1, BorderSizePixel = 0,
		Size = UDim2.new(1, -LIST_PAD * 2, 1, -LIST_PAD * 2),
		Position = UDim2.new(0, LIST_PAD, 0, LIST_PAD),
		CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollBarThickness = 3, ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 206, Parent = listWrap.Content,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, OPT_GAP), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	-- Scrollbar picks up the live accent instead of a hardcoded gray.
	self.Lib:_bindAccent(listScroll, "ScrollBarImageColor3")

	local api = {}
	local optButtons = {}

	local function isSelected(opt)
		if multi then return selected[opt] == true end
		return selected == opt
	end

	local function refresh(fire)
		valLabel.Text = displayText()
		for opt, b in pairs(optButtons) do
			b.BackgroundColor3 = isSelected(opt) and Theme.AccentBg or Theme.InnerFill
			b.TextColor3 = isSelected(opt) and Theme.TextBright or Theme.Text
		end
		registerFlag(self.Lib, opts.Flag, selected)
		if fire and opts.Callback then task.spawn(opts.Callback, selected) end
	end

	local open = false
	-- Visible list height: full content up to MAX_VISIBLE rows, then it caps and
	-- the scrollbar handles the rest. Zero options means zero height (never opens).
	local function listHeight()
		local n = #options
		if n == 0 then return 0 end
		local shown = math.min(n, MAX_VISIBLE)
		return shown * OPT_H + (shown - 1) * OPT_GAP + LIST_PAD * 2
	end
	local function setOpen(o)
		-- An empty dropdown simply does nothing: no open, no empty black panel.
		if o and #options == 0 then return end
		if o == open then return end
		open = o
		tween(arrow, Anim.Slow, { Rotation = o and 180 or 0 })
		local h = o and listHeight() or 0
		row.Wrap.ZIndex = o and 200 or 11
		row.Wrap.Size = UDim2.new(1, 0, 0, o and (Layout.DropH + 3 + h) or Layout.DropH)
		if o then
			listWrap.Root.Visible = true
			tween(listWrap.Root, Anim.Slow, { Size = UDim2.new(1, -16, 0, h) })
		else
			local t = tween(listWrap.Root, Anim.Base, { Size = UDim2.new(1, -16, 0, 0) })
			t.Completed:Connect(function()
				if not open then listWrap.Root.Visible = false end
			end)
		end
	end

	local function rebuild()
		for _, b in pairs(optButtons) do b:Destroy() end
		optButtons = {}
		for i, opt in ipairs(options) do
			local b = create("TextButton", {
				BackgroundColor3 = isSelected(opt) and Theme.AccentBg or Theme.InnerFill,
				BorderSizePixel = 0, AutoButtonColor = false, Text = tostring(opt),
				FontFace = Theme.Font, TextSize = Theme.TextSize,
				TextColor3 = isSelected(opt) and Theme.TextBright or Theme.Text,
				Size = UDim2.new(1, 0, 0, OPT_H), ZIndex = 207,
				LayoutOrder = i, Parent = listScroll,
			}, { corner(Theme.CornerSmall) })
			-- Hover tint so the row the cursor is on is obvious even before click.
			b.MouseEnter:Connect(function()
				if not isSelected(opt) then tween(b, Anim.Fast, { BackgroundColor3 = Theme.InnerHover }) end
			end)
			b.MouseLeave:Connect(function()
				if not isSelected(opt) then tween(b, Anim.Fast, { BackgroundColor3 = Theme.InnerFill }) end
			end)
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

	bar.MouseButton1Click:Connect(function() setOpen(not open) end)

	UserInputService.InputBegan:Connect(function(input)
		if not open then return end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1
		and input.UserInputType ~= Enum.UserInputType.Touch then return end
		local inset = GuiService:GetGuiInset()
		local m = UserInputService:GetMouseLocation() + inset
		local pos, sz = row.Wrap.AbsolutePosition, row.Wrap.AbsoluteSize
		if m.X < pos.X or m.X > pos.X + sz.X or m.Y < pos.Y or m.Y > pos.Y + sz.Y then
			setOpen(false)
		end
	end)

	rebuild()

	function api:Set(v, silent) selected = v; refresh(not silent) end
	function api:Get() return selected end
	function api:Refresh(newOpts, keep)
		options = newOpts or options
		if not keep then selected = multi and {} or options[1] end
		rebuild(); refresh(false)
		-- Re-fit an open list to the new option count; collapse if it emptied out.
		if open then
			if #options == 0 then
				-- setOpen must see open==true to run its collapse branch, so we
				-- let it flip the flag itself rather than pre-clearing it here.
				setOpen(false)
			else
				local h = listHeight()
				row.Wrap.Size = UDim2.new(1, 0, 0, Layout.DropH + 3 + h)
				listWrap.Root.Size = UDim2.new(1, -16, 0, h)
			end
		end
	end
	api.Instance = row.Wrap
	return api
end

function Section:AddKeybind(opts)
	opts = opts or {}
	local key = opts.Default
	local row = self:_row(Layout.RowH)

	label({
		Parent = row.Content, Text = opts.Name or "Keybind",
		ZIndex = 14, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -70, 1, 0),
	})

	local box = create("TextButton", {
		Name = "Keybind", BorderSizePixel = 0, AnchorPoint = Vector2.new(1, 0.5),
		AutoButtonColor = false, FontFace = Theme.Font, TextSize = Theme.TextSize,
		TextColor3 = Theme.TextBright,
		Text = key and key.Name or "None",
		Size = UDim2.new(0, 52, 0, 15), Position = UDim2.new(1, -8, 0.5, 0),
		ZIndex = 15, Parent = row.Content, ClipsDescendants = true,
	}, { corner(Theme.CornerSmall) })
	self.Lib:_bindAccent(box, "BackgroundColor3", "dark")
	hoverLift(box)

	local api = {}
	local listening = false
	box.MouseButton1Click:Connect(function()
		pressBounce(box)
		listening = true
		box.Text = "..."
		box.TextColor3 = Theme.TextBright
	end)

	UserInputService.InputBegan:Connect(function(input, gpe)
		if listening and input.UserInputType == Enum.UserInputType.Keyboard then
			listening = false
			if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace then
				key = nil; box.Text = "None"
			else
				key = input.KeyCode; box.Text = key.Name
			end
			box.TextColor3 = Theme.TextBright
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
	local row = self:_row(opts.Vertical and Layout.DropH or Layout.RowH)
	registerFlag(self.Lib, opts.Flag, opts.Default or "")

	if opts.Vertical then
		label({
			Parent = row.Content, Text = opts.Name or "Input",
			ZIndex = 14, Position = UDim2.new(0, 8, 0, 3), Size = UDim2.new(1, -16, 0, 15),
		})
		local field = create("Frame", {
			Name = "TextBox", BackgroundColor3 = Theme.AccentDark, BorderSizePixel = 0,
			Size = UDim2.new(1, -16, 0, 16), Position = UDim2.new(0, 8, 0, 24),
			ZIndex = 14, Parent = row.Content,
		}, { corner(Theme.CornerSmall) })
		self.Lib:_bindAccent(field, "BackgroundColor3", "dark")
		local box = create("TextBox", {
			Name = "Input", BackgroundTransparency = 1,
			FontFace = Theme.Font, TextSize = Theme.TextSize, TextColor3 = Theme.Text,
			TextXAlignment = Enum.TextXAlignment.Left,
			PlaceholderText = opts.Placeholder or "", PlaceholderColor3 = Theme.TextDim,
			Text = opts.Default or "", ClearTextOnFocus = false,
			Size = UDim2.new(1, -14, 1, 0), Position = UDim2.new(0, 7, 0, 0),
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
		ZIndex = 14, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(0.4, -10, 1, 0),
	})
	local box = create("TextBox", {
		Name = "TextBox", BackgroundColor3 = Theme.AccentDark, BorderSizePixel = 0,
		FontFace = Theme.Font, TextSize = Theme.TextSize, TextColor3 = Theme.Text,
		PlaceholderText = opts.Placeholder or "", PlaceholderColor3 = Theme.TextDim,
		Text = opts.Default or "", ClearTextOnFocus = false,
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(0.6, -12, 0, 16), Position = UDim2.new(0.4, 0, 0.5, 0),
		ZIndex = 15, Parent = row.Content, ClipsDescendants = true,
	}, { corner(Theme.CornerSmall), create("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }) })
	self.Lib:_bindAccent(box, "BackgroundColor3", "dark")

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

	local row = self:_row(Layout.RowH)

	label({
		Parent = row.Content, Text = opts.Name or "Color",
		ZIndex = 14, Position = UDim2.new(0, 8, 0, 0), Size = UDim2.new(1, -30, 1, 0),
	})

	-- Swatch is centre-anchored so it always sits on the row's vertical midline
	-- (the old fixed top offset made it read as dropped a couple of pixels).
	local swatch = create("ImageButton", {
		AutoButtonColor = false, ImageTransparency = 1,
		BackgroundColor3 = color, BorderSizePixel = 0,
		AnchorPoint = Vector2.new(0, 0.5),
		Size = UDim2.new(0, 14, 0, 14), Position = UDim2.new(1, -22, 0, math.floor(Layout.RowH / 2)),
		ZIndex = 15, Parent = row.Content,
	}, { corner(Theme.CornerSmall) })
	hoverLift(swatch)

	local satBox = create("Frame", {
		Name = "Saturation", BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0,
		Size = UDim2.new(1, -34, 0, 70), Position = UDim2.new(0, 8, 0, Layout.PadTop),
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
		Size = UDim2.new(0, 14, 0, 70), Position = UDim2.new(1, -22, 0, Layout.PadTop),
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

	-- Expanded panel: the sat/hue boxes start at y=26 and are 70 tall, so the row
	-- opens to 26 + 70 + 8 padding. Collapsed it's a normal grid row.
	local function setExpanded(o)
		expanded = o
		satBox.Visible = o
		hueBar.Visible = o
		row.Wrap.Size = UDim2.new(1, 0, 0, o and 104 or Layout.RowH)
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
		ScrollBarThickness = 2,
		ZIndex = 15, Parent = screen,
	}, {
		create("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	self.Lib:_bindAccent(scroll, "ScrollBarImageColor3")

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
	local tab = self:AddTab({ Name = "Settings", Icon = opts.Icon or Icons.Gear, Bottom = true, Columns = opts.Columns or 2 })

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
