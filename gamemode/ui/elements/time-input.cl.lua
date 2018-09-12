TimeInput = TimeInput or Class.New(Element)

local TimeInputPanel = {}

local max_time_digits = 6
local start_padding = 2

local function ZeroString(len)
	len = len or max_time_digits

	local digits = ""

	for i = 1, len do
		digits = digits.."0"
	end

	return digits
end

function TimeInputPanel:Init()
	self:SetMouseInputEnabled(false)
	self:SetUpdateOnType(true)
	
	self.time = "0"
	self.old_caret_pos = max_time_digits
	self.last_caret_pos_change = CurTime()
	self.digit_width = 0
	self.formatted_lookup = {}
	
	self:OffsetCaretPos()
end

function TimeInputPanel:AllowInput(string)
	local allowed

	local is_num = string.find(string, "%d")

	if is_num then
		allowed = true
	else
		allowed = false
	end

	return not allowed
end

function TimeInputPanel:FormatDigits(digits)
	local trimmed_digits = string.TrimLeft(digits, "0")
	local lookup_start = (self.non_zero_i or (max_time_digits + 1)) - 1
	local digits_len = #trimmed_digits

	local time
	local colons

	if tonumber(digits) == 0 then
		time = ""
		colons = ""
	elseif 2 >= digits_len then
		time = trimmed_digits
		colons = ""
	else
		self.formatted_lookup = {
			[0] = lookup_start
		}

		if (digits_len % 2) ~= 0 then
			time = trimmed_digits[1]
			colons = " "
			table.insert(self.formatted_lookup, lookup_start + 1)
		else
			time = string.sub(trimmed_digits, 1, 2)
			colons = "  "
			table.insert(self.formatted_lookup, lookup_start + 1)
			table.insert(self.formatted_lookup, lookup_start + 2)
		end
		
		for i = #time + 1, digits_len, 2 do
			local next_i = i + 1
			local curr_digit = trimmed_digits[i]
			local next_digit = trimmed_digits[next_i]
			local pair = curr_digit..next_digit

			time = time.." "..pair
			colons = colons..":".."  "

			table.insert(self.formatted_lookup, lookup_start + i - 1)
			table.insert(self.formatted_lookup, lookup_start + i)
			table.insert(self.formatted_lookup, lookup_start + next_i)
		end
	end

	self.time = time
	self.colons = colons
end

function TimeInputPanel:OnValueChange(value)
	local text = value
	local value_len = #value
	local caret_pos = self:GetCaretPos()

	if value_len > max_time_digits then
		local trim = max_time_digits - (value_len + 1)

		if self.non_zero_i == 1 and (max_time_digits + 1) > caret_pos then
			text = string.Left(value, trim)
		else
			text = string.Right(value, trim)
			caret_pos = caret_pos - 1
		end
	elseif max_time_digits > value_len then
		text = ZeroString(max_time_digits - value_len)..text
		caret_pos = caret_pos + 1
	end

	self:SetText(text)
	self:OffsetCaretPos(caret_pos)
	self:FormatDigits(text)
end

function TimeInputPanel:ClampCaretPos(new_caret_pos)
	local caret_pos = new_caret_pos or self:GetCaretPos()

	self.non_zero_i = string.find(self:GetText(), "[^0]")

	if self.non_zero_i then
		caret_pos = math.max(caret_pos, self.non_zero_i - 1)
	else
		caret_pos = max_time_digits
	end

	self:SetCaretPos(caret_pos)
end

function TimeInputPanel:GenerateNewCaretPos()
	local caret_pos = self:GetCaretPos()
	local non_zero_i = self.non_zero_i or (max_time_digits + 1)
	local trimmed_caret_pos = caret_pos - non_zero_i + 1

	self.caret_pos_after_colon = trimmed_caret_pos

	if #self:GetText() > 2 then
		local offset_base

		if ((non_zero_i - 1) % 2) == 0 then
			offset_base = trimmed_caret_pos
		else
			offset_base = trimmed_caret_pos + 1
		end

		self.caret_pos_after_colon = trimmed_caret_pos + math.max(math.Round(offset_base/2) - 1, 0)
	end
end

function TimeInputPanel:OffsetCaretPos(new_caret_pos)
	self:ClampCaretPos(new_caret_pos)
	self:GenerateNewCaretPos()
end

function TimeInputPanel:PreventLetters()
	local text = self:GetText()

	if string.find(text, "[^%d]") then
		self:SetText(ZeroString())
		self.time = ""
	end
end

function TimeInputPanel:Think()
	self:PreventLetters()

	if self:HasFocus() then
		local caret_pos = self:GetCaretPos()

		if caret_pos ~= self.old_caret_pos then
			self:OffsetCaretPos()
			self.old_caret_pos = caret_pos
			self.last_caret_pos_change = CurTime()
		end
	end
end

function TimeInputPanel:Paint(w, h)
	local color = self.element:GetAttribute "text_color" or self.element:GetAttribute "color"

	surface.SetFont(self:GetFont())

	surface.SetTextColor(color)
	surface.SetTextPos(start_padding, 0)
	surface.DrawText(self.time)
	
	surface.SetTextColor(ColorAlpha(color, CombineAlphas(color.a, QUARTER_ALPHA) * 255))
	surface.SetTextPos(start_padding - 1, 0)
	surface.DrawText(self.colons)

	self.digit_width = surface.GetTextSize "0"

	surface.SetDrawColor(color)

	if self:HasFocus() and math.Round((CurTime() - self.last_caret_pos_change) % 1) == 0 then
		surface.DrawRect((self.digit_width * self.caret_pos_after_colon) + start_padding, 0, LINE_THICKNESS/2, h - MARGIN)
	end
end

function TimeInputPanel:ManuallySetCaretPos()
	local x, y = self:LocalCursorPos()

	local time_len = #self.time

	self:OffsetCaretPos(self.formatted_lookup[math.Round(math.Clamp((x - start_padding)/(time_len * self.digit_width), 0, 1) * time_len)])
end

function TimeInputPanel:OnCursorEntered()
	self.element.panel:OnCursorEntered()
end

function TimeInputPanel:OnCursorExited()
	self.element.panel:OnCursorExited()
end

function TimeInputPanel:OnMousePressed(mouse)
	self.element.panel:OnMousePressed(mouse)
end

function TimeInputPanel:OnLoseFocus()
	self.element:OnUnFocus()
end

vgui.Register("TimeInputPanel", TimeInputPanel, "DTextEntry")

function TimeInput:Init(props)
	TimeInput.super.Init(self, {
		fit_y = true,
		width = BAR_WIDTH,
		padding_left = MARGIN * 2,
		padding_y = MARGIN * 2,
		background_color = COLOR_GRAY,
		cursor = "beam",
		font = "NumberInfo",
		border = 2,
		border_alpha = 0,
		
		hover = {
			border_alpha = 255
		},

		text_line = Element.New {
			layout = false,
			overlay = true,
			origin_position = true,
			origin_justification_x = JUSTIFY_CENTER,
			origin_justification_y = JUSTIFY_END,
			position_justification_x = JUSTIFY_CENTER,
			position_justification_y = JUSTIFY_END,
			width_percent = 1,
			height = LINE_THICKNESS/2,
			fill_color = true,
			alpha = 0
		}
	})

	self.panel.text = self.panel:Add(vgui.Create "TimeInputPanel")
	self.panel.text.element = self
	self.panel.text:SetFont(self:GetAttribute "font")

	local text = self:GetAttribute "text"

	if not text then
		text = ZeroString()
	end

	self.panel.text:SetText(text)
	self.panel.text:FormatDigits(text)

	if props then
		self:SetAttributes(props)
		self.on_click = props.on_click
	end
end

function TimeInput:OnMousePressed(mouse)
	TimeInput.super.OnMousePressed(self, mouse)
	self.panel.text:ManuallySetCaretPos()
	
	if self.on_click then
		self.on_click(self, mouse)
	end

	self:OnFocus(self)
end

function TimeInput:OnFocus()
	self.panel.text:SetMouseInputEnabled(false)
	self.panel.text:RequestFocus()
	
	hook.Run("TextEntryFocus", self)
	
	self.text_line:AnimateAttribute("alpha", 255)
end

function TimeInput:OnUnFocus()
	hook.Run("TextEntryUnFocus", self)
	self.text_line:AnimateAttribute("alpha", 0)
end