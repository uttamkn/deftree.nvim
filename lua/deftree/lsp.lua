local M = {}

---@param bufnr integer
---@return table<integer, { error: (lsp.ResponseError)?, result: any }>?
local function _get_doc_symbols(bufnr)
	local params = {
		textDocument = vim.lsp.util.make_text_document_params(bufnr),
	}

	-- TODO: handle timeout and errors
	return vim.lsp.buf_request_sync(bufnr, "textDocument/documentSymbol", params, 1000)
end

---@param result table
---@param chunk DocumentSymbolOutput
local function _recursive_doc_sym_helper(result, chunk)
	local newChunk = {
		kind = vim.lsp.protocol.SymbolKind[chunk.kind],
		name = chunk.name,
		range = chunk.range,
		showChildren = false,
		children = {},
	}
	for _, child in ipairs(chunk.children) do
		local children = _recursive_doc_sym_helper(result, child)
		table.insert(newChunk.children, children)
	end
	table.insert(result, newChunk)
	return result
end

---@param bufnr integer
---@return DocumentSymbolOutput[]
M.get_toc = function(bufnr)
	local symbols = _get_doc_symbols(bufnr)
	if not symbols or vim.tbl_isempty(symbols) then
		return {}
	end

	---@type DocumentSymbolOutput[]
	local result = {}

	for _, res in pairs(symbols) do
		for _, chunk in ipairs(res.result) do
			table.insert(result, _recursive_doc_sym_helper({}, chunk))
		end
	end
	return result
end

vim.print(M.get_toc(26))

return M
