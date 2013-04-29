local Point = sonnet.Point
local List = sonnet.List
local Tween = sonnet.Tween
local Clock = sonnet.Clock
Tower = sonnet.middleclass.class('Tower')

function Tower:initialize(game, loc)
    self.game = game
    self.map = game.map
    self.loc = loc

    self.angle = math.random(360) / 180 * math.pi
    self.shot_clock = Clock(2, self.shoot, self)
    self.target = false

    self.range = 100
    self.damage = 20
end

function Tower:update(dt)
    if self.target and not self:valid_target() then
        self.target = nil
    end

    if not self.target then
        self:choose_target()
    end

    if self.target then
        local center = self.loc * 24 + Point(12, 12)
        self.angle = math.atan2(self.target.loc.y-center.y,
                                self.target.loc.x-center.x)
    end
end

-- ## valid target
--
-- Returns true if the current target exists, is
-- alive, and is in range.

function Tower:valid_target()
    if not self.target then return false end
    if not self.target:is_alive() then return false end
    if self.target.health <= 0 then return false end
    local center = self.loc*24 + Point(12, 12)
    if not center:dist(self.target.loc, self.range) then
        return false end
    return true
end

-- ## choose target
--
-- Set target to the closest Bug in range

function Tower:choose_target()
    local closest, closest_dist = nil
    local center = self.loc * 24 + Point(12, 12)
    for _, bug in self.game.bugs:each() do
        local dist = center:dist(bug.loc)
        if (not closest and dist <= self.range or
            closest and dist < closest_dist) and bug.health > 0 then
            closest = bug
            closest_dist = dist
        end
    end

    if closest then self.target = closest end
end

function Tower:draw()
    local g = love.graphics
    g.push()
    g.translate(self.loc.x*24, self.loc.y*24)

    g.setLineWidth(2)
    g.setColor(255, 255, 255, 255)
    g.rectangle('line', 0, 0, 24, 24)

    g.line(12, 12,
           12+math.cos(self.angle)*12,
           12+math.sin(self.angle)*12)

    g.pop()
end

function Tower:shoot()
    if not self.target then return end

    local barrel = Point(math.cos(self.angle),
                         math.sin(self.angle))*10

    local x, y = (self.loc*24+Point(12, 12)+barrel)()

    local b = sonnet.effects.Bullet(Point(x,y),self.target.loc,250)
    sonnet.effects.Spray(x, y, self.angle)

    b:promise():add(function()
                        if self.target then
                            self.target.health =
                                self.target.health - self.damage
                        end
                    end)
end