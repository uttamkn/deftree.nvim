---@class Location
---@field character integer
---@field line integer

---@class Range
---@field start Location
---@field end Location

---@class DocumentSymbolOutput
---@field kind string
---@field name string
---@field range Range
---@field showChildren boolean
---@field children DocumentSymbolOutput[]
