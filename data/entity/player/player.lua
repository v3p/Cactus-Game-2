local player = {}

function player:load(param)
	--Basics
	self.type = "PLAYER"
	self.width = math.floor(drawSize * 0.4)
	self.height = drawSize * 0.85

	self.opacity = 0
	self.target_opacity = 0

	self.slideWidth = drawSize * 0.85
	self.slideHeight = math.floor(drawSize * 0.4)

	self.x = config.display.width * 0.15
	self.y = param.ground - self.height
	self.jumpHeight = drawSize * 16
	self.gravity = true

	self.gameSpeed = param.gameSpeed

	self.xVel = 0
	self.yVel = 0

	self.distanceToGround = 0

	--Image
	self.skins = {
		"Ninja",
		"Classic",
		"CJ",
		"The streaker",
		"Business casual",
		"Deadpool",
		"Batman"
	}
	self.selectedSkin = 0
	self.quadCount = 9

	self.img, self.quad = loadAtlas("data/art/img/player.png", assetSize, assetSize, 0)


	--Animation
	self.animFrame = 1
	self.animFPS = 10
	self.animTick = 0
	self.akdsfjgh = 0

	--State
	self.grounded = true
	self.moving = false
	self.sliding = false
	self.canSlide = true

	self.colItem = "none"

	self.flashAlpha = 0
	self.flashSpeed = 4

	--Slide
	self.slideTime = self.width * 0.03
	self.slideTick = 0
	
	self:setSkin()
end

function player:show()
	self.target_opacity = 1
	screenEffect:ripple(self.x + (self.width / 2), self.y + (self.height / 2), 5, drawSize, {math.random(), math.random(), math.random()})
end

function player:hide(del)
	del = del or true
	self.target_opacity = 0
	screenEffect:ripple(self.x + (self.width / 2), self.y + (self.height / 2), 5, drawSize, {math.random(), math.random(), math.random()})
	if del then
		self.obsolete = true
	end
end

function player:setSkin(id)
	id = id or math.random(#self.skins)
	if id > tableLength(self.skins) - 1 then
		id = 0
	end
	self.selectedSkin = id
end

function player:flash()
	self.flashAlpha = 126
end

function player:run()
	self.moving = true
end

function player:stop()
	self.moving = false
end

function player:slide()
	if self.canSlide and self.grounded then
		self.slideTick = self.slideTime
		self.sliding = true
		self.canSlide = false
		physics:changeItem(self, self.x, self.y, self.slideWidth, self.slideHeight)
	end
end
function player:stopSlide()
	self.sliding = false
	self.canSlide = true
	physics:changeItem(self, self.x, self.y, self.width, self.height)
end

function player:jump(height, silent)
	height = height or self.jumpHeight
	silent = silent or false
	if self.grounded then
		self.yVel = -height
		self.grounded = false
		if not silent then 
			local snd = "jump"
			if state:getState().trip then
				snd = "jumpTrip"
			end
			sound:setPitch(snd, 0.8)
			sound:play(snd) 
		end
		sound:stop("run")
	end
end

--==[[ CALLBACK ]]==--

function player:update(dt)
	--Slide
	if self.sliding then
		self.slideTick = self.slideTick - dt
		if self.slideTick < 0 then
			self:stopSlide()
		end
	end

	--ANIMATION

	local fps = self.animFPS * self.gameSpeed
	if self.moving then
		if self.grounded then
			if self.sliding then
				self.animFrame = 5
			else--RUN
				self.animTick = self.animTick + dt
				if self.animTick > (1 / fps) then
					self.animFrame = self.animFrame + 1
					if self.animFrame > 4 then
						self.animFrame = 1
					end
					self.animTick = 0
				end
			end
		else
			self.animFrame = 2
			self.animTick = 1 / self.animFPS
		end
	end

	if self.grounded and state:getState().started then
		sound:play("run")
	end

	self.distanceToGround = math.abs( (self.y + self.height) - state:getState().ground.y)

	--self.y = self.y + math.floor(self._y - self.y) * (self.smoothFactor * dt)
	self.flashAlpha = self.flashAlpha + math.floor(0 - self.flashAlpha) * (self.flashSpeed * dt)

	self.opacity = self.opacity + (self.target_opacity - self.opacity) * 10 * dt
end

function player:draw()
	love.graphics.setColor(1, 1, 1, self.opacity)
	local xOffset = -(drawSize * 0.3)
	local yOffset = -(drawSize * 0.15)

	--Skin handling
	local frame = self.animFrame + (self.selectedSkin * self.quadCount)

	if not self.grounded then
		yOffset = 0--drawSize * 0.2
	end
	if self.sliding then
		yOffset = -(drawSize * 0.6)
		xOffset = 0
	end
	love.graphics.draw(self.img, self.quad[frame], self.x + xOffset, self.y + yOffset, 0, drawSize / assetSize, drawSize / assetSize)
	
	if self.flashAlpha > 0 then
		setColor(1, 0, 0, self.flashAlpha)
		love.graphics.draw(self.img, self.quad[frame], self.x + xOffset, self.y + yOffset, 0, drawSize / assetSize, drawSize / assetSize)
	end
	
	--[[
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setFont(font.tiny)
	love.graphics.print(tostring(self.slideTick), self.x, self.y - 24)
	]]


	
end

function player:colResponse(c)
	state:getState().lives = state:getState().lives - 1
	self.grounded = true
	self:jump(state:getState().player.jumpHeight * 0.5, true)
	self:flash()

	sound:play("hit")
end

function player:col(c)
	if c.other.type == "cactus" then
		if state:getState().lives < 1 then
			state:getState():lose()
		else
			state:getState().lives = state:getState().lives - 1
			state:getState().player.grounded = true
			state:getState().player:jump(state:getState().player.jumpHeight * 0.5, true)
			state:getState().player:flash()
			--sound:setVolume("hit", 1)
			sound:play("hit")
			c.other.obsolete = true
		end
	elseif c.other.type == "goodCactus" or c.other.type == "funnyCactus" then
		c.other:colResponse(c)
	end
end

return player