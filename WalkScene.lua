local Point = sonnet.Point
local WalkScene = sonnet.middleclass.class('WalkScene', sonnet.Scene)

function WalkScene:initialize()
    sonnet.Scene.initialize(self)
    self.player_loc = Point(100, 100)
    self.walls = sonnet.List{
        Point(150, 100)
    }

    WalkScene.init_quads()
    self.zoom = 1
    self.sb = love.graphics.newSpriteBatch(WalkScene.image, 128*128)
end

function WalkScene.static.init_quads()
    if WalkScene.image then return end
    local nq = love.graphics.newQuad
    WalkScene.image = love.graphics.newImage('tiles.png')
    WalkScene.quads = {
        grass = nq(0, 0, 32, 32, 128, 128),
        ground = nq(32, 0, 32, 32, 128, 128),
        flower = nq(64, 0, 32, 32, 128, 128),
        field = nq(0, 32, 32, 32, 128, 128),
        crop = nq(32, 32, 32, 32, 128, 128),
    }
end

function WalkScene:draw()
    local g = love.graphics

    local player_tile = Point(math.floor(self.player_loc.x/32),
                              math.floor(self.player_loc.y/32))

    g.push()

    g.translate(
        math.floor(32*9.5 - self.player_loc.x*self.zoom),
        math.floor(32*8.5 - self.player_loc.y*self.zoom))

    g.setScissor(0, 0, 32*19, 32*17)
    g.scale(self.zoom)

    -- Dimensions of the map viewport in tiles
    -- (taking zoom into account)
    local th = 17 / self.zoom
    local tw = 19 / self.zoom

    for y = math.max(0, player_tile.y-math.ceil(th/2)), math.min(127, player_tile.y+math.ceil(th/2)) do
        for x = math.max(0, player_tile.x-math.ceil(tw/2)), math.min(127, player_tile.x+math.ceil(tw/2)) do
            local q = WalkScene.quads.ground
            if (x + y * 128) % 13 == 0 then q = WalkScene.quads.grass end
            if (x + y * 128) % 23 == 0 then q = WalkScene.quads.flower end

            if q then
                self.sb:addq(q, x*32, y*32)
            end
        end
    end

    g.draw(self.sb, 0, 0)
    self.sb:clear()

    g.circle('fill', self.player_loc.x, self.player_loc.y, 20)

    for _, wall in self.walls:each() do
        g.rectangle('fill', wall.x-24, wall.y-24, 48, 48)
    end

    g.setScissor()
    g.pop()
end

function WalkScene:mousepressed(x, y, btn)
    if btn == 'wu' and self.zoom < 1 then self.zoom = self.zoom * 2
    elseif btn == 'wd' and self.zoom > 0.25 then self.zoom = self.zoom / 2 end
end

function WalkScene:update(dt)
    print(math.floor(1/dt))
    local k = love.keyboard.isDown
    local p = Point(0,0)
    local spd = 200

    if k('a') or k('left') then p.x = p.x-1 end
    if k('w') or k(',') or k('up') then p.y = p.y-1 end
    if k('s') or k('o') or k('down') then p.y = p.y+1 end
    if k('d') or k('e') or k('right') then p.x = p.x+1 end
    p = p:normal()

    self.player_loc = self.player_loc + p * spd * dt

    for _, wall in self.walls:each() do
        local coll, dir = self:collision(wall, 48, 48, self.player_loc, 20)
        if coll then
            self.player_loc = self.player_loc + dir * spd * dt
        end
    end
end

-- ## Collision
--
-- Returns whether a rectangle and a circle have collided, and if so how.
--
-- - `rect` is a Point for the center of a rectangle
-- - `w` and `h` are the width and height of the rectangle
-- - `circle` is a Point for the center of the circle
-- - `radius` is the radius of the circle.
--
-- If no collision, then returns false.
--
-- If there is a collision, it returns true, and a unit-length Point representing
-- the direction the circle will have to move to move away from the collision.

function WalkScene:collision(rect, w, h, circle, radius)
    local diag = math.sqrt(w*w + h*h) -- Length of the rect diagonal
    local dist = circle:dist(rect) -- Distance the centers are apart

    -- First, check a circle circumscribing the rect.
    -- Obviously no collision, return false. This is to make the
    -- most common case (you're really far away) fast.
    if dist > diag/2 + radius then return false end

    -- Then, let's see if we hit one of the walls of the rect:

    -- We may hit a top / btm wall if we're too close:
    if circle.x >= rect.x-w/2 and circle.x <= rect.x+w/2 then
        if math.abs(circle.y-rect.y) > radius + h/2 then return false
        else -- we hit it, move either up or down to resolve
            if circle.y < rect.y then return true, Point(0, -1)
            else return true, Point(0, 1) end
        end
    end

    -- We may hit a left / rt wall if we're too close:
    if circle.y >= rect.y-h/2 and circle.y <= rect.y+h/2 then
        if math.abs(circle.x-rect.x) > radius + w/2 then return false
        else -- we hit it, move either up or down to resolve
            if circle.x < rect.x then return true, Point(-1, 0)
            else return true, Point(1, 0) end
        end
    end

    -- We're still here, so we are diagonal-wise to the rect.

    if circle.x < rect.x and circle.y < rect.y and
        circle:dist(Point(rect.x-w/2, rect.y-h/2), diag/2+radius) then
        -- We hit the top left corner
        return true, (circle-rect):normal()
    end

    if circle.x > rect.x and circle.y < rect.y and
        circle:dist(Point(rect.x+w/2, rect.y-h/2), diag/2+radius) then
        -- We hit the top right corner
        return true, (circle-rect):normal()
    end

    if circle.x > rect.x and circle.y > rect.y and
        circle:dist(Point(rect.x+w/2, rect.y+h/2), diag/2+radius) then
        -- We hit the bottom right corner
        return true, (circle-rect):normal()
    end

    if circle.x < rect.x and circle.y > rect.y and
        circle:dist(Point(rect.x-w/2, rect.y+h/2), diag/2+radius) then
        -- We hit the bottom left corner
        return true, (circle-rect):normal()
    end

    -- And we're close but not too close, so we are fine.
    return false
end

return WalkScene