local Point = sonnet.Point
local List = sonnet.List
local Tween = sonnet.Tween
Flower = sonnet.middleclass.class('Flower')

function Flower:initialize(game, loc, value, time, color)
    self.game = game
    self.map = game.map
    self.loc = loc
    self.value = value
    self.color = color
    self.health = 100
    self.growth = Tween(0, 100, time)
    self.growth:promise():method_add(self, 'on_mature')
    self.mature = false
end

-- Red: slowest growth, highest value
function Flower.static.red(game, loc)
    return Flower(game, loc, 20, 45, {255, 0, 0, 255})
end

-- Blue: middle of the road
function Flower.static.blue(game, loc)
    return Flower(game, loc, 10, 30, {0, 0, 255, 255})
end

-- Yellow: fastest growth, lowest value
function Flower.static.yellow(game, loc)
    return Flower(game, loc, 5, 15, {255, 255, 0, 255})
end

function Flower:is_alive() return self.health > 0 and not self.mature end

function Flower:kill()
    self.growth:stop()
end

function Flower:draw_plant(x, y)
    local g = love.graphics
    g.push()
    g.translate(x, y)

    g.setLineWidth(2)
    g.setColor(0, 180, 0, 255)
    g.line(12, 22, 12, 8)

    g.setLineWidth(3)
    g.setColor(unpack(self.color))
    local sx, sy = 12, 8
    for a = 0, 360, 60 do
        g.line(sx, sy, sx+math.cos(a*math.pi/180)*6, sy+math.sin(a*math.pi/180)*6)
    end

    g.pop()
end

function Flower:draw()
    local g = love.graphics
    g.push()
    g.translate(self.loc.x*24, self.loc.y*24)

    self:draw_plant(0, 0)

    g.setLineWidth(2)
    g.setColor(0, 0, 255, 255)
    g.line(0, 23, self.growth.value*24/100, 23)

    g.setLineWidth(2)
    g.setColor(0, 255, 0, 255)
    g.line(0, 21, self.health*24/100, 21)

    g.pop()
end

function Flower:on_mature()
    self.mature = true
    self.game.money = self.game.money + self.value
    local x, y = self.loc()
    sonnet.effects.RisingText(x*24+12, y*23, "+$" .. self.value, {255, 255, 255})
    sonnet.effects.Sparks(x*24+12, y*24+12, self.color, self.color)
end