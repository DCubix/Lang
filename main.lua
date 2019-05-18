tokenize = require "tokenizer"
Parser = require "parser"
util = require "util"

local tokens = tokenize("-2 / (5 + 5) * 7")
-- print(util.dump(tokens))

local parser = Parser(tokens)
print(util.dump(parser:parse()))