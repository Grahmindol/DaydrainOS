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

local heap={}
function heap.push(a,b)table.insert(a,b)local c=#a;while c>1 do local d=math.floor(c/2)if a[c].f>=a[d].f then break end;a[c],a[d]=a[d],a[c]c=d end end
function heap.pop(a)local e=a[1]a[1]=a[#a]table.remove(a)local c=1;while true do local f,g=c*2,c*2+1;local h=c;if f<=#a and a[f].f<a[h].f then h=f end;if g<=#a and a[g].f<a[h].f then h=g end;if h==c then break end;a[c],a[h]=a[h],a[c]c=h end;return e end

local function distance(a,b,c,d,e,f)local g=a-d;local h=b-e;local i=c-f;return g*g+h*h+i*i end

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

local function key(a) return a.x+32<<12|(a.y+32<<6)|a.z+32 end

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

local function is_straight_fly_possible(a,b,c,d,e,f)if not component.drone then return false end;a,b,c=a+0.5,b+0.5,c+0.5;d,e,f=d+0.5,e+0.5,f+0.5;local g=d-a;local h=e-b;local i=f-c;local j,k,l=math.abs(g),math.abs(h),math.abs(i)local m,n,o,p;if j>=k and j>=l then m=j;n=g>0 and 1 or-1;o=h/j;p=i/j elseif k>=j and k>=l then m=k;n=g/k;o=h>0 and 1 or-1;p=i/k else m=l;n=g/l;o=h/l;p=i>0 and 1 or-1 end;local q,r,s=a,b,c;for t=0,math.floor(m)do local u,v,w=math.floor(q),math.floor(r),math.floor(s)if getHardness(u,v,w)<0 then return false end;q=q+n;r=r+o;s=s+p end;return true end
local function pathToMoves(a)if#a<2 then return{}end;local b={}local c=a[1]for d=2,#a do local e=a[d]if not is_straight_fly_possible(c.x,c.y,c.z,e.x,e.y,e.z)then local f=a[d-1]table.insert(b,{dx=f.x-c.x,dy=f.y-c.y,dz=f.z-c.z})c=f end end;local g=a[#a]table.insert(b,{dx=g.x-c.x,dy=g.y-c.y,dz=g.z-c.z})return b end

function astar.go_to(gx,gy,gz)
    if gx==0 and gy==0 and gz==0 then return true end
    local path = find_path_to(math.floor(gx),math.floor(gy),math.floor(gz))
    if not path then return false end
    local moves = pathToMoves(path)

    local d = component.drone
    if d then
        local _,y,_ = component.navigation.getPosition()
        d.move(0,math.floor(y-0.1) - y + 0.5,0)
        d.setAcceleration(2)
    end

    for _, m in ipairs(moves) do 
        (d or component.robot).move(m.dx,m.dy,m.dz)
        if d then while d.getOffset() > 0.2 do end end
    end

    if d then 
        d.move(gx - math.floor(gx),gy - math.floor(gy),gz - math.floor(gz))
        while d.getOffset() > 0.1 do end 
    end
    return true
end

function astar.go_to_waypoint(label, max_sig)
    local n = component.navigation
    if not n then return false, "navigation upgrade required" end
    
    max_sig = max_sig or 15
    
    local d = component.drone
    if d then 
        local _,y,_ = n.getPosition()
        d.move(0,math.floor(y-0.1) - y + 0.5,0)
        while d.getOffset() > 0.1 do sleep(0.05) end
    end

    for _,w in ipairs(n.findWaypoints(64)) do
        if w.redstone <= max_sig and w.label:sub(-#label) == label then
            if astar.go_to(table.unpack(w.position)) then 
                return true, w.label
            end
        end
    end

    return false
end

local move_hist = {}

if component.drone then 
    local a=component.drone.move
    component.drone.move=function(b,c,d)local e=table.remove(move_hist)if e then e[1]=e[1]-b;e[2]=e[2]-c;e[3]=e[3]-d;table.insert(move_hist,e)end;a(b,c,d)end 
elseif component.robot then 
    local a=component.robot.move
    component.robot.move=function(b,c,d)local e=table.remove(move_hist)if e then e[1]=e[1]-b;e[2]=e[2]-c;e[3]=e[3]-d;table.insert(move_hist,e)end;for f=1,b do a(5)end;for f=-1,b,-1 do a(4)end;for f=1,d do a(3)end;for f=-1,d,-1 do a(2)end;for f=1,c do a(1)end;for f=-1,c,-1 do a(0)end end 
end

function astar.record_moves()table.insert(move_hist,{0,0,0})end
function astar.rollback_moves()local a=table.remove(move_hist)return a and astar.go_to(table.unpack(a))end