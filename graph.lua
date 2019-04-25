
local Graph = {}

function Graph:new(o)
    if o == nil then o = {} end
    if o.vertices == nil then o.vertices = {} end
    if o.edges == nil then o.edges = {} end
    setmetatable(o, self)
    self.__index = self
    return o
end

function Graph:clone()
    local newGraph = Graph:new()
    for k, v in pairs(self.vertices) do
        newGraph.vertices[k] = {x=v.x, y=v.y, z=v.z}
    end
    for k, v in pairs(self.edges) do
        newGraph.edges[k] = {}
        for k2, v2 in pairs(v) do
            newGraph.edges[k][k2] = v2
        end
    end
    return newGraph
end

function Graph:addVertex(p)
    if type(p) ~= 'table' then
        p = {}
    end
    if p.x == nil then p.x = lume.random(-0.1, 0.1) end
    if p.y == nil then p.y = lume.random(-0.1, 0.1) end
    if p.z == nil then p.z = lume.random(-0.1, 0.1) end
    local i = #self.vertices+1
    self.vertices[i] = p
    return i
end

function Graph:removeVertex(i)
    local e = lume.clone(self.edges[i] or {})
    for v2i, _ in pairs(e) do
        self:removeEdge(i, v2i)
    end
    self.vertices[i] = nil
end

function Graph:addEdge(a, b, v)
    if not self.vertices[a] or not self.vertices[b] or a == b then return end
    v = v or true
    if self.edges[a] == nil then self.edges[a] = {} end
    if self.edges[b] == nil then self.edges[b] = {} end
    self.edges[a][b] = v
    self.edges[b][a] = v
end

function Graph:removeEdge(a, b)
    if self.edges[a] then
        self.edges[a][b] = nil
    end
    if self.edges[b] then
        self.edges[b][a] = nil
    end
end

function Graph:draw()
    local mx, my = camera:screen2world(love.mouse.getPosition())
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.setLineWidth(2)
    for v1i, t in pairs(self.edges) do
        for v2i, _ in pairs(t) do
            local v1 = self.vertices[v1i]
            local v2 = self.vertices[v2i]
            love.graphics.line(v1.x, v1.y, v2.x, v2.y)
        end
    end
    love.graphics.setColor(0.6, 0.6, 0.8)
    if menu.editToggle.selected == 1 then -- edit
        if love.keyboard.isDown('v') then
            local v = graph.vertices[edgeVertex]
            if v then
                love.graphics.line(v.x, v.y, mx, my)
                love.graphics.circle('fill', mx, my, 5)
            end
        elseif love.keyboard.isDown('e') then
            local v1 = graph.vertices[edgeVertex]
            local v2 = graph.vertices[closestToMouse]
            if v1 and v2 then
                if graph.edges[edgeVertex] and graph.edges[edgeVertex][closestToMouse] then
                    love.graphics.setColor(0.8, 0.6, 0.6)
                end
                love.graphics.line(v1.x, v1.y, v2.x, v2.y)
            end
        end
    end
    love.graphics.setColor(0.8, 0.8, 0.8)
    for _, v in pairs(self.vertices) do
        love.graphics.circle('fill', v.x, v.y, 5)
    end
    local v = self.vertices[closestToMouse]
    if v then
        love.graphics.setColor(0.2, 0.8, 0.2)
        love.graphics.circle('fill', v.x, v.y, 5)
    end
end

return Graph
