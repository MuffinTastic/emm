Indicator = Indicator or Class.New(Element)

local indicator_material = Material("emm2/shapes/arrow.png", "noclamp smooth")

function Indicator:Init(ply_or_vec)
	Indicator.super.Init(self, {
		layout = false,
		width_percent = 1,
		height_percent = 1,
		inherit_color = false,
		alpha = 0
	})

	if isentity(ply_or_vec) then
		ply_or_vec.indicator = self
		self.player = ply_or_vec
		self.position = ply_or_vec:WorldSpaceCenter()
	elseif isvector(ply_or_vec) then
		self.position = ply_or_vec
	end

	self.distance = LocalPlayer():EyePos():Distance(self.position)

	local x, y = IndicatorService.IndicatorPosition(self)

	self.x = x
	self.y = y

	local function OffScreen()
		return 0 > self.x or self.x > ScrW() or 0 > self.y or self.y > ScrH()
	end

	self.world_alpha = AnimatableValue.New(not OffScreen() and 255 or 0)

	self:SetAttribute("color", function ()
		return GetSmoothPlayerColor(self.player)
	end)

	self.off_screen = AnimatableValue.New(OffScreen(), {
		generate = OffScreen,

		callback = function (anim_v)
			if anim_v.current then
				self.world_alpha:AnimateTo(0)
				self.peripheral:AnimateAttribute("alpha", 255)
			else
				self.world_alpha:AnimateTo(255)
				self.peripheral:AnimateAttribute("alpha", 0)
			end
		end
	})

	self.peripheral = self:Add(Element.New {
		layout = false,
		width = INDICATOR_PERIPHERAL_SIZE,
		height = INDICATOR_PERIPHERAL_SIZE,
		material = indicator_material,
		angle = 0,
		alpha = 0
	})
end

function Indicator:Think()
	Indicator.super.Think(self)

	if self.off_screen.current then
		local attr = self.peripheral.attributes

		local scr_w = ScrW()
		local scr_h = ScrH()
		local half_scr_w = scr_w/2
		local half_scr_h = scr_h/2
		local half_w = attr.width.current/2
		local half_h = attr.height.current/2
		local periph_radius = half_scr_h - half_h

		local x = self.x
		local y = self.y

		local rad_ang = math.atan2(y + (half_h/2) - half_scr_h, x + (half_w/2) - half_scr_w)
		local periph_x = (math.cos(rad_ang) * periph_radius) + half_scr_w
		local periph_y = (math.sin(rad_ang) * periph_radius) + half_scr_h

		attr.x.current = periph_x - half_w
		attr.y.current = periph_y - half_h
		attr.angle.current = -math.deg(rad_ang) + 90

		self.peripheral:Layout()
	end
end

function Indicator:AnimateFinish()
	self:AnimateAttribute("alpha", 0, {
		callback = function ()
			local ent = self.player

			if IsValid(ent) then
				if self == ent.indicator then
					ent.indicator = nil
				end
			end

			self.world_alpha:Finish()
			self.off_screen:Finish()
			Indicator.super.Finish(self)
		end
	})
end

function Indicator:Finish()
	self:AnimateFinish()
end