local forestBossTeleporter = {
    { 160, -148 },
    { 145, -156 },
    { 143, -141 },
}

local caveBossTeleporter = {
    { 55, 48 }, -- 進行方向の後ろ側
    { 45, 65 }, -- 進行方向右側
    { 66, 65 }, -- 進行方向左側
}

local function directionVector(px, py, qx, qy)
    local dx, dy = qx - px, qy - py
    local len = math.sqrt(dx * dx + dy * dy)
    return dx / len, dy / len, len
end

local function closestPointOnSegment(px, py, ax, ay, bx, by)
    local abx, aby = bx - ax, by - ay
    local apx, apy = px - ax, py - ay
    local ab2 = abx * abx + aby * aby
    if ab2 == 0 then return ax, ay end
    local t = (apx * abx + apy * aby) / ab2
    t = math.max(0, math.min(1, t))
    return ax + abx * t, ay + aby * t
end

local function pointInTriangle(px, py, ax, ay, bx, by, cx, cy)
    local v0x, v0y = cx - ax, cy - ay
    local v1x, v1y = bx - ax, by - ay
    local v2x, v2y = px - ax, py - ay

    local dot00 = v0x * v0x + v0y * v0y
    local dot01 = v0x * v1x + v0y * v1y
    local dot02 = v0x * v2x + v0y * v2y
    local dot11 = v1x * v1x + v1y * v1y
    local dot12 = v1x * v2x + v1y * v2y

    local denom = dot00 * dot11 - dot01 * dot01
    if denom == 0 then return false end
    local invDenom = 1 / denom
    local u = (dot11 * dot02 - dot01 * dot12) * invDenom
    local v = (dot00 * dot12 - dot01 * dot02) * invDenom
    return (u >= 0) and (v >= 0) and (u + v <= 1)
end

local function directionToTriangle(px, py, triangle)
    local ax, ay = triangle[1][1], triangle[1][2]
    local bx, by = triangle[2][1], triangle[2][2]
    local cx, cy = triangle[3][1], triangle[3][2]

    if pointInTriangle(px, py, ax, ay, bx, by, cx, cy) then
        return 0, 0
    end

    local points = {
        { closestPointOnSegment(px, py, ax, ay, bx, by) },
        { closestPointOnSegment(px, py, bx, by, cx, cy) },
        { closestPointOnSegment(px, py, cx, cy, ax, ay) },
    }

    local minDist = math.huge
    local dx, dy = 0, 0

    for _, pt in ipairs(points) do
        local qx, qy = pt[1], pt[2]
        local dirx, diry, dist = directionVector(px, py, qx, qy)
        if dist < minDist then
            minDist = dist
            dx, dy = dirx * dist, diry * dist
        end
    end

    return dx, dy
end

local function directionToTeleportZone(floor, px, py)
    if floor == 11 then
        local dx, dy = directionToTriangle(px, py, forestBossTeleporter)
        if dx == 0 and dy == 0 then return true end
        return { dx = dx, dy = dy }
    elseif floor == 12 then
        local dx, dy = directionToTriangle(px, py, caveBossTeleporter)
        if dx == 0 and dy == 0 then return true end
        return { dx = dx, dy = dy }
    else
        return nil
    end
end


return {
    directionToTeleportZone = directionToTeleportZone,
}
