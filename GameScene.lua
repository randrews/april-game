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

    self.big_font = love.graphics.newFont(72)
    self.grass_glyph = love.graphics.newImage('grass.png')
    self.pie_menu = PieMenu()
    self.hover_space = nil --- The square the mouse cursor is hovering over

    self.bugs = List()
    self.flowers = sonnet.SparseMap(25, 25)
    self.towers = sonnet.SparseMap(25, 25)

    self.money = 100
    self.score = 0
    self.seeds = 9 -- We'll spend 4 on the initial 4 flowers

    self:on_plant{color='yellow', space=Point(10, 10)}
    self:on_plant{color='blue', space=Point(10, 14)}
    self:on_plant{color='blue', space=Point(14, 10)}
    self:on_plant{color='yellow', space=Point(14, 14)}

    self:filter_grass()

    self.gameover = false
end

function GameScene:on_install()
    love.graphics.setBackgroundColor(130, 187, 101)
    self.bug_clock = sonnet.Clock(3, self.spawn_bug, self)
    Messenger.method_subscribe('command', self, 'on_command')
    Messenger.method_subscribe('plant_flower', self, 'on_plant')
    Messenger.method_subscribe('upgrade_tower', self, 'on_upgrade_tower')
end

function GameScene:draw()
    --- Draw the special squares
    for pt in self.map:each() do
        if self.map:at(pt) == 'r' then
            love.graphics.setColor(204, 170, 90)
            love.graphics.rectangle('fill', pt.x*24, pt.y*24, 24, 24)
        elseif self.map:at(pt) == 't' or self.map:at(pt) == 'f' then
            love.graphics.setColor(102, 52, 13)
            love.graphics.rectangle('fill', pt.x*24, pt.y*24, 24, 24)
        elseif self.map:at(pt) == 'i' then
            love.graphics.setColor(180, 187, 101)
            love.graphics.rectangle('fill', pt.x*24, pt.y*24, 24, 24)
        elseif self.map:at(pt) == 'T' then
            love.graphics.setColor(140, 140, 160)
            love.graphics.rectangle('fill', pt.x*24, pt.y*24, 24, 24)
        end
    end    

    --- Decorative grass
    love.graphics.setColor(109, 165, 88)
    for _, pt in self.grass_points:each() do
        love.graphics.draw(self.grass_glyph, pt.x-5, pt.y-5)
    end

    --- Flowers
    for pt in self.flowers:each() do
        self.flowers:at(pt):draw()
    end

    --- Bugs
    self.bugs:method_map('draw')

    --- Towers
    for pt in self.towers:each() do
        self.towers:at(pt):draw()
    end

    --- Sidebar
    love.graphics.setColor(166, 166, 166)
    love.graphics.rectangle('fill', 600, 0, 200, 600)

    --- Hover space
    if self.hover_space and not self.gameover then
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

    if self.gameover then self:draw_gameover() end
end

function GameScene:draw_sidebar()
    local g = love.graphics

    local col, caption
    local pie_hovered = self.pie_menu:hovered_option()
    local flower_hovered = nil

    -- Figure out the color to display and the caption, based
    -- on what we're hovering over
    if self.hover_space then
        flower_hovered = self.flowers:at(self.hover_space)
        tower_hovered = self.towers:at(self.hover_space)
        local hovered = self.map:at(self.hover_space)

        if hovered == 'r' then --- A path
            col = {204, 170, 90, 255}
            caption = "Path"
        elseif hovered == 'g' then --- Normal grass
            col = {130, 187, 101, 255}
            caption = "Grass\nClick to till or build"
        elseif hovered == 'i' then --- Normal grass
            col = {180, 187, 101, 255}
            caption = "Insecticide\nSlows down bugs"
        elseif hovered == 't' then --- Tilled plot
            col = {102, 52, 13, 255}
            caption = "Tilled plot\nClick to plant"
        elseif hovered == 'f' then --- Growing flower
            col = {102, 52, 13, 255}
        elseif hovered == 'T' then --- Tower
            col = {140, 140, 160, 255}
        end
    end

    if flower_hovered then
        caption = string.format("Flower: health %s%%, growth %s%%",
                                math.floor(flower_hovered.health),
                                math.floor(flower_hovered.growth.value))
    end

    if tower_hovered then
        caption = tower_hovered:caption()
    end

    -- If we're hovering over a pie menu option then we may
    -- override that caption though.
    if pie_hovered then
        if pie_hovered == "Till" then caption = "Till a plot to grow flowers ($10)"
        elseif pie_hovered == "Build" then caption = "Build a basic guard tower ($25)"
        elseif pie_hovered == "Insecticide" then caption = "Lay insecticide in this area ($5)"

        elseif pie_hovered == "Plant red" then caption = "Red flower: slowest growth, earns $20"
        elseif pie_hovered == "Plant blue" then caption = "Blue flower: medium growth, earns $10"
        elseif pie_hovered == "Plant yellow" then caption = "Yellow flower: fastest growth, earns $5"
        end
    end

    if not self.gameover then
        if col then
            g.setColor(unpack(col))
            g.rectangle('fill', 688, 10, 24, 24)
        end

        if flower_hovered then
            flower_hovered:draw_plant(688, 10)
        end

        if caption then
            g.setColor(255, 255, 255, 255)
            g.printf(caption, 620, 44, 160, "center")
        end
    end

    --- Status
    g.setColor(255, 255, 255, 255)
    g.printf( string.format("Money: %s", self.money),
              610, 84, 200, "left")

    g.printf( string.format("Score: %s", self.score),
              610, 100, 200, "left")

    g.printf( string.format("Seeds: %s", self.seeds),
              610, 116, 200, "left")
end

function GameScene:draw_gameover()
    local g = love.graphics
    local w, h = g.getMode()
    g.setColor(0, 0, 0, 180)
    g.rectangle('fill', 0, 0, w, h)

    g.setColor(100, 220, 100, 255)
    local f = g.getFont()
    g.setFont(self.big_font)
    g.printf("Game Over", 0, 60, w, 'center')
    g.setFont(f)

    g.setColor(255, 255, 255, 255)
    g.printf("Score: " .. self.score, 0, 180, w, 'center')
end

function GameScene:update(dt)
    self.fps = math.floor(1 / dt)

    self.bugs:method_map('update', dt)
    self.bugs:method_filter('is_alive')

    local any_flowers = false

    for pt in self.flowers:each() do
        any_flowers = true
        local f = self.flowers:at(pt)
        if not f:is_alive() then
            self.map:at(pt, 't')
            f:kill()
            self.flowers:delete(pt)
        end
    end

    for pt in self.towers:each() do
        local t = self.towers:at(pt)
        t:update(dt)
    end

    if self.pie_menu.state == 'closed' then
        self.hover_space = Point(
            math.floor(love.mouse.getX() / 24),
            math.floor(love.mouse.getY() / 24))

        if not self.map:inside(self.hover_space) then
            self.hover_space = nil
        end
    end

    if self.seeds == 0 and not any_flowers then
        self.gameover = true
        self.pie_menu:close()
    end
end

function GameScene:mousepressed(x, y, btn)
    if self.gameover then
        return
    elseif not self.pie_menu:mousepressed(x, y, btn) then
        -- First, figure out what space we're over, if any
        local clicked_space = self.hover_space

        if clicked_space then
            local clicked_value = self.map:at(clicked_space)
            local pie_center = Point(x,y)
            if pie_center.x < 150 then pie_center.x = 150 end
            if pie_center.y < 150 then pie_center.y = 150 end
            if pie_center.y > 450 then pie_center.y = 450 end

            if clicked_value == 'p' then return -- Can't do anything to paths

            elseif clicked_value == 'g' then -- If it's grass, we can build a tower, lay poison, or till
                local p = self.pie_menu:open(pie_center, {"Build", "Insecticide", "Till"})
                p:add(function(cmd)
                          if not cmd then return end
                          Messenger.send("command",
                                         {type=cmd, space=clicked_space})
                      end)

            elseif clicked_value == 't' then -- Can plant flowers on plots
                local p = self.pie_menu:open(pie_center, {"Plant red", "Plant blue", "Plant yellow"})
                p:add(function(cmd)
                          if not cmd then return end
                          local color = cmd:match(" (%w+)")
                          Messenger.send("plant_flower",
                                         {color=color, space=clicked_space})
                      end)

            elseif clicked_value == 'T' then -- Can upgrade towers
                local tower = self.towers:at(clicked_space)
                if tower:can_upgrade() then
                    local cost = " $" .. tower:upgrade_cost()
                    local p = self.pie_menu:open(pie_center, {"Upgrade range" .. cost,
                                                              "Upgrade damage" .. cost,
                                                              "Upgrade fire rate" .. cost})
                    p:add(function(cmd)
                              if not cmd then return end
                              local type = cmd:match(" (%w+)")
                              Messenger.send("upgrade_tower",
                                             {type=type, tower=tower})
                          end)
                end
            end

        end
    end
end

function GameScene:on_upgrade_tower(cmd)
    local t = cmd.tower
    assert(t:can_upgrade())
    local cost = t:upgrade_cost()

    if self.money >= cost then
        self.money = self.money - cost
        t:upgrade(cmd.type)
        sonnet.effects.RisingText(t.loc.x*24+12, t.loc.y*24-24, "Upgraded", {255, 255, 255})
    else
        sonnet.effects.RisingText(t.loc.x*24+12, t.loc.y*24-24, "Not enough money", {255, 0, 0})
    end
end

function GameScene:on_plant(cmd)
    if self.seeds > 0 then
        self.seeds = self.seeds - 1
        local f = Flower[cmd.color](self, cmd.space)
        self.flowers:at(cmd.space, f)
        self.map:at(cmd.space, 'f')
    else
        sonnet.effects.RisingText(cmd.space.x*24+12, cmd.space.y*24-24, "No seeds left", {255, 0, 0})
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
    elseif cmd.type == "Build" then
        if self.money >= 25 then
            self.money = self.money - 25
            local t = Tower(self, cmd.space)
            self.towers:at(cmd.space, t)
            self.map:at(cmd.space, 'T')
            self:filter_grass()
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

    self.bugs:push(Bug(self, start*24+Point(12, 12), angle))
end
