local M = {}

---@param symbols DocumentSymbolOutput[]
function M.generate_toc_tree(symbols)
	---@type TreeItem[]
	local lines = {}

	---@param symbs DocumentSymbolOutput[]
	---@param depth integer
	local function _traverse(symbs, depth)
		for _, sym in ipairs(symbs) do
			local indent = string.rep("  ", depth)
			local line = string.format("%s- [%s] %s (L%d)", indent, sym.kind, sym.name, sym.range.start.line + 1)

			---@type TreeItem
			local item = {
				text = line,
				depth = depth,
				data = sym,
				hl = {
					{ start = #indent + 3, ["end"] = #indent + 3 + #sym.kind, group = "Type" }, -- to highlight the kind and text differently in ui
					{ start = #indent + 6 + #sym.kind, ["end"] = #line, group = "Name" },
				},
			}
			table.insert(lines, item)

			if sym.expanded and sym.children and #sym.children > 0 then
				_traverse(sym.children, depth + 1)
			end
		end
	end

	_traverse(symbols, 0)
	return lines
end

return M
