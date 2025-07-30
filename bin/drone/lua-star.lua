-- made by Grahmindol on 2025 from https://github.com/wesleywerner/lua-star/blob/master/src/lua-star.lua 
astar = {}

astar.hardness_map = {}
local function getHardness(x,y,z) 
    if math.max(math.abs(x), math.abs(y), math.abs(z)) > 32 then return -1 end
    local k = ((x + 32) << 6) | (z + 32)
    if not astar.hardness_map[k] then
        astar.hardness_map[k] = component.geolyzer.scan(x,z)
    end
    return 0 == astar.hardness_map[k][y+33] and 0 or -1
end

local heap = {}
function heap.push(h, node)
    table.insert(h, node)
    local i = #h
    while i > 1 do
        local parent = math.floor(i/2)
        if h[i].f >= h[parent].f then break end
        h[i], h[parent] = h[parent], h[i]
        i = parent
    end
end

function heap.pop(h)
    local root = h[1]
    h[1] = h[#h]
    table.remove(h)
    local i = 1
    while true do
        local left, right = i*2, i*2+1
        local smallest = i
        if left <= #h and h[left].f < h[smallest].f then smallest = left end
        if right <= #h and h[right].f < h[smallest].f then smallest = right end
        if smallest == i then break end
        h[i], h[smallest] = h[smallest], h[i]
        i = smallest
    end
    return root
end

local function distance(x1, y1, z1, x2, y2, z2)
    local dx = x1 - x2
    local dy = y1 - y2
    local dz = z1 - z2
    return dx * dx + dy * dy + dz * dz
end

local function calculateScore(previous, node, goal)
    local cost = 2
    if previous.parent then
        local dx1 = previous.parent.x - previous.x
        local dy1 = previous.parent.y - previous.y
        local dz1 = previous.parent.z - previous.z

        local dx2 = previous.x - node.x
        local dy2 = previous.y - node.y
        local dz2 = previous.z - node.z

        if dx1 == dx2 or dy1 == dy2 or dz1 == dz2 then
            cost = 0
        end
    end

    local g = previous.g + cost
    local h = distance(node.x, node.y, node.z, goal.x, goal.y, goal.z)
    return g + h, g, h
end

local function key(node)
    return ((node.x + 32) << 12) | ((node.y + 32) << 6) | (node.z + 32)
end

local function getAdjacent(node)
    local dirs = {
        {1,0,0}, {-1,0,0}, {0,1,0}, {0,-1,0},
        {0,0,1}, {0,0,-1}
    }
    local neighbors = {}
    for _, d in ipairs(dirs) do
        local x, y, z = node.x + d[1], node.y + d[2], node.z + d[3]
        local hardness = getHardness(x,y,z)
        if hardness >= 0 then
            table.insert(neighbors, {x = x, y = y, z = z, hardness = hardness})
        end
    end
    return neighbors
end

local function find_path_to(gx,gy,gz)
    astar.hardness_map = {} -- reset the map
    local goal = {x = gx, y = gy, z = gz}
    local start = {x = 0, y = 0, z = 0, g = 0}
    start.f = distance(0, 0, 0, goal.x, goal.y, goal.z)
    local open = {[key(start)] = start}
    local openList = {start}
    local closed = {}

    while #openList > 0 do
        local current = heap.pop(openList)
        local k = key(current)
        open[k] = nil
        closed[k] = true

        if current.x == goal.x and current.y == goal.y and current.z == goal.z then
            local path = {}
            while current do
                table.insert(path, 1, {x = current.x, y = current.y, z = current.z, h = current.hardness})
                current = current.parent
            end
            return path
        end

        for _, neighbor in ipairs(getAdjacent(current)) do
            local k = key(neighbor)
            if not closed[k] then
                local f,g,h= calculateScore(current, neighbor, goal)
                local existing = open[k]
                if not existing or g < existing.g then
                    neighbor.g, neighbor.h, neighbor.f = g, h, f
                    neighbor.parent = current
                    if not existing then
                        heap.push(openList, neighbor)
                        open[k] = neighbor
                    end
                end
            end
        end
    end

    return nil
end
function astar.is_straight_fly_possible(fx, fy, fz, tx, ty, tz)
    -- Centre des voxels
    fx, fy, fz = fx + 0.5, fy + 0.5, fz + 0.5
    tx, ty, tz = tx + 0.5, ty + 0.5, tz + 0.5

    local dx = tx - fx
    local dy = ty - fy
    local dz = tz - fz

    local ax, ay, az = math.abs(dx), math.abs(dy), math.abs(dz)

    local steps, xinc, yinc, zinc

    if ax >= ay and ax >= az then
        steps = ax
        xinc = dx > 0 and 1 or -1
        yinc = dy / ax
        zinc = dz / ax
    elseif ay >= ax and ay >= az then
        steps = ay
        xinc = dx / ay
        yinc = dy > 0 and 1 or -1
        zinc = dz / ay
    else
        steps = az
        xinc = dx / az
        yinc = dy / az
        zinc = dz > 0 and 1 or -1
    end

    local x, y, z = fx, fy, fz

    for i = 0, math.floor(steps) do
        local cx, cy, cz = math.floor(x), math.floor(y), math.floor(z)
        if getHardness(cx, cy, cz) < 0 then
            return false
        end
        x = x + xinc
        y = y + yinc
        z = z + zinc
    end

    return true
end


local function pathToMoves(path)
    if #path < 2 then return {} end

    local moves = {}
    local anchor = path[1]

    for i = 2, #path do
        local current = path[i]
        if not astar.is_straight_fly_possible(anchor.x, anchor.y, anchor.z, current.x, current.y, current.z) then
            local prev = path[i - 1]
            table.insert(moves, {
                dx = prev.x - anchor.x,
                dy = prev.y - anchor.y,
                dz = prev.z - anchor.z
            })
            anchor = prev
        end
    end

    -- Dernier segment
    local last = path[#path]
    table.insert(moves, {
        dx = last.x - anchor.x,
        dy = last.y - anchor.y,
        dz = last.z - anchor.z
    })

    return moves
end


function astar.go_to(gx,gy,gz)
    if gx==0 and gy==0 and gz==0 then return true end
    local path = find_path_to(math.floor(gx),math.floor(gy),math.floor(gz))
    if not path then return false end
    local d = component.drone
    local moves = pathToMoves(path)
    local _,y,_ = component.navigation.getPosition()
    d.move(0,math.floor(y-0.2) - y + 0.5,0)
    d.setAcceleration(2)
    for _, m in ipairs(moves) do 
        d.move(m.dx,m.dy,m.dz)
        while d.getOffset() > 0.2 do end
    end
    d.move(gx - math.floor(gx),gy - math.floor(gy),gz - math.floor(gz))
    while d.getOffset() > 0.1 do end
    return true
end

function astar.go_to_waypoint(label, max_sig)
    max_sig = max_sig or 15

    for _,w in ipairs(component.navigation.findWaypoints(64)) do
        if w.redstone <= max_sig and w.label == label then
            if astar.go_to(table.unpack(w.position)) then 
                return true
            end
        end
    end

    return false
end

local move_hist = {}
local std_move = component.drone.move

component.drone.move = function(x,y,z)
    local last = table.remove(move_hist)
    if last then 
        last[1] = last[1] - x 
        last[2] = last[2] - y 
        last[3] = last[3] - z 
        table.insert(move_hist,last)
    end
    std_move(x,y,z)
end

function astar.record_moves()
    table.insert(move_hist,{0,0,0})
end

function astar.rollback_moves()
    local last = table.remove(move_hist)
    component.tunnel.send(table.unpack(last))
    return last and astar.go_to(table.unpack(last))
end