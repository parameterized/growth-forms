
lume = require 'lume'
Camera = require 'camera'
camera = Camera()
Graph = require 'graph'
Sim = require 'sim'

ssx, ssy = love.graphics.getDimensions()

love.filesystem.setIdentity(love.window.getTitle())
math.randomseed(love.timer.getTime())

simulate = true

function love.load()
    graph = Graph:new()
    local v1 = graph:addVertex(ssx/2, ssy/2)
    local v2 = graph:addVertex(ssx/2, ssy/2 - 100)
    local v3 = graph:addVertex(ssx/2 + 100, ssy/2 + 100)
    local v4 = graph:addVertex(ssx/2 - 100, ssy/2 + 100)
    graph:addEdge(v1, v2)
    graph:addEdge(v1, v3)
    graph:addEdge(v1, v4)
    graph:addEdge(v2, v3)
    graph:addEdge(v3, v4)
    graph:addEdge(v4, v2)
    local v5 = graph:addVertex(ssx/2, ssy/2 - 200)
    graph:addEdge(v2, v5)

    sim = Sim:new{graph=graph}

    timer = 1
    numVerts = 4
    closestToMouse = 1
    ctmDist = 0
    heldVertex = nil
    regrab = false

    camera.x = ssx/2
    camera.y = ssy/2
    camera.scale = 1

    collectgarbage()
end

function love.update(dt)
    if simulate then
        timer = timer - dt*3
        if timer < 0 then
            timer = timer + 1
            sim:graphStep()
        end
        sim:embedStep()
    end

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
    if k == 'r' then
        love.load()
    elseif k == 'space' then
        simulate = not simulate
    elseif k == 'escape' then
        love.event.quit()
    end
end

function love.mousepressed(x, y, btn, isTouch)
    if btn == 1 then
        heldVertex = closestToMouse
    end
end

function love.mousereleased(x, y, btn, isTouch)
    if btn == 1 then
        heldVertex = nil
    end
end

function love.mousemoved(x, y, dx, dy)
    if love.mouse.isDown(2) then
        camera.x = camera.x - dx/camera.scale
        camera.y = camera.y - dy/camera.scale
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
end
