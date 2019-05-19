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

local code = luagen(ast)
print(code)