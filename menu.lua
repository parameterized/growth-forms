
menu = {}

menu.w = 300
menu.open = false
menu.openX = ssx - menu.w
menu.closedX = ssx
menu.x = menu.closedX
menu.timer = 0

menu.text = {}
menu.toggles = {}

function menu.addText(t)
    if t.text == nil then t.text = 'Text' end
    if t.x == nil then t.x = 150 end
    if t.y == nil then t.y = ssy/2 end
    if t.font == nil then t.font = fonts.f24 end
    table.insert(menu.text, t)
    return t
end

function menu.addToggle(t)
    if t.x == nil then t.x = 150 end
    if t.y == nil then t.y = ssy/2 end
    if t.imgA == nil then t.imgA = gfx.play end
    if t.imgB == nil then t.imgB = gfx.edit end
    t.selected = 0
    t.timer = 0
    table.insert(menu.toggles, t)
    return t
end

menu.addText{text='Menu', y=60, font=fonts.f48}
menu.addText{text='Modes', y=150, font=fonts.f24}

menu.dimToggle = menu.addToggle{x=150-60, y=200, imgA=gfx.dim2, imgB=gfx.dim3, action=function(v)
    local dim = '2d'
    if v == 1 then dim = '3d' end
    if dim == '2d' then
        for _, vert in pairs(graph.vertices) do
            vert.z = lume.random(-0.1, 0.1)
        end
    end
    sim = Sim:new{graph=graph, dim=dim}
end}
menu.editToggle = menu.addToggle{x=150+60, y=200, imgA=gfx.play, imgB=gfx.edit, action=function(v)
    if v == 0 then -- play
        baseGraph = graph:clone()
        doGraphStep = true
    elseif v == 1 then -- edit
        doGraphStep = false
    end
    loadGraph()
end}

function menu.update(dt)
    if menu.open then
        menu.timer = lume.clamp(menu.timer + 3*dt, 0, 1)
    else
        menu.timer = lume.clamp(menu.timer - 3*dt, 0, 1)
    end
    local t = ease.inOutCubic(menu.timer)
    menu.x = lume.lerp(menu.closedX, menu.openX, t)

    for _, v in pairs(menu.toggles) do
        if v.selected == 1 then
            v.timer = lume.clamp(v.timer + 5*dt, 0, 1)
        elseif v.selected == 0 then
            v.timer = lume.clamp(v.timer - 5*dt, 0, 1)
        end
    end
end

function menu.keypressed(k, scancode, isrepeat)
    if k == 'tab' then
        menu.open = not menu.open
    end
end

function menu.mousepressed(x, y, btn, isTouch)
    x = x - menu.x
    for _, v in pairs(menu.toggles) do
        if y > v.y - 25 and y < v.y + 25 then
            if x > v.x - 50 and x <= v.x and v.selected ~= 0 then
                v.selected = 0
                if v.action then v.action(v.selected) end
            elseif x > v.x and x < v.x + 50 and v.selected ~= 1 then
                v.selected = 1
                if v.action then v.action(v.selected) end
            end
        end
    end
end

function menu.draw()
    love.graphics.push()
    love.graphics.translate(lume.round(menu.x), 0)

    love.graphics.setColor(1, 1, 1, 0.8)
    love.graphics.rectangle('fill', 0, 0, menu.w, ssy)

    for _, v in pairs(menu.toggles) do
        love.graphics.setColor(1, 1, 1)
        love.graphics.draw(gfx.toggleBG, lume.round(v.x - 50), lume.round(v.y - 25))
        love.graphics.setColor(1, 1, 1)
        local t = ease.inOutCubic(v.timer)
        love.graphics.draw(gfx.toggleSelector, lume.round(v.x - 50 + t*50), lume.round(v.y - 25))
        love.graphics.draw(v.imgA, lume.round(v.x - 50), lume.round(v.y - 25))
        love.graphics.draw(v.imgB, lume.round(v.x), lume.round(v.y - 25))
    end

    love.graphics.setColor(0.2, 0.2, 0.2)
    for _, v in pairs(menu.text) do
        love.graphics.setFont(v.font)
        love.graphics.print(v.text, lume.round(v.x - v.font:getWidth(v.text)/2), lume.round(v.y - v.font:getHeight()/2))
    end

    love.graphics.pop()
end
