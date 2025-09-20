local M = {}

---@param bufnr integer
---@return table<integer, { error: (lsp.ResponseError)?, result: any }>?
local function _get_doc_symbols(bufnr)
	local params = {
		textDocument = vim.lsp.util.make_text_document_params(bufnr),
	}

	local result = vim.lsp.buf_request_sync(bufnr, "textDocument/documentSymbol", params, 1000)
	if not result or vim.tbl_isempty(result) then
		vim.notify("No LSP response for document symbols", vim.log.levels.WARN)
		return nil
	end

	if result[1].error then
		vim.notify("LSP Error: " .. result[1].error.message, vim.log.levels.ERROR)
		return nil
	end

	return result
end

---@param chunk DocumentSymbolOutput
local function _recursive_doc_sym_helper(chunk)
	local newChunk = {
		kind = vim.lsp.protocol.SymbolKind[chunk.kind],
		name = chunk.name,
		range = chunk.range,
		showChildren = false,
		children = {},
	}
	for _, child in ipairs(chunk.children) do
		local children = _recursive_doc_sym_helper(child)
		table.insert(newChunk.children, children)
	end
	return newChunk
end

---@param bufnr integer
---@return DocumentSymbolOutput[]
function M.get_toc(bufnr)
	local symbols = _get_doc_symbols(bufnr)
	if not symbols or vim.tbl_isempty(symbols) then
		return {}
	end

	---@type DocumentSymbolOutput[]
	local result = {}

	for _, res in pairs(symbols) do
		for _, chunk in ipairs(res.result) do
			table.insert(result, _recursive_doc_sym_helper(chunk))
		end
	end
	return result
end

return M
