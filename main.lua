
require 'loadassets'
lume = require 'lume'
Camera = require 'camera'
camera = Camera()
Graph = require 'graph'
Sim = require 'sim'
require 'menu'

doGraphStep = true

defaultGraph = Graph:new()
local v1 = defaultGraph:addVertex{x=ssx/2, y=ssy/2 - 85}
local v2 = defaultGraph:addVertex{x=ssx/2, y=ssy/2 + 85}
local v3 = defaultGraph:addVertex{x=ssx/2 - 85, y=ssy/2}
local v4 = defaultGraph:addVertex{x=ssx/2 + 85, y=ssy/2}
local v5 = defaultGraph:addVertex{x=ssx/2, y=ssy/2 - 170}
local v6 = defaultGraph:addVertex{x=ssx/2, y=ssy/2 + 170}
defaultGraph:addEdge(v1, v2)
defaultGraph:addEdge(v3, v4)
defaultGraph:addEdge(v1, v4)
defaultGraph:addEdge(v4, v2)
defaultGraph:addEdge(v2, v3)
defaultGraph:addEdge(v3, v1)
defaultGraph:addEdge(v1, v5)
defaultGraph:addEdge(v2, v6)

function love.load()
    baseGraph = defaultGraph:clone()
    loadGraph()

    timer = 1
    closestToMouse = 1
    ctmDist = 0
    heldVertex = nil
    regrab = false
    edgeVertex = 1

    camera.x = ssx/2
    camera.y = ssy/2
    camera.scale = 1

    collectgarbage()
end

function loadGraph()
    graph = baseGraph:clone()
    local dim = '2d'
    if menu.dimToggle.selected == 1 then dim = '3d' end
    if dim == '2d' then
        for _, v in pairs(graph.vertices) do
            v.z = lume.random(-0.1, 0.1)
        end
    end
    sim = Sim:new{graph=graph, dim=dim}
end

function love.update(dt)
    menu.update(dt)

    timer = timer - dt*3
    if timer < 0 then
        timer = timer + 1
        if doGraphStep and menu.editToggle.selected == 0 then -- play
            sim:graphStep()
        end
    end
    sim:embedStep()

    local mx, my = camera:screen2world(love.mouse.getPosition())
    ctmDist = nil
    for vi, v in pairs(graph.vertices) do
        local mdist = lume.distance(v.x, v.y, mx, my)
        if ctmDist == nil or mdist < ctmDist then
            ctmDist = mdist
            closestToMouse = vi
        end
    end
    if regrab then
        regrab = false
        heldVertex = closestToMouse
    end
    if heldVertex then
        local v = graph.vertices[heldVertex]
        if v then
            v.x = mx
            v.y = my
        end
    end

    love.window.setTitle(string.format('GrowthForms (%i FPS)', love.timer.getFPS()))
end

function love.keypressed(k, scancode, isrepeat)
    menu.keypressed(k, scancode, isrepeat)
    if menu.editToggle.selected == 1 then -- edit
        if k == 'x' then
            graph:removeVertex(closestToMouse)
        elseif k == 'v' then
            edgeVertex = closestToMouse
        elseif k == 'e' then
            edgeVertex = closestToMouse
        end
    end
    if k == 'f' then
        local sumx, sumy, sumn = 0, 0, 0
        for _, v in pairs(graph.vertices) do
            sumx = sumx + v.x
            sumy = sumy + v.y
            sumn = sumn + 1
        end
        if sumn == 0 then sumn = 1 end
        local meanx, meany = sumx/sumn, sumy/sumn
        local sumd, sumn = 0, 0
        for _, v in pairs(graph.vertices) do
            sumd = sumd + ((v.x - meanx)^2 + (v.y - meany)^2)
            sumn = sumn + 1
        end
        if sumn == 0 then sumn = 1 end
        local std = math.sqrt(sumd/sumn)
        if std == 0 then std = 50 end
        camera.x = meanx
        camera.y = meany
        camera.scale = 1/(std/120)
    elseif k == 'r' then
        love.load()
    elseif k == 'space' then
        doGraphStep = not doGraphStep
    elseif k == 'escape' then
        love.event.quit()
    end
end

function love.keyreleased(k, scancode)
    local mx, my = camera:screen2world(love.mouse.getPosition())
    if menu.editToggle.selected == 1 then -- edit
        if k == 'v' then
            local v1 = edgeVertex
            local v2 = graph:addVertex{x=mx, y=my}
            if graph.vertices[v1] then
                graph:addEdge(v1, v2)
            end
        elseif k == 'e' then
            local v1, v2 = edgeVertex, closestToMouse
            if v1 ~= v2 then
                if graph.edges[v1] and graph.edges[v1][v2] then
                    graph:removeEdge(v1, v2)
                elseif graph.vertices[v1] and graph.vertices[v2] then
                    graph:addEdge(v1, v2)
                end
            end
        end
    end
end

function love.mousepressed(x, y, btn, isTouch)
    if x < menu.x then
        if btn == 1 then
            heldVertex = closestToMouse
        end
    else
        menu.mousepressed(x, y, btn, isTouch)
    end
end

function love.mousereleased(x, y, btn, isTouch)
    if btn == 1 then
        heldVertex = nil
    end
end

function rotateY3D(p, theta)
    local sin_t = math.sin(theta)
    local cos_t = math.cos(theta)
    local x, z = p.x, p.z
    p.x = x*cos_t - z*sin_t
    p.z = z*cos_t + x*sin_t
    return p
end

function rotateX3D(p, theta)
    local sin_t = math.sin(theta)
    local cos_t = math.cos(theta)
    local y, z = p.y, p.z
    p.y = y*cos_t - z*sin_t
    p.z = z*cos_t + y*sin_t
    return p
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(2) then
        camera.x = camera.x - dx/camera.scale
        camera.y = camera.y - dy/camera.scale
    elseif love.mouse.isDown(3) then
        if menu.dimToggle.selected == 1 then -- 3d
            local sumx, sumy, sumz, sumn = 0, 0, 0, 0
            for _, v in pairs(graph.vertices) do
                sumx = sumx + v.x
                sumy = sumy + v.y
                sumz = sumz + v.z
                sumn = sumn + 1
            end
            if sumn == 0 then sumn = 1 end
            local meanx, meany, meanz = sumx/sumn, sumy/sumn, sumz/sumn
            for _, v in pairs(graph.vertices) do
                local p = {x=v.x - meanx, y=v.y - meany, z=v.z - meanz}
                rotateY3D(p, dx*0.01)
                rotateX3D(p, dy*0.01)
                v.x, v.y, v.z = p.x + meanx, p.y + meany, p.z + meanz
            end
        end
    end
end

function love.wheelmoved(x, y)
    camera.scale = camera.scale*(1 + y*0.1)
end

function love.draw()
    love.graphics.clear(0.2, 0.2, 0.2)
    camera:set()
    graph:draw()
    camera:reset()
    menu.draw()
end
