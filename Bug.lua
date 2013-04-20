local Point = sonnet.Point
local List = sonnet.List
Bug = sonnet.middleclass.class('Bug')

function Bug:initialize(loc, dir)
    self.loc = loc
    self.dir = dir
    self.alive = true
end

function Bug:is_alive() return self.alive end

function Bug:update(dt)
    local dist = 24 * dt
    self.loc.x = self.loc.x + math.cos(self.dir) * dist
    self.loc.y = self.loc.y + math.sin(self.dir) * dist

    if not sonnet.Math.collision_point_rect(self.loc,
                                            Point(-24, -24),
                                            Point(648, 648)) then
        self.alive = false
    end
end

function Bug:draw()
    local g = love.graphics
    g.setColor(30, 30, 30)
    g.circle('fill', self.loc.x, self.loc.y, 10)
    g.setColor(255, 0, 0)
    g.setLineWidth(1)
    g.line(self.loc.x, self.loc.y,
           self.loc.x + math.cos(self.dir) * 20,
           self.loc.y + math.sin(self.dir) * 20)
end

return Bug