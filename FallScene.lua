local FallScene = sonnet.middleclass.class('FallScene', sonnet.Scene)

function FallScene:initialize()
    sonnet.Scene.initialize(self)

    self.board = sonnet.Map(8, 8)
    self.angle = {value=0}

    self:init_board()
    FallScene.init_quads()
end

function FallScene:init_board()
    self.board:clear('r')
end

function FallScene.init_quads()
    if FallScene.image then return end
    local nq = love.graphics.newQuad
    FallScene.image = love.graphics.newImage('arrow_blocks.png')
    FallScene.quads = {
        r = nq(0, 0, 48, 48, 192, 96),
        g = nq(48, 0, 48, 48, 192, 96),
        y = nq(96, 0, 48, 48, 192, 96),
        b = nq(144, 0, 48, 48, 192, 96),

        r_crush = nq(0, 48, 48, 48, 192, 96),
        g_crush = nq(48, 48, 48, 48, 192, 96),
        y_crush = nq(96, 48, 48, 48, 192, 96),
        b_crush = nq(144, 48, 48, 48, 192, 96)
    }
end

function FallScene:draw()
    local g = love.graphics

    g.push()
    g.translate(g.getWidth()/2, g.getHeight()/2)
    g.rotate(self.angle.value)
    g.translate(-4*48, -4*48)

    for p, val in self.board:each() do
        if FallScene.quads[val] then
            g.drawq(FallScene.image, FallScene.quads[val], (p*48)())
        end
    end

    g.pop()
end

function FallScene:mousepressed(x, y, btn)
    if btn == 'l' then
        self.angle = sonnet.Tween(0, -math.pi/2, 0.4)
        self.angle:promise():add(function()
                                     self.angle = {value=0}
                                 end)
    elseif btn == 'r' then
        self.angle = sonnet.Tween(0, math.pi/2, 0.4)
        self.angle:promise():add(function()
                                     self.angle = {value=0}
                                 end)
    end
end

return FallScene