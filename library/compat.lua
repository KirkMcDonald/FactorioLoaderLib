serpent = require("library/serpent")

function table_size(t)
	local count = 0
	for k, v in pairs(t) do
		count = count + 1
	end
	return count
end
