local M = {}

-- LSP calls
---@param bufnr integer
---@return table<integer, { error: (lsp.ResponseError)?, result: any }>?
local function _get_doc_symbols(bufnr)
	local params = {
		textDocument = vim.lsp.util.make_text_document_params(bufnr),
	}

	if vim.tbl_isempty(vim.lsp.get_clients({ bufnr = bufnr })) then
		vim.notify("No LSP attached", vim.log.levels.WARN)
		return {}
	end

	--TODO: Make this async and render loading state
	local result = vim.lsp.buf_request_sync(bufnr, "textDocument/documentSymbol", params, 1000)
	if not result or vim.tbl_isempty(result) then
		vim.notify("No LSP response for document symbols", vim.log.levels.WARN)
		return nil
	end

	return result
end

-- Helper functions
---@param chunks DocumentSymbolOutput[]
local function _recursive_doc_sym_helper(chunks)
	local newChunks = {}
	for _, chunk in ipairs(chunks or {}) do
		table.insert(newChunks, {
			kind = vim.lsp.protocol.SymbolKind[chunk.kind],
			name = chunk.name,
			range = chunk.range,
			children = _recursive_doc_sym_helper(chunk.children or {}),
			expanded = true,
		})
	end
	return newChunks
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
	for _, clientOutput in pairs(symbols) do
		if clientOutput.error then
			vim.notify("LSP Error: " .. clientOutput.error.message, vim.log.levels.WARN)
		else
			result = _recursive_doc_sym_helper(clientOutput.result)
			break
		end
	end

	return result
end

return M
