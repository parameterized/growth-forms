
local Sim = {}

function Sim:new(o)
    if o == nil then o = {} end
    if o.graph == nil then o.graph = Graph:new() end
    if o.dim == nil then o.dim = '2d' end
    setmetatable(o, self)
    self.__index = self
    return o
end

function Sim:graphStep()
    local vlist = {}
    for i, _ in pairs(self.graph.vertices) do
        table.insert(vlist, i)
    end
    if #vlist == 0 then return end
    local v1i = lume.randomchoice(vlist)
    local v1 = self.graph.vertices[v1i]
    local e = lume.clone(self.graph.edges[v1i] or {})
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
    local z = self.dim == '2d' and lume.random(-0.1, 0.1) or lume.random(v1.z - 50, v1.z + 50)
    local nv1i = self.graph:addVertex{x=x, y=y, z=z}
    local nv1 = self.graph.vertices[nv1i]
    x = lume.random(v1.x - 50, v1.x + 50)
    y = lume.random(v1.y - 50, v1.y + 50)
    z = self.dim == '2d' and lume.random(-0.1, 0.1) or lume.random(v1.z - 50, v1.z + 50)
    local nv2i = self.graph:addVertex{x=x, y=y, z=z}
    local nv2 = self.graph.vertices[nv2i]
    self.graph:addEdge(nv1i, nv2i)
    if #sv == 1 then
        local sv1i = sv[1]
        local sv1 = self.graph.vertices[sv1i]
        -- squared distance (faster)
        local nv1sv1d = (nv1.x - sv1.x)^2 + (nv1.y - sv1.y)^2 + (self.dim == '2d' and 0 or (nv1.z - sv1.z)^2)
        local nv2sv1d = (nv2.x - sv1.x)^2 + (nv2.y - sv1.y)^2 + (self.dim == '2d' and 0 or (nv2.z - sv1.z)^2)
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
        local nv1sv1d = (nv1.x - sv1.x)^2 + (nv1.y - sv1.y)^2 + (self.dim == '2d' and 0 or (nv1.z - sv1.z)^2)
        local nv1sv2d = (nv1.x - sv2.x)^2 + (nv1.y - sv2.y)^2 + (self.dim == '2d' and 0 or (nv1.z - sv2.z)^2)
        local nv2sv1d = (nv2.x - sv1.x)^2 + (nv2.y - sv1.y)^2 + (self.dim == '2d' and 0 or (nv2.z - sv1.z)^2)
        local nv2sv2d = (nv2.x - sv2.x)^2 + (nv2.y - sv2.y)^2 + (self.dim == '2d' and 0 or (nv2.z - sv2.z)^2)
        if nv1sv1d + nv2sv2d < nv1sv2d + nv2sv1d then
            self.graph:addEdge(nv1i, sv1i)
            self.graph:addEdge(nv2i, sv2i)
        else
            self.graph:addEdge(nv1i, sv2i)
            self.graph:addEdge(nv2i, sv1i)
        end
    elseif #sv ~= 0 then
        -- todo: check neighbor connection degrees, connect it and opposite to both
        sv = lume.shuffle(sv)
        self.graph:addEdge(nv1i, sv[1])
        self.graph:addEdge(nv2i, sv[1])
        self.graph:addEdge(nv1i, sv[2])
        self.graph:addEdge(nv2i, sv[2])
        for i=3, #sv do
            local sv1i = sv[i]
            local sv1 = self.graph.vertices[sv1i]
            local nv1sv1d = (nv1.x - sv1.x)^2 + (nv1.y - sv1.y)^2 + (self.dim == '2d' and 0 or (nv1.z - sv1.z)^2)
            local nv2sv1d = (nv2.x - sv1.x)^2 + (nv2.y - sv1.y)^2 + (self.dim == '2d' and 0 or (nv2.z - sv1.z)^2)
            if nv1sv1d < nv2sv1d then
                self.graph:addEdge(nv1i, sv1i)
            else
                self.graph:addEdge(nv2i, sv1i)
            end
        end
    end
end

function Sim:embedStep()
    local velocities = {}
    local pdist = 100
    local totalvx, totalvy, totalvz, totalvn = 0, 0, 0, 0
    for vi, v in pairs(self.graph.vertices) do
        local vxe, vye, vze, ven = 0, 0, 0, 0
        local vxu, vyu, vzu, vun = 0, 0, 0, 0
        for v2i, _ in pairs(self.graph.edges[vi] or {}) do
            -- edge length force
            local v2 = self.graph.vertices[v2i]
            local vecx = v2.x - v.x
            local vecy = v2.y - v.y
            local vecz = self.dim == '2d' and 0 or v2.z - v.z
            local v2dist = math.sqrt(vecx^2 + vecy^2 + vecz^2)
            if v2dist == 0 then v2dist = 0.1 end
            vecx = vecx/v2dist
            vecy = vecy/v2dist
            vecz = vecz/v2dist
            vxe = vxe + vecx*(v2dist - pdist)
            vye = vye + vecy*(v2dist - pdist)
            vze = vze + vecz*(v2dist - pdist)
            ven = ven + 1

            -- unfolding force
            for v3i, _ in pairs(self.graph.edges[v2i] or {}) do
                if v3i ~= vi then
                    local v3 = self.graph.vertices[v3i]
                    local v3vecx = v3.x - v.x
                    local v3vecy = v3.y - v.y
                    local v3vecz = self.dim == '2d' and 0 or v3.z - v.z
                    local v3dist = math.sqrt(v3vecx^2 + v3vecy^2 + v3vecz^2)
                    if v3dist == 0 then v3dist = 0.1 end
                    v3vecx = v3vecx/v3dist
                    v3vecy = v3vecy/v3dist
                    v3vecz = v3vecz/v3dist
                    vxu = vxu + v3vecx*(v3dist - 2*pdist)
                    vyu = vyu + v3vecy*(v3dist - 2*pdist)
                    vzu = vzu + v3vecz*(v3dist - 2*pdist)
                    vun = vun + 1
                end
            end
        end
        if ven == 0 then ven = 1 end
        if vun == 0 then vun = 1 end
        local vx = (vxe/ven + vxu/vun)/2
        local vy = (vye/ven + vyu/vun)/2
        local vz = self.dim == '2d' and 0 or (vze/ven + vzu/vun)/2
        velocities[vi] = {vx=vx, vy=vy, vz=vz}
        totalvx = totalvx + vx
        totalvy = totalvy + vy
        totalvz = totalvz + vz
        totalvn = totalvn + 1
    end
    if totalvn == 0 then totalvn = 1 end
    local meanvx = totalvx/totalvn
    local meanvy = totalvy/totalvn
    local meanvz = totalvz/totalvn
    for vi, v in pairs(self.graph.vertices) do
        v.x = v.x + (velocities[vi].vx - meanvx)*0.9
        v.y = v.y + (velocities[vi].vy - meanvy)*0.9
        v.z = v.z + (velocities[vi].vz - meanvz)*0.9
    end
end

return Sim
