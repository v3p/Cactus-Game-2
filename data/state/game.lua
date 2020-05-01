local game = {}

function game:load()
	self.canvas = {
		entity = love.graphics.newCanvas(config.display.width, config.display.height),
		gui = love.graphics.newCanvas(config.display.width, config.display.height),
		shader = love.graphics.newCanvas(config.display.width, config.display.height)
	}

	self.first = true
	sky:load()

	self:reset()
end

function game:reset()
	physics:load()
	light:load()
	sky:createLights()

	--UI
	ui:clear()
	--Title
	local titleQuad = ui:newQuad(0, 16, 76, 31)
	--ui:newImage(quad, x, y, scale, hideDirection)
	self.title = ui:newImage(titleQuad, 0, lg.getHeight() * 0.2, (drawSize / assetSize) * 1.4, "left")

	ui:center(self.title, true, false)
	ui:hide(self.title, true)
	ui:show(self.title)

	--Creating World
	self.ground = {
		x = 0,
		y = math.floor(config.display.height * 0.8),
		width = config.display.width * 2,
		height = config.display.height - math.floor(config.display.height * 0.8),
		color = {219, 212, 135, 255},
		type = "GROUND"
	}
	--GAME VARIABLES
	--State
	self.started = false
	self.paused = false
	self.ended = false
	self.newHighScore = false
	self.distance = 0
	self.lives = 0

	self.inputDelay = 1
	self.inputDelayTick = 0
	self.takeInput = true

	--settings
	self.gameSpeed = 1
	self.gameSpeedTick = 0
	self.gameSpeedTime = 10
	self.time = 0

	--Obstacles
	self.obstacleSpawnRate = 0.5
	self.obstacleSpawnTick = 0
	self.obstacleSpeed = config.display.width * 0.5

	--Creating Entities
	entity:clear()

	physics:add(self.ground)
	self.player = entity:spawn("player", {ground = self.ground.y, gameSpeed = self.gameSpeed}, "player")

	self.trip = false
	self.tripDuration = 8
	self.tripMagnitude = 1
	self.tripTick = 0
	self.tripRising = false
	self.tripRiseSpeed = 1

	if self.first then
		self.first = false
	end

	wave:send("strength", 1)
	self:setVolume()
	sound:stopAll()
	sound:play("main_theme")
	sound:setVolume("main_theme", 0.6)

	screenEffect:flash(5, {0, 0, 0})
end

function game:start()
	self.started = true
	self.player:run()
	self.player:show()
	ui:hide(self.title)
	sound:play("run")

end

function game:lose()
	sound:stopAll()
	game:stopTrip()
	sound:play("game_over")
	screenEffect:shake()
	self.player:hide()

	--Input Delay
	self.takeInput = false
	self.inputDelayTick = self.inputDelay

	self.ended = true

	--High score
	if self.distance > config.stats.topDistance then
		self.newHighScore = true
		config.stats.topDistance = math.floor(self.distance * 100) / 100
	end
	config.stats.totalDistance = config.stats.totalDistance + math.floor(self.distance * 100) / 100

	saveConfig()
	--sound:setVolume("hit", 0.1)
	sound:play("hit")
	sound:play("death", 0.05)
	sound:stop("run")
end

function game:pause()
	if self.started and not self.lost then
		self.paused = true
		sound:stop("run")
	end
end

function game:resume()
	self.paused = false
	sound:play("run")
end

function game:addLife()
	self.lives = self.lives + 1
	sound:play("life")
end

function game:startTrip()
    self.player:setSkin()
	if self.trip then
		self.tripTick = self.tripDuration
	else
		self.trip = true
		self.tripRising = true
		self.tripMagnitude = 0
		self.tripTick = self.tripDuration
	end
	sound:play("trip")
end

function game:stopTrip()
	self.trip = false
	self.tripRising = false
	self.tripMagnitude = 0
	self.tripTick = 0
	sound:stopAll()
end

function game:setVolume(c)
	c = c or false
	if c then
		config.sound.volume = config.sound.volume - 0.25
		if config.sound.volume < 0.25 then
			config.sound.volume = 1
		end
	end

	local realVolume = config.sound.volume
	if config.sound.volume == 0.25 then
		realVolume = 0
	end

	sound:setMasterVolume(realVolume)
end

function game:spawnObstacle()
	--Deciding type
	local r = love.math.random()
	local type = "cactus"
	if r < 0.5 then
		r = love.math.random()
		if r > 0.2 then
			type = "mutantCactus"
		elseif r > 0.1 then
			type = "imposterCactus"
		else
			type = "funnyCactus"
		end
	end
	--type = "funnyCactus"
	
	--Spawning
	local c = entity:spawn(type, {ground = self.ground.y, obstacleSpeed = self.obstacleSpeed, gameSpeed = self.gameSpeed})
	physics.add(c)
end

--==[[ UPDATING ]]==--

function game:updateObstacles(dt)
	if self.started and not self.paused and not self.ended then
		self.obstacleSpawnTick = self.obstacleSpawnTick + (dt * self.gameSpeed)
		if self.obstacleSpawnTick > (1 / self.obstacleSpawnRate) then
			game:spawnObstacle()
			--Double Spawn
			local r = math.random()
			if r < 0.4 then
				self.obstacleSpawnTick = (1 / self.obstacleSpawnRate)  / 2
			else
				self.obstacleSpawnTick = 0
			end
		end
	end
end

function game:update(dt)
	if self.trip then
		if self.tripRising then
			self.tripMagnitude = self.tripMagnitude + (self.tripRiseSpeed * dt)
			dt = dt / (self.tripMagnitude + 1)
			wave:send("strength", self.tripMagnitude )
			color:send("strength", self.tripMagnitude )

			if self.tripMagnitude > 1 then
				self.tripMagnitude = 1
				self.tripRising = false
			end
		else
			self.tripTick = self.tripTick - dt
			self.tripMagnitude = fmath.normal(self.tripTick, 0, self.tripDuration)
			dt = dt / (self.tripMagnitude + 1)
			wave:send("strength", self.tripMagnitude )
			color:send("strength", self.tripMagnitude )

			if self.tripTick < 0 then
				self.tripTick = 0
				self.trip = false
			end
		end
	end

	self.time = self.time + dt
	if self.time > math.pi then time = 0 end
	wave:send("time", self.time)
	color:send("time", self.time)

	--Input Delay
	if not self.takeInput then
		self.inputDelayTick = self.inputDelayTick - dt
		if self.inputDelayTick < 0 then
			self.inputDelayTick = 0
			self.takeInput = true
		end
	end

	if self.started and not self.ended and not self.paused then
		local timeScale = 1
		if self.trip then
			timeScale = timeScale * 2
		end
		self.distance = self.distance + (dt * (self.gameSpeed * timeScale) )

		self.gameSpeedTick = self.gameSpeedTick + dt
		if self.gameSpeedTick > self.gameSpeedTime then
			self.gameSpeed = self.gameSpeed + 0.05
			self.player.gameSpeed = self.gameSpeed
			self.gameSpeedTick = 0
		end

	end

	if self.ended then
		dt = dt / 8
	end

	sky:update(dt)
	game:updateObstacles(dt)
	entity:update(dt)
	physics:update(dt)
	sound:update(dt)
	ui:update(dt)

	if self.ended then
		dt = dt * 8
	end

	popup:update(dt)

	--Sound killer
	if self.ended or self.paused then
		sound:stop("run")
	end
end

--==[[ DRAWING ]]==--


function game:drawTrip()
	love.graphics.setCanvas(self.canvas.shader)
	
	lg.translate(self.player.x, self.player.y)
	lg.scale(1 + (math.cos(self.time * 0.2) * (self.tripMagnitude * 0.01)) + (0.2 * self.tripMagnitude))
	lg.rotate(math.sin(self.time) * (self.tripMagnitude * 0.05))
	lg.translate(-(self.player.x), -(self.player.y))

	color:draw(function()

	sky:draw()

	--Ground
	setColor(self.ground.color)
	love.graphics.rectangle("fill", 0, self.ground.y, config.display.width, config.display.height - self.ground.y)


	love.graphics.setBlendMode("alpha", "premultiplied")
	setColor(255, 255, 255, 255)
	love.graphics.draw(self.canvas.entity)

	light:draw()
	end)
	love.graphics.setCanvas()

	wave:draw(function()
		setColor(255, 255, 255, 255)
		love.graphics.draw(self.canvas.shader)
	end)
end

function game:drawLose()
	love.graphics.setCanvas(self.canvas.shader)
	
	bw:draw(function()

	sky:draw()

	--Ground
	setColor(self.ground.color)
	love.graphics.rectangle("fill", 0, self.ground.y, config.display.width, config.display.height - self.ground.y)


	love.graphics.setBlendMode("alpha", "premultiplied")
	setColor(255, 255, 255, 255)
	love.graphics.draw(self.canvas.entity)

	light:draw()
	end)
	love.graphics.setCanvas()

	setColor(255, 255, 255, 255)
	love.graphics.draw(self.canvas.shader)
end


function game:draw()

	--Entity
	love.graphics.setCanvas(self.canvas.entity)
	love.graphics.clear()
	entity:draw()


	--UI
	love.graphics.setCanvas(self.canvas.gui)
	love.graphics.clear()
	ui:draw()
	love.graphics.setCanvas()


	if self.trip then
		self:drawTrip()
    elseif self.ended then
        self:drawLose()
	else
		sky:draw()

		--Ground
		setColor(self.ground.color)
		love.graphics.rectangle("fill", 0, self.ground.y, config.display.width, config.display.height - self.ground.y)


		love.graphics.setBlendMode("alpha", "premultiplied")
		setColor(255, 255, 255, 255)
		love.graphics.draw(self.canvas.entity)
		light:draw()
	end


	--Vignette
	setColor(255, 255, 255, 100)
	love.graphics.draw(vignette, 0, 0, 0, config.display.width / vignette:getWidth(), config.display.height / vignette:getHeight())
	
	--UI Shadow
	setColor(0, 0, 0, 30)
	love.graphics.draw(self.canvas.gui, math.floor( -(config.display.width * 0.003)), 0)

	setColor(255, 255, 255, 255)
	love.graphics.draw(self.canvas.gui)
	love.graphics.setBlendMode("alpha")
end


function game:resize()
	self:load()
end

function game:keypressed(key)
	if key == "o" then
		ui:show(self.title)
	elseif key == "p" then
		ui:hide(self.title)
	end


	if self.takeInput then
		if key == config.controls.jump then
			if not self.started then
				self:start()
			elseif self.paused then
				self:resume()
			elseif self.ended then
				self:reset()
			else
				self.player:jump()
			end
		end

		if key == config.controls.pause then
			self:pause()
		elseif key == config.controls.slide then
			if self.started then
				self.player:slide()
			end
		elseif key == "up" then
			self.player:setSkin()
		end
	end
end

function game:keyreleased()
	if self.takeInput then
		self.player:stopSlide()
	end
end

function game:touchpressed(id, x, y, dx, dy, pressure)
	if platform == "mobile" then
		self:input(x, y, "press")
	end
end

function game:touchreleased(id, x, y, dx, dy, pressure)
	if platform == "mobile" then
		self:input(x, y, "release")
	end
end

function game:mousepressed(x, y, key)
	if platform == "pc" then
		self:input(x, y, "mouse")
	end

	--popup:new(heart, config.display.width / 2, config.display.height / 2)
end

function game:input(x, y, t)
	if self.takeInput then
		if y < self.ground.y then
			if t == "press" or t == "mouse" then
				if self.started and not self.paused and not self.ended then
					self.player:jump()
				else
					ui:press(x, y)
				end
			end
		else
			if t == "release" or t == "mouse" then
				for i,v in pairs(self.textObject) do
					v:release(x, y)
				end
			end
		end
	end
end

return game