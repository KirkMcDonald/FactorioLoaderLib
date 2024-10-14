FileLoader = {}
FileLoader.__index = FileLoader

local directory_stack = {}
local module_root_stack = {}

function FileLoader.new(name, dirname)
	local mod = {
		name = name,
		dirname = dirname,
	}
	return setmetatable(mod, FileLoader)
end

function FileLoader.__call(self, name)
    name = string.gsub(name, "%.", "/")
    local potential_files = { self.dirname .. name .. ".lua" }
    if #directory_stack ~= 0 then
        table.insert(potential_files, directory_stack[#directory_stack] .. name .. ".lua")
		table.insert(potential_files, module_root_stack[#module_root_stack] .. name .. ".lua")
    end
	local file = nil
	local filename = nil
    for _, f in ipairs(potential_files) do
        file = io.open(f, "r")
        if file then
            filename = f
            break
        end
    end
    if not file then
        return "Not found: " .. name .. " in " .. self.dirname or "[no dirname]" .. " / " .. directory_stack[#directory_stack]
    end
	local content = file:read("a")
	file:close()
    local loaded_chunk = load(content, filename)
    return function()
        table.insert(directory_stack, filename:sub(1, filename:find("/[^/]*$")))
		table.insert(module_root_stack, self.dirname)
        local result = loaded_chunk()
        table.remove(directory_stack)
        table.remove(module_root_stack)
        return result
    end
end

return FileLoader
