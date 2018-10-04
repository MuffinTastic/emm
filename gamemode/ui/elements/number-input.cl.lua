NumberInput = NumberInput or Class.New(Element)

local NumberInputPanel = {}

function NumberInputPanel:Init()
	self:SetUpdateOnType(true)
end

function NumberInputPanel:Paint(w, h)
	local attr = self.element.attributes
	local color = attr.text_color and attr.text_color.current or self.element:GetColor()

	self:DrawTextEntryText(color, COLOR_GRAY_LIGHTER, color)
end

function NumberInputPanel:AllowInput(string)
	local allowed

	local is_num = string.find(string, "%d")

	if is_num then
		allowed = true
	else
		allowed = false
	end

	return not allowed
end

function NumberInputPanel:OnValueChange(v)
	self.element:OnValueChanged(v)
end

function NumberInputPanel:OnCursorEntered()
	self.element.panel:OnCursorEntered()
end

function NumberInputPanel:OnCursorExited()
	self.element.panel:OnCursorExited()
end

function NumberInputPanel:OnMousePressed(mouse)
	self.element.panel:OnMousePressed(mouse)
end

function NumberInputPanel:OnLoseFocus()
	self.element:OnUnFocus()
end

vgui.Register("NumberInputPanel", NumberInputPanel, "DTextEntry")

local offset = 2

function NumberInput:Init(text, props)
	NumberInput.super.Init(self, {
		fit_y = true,
		width_percent = 1,
		padding_left = MARGIN,
		padding_top = (MARGIN/2) + offset,
		padding_bottom = (MARGIN * 2) - offset,
		background_color = COLOR_GRAY_DARK,
		cursor = "beam",
		font = "NumberInfo",
		border = 2,
		border_alpha = 0,
		
		hover = {
			border_alpha = 255
		},

		text_line = TextInput.CreateTextLine()
	})

	self.value = tostring(text)
	self.panel.text = self.panel:Add(vgui.Create "NumberInputPanel")
	TextInput.SetupPanel(self, text)

	if props then
		self:SetAttributes(props)
		self.on_change = props.on_change
		self.on_click = props.on_click
	end
end

function NumberInput:OnValueChanged(v)
	self.value = v

	if self.on_change then
		self.on_change(self, v)
	end
end

function NumberInput:SetValue(v)
	self.panel.text:SetText(v)
	self.panel.text:OnValueChange(v)
end

function NumberInput:OnMousePressed(mouse)
	NumberInput.super.OnMousePressed(self, mouse)
	
	if self.on_click then
		self.on_click(self, mouse)
	end

	self:OnFocus(self)
end

function NumberInput:OnFocus()
	self.panel.text:RequestFocus()
	hook.Run("TextEntryFocus", self)
	self.text_line:AnimateAttribute("alpha", 255)
end

function NumberInput:OnUnFocus()
	hook.Run("TextEntryUnFocus", self)
	self.text_line:AnimateAttribute("alpha", 0)
end