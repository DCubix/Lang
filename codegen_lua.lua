util = require "util"
id = 0
usesrng = false
rngit = [[function __it(a)
	local i = 1
	return function()
		i = i + 1
		if i <= #a then return a[i - 1] end
	end
end
function __rngit(a, b)
	local lst = {}
	for i = a, b do
		table.insert(lst, i)
	end
	return __it(lst)
end
function __strit(a)
	local lst = {}
	string.gsub(a, ".", function(c) table.insert(lst, c) end)
	return __it(lst)
end
]]

function visit(ast, islocal)
	islocal = islocal ~= nil and islocal or false
	if ast == nil then
		return "nil"
	elseif ast.type == "null" then
		return "nil"
	elseif ast.type == "lit" then
		if type(ast.value) == "string" then
			return '"' .. ast.value .. '"'
		else
			return ast.value
		end
	elseif ast.type == "un" then
		if ast.op == "-" then return "-" .. visit(ast.value, islocal)
		elseif ast.op == "!" then return "not " .. visit(ast.value, islocal)
		elseif ast.op == "~" then return "~" .. visit(ast.value, islocal)
		end
	elseif ast.type == "bin" then
		local a = visit(ast.a, islocal)
		local b = visit(ast.b, islocal)
		if ast.op == "+" then return a .. " + " .. b
		elseif ast.op == "-" then return a .. " - " .. b
		elseif ast.op == "*" then return a .. " * " .. b
		elseif ast.op == "/" then return a .. " / " .. b
		elseif ast.op == "%" then return a .. " % " .. b
		elseif ast.op == ">>" then return a .. " >> " .. b
		elseif ast.op == "<<" then return a .. " << " .. b
		elseif ast.op == ">" then return a .. " > " .. b
		elseif ast.op == "<" then return a .. " < " .. b
		elseif ast.op == ">=" then return a .. " >= " .. b
		elseif ast.op == "<=" then return a .. " <= " .. b
		elseif ast.op == "==" then return a .. " == " .. b
		elseif ast.op == "!=" then return a .. " ~= " .. b
		elseif ast.op == "&" then
			if type(a) == "string" and type(b) ~= "string" then
				return a .. " .. " .. tostring(b)
			elseif type(a) ~= "string" and type(b) == "string" then
				return tostring(a) .. " .. " .. b
			elseif type(a) == "string" and type(b) == "string" then
				return a .. " .. " .. b
			else
				return a .. " & " .. b
			end
		elseif ast.op == "^" then return a .. " ~ " .. b
		elseif ast.op == "|" then return a .. " | " .. b
		elseif ast.op == "&&" then return a .. " and " .. b
		elseif ast.op == "||" then return a .. " or " .. b
		end
	elseif ast.type == "print" then
		local ln = ast.line ~= nil and " --" .. ast.line or ""
		return "print(" .. visit(ast.value, islocal) .. ") " .. ln .. "\n"
	elseif ast.type == "var_decl" then
		local vars = ""
		local loc = islocal and "local " or ""
		local ln = ast.line ~= nil and " --" .. ast.line or ""
		for i, v in ipairs(ast.vars) do
			vars = vars .. loc .. v.name .. " = " .. visit(v.value, islocal) .. ln .. "\n"
		end
		return vars
	elseif ast.type == "for_var_decl" then
		return ast.name
	elseif ast.type == "var" then
		return ast.name
	elseif ast.type == "assign" then
		local ln = ast.line ~= nil and " --" .. ast.line .. "\n" or "\n"
		local a = ast.a.type == "var" and ast.a.name or nil
		local b = visit(ast.b, islocal)
		if ast.op == "=" then return a .. " = " .. b .. ln
		elseif ast.op == "+=" then return a .. " = " .. a .. " + " .. b .. ln
		elseif ast.op == "-=" then return a .. " = " .. a .. " - " .. b .. ln
		elseif ast.op == "*=" then return a .. " = " .. a .. " * " .. b .. ln
		elseif ast.op == "/=" then return a .. " = " .. a .. " / " .. b .. ln
		elseif ast.op == "%=" then return a .. " = " .. a .. " % " .. b .. ln
		elseif ast.op == "^=" then return a .. " = " .. a .. " ~ " .. b .. ln
		elseif ast.op == "|=" then return a .. " = " .. a .. " | " .. b .. ln
		elseif ast.op == "&=" then return a .. " = " .. a .. " & " .. b .. ln
		elseif ast.op == "<<=" then return a .. " = " .. a .. " << " .. b .. ln
		elseif ast.op == ">>=" then return a .. " = " .. a .. " >> " .. b .. ln
		elseif ast.op == "&&=" then return a .. " = " .. a .. " and " .. b .. ln
		elseif ast.op == "||=" then return a .. " = " .. a .. " or " .. b .. ln
		end
	elseif ast.type == "if" then
		local ln = ast.line ~= nil and " --" .. ast.line or ""
		local ifstmt = ""
		ifstmt = "if " .. visit(ast.cond, islocal) .. " then" .. ln .. "\n"
		ifstmt = ifstmt .. visit(ast.ifbody, islocal)
		if ast.elsebody ~= nil then
			ifstmt = ifstmt .. "else\n" .. visit(ast.elsebody, islocal)
		end
		ifstmt = ifstmt .. "\nend\n"
		return ifstmt
	elseif ast.type == "for" then
		local ln = ast.line ~= nil and " --" .. ast.line or ""
		local forc = ""
		local contvar = "__cont__loop__" .. id
		id = id + 1
		if ast.decl == nil or ast.range == nil then
			forc = forc .. "while true "
		else
			forc = forc .. "for " .. visit(ast.decl) .. " in "
			if ast.range.type == "lit" then
				if type(ast.range.value) == "string" then
					usesrng = true
					forc = forc .. "__strit(" .. visit(ast.range) .. ")"
				else
					usesrng = true
					forc = forc .. "__it({" .. visit(ast.range) .. "})"
				end
			else
				forc = forc .. visit(ast.range)
			end
		end
		forc = forc .. " do" .. ln .. "\n"
		forc = forc .. visit(ast.body)
		forc = forc .. "::" .. contvar .. "::"
		forc = forc .. "\nend\n"
		return forc
	elseif ast.type == "break" then
		local ln = ast.line ~= nil and " --" .. ast.line or ""
		return "break" .. ln
	elseif ast.type == "return" then
		local ln = ast.line ~= nil and " --" .. ast.line or ""
		return ast.expr ~= nil and "return " .. visit(ast.expr, islocal) .. ln or "return" .. ln
	elseif ast.type == "continue" then
		local ln = ast.line ~= nil and " --" .. ast.line or ""
		local contvar = "__cont__loop__" .. (id-1)
		return "goto " .. contvar .. ln .. "\n"
	elseif ast.type == "range" then
		local ln = ast.line ~= nil and " --" .. ast.line or ""
		usesrng = true
		return "__rngit(" .. visit(ast.from) .. ", " .. visit(ast.to) .. ")"
	elseif ast.type == "block" then
		local blc = "do\n"
		for i, stmt in ipairs(ast.content) do
			blc = blc .. visit(stmt, true)
		end
		blc = blc .. "\nend\n"
		return blc
	elseif ast.type == "func_def" then
		local ln = ast.line ~= nil and " --" .. ast.line .. "\n" or "\n"
		local funcd = "function "
		funcd = funcd .. ast.name .. "("
		for i, arg in ipairs(ast.args) do
			funcd = funcd .. arg
			if i < #ast.args then funcd = funcd .. ", " end
		end
		funcd = funcd .. ")" .. ln
		funcd = funcd .. visit(ast.body)
		funcd = funcd .. "end\n"
		return funcd
	elseif ast.type == "call" then
		local ln = ast.line ~= nil and " --" .. ast.line .. "" or ""
		local funcc = ""
		funcc = funcc .. visit(ast.callee) .. "("
		for i, arg in ipairs(ast.args) do
			funcc = funcc .. visit(arg)
			if i < #ast.args then funcc = funcc .. ", " end
		end
		funcc = funcc .. ")" .. ln
		return funcc
	elseif ast.type == "stmt_list" then
		local code = ""
		for i, stmt in ipairs(ast.list) do
			code = code .. visit(stmt)
		end
		return code
	elseif ast.type == "code" then
		local code = visit(ast.code)
		if usesrng then code = rngit .. code end
		return code
	else
		return ""
	end
end

return visit