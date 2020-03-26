require "class"

local Casket = Class(function(self, inst)
    self.inst = inst
    self.owner = nil
    self.backpack = false
end)

function Casket:SetOwner(owner)
    self.owner = owner
end

return Casket