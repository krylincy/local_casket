require "class"


local Casket = Class(function(self, inst)
    self.inst = inst
    self.owner = nil
    self.backpack = false
end)

function Casket:SetOwner(owner)
    self.owner = owner
end

function Casket:Add(inst)
    local casket_owner =  inst.components.inventoryitem.owner
    local player = ThePlayer

    if player == casket_owner then
         casket_owner.components.inventory:SetCasket(inst)
        inst.components.casket:SetOwner(casket_owner)
    end	
end

function Casket:Remove(inst)
    local casket_owner =  inst.components.casket.owner
	
	if casket_owner then
		casket_owner.components.inventory:SetCasket(nil)
		inst.components.casket:SetOwner(nil)
	end
end

return Casket