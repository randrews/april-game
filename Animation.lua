local Animation = sonnet.middleclass.class('Animation', sonnet.Clock)

function Animation:initialize(delay, quads)
    sonnet.Clock.initialize(self, delay, Animation.next_frame, self)
    self.quads = quads
    self.current_frame = 1

    if #self.quads == 1 then
        self.direction = 0
    else
        self.direction = 1
    end
end

function Animation:next_frame()
    if self.direction == -1 and self.current_frame == 1
        or self.direction == 1 and self.current_frame == #self.quads
    then
        self.direction = -self.direction
    end

    self.current_frame = self.current_frame + self.direction
end

function Animation:quad()
    return self.quads[self.current_frame]
end

return Animation