Utils = {}

function Utils.FormatCoords3(coords)
    return ('vector3(%.2f, %.2f, %.2f)'):format(coords.x, coords.y, coords.z)
end

function Utils.FormatCoords4(coords, heading)
    return ('vector4(%.2f, %.2f, %.2f, %.2f)'):format(coords.x, coords.y, coords.z, heading or 0.0)
end

function Utils.FormatDuration(hours)
    if hours == -1 then return 'Permanent' end
    if hours < 24 then return hours .. 'h' end
    return math.floor(hours / 24) .. 'd'
end
