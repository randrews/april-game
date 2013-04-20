require('sonnet')

local Point = sonnet.Point
local PieMenu = sonnet.middleclass.class('PieMenu')

-- ## Initialize
--
-- Handles a PieMenu. One instance of PieMenu
-- can draw any number of PieMenus, with any
-- different set of options, but only one menu
-- at a time. Typically this means one Scene
-- will need one instance of PieMenu.

function PieMenu:initialize()
    self.state = 'closed' -- State is "closed" or "open"
    self.center = nil -- Center is a Point for the center of the menu
    self.promise = nil -- Promise is the promise we fulfill when they select an option.
    self.options = nil -- Options is the array of 1-8 string options
end

-- ## Open
--
-- Opens a new PieMenu, closing the one in process
-- if there is one.
--
-- - `center` is the center of the new menu
-- - `options` is an array of 1 to 8 strings,
-- the options for the new menu.
--
-- Returns a Promise that is fulfilled when the menu
-- closes / finishes.

function PieMenu:open(center, options)
    if self.state == 'open' then self:close() end
    self.state = 'open'
    self.center = center
    self.options = options
    self.promise = sonnet.Promise()
    return self.promise
end

-- ## Close
--
-- If there is a menu open, close it.
--
-- This causes the promise to be fulfilled with
-- a `nil` selected, if it hasn't been finished yet

function PieMenu:close()
    if self.state == 'closed' then return end
    self.state = 'closed'
    if not self.promise.finished then
        self.promise:finish(nil)
    end
end

-- ## drawArc
--
-- Utility function to draw an arc without lines toward the center
--
-- - `cx` and `cy` are the coordinates of the center
-- - `rad` is the radius
-- - `from` and `to` are the start and end angles (radians)
-- - `segments` is how many segments to draw; default 32
local function drawArc(cx, cy, rad, from, to, segments)
    segments = segments or 32
    local g = love.graphics

    local seg_angle = (to-from) / segments

    for i = 0, segments-1 do
        local sx, sy = cx + math.cos(from+seg_angle*i) * rad, cy + math.sin(from+seg_angle*i) * rad
        local ex, ey = cx + math.cos(from+seg_angle*(i+1)) * rad, cy + math.sin(from+seg_angle*(i+1)) * rad
        g.line(sx, sy, ex, ey)
    end
end

-- ## Draw
--
-- Draws the pie menu, if it's open. It's safe to
-- call this even if the menu is closed, it just
-- won't do anything.

function PieMenu:draw()
    if self.state == 'closed' then return end

    local g = love.graphics
    local mouse = Point(love.mouse.getPosition())

    local num_options = #(self.options)
    local angle = math.pi * 2 / num_options

    for i, opt in ipairs(self.options) do
        local x = self.center.x + 100 * math.cos(angle * (i-1))
        local y = self.center.y + 100 * math.sin(angle * (i-1))
        local p = Point(x, y)

        g.setColor(180, 180, 255, 255)
        local center_ang = angle * (i-1)
        local gap = 4 * math.pi / 180

        if mouse:dist(p, 32) then
            g.setLineWidth(10)
        else
            g.setLineWidth(2)
        end

        drawArc(self.center.x, self.center.y,
                100,
                center_ang - angle/2 + gap/2,
                center_ang + angle/2 - gap/2)

        g.setColor(255, 255, 255, 255)
        g.printf(opt, x-50, y-6, 100, 'center')
    end
end

-- ## mousepressed
--
-- Call this with every mouse click. If the PieMenu
-- handles the click (that is, if it's open) then
-- it will return true; otherwise it returns false
-- and you should handle the click yourself.

function PieMenu:mousepressed(x, y, btn)
    if self.state == 'open' then
        self.promise:finish(self:hovered_option())
        self:close()
        return true
    else
        return false
    end
end

-- ## Hovered option
--
-- Returns the text of the option the mouse is
-- currently hovering over, or nil.

function PieMenu:hovered_option()
    if self.state == 'closed' then return nil end

    local mouse = Point(love.mouse.getPosition())

    local num_options = #(self.options)
    local angle = math.pi * 2 / num_options

    for i, opt in ipairs(self.options) do
        local x = self.center.x + 100 * math.cos(angle * (i-1))
        local y = self.center.y + 100 * math.sin(angle * (i-1))
        local p = Point(x, y)

        if mouse:dist(p, 32) then
            return opt
        end
    end

    return nil
end

return PieMenu