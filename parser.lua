class = require "clasp"

return class {
	init = function(self, tokens)
		self.currentToken = 1
		self.tokens = tokens ~= nil and tokens or {}
	end;
	parse = function(self)
		return self:__addsub()
	end;

	__accept = function(self, toktype, lex)
		if self.currentToken > #self.tokens then return false end
		if type(toktype) == "string" then
			if self.tokens[self.currentToken].type == toktype then
				if lex ~= nil then
					if self.tokens[self.currentToken].lexeme == lex then
						self.currentToken = self.currentToken + 1
						return true
					end
				else
					self.currentToken = self.currentToken + 1
					return true
				end
			end
		elseif type(toktype) == "table" then
			for i, tt in ipairs(toktype) do
				if self:__accept(tt, lex) then
					return true
				end
			end
		end
		return false
	end;

	__last = function(self)
		return self.tokens[self.currentToken - 1]
	end;

	__expect = function(self, type, lex)
		if self:__accept(type, lex) then return true end
		error("Expected " .. type .. ", got " .. self:__last().type)
		return false
	end;

	__factor = function(self)
		if self:__accept("num") then
			return { type = "lit", value = self:__last().value }
		elseif self:__accept("(") then
			local ex = self:__addsub()
			self:__expect(")")
			return ex
		else
			self.currentToken = self.currentToken + 1
			error("Invalid factor syntax.")
			return nil
		end
	end;

	__unary = function(self)
		if self:__accept("-") then
			local op = self:__last().type
			local right = self:__factor()
			return { type = "un", val = right, op = op }
		end
		return self:__factor()
	end;

	__muldiv = function(self)
		local left = self:__unary()
		while self:__accept({ "*", "/" }) do
			local op = self:__last().type
			local right = self:__unary()
			left = { type = "bin", a = left, b = right, op = op }
		end
		return left
	end;

	__addsub = function(self)
		local left = self:__muldiv()
		while self:__accept({ "+", "-" }) do
			local op = self:__last().type
			local right = self:__muldiv()
			left = { type = "bin", a = left, b = right, op = op }
		end
		return left
	end;

}