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
---@field children DocumentSymbolOutput[]
---@field expanded boolean

---@class hlGroup
---@field start integer
---@field ['end'] integer
---@field group string

---@class TreeItem
---@field text string
---@field data DocumentSymbolOutput -- will be changed to any or multiple types in future
---@field depth integer
---@field hl hlGroup[]
