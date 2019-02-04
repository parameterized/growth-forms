
local Sim = {}

function Sim:new(o)
    if o == nil then o = {} end
    if o.graph == nil then o.graph = Graph:new() end
    setmetatable(o, self)
    self.__index = self
    return o
end

function Sim:graphStep()
    local vlist = {}
    for i, _ in pairs(self.graph.vertices) do
        table.insert(vlist, i)
    end
    local v1i = lume.randomchoice(vlist)
    local v1 = self.graph.vertices[v1i]
    local e = lume.clone(self.graph.edges[v1i])
    -- surrounding vertices
    local sv = {}
    for v2i, _ in pairs(e) do
        table.insert(sv, v2i)
    end
    if heldVertex == v1i then
        regrab = true
    end
    self.graph:removeVertex(v1i)
    -- new vertices
    local x = lume.random(v1.x - 50, v1.x + 50)
    local y = lume.random(v1.y - 50, v1.y + 50)
    local nv1i = self.graph:addVertex(x, y)
    local nv1 = self.graph.vertices[nv1i]
    x = lume.random(v1.x - 50, v1.x + 50)
    y = lume.random(v1.y - 50, v1.y + 50)
    local nv2i = self.graph:addVertex(x, y)
    local nv2 = self.graph.vertices[nv2i]
    self.graph:addEdge(nv1i, nv2i)
    if #sv == 1 then
        local sv1i = sv[1]
        local sv1 = self.graph.vertices[sv1i]
        -- squared distance (faster)
        local nv1sv1d = lume.distance(nv1.x, nv1.y, sv1.x, sv1.y, true)
        local nv2sv1d = lume.distance(nv2.x, nv2.y, sv1.x, sv1.y, true)
        if nv1sv1d < nv2sv1d then
            self.graph:addEdge(nv1i, sv1i)
        else
            self.graph:addEdge(nv2i, sv1i)
        end
    elseif #sv == 2 then
        local sv1i = sv[1]
        local sv1 = self.graph.vertices[sv1i]
        local sv2i = sv[2]
        local sv2 = self.graph.vertices[sv2i]
        local nv1sv1d = lume.distance(nv1.x, nv1.y, sv1.x, sv1.y, true)
        local nv1sv2d = lume.distance(nv1.x, nv1.y, sv2.x, sv2.y, true)
        local nv2sv1d = lume.distance(nv2.x, nv2.y, sv1.x, sv1.y, true)
        local nv2sv2d = lume.distance(nv2.x, nv2.y, sv2.x, sv2.y, true)
        if nv1sv1d + nv2sv2d < nv1sv2d + nv2sv1d then
            self.graph:addEdge(nv1i, sv1i)
            self.graph:addEdge(nv2i, sv2i)
        else
            self.graph:addEdge(nv1i, sv2i)
            self.graph:addEdge(nv2i, sv1i)
        end
    else
        -- todo: check neighbor connection degrees, connect it and opposite to both
        sv = lume.shuffle(sv)
        self.graph:addEdge(nv1i, sv[1])
        self.graph:addEdge(nv2i, sv[1])
        self.graph:addEdge(nv1i, sv[2])
        self.graph:addEdge(nv2i, sv[2])
        for i=3, #sv do
            local sv1i = sv[i]
            local sv1 = self.graph.vertices[sv1i]
            local nv1sv1d = lume.distance(nv1.x, nv1.y, sv1.x, sv1.y, true)
            local nv2sv1d = lume.distance(nv2.x, nv2.y, sv1.x, sv1.y, true)
            if nv1sv1d < nv2sv1d then
                self.graph:addEdge(nv1i, sv1i)
            else
                self.graph:addEdge(nv2i, sv1i)
            end
        end
    end
    numVerts = numVerts + 1
end

function Sim:embedStep()
    local velocities = {}
    local pdist = 100
    for vi, v in pairs(self.graph.vertices) do
        local vxe, vye, ven = 0, 0, 0
        local vxu, vyu, vun = 0, 0, 0
        for v2i, _ in pairs(self.graph.edges[vi]) do
            -- edge length force
            local v2 = self.graph.vertices[v2i]
            local vecx = v2.x - v.x
            local vecy = v2.y - v.y
            local v12dist = lume.distance(v.x, v.y, v2.x, v2.y)
            vxe = vxe + vecx*(v12dist - pdist)
            vye = vye + vecy*(v12dist - pdist)
            ven = ven + 1

            -- unfolding force
            for v3i, _ in pairs(self.graph.edges[v2i]) do
                if v3i ~= vi then
                    local v3 = self.graph.vertices[v3i]
                    local v3vecx = v3.x - v.x
                    local v3vecy = v3.y - v.y
                    local v23dist = lume.distance(v2.x, v2.y, v3.x, v3.y)
                    local v3graphDist = v12dist + v23dist
                    local v3geoDist = lume.distance(v.x, v.y, v3.x, v3.y)
                    vxu = vxu + v3vecx*(v3geoDist - v3graphDist)
                    vyu = vyu + v3vecy*(v3geoDist - v3graphDist)
                    vun = vun + 1
                end
            end
        end
        if ven == 0 then ven = 1 end
        if vun == 0 then vun = 1 end
        velocities[vi] = {
            vx = vxe + vxu/vun*2,
            vy = vye + vyu/vun*2
        }
    end
    for vi, v in pairs(self.graph.vertices) do
        v.x = v.x + velocities[vi].vx*0.0001
        v.y = v.y + velocities[vi].vy*0.0001
    end
end

return Sim
