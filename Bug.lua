local Point = sonnet.Point
local List = sonnet.List
Bug = sonnet.middleclass.class('Bug')

function Bug:initialize(map, loc, dir)
    self.map = map
    self.loc = loc
    self.dir = dir
    self.alive = true
    self.spaces = List{}
    self.speed = 24
    self.poisoned = false
end

function Bug:is_alive() return self.alive end

function Bug:update(dt)
    local dist = self.speed * dt
    self.loc.x = self.loc.x + math.cos(self.dir) * dist
    self.loc.y = self.loc.y + math.sin(self.dir) * dist

    if not sonnet.Math.collision_point_rect(self.loc,
                                            Point(-24, -24),
                                            Point(648, 648)) then
        self.alive = false
    end

    --- Figure out which spaces it's over
    local space = Point(math.floor(self.loc.x/24), math.floor(self.loc.y/24))
    local function in_space(map, pt)
        local topleft = pt*24
        return sonnet.Math.collision_circle_rect(self.loc, 10, topleft, Point(24, 24))
    end
    self.spaces = self.map:neighbors(space, in_space, true)
    self.spaces:push(space)

    --- See if we're over any poison
    for _, sp in self.spaces:each() do
        if self.map:at(sp) == 'i' then
            self.speed = 12
            self.poisoned = true
            break
        end
    end
end

function Bug:draw()
    local g = love.graphics

    -- g.setColor(255, 255, 255, 255)
    -- if self.spaces then
    --     for _, pt in self.spaces:each() do
    --         g.rectangle('line', pt.x*24, pt.y*24, 24, 24)
    --     end
    -- end

    if self.poisoned then
        g.setColor(70, 100, 70)
    else
        g.setColor(30, 30, 30)
    end

    g.circle('fill', self.loc.x, self.loc.y, 10)
    g.setColor(255, 0, 0)
    g.setLineWidth(1)
    g.line(self.loc.x, self.loc.y,
           self.loc.x + math.cos(self.dir) * 20,
           self.loc.y + math.sin(self.dir) * 20)
end

return Bug