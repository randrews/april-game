local Point = sonnet.Point
local List = sonnet.List
local GameScene = sonnet.middleclass.class('GameScene', sonnet.Scene)

function GameScene:initialize()
    sonnet.Scene.initialize(self)

    self.grass_points = sonnet.Math.qrandom_points(100,
                                                   love.graphics.getHeight(),
                                                   love.graphics.getHeight())

    self.map = sonnet.Map(25, 25)
    self.map:clear('g')
    for n = 0, 24 do
        self.map:at(Point(n, 12), 'r')
        self.map:at(Point(12, n), 'r')
    end

    self.grass_points = self.grass_points:select(
        function(pt)
            local x = math.floor(pt.x/24)
            local y = math.floor(pt.y/24)
            return self.map:at(Point(x, y)) == 'g'
        end)

    self.grass_glyph = love.graphics.newImage('grass.png')
end

function GameScene:on_install()
    love.graphics.setBackgroundColor(130, 187, 101)
end

function GameScene:draw()
    love.graphics.setColor(204, 170, 90)

    for pt in self.map:each() do
        if self.map:at(pt) == 'r' then
            love.graphics.rectangle('fill', pt.x*24, pt.y*24, 24, 24)
        end
    end

    love.graphics.setColor(109, 165, 88)

    for _, pt in self.grass_points:each() do
        love.graphics.draw(self.grass_glyph, pt.x-5, pt.y-5)
    end

    love.graphics.setColor(166, 166, 166)
    love.graphics.rectangle('fill', 600, 0, 200, 600)
end

function GameScene:update()
end

function GameScene:keypressed(key)
    if key == 'escape' then
        love.event.quit() -- TODO: toss this later
    end
end

return GameScene