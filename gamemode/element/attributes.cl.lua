local animatable_attributes = {
	"x",
	"y",
	"width",
	"height",
	"padding_left",
	"padding_top",
	"padding_right",
	"padding_bottom",
	"crop_left",
	"crop_top",
	"crop_right",
	"crop_bottom",
	"child_margin",

	color = COLOR_WHITE,
	background_color = COLOR_BLACK_CLEAR,
	alpha = 255,
	border = 0,
	border_alpha = 255
}

local optional_attributes = {
	"duration",
	"overlay",
	"origin_x",
	"origin_y",
	"width_percent",
	"height_percent",
	"angle",
	"text_color",
	"border_color",
	"cursor"
}

local layout_invalidators = {
	"origin_x",
	"origin_y",
	"fit_x",
	"fit_y",
	"x",
	"y",
	"width",
	"height",
	"width_percent",
	"height_percent",
	"padding_left",
	"padding_top",
	"padding_right",
	"padding_bottom",
	"crop_left",
	"crop_top",
	"crop_right",
	"crop_bottom",
	"child_margin"
}

function Element:InitAttributes()
	self.static_attributes = {
		paint = true,
		layout = true,
		origin_position = false,
		origin_justification_x = JUSTIFY_START,
		origin_justification_y = JUSTIFY_START,
		position_justification_x = JUSTIFY_START,
		position_justification_y = JUSTIFY_START,
		self_adjacent_justification = JUSTIFY_INHERIT,
		layout_justification_x = JUSTIFY_START,
		layout_justification_y = JUSTIFY_START,
		layout_direction = DIRECTION_ROW,
		wrap = true,
		fit_x = false,
		fit_y = false,
		inherit_color = true,
		fill_color = false,
		inherit_cursor = true,
		bubble_mouse = true
	}

	self.optional_attributes = {}
	
	for _, k in pairs(optional_attributes) do
		self.optional_attributes[k] = true
	end
	
	self.layout_invalidators = {}
	
	for _, k in pairs(layout_invalidators) do
		self.layout_invalidators[k] = true
	end

	self.attributes = {}

	for k, v in pairs(animatable_attributes) do
		local props

		if self.layout_invalidators[v] then
			props = {
				debounce = 1/60,
	
				callback = function ()
					if IsValid(self.panel) then
						self.panel:InvalidateLayout(true)
					end
				end
			}
		end

		if isnumber(k) then
			self.attributes[v] = AnimatableValue.New(0, props)
		else
			self.attributes[k] = AnimatableValue.New(v, props)
		end
	end
end

function Element:SetTextJustification(justify)
	self.panel.text:SetContentAlignment(justify)
end

function Element:SetFont(font)
	self.panel.text:SetFont(font)
end

function Element:SetText(text)
	text = tostring(text)
	
	local old_text = self.panel.text:GetText()

	if text ~= old_text then
		self.panel.text:SetText(text)
		self:LayoutText(text)
	end
end

function Element:SetAttribute(k, v, no_layout)
	local static_attr = self.static_attributes
	local attr = self.attributes
	local layout_invalidator = self.layout_invalidators[k]

	local old_v

	if layout_invalidator then
		old_v = self:GetAttribute(k)
	end

	if static_attr[k] ~= nil then
		static_attr[k] = v
	elseif attr[k] ~= nil then
		if self.optional_attributes[k] ~= nil and v == false then
			attr[k]:Finish()
			attr[k] = nil
		elseif Class.InstanceOf(v, AnimatableValue) then
			attr[k]:Finish()
			attr[k] = v
		elseif isfunction(v) then
			attr[k].generate = v
		else
			attr[k].current = v
		end
	elseif self.setters[k] then
		self.setters[k](self, static_attr, attr, v)
	elseif self.optional_attributes[k] ~= nil then
		if Class.InstanceOf(v, AnimatableValue) then
			attr[k] = v
		else
			attr[k] = AnimatableValue.New(v)
		end
	elseif Class.InstanceOf(v, Element) then
		local element = self:Add(v)

		if isstring(k) then
			self[k] = element
		end
	elseif self.reserved_states[k] then
		self:AddState(k, v)
	else
		static_attr[k] = v
	end

	if not no_layout and layout_invalidator and (
		(static_attr[k] ~= nil) or (old_v and not self.laying_out and isnumber(v) and math.Round(v, 3) ~= math.Round(old_v, 3))
	) then
		self.panel:InvalidateLayout(true)
	end
end

function Element:SetAttributes(attr)
	for k, v in pairs(attr) do
		self:SetAttribute(k, v, true)
	end

	if not self.laying_out then
		self.panel:InvalidateLayout(true)
	end
end

function Element:GetAttribute(k)
	local attr

	if k == "color" and self.static_attributes.inherit_color and self.parent then
		attr = self.parent:GetAttribute "color"
	elseif self.attributes[k] then
		attr = self.attributes[k].smooth or self.attributes[k].current
	elseif self.static_attributes[k] then
		attr = self.static_attributes[k]
	end

	return attr
end

function Element:AnimateAttribute(k, v, ...)
	self.attributes[k]:AnimateTo(v, ...)
end
