local Point = sonnet.Point
local List = sonnet.List
Bug = sonnet.middleclass.class('Bug')

Bug.image = love.graphics.newImage('ladybug.png')

function Bug:initialize(game, loc, dir)
    self.game = game
    self.map = game.map
    self.loc = loc
    self.dir = dir
    self.alive = true
    self.spaces = List{}
    self.speed = 24
    self.bounds = Point(648, 648)
    self.poisoned = false
    self.target = nil
    self.eating = false
    self.health = 100

    self.fadeout = nil
end

function Bug:is_alive() return self.alive end

function Bug:update(dt)
    --- We're fading out; don't do anything
    if self.fadeout then return end

    --- We're newly-dead this tick, create a fadeout and
    --- return
    if self.health <= 0 then
        self.fadeout = sonnet.Tween(255, 0, 0.5)
        self.fadeout:promise():add(function() self.alive = false end)
        return
    end

    --- Space we were in pre-update
    --- (to check if we crossed a boundary)
    local start_space = Point(math.floor(self.loc.x/24), math.floor(self.loc.y/24))

    --- Move us along, if we aren't stopped to eat
    if not self.eating then
        local dist = self.speed * dt
        self.loc.x = self.loc.x + math.cos(self.dir) * dist
        self.loc.y = self.loc.y + math.sin(self.dir) * dist
    end

    --- If we walked off-screen, kill us
    if not sonnet.Math.collision_point_rect(self.loc,
                                            Point(-24, -24),
                                            self.bounds) then
        self.alive = false
    end

    --- We're in the title scene, we just walk and that's
    --- it.
    if self.game.class == TitleScene then return end

    --- Space we're in after update
    local space = Point(math.floor(self.loc.x/24), math.floor(self.loc.y/24))

    --- If we changed spaces, rerun AI
    if space ~= start_space then
        self:navigate()
    end

    --- Figure out which spaces it's over
    local function in_space(map, pt)
        local topleft = pt*24
        return sonnet.Math.collision_circle_rect(self.loc, 10, topleft, Point(24, 24))
    end
    self.spaces = self.map:neighbors(space, in_space, true)
    self.spaces:push(space)

    --- See if we're over any poison or flowers
    for _, sp in self.spaces:each() do
        if self.map:at(sp) == 'i' then
            self.speed = 12
            self.poisoned = true
            break
        elseif self.map:at(sp) == 'f' then
            self:set_target(sp)
            self:eat()
        elseif self.map:at(sp) == 'T' then
            --- Hit a tower; turn
            local coll, normal = sonnet.Math.collision_circle_rect(
                self.loc, 10,
                sp*24, Point(24, 24))

            if coll then self.dir = math.atan2(normal.y, normal.x) end
        end
    end

    --- Should we eat a flower? If so, do it
    if self.eating then
        self.target.health = self.target.health - 10 * dt
    end

    if self.target and not self.target:is_alive() then
        self.target = nil
        self.eating = false
        self:navigate()
    end
end

function Bug:draw()
    local g = love.graphics

    local opacity = 255
    if self.fadeout then opacity = self.fadeout.value end

    if self.poisoned then
        g.setColor(120, 120, 120, opacity)
    else
        g.setColor(220, 220, 220, opacity)
    end

    g.draw(Bug.image,
           self.loc.x, self.loc.y,
           self.dir + math.pi/2,
           1, 1,
           12, 12)

    --- We're in the title scene, no health bar
    if self.game.class == TitleScene then return end

    g.push()
    g.translate(self.loc.x-12, self.loc.y-12)
    g.setLineWidth(2)
    g.setColor(255, 0, 0, opacity)
    g.line(0, 22, self.health*24/100, 22)
    g.pop()
end

function Bug:navigate()
    --- If we are already targeting a flower then leave
    if self.target then return end

    local space = Point(math.floor(self.loc.x/24), math.floor(self.loc.y/24))

    for pt in self.game.flowers:each() do
        if pt:dist(space, 6) then
            self:set_target(pt)
            return
        end
    end
end

function Bug:set_target(pt)
    self.target = self.game.flowers:at(pt)
    assert(self.target)
    local center = pt*24+Point(12, 12)
    self.dir = math.atan2(center.y-self.loc.y,
                          center.x-self.loc.x)
end

function Bug:eat()
    assert(self.target)
    self.eating = true
end

return Bug