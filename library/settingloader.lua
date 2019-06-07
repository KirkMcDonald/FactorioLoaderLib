local SettingLoader = {}

local function readAll(f, n)
    local result = ""
    while n > 0 do
        local s = f:read(n)
        n = n - #s
        result = result .. s
    end
    return result
end

function SettingLoader.readByte(f)
    return string.byte(readAll(f, 1), 1)
end

function SettingLoader.readBool(f)
    return SettingLoader.readByte(f) == 1
end

function SettingLoader.readShort(f)
    return string.unpack("<i2", readAll(f, 2))
end

function SettingLoader.readInt(f)
    return string.unpack("<i4", readAll(f, 4))
end

function SettingLoader.readFloat(f)
    return string.unpack("<d", readAll(f, 8))
end

function SettingLoader.readVersion(f)
    return 0x1000000 * SettingLoader.readShort(f) + 0x10000 * SettingLoader.readShort(f)
        + 0x100 * SettingLoader.readShort(f) + SettingLoader.readShort(f)
end

function SettingLoader.readString(f)
    if SettingLoader.readBool(f) then
        return ""
    end
    local length = SettingLoader.readByte(f)
    if length == 0xFF then
        length = SettingLoader.readInt(f)
    end
    return readAll(f, length)
end

function SettingLoader.readPropertyTree(f, depth)
    local treeType = SettingLoader.readByte(f)
    local anyType = readAll(f, 1)  -- discard
    if treeType == 0 then
        return {}
    elseif treeType == 1 then
        return SettingLoader.readBool(f)
    elseif treeType == 2 then
        return SettingLoader.readFloat(f)
    elseif treeType == 3 then
        return SettingLoader.readString(f)
    elseif treeType == 4 then
        local result = {}
        local length = SettingLoader.readInt(f)
        for x = 1, length do
            SettingLoader.readString(f)
            table.insert(result, SettingLoader.readPropertyTree(f))
        end
        return result
    elseif treeType == 5 then
        local result = {}
        local length = SettingLoader.readInt(f)
        for x = 1, length do
            local key = SettingLoader.readString(f)
            result[key] = SettingLoader.readPropertyTree(f, depth+1)
        end
        return result
    end
end

function SettingLoader.load(filename)
    local f = io.open(filename, "rb")
    if f == nil then
        return {}
    end
    local version = SettingLoader.readVersion(f)
    if version >= 0x110000 then -- factorio >= 0.17
        local unusedFalse = readAll(f, 1)
    end
    local settings = SettingLoader.readPropertyTree(f, 0)
    f:close()
    return settings
end

return SettingLoader
