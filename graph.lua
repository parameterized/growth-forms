
local Graph = {}

function Graph:new(o)
    if o == nil then o = {} end
    if o.vertices == nil then o.vertices = {} end
    if o.edges == nil then o.edges = {} end
    setmetatable(o, self)
    self.__index = self
    return o
end

function Graph:addVertex(x, y)
    local i = #self.vertices+1
    self.vertices[i] = {x=x, y=y}
    return i
end

function Graph:removeVertex(i)
    local e = lume.clone(self.edges[i])
    for v2i, _ in pairs(e) do
        self:removeEdge(i, v2i)
    end
    self.vertices[i] = nil
end

function Graph:addEdge(a, b)
    if self.edges[a] == nil then self.edges[a] = {} end
    if self.edges[b] == nil then self.edges[b] = {} end
    self.edges[a][b] = true
    self.edges[b][a] = true
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
    love.graphics.setColor(0.8, 0.8, 0.8)
    love.graphics.setLineWidth(2)
    for v1i, t in pairs(self.edges) do
        for v2i, _ in pairs(t) do
            local v1 = self.vertices[v1i]
            local v2 = self.vertices[v2i]
            love.graphics.line(v1.x, v1.y, v2.x, v2.y)
        end
    end
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
