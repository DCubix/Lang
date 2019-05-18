util = {
	dump = function(o, level, indentsize)
		indentsize=  indentsize ~= nil and indentsize or 3
		level = level ~= nil and level or indentsize
		local spaces = string.rep(" ", level)
		if type(o) == 'table' then
			local s = '{\n'
			local i = 0
			local count = 0
			for _ in pairs(o) do count = count + 1 end

			for k, v in pairs(o) do
				s = s .. spaces
				if type(k) ~= 'number' then
					s = s .. "\"" .. k .. "\" = "
				else
					s = s .. "[" .. k .. "] = "
				end
				s = s .. util.dump(v, level + indentsize, indentsize)
				if i < count-1 then s = s .. "," end
				s = s .. "\n"
				i = i + 1
			end
			s = s .. string.rep(" ", level - indentsize)
			return s .. '}'
		else
			if type(o) == "number" then return tostring(o)
			elseif type(o) == "string" then return "\"" .. o .. "\""
			else return tostring(o)
			end
		end
	end
}

return util