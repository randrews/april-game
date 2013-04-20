local Point = sonnet.Point
local List = sonnet.List
local Messenger = sonnet.Messenger

GameScene = sonnet.middleclass.class('GameScene', sonnet.Scene)

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

    self:filter_grass()
    self.grass_glyph = love.graphics.newImage('grass.png')
    self.pie_menu = PieMenu()

    self.bugs = List()
    self.bug_clock = sonnet.Clock(3, self.spawn_bug, self)
    self.money = 100
    self.hover_space = nil --- The square the mouse cursor is hovering over
    Messenger.method_subscribe('command', self, 'on_command')
end

function GameScene:on_install()
    love.graphics.setBackgroundColor(130, 187, 101)
end

function GameScene:draw()
    --- Draw the special squares
    for pt in self.map:each() do
        if self.map:at(pt) == 'r' then
            love.graphics.setColor(204, 170, 90)
            love.graphics.rectangle('fill', pt.x*24, pt.y*24, 24, 24)
        elseif self.map:at(pt) == 't' then
            love.graphics.setColor(102, 52, 13)
            love.graphics.rectangle('fill', pt.x*24, pt.y*24, 24, 24)
        elseif self.map:at(pt) == 'i' then
            love.graphics.setColor(180, 187, 101)
            love.graphics.rectangle('fill', pt.x*24, pt.y*24, 24, 24)
        end
    end    

    --- Decorative grass
    love.graphics.setColor(109, 165, 88)
    for _, pt in self.grass_points:each() do
        love.graphics.draw(self.grass_glyph, pt.x-5, pt.y-5)
    end

    --- Bugs
    self.bugs:method_map('draw')

    --- Sidebar
    love.graphics.setColor(166, 166, 166)
    love.graphics.rectangle('fill', 600, 0, 200, 600)

    --- Hover space
    if self.hover_space then
        love.graphics.setColor(255, 0, 0, 100)
        love.graphics.rectangle('fill', self.hover_space.x*24,
                                self.hover_space.y*24, 24, 24)
    end

    --- Sidebar
    self:draw_sidebar()

    --- FPS
    love.graphics.setColor(0, 0, 0)
    love.graphics.print(tostring(self.fps), 10, 10)

    self.pie_menu:draw()
end

function GameScene:draw_sidebar()
    local g = love.graphics

    local col, caption
    local pie_hovered = self.pie_menu:hovered_option()

    -- Figure out the color to display and the caption, based
    -- on what we're hovering over
    if self.hover_space then
        local hovered = self.map:at(self.hover_space)
        if hovered == 'r' then --- A path
            col = {204, 170, 90, 255}
            caption = "Path"
        elseif hovered == 'g' then --- Normal grass
            col = {130, 187, 101, 255}
            caption = "Grass\nClick to till or build"
        elseif hovered == 't' then --- Tilled plot
            col = {102, 52, 13, 255}
            caption = "Tilled plot\nClick to plant"
        end
    end

    -- If we're hovering over a pie menu option then we may
    -- override that caption though.
    if pie_hovered then
        if pie_hovered == "Till" then caption = "Till a plot to grow flowers ($10)"
        elseif pie_hovered == "Build" then caption = "Build a basic guard tower ($25)"
        elseif pie_hovered == "Insecticide" then caption = "Lay insecticide in this area ($5)"
        end
    end

    if col then
        g.setColor(unpack(col))
        g.rectangle('fill', 688, 10, 24, 24)
    end

    if caption then
        g.setColor(255, 255, 255, 255)
        g.printf(caption, 620, 44, 160, "center")
    end

    --- Status
    g.setColor(255, 255, 255, 255)
    g.printf( string.format("Money: %s", self.money),
              610, 84, 200, "left")
end

function GameScene:update(dt)
    self.fps = math.floor(1 / dt)

    self.bugs:method_map('update', dt)
    self.bugs:method_filter('is_alive')

    if self.pie_menu.state == 'closed' then
        self.hover_space = Point(
            math.floor(love.mouse.getX() / 24),
            math.floor(love.mouse.getY() / 24))

        if not self.map:inside(self.hover_space) then
            self.hover_space = nil
        end
    end
end

function GameScene:keypressed(key)
    if key == 'escape' then
        love.event.quit() -- TODO: toss this later
    end
end

function GameScene:mousepressed(x, y, btn)
    if not self.pie_menu:mousepressed(x, y, btn) then
        -- First, figure out what space we're over, if any
        local clicked_space = self.hover_space

        if clicked_space then
            local clicked_value = self.map:at(clicked_space)
            local pie_center = Point(x,y)

            -- Can't do anything to paths
            if clicked_value == 'p' then return end

            -- If it's grass, we can build a tower, lay poison, or till
            if clicked_value == 'g' then
                local p = self.pie_menu:open(pie_center, {"Build", "Insecticide", "Till"})
                p:add(function(cmd)
                          Messenger.send("command",
                                         {type=cmd, space=clicked_space})
                      end)
            end
        end
    end
end

function GameScene:on_command(cmd)
    if cmd.type == "Till" then
        if self.money >= 10 then
            self.money = self.money - 10
            self.map:at(cmd.space, 't')
            self:filter_grass()
            sonnet.effects.Sparks(cmd.space.x*24+12, cmd.space.y*24+12, {102, 52, 13}, {102, 52, 13})
        else
            sonnet.effects.RisingText(cmd.space.x*24+12, cmd.space.y*24-24, "Not enough money", {255, 0, 0})
        end
    elseif cmd.type == "Insecticide" then
        if self.money >= 5 then
            self.money = self.money - 5
            self.map:at(cmd.space, 'i')
        else
            sonnet.effects.RisingText(cmd.space.x*24+12, cmd.space.y*24-24, "Not enough money", {255, 0, 0})
        end        
    end
end

function GameScene:filter_grass()
    self.grass_points = self.grass_points:select(
        function(pt)
            local x = math.floor(pt.x/24)
            local y = math.floor(pt.y/24)
            local v = self.map:at(Point(x, y))
            return v == 'g' or v == 'i'
        end)
end

function GameScene:spawn_bug()
    local n = math.random(0, 24)
    local edge = math.random(0, 3)
    local start = nil

    if edge == 0 then --- north
        start = Point(n, -1)
    elseif edge == 1 then --- east
        start = Point(25, n)
    elseif edge == 2 then --- south
        start = Point(n, 25)
    elseif edge == 3 then --- west
        start = Point(-1, n)
    end

    --- starting angle is somewhere within 22.5 deg of toward the center
    local center = Point(12, 12)
    local dir = (center - start):normal()
    local angle = math.atan2(dir.y, dir.x)
    angle = angle + math.random()*math.pi/4 - math.pi/8

    self.bugs:push(Bug(start*24+Point(12, 12), angle))
end
