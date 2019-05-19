class = require "clasp"

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
	end,
	Stack = class {
		init = function(self)
			self.data = {}
		end;
		push = function(self, value)
			table.insert(self.data, value)
		end;
		pop = function(self)
			local value = self.data[#self.data]
			table.remove(self.data, #self.data)
			return value
		end;
		top = function(self)
			return self.data[#self.data]
		end;
		empty = function(self)
			return #self.data == 0
		end;
		at = function(self, k)
			return self.data[k]
		end;
	}
}

return util