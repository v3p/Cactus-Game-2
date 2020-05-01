local mutantCactus = {}

function mutantCactus:load(param)
	self.type = "CACTUS"
	self.obsolete = false
	self.width = math.floor(drawSize * 0.8)
	self.height = drawSize
	self.jumpHeight = drawSize * 16
	self.x = config.display.width * 1.5
	self.y = param.ground - self.height
	self.yVel = 0
	self.xVel = -param.obstacleSpeed
	self.speed = -param.obstacleSpeed
	self.gameSpeed = param.gameSpeed
	self.gravity = true
	self.grounded = true

	self.jumpDistance = config.display.width * 0.16

	self.quad = {
		love.graphics.newQuad(0, 17, assetSize, assetSize, atlas:getWidth(), atlas:getHeight()),
		love.graphics.newQuad(17, 17, assetSize, assetSize, atlas:getWidth(), atlas:getHeight())
	}

	--Animation
	self.animFrame = 1
	self.animFPS = 3
	self.animTick = 0

	light:new(self.x, self.y, self.height * 5, {0, 0.5, 0}, self)
	light:new(self.x, self.y, self.height * 0.6, {1, 0, 0}, self, self.width / 2, self.height * 0.2)
end

function mutantCactus:jump(height)
	height = height or self.jumpHeight
	if self.grounded then
		self.yVel = -height
		self.grounded = false
		local snd = "jump"
		if state:getState().trip then
			snd = "jumpTrip"
		end
		sound:play(snd)
	end
end

function mutantCactus:update(dt)
	self.xVel = self.speed * self.gameSpeed
	if self.x < -(config.display.width / 2) then
		self.obsolete = true
	end


	if self.grounded then
		self.animTick = self.animTick + dt
		if self.animTick > (1 / self.animFPS) then
			self.animFrame = self.animFrame + 1
			if self.animFrame > 2 then
				self.animFrame = 1
			end
			self.animTick = 0
		end
	else
		self.animFrame = 1
	end

	--Hopping over player
	if not state:getState().ended then
		if self.x > state:getState().player.x then
			if fmath.distance(self.x, 0, state:getState().player.x, 0) < self.jumpDistance then
				self:jump()
			end
		end
	end
end

function mutantCactus:draw()
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.draw(atlas, self.quad[self.animFrame], math.floor(self.x - (drawSize * 0.1)) , math.floor(self.y), 0, drawSize / assetSize, drawSize / assetSize)
end

function mutantCactus:col(c)
	if c.other.type == "PLAYER" then
		if state:getState().lives < 1 then
			state:getState():lose()
		else
			c.other:colResponse()
			self.obsolete = true
		end
	end
end

return mutantCactus