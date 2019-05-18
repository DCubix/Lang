class = require "clasp"

Scanner = class {
	init = function(self, input)
		self.input = {}
		string.gsub(input, ".", function(c) table.insert(self.input, c) end)
	end;
	pop = function(self)
		if #self.input == 0 then
			return "\0"
		end
		return table.remove(self.input, 1)
	end;
	peek = function(self)
		if #self.input == 0 then
			return "\0"
		end
		return self.input[1]
	end;
	valid = function(self)
		return #self.input > 0
	end;
	read = function(self, pattern, popfirst)
		local str = (popfirst ~= nil and popfirst) and self:pop() or ""
		while self:valid() and string.match(self:peek(), pattern) ~= nil do
			str = str .. self:pop()
		end
		return str
	end;
}

return function(input)
	local tokens = {}
	local sc = Scanner(input)
	while sc:valid() do
		if string.match(sc:peek(), "%d") then
			local num = sc:read("[0-9.]")
			table.insert(tokens, { type = "num", value = tonumber(num) })
		elseif string.match(sc:peek(), "[a-zA-Z_]") then
			local id = sc:read("[a-zA-Z_0-9]", true)
			local val = nil
			if string.match(id, "true") then val = true
			elseif string.match(id, "false") then val = false
			end
			table.insert(tokens, { type = "id", id = id, value = val })
		elseif string.match(sc:peek(), "[<>%+%-%*%/%!%|%&%^%%~]") then
			table.insert(tokens, { type = sc:read("[<>%+%-%*%/%!%|%&%^%%%~=]", true), kind = "op" })
		elseif string.match(sc:peek(), "[%(%)]") then
			table.insert(tokens, { type = sc:pop() })
		elseif string.match(sc:peek(), "=") then
			table.insert(tokens, { type = sc:pop() })
		else
			sc:pop()
		end
	end
	return tokens
end