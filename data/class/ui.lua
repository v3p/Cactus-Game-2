local ui = {
	list = {},
	atlas = false
}

function ui:load()
	self.atlas = lg.newImage("data/art/img/ui.png")
	self.quads = loadAtlas("data/art/img/ui.png", assetSize, assetSize, 0)
	self.smoof = 6
	self.smoofSnap = 1
end


--UTILITY SHIT

function ui:clear()
	self.list = {}
end

--Wrapper for lg.newQuad because it makes shit simpler
function ui:newQuad(x, y, width, height)
	return lg.newQuad(x, y, width, height, self.atlas:getWidth(), self.atlas:getHeight())
end

function ui:getHidePosition(hideDirection, x, y, width, height)
	local hideX, hideY = x, y
	if hideDirection == "top" then
		hideY = -(height * 2)
	elseif hideDirection == "bottom" then
		hideY = lg.getHeight() + (height * 2)
	elseif hideDirection == "left" then
		hideX = -(width * 2)
	elseif hideDirection == "right" then
		hideX = lg.getWidth() + (width * 2)
	end

	return hideX, hideY
end

--ELEMENT CREATING SHIT

--Creates image object.
--Source: Source image, quad: Quad. X & y: Position
--hideDirection: "top", "bottom", "left", "right", Decies where the object goes when hidden
function ui:newImage(quad, x, y, scale, hideDirection)
	local _x, _y, width, height = quad:getViewport()
	width = width * scale
	height = height * scale

	local hideX, hideY = self:getHidePosition(hideDirection, x, y, width, height)
	self.list[#self.list + 1] = {
		type = "image",
		quad = quad,
		hideDirection = hideDirection,
		--Status
		hidden = false,
		offScreen = false,

		--UNSCALED DIMENSIONS!
		width = width,
		height = height,
		scale = scale,
		--Current position
		x = x,
		y = y,
		--target position
		targetX = x,
		targetY = y,
		--Visible position
		visibleX = x,
		visibleY = y,
		--Hidden position
		hiddenX = hideX,
		hiddenY = hideY
	}

	return self.list[#self.list]
end

function ui:newButton(func, text, x, y, scale, width, hideDirection)
	self.list[#self.list + 1] = {
		type = "button",
		func = func,
		text = text

	}
end

--CONTROLLING SHIT
function ui:show(element, instant)
	instant = instant or false

	element.hidden = false
	element.targetX = element.visibleX
	element.targetY = element.visibleY

	if instant then
		element.x = element.targetX
		element.y = element.targetY
	end
end

function ui:hide(element, instant)
	instant = instant or false

	element.hidden = true
	element.targetX = element.hiddenX
	element.targetY = element.hiddenY

	if instant then
		element.x = element.targetX
		element.y = element.targetY
	end
end

function ui:center(element, x, y)

	if x then
		element.visibleX = (lg.getWidth() / 2) - (element.width / 2)
	end
	if y then
		element.visibleY = (lg.getHeight() / 2) - (element.height / 2)
	end

	--Updating hide positions
	local hideX, hideY = self:getHidePosition(element.hideDirection, element.visibleX, element.visibleY, element.width, element.height)
	element.hiddenX = hideX
	element.hiddenY = hideY
end

--CALLBACK SHIT

function ui:update(dt)
	for i,v in ipairs(self.list) do
		--Updating position
		v.x = v.x + (v.targetX - v.x) * self.smoof * dt
		v.y = v.y + (v.targetY - v.y) * self.smoof * dt

		if math.abs(v.x - v.targetX) < self.smoofSnap then
			v.x = v.targetX
		end
		if math.abs(v.y - v.targetY) < self.smoofSnap then
			v.y = v.targetY
		end

	end
end

function ui:draw()
	for i,v in ipairs(self.list) do
		if v.type == "image" then
			lg.setColor(1, 1, 1, 1)
			lg.draw(self.atlas, v.quad, v.x, v.y, 0, v.scale, v.scale)
		end
	end
end

function ui:drawBounds()
	lg.setColor(1, 0, 1, 1)
	for i,v in ipairs(self.list) do
		lg.rectangle("line", v.x, v.y, v.width, v.height)
	end
end

function ui:press(x, y)

end

function ui:release(x, y)

end

return ui