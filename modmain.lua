require = GLOBAL.require
require "class"

--GLOBAL.CHEATS_ENABLED = true
--GLOBAL.require( 'debugkeys' )

PrefabFiles = {
    "casket",
}

Assets = {
		
	Asset("IMAGE", "images/casket-ui.tex"),
	Asset("ATLAS", "images/casket-ui.xml"),

	Asset("IMAGE", "images/inventoryimages/casket.tex"),
	Asset("ATLAS", "images/inventoryimages/casket.xml"),
	
	Asset("IMAGE", "images/casket.tex"),
	Asset("ATLAS", "images/casket.xml"),
}

AddMinimapAtlas("images/casket.xml")

GLOBAL.STRINGS.NAMES.CASKET = "Casket"
GLOBAL.STRINGS.CHARACTERS.GENERIC.DESCRIBE.CASKET = "With this small thing I feel so big."
GLOBAL.STRINGS.RECIPE_DESC.CASKET = "A small casket for your pocket."

RECIPETABS = GLOBAL.RECIPETABS
Recipe = GLOBAL.Recipe
Ingredient = GLOBAL.Ingredient
TECH = GLOBAL.TECH

local machine = GetModConfigData("machine")
local purplegem = GetModConfigData("purplegem")
local nightmarefuel = GetModConfigData("nightmarefuel")
local livinglog = GetModConfigData("livinglog")
local goldnugget = GetModConfigData("goldnugget")
local tier = GLOBAL.TECH.NONE

if machine == 2 then
	tier = GLOBAL.TECH.MAGIC_TWO
elseif machine == 3 then
	tier = GLOBAL.TECH.MAGIC_THREE
end

local ingredient_casket = {}


--local ingredient_casket = {Ingredient("boards", 10), Ingredient("goldnugget", 8), Ingredient("purplegem", 1)}

if purplegem > 0 then
	 table.insert(ingredient_casket, Ingredient("purplegem", purplegem))
end
if nightmarefuel > 0 then
	table.insert(ingredient_casket, Ingredient("nightmarefuel", nightmarefuel))
end
if livinglog > 0 then
	table.insert(ingredient_casket, Ingredient("livinglog", livinglog))
end
if goldnugget > 0 then
	table.insert(ingredient_casket, Ingredient("goldnugget", goldnugget))
end

casket = Recipe("casket", ingredient_casket, RECIPETABS.MAGIC, tier, nil, 1)


casket.atlas = "images/inventoryimages/casket.xml"

--TheInput:ControllerAttached()

local function Casket_inventory(inst)

	local function SetCasket(self, casket)
		self.casket = casket	
	end

	local function FindItemOverwrite(self, fn)
	    for k,v in pairs(self.itemslots) do
	        if fn(v) then
	            return v
	        end
	    end

	    local foundItem = nil 
	    
	    if self.activeitem and fn(self.activeitem) then
	        foundItem = self.activeitem
	    end
	    
	    if self.overflow then
			foundItem = self.overflow.components.container:FindItem(fn)
	    end

	    if not foundItem and self.casket then
			foundItem = self.casket.components.container:FindItem(fn)
		end

		return foundItem
	end

	local function FindItemsOverwrite(self, fn)
	    local items = {}
	    
	    for k,v in pairs(self.itemslots) do
	        if fn(v) then
	            table.insert(items, v)
	        end
	    end
	    
	    if self.activeitem and fn(self.activeitem) then
	        table.insert(items, self.activeitem)
	    end
	    
	    local overflow_items = {}

	    if self.overflow then
	        overflow_items = self.overflow.components.container:FindItems(fn)
	    end

	    if #overflow_items > 0 then
	        for k,v in pairs(overflow_items) do
	            table.insert(items, v)
	        end
	    end

	    local casket_items = {}

	    if self.casket then
	        casket_items = self.casket.components.container:FindItems(fn)
	    end

	    if #casket_items > 0 then
	        for k,v in pairs(casket_items) do
	            table.insert(items, v)
	        end
	    end

	    return items
	end

	local function GetNextAvailableSlotOverwrite(self, item)
		
		local prefabname = nil
		if item.components.stackable ~= nil then
			prefabname = item.prefab
		
	        --check for stacks that aren't full
	        for k,v in pairs(self.equipslots) do
	            if v.prefab == prefabname and v.components.equippable.equipstack and v.components.stackable and not v.components.stackable:IsFull() then
	                return k, self.equipslots
	            end
	        end
	        for k,v in pairs(self.itemslots) do
	            if v.prefab == prefabname and v.components.stackable and not v.components.stackable:IsFull() then
	                return k, self.itemslots
	            end
	        end
	        if self.overflow and self.overflow.components.container then
	            for k,v in pairs(self.overflow.components.container.slots) do
	                if v.prefab == prefabname and v.components.stackable and not v.components.stackable:IsFull() then
	                    return k, self.overflow
	                end
	            end
	        end
	        if self.casket and self.casket.components.container then
	            for k,v in pairs(self.casket.components.container.slots) do
	                if v.prefab == prefabname and v.components.stackable and not v.components.stackable:IsFull() then
	                    return k, self.casket
	                end
	            end
	        end
		end

	    --check for empty space in the container
		local empty = nil
	    for k = 1, self.maxslots do
			if self:CanTakeItemInSlot(item, k) and not self.itemslots[k] then
				if prefabname ~= nil then
					if empty == nil then
	            		empty = k
					end
				else
					return k, self.itemslots
				end
			end
	    end
	    return empty, self.itemslots
	end

	local function GiveItemOverride( self, inst, slot, screen_src_pos, skipsound )	    
	    

		local targetslot = slot

	    if not inst.components.inventoryitem or not inst:IsValid() then
	        return
	    end

	    local eslot = self:IsItemEquipped(inst)
	    
	    if eslot then
	       self:Unequip(eslot) 
	    end

	    local new_item = inst ~= self.activeitem
	    if new_item then
	        for k, v in pairs(self.equipslots) do
	            if v == inst then
	                new_item = false
	                break
	            end
	        end
	    end

		if inst.components.inventoryitem.owner and inst.components.inventoryitem.owner ~= self.inst then
	        inst.components.inventoryitem:RemoveFromOwner(true)
		end

	    local objectDestroyed = inst.components.inventoryitem:OnPickup(self.inst)
	    if objectDestroyed then
	      	return
	    end

	    local can_use_suggested_slot = false

	    if not slot and inst.prevslot and not inst.prevcontainer then
	        slot = inst.prevslot
	    end

	    if not slot and inst.prevslot and inst.prevcontainer then
	        if inst.prevcontainer.inst.components.inventoryitem and inst.prevcontainer.inst.components.inventoryitem.owner == self.inst and inst.prevcontainer:IsOpen() and inst.prevcontainer:GetItemInSlot(inst.prevslot) == nil then
	            if inst.prevcontainer:GiveItem(inst, inst.prevslot, false) then
	                return true
	            else
	                inst.prevcontainer = nil
	                inst.prevslot = nil
	                slot = nil
	            end
	        end
	    end

	    if slot then
	        local olditem = self:GetItemInSlot(slot)
	        can_use_suggested_slot = slot ~= nil and slot <= self.maxslots and ( olditem == nil or (olditem and olditem.components.stackable and olditem.prefab == inst.prefab)) and self:CanTakeItemInSlot(inst,slot)
	    end

	    local container = self.itemslots
	    if not can_use_suggested_slot then
			slot,container = self:GetNextAvailableSlot(inst)
	    end

	    local itemProcessed = false

	    if slot then
			if new_item and not skipsound then
				self.inst:PushEvent("gotnewitem", {item = inst, slot = slot})
			end
			
			local leftovers = nil
	        if container == self.overflow and self.overflow and self.overflow.components.container then
	            local overflow_itemInSlot = self.overflow.components.container:GetItemInSlot(slot) 
				if overflow_itemInSlot then
					leftovers = overflow_itemInSlot.components.stackable:Put(inst, screen_src_pos)
				end
	        elseif container == self.equipslots then
		        if self.equipslots[slot] then
					leftovers = self.equipslots[slot].components.stackable:Put(inst, screen_src_pos)
				end
		    elseif container == self.casket and self.casket and self.casket.components.container then
	            local casket_itemInSlot = self.casket.components.container:GetItemInSlot(slot) 
				if casket_itemInSlot then
					leftovers = casket_itemInSlot.components.stackable:Put(inst, screen_src_pos)
				end
			else
		        if self.itemslots[slot] ~= nil then
	                if self.itemslots[slot].components.stackable:IsFull() then
	                    leftovers = inst
	                    inst.prevslot = nil
	                else
	                    leftovers = self.itemslots[slot].components.stackable:Put(inst, screen_src_pos)
	                end
		        else
	                inst.components.inventoryitem:OnPutInInventory(self.inst)
		    	    self.itemslots[slot] = inst
				    self.inst:PushEvent("itemget", {item=inst, slot = slot, src_pos = screen_src_pos})
		        end

	            if inst.components.equippable then
	                inst.components.equippable:ToPocket()
	            end
	        end
	        
	        if leftovers then
	            self:GiveItem(leftovers)
	        end
	        
	        return slot
	    end

	    if not itemProcessed and self.overflow and self.overflow.components.container then
			if self.overflow.components.container:GiveItem(inst, nil, screen_src_pos) then
				itemProcessed = true
			end
		end

		if not itemProcessed and self.casket and self.casket.components.container then
			if self.casket.components.container:GiveItem(inst, nil, screen_src_pos) then
				itemProcessed = true
			end
		end

		if itemProcessed then
			return true
		end


	    self.inst:PushEvent("inventoryfull", {item=inst})
	    
	    --can't hold it!    
	    if not self.activeitem and not GLOBAL.TheInput:ControllerAttached() then
	        inst.components.inventoryitem:OnPutInInventory(self.inst)
	        self:SetActiveItem(inst)
	        return true
	    else
	        self:DropItem(inst, true, true)
	    end
	    
	end

	local function RemoveItemOverwrite(self, item, wholestack)

	    local dec_stack = not wholestack and item and item.components.stackable and item.components.stackable:IsStack() and item.components.stackable:StackSize() > 1
		
		local prevslot = item.components.inventoryitem and item.components.inventoryitem:GetSlotNum() or nil

	    if dec_stack then
	        local dec = item.components.stackable:Get()
	        dec.prevslot = prevslot
	        return dec
	    else
	        for k,v in pairs(self.itemslots) do
	            if v == item then
	                self.itemslots[k] = nil
	                self.inst:PushEvent("itemlose", {slot = k})
	                
	                if item.components.inventoryitem then
	                    item.components.inventoryitem:OnRemoved()
	                end
	                
					item.prevslot = prevslot
	                return item	                
	            end
	        end

	        local ret = nil
	        if item == self.activeitem then
	            self:SetActiveItem(nil)
	            ret = item
				self.inst:PushEvent("itemlose", {activeitem = true})            
	        end

	        for k,v in pairs(self.equipslots) do
	            if v == item then
	                self:Unequip(k)
	                ret = v
	            end
	        end
	        	        
	        if ret then
	            if ret.components.inventoryitem and ret.components.inventoryitem.OnRemoved then
	                ret.components.inventoryitem:OnRemoved()
					ret.prevslot = prevslot
	                return ret
	            end
	        else
	            if self.overflow and self.overflow.components.container and self.overflow.components.container:HasItemOrNull(item) then
			        local item = self.overflow.components.container:RemoveItem(item, wholestack)
			        item.prevslot = prevslot
					item.prevcontainer = self.overflow.components.container
					return item
	            end
	            if self.casket and self.casket.components.container and self.casket.components.container:HasItemOrNull(item) then
			        local item = self.casket.components.container:RemoveItem(item, wholestack)
			        item.prevslot = prevslot
					item.prevcontainer = self.casket.components.container

					return item
	            end
	        end

	    end
	    
	    return item

	end

	local OldHasFunction = inst.Has

	local function HasOverwrite(self, item, amount)
		oldreturn1, returnamount = OldHasFunction(self, item, amount)

	    if self.casket then
	    	local casket_enough, casket_found = self.casket.components.container:Has(item, amount)
			returnamount = returnamount + casket_found
	    end
	    
	    return returnamount >= amount, returnamount
	end

	if not GLOBAL.IsDLCEnabled(GLOBAL.REIGN_OF_GIANTS) then
		local function ConsumeByNameOverwrite ( self, item, amount )
			
			local total_num_found = 0
			
			local function tryconsume(v)
				local num_found = 0
				if v and v.prefab == item then
					local num_left_to_find = amount - total_num_found
					
					if v.components.stackable then
						if v.components.stackable.stacksize > num_left_to_find then
							v.components.stackable:SetStackSize(v.components.stackable.stacksize - num_left_to_find)
							num_found = amount
						else
							num_found = num_found + v.components.stackable.stacksize
							self:RemoveItem(v, true):Remove()
						end
					else
						num_found = num_found + 1
						self:RemoveItem(v):Remove()
					end
				end
				return num_found
			end
			

			for k = 1,self.maxslots do
				local v = self.itemslots[k]
				total_num_found = total_num_found + tryconsume(v)
				
				if total_num_found >= amount then
					break
				end
			end
			
			if self.activeitem and self.activeitem.prefab == item and total_num_found < amount then
				total_num_found = total_num_found + tryconsume(self.activeitem)
			end

			
			if self.overflow and total_num_found < amount then
				dumpvar, howmanyitemswereinoverflow = self.overflow.components.container:Has(item, 0)
				if howmanyitemswereinoverflow > 0 then
					self.overflow.components.container:ConsumeByName(item, (amount - total_num_found))
					total_num_found = total_num_found + howmanyitemswereinoverflow
				end
			end
			
			if self.casket and total_num_found < amount then
				dumpvar, howmanyitemswereincasket = self.casket.components.container:Has(item, 0)
			
				if howmanyitemswereincasket > 0 then
				
					self.casket.components.container:ConsumeByName(item, (amount - total_num_found))
					total_num_found = total_num_found + howmanyitemswereincasket
				end
			end
		end

		inst.ConsumeByName = ConsumeByNameOverwrite
	end

	local function GetItemByNameOverwrite (self, item, amount)
		local total_num_found = 0
		local items = {}
		
		local function tryfind(v)
		
			local num_found = 0
				if v and v.prefab == item then
					local num_left_to_find = amount - total_num_found
					if v.components.stackable then
						if v.components.stackable.stacksize > num_left_to_find then
							items[v] = num_left_to_find
							num_found = amount
						else
							items[v] = v.components.stackable.stacksize
							num_found = num_found + v.components.stackable.stacksize
						end
					else
						items[v] = 1
						num_found = num_found + 1
					end
			  end
			  
			  return num_found
			  
		end

		for k = self:GetNumSlots(), 1, -1 do
			local v = self.itemslots[k]
			total_num_found = total_num_found + tryfind(v)
			if total_num_found >= amount then
				break
			end
		end
		
		if self.activeitem and self.activeitem.prefab == item and total_num_found < amount then
			total_num_found = total_num_found + tryfind(self.activeitem)
		end
	
		if self.overflow and total_num_found < amount then
			local overflow_items = self.overflow.components.container:GetItemByName(item, (amount - total_num_found))
			for k,v in pairs(overflow_items) do
				items[k] = v
				total_num_found = total_num_found + v
			end
		end

		if self.casket and total_num_found < amount then
			local casket_items = self.casket.components.container:GetItemByName(item, (amount - total_num_found))
			for k,v in pairs(casket_items) do
				items[k] = v
				total_num_found = total_num_found + v
			end
		end	

		return items
	end

	inst.FindItem = FindItemOverwrite
	inst.FindItems = FindItemsOverwrite
	inst.GetNextAvailableSlot = GetNextAvailableSlotOverwrite
	inst.GiveItem = GiveItemOverride
	inst.RemoveItem = RemoveItemOverwrite
	inst.Has = HasOverwrite
	inst.GetItemByName = GetItemByNameOverwrite
	inst.SetCasket = SetCasket
end

AddComponentPostInit("inventory", Casket_inventory)

function Casket_container (inst)
	local function GetItemByNameOverride(self, item, amount)
		local total_num_found = 0
		local items = {}

		local function tryfind(v)
			local num_found = 0
			if v and v.prefab == item then
				local num_left_to_find = amount - total_num_found
				if v.components.stackable then
					if v.components.stackable.stacksize > num_left_to_find then
						items[v] = num_left_to_find
						num_found = amount
					else
						items[v] = v.components.stackable.stacksize
						num_found = num_found + v.components.stackable.stacksize
					end
				else
					items[v] = 1
					num_found = num_found + 1
				end
			end
			return num_found
		end
		
		for k = self:GetNumSlots(), 1, -1 do
			local v = self.slots[k]
			total_num_found = total_num_found + tryfind(v)
			if total_num_found >= amount then
				break
			end
		end
		--print("items", items)
		return items
	end

	local function HasItemOrNull(self,item)
	
		local toReturn = nil
	
		for k,v in pairs(self.slots) do
			if v == item then
				toReturn = v
				break
			end
		end
		
		return toReturn
	
	end
	
	local function RemoveItemOverwrite(self, item, wholestack)
	    local dec_stack = not wholestack and item and item.components.stackable and item.components.stackable:IsStack() and item.components.stackable:StackSize() > 1
		local slot = self:GetItemSlot(item)
	    if dec_stack then
	        local dec = item.components.stackable:Get()
	        dec.prevslot = slot
	        dec.prevcontainer = self
	        return dec
	    else
	        for k,v in pairs(self.slots) do
	            if v == item then
	                self.slots[k] = nil
	                self.inst:PushEvent("itemlose", {slot = k})
	                
	                if item.components.inventoryitem then
	                    item.components.inventoryitem:OnRemoved()
	                end
	                
			        item.prevslot = slot
			        item.prevcontainer = self
	                return item
	            end
	        end
	    end
	    
	    return item

	end

	inst.GetItemByName = GetItemByNameOverride
	inst.HasItemOrNull = HasItemOrNull
	inst.RemoveItem = RemoveItemOverwrite
end

AddComponentPostInit("container", Casket_container)
