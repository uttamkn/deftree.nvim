local M = {}

---@param symbols DocumentSymbolOutput[]
function M.generate_toc_tree(symbols)
	local lines = {}
	local function _traverse(symbs, depth)
		for _, sym in ipairs(symbs) do
			local indent = string.rep("  ", depth)
			local line = string.format("%s- [%s] %s (L%d)", indent, sym.kind, sym.name, sym.range.start.line + 1)
			table.insert(lines, line)
			-- TODO: This should display only if the user expands the node
			if sym.children and #sym.children > 0 then
				_traverse(sym.children, depth + 1)
			end
		end
	end
	_traverse(symbols, 0)
	return lines
end

return M
