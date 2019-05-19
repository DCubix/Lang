class = require "clasp"
util = require "util"

return class {
	init = function(self, tokens)
		self.currentToken = 1
		self.tokens = tokens ~= nil and tokens or {}
	end;
	parse = function(self)
		return self:__code()
	end;

	__accept = function(self, toktype, lex)
		if self.currentToken > #self.tokens then return false end
		if type(toktype) == "string" then
			if self.tokens[self.currentToken].type == toktype then
				if lex ~= nil then
					if self.tokens[self.currentToken].value == lex then
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
		print("ERROR(@" .. self:__last().line .. "): Expected '" .. type .. "', got '" .. self:__last().type .. "'")
		return false
	end;

	__factor = function(self)
		if self:__accept({ "num", "str", "bool", "null" }) then
			return { type = "lit", value = self:__last().value, line = self:__last().line }
		elseif self:__accept("id") then
			return { type = "var", name = self:__last().value, line = self:__last().line }
		elseif self:__accept("(") then
			local ex = self:__rangeExpr()
			self:__expect(")")
			return ex
		else
			print("ERROR(@" .. self:__last().line .. "): Invalid factor syntax.")
			self.currentToken = self.currentToken + 1
			return nil
		end
	end;

	__call = function(self)
		local expr = self:__factor();
		while true do
			if self:__accept("(") then
				expr = self:__finishCall(expr)
			else
				break
			end
		end
		return expr
	end;

	__finishCall = function(self, callee)
		local args = {}
		if self:__last().type ~= ")" then
			repeat
				if #args >= 8 then
					print("ERROR(parse): Cannot have more than 8 parameters.")
					break
				end
				table.insert(args, self:__rangeExpr())
			until not self:__accept(",")
		end

		if self:__expect(")") then
			return { type = "call", callee = callee, args = args, paren = self:__last() }
		end
		return nil
	end;

	__unary = function(self)
		if self:__accept({ "+", "-", "~", "!" }) then
			local op = self:__last().type
			local right = self:__call()
			return { type = "un", val = right, op = op, line = self:__last().line }
		end
		return self:__call()
	end;

	__muldiv = function(self)
		local left = self:__unary()
		while self:__accept({ "*", "/", "%" }) do
			local op = self:__last().type
			local right = self:__unary()
			left = { type = "bin", a = left, b = right, op = op, line = self:__last().line }
		end
		return left
	end;

	__addsub = function(self)
		local left = self:__muldiv()
		while self:__accept({ "+", "-" }) do
			local op = self:__last().type
			local right = self:__muldiv()
			left = { type = "bin", a = left, b = right, op = op, line = self:__last().line }
		end
		return left
	end;

	__bitShift = function(self)
		local left = self:__addsub()
		while self:__accept({ "<<", ">>" }) do
			local op = self:__last().type
			local right = self:__addsub()
			left = { type = "bin", a = left, b = right, op = op, line = self:__last().line }
		end
		return left
	end;

	__compare = function(self)
		local left = self:__bitShift()
		while self:__accept({ "<", ">", "<=", ">=" }) do
			local op = self:__last().type
			local right = self:__bitShift()
			left = { type = "bin", a = left, b = right, op = op, line = self:__last().line }
		end
		return left
	end;

	__compareEqNeq = function(self)
		local left = self:__compare()
		while self:__accept({ "==", "!=" }) do
			local op = self:__last().type
			local right = self:__compare()
			left = { type = "bin", a = left, b = right, op = op, line = self:__last().line }
		end
		return left
	end;

	__bitAnd = function(self)
		local left = self:__compareEqNeq()
		while self:__accept("&") do
			local op = self:__last().type
			local right = self:__compareEqNeq()
			left = { type = "bin", a = left, b = right, op = op, line = self:__last().line }
		end
		return left
	end;

	__bitXor = function(self)
		local left = self:__bitAnd()
		while self:__accept("^") do
			local op = self:__last().type
			local right = self:__bitAnd()
			left = { type = "bin", a = left, b = right, op = op, line = self:__last().line }
		end
		return left
	end;

	__bitOr = function(self)
		local left = self:__bitXor()
		while self:__accept("|") do
			local op = self:__last().type
			local right = self:__bitXor()
			left = { type = "bin", a = left, b = right, op = op, line = self:__last().line }
		end
		return left
	end;

	__logicAnd = function(self)
		local left = self:__bitOr()
		while self:__accept("&&") do
			local op = self:__last().type
			local right = self:__bitOr()
			left = { type = "bin", a = left, b = right, op = op, line = self:__last().line }
		end
		return left
	end;

	__expr = function(self)
		local left = self:__logicAnd()
		while self:__accept("||") do
			local op = self:__last().type
			local right = self:__logicAnd()
			left = { type = "bin", a = left, b = right, op = op, line = self:__last().line }
		end
		return left
	end;

	__rangeExpr = function(self)
		local left = self:__expr()
		if self:__accept("..") then
			local right = self:__expr()
			return { type = "range", from = left, to = right, line = self:__last().line }
		end
		return left
	end;

	__assign = function(self)
		local left = self:__rangeExpr()
		if self:__accept({ "=", "+=", "-=", "*=", "/=", "%=", "^=", "|=", "~=", "&=", "<<=", ">>=", "&&=", "||=" }) then
			local op = self:__last().type
			local right = self:__rangeExpr()
			return { type = "assign", a = left, b = right, op = op, line = self:__last().line }
		end
		return left
	end;

	__exprStmt = function(self)
		local expr = self:__assign()
		if self:__expect(";") then return expr end
		return nil
	end;

	__printStmt = function(self)
		local expr = self:__rangeExpr()
		if self:__expect(";") then return { type = "print", value = expr, line = self:__last().line } end
		return nil
	end;

	__ifStmt = function(self)
		if self:__expect("(") then
			local ln = self:__last().line
			local cond = self:__expr()
			if self:__expect(")") then
				local ifbody = self:__stmt()
				local elsebody = nil
				if self:__accept("kw", "else") then
					elsebody = self:__stmt()
				end
				return { type = "if", cond = cond, ifbody = ifbody, elsebody = elsebody, line = ln }
			end
		end
		return nil
	end;

	__forStmt = function(self)
		local ln = self:__last().line
		-- for <decl> in <range> { <stmts> } ranged
		-- for { <stmts> } inf
		local decl = self:__forVarDecl()
		if decl ~= nil then
			if self:__accept("kw", "in") then
				local range = self:__rangeExpr()
				local body = self:__stmt()
				return { type = "for", decl = decl, body = body, range = range, line = ln }
			end
		else
			local body = self:__stmt()
			return { type = "for", body = body, line = ln }
		end
		return nil
	end;

	__funcDefStmt = function(self)
		if self:__expect("id") then
			local fun = self:__last().value
			while true do
				if self:__accept("(") then
					fun = self:__finishfuncDef(fun, self:__last().line)
				else
					break
				end
			end
			return fun
		end
		return nil
	end;

	__finishfuncDef = function(self, name, ln)
		local args = {}
		if self:__last().type ~= ")" then
			repeat
				if #args >= 8 then
					print("ERROR(parse): Cannot have more than 8 parameters.")
					break
				end
				self:__accept("id")
				table.insert(args, self:__last().value)
			until not self:__accept(",")
		end

		if self:__expect(")") then
			local body = self:__stmt()
			return { type = "func_def", name = name, args = args, body = body, paren = self:__last(), line = ln }
		end
		return nil
	end;

	__stmt = function(self)
		if self:__accept("id", "print") then return self:__printStmt()
		elseif self:__accept("{") then return self:__block()
		elseif self:__accept("kw", "if") then return self:__ifStmt()
		elseif self:__accept("kw", "for") then return self:__forStmt()
		elseif self:__accept("kw", "func") then return self:__funcDefStmt()
		elseif self:__accept("kw", "return") then
			if self:__accept(";") then return { type = "return", line = self:__last().line }
			else return { type = "return", expr = self:__exprStmt(), line = self:__last().line }
			end
		elseif self:__accept("kw", "break") then
			self:__expect(";");
			return { type = "break", line = self:__last().line };
		elseif self:__accept("kw", "continue") then
			self:__expect(";");
			return { type = "continue", line = self:__last().line };
		end
		return self:__exprStmt()
	end;

	__forVarDecl = function(self)
		if self:__accept("id") then
			local varname = self:__last().value
			return { type = "for_var_decl", name = varname, line = self:__last().line }
		end
		return nil
	end;

	__varOneDecl = function(self)
		if self:__expect("id") then
			local varname = self:__last().value
			local init = { type = "null" }
			if self:__accept("=") then
				init = self:__rangeExpr()
			end
			return { name = varname, value = init, line = self:__last().line }
		end
		return nil
	end;

	__varDecl = function(self)
		local first = self:__varOneDecl()
		local decl = { type = "var_decl", vars = {} }
		table.insert(decl.vars, first)
		while self:__accept(",") do
			table.insert(decl.vars, self:__varOneDecl())
		end
		decl.line = #decl.vars > 0 and decl.vars[1].line or nil
		return decl
	end;

	__decl = function(self)
		if self:__accept("kw", "let") then
			local decl = self:__varDecl()
			if self:__expect(";") then return decl end
		end
		return self:__stmt()
	end;

	__stmtList = function(self)
		local stmts = {}
		while self.currentToken < #self.tokens do
			table.insert(stmts, self:__decl())
		end
		return { type = "stmt_list", list = stmts }
	end;

	__block = function(self)
		local stmts = {}
		while not self:__accept("}") do
			table.insert(stmts, self:__decl())
		end
		return { type = "block", content = stmts }
	end;

	__code = function(self)
		return { type = "code", code = self:__stmtList() }
	end;

}