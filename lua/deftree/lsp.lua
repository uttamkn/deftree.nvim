local M = {}

---@param bufnr integer
---@return table<integer, { error: (lsp.ResponseError)?, result: any }>?
local get_doc_symbols = function(bufnr)
	local params = {
		textDocument = vim.lsp.util.make_text_document_params(bufnr),
	}

	-- TODO: handle timeout and errors
	return vim.lsp.buf_request_sync(bufnr, "textDocument/documentSymbol", params, 1000)
end

---@param bufnr integer
---@return table
M.get_toc = function(bufnr)
	local symbols = get_doc_symbols(bufnr)
	if not symbols or vim.tbl_isempty(symbols) then
		return {}
	end

	local result = {}
	-- TODO: Go through the symbols and build the table of contents
	return result
end

return M
