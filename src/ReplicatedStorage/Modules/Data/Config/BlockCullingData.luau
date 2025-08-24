local BlockIDData = require(script.Parent.BlockIDConverter)
local BlockNameToID = BlockIDData.BlockNameToBlockID

local CullingIgnoreList = {
     [BlockNameToID["Air"]] = ""
}

return CullingIgnoreList