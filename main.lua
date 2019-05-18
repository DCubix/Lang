tokenize = require "tokenizer"
Parser = require "parser"
util = require "util"

local tokens = tokenize("1 << 2")
local parser = Parser(tokens)
local ast = parser:parse();
print(util.dump(ast))

-- Evaluate expr
function visit(ast)
	if ast.type == "lit" then return ast.value
	elseif ast.type == "un" then
		if ast.op == "-" then return -visit(ast.value)
		elseif ast.op == "+" then return visit(ast.value) * -1
		elseif ast.op == "!" then return not visit(ast.value)
		elseif ast.op == "~" then return ~visit(ast.value)
		end
	elseif ast.type == "bin" then
		local a = visit(ast.a)
		local b = visit(ast.b)
		if     ast.op == "+" then return a + b
		elseif ast.op == "-" then return a - b
		elseif ast.op == "*" then return a * b
		elseif ast.op == "/" then return a / b
		elseif ast.op == "%" then return a % b
		elseif ast.op == ">>" then return a >> b
		elseif ast.op == "<<" then return a << b
		elseif ast.op == ">" then return a > b
		elseif ast.op == "<" then return a < b
		elseif ast.op == ">=" then return a >= b
		elseif ast.op == "<=" then return a <= b
		elseif ast.op == "==" then return a == b
		elseif ast.op == "!=" then return a ~= b
		elseif ast.op == "&" then return a & b
		elseif ast.op == "^" then return a ~ b
		elseif ast.op == "|" then return a | b
		elseif ast.op == "&&" then return a and b
		elseif ast.op == "||" then return a or b
		end
	end
end

print(visit(ast))