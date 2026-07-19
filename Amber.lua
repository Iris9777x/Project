-- AmberUI — bundle autonome généré par build.py. NE PAS ÉDITER À LA MAIN.
-- Source multi-fichiers : https://github.com/USER/REPO
-- =====================================================================
-- Runtime : faux arbre `script` + require() par nœud (avec cache).
-- Reproduit le comportement des ModuleScripts Roblox dans une seule source.
-- =====================================================================
local function __build_AmberUI()
	local __cache = {}
	local __loaders = {}

	-- Nœud d'arbre : indexe ses enfants par nom, expose .Parent.
	local __nodeMeta = {}
	__nodeMeta.__index = function(self, key)
		if key == "Parent" then return rawget(self, "__parent") end
		local children = rawget(self, "__children")
		local child = children and children[key]
		if child then return child end
		error("[AmberUI] noeud introuvable: " .. tostring(key), 2)
	end

	local function __node(name, parent)
		local n = setmetatable(
			{ __name = name, __parent = parent, __children = {} },
			__nodeMeta
		)
		if parent then
			rawget(parent, "__children")[name] = n
		end
		return n
	end

	local function __require(node)
		if __cache[node] ~= nil then return __cache[node] end
		local loader = __loaders[node]
		if not loader then
			error("[AmberUI] module non charge: " .. tostring(rawget(node, "__name")), 2)
		end
		local result = loader(node, __require)
		__cache[node] = result
		return result
	end

	-- ---- Arbre des modules ----
	local __root = __node("AmberUI")
	local __n_Theme = __node("Theme", __root)
	local __n_Util = __node("Util", __root)
	local __n_Glow = __node("Glow", __root)
	local __n_Scanlines = __node("Scanlines", __root)
	local __n_Components = __node("Components", __root)
	local __n_Components_Button = __node("Button", __n_Components)
	local __n_Components_TextInput = __node("TextInput", __n_Components)
	local __n_Components_Toggle = __node("Toggle", __n_Components)
	local __n_Components_Slider = __node("Slider", __n_Components)
	local __n_Components_Checkbox = __node("Checkbox", __n_Components)
	local __n_Components_Card = __node("Card", __n_Components)
	local __n_Components_Nav = __node("Nav", __n_Components)
	local __n_Components_Badge = __node("Badge", __n_Components)
	local __n_Components_Modal = __node("Modal", __n_Components)
	local __n_Components_Terminal = __node("Terminal", __n_Components)

	-- ---- Loaders (une closure par module = un ModuleScript) ----
	__loaders[__root] = function(script, require)
		--!strict
		-- AmberUI / init.lua
		-- =====================================================================
		-- Point d'entrée de la library "04 Amber Retro". Place ce dossier comme
		-- ModuleScript nommé "AmberUI" (avec init.lua) dans ReplicatedStorage.
		-- Structure attendue :
		--   AmberUI/                (ModuleScript = ce init.lua)
		--     Theme, Util, Glow, Scanlines   (ModuleScripts enfants)
		--     Components/
		--       Button, TextInput, Toggle, Slider, Checkbox,
		--       Card, Nav, Badge, Modal, Terminal
		--
		-- Réutilisation :
		--   local UI = require(ReplicatedStorage.AmberUI)
		--   local term = UI.Terminal.new({ parent = screenGui })
		--   UI.Toggle.new({ label = "AUTO_ATTACK", value = true, parent = term.body })
		-- =====================================================================

		local Components = script.Components

		local AmberUI = {
			Theme     = require(script.Theme),
			Util      = require(script.Util),
			Glow      = require(script.Glow),
			Scanlines = require(script.Scanlines),

			Button    = require(Components.Button),
			TextInput = require(Components.TextInput),
			Toggle    = require(Components.Toggle),
			Slider    = require(Components.Slider),
			Checkbox  = require(Components.Checkbox),
			Card      = require(Components.Card),
			Nav       = require(Components.Nav),
			Badge     = require(Components.Badge),
			Modal     = require(Components.Modal),
			Terminal  = require(Components.Terminal),
		}

		return AmberUI

	end

	__loaders[__n_Theme] = function(script, require)
		--!strict
		-- AmberUI / Theme.lua
		-- =====================================================================
		-- Thème centralisé du concept "04 Amber Retro" (terminal CRT vintage ambre,
		-- scanlines). Valeurs Color3 extraites À L'IDENTIQUE du CSS d'origine
		-- (autofarm-cheat-concepts.html, bloc `.amber*`).
		--
		-- Réutilisation :
		--   local Theme = require(path.to.AmberUI.Theme)
		--   frame.BackgroundColor3 = Theme.Color.Panel
		-- =====================================================================

		local function hex(h: string): Color3
			return Color3.fromHex(h)
		end

		local Theme = {}

		-- ---------------------------------------------------------------------
		-- PALETTE — reprise telle quelle du CSS `.amber`
		-- ---------------------------------------------------------------------
		Theme.Color = {
			-- Fonds
			Stage      = hex("0a0700"), -- .st-amber   fond de scène (noir chaud)
			Panel      = hex("0d0a02"), -- .amber      corps du terminal
			Inner      = hex("0d0a02"), -- .amber-in   même fond, cadre interne

			-- Bordures
			Border     = hex("3a2c05"), -- .amber      bordure ambre sombre
			BorderIn   = hex("241a03"), -- .amber-in   cadre interne (corrige la typo CSS "24 1a03")

			-- Ambres (accent primaire du concept)
			Primary    = hex("fbbf24"), -- .amber-in / .amber-nav.on   ambre vif
			Header     = hex("d97706"), -- .amber-hd                   ambre foncé (en-tête)
			NavMuted   = hex("a16207"), -- .amber-nav                  onglet inactif
			Text       = hex("eab308"), -- .amber-opt                  texte principal ambre
			Value      = hex("fde68a"), -- .amber-opt .v               valeurs claires

			-- États (statuts [ON]/[OFF])
			On         = hex("22c55e"), -- .st-on   vert
			Off        = hex("78716c"), -- .st-off  gris chaud
			OnPrimary  = hex("0d0a02"), -- texte sur fond ambre plein (.amber-nav.on)

			Disabled   = hex("57430a"), -- dérivé cohérent
		}

		-- ---------------------------------------------------------------------
		-- GLOW — gros halo ambre (box-shadow:0 0 50px rgba(251,191,36,.12))
		-- Halo large et diffus : c'est un CRT, pas un liseré net.
		-- ---------------------------------------------------------------------
		Theme.Glow = {
			Color   = Theme.Color.Primary,
			Rest    = 0.7,   -- diffus/subtil au repos (le .12 d'origine)
			Active  = 0.35,
			Spread  = 40,    -- large (box-shadow 50px)
		}

		-- ---------------------------------------------------------------------
		-- SCANLINES — signature CRT
		-- CSS: repeating-linear-gradient(0deg, rgba(251,191,36,.03) 0-1px, transparent 1-3px)
		-- On reproduit via une texture rayée en overlay (voir Scanlines.lua).
		-- ---------------------------------------------------------------------
		Theme.Scanline = {
			Color        = Theme.Color.Primary,
			Transparency = 0.94, -- ~ rgba .03 -> très subtil
			Spacing      = 3,    -- période de 3px
			Flicker      = true, -- léger scintillement CRT
		}

		-- ---------------------------------------------------------------------
		-- TYPOGRAPHIE — JetBrains Mono => Enum.Font.Code
		-- ---------------------------------------------------------------------
		Theme.Font = {
			Mono     = Enum.Font.Code,
			MonoBold = Enum.Font.Code,
			Display  = Enum.Font.Code,
		}

		Theme.Text = {
			Small = 12,
			Body  = 14,
			Title = 15,
			Big   = 20,
			StrokeTransparency = 0.7, -- léger halo de texte pour l'effet phosphore CRT
		}

		-- ---------------------------------------------------------------------
		-- FORMES — CRT : coins très légèrement arrondis (radius 6px du .amber)
		-- ---------------------------------------------------------------------
		Theme.Shape = {
			Corner      = UDim.new(0, 6),  -- .amber border-radius:6px
			CornerSoft  = UDim.new(0, 4),
			Stroke      = 1,
			StrokeThick = 2,
		}

		-- ---------------------------------------------------------------------
		-- ESPACEMENTS — dérivés du CSS (.amber-in padding 16, .amber-opt 6px)
		-- ---------------------------------------------------------------------
		Theme.Space = {
			XS = 4, SM = 8, MD = 12, LG = 16, XL = 24,
			RowPad = 6,    -- .amber-opt
			PanelPad = 16, -- .amber-in
		}

		Theme.Motion = {
			Fast   = 0.12,
			Normal = 0.2,
			Slow   = 0.4,
			Pulse  = 1.3,  -- respiration CRT plus lente
			Flicker = 0.08,
		}

		return Theme

	end

	__loaders[__n_Util] = function(script, require)
		--!strict
		-- AmberUI / Util.lua
		-- =====================================================================
		-- Helpers partagés par tous les composants : création d'Instances,
		-- tweens, gestion responsive (Scale + contraintes), détection tactile.
		-- Aucune dépendance au thème -> réutilisable tel quel dans Amber aussi.
		--
		-- Réutilisation :
		--   local Util = require(path.to.ProtocolUI.Util)
		--   local f = Util.make("Frame", { BackgroundColor3 = ... }, parent)
		-- =====================================================================

		local TweenService = game:GetService("TweenService")
		local UserInputService = game:GetService("UserInputService")

		local Util = {}

		-- ---------------------------------------------------------------------
		-- make(className, props, parent, children)
		-- Crée une Instance, applique les props, parente d'éventuels enfants.
		-- children peut contenir des Instances déjà créées (contraintes, layout…).
		-- ---------------------------------------------------------------------
		function Util.make(className: string, props: {[string]: any}?, parent: Instance?, children: {Instance}?): Instance
			local inst = Instance.new(className)
			if props then
				for k, v in pairs(props) do
					(inst :: any)[k] = v
				end
			end
			if children then
				for _, c in ipairs(children) do
					c.Parent = inst
				end
			end
			if parent then
				inst.Parent = parent
			end
			return inst
		end

		-- ---------------------------------------------------------------------
		-- tween(inst, props, duration?, style?, direction?)
		-- Raccourci TweenService avec valeurs par défaut douces. Retourne le Tween.
		-- ---------------------------------------------------------------------
		function Util.tween(inst: Instance, props: {[string]: any}, duration: number?, style: Enum.EasingStyle?, direction: Enum.EasingDirection?): Tween
			local info = TweenInfo.new(
				duration or 0.2,
				style or Enum.EasingStyle.Quad,
				direction or Enum.EasingDirection.Out
			)
			local t = TweenService:Create(inst, info, props)
			t:Play()
			return t
		end

		-- ---------------------------------------------------------------------
		-- corner / stroke / padding / listLayout : fabriques d'objets d'UI courants.
		-- ---------------------------------------------------------------------
		function Util.corner(radius: UDim, parent: Instance?): UICorner
			return Util.make("UICorner", { CornerRadius = radius }, parent) :: UICorner
		end

		function Util.stroke(color: Color3, thickness: number?, transparency: number?, parent: Instance?): UIStroke
			return Util.make("UIStroke", {
				Color = color,
				Thickness = thickness or 1,
				Transparency = transparency or 0,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}, parent) :: UIStroke
		end

		function Util.padding(all: number, parent: Instance?): UIPadding
			local u = UDim.new(0, all)
			return Util.make("UIPadding", {
				PaddingTop = u, PaddingBottom = u, PaddingLeft = u, PaddingRight = u,
			}, parent) :: UIPadding
		end

		function Util.paddingXY(x: number, y: number, parent: Instance?): UIPadding
			return Util.make("UIPadding", {
				PaddingLeft = UDim.new(0, x), PaddingRight = UDim.new(0, x),
				PaddingTop = UDim.new(0, y), PaddingBottom = UDim.new(0, y),
			}, parent) :: UIPadding
		end

		function Util.vlist(gap: number, parent: Instance?, align: Enum.HorizontalAlignment?): UIListLayout
			return Util.make("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, gap),
				HorizontalAlignment = align or Enum.HorizontalAlignment.Left,
			}, parent) :: UIListLayout
		end

		function Util.hlist(gap: number, parent: Instance?, align: Enum.VerticalAlignment?): UIListLayout
			return Util.make("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, gap),
				VerticalAlignment = align or Enum.VerticalAlignment.Center,
			}, parent) :: UIListLayout
		end

		-- ---------------------------------------------------------------------
		-- RESPONSIVE
		-- textConstraint : garde le texte lisible quand l'UI est mise à l'échelle.
		-- aspect : verrouille un ratio (utile pour cartes/fenêtres sur mobile).
		-- sizeConstraint : borne min/max en pixels pour éviter l'extrême.
		-- ---------------------------------------------------------------------
		function Util.textConstraint(min: number, max: number, parent: Instance?): UITextSizeConstraint
			return Util.make("UITextSizeConstraint", {
				MinTextSize = min, MaxTextSize = max,
			}, parent) :: UITextSizeConstraint
		end

		function Util.aspect(ratio: number, parent: Instance?): UIAspectRatioConstraint
			return Util.make("UIAspectRatioConstraint", {
				AspectRatio = ratio,
				DominantAxis = Enum.DominantAxis.Width,
			}, parent) :: UIAspectRatioConstraint
		end

		function Util.sizeConstraint(minPx: Vector2, maxPx: Vector2, parent: Instance?): UISizeConstraint
			return Util.make("UISizeConstraint", {
				MinSize = minPx, MaxSize = maxPx,
			}, parent) :: UISizeConstraint
		end

		-- ---------------------------------------------------------------------
		-- isTouch() : true si l'appareil est principalement tactile (mobile Roblox).
		-- Les composants l'utilisent pour agrandir les zones cliquables.
		-- ---------------------------------------------------------------------
		function Util.isTouch(): boolean
			return UserInputService.TouchEnabled and not UserInputService.MouseEnabled
		end

		-- ---------------------------------------------------------------------
		-- debounce(fn, delay) : renvoie une fonction throttlée (anti-spam d'input).
		-- ---------------------------------------------------------------------
		function Util.debounce(fn: (...any) -> (), delay: number): (...any) -> ()
			local ready = true
			return function(...)
				if not ready then return end
				ready = false
				fn(...)
				task.delay(delay, function() ready = true end)
			end
		end

		-- ---------------------------------------------------------------------
		-- hover(guiObject, onEnter, onLeave)
		-- Branche à la fois souris (MouseEnter/Leave) ET tactile (press/release)
		-- pour que les états hover marchent sur PC comme sur mobile.
		-- Retourne une fonction de déconnexion.
		-- ---------------------------------------------------------------------
		function Util.hover(obj: GuiObject, onEnter: () -> (), onLeave: () -> ()): () -> ()
			local conns: {RBXScriptConnection} = {}
			table.insert(conns, obj.MouseEnter:Connect(onEnter))
			table.insert(conns, obj.MouseLeave:Connect(onLeave))
			-- Sur tactile : InputBegan/Ended simulent le survol au toucher.
			table.insert(conns, obj.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch then onEnter() end
			end))
			table.insert(conns, obj.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.Touch then onLeave() end
			end))
			return function()
				for _, c in ipairs(conns) do c:Disconnect() end
			end
		end

		return Util

	end

	__loaders[__n_Glow] = function(script, require)
		--!strict
		-- AmberUI / Glow.lua
		-- =====================================================================
		-- Le halo lumineux "réel" du concept. Le CSS d'origine utilise
		--   box-shadow:0 0 10px rgba(220,38,38,.6)
		-- que UIStroke seul ne reproduit pas (pas de diffusion). On combine donc :
		--   1) un ImageLabel avec une texture radiale floutée (vrai halo diffus)
		--   2) un UIStroke à Transparency animée (le liseré net brutaliste)
		--
		-- La texture radiale utilisée est l'asset Roblox standard de glow radial.
		-- Si tu as ta propre texture, remplace GLOW_TEXTURE ci-dessous.
		--
		-- Réutilisation :
		--   local Glow = require(path.to.ProtocolUI.Glow)
		--   local halo = Glow.attach(monBouton, { color = Theme.Color.Primary })
		--   halo:setActive(true)   -- intensifie (hover/on)
		--   halo:pulse()           -- respiration continue (état "live")
		-- =====================================================================

		local RunService = game:GetService("RunService")
		local Util = require(script.Parent.Util)

		-- Texture radiale floue standard (halo doux). Asset public Roblox.
		local GLOW_TEXTURE = "rbxassetid://5028857084" -- radial glow (soft)

		local Glow = {}
		Glow.__index = Glow

		type GlowConfig = {
			color: Color3?,
			rest: number?,     -- transparency au repos (0..1)
			active: number?,   -- transparency actif
			spread: number?,   -- débordement du halo en px
			stroke: boolean?,  -- ajouter aussi un UIStroke net ? (défaut true)
		}

		-- attach(target, config) : pose un halo DERRIÈRE `target`.
		-- Le halo est parenté À L'INTÉRIEUR de la cible, centré avec un inset négatif
		-- (Size = 1 + spread des deux côtés). Il suit donc automatiquement la
		-- taille/position de la cible (aucun binding manuel = responsive + performant),
		-- et n'est PAS capturé par un éventuel UIListLayout du parent.
		-- Sous ZIndexBehavior.Sibling, un ZIndex inférieur le rend derrière la cible.
		function Glow.attach(target: GuiObject, config: GlowConfig?)
			config = config or {}
			local color = config.color or Color3.fromRGB(220, 38, 38)
			local rest = config.rest or 0.55
			local active = config.active or 0.15
			local spread = config.spread or 18

			-- Halo diffus (ImageLabel radial) enfant de la cible, débordant via inset.
			local halo = Util.make("ImageLabel", {
				Name = "Glow",
				BackgroundTransparency = 1,
				Image = GLOW_TEXTURE,
				ImageColor3 = color,
				ImageTransparency = rest,
				ZIndex = math.max(target.ZIndex - 1, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, spread * 2, 1, spread * 2),
				Active = false,
				Selectable = false,
			}, target) :: ImageLabel

			-- Liseré net optionnel (le côté brutaliste).
			local stroke: UIStroke? = nil
			if config.stroke ~= false then
				stroke = Util.stroke(color, 1, rest, target)
			end

			local self = setmetatable({
				halo = halo,
				stroke = stroke,
				_color = color,
				_rest = rest,
				_active = active,
				_pulsing = false,
				_conns = {},
				_heartbeat = nil :: RBXScriptConnection?,
			}, Glow)

			return self
		end

		-- setActive(on) : passe le halo entre repos et surbrillance (tween doux).
		function Glow:setActive(on: boolean)
			local target = on and self._active or self._rest
			Util.tween(self.halo, { ImageTransparency = target }, 0.2)
			if self.stroke then
				Util.tween(self.stroke, { Transparency = target }, 0.2)
			end
		end

		-- pulse() : respiration continue (RunService.Heartbeat, une seule boucle).
		-- Idéal pour un status "live"/"injected". Appeler stop() pour arrêter.
		function Glow:pulse(speed: number?)
			if self._pulsing then return end
			self._pulsing = true
			local sp = speed or 1.1
			local t0 = os.clock()
			self._heartbeat = RunService.Heartbeat:Connect(function()
				local phase = (math.sin((os.clock() - t0) * math.pi / sp) + 1) / 2 -- 0..1
				local val = self._rest + (self._active - self._rest) * phase
				self.halo.ImageTransparency = val
				if self.stroke then self.stroke.Transparency = val end
			end)
		end

		-- stop() : arrête la pulsation et revient au repos.
		function Glow:stop()
			self._pulsing = false
			if self._heartbeat then
				self._heartbeat:Disconnect()
				self._heartbeat = nil
			end
			self:setActive(false)
		end

		-- destroy() : nettoyage complet (connexions + instances).
		function Glow:destroy()
			self:stop()
			for _, c in ipairs(self._conns) do c:Disconnect() end
			self.halo:Destroy()
		end

		return Glow

	end

	__loaders[__n_Scanlines] = function(script, require)
		--!strict
		-- AmberUI / Scanlines.lua
		-- =====================================================================
		-- SIGNATURE CRT du concept "04 Amber Retro".
		-- Reproduit le CSS `.amber::after` :
		--   repeating-linear-gradient(0deg, rgba(251,191,36,.03) 0-1px, transparent 1-3px)
		-- soit des lignes horizontales ambre très subtiles, périodiques.
		--
		-- Implémentation Roblox : un ImageLabel rayé en overlay (Tile) posé par-dessus
		-- le contenu, non cliquable. Option "flicker" = léger scintillement CRT via
		-- TweenService (pas de Heartbeat -> économe).
		--
		-- Réutilisation :
		--   local Scanlines = require(path.to.AmberUI.Scanlines)
		--   Scanlines.attach(monPanneau, { flicker = true })
		-- =====================================================================

		local Theme = require(script.Parent.Theme)
		local Util  = require(script.Parent.Util)

		-- Texture de rayures horizontales fines (1px ligne / 2px vide) tileable.
		-- Asset générique de scanlines ; remplace par le tien si besoin.
		local SCANLINE_TEXTURE = "rbxassetid://14204231522"

		local Scanlines = {}

		type ScanConfig = {
			color: Color3?,
			transparency: number?,
			spacing: number?,   -- hauteur d'un motif tuilé (px)
			flicker: boolean?,
		}

		-- attach(target, config) : ajoute l'overlay scanlines par-dessus `target`.
		-- Retourne l'ImageLabel (pour destroy manuel si besoin).
		function Scanlines.attach(target: GuiObject, config: ScanConfig?): ImageLabel
			config = config or {}
			local spacing = config.spacing or Theme.Scanline.Spacing

			local overlay = Util.make("ImageLabel", {
				Name = "Scanlines",
				BackgroundTransparency = 1,
				Image = SCANLINE_TEXTURE,
				ImageColor3 = config.color or Theme.Scanline.Color,
				ImageTransparency = config.transparency or Theme.Scanline.Transparency,
				ScaleType = Enum.ScaleType.Tile,
				TileSize = UDim2.fromOffset(spacing, spacing),
				Size = UDim2.fromScale(1, 1),
				ZIndex = 20,           -- au-dessus du contenu
				Active = false,        -- ne capte pas les clics
				Selectable = false,
			}, target) :: ImageLabel

			-- Coins arrondis identiques au conteneur pour ne pas déborder.
			Util.corner(Theme.Shape.Corner, overlay)

			-- Scintillement CRT : oscillation très légère de la transparence.
			if config.flicker ~= false and Theme.Scanline.Flicker then
				local base = overlay.ImageTransparency
				task.spawn(function()
					while overlay.Parent do
						-- tween aller-retour subtil ; intervalle irrégulier = plus organique.
						Util.tween(overlay, { ImageTransparency = base - 0.02 }, 0.9)
						task.wait(0.9 + math.random() * 0.6)
						Util.tween(overlay, { ImageTransparency = base + 0.02 }, 0.9)
						task.wait(0.9 + math.random() * 0.6)
					end
				end)
			end

			return overlay
		end

		return Scanlines

	end

	__loaders[__n_Components_Button] = function(script, require)
		--!strict
		-- AmberUI / Components / Button.lua
		-- =====================================================================
		-- Bouton CRT ambre. Variantes : primary | secondary | ghost | disabled.
		-- primary = fond ambre plein (comme .amber-nav.on) texte sombre + glow.
		-- États Hover/Pressed/Focus via Util.hover + input events + TweenService.
		-- Texte mono uppercase avec léger TextStroke (phosphore CRT).
		--
		-- API :
		--   local Button = require(...Components.Button)
		--   local b = Button.new({ text = "EXECUTE", variant = "primary", onClick = fn, parent = frame })
		--   b:setEnabled(false) / b:setText("...") / b:destroy()
		-- =====================================================================

		local Theme = require(script.Parent.Parent.Theme)
		local Util  = require(script.Parent.Parent.Util)
		local Glow  = require(script.Parent.Parent.Glow)

		local Button = {}
		Button.__index = Button

		type ButtonProps = {
			text: string?, variant: string?, size: UDim2?, minHeight: number?,
			layoutOrder: number?, onClick: (() -> ())?, parent: Instance?,
		}

		local function styleFor(variant: string)
			if variant == "primary" then
				return { bg = Theme.Color.Primary, text = Theme.Color.OnPrimary, border = Theme.Color.Primary, glow = true }
			elseif variant == "secondary" then
				return { bg = Theme.Color.Inner, text = Theme.Color.Primary, border = Theme.Color.Border, glow = false }
			elseif variant == "ghost" then
				return { bg = nil, text = Theme.Color.NavMuted, border = Theme.Color.BorderIn, glow = false }
			else
				return { bg = Theme.Color.Inner, text = Theme.Color.Disabled, border = Theme.Color.BorderIn, glow = false }
			end
		end

		function Button.new(props: ButtonProps)
			local variant = props.variant or "primary"
			local style = styleFor(variant)
			local minH = props.minHeight or 36

			local btn = Util.make("TextButton", {
				Name = "AmberButton", Text = "", AutoButtonColor = false,
				BackgroundColor3 = style.bg or Theme.Color.Panel,
				BackgroundTransparency = style.bg and 0 or 1,
				Size = props.size or UDim2.new(1, 0, 0, minH),
				LayoutOrder = props.layoutOrder or 0, BorderSizePixel = 0,
			}, props.parent) :: TextButton
			Util.corner(Theme.Shape.CornerSoft, btn)
			local stroke = Util.stroke(style.border, Theme.Shape.Stroke, 0, btn)
			Util.sizeConstraint(Vector2.new(48, minH), Vector2.new(math.huge, minH + 14), btn)

			local label = Util.make("TextLabel", {
				Name = "Label", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
				Font = Theme.Font.Mono, Text = "[ " .. string.upper(props.text or "BUTTON") .. " ]",
				TextColor3 = style.text, TextSize = Theme.Text.Body,
				TextXAlignment = Enum.TextXAlignment.Center,
				TextStrokeColor3 = style.text, TextStrokeTransparency = variant == "primary" and 1 or Theme.Text.StrokeTransparency,
			}, btn) :: TextLabel
			Util.textConstraint(11, 18, label)

			local glow = nil
			if style.glow then
				glow = Glow.attach(btn, { color = Theme.Color.Primary, rest = 0.6, active = 0.25, spread = 24, stroke = false })
			end

			local self = setmetatable({
				instance = btn, _label = label, _stroke = stroke, _glow = glow,
				_variant = variant, _style = style, _enabled = variant ~= "disabled",
				_conns = {} :: {any}, _baseSize = props.size or UDim2.new(1, 0, 0, minH),
			}, Button)

			local function toRest()
				if not self._enabled then return end
				Util.tween(btn, { BackgroundColor3 = style.bg or Theme.Color.Panel }, Theme.Motion.Fast)
				if glow then glow:setActive(false) end
			end
			local function toHover()
				if not self._enabled then return end
				local hv = style.bg and (style.bg :: Color3):Lerp(Color3.new(1,1,1), 0.1) or Theme.Color.Inner
				Util.tween(btn, { BackgroundColor3 = hv }, Theme.Motion.Fast)
				if glow then glow:setActive(true) end
			end
			table.insert(self._conns, Util.hover(btn, toHover, toRest))

			table.insert(self._conns, btn.MouseButton1Down:Connect(function()
				if self._enabled then Util.tween(btn, { Size = self._baseSize - UDim2.fromOffset(0, 2) }, Theme.Motion.Fast) end
			end))
			table.insert(self._conns, btn.MouseButton1Up:Connect(function()
				if self._enabled then Util.tween(btn, { Size = self._baseSize }, Theme.Motion.Fast) end
			end))
			table.insert(self._conns, btn.SelectionGained:Connect(function()
				Util.tween(stroke, { Thickness = Theme.Shape.StrokeThick }, Theme.Motion.Fast)
			end))
			table.insert(self._conns, btn.SelectionLost:Connect(function()
				Util.tween(stroke, { Thickness = Theme.Shape.Stroke }, Theme.Motion.Fast)
			end))

			if props.onClick then
				local guarded = Util.debounce(props.onClick, 0.25)
				table.insert(self._conns, btn.Activated:Connect(function()
					if self._enabled then guarded() end
				end))
			end

			return self
		end

		function Button:setEnabled(on: boolean)
			self._enabled = on
			local style = on and self._style or styleFor("disabled")
			self.instance.BackgroundColor3 = style.bg or Theme.Color.Panel
			self._label.TextColor3 = style.text
			self._stroke.Color = style.border
			self.instance.Active = on
			if self._glow then self._glow:setActive(false) end
		end

		function Button:setText(t: string)
			self._label.Text = "[ " .. string.upper(t) .. " ]"
		end

		function Button:destroy()
			for _, c in ipairs(self._conns) do
				if typeof(c) == "RBXScriptConnection" then c:Disconnect()
				elseif typeof(c) == "function" then c() end
			end
			if self._glow then self._glow:destroy() end
			self.instance:Destroy()
		end

		return Button

	end

	__loaders[__n_Components_TextInput] = function(script, require)
		--!strict
		-- AmberUI / Components / TextInput.lua
		-- =====================================================================
		-- Champ de saisie CRT ambre. Placeholder, focus state (liseré ambre vif +
		-- curseur "_" clignotant façon terminal), label optionnel. Léger phosphore
		-- (TextStroke) sur le texte saisi.
		--
		-- API :
		--   local TextInput = require(...Components.TextInput)
		--   local f = TextInput.new({ label = "TARGET", placeholder = "value_", onSubmit = fn, parent = frame })
		--   f:getText() / f:setText("x") / f:destroy()
		-- =====================================================================

		local Theme = require(script.Parent.Parent.Theme)
		local Util  = require(script.Parent.Parent.Util)

		local TextInput = {}
		TextInput.__index = TextInput

		type InputProps = {
			label: string?, placeholder: string?, text: string?, clearOnFocus: boolean?,
			layoutOrder: number?, onChanged: ((text: string) -> ())?, onSubmit: ((text: string) -> ())?, parent: Instance?,
		}

		function TextInput.new(props: InputProps)
			local root = Util.make("Frame", {
				Name = "AmberInput", BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, props.label and 56 or 36),
				LayoutOrder = props.layoutOrder or 0, AutomaticSize = Enum.AutomaticSize.Y,
			}, props.parent)
			Util.vlist(4, root)

			if props.label then
				local lbl = Util.make("TextLabel", {
					Name = "FieldLabel", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 14),
					Font = Theme.Font.Mono, Text = string.upper(props.label) .. ":",
					TextColor3 = Theme.Color.NavMuted, TextSize = Theme.Text.Small,
					TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1,
				}, root)
				Util.textConstraint(10, 15, lbl)
			end

			local box = Util.make("TextBox", {
				Name = "Box", BackgroundColor3 = Theme.Color.Inner,
				Size = UDim2.new(1, 0, 0, 36), Font = Theme.Font.Mono,
				Text = props.text or "", PlaceholderText = props.placeholder or "",
				PlaceholderColor3 = Theme.Color.NavMuted, TextColor3 = Theme.Color.Value,
				TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = props.clearOnFocus or false,
				ClipsDescendants = true, BorderSizePixel = 0, LayoutOrder = 2,
				TextStrokeColor3 = Theme.Color.Primary, TextStrokeTransparency = 0.8,
			}, root) :: TextBox
			Util.corner(Theme.Shape.CornerSoft, box)
			Util.paddingXY(12, 0, box)
			Util.textConstraint(11, 18, box)
			Util.sizeConstraint(Vector2.new(60, 32), Vector2.new(math.huge, 50), box)
			local stroke = Util.stroke(Theme.Color.Border, Theme.Shape.Stroke, 0, box)

			local self = setmetatable({ instance = root, _box = box, _stroke = stroke, _conns = {} :: {RBXScriptConnection} }, TextInput)

			table.insert(self._conns, box.Focused:Connect(function()
				Util.tween(stroke, { Color = Theme.Color.Primary, Thickness = Theme.Shape.StrokeThick }, Theme.Motion.Fast)
				Util.tween(box, { BackgroundColor3 = Theme.Color.Inner:Lerp(Theme.Color.Primary, 0.08) }, Theme.Motion.Fast)
			end))
			table.insert(self._conns, box.FocusLost:Connect(function(enterPressed)
				Util.tween(stroke, { Color = Theme.Color.Border, Thickness = Theme.Shape.Stroke }, Theme.Motion.Fast)
				Util.tween(box, { BackgroundColor3 = Theme.Color.Inner }, Theme.Motion.Fast)
				if enterPressed and props.onSubmit then props.onSubmit(box.Text) end
			end))
			if props.onChanged then
				table.insert(self._conns, box:GetPropertyChangedSignal("Text"):Connect(function()
					props.onChanged(box.Text)
				end))
			end

			return self
		end

		function TextInput:getText(): string return self._box.Text end
		function TextInput:setText(t: string) self._box.Text = t end
		function TextInput:destroy()
			for _, c in ipairs(self._conns) do c:Disconnect() end
			self.instance:Destroy()
		end

		return TextInput

	end

	__loaders[__n_Components_Toggle] = function(script, require)
		--!strict
		-- AmberUI / Components / Toggle.lua
		-- =====================================================================
		-- Toggle SIGNATURE du concept : pas de switch graphique mais un libellé
		-- texte [ON]/[OFF] cliquable, comme `.amber-opt .st-on`/`.st-off`.
		--   ON  -> vert #22c55e   OFF -> gris chaud #78716c
		-- Ligne complète : label ambre à gauche + [ON]/[OFF] à droite.
		--
		-- API :
		--   local Toggle = require(...Components.Toggle)
		--   local t = Toggle.new({ label = "AUTO_ATTACK", value = true, onChanged = fn, parent = frame })
		--   t:get() / t:set(bool) / t:destroy()
		-- =====================================================================

		local Theme = require(script.Parent.Parent.Theme)
		local Util  = require(script.Parent.Parent.Util)

		local Toggle = {}
		Toggle.__index = Toggle

		type ToggleProps = {
			label: string?, value: boolean?, layoutOrder: number?,
			onChanged: ((on: boolean) -> ())?, parent: Instance?,
		}

		function Toggle.new(props: ToggleProps)
			local row = Util.make("TextButton", {
				Name = "AmberToggle", Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 30), LayoutOrder = props.layoutOrder or 0,
			}, props.parent) :: TextButton
			Util.sizeConstraint(Vector2.new(0, 26), Vector2.new(math.huge, 42), row)

			local label = Util.make("TextLabel", {
				Name = "Label", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5), Size = UDim2.new(0.65, 0, 1, 0),
				Font = Theme.Font.Mono, Text = props.label or "OPTION", TextColor3 = Theme.Color.Text,
				TextSize = Theme.Text.Body, TextXAlignment = Enum.TextXAlignment.Left,
				TextStrokeColor3 = Theme.Color.Primary, TextStrokeTransparency = Theme.Text.StrokeTransparency,
			}, row)
			Util.textConstraint(11, 18, label)

			local state = Util.make("TextLabel", {
				Name = "State", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5), Size = UDim2.new(0.35, 0, 1, 0),
				Font = Theme.Font.Mono, Text = "[OFF]", TextColor3 = Theme.Color.Off,
				TextSize = Theme.Text.Body, TextXAlignment = Enum.TextXAlignment.Right,
			}, row)
			Util.textConstraint(11, 18, state)

			local self = setmetatable({
				instance = row, _state = state, _value = props.value == true,
				_onChanged = props.onChanged, _conns = {} :: {any},
			}, Toggle)

			local function render(animated: boolean)
				local d = animated and Theme.Motion.Fast or 0
				if self._value then
					self._state.Text = "[ON]"
					Util.tween(self._state, { TextColor3 = Theme.Color.On }, d)
				else
					self._state.Text = "[OFF]"
					Util.tween(self._state, { TextColor3 = Theme.Color.Off }, d)
				end
			end
			self._render = render
			render(false)

			local flip = Util.debounce(function()
				self._value = not self._value
				render(true)
				if self._onChanged then self._onChanged(self._value) end
			end, 0.15)
			table.insert(self._conns, row.Activated:Connect(flip))
			table.insert(self._conns, Util.hover(row,
				function() Util.tween(label, { TextColor3 = Theme.Color.Value }, Theme.Motion.Fast) end,
				function() Util.tween(label, { TextColor3 = Theme.Color.Text }, Theme.Motion.Fast) end
			))

			return self
		end

		function Toggle:get(): boolean return self._value end
		function Toggle:set(on: boolean, silent: boolean?)
			self._value = on
			self._render(true)
			if not silent and self._onChanged then self._onChanged(on) end
		end
		function Toggle:destroy()
			for _, c in ipairs(self._conns) do
				if typeof(c) == "RBXScriptConnection" then c:Disconnect()
				elseif typeof(c) == "function" then c() end
			end
			self.instance:Destroy()
		end

		return Toggle

	end

	__loaders[__n_Components_Slider] = function(script, require)
		--!strict
		-- AmberUI / Components / Slider.lua
		-- =====================================================================
		-- Slider CRT ambre : rail sombre, remplissage ambre avec glow doux, poignée
		-- ambre claire. Valeur affichée façon terminal ("RANGE   85 STUDS").
		-- Souris ET tactile (drag via UserInputService).
		--
		-- API :
		--   local Slider = require(...Components.Slider)
		--   local s = Slider.new({ label = "RANGE", min=0, max=100, value=85, suffix="STUDS", onChanged=fn, parent=frame })
		--   s:get() / s:set(v) / s:destroy()
		-- =====================================================================

		local UserInputService = game:GetService("UserInputService")
		local Theme = require(script.Parent.Parent.Theme)
		local Util  = require(script.Parent.Parent.Util)
		local Glow  = require(script.Parent.Parent.Glow)

		local Slider = {}
		Slider.__index = Slider

		type SliderProps = {
			label: string?, min: number?, max: number?, value: number?, step: number?,
			suffix: string?, layoutOrder: number?, onChanged: ((v: number) -> ())?, parent: Instance?,
		}

		function Slider.new(props: SliderProps)
			local min = props.min or 0
			local max = props.max or 100
			local step = props.step or 1
			local value = math.clamp(props.value or min, min, max)

			local root = Util.make("Frame", {
				Name = "AmberSlider", BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 44), LayoutOrder = props.layoutOrder or 0,
			}, props.parent)
			Util.vlist(6, root)

			local head = Util.make("Frame", { Name = "Head", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 16), LayoutOrder = 1 }, root)
			local lbl = Util.make("TextLabel", {
				BackgroundTransparency = 1, Size = UDim2.new(0.6, 0, 1, 0), Font = Theme.Font.Mono,
				Text = string.upper(props.label or "VALUE"), TextColor3 = Theme.Color.Text, TextSize = Theme.Text.Body,
				TextXAlignment = Enum.TextXAlignment.Left,
			}, head)
			Util.textConstraint(11, 18, lbl)
			local valLbl = Util.make("TextLabel", {
				Name = "Value", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(0.4, 0, 1, 0), Font = Theme.Font.Mono, TextColor3 = Theme.Color.Value,
				TextSize = Theme.Text.Body, TextXAlignment = Enum.TextXAlignment.Right,
			}, head)
			Util.textConstraint(11, 18, valLbl)

			local rail = Util.make("TextButton", {
				Name = "Rail", Text = "", AutoButtonColor = false, BackgroundColor3 = Theme.Color.Inner,
				Size = UDim2.new(1, 0, 0, 6), LayoutOrder = 2, BorderSizePixel = 0,
			}, root) :: TextButton
			Util.corner(UDim.new(0, 3), rail)
			Util.stroke(Theme.Color.Border, 1, 0, rail)
			if Util.isTouch() then rail.Size = UDim2.new(1, 0, 0, 12) end

			local fill = Util.make("Frame", {
				Name = "Fill", BackgroundColor3 = Theme.Color.Primary, Size = UDim2.fromScale(0, 1), BorderSizePixel = 0,
			}, rail)
			Util.corner(UDim.new(0, 3), fill)
			local fillGlow = Glow.attach(fill, { color = Theme.Color.Primary, rest = 0.55, active = 0.3, spread = 12, stroke = false })
			fillGlow:setActive(true)

			local knob = Util.make("Frame", {
				Name = "Knob", BackgroundColor3 = Theme.Color.Value, AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0, 0.5), Size = UDim2.fromOffset(12, 12), BorderSizePixel = 0, ZIndex = 3,
			}, rail)
			Util.aspect(1, knob)
			Util.corner(UDim.new(1, 0), knob) -- poignée ronde (contraste doux avec le CRT)

			local self = setmetatable({
				instance = root, _rail = rail, _fill = fill, _knob = knob, _valLbl = valLbl, _glow = fillGlow,
				_min = min, _max = max, _step = step, _value = value, _suffix = props.suffix,
				_onChanged = props.onChanged, _conns = {} :: {any}, _dragging = false,
			}, Slider)

			local function render()
				local alpha = (self._value - self._min) / (self._max - self._min)
				self._fill.Size = UDim2.fromScale(alpha, 1)
				self._knob.Position = UDim2.fromScale(alpha, 0.5)
				local suffix = self._suffix and (" " .. self._suffix) or ""
				self._valLbl.Text = tostring(self._value) .. suffix
			end
			self._render = render
			render()

			local function setFromX(px: number)
				local rel = math.clamp((px - rail.AbsolutePosition.X) / rail.AbsoluteSize.X, 0, 1)
				local raw = self._min + rel * (self._max - self._min)
				local snapped = math.clamp(math.floor(raw / step + 0.5) * step, self._min, self._max)
				if snapped ~= self._value then
					self._value = snapped
					render()
					if self._onChanged then self._onChanged(snapped) end
				end
			end

			table.insert(self._conns, rail.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					self._dragging = true
					Util.tween(knob, { Size = UDim2.fromOffset(16, 16) }, Theme.Motion.Fast)
					setFromX(input.Position.X)
				end
			end))
			table.insert(self._conns, UserInputService.InputChanged:Connect(function(input)
				if self._dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					setFromX(input.Position.X)
				end
			end))
			table.insert(self._conns, UserInputService.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					if self._dragging then
						self._dragging = false
						Util.tween(knob, { Size = UDim2.fromOffset(12, 12) }, Theme.Motion.Fast)
					end
				end
			end))

			return self
		end

		function Slider:get(): number return self._value end
		function Slider:set(v: number, silent: boolean?)
			self._value = math.clamp(v, self._min, self._max)
			self._render()
			if not silent and self._onChanged then self._onChanged(self._value) end
		end
		function Slider:destroy()
			for _, c in ipairs(self._conns) do
				if typeof(c) == "RBXScriptConnection" then c:Disconnect() end
			end
			self._glow:destroy()
			self.instance:Destroy()
		end

		return Slider

	end

	__loaders[__n_Components_Checkbox] = function(script, require)
		--!strict
		-- AmberUI / Components / Checkbox.lua
		-- =====================================================================
		-- Case à cocher façon terminal : libellé + marqueur "[x]" / "[ ]" ambre.
		-- Pur texte (aucune forme) pour coller à l'esthétique CRT ASCII.
		--
		-- API :
		--   local Checkbox = require(...Components.Checkbox)
		--   local c = Checkbox.new({ label = "AUTO_REJOIN", value = false, onChanged = fn, parent = frame })
		--   c:get() / c:set(bool) / c:destroy()
		-- =====================================================================

		local Theme = require(script.Parent.Parent.Theme)
		local Util  = require(script.Parent.Parent.Util)

		local Checkbox = {}
		Checkbox.__index = Checkbox

		type CheckboxProps = {
			label: string?, value: boolean?, layoutOrder: number?,
			onChanged: ((on: boolean) -> ())?, parent: Instance?,
		}

		function Checkbox.new(props: CheckboxProps)
			local row = Util.make("TextButton", {
				Name = "AmberCheckbox", Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 28), LayoutOrder = props.layoutOrder or 0,
			}, props.parent) :: TextButton
			Util.hlist(8, row)
			Util.sizeConstraint(Vector2.new(0, 24), Vector2.new(math.huge, 38), row)

			local mark = Util.make("TextLabel", {
				Name = "Mark", BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 1, 0), Font = Theme.Font.Mono, Text = "[ ]",
				TextColor3 = Theme.Color.NavMuted, TextSize = Theme.Text.Body, LayoutOrder = 1,
			}, row)
			Util.textConstraint(11, 18, mark)
			local label = Util.make("TextLabel", {
				Name = "Label", BackgroundTransparency = 1, Size = UDim2.new(1, -30, 1, 0),
				Font = Theme.Font.Mono, Text = props.label or "OPTION", TextColor3 = Theme.Color.Text,
				TextSize = Theme.Text.Body, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 2,
			}, row)
			Util.textConstraint(11, 18, label)

			local self = setmetatable({
				instance = row, _mark = mark, _value = props.value == true,
				_onChanged = props.onChanged, _conns = {} :: {any},
			}, Checkbox)

			local function render(animated: boolean)
				local d = animated and Theme.Motion.Fast or 0
				if self._value then
					self._mark.Text = "[x]"
					Util.tween(self._mark, { TextColor3 = Theme.Color.Primary }, d)
				else
					self._mark.Text = "[ ]"
					Util.tween(self._mark, { TextColor3 = Theme.Color.NavMuted }, d)
				end
			end
			self._render = render
			render(false)

			local flip = Util.debounce(function()
				self._value = not self._value
				render(true)
				if self._onChanged then self._onChanged(self._value) end
			end, 0.15)
			table.insert(self._conns, row.Activated:Connect(flip))
			table.insert(self._conns, Util.hover(row,
				function() Util.tween(label, { TextColor3 = Theme.Color.Value }, Theme.Motion.Fast) end,
				function() Util.tween(label, { TextColor3 = Theme.Color.Text }, Theme.Motion.Fast) end
			))

			return self
		end

		function Checkbox:get(): boolean return self._value end
		function Checkbox:set(on: boolean, silent: boolean?)
			self._value = on
			self._render(true)
			if not silent and self._onChanged then self._onChanged(on) end
		end
		function Checkbox:destroy()
			for _, c in ipairs(self._conns) do
				if typeof(c) == "RBXScriptConnection" then c:Disconnect()
				elseif typeof(c) == "function" then c() end
			end
			self.instance:Destroy()
		end

		return Checkbox

	end

	__loaders[__n_Components_Card] = function(script, require)
		--!strict
		-- AmberUI / Components / Card.lua
		-- =====================================================================
		-- Panneau/Carte CRT ambre. Fond .amber-in, bordure interne #241a03,
		-- titre ambre foncé avec séparateur pointillé (rappel `.amber-hd`
		-- border-bottom:1px dashed #3a2c05). Auto-layout vertical.
		--
		-- API :
		--   local Card = require(...Components.Card)
		--   local c = Card.new({ title = "FARM", parent = frame })
		--   c.content -> Frame où empiler les composants
		--   c:destroy()
		-- =====================================================================

		local Theme = require(script.Parent.Parent.Theme)
		local Util  = require(script.Parent.Parent.Util)

		local Card = {}
		Card.__index = Card

		type CardProps = {
			title: string?, size: UDim2?, layoutOrder: number?, parent: Instance?,
		}

		-- Petit helper : bordure pointillée horizontale (suite de tirets).
		local function dashedDivider(parent: Instance, order: number)
			local holder = Util.make("Frame", {
				Name = "DashDivider", BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 6), LayoutOrder = order, ClipsDescendants = true,
			}, parent)
			local lbl = Util.make("TextLabel", {
				BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1),
				Font = Theme.Font.Mono, Text = string.rep("-", 200),
				TextColor3 = Theme.Color.Border, TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
				TextTruncate = Enum.TextTruncate.AtEnd,
			}, holder)
			return holder
		end

		function Card.new(props: CardProps)
			local root = Util.make("Frame", {
				Name = "AmberCard", BackgroundColor3 = Theme.Color.Inner,
				Size = props.size or UDim2.new(1, 0, 0, 0),
				AutomaticSize = props.size and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
				LayoutOrder = props.layoutOrder or 0, BorderSizePixel = 0,
			}, props.parent)
			Util.corner(Theme.Shape.CornerSoft, root)
			Util.stroke(Theme.Color.BorderIn, Theme.Shape.Stroke, 0, root)
			Util.padding(Theme.Space.LG, root)
			local list = Util.vlist(Theme.Space.SM, root)
			list.HorizontalAlignment = Enum.HorizontalAlignment.Left

			if props.title then
				local head = Util.make("TextLabel", {
					Name = "Title", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 18),
					Font = Theme.Font.Mono, Text = string.upper(props.title), TextColor3 = Theme.Color.Header,
					TextSize = Theme.Text.Title, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = -2,
				}, root)
				Util.textConstraint(12, 20, head)
				dashedDivider(root, -1)
			end

			local self = setmetatable({ instance = root, content = root, _list = list }, Card)
			return self
		end

		function Card:destroy() self.instance:Destroy() end

		return Card

	end

	__loaders[__n_Components_Nav] = function(script, require)
		--!strict
		-- AmberUI / Components / Nav.lua
		-- =====================================================================
		-- Barre d'onglets CRT. Reproduit `.amber-nav` : onglets ambre muet, l'actif
		-- prend un fond ambre plein (#fbbf24) avec texte sombre. Petit espacement
		-- entre onglets (gap 8px, pas de fond global comme le CSS).
		--
		-- API :
		--   local Nav = require(...Components.Nav)
		--   local nav = Nav.new({ tabs = {"INFO","FARM","CONFIG"}, active = 1, onChanged = fn, parent = frame })
		--   nav:setActive(2) / nav:getActive() / nav:destroy()
		-- =====================================================================

		local Theme = require(script.Parent.Parent.Theme)
		local Util  = require(script.Parent.Parent.Util)

		local Nav = {}
		Nav.__index = Nav

		type NavProps = {
			tabs: {string}, active: number?, layoutOrder: number?,
			onChanged: ((index: number, name: string) -> ())?, parent: Instance?,
		}

		function Nav.new(props: NavProps)
			local root = Util.make("Frame", {
				Name = "AmberNav", BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 30), LayoutOrder = props.layoutOrder or 0,
			}, props.parent)
			local list = Util.hlist(8, root)
			list.HorizontalAlignment = Enum.HorizontalAlignment.Left

			local self = setmetatable({
				instance = root, _tabs = {} :: {TextButton}, _active = props.active or 1,
				_onChanged = props.onChanged, _conns = {} :: {any},
			}, Nav)

			for i, name in ipairs(props.tabs) do
				local tab = Util.make("TextButton", {
					Name = "Tab_" .. name, Text = string.upper(name), AutoButtonColor = false,
					BackgroundColor3 = Theme.Color.Primary, BackgroundTransparency = 1,
					AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 1, 0),
					Font = Theme.Font.Mono, TextColor3 = Theme.Color.NavMuted, TextSize = Theme.Text.Small,
					BorderSizePixel = 0, LayoutOrder = i,
				}, root) :: TextButton
				Util.paddingXY(8, 4, tab)
				Util.corner(Theme.Shape.CornerSoft, tab)
				Util.textConstraint(10, 15, tab)
				self._tabs[i] = tab

				local select = Util.debounce(function() self:setActive(i) end, 0.1)
				table.insert(self._conns, tab.Activated:Connect(select))
				table.insert(self._conns, Util.hover(tab,
					function() if i ~= self._active then Util.tween(tab, { TextColor3 = Theme.Color.Primary }, Theme.Motion.Fast) end end,
					function() if i ~= self._active then Util.tween(tab, { TextColor3 = Theme.Color.NavMuted }, Theme.Motion.Fast) end end
				))
			end

			self:_render(false)
			return self
		end

		function Nav:_render(animated: boolean)
			local d = animated and Theme.Motion.Normal or 0
			for i, tab in ipairs(self._tabs) do
				if i == self._active then
					Util.tween(tab, { BackgroundTransparency = 0, TextColor3 = Theme.Color.OnPrimary }, d)
				else
					Util.tween(tab, { BackgroundTransparency = 1, TextColor3 = Theme.Color.NavMuted }, d)
				end
			end
		end

		function Nav:setActive(index: number)
			if index == self._active then return end
			self._active = index
			self:_render(true)
			if self._onChanged then self._onChanged(index, self._tabs[index].Text) end
		end

		function Nav:getActive(): number return self._active end

		function Nav:destroy()
			for _, c in ipairs(self._conns) do
				if typeof(c) == "RBXScriptConnection" then c:Disconnect()
				elseif typeof(c) == "function" then c() end
			end
			self.instance:Destroy()
		end

		return Nav

	end

	__loaders[__n_Components_Badge] = function(script, require)
		--!strict
		-- AmberUI / Components / Badge.lua
		-- =====================================================================
		-- Badge / Tag / Status pour le CRT ambre.
		--   Badge.new{...}    -> tag texte encadré ambre
		--   Badge.status{...} -> "▸ RUNNING" (préfixe + libellé) avec glow/pulse
		--   Badge.stat{...}   -> ligne "LABEL           value" (façon .amber-opt)
		--
		-- Tons : primary(ambre) | on(vert) | off(gris) | value(ambre clair)
		--
		-- API status :
		--   local Badge = require(...Components.Badge)
		--   local st = Badge.status({ text = "RUNNING", tone = "on", pulse = true, parent = frame })
		--   st:setText("STOPPED"); st:setTone("off")
		-- =====================================================================

		local Theme = require(script.Parent.Parent.Theme)
		local Util  = require(script.Parent.Parent.Util)
		local Glow  = require(script.Parent.Parent.Glow)

		local Badge = {}

		local TONES = {
			primary = Theme.Color.Primary,
			on      = Theme.Color.On,
			off     = Theme.Color.Off,
			value   = Theme.Color.Value,
			header  = Theme.Color.Header,
		}

		-- --- Tag encadré ------------------------------------------------------
		type TagProps = { text: string?, tone: string?, layoutOrder: number?, parent: Instance? }
		function Badge.new(props: TagProps): TextLabel
			local color = TONES[props.tone or "primary"] or Theme.Color.Primary
			local tag = Util.make("TextLabel", {
				Name = "AmberTag", BackgroundColor3 = Theme.Color.Inner,
				AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.new(0, 0, 0, 20),
				Font = Theme.Font.Mono, Text = string.upper(props.text or "TAG"),
				TextColor3 = color, TextSize = Theme.Text.Small,
				LayoutOrder = props.layoutOrder or 0, BorderSizePixel = 0,
			}, props.parent) :: TextLabel
			Util.paddingXY(8, 3, tag)
			Util.corner(Theme.Shape.CornerSoft, tag)
			Util.stroke(color, 1, 0.5, tag)
			Util.textConstraint(10, 15, tag)
			return tag
		end

		-- --- Status (préfixe ▸ + libellé) ------------------------------------
		type StatusProps = { text: string?, tone: string?, pulse: boolean?, layoutOrder: number?, parent: Instance? }
		local Status = {}
		Status.__index = Status

		function Badge.status(props: StatusProps)
			local tone = props.tone or "on"
			local color = TONES[tone] or Theme.Color.On

			local lbl = Util.make("TextLabel", {
				Name = "AmberStatus", BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.new(0, 0, 0, 18), Font = Theme.Font.Mono,
				Text = "\226\150\184 " .. string.upper(props.text or "RUNNING"), -- ▸
				TextColor3 = color, TextSize = Theme.Text.Body, LayoutOrder = props.layoutOrder or 0,
				TextStrokeColor3 = color, TextStrokeTransparency = 0.6,
			}, props.parent) :: TextLabel
			Util.textConstraint(11, 18, lbl)

			-- Glow doux derrière le texte (halo phosphore).
			local glow = Glow.attach(lbl, { color = color, rest = 0.6, active = 0.3, spread = 14, stroke = false })

			local self = setmetatable({ instance = lbl, _lbl = lbl, _glow = glow }, Status)
			if props.pulse then glow:pulse(Theme.Motion.Pulse) else glow:setActive(true) end
			return self
		end

		function Status:setText(t: string) self._lbl.Text = "\226\150\184 " .. string.upper(t) end
		function Status:setTone(tone: string)
			local color = TONES[tone] or Theme.Color.On
			self._lbl.TextColor3 = color
			self._lbl.TextStrokeColor3 = color
		end
		function Status:destroy() self._glow:destroy(); self.instance:Destroy() end

		-- --- Stat row ("LABEL           value") ------------------------------
		type StatProps = { label: string?, value: string?, tone: string?, layoutOrder: number?, parent: Instance? }
		function Badge.stat(props: StatProps): (Frame, TextLabel)
			local row = Util.make("Frame", {
				Name = "AmberStat", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24),
				LayoutOrder = props.layoutOrder or 0,
			}, props.parent)
			local lbl = Util.make("TextLabel", {
				BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.new(0.6, 0, 1, 0), Font = Theme.Font.Mono, Text = string.upper(props.label or ""),
				TextColor3 = Theme.Color.Text, TextSize = Theme.Text.Body, TextXAlignment = Enum.TextXAlignment.Left,
			}, row)
			Util.textConstraint(11, 18, lbl)
			local val = Util.make("TextLabel", {
				Name = "Value", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.new(0.4, 0, 1, 0), Font = Theme.Font.Mono, Text = props.value or "",
				TextColor3 = TONES[props.tone or "value"] or Theme.Color.Value, TextSize = Theme.Text.Body,
				TextXAlignment = Enum.TextXAlignment.Right,
			}, row)
			Util.textConstraint(11, 18, val)
			return row, val
		end

		return Badge

	end

	__loaders[__n_Components_Modal] = function(script, require)
		--!strict
		-- AmberUI / Components / Modal.lua
		-- =====================================================================
		-- Fenêtre modale CRT ambre : overlay sombre + panneau ambre centré avec
		-- scanlines, animation d'ouverture (fade + rise/scale) et fermeture.
		-- Responsive (Scale + bornes px).
		--
		-- API :
		--   local Modal = require(...Components.Modal)
		--   local m = Modal.new({ title = "CONFIRM", parent = screenGui })
		--   m.content -> Frame (auto vlist)
		--   m:open() / m:close(); m.onClose = fn
		-- =====================================================================

		local Theme = require(script.Parent.Parent.Theme)
		local Util  = require(script.Parent.Parent.Util)
		local Scanlines = require(script.Parent.Parent.Scanlines)

		local Modal = {}
		Modal.__index = Modal

		type ModalProps = { title: string?, width: number?, parent: Instance? }

		function Modal.new(props: ModalProps)
			local overlay = Util.make("TextButton", {
				Name = "AmberModalOverlay", Text = "", AutoButtonColor = false,
				BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 50, BorderSizePixel = 0,
			}, props.parent) :: TextButton

			local panel = Util.make("Frame", {
				Name = "Panel", BackgroundColor3 = Theme.Color.Panel,
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.9, 0), AutomaticSize = Enum.AutomaticSize.Y,
				ZIndex = 51, BorderSizePixel = 0, Active = true, ClipsDescendants = true,
			}, overlay)
			Util.corner(Theme.Shape.Corner, panel)
			Util.stroke(Theme.Color.Border, Theme.Shape.StrokeThick, 0, panel)
			Util.sizeConstraint(Vector2.new(240, 0), Vector2.new(props.width or 410, math.huge), panel)

			-- Scanlines par-dessus le panneau (signature CRT). Posées sur `panel`, qui
			-- n'a PAS de UIListLayout (le layout est sur `inner`) -> pas capturées.
			Scanlines.attach(panel, { flicker = false })

			-- Conteneur interne : porte padding + layout (head + content).
			local inner = Util.make("Frame", {
				Name = "Inner", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 52, BorderSizePixel = 0,
			}, panel)
			Util.padding(Theme.Space.LG, inner)
			local vlist = Util.vlist(Theme.Space.MD, inner)
			vlist.HorizontalAlignment = Enum.HorizontalAlignment.Left

			-- Header : titre ambre + [×].
			local head = Util.make("Frame", {
				Name = "Head", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 24), ZIndex = 52, LayoutOrder = 1,
			}, inner)
			local title = Util.make("TextLabel", {
				BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.new(1, -28, 1, 0), Font = Theme.Font.Mono, Text = string.upper(props.title or "MODAL"),
				TextColor3 = Theme.Color.Header, TextSize = Theme.Text.Title, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 52,
			}, head)
			Util.textConstraint(12, 20, title)
			local closeBtn = Util.make("TextButton", {
				Name = "Close", AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(22, 22), BackgroundTransparency = 1, Text = "[x]",
				Font = Theme.Font.Mono, TextColor3 = Theme.Color.NavMuted, TextSize = 14, ZIndex = 52, AutoButtonColor = false,
			}, head) :: TextButton
			Util.textConstraint(11, 16, closeBtn)

			local content = Util.make("Frame", {
				Name = "Content", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
				AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 52, LayoutOrder = 2,
			}, inner)
			local clist = Util.vlist(Theme.Space.SM, content)
			clist.HorizontalAlignment = Enum.HorizontalAlignment.Left

			local self = setmetatable({
				instance = overlay, panel = panel, content = content,
				onClose = nil :: (() -> ())?, _conns = {} :: {any},
			}, Modal)

			table.insert(self._conns, closeBtn.Activated:Connect(function() self:close() end))
			table.insert(self._conns, overlay.Activated:Connect(function() self:close() end))
			table.insert(self._conns, Util.hover(closeBtn,
				function() Util.tween(closeBtn, { TextColor3 = Theme.Color.Primary }, Theme.Motion.Fast) end,
				function() Util.tween(closeBtn, { TextColor3 = Theme.Color.NavMuted }, Theme.Motion.Fast) end
			))

			return self
		end

		function Modal:open()
			self.instance.Visible = true
			self.instance.BackgroundTransparency = 1
			self.panel.Position = UDim2.fromScale(0.5, 0.54)
			Util.tween(self.instance, { BackgroundTransparency = 0.35 }, Theme.Motion.Normal)
			Util.tween(self.panel, { Position = UDim2.fromScale(0.5, 0.5) }, Theme.Motion.Normal, Enum.EasingStyle.Back)
		end

		function Modal:close()
			Util.tween(self.instance, { BackgroundTransparency = 1 }, Theme.Motion.Normal)
			local t = Util.tween(self.panel, { Position = UDim2.fromScale(0.5, 0.54) }, Theme.Motion.Fast)
			t.Completed:Once(function()
				self.instance.Visible = false
				if self.onClose then self.onClose() end
			end)
		end

		function Modal:destroy()
			for _, c in ipairs(self._conns) do
				if typeof(c) == "RBXScriptConnection" then c:Disconnect()
				elseif typeof(c) == "function" then c() end
			end
			self.instance:Destroy()
		end

		return Modal

	end

	__loaders[__n_Components_Terminal] = function(script, require)
		--!strict
		-- AmberUI / Components / Terminal.lua
		-- =====================================================================
		-- COMPOSANT SIGNATURE du concept "04 Amber Retro".
		-- Reproduit le panneau `.amber` complet : cadre double (bordure externe
		-- #3a2c05 + cadre interne #241a03), gros halo ambre diffus (box-shadow 50px),
		-- SCANLINES CRT en overlay, en-tête façon terminal ("AUTOFARM.EXE  SES#... ▸ uptime").
		-- Draggable (souris + tactile). Corps scrollable auto-layouté.
		--
		-- Responsive : Scale + bornes px + ratio verrouillé.
		--
		-- API :
		--   local Terminal = require(...Components.Terminal)
		--   local term = Terminal.new({ title = "AUTOFARM.EXE", tag = "SES#4821 ▸ 02:14:37", parent = screenGui })
		--   term.body -> ScrollingFrame (auto vlist)
		--   term:setTag("...") / term:destroy()
		-- =====================================================================

		local UserInputService = game:GetService("UserInputService")
		local Theme = require(script.Parent.Parent.Theme)
		local Util  = require(script.Parent.Parent.Util)
		local Glow  = require(script.Parent.Parent.Glow)
		local Scanlines = require(script.Parent.Parent.Scanlines)

		local Terminal = {}
		Terminal.__index = Terminal

		type TerminalProps = {
			title: string?, tag: string?, size: UDim2?, maxWidth: number?,
			parent: Instance?, draggable: boolean?,
		}

		function Terminal.new(props: TerminalProps)
			-- Bordure externe.
			local root = Util.make("Frame", {
				Name = "AmberTerminal", BackgroundColor3 = Theme.Color.Panel,
				AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
				Size = props.size or UDim2.fromScale(0.42, 0.62), BorderSizePixel = 0,
			}, props.parent)
			Util.corner(Theme.Shape.Corner, root)
			Util.stroke(Theme.Color.Border, Theme.Shape.Stroke, 0, root)
			Util.sizeConstraint(Vector2.new(260, 230), Vector2.new(props.maxWidth or 440, 720), root)
			local ratio = Util.aspect(0.7, root)
			ratio.DominantAxis = Enum.DominantAxis.Height

			-- Gros halo ambre diffus (le box-shadow:0 0 50px du .amber).
			local glow = Glow.attach(root, { color = Theme.Color.Primary, rest = Theme.Glow.Rest, active = Theme.Glow.Active, spread = Theme.Glow.Spread, stroke = false })
			glow:setActive(true)

			-- Cadre interne (.amber-in) : padding + bordure interne.
			local inner = Util.make("Frame", {
				Name = "Inner", BackgroundColor3 = Theme.Color.Inner, Size = UDim2.fromScale(1, 1),
				BorderSizePixel = 0, ClipsDescendants = true,
			}, root)
			Util.corner(Theme.Shape.CornerSoft, inner)
			Util.stroke(Theme.Color.BorderIn, Theme.Shape.Stroke, 0, inner)
			Util.padding(Theme.Space.MD, inner)
			Util.vlist(Theme.Space.SM, inner)

			-- Scanlines par-dessus tout : posées sur `root` (qui n'a PAS de UIListLayout)
			-- pour ne pas être capturées comme item de liste. ZIndex élevé -> au-dessus.
			Scanlines.attach(root, { flicker = Theme.Scanline.Flicker })

			-- ---- En-tête terminal (.amber-hd) ----
			local header = Util.make("Frame", {
				Name = "Header", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 26), LayoutOrder = 1, ZIndex = 5,
			}, inner)
			local title = Util.make("TextLabel", {
				Name = "Title", BackgroundTransparency = 1, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.new(0.5, 0, 1, 0), Font = Theme.Font.Mono, Text = props.title or "AUTOFARM.EXE",
				TextColor3 = Theme.Color.Header, TextSize = Theme.Text.Body, TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 5,
			}, header)
			Util.textConstraint(11, 17, title)
			local tag = Util.make("TextLabel", {
				Name = "Tag", BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.new(0.5, 0, 1, 0), Font = Theme.Font.Mono, Text = props.tag or "SES#4821 \226\150\184 02:14:37",
				TextColor3 = Theme.Color.Header, TextSize = Theme.Text.Small, TextXAlignment = Enum.TextXAlignment.Right, ZIndex = 5,
			}, header)
			Util.textConstraint(9, 14, tag)

			-- Séparateur pointillé sous l'en-tête (border-bottom dashed).
			local sep = Util.make("TextLabel", {
				Name = "HeaderSep", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 6), LayoutOrder = 2, ZIndex = 5,
				Font = Theme.Font.Mono, Text = string.rep("-", 200), TextColor3 = Theme.Color.Border, TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd, ClipsDescendants = true,
			}, inner)

			-- ---- Corps scrollable ----
			local body = Util.make("ScrollingFrame", {
				Name = "Body", BackgroundTransparency = 1, Size = UDim2.new(1, 0, 1, -40), LayoutOrder = 3,
				BorderSizePixel = 0, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
				ScrollBarThickness = 3, ScrollBarImageColor3 = Theme.Color.Primary, ScrollBarImageTransparency = 0.3, ZIndex = 5,
			}, inner) :: ScrollingFrame
			local blist = Util.vlist(Theme.Space.SM, body)
			blist.HorizontalAlignment = Enum.HorizontalAlignment.Left

			local self = setmetatable({
				instance = root, body = body, _tag = tag, _header = header, _glow = glow,
				_conns = {} :: {RBXScriptConnection}, _dragging = false,
			}, Terminal)

			-- ---- Drag via l'en-tête (souris + tactile) ----
			if props.draggable ~= false then
				local dragStart: Vector2? = nil
				local startPos: UDim2? = nil
				local dragInput: InputObject? = nil
				-- On rend le header cliquable pour capter les inputs.
				local grip = Util.make("TextButton", {
					Name = "Grip", Text = "", AutoButtonColor = false, BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1), ZIndex = 4,
				}, header) :: TextButton

				table.insert(self._conns, grip.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
						self._dragging = true; dragStart = input.Position; startPos = root.Position; dragInput = input
					end
				end))
				table.insert(self._conns, UserInputService.InputChanged:Connect(function(input)
					if self._dragging and input == dragInput and dragStart and startPos then
						local delta = input.Position - dragStart
						root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
					end
				end))
				table.insert(self._conns, UserInputService.InputEnded:Connect(function(input)
					if input == dragInput then self._dragging = false; dragInput = nil end
				end))
			end

			return self
		end

		function Terminal:setTag(t: string) self._tag.Text = t end

		function Terminal:destroy()
			for _, c in ipairs(self._conns) do c:Disconnect() end
			self._glow:destroy()
			self.instance:Destroy()
		end

		return Terminal

	end

	return __require(__root)
end

local AmberUI = __build_AmberUI()

return AmberUI
