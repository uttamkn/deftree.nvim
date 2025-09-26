local M = {}

-- the tree is flattened here
---@type DocumentSymbolOutputTreeState[]
local tree_state = {}

---@param nodes DocumentSymbolOutput[]
---@param level integer
local function _recursive_tree_state_builder(nodes, level)
	for _, node in ipairs(nodes) do
		table.insert(tree_state, {
			node = node,
			showChildren = false,
			level = level,
		})
		if node.children and #node.children > 0 then
			_recursive_tree_state_builder(node.children, level + 1)
		end
	end
end

---@param symbols DocumentSymbolOutput[]
local function _refresh_tree_state(symbols)
	tree_state = {}
	_recursive_tree_state_builder(symbols, 0)
end

---@return DocumentSymbolOutputTreeState[]
function M.get_tree_state()
	return tree_state
end

---@param symbols DocumentSymbolOutputTreeState[]
function M.generate_toc_tree(symbols)
	_refresh_tree_state(symbols)
	-- TODO: flatten and return only visible nodes
	return tree_state
end

---@param node DocumentSymbolOutputTreeState
function M.toggle_node(node)
	node.showChildren = not node.showChildren
end

return M
