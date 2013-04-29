local Point = sonnet.Point
local List = sonnet.List

TitleScene = sonnet.middleclass.class('TitleScene', sonnet.Scene)

function TitleScene:initialize()
    sonnet.Scene.initialize(self)
    self.grass_glyph = love.graphics.newImage('grass.png')
    self.logo = love.graphics.newImage('logo.png')
    self.bugs = List()
    self.bug_clock = sonnet.Clock(1, self.spawn_bug, self)

    self.grass_points = sonnet.Math.qrandom_points(100,
                                                   love.graphics.getWidth(),
                                                   love.graphics.getHeight())
end

function TitleScene:on_install()
    love.graphics.setBackgroundColor(130, 187, 101)
end

function TitleScene:draw()
    local w, h = love.graphics.getMode()
    local mx, my = love.mouse.getPosition()

    --- Decorative grass
    love.graphics.setColor(109, 165, 88)
    for _, pt in self.grass_points:each() do
        love.graphics.draw(self.grass_glyph, pt.x-5, pt.y-5)
    end

    --- Bugs
    self.bugs:method_map('draw')

    --- Logo
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.draw(self.logo, w/2 - 270, 60)

    --- Start button
    love.graphics.setColor(89, 145, 68)
    love.graphics.rectangle('fill', w/2-100, 330, 200, 70)
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.printf("Start game",
                         w/2-100, 359, 200, 'center')

    if sonnet.Math.collision_point_rect(Point(mx, my),
                                        Point(w/2-100, 330),
                                        Point(200, 70)) then
        love.graphics.setColor(129, 185, 108)
        love.graphics.setLineWidth(2)
        love.graphics.rectangle('line', w/2-95, 335, 190, 60)
    end

    --- Author
    love.graphics.setColor(255, 255, 255, 255)
    love.graphics.printf("By Ross Andrews\nApril 2013",
                         0, h-30, w-5, 'right')
end

function TitleScene:keypressed(key, code)
    if key == 'escape' then
        love.event.quit()
    end
end

function TitleScene:mousepressed(x, y, btn)
    local w, h = love.graphics.getMode()
    if sonnet.Math.collision_point_rect(Point(x, y),
                                        Point(w/2-100, 330),
                                        Point(200, 70)) then
        sonnet.Scene.push(GameScene())
    end
end

function TitleScene:update(dt)
    self.bugs:method_map('update', dt)
    self.bugs:method_filter('is_alive')
end

function TitleScene:spawn_bug()
    local n = math.random()
    local edge = math.random(0, 3)
    local start = nil
    local w, h = love.graphics.getMode()

    if edge == 0 then --- north
        start = Point(w*n, -24)
    elseif edge == 1 then --- east
        start = Point(w+24, n*h)
    elseif edge == 2 then --- south
        start = Point(w*n, h+24)
    elseif edge == 3 then --- west
        start = Point(-24, n*h)
    end

    --- starting angle is somewhere within 22.5 deg of toward the center
    local center = Point(w/2, h/2)
    local dir = (center - start):normal()
    local angle = math.atan2(dir.y, dir.x)
    angle = angle + math.random()*math.pi/4 - math.pi/8

    local b = Bug(self, start, angle)
    b.bounds = Point(w+48, h+48) --- Set bounds to the whole screen
    self.bugs:push(b)
end