local game = {}

local gameOverLines = {
	"wasted",
	"you fucked up",
	"you got fucked up",
	"you got dead",
	"lol u suck",
	"better luck next time",
	"R.I.P",
	"u dead",
	"that looked like it hurt",
	"stings doesn't it?",
	"you're dead",
	"Cluckity fucked",
	"hahahahahahahaha",
	"<==3"

}

--USER INTERFACE
--Button callbacks
function startButton(e)
	game:start()
end

function resetButton(e)
	game:reset()
end

function exitButton(e)
	love.event.push("quit")
end

--Screen creation
function game:createStartup()
	--UI
	ui:clear()

	--Panel
	self.mainPanel = ui:newPanel({0, 0, 0, 0.4}, 0, 0, lg.getWidth() / 2, lg.getHeight(), "top")
	ui:center(self.mainPanel, true, false)
	ui:hide(self.mainPanel, true)
	ui:setScreen(self.mainPanel, "main")

	--Title
	local titleQuad = ui:newQuad(0, 16, 77, 32)
	--ui:newImage(quad, x, y, scale, hideDirection)
	self.title = ui:newImage(false, titleQuad, 0, lg.getHeight() * 0.1, (drawSize / assetSize) * 1.4, "left")

	ui:center(self.title, true, false)
	ui:hide(self.title, true)
	ui:setScreen(self.title, "main")

	--Start button
	--ui:newButton(func, text, x, y, width, height, hideDirection)
	self.startButton = ui:newButton(startButton, "Start", 0, lg.getHeight() * 0.6, drawSize * 5, drawSize * 2, "right")

	ui:setFont(self.startButton, font.large)

	ui:center(self.startButton, true, false)
	ui:hide(self.startButton, true)
	ui:setScreen(self.startButton, "main")

	--Exit button
	self.exitButton = ui:newImage(exitButton, ui.quad[4], drawSize * 0.1, lg.getHeight() - (drawSize * 1.7), (drawSize / assetSize) * 1.6, "bottom")

	ui:hide(self.exitButton, true)
	ui:setScreen(self.exitButton, "main")

	---func, text, x, y, font, color, hideDirection)
	self.subtitle = ui:newText(false, SUBTITLE, 0, lg.getHeight() * 0.45, font.tiny, {0.9, 0.1, 0.1}, "top")
	ui:center(self.subtitle, true, false)
	ui:hide(self.subtitle, true)
	ui:setScreen(self.subtitle, "main")
end

function game:createIngame()
	self.distanceLogo = ui:newImage(false, ui.quad[28], lg.getWidth() * 0.01, lg.getHeight() * 0.85, (drawSize / assetSize) * 1.4, "left")
	ui:hide(self.distanceLogo, true)
	ui:setScreen(self.distanceLogo, "ingame")

	self.ingameScore = ui:newText(false, "0", lg.getWidth() * 0.11, lg.getHeight() * 0.87, font.small, {0.9, 0.9, 0.9}, "bottom")
	ui:hide(self.ingameScore, true)
	ui:setScreen(self.ingameScore, "ingame")
end

function game:createEndgame()
	--Destroy
	ui:clear()

	self.resetButton = ui:newButton(resetButton, "RESET", 0, lg.getHeight() * 0.6, drawSize * 5, drawSize * 2, "left")

	ui:setFont(self.resetButton, font.large)

	ui:center(self.resetButton, true, false)
	ui:hide(self.resetButton, true)
	ui:setScreen(self.resetButton, "endgame")


	self.gameOverText = ui:newText(false, gameOverLines[math.random(#gameOverLines)], 0, lg.getHeight() * 0.2, font.large, {0.8, 0.2, 0.2}, "top")
	ui:center(self.gameOverText, true, false)
	ui:hide(self.gameOverText, true)
	ui:setScreen(self.gameOverText, "endgame")

	self.scoreText = ui:newText(false, "You made it "..(math.floor(self.distance * 100) / 100).." meters", 0, lg.getHeight() * 0.85, font.small, {0.1, 0.9, 0.2}, "left")
	ui:center(self.scoreText, true, false)
	ui:hide(self.scoreText, true)
	ui:setScreen(self.scoreText, "endgame")

	self.exitButton = ui:newImage(exitButton, ui.quad[4], drawSize * 0.1, lg.getHeight() - (drawSize * 1.7), (drawSize / assetSize) * 1.6, "bottom")

	ui:hide(self.exitButton, true)
	ui:setScreen(self.exitButton, "endgame")
end

--Showing
function game:showStartup()
	ui:showScreen("main")
end

function game:showIngame()
	ui:showScreen("ingame")
end

function game:showEndgame()
	ui:showScreen("endgame")
	ui:show(self.exitButton)
end

--Hiding
function game:hideStartup()
	ui:hideScreen("main")
end

function game:hideIngame()
	ui:hideScreen("ingame")
end

function game:hideEndgame()
	ui:hideScreen("endgame")
end

function game:load()
	self.canvas = {
		entity = love.graphics.newCanvas(config.display.width, config.display.height),
		gui = love.graphics.newCanvas(config.display.width, config.display.height),
		shader = love.graphics.newCanvas(config.display.width, config.display.height)
	}

	self.button = {}

	self.first = true
	sky:load()

	--Creating UI
	self:createStartup()

	self:reset()
end

function game:reset()
	physics:load()
	light:load()
	sky:createLights()

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

	screenEffect:flash(3, {0, 0, 0})

	--UI
	self:createStartup()
	self:showStartup()
end

function game:start()
	self:createIngame()
	self.started = true
	self.player:run()
	self.player:show()
	sound:play("run")
	ui:hideScreen("main")
	ui:showScreen("ingame")
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

	--UI
	ui:hideScreen("ingame")
	ui:deleteScreen("endgame")
	self:createEndgame()
	ui:showScreen("endgame")
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
		self.ingameScore.text = math.floor(self.distance * 100) / 100

		self.gameSpeedTick = self.gameSpeedTick + dt
		if self.gameSpeedTick > self.gameSpeedTime then
			self.gameSpeed = self.gameSpeed + 0.05
			self.player.gameSpeed = self.gameSpeed
			self.gameSpeedTick = 0
		end

	end

	--Dead slow motion
	ui:update(dt)
	if self.ended then
		dt = dt / 8
	end

	sky:update(dt)
	game:updateObstacles(dt)
	entity:update(dt)
	physics:update(dt)
	sound:update(dt)

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
		ui:show(self.startButton)
	elseif key == "p" then
		ui:hide(self.title)
		ui:hide(self.startButton)
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
end

function game:input(x, y, t)
	if self.takeInput then
		if not ui:press(x, y) then
			if y < self.ground.y then
				self.player:jump()
			else
				self.player:slide()
			end
		end
	end
end

return game