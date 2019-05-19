class = require "clasp"

Scanner = class {
	init = function(self, input)
		self.input = {}
		string.gsub(input, ".", function(c) table.insert(self.input, c) end)
	end;
	push = function(self, c)
		table.insert(self.input, 1, c)
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

function Set (list)
	local set = {}
	for _, l in ipairs(list) do set[l] = true end
	return set
end

return function(input)
	local keywords = Set {
		"func", "if", "else", "let", "return", "break", "continue", "for", "in", "import"
	}

	local tokens = {}
	local sc = Scanner(input)
	local line = 0
	while sc:valid() do
		if string.match(sc:peek(), "%#") then
			while not string.match(sc:peek(), "\n") and sc:valid() do
				sc:pop()
			end
		elseif string.match(sc:peek(), "[ \t]") then
			sc:pop()
		elseif string.match(sc:peek(), "\n") then
			line = line + 1
			sc:pop()
		elseif string.match(sc:peek(), "%d") then
			local rgx = "[0-9a-fA-FxX%.]"
			local num = sc:pop()
			local dots = 0
			local last = ""
			while sc:valid() and string.match(sc:peek(), rgx) ~= nil do
				if sc:peek() == "." then
					dots = dots + 1
				end
				if dots >= 2 then
					num = string.sub(num, 0, #num-1)
					sc:push(last)
					break
				end
				last = sc:pop()
				num = num .. last
			end
			table.insert(tokens, { type = "num", value = tonumber(num), line = line })
		elseif string.match(sc:peek(), "[a-zA-Z_]") then
			local id = sc:read("[a-zA-Z_0-9]", true)
			local val = nil
			if string.match(id, "true") or string.match(id, "false") then
				val = string.match(id, "true") and true or false
				table.insert(tokens, { type = "bool", id = id, value = val, line = line })
			elseif string.match(id, "null") then
				table.insert(tokens, { type = "null", value = "null", line = line })
			elseif keywords[id] ~= nil then
				table.insert(tokens, { type = "kw", value = id, line = line })
			else
				table.insert(tokens, { type = "id", value = id, line = line })
			end
		elseif string.match(sc:peek(), "[<>%+%-%*%/%!%|%&%^%%~]") then
			table.insert(tokens, { type = sc:read("[<>%+%-%*%/%!%|%&%^%%%~=]", true), kind = "op", line = line })
		elseif string.match(sc:peek(), "[%(%)%{%}]") then
			table.insert(tokens, { type = sc:pop(), line = line })
		elseif string.match(sc:peek(), "=") then
			local eq = sc:pop()
			if sc:peek() == "=" then
				eq = eq .. sc:pop()
				table.insert(tokens, { type = eq, kind = "op", line = line })
			else
				table.insert(tokens, { type = eq, line = line })
			end
		elseif string.match(sc:peek(), "%.") then
			local dot = sc:pop()
			if string.match(sc:peek(), "%.") then
				table.insert(tokens, { type = dot .. sc:pop(), line = line })
			else
				table.insert(tokens, { type = dot, line = line })
			end
		elseif string.match(sc:peek(), ";") then
			table.insert(tokens, { type = sc:pop(), line = line })
		elseif string.match(sc:peek(), ",") then
			table.insert(tokens, { type = sc:pop(), line = line })
		elseif sc:peek() == '"' then -- Strings
			sc:pop()
			local str = "";
			while sc:valid() and sc:peek() ~= '"' do
				str = str .. sc:pop()
			end
			sc:pop()
			table.insert(tokens, { type = "str", value = str, line = line })
		else
			sc:pop()
		end
	end
	return tokens
end