
ssx, ssy = love.graphics.getDimensions()

love.filesystem.setIdentity(love.window.getTitle())
math.randomseed(love.timer.getTime())

ease = {
	inOutCubic = function (t) return t<0.5 and 4*t*t*t or (t-1)*(2*t-2)*(2*t-2)+1 end
}

fonts = {
    f18 = love.graphics.newFont(18),
    f24 = love.graphics.newFont(24),
    f48 = love.graphics.newFont(48)
}

gfx = {
    toggleBG = love.graphics.newImage('gfx/toggleBG.png'),
    toggleSelector = love.graphics.newImage('gfx/toggleSelector.png'),
    play = love.graphics.newImage('gfx/play.png'),
    edit = love.graphics.newImage('gfx/edit.png'),
    dim2 = love.graphics.newImage('gfx/dim2.png'),
    dim3 = love.graphics.newImage('gfx/dim3.png')
}
