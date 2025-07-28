-- made by Grahmindol on 2025 from https://github.com/wesleywerner/lua-star/blob/master/src/lua-star.lua 
astar = {}


local function getHardness(x,y,z) 
    if math.max(math.abs(x), math.abs(y), math.abs(z)) > 32 then return -1 end
    return 0 == component.geolyzer.scan(x,z,y,1,1,1)[1] and 0 or -1
end

local function distance(x1, y1, z1, x2, y2, z2)
    local dx = x1 - x2
    local dy = y1 - y2
    local dz = z1 - z2
    return dx * dx + dy * dy + dz * dz
end

local function calculateScore(previous, node, goal)
    local g = previous.g + 1 + 10*node.hardness 
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
    local goal = {x = gx, y = gy, z = gz}
    local start = {x = 0, y = 0, z = 0, g = 0}
    start.f = distance(0, 0, 0, goal.x, goal.y, goal.z)
    local open = {[key(start)] = start}
    local openList = {start}
    local closed = {}

    while #openList > 0 do
        table.sort(openList, function(a, b) return a.f < b.f end)
        local current = table.remove(openList, 1)
        open[key(current)] = nil
        closed[key(current)] = true

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
                local g, h, f = calculateScore(current, neighbor, goal)
                local existing = open[k]
                if not existing or g < existing.g then
                    neighbor.g, neighbor.h, neighbor.f = g, h, f
                    neighbor.parent = current
                    if not existing then
                        table.insert(openList, neighbor)
                        open[k] = neighbor
                    end
                end
            end
        end
    end

    return nil
end

local function pathToMoves(path)
    local moves = {}
    if #path < 2 then return moves end

    for i = 2,#path do 
        table.insert(moves,{
            dx = path[i].x - path[i-1].x,
            dy = path[i].y - path[i-1].y,
            dz = path[i].z - path[i-1].z
        })
    end

    return moves
end

function astar.go_to(gx,gy,gz)
    local path = find_path_to(gx,gy,gz)
    if not path then return false end
    local d = component.drone
    local moves = pathToMoves(path)
    for _, m in ipairs(moves) do 
        d.move(m.dx,m.dy,m.dz)
        while d.getOffset() > 0.5 do end
    end
    return true
end
