tokenize = require "tokenizer"
Parser = require "parser"
util = require "util"
luagen = require "codegen_lua"

local f = assert(io.open("test.lan", "r"))
local script = f:read("*all")
f:close()

local tokens = tokenize(script)
local parser = Parser(tokens)
local ast = parser:parse();
--print(util.dump(ast))

-- local loops = util.Stack()
-- local scopes = util.Stack()
-- scopes:push({}) -- GLOBAL

-- function getVar(name)
-- 	for i = #scopes.data, 1, -1 do -- Search for it on all scopes
-- 		local val = scopes.data[i][name]
-- 		if val ~= nil then return { value = val, index = i } end
-- 	end
-- 	return nil
-- end

-- -- Evaluate
-- function visit(ast)
-- 	if ast == nil then return nil
-- 	elseif ast.type == "null" then return nil
-- 	elseif ast.type == "lit" then return ast.value
-- 	elseif ast.type == "un" then
-- 		if ast.op == "-" then return -visit(ast.value)
-- 		elseif ast.op == "+" then return visit(ast.value) * -1
-- 		elseif ast.op == "!" then return not visit(ast.value)
-- 		elseif ast.op == "~" then return ~visit(ast.value)
-- 		end
-- 	elseif ast.type == "bin" then
-- 		local a = visit(ast.a)
-- 		local b = visit(ast.b)
-- 		if ast.op == "+" then
-- 			if type(a) == "string" and type(b) ~= "string" then
-- 				return a .. tostring(b)
-- 			elseif type(a) ~= "string" and type(b) == "string" then
-- 				return tostring(a) .. b
-- 			elseif type(a) == "string" and type(b) == "string" then
-- 				return a .. b
-- 			else
-- 				return a + b
-- 			end
-- 		elseif ast.op == "-" then return a - b
-- 		elseif ast.op == "*" then return a * b
-- 		elseif ast.op == "/" then return a / b
-- 		elseif ast.op == "%" then return a % b
-- 		elseif ast.op == ">>" then return a >> b
-- 		elseif ast.op == "<<" then return a << b
-- 		elseif ast.op == ">" then return a > b
-- 		elseif ast.op == "<" then return a < b
-- 		elseif ast.op == ">=" then return a >= b
-- 		elseif ast.op == "<=" then return a <= b
-- 		elseif ast.op == "==" then return a == b
-- 		elseif ast.op == "!=" then return a ~= b
-- 		elseif ast.op == "&" then return a & b
-- 		elseif ast.op == "^" then return a ~ b
-- 		elseif ast.op == "|" then return a | b
-- 		elseif ast.op == "&&" then return a and b
-- 		elseif ast.op == "||" then return a or b
-- 		end
-- 	elseif ast.type == "print" then
-- 		print(visit(ast.value))
-- 		return nil
-- 	elseif ast.type == "var_decl" then
-- 		for i, v in ipairs(ast.vars) do
-- 			local var = getVar(v.name)
-- 			if var == nil then
-- 				scopes:top()[v.name] = visit(v.value)
-- 			else
-- 				print("ERROR(run): A variable named '" .. v.name .. "' is already declared in this scope.")
-- 			end
-- 		end
-- 		return nil
-- 	elseif ast.type == "var" then
-- 		local var = getVar(ast.name)
-- 		if var ~= nil then
-- 			return var.value
-- 		else
-- 			print("ERROR(run): Variable '" .. ast.name .. "' was not declared in this scope.")
-- 		end
-- 		return nil
-- 	elseif ast.type == "assign" then
-- 		local a = ast.a.type == "var" and ast.a.name or nil
-- 		local b = visit(ast.b)
-- 		if type(a) == "string" then
-- 			local var = getVar(a)
-- 			if var == nil then
-- 				print("ERROR(run): Variable '" .. a .. "' was not declared in this scope.")
-- 				return nil
-- 			end
-- 			local sc = var.index
-- 			if ast.op == "=" then scopes:at(sc)[a] = b
-- 			elseif ast.op == "+=" then scopes:at(sc)[a] = scopes:at(sc)[a] + b
-- 			elseif ast.op == "-=" then scopes:at(sc)[a] = scopes:at(sc)[a] - b
-- 			elseif ast.op == "*=" then scopes:at(sc)[a] = scopes:at(sc)[a] * b
-- 			elseif ast.op == "/=" then scopes:at(sc)[a] = scopes:at(sc)[a] / b
-- 			elseif ast.op == "%=" then scopes:at(sc)[a] = scopes:at(sc)[a] % b
-- 			elseif ast.op == "^=" then scopes:at(sc)[a] = scopes:at(sc)[a] ~ b
-- 			elseif ast.op == "|=" then scopes:at(sc)[a] = scopes:at(sc)[a] | b
-- 			elseif ast.op == "&=" then scopes:at(sc)[a] = scopes:at(sc)[a] & b
-- 			elseif ast.op == "<<=" then scopes:at(sc)[a] = scopes:at(sc)[a] << b
-- 			elseif ast.op == ">>=" then scopes:at(sc)[a] = scopes:at(sc)[a] >> b
-- 			elseif ast.op == "&&=" then scopes:at(sc)[a] = scopes:at(sc)[a] and b
-- 			elseif ast.op == "||=" then scopes:at(sc)[a] = scopes:at(sc)[a] or b
-- 			end
-- 			return scopes:at(sc)[a]
-- 		end
-- 		return nil
-- 	elseif ast.type == "if" then
-- 		if visit(ast.cond) then
-- 			visit(ast.ifbody)
-- 		else
-- 			if ast.elsebody ~= nil then
-- 				visit(ast.elsebody)
-- 			end
-- 		end
-- 		return nil
-- 	elseif ast.type == "while" then
-- 		local continue = false
-- 		local name = "$" .. tostring(#loops.data)
-- 		loops:push(name)
-- 		while visit(ast.cond) do
-- 			if continue then
-- 				continue = false
-- 			else
-- 				local result = visit(ast.body)
-- 				if result ~= nil then
-- 					local t = result.__type
-- 					if t == "brk" then
-- 						break
-- 					elseif t == "cnt" then
-- 						continue = true
-- 					end
-- 				end
-- 			end
-- 		end
-- 		if not loops:empty() then loops:pop() end
-- 		return nil
-- 	elseif ast.type == "break" then
-- 		return nil
-- 	elseif ast.type == "return" then
-- 		return ast.expr ~= nil and visit(ast.expr) or nil
-- 	elseif ast.type == "continue" then

-- 		return nil
-- 	elseif ast.type == "block" then
-- 		scopes:push({})
-- 		for i, stmt in ipairs(ast.content) do
-- 			visit(stmt)
-- 		end
-- 		scopes:pop()
-- 		return nil
-- 	end
-- end

-- for _, stmt in ipairs(ast) do
-- 	visit(stmt)
-- end

local code = luagen(ast)
print(code)