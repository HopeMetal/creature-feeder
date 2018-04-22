local spider = {}
local ball = {}
local bloodimg
local bloodsystem

local ballblood

local feedbutton = love.graphics.newImage("img/foodbutton.png")
local ballbutton = love.graphics.newImage("img/ballbutton.png")
local foodimg = love.graphics.newImage("img/food.png")

local sndball = love.audio.newSource("snd/ball.wav", "static")
local sndfood = love.audio.newSource("snd/food.wav", "static")
local sndeat = love.audio.newSource("snd/monster_eat.wav", "static")
local sndhappy = love.audio.newSource("snd/monster_happy.wav", "static")
local sndmove = {love.audio.newSource("snd/monster_idle1.wav", "static"),
                 love.audio.newSource("snd/monster_idle2.wav", "static"),
                 love.audio.newSource("snd/monster_idle3.wav", "static")}
local sndangry = love.audio.newSource("snd/monster_angry.wav", "static")


local win_w = love.graphics.getWidth()
local win_h = love.graphics.getHeight()

local feedEnabled
local feedtime
local feedDelay
local feedNum

local ballEnabled
local balltime
local ballDelay

local inAction
-- actions: no, feed, ball, throw

local dead
local horror

local function makeButton(img, x, y, w, h)
    local btn = {img, x, y, w, h, clicked = false, enabled = true}
    return btn
end

local buttons = {ball = makeButton(ballbutton, win_w - 144, win_h - 80, 64, 64),
                 feed = makeButton(feedbutton, win_w - 72, win_h - 80, 64, 64)
                }

local function init()
    feedEnabled = true
    feedtime = 0
    feedDelay = 4
    feedNum = 0
    inAction = "no"

    ballEnabled = true
    balltime = 0
    ballDelay = 12

    spider.x = win_w / 2
    spider.y = win_h / 2 + 40
    spider.mov_x = 1 -- 1 ore -1 depending on direction
    spider.mov_dist = 0
    spider.body = 80
    spider.hunger = 0.5
    spider.boredom = 0
    spider.htime = 0
    spider.btime = 0
    spider.hrate = 0.7
    spider.brate = 2
    spider.ctime = 0

    ball.x = 0
    ball.y = 0
    ball.xspeed = 0
    ball.yspeed = 0
    ball.gravity = 30
    ball.mov_dist = 0
    ball.bouncey = 0
    ball.bounceratey = 32
    ball.bouncex = 0
    ball.bounceratex = 32
    ball.time = 0
    ball.active = false
    ball.throw = false

    dead = false;

    buttons.ball.enabled = true
    buttons.feed.enabled = true
    buttons.ball.clicked = false
    buttons.feed.clicked = false
end

local function playsound(snd)
    if snd:isPlaying() then
        snd:stop()
    end
    snd:play()
end

local function playidlesound()
    for i = 1, #sndmove do
        if not sndmove[i]:isPlaying() then
            playsound(sndmove[math.random(#sndmove)])
            break
        end
    end
end

local function fnfeed()
    --spider.hunger = 0
    feedEnabled = false
    inAction = "feed"
    love.mouse.setVisible(false)
    playsound(sndfood)
end

local function fnball()
    print("ball")
    ballEnabled = false
    inAction = "ball"
    love.mouse.setVisible(false)
end

local button_actions = {feed = fnfeed,
                        ball = fnball}

local mouseclicks = {}

local foodDelays = {[5] = 6, [10] = 8}

local font = love.graphics.newFont("fonts/DejaVuSans.ttf", 16)
local midfont = love.graphics.newFont("fonts/DejaVuSans.ttf", 24)
local bigfont = love.graphics.newFont("fonts/DejaVuSans.ttf", 48)

local function feedStatus(dt)
    if foodDelays[feedNum] then
        feedDelay = foodDelays[feedNum]
    end
    if not feedEnabled then
        if feedtime >= feedDelay then
            feedtime = feedtime - feedDelay
            feedEnabled = true
            buttons.feed.enabled = true
        end
        if inAction ~= "feed" then
            feedtime = feedtime + dt
        end
    end
end

local ball_xold, ball_yold
local function ballStatus(dt)
    if not ballEnabled then
        if balltime >= ballDelay then
            balltime = balltime - ballDelay
            ballEnabled = true
            buttons.ball.enabled = true
        end
        if inAction ~= "ball" and inAction ~= "throw" then
            balltime = balltime + dt
        end
    end
    if ball.active then
        if ball.time >= 4 then
            ball.time = ball.time - 4
            inAction = "no"
            love.mouse.setVisible(true)
            ball_xold = ball.x
            ball_yold = ball.y
            ballblood:emit(80)
            ball:reset()
        end
        if ball.xspeed + ball.yspeed == 0 then
            ball.time = ball.time + dt
        end
    end
end

local selectmode = true
function love.load()
    init()

    bloodimg = love.graphics.newImage("img/blood.png")
    bloodsystem = love.graphics.newParticleSystem(bloodimg, 200)
    bloodsystem:setSizes(0.01, 0.2, 0.01)
    bloodsystem:setParticleLifetime(0.6, 1.1)
    bloodsystem:setEmissionRate(0)
    bloodsystem:setLinearAcceleration(-40, 0, 40, 20)
    bloodsystem:setSpeed(64)
    bloodsystem:setDirection(0.3)
    bloodsystem:setEmissionArea('normal', 16, 8)

    ballblood = bloodsystem:clone()

    love.graphics.setFont(font)

    time = 0
    mx, my = 0, 0
end

function spider.draw(self)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(spider.body / 40)
    love.graphics.circle('line', spider.x, spider.y, spider.body)
    love.graphics.setColor(1, 0, 0, 1)
    local angle
    if inAction == "ball" or inAction == "throw" then
        anglel = math.atan2(ball.y - (spider.y - spider.body / 5), ball.x - (spider.x - spider.body / 2))
        angler = math.atan2(ball.y - (spider.y - spider.body / 5), ball.x - (spider.x + spider.body / 2))
        love.graphics.circle('fill', (spider.x - spider.body / 2) + (math.cos(anglel) * 4),
                                     (spider.y - spider.body / 5) + (math.sin(anglel) * 4), spider.body / 10)
        love.graphics.circle('fill', (spider.x + spider.body / 2) + (math.cos(angler) * 4),
                                     (spider.y - spider.body / 5) + (math.sin(angler) * 4), spider.body / 10)
    else
        love.graphics.circle('fill', spider.x - spider.body / 2, spider.y - spider.body / 5, spider.body / 10)
        love.graphics.circle('fill', spider.x + spider.body / 2, spider.y - spider.body / 5, spider.body / 10)
    end
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

function spider.move(self, dt)
    self.x = self.x + (8 * dt) * self.mov_dist * self.mov_x
    self.mov_dist = self.mov_dist - (8 * dt)
    if self.mov_dist < 0 then
       self.mov_dist = 0 
    end
end

local function getsign(num)
    if num < 0 then
        return -1
    else
        return 1
    end
end

function spider.setmove(self, dist, dir)
    self.mov_dist = dist
    self.mov_x = dir
    playidlesound()
end

function spider.update(self, dt)
    -- if hunger is maxed, kill you (but only if you're playing on horror mode)
    if horror and self.hunger >= 1 then
        playsound(sndangry)
        dead = true
    end
    -- if the creature gets off-screen then make it come back on-screen
    if self.x < 0 then
        self:setmove(self.body / 4, 1)
    end
    if self.x > win_w then
        self:setmove(self.body / 4, -1)
    end
    self:move(dt)
    if inAction == "feed" then
        if mx > self.x - self.body and mx < self.x + self.body
        and my > self.y - self.body and my < self.y + self.body then
            self.hunger = self.hunger - 1
            self.boredom = self.boredom + 0.1
            bloodsystem:emit(80)
            if self.hunger < 0 then
                self.hunger = 0
            end
            if self.boredom > 1 then
                self.boredom = 0
            end
            inAction = "no"
            feedNum = feedNum + 1
            print("feednum "..feedNum)
            love.mouse.setVisible(true)
            --play eating sound
            playsound(sndeat)
        end
    end
    if ball.active then
        self.mov_dist = math.abs(self.x - ball.x) / 4
        self.mov_x = -getsign(self.x - ball.x)
        playidlesound()
        if ball.x > self.x - self.body and ball.x < self.x + self.body
        and ball.y > self.y - self.body and ball.y < win_h - 138 then
            bloodsystem:emit(80)
            self.boredom = self.boredom - 0.3 * self.ctime
            self.hunger = self.hunger - 0.4
            if self.boredom < 0 then
                self.boredom = 0
            end
            if self.hunger < 0 then
                self.hunger = 0
            end
            inAction = "no"
            ball.active = false
            love.mouse.setVisible(true)
            ball:reset()
            --play happy sound
            playsound(sndhappy)
            self.ctime = 0
        end
        self.ctime = self.ctime + dt
    end
    if self.htime >= self.hrate then
        self.htime = self.htime - self.hrate
        self.hunger = self.hunger + 0.02 * (self.boredom * 4 + 1)
    end
    if self.btime >= self.brate then
        self.btime = self.btime - self.brate
        self.boredom = self.boredom + 0.02
    end
    self.htime = self.htime + dt
    self.btime = self.btime + dt
end

function ball.update(self, dt)
    if self.active then
        self.x = self.x + self.xspeed * dt
        self.y = self.y + self.yspeed * dt
        self.y = self.y + ((self.gravity * dt) - (self.bouncey * dt)) * self.mov_dist
        self.mov_dist = self.mov_dist + (self.gravity / 2 * dt)
        self.bouncey = self.bouncey - self.gravity * dt

        if self.mov_dist < 0 then
            self.mov_dist = 0 
        end
        if self.y + 32 > win_h - 138 then
            self.y = win_h - 170
            if self.xspeed + self.yspeed ~= 0 then
                playsound(sndball)
            end
            if self.xspeed > 0 then
                self.xspeed = self.xspeed - 16
                if self.xspeed < 0 then
                    self.xspeed = 0
                end
            end
            if self.xspeed < 0 then
                self.xspeed = self.xspeed + 16
                if self.xspeed > 0 then
                    self.xspeed = 0
                end
            end
            self.bouncey = self.bounceratey
            self.bounceratey = self.bounceratey - 0.96
        end
        if self.x + 32 > win_w then
            if self.xspeed + self.yspeed ~= 0 then
                playsound(sndball)
            end
            self.x = win_w - 32
        end
        if self.x - 32 < 0 then
            if self.xspeed + self.yspeed ~= 0 then
                playsound(sndball)
            end
            self.x = 32
        end
    elseif not self.throw then
        self.x = mx
        self.y = my
    end
end

function ball.draw(self)
    love.graphics.draw(bloodimg, self.x, self.y, 0, 0.5, 0.5, 64, 64)
end

function ball.reset(self)
    self.x = 0
    self.y = 0
    self.xspeed = 0
    self.yspeed = 0
    self.gravity = 30
    self.mov_dist = 0
    self.bouncey = 0
    self.bounceratey = 32
    self.bouncex = 0
    self.bounceratex = 32
    self.time = 0
    self.active = false
    self.throw = false
end

local function draw_buttons()
    for _, button in pairs(buttons) do
        if not button.enabled then
            love.graphics.setColor(0.5, 0.5, 0.5, 1)
        else
            love.graphics.setColor(1, 1, 1, 1)
        end
        if mx > button[2] and mx < button[2] + button[4]
        and my > button[3] and my < button[3] + button[5]
        and button.enabled and inAction == "no" then
            love.graphics.setColor(1, 1, 0, 1)
        end
        if button.clicked then
            love.graphics.draw(button[1], button[2], button[3])
        else
            love.graphics.draw(button[1], button[2], button[3] + 8)
        end
        love.graphics.setColor(1, 1, 1, 1)
    end
end

local function update_buttons()
    for _, button in pairs(buttons) do
        local mx_c, my_c
        if #mouseclicks > 0 then
            mx_c, my_c = mouseclicks[#mouseclicks].x, mouseclicks[#mouseclicks].y
        end
        if button.clicked then
            button.clicked = false
        elseif #mouseclicks > 0 and mx_c > button[2] and mx_c < button[2] + button[4]
            and my_c > button[3] and my_c < button[3] + button[5]
            and not button.clicked and button.enabled and inAction == "no" then
                print("button")
                button.clicked = true
                button.enabled = false
                button_actions[_]()
            mouseclicks[#mouseclicks] = nil
        end
    end
end

function love.draw()
    spider:draw()
    --love.graphics.draw(bloodimg, 0, 0)

    if selectmode then
        love.graphics.print("Would you like to play in Horror Mode?", win_w / 2 - 170, win_h / 2 - 128)
        love.graphics.print("In Horror Mode, when the bar labeled \"hunger\"", win_w / 2 - 170, win_h / 2 - 112)
        love.graphics.print("is depleted, you lose", win_w / 2 - 170, win_h / 2 - 96)
        love.graphics.print("(press y or n)", win_w / 2 - 170, win_h / 2 - 80)
    else
        love.graphics.setFont(font)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.line(0, win_h - 138, win_w, win_h - 138)
        love.graphics.print("hunger", 16, win_h - 130)
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.rectangle('fill', 0, win_h - 104, 300, 32)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle('fill', 0, win_h - 104, 300 * (1 - spider.hunger), 32)
        love.graphics.print("boredom", 16, win_h - 66)
        love.graphics.setColor(0.5, 0.5, 0.5, 1)
        love.graphics.rectangle('fill', 0, win_h - 40, 300, 32)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle('fill', 0, win_h - 40, 300 * (1 - spider.boredom), 32)
        draw_buttons()
        if inAction == "feed" then
            love.graphics.draw(foodimg, mx, my, 0, 1, 1, 64, 64)
        end
        if inAction == "ball" or inAction == "throw" then
            ball:draw()
            if ball.throw then
                love.graphics.setColor(1, 1, 1, 0.8)
                love.graphics.draw(bloodimg, mx, my, 0, 0.2, 0.2, 64, 64)
                love.graphics.setColor(1, 1, 1, 1)
            end
        end
        love.graphics.draw(bloodsystem, spider.x, spider.y + spider.body / 2)
        love.graphics.draw(ballblood, ball_xold, ball_yold)

        if horror then
            love.graphics.setFont(midfont)
            love.graphics.setColor(1, 0, 0, 1)
            love.graphics.print("HORROR MODE", 8, 8)
            love.graphics.setColor(1, 1, 1, 1)
        end

        if dead then
            love.graphics.setFont(bigfont)
            love.graphics.print("GAME    OVER", win_w / 2 - 170, win_h / 2 - 128)
            love.graphics.setFont(font)
            love.graphics.print("you have been eaten", win_w / 2 - 80, win_h / 2 - 64)
            love.graphics.print("press r to restart", win_w / 2 - 80, win_h / 2 - 48)
        end
    end
end

function love.update(dt)
    if not dead then
        bloodsystem:update(dt*2)
        ballblood:update(dt*2)
        spider:update(dt)
        ball:update(dt)
        update_buttons()
        feedStatus(dt)
        ballStatus(dt)
        if time >= 0.5 then
            time = time - 0.5
            bloodsystem:setDirection(love.math.random() * 3)
            ballblood:setDirection(love.math.random() * 3)
        end
        time = time + dt
    end
end

function love.mousemoved(x, y, dx, dy)
    mx = x
    my = y
    print(mx.." "..my)
end

function love.mousepressed(x, y, button)
    local click = {["x"] = x, ["y"] = y, ["button"] = button}
    table.insert(mouseclicks, click)
    if inAction == "ball" then
        ball.throw = true
        inAction = "throw"
    end
end

function love.mousereleased(x, y, button)
    local click
    local angle
    local dist
    if inAction == "throw" then
        if #mouseclicks > 0 then
            click = mouseclicks[#mouseclicks]
            angle = math.atan2(y - click.y, x - click.x)
            dist = math.sqrt((y - click.y) ^ 2 + (x - click.x) ^ 2) * 2
            ball.xspeed = math.cos(angle) * dist
            ball.yspeed = math.sin(angle) * dist
            ball.active = true
            ball.throw = false
            mouseclicks[#mouseclicks] = nil
        end
    end
end

function love.keypressed(key)
    if key == "kp6" then
        spider.mov_dist = 10
        spider.mov_x = 1
    end
    if key == "kp4" then
        spider.mov_dist = 10
        spider.mov_x = -1
    end
    if key == "kp+" then
        spider.body = spider.body + 5
    end
    if key == "kp-" then
        spider.body = spider.body - 5
    end
    if selectmode then
        if key == "y" then
            selectmode = false
            horror = true
        end
        if key == "n" then
            selectmode = false
        end
    end
    if key == "escape" then
        love.event.quit()
    end
    if key == "r" and dead then
        init()
    end
end