require = GLOBAL.require
require "class"
local containers = require "containers"

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

local RECIPETABS = GLOBAL.RECIPETABS
local Recipe = GLOBAL.Recipe
local Ingredient = GLOBAL.Ingredient
local TECH = GLOBAL.TECH
local net_entity = GLOBAL.net_entity
local ThePlayer = GLOBAL.ThePlayer
local SendRPCToServer = GLOBAL.SendRPCToServer
local RPC = GLOBAL.RPC

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

AddReplicableComponent("casket")

function dump(o)
	if type(o) == 'table' then
	   local s = '{ '
	   for k,v in pairs(o) do
		 if type(k) == 'table' then
			 print('Table', k)
			 --dump(k)
		 else
			 print('k', k)
			 print('v', v)
			 --dump(v)
		 end
		  
	   end
	end
 end

local function Casket_inventory(inst)

	local function SetCasket(self, casket, owner)
		self.casket = casket	
		self.inst.replica.inventory:_SetCasket(casket, owner)
	end

	local function GetCasket(self, casket)
		return self.casket or (self.inst.replica and self.inst.replica.inventory:_GetCasket()) or nil
	end
	
	local function tryconsume(self, v, amount)
		if v.components.stackable == nil then
			self:RemoveItem(v):Remove()
			return 1
		elseif v.components.stackable.stacksize > amount then
			v.components.stackable:SetStackSize(v.components.stackable.stacksize - amount)
			return amount
		else
			amount = v.components.stackable.stacksize
			self:RemoveItem(v, true):Remove()
			return amount
		end
		--shouldn't be possible?
		return 0
	end

	-- like the backpack container (overflow) I need a own one for the casket to return the container
	local function GetOverflowContainerCasket(self)
		local item = self.casket
		return item ~= nil and item.components.container or nil
	end
	
	local function FindItemOverwrite(self, fn)
		for k,v in pairs(self.itemslots) do
			if fn(v) then
				return v
			end
		end

		if self.activeitem and fn(self.activeitem) then
			return self.activeitem
		end

		local overflow = self:GetOverflowContainer()
		local foundItems = overflow ~= nil and overflow:FindItem(fn) or nil
		
		if foundItems then
			return foundItems
		else
			-- if no items found in the overflow container, then start searching in casket
			local overflowCasket = self:GetOverflowContainerCasket()
			return overflowCasket ~= nil and overflowCasket:FindItem(fn) or nil
		end		 
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

		local overflow = self:GetOverflowContainer()
		if overflow ~= nil then
			for k, v in pairs(overflow:FindItems(fn)) do
				table.insert(items, v)
			end
		end
		
		-- if no items found in the overflow container, then start searching in casket
		local overflowCasket = self:GetOverflowContainerCasket()
		if overflowCasket ~= nil then
			for k, v in pairs(overflowCasket:FindItems(fn)) do
				table.insert(items, v)
			end
		end

		return items
	end
	
	local function GetNextAvailableSlotOverwrite(self, item)
		local prefabname = nil
		local prefabskinname = nil
		if item.components.stackable ~= nil then
			prefabname = item.prefab
			prefabskinname = item.skinname

			--check for stacks that aren't full
			for k, v in pairs(self.equipslots) do
				if v.prefab == prefabname and v.skinname == prefabskinname and v.components.equippable.equipstack and v.components.stackable and not v.components.stackable:IsFull() then
					return k, self.equipslots
				end
			end
			for k, v in pairs(self.itemslots) do
				if v.prefab == prefabname and v.skinname == prefabskinname and v.components.stackable and not v.components.stackable:IsFull() then
					return k, self.itemslots
				end
			end
			if not (item.components.inventoryitem ~= nil and item.components.inventoryitem.canonlygoinpocket) then
				local overflow = self:GetOverflowContainer()
				if overflow ~= nil then
					for k, v in pairs(overflow.slots) do
						if v.prefab == prefabname and v.skinname == prefabskinname and v.components.stackable and not v.components.stackable:IsFull() then
							return k, overflow
						end
					end
				end
				
				-- check now additional in the casket container
				local overflowCasket = self:GetOverflowContainerCasket()
				if overflowCasket ~= nil then
					for k, v in pairs(overflowCasket.slots) do
						if v.prefab == prefabname and v.skinname == prefabskinname and v.components.stackable and not v.components.stackable:IsFull() then
							return k, overflowCasket
						end
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

	local function CanAcceptCountOverwrite(self, item, maxcount)
		local stacksize = math.max(maxcount or 0, item.components.stackable ~= nil and item.components.stackable.stacksize or 1)
		if stacksize <= 0 then
			return 0
		end

		local acceptcount = 0

		--check for empty space in the container
		for k = 1, self.maxslots do
			local v = self.itemslots[k]
			if v ~= nil then
				if v.prefab == item.prefab and v.skinname == item.skinname and v.components.stackable ~= nil then
					acceptcount = acceptcount + v.components.stackable:RoomLeft()
					if acceptcount >= stacksize then
						return stacksize
					end
				end
			elseif self:CanTakeItemInSlot(item, k) then
				if self.acceptsstacks or stacksize <= 1 then
					return stacksize
				end
				acceptcount = acceptcount + 1
				if acceptcount >= stacksize then
					return stacksize
				end
			end
		end

		if not (item.components.inventoryitem ~= nil and item.components.inventoryitem.canonlygoinpocket) then
			--check for empty space in our backpack
			local overflow = self:GetOverflowContainer()
			if overflow ~= nil then
				for k = 1, overflow.numslots do
					local v = overflow.slots[k]
					if v ~= nil then
						if v.prefab == item.prefab and v.skinname == item.skinname and v.components.stackable ~= nil then
							acceptcount = acceptcount + v.components.stackable:RoomLeft()
							if acceptcount >= stacksize then
								return stacksize
							end
						end
					elseif overflow:CanTakeItemInSlot(item, k) then
						if overflow.acceptsstacks or stacksize <= 1 then
							return stacksize
						end
						acceptcount = acceptcount + 1
						if acceptcount >= stacksize then
							return stacksize
						end
					end
				end
			end
			
			--check for casket
			local overflowCasket = self:GetOverflowContainerCasket()
			if overflowCasket ~= nil then
				for k = 1, overflowCasket.numslots do
					local v = overflowCasket.slots[k]
					if v ~= nil then
						if v.prefab == item.prefab and v.skinname == item.skinname and v.components.stackable ~= nil then
							acceptcount = acceptcount + v.components.stackable:RoomLeft()
							if acceptcount >= stacksize then
								return stacksize
							end
						end
					elseif overflowCasket:CanTakeItemInSlot(item, k) then -- check here for the casket
						if overflowCasket.acceptsstacks or stacksize <= 1 then
							return stacksize
						end
						acceptcount = acceptcount + 1
						if acceptcount >= stacksize then
							return stacksize
						end
					end
				end
			end
		end

		if item.components.stackable ~= nil then
			--check for equip stacks that aren't full
			for k, v in pairs(self.equipslots) do
				if v.prefab == item.prefab and v.skinname == item.skinname and v.components.equippable.equipstack and v.components.stackable ~= nil then
					acceptcount = acceptcount + v.components.stackable:RoomLeft()
					if acceptcount >= stacksize then
						return stacksize
					end
				end
			end
		end

		return acceptcount
	end
	
	local function RemoveItemOverwrite(self, item, wholestack)
		if item == nil then
			return
		end

		local prevslot = item.components.inventoryitem and item.components.inventoryitem:GetSlotNum() or nil

		if not wholestack and item.components.stackable ~= nil and item.components.stackable:IsStack() then
			local dec = item.components.stackable:Get()
			dec.prevslot = prevslot
			dec.prevcontainer = nil
			return dec
		end

		for k, v in pairs(self.itemslots) do
			if v == item then
				self.itemslots[k] = nil
				self.inst:PushEvent("itemlose", { slot = k })
				item.components.inventoryitem:OnRemoved()
				item.prevslot = prevslot
				item.prevcontainer = nil
				return item
			end
		end

		if item == self.activeitem then
			self:SetActiveItem()
			self.inst:PushEvent("itemlose", { activeitem = true })
			item.components.inventoryitem:OnRemoved()
			item.prevslot = prevslot
			item.prevcontainer = nil
			return item
		end

		for k, v in pairs(self.equipslots) do
			if v == item then
				self:Unequip(k)
				item.components.inventoryitem:OnRemoved()
				item.prevslot = prevslot
				item.prevcontainer = nil
				return item
			end
		end

		local overflow = self:GetOverflowContainer()
		local overflowItem =  overflow ~= nil and overflow:RemoveItem(item, wholestack) or item
		
		if overflowItem then
			return overflowItem
		else
			local overflowCasket = self:GetOverflowContainerCasket()
			return overflowCasket ~= nil and overflowCasket:RemoveItem(item, wholestack) or item
		end
	end

	local function HasOverwrite(self, item, amount)
		local num_found = 0
		for k, v in pairs(self.itemslots) do
			if v and v.prefab == item then
				if v.components.stackable ~= nil then
					num_found = num_found + v.components.stackable:StackSize()
				else
					num_found = num_found + 1
				end
			end
		end

		if self.activeitem and self.activeitem.prefab == item then
			if self.activeitem.components.stackable ~= nil then
				num_found = num_found + self.activeitem.components.stackable:StackSize()
			else
				num_found = num_found + 1
			end
		end

		local overflow = self:GetOverflowContainer()
		if overflow ~= nil then
			local overflow_enough, overflow_found = overflow:Has(item, amount)
			num_found = num_found + overflow_found
		end
		
		local overflowCasket = self:GetOverflowContainerCasket()
		if overflowCasket ~= nil then
			local overflow_enough, overflow_found = overflowCasket:Has(item, amount)
			num_found = num_found + overflow_found
		end

		return num_found >= amount, num_found
	end
		
	local function HasItemWithTagOverwrite(self, tag, amount)
		local num_found = 0
		for k, v in pairs(self.itemslots) do
			if v and v:HasTag(tag) then
				if v.components.stackable ~= nil then
					num_found = num_found + v.components.stackable:StackSize()
				else
					num_found = num_found + 1
				end
			end
		end

		if self.activeitem and self.activeitem:HasTag(tag) then
			if self.activeitem.components.stackable ~= nil then
				num_found = num_found + self.activeitem.components.stackable:StackSize()
			else
				num_found = num_found + 1
			end
		end

		local overflow = self:GetOverflowContainer()
		if overflow ~= nil then
			local overflow_enough, overflow_found = overflow:HasItemWithTag(tag, amount)
			num_found = num_found + overflow_found
		end

		local overflowCasket = self:GetOverflowContainerCasket()
		if overflowCasket ~= nil then
			local overflow_enough, overflow_found = overflowCasket:HasItemWithTag(tag, amount)
			num_found = num_found + overflow_found
		end
		
		return num_found >= amount, num_found
	end
	
	local function GetItemByNameOverwrite(self, item, amount) 
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

		for k = 1,self.maxslots do
			local v = self.itemslots[k]
			total_num_found = total_num_found + tryfind(v)
			if total_num_found >= amount then
				break
			end
		end

		if self.activeitem and self.activeitem.prefab == item and total_num_found < amount then
			total_num_found = total_num_found + tryfind(self.activeitem)
		end

		local overflow = self:GetOverflowContainer()
		if overflow and total_num_found < amount then
			local overflow_items = overflow:GetItemByName(item, (amount - total_num_found))
			for k,v in pairs(overflow_items) do
				items[k] = v
			end
		end
		
		local overflowCasket = self:GetOverflowContainerCasket()
		if overflowCasket and total_num_found < amount then
			local overflow_items = overflowCasket:GetItemByName(item, (amount - total_num_found))
			for k,v in pairs(overflow_items) do
				items[k] = v
			end
		end

		return items
	end

	local function ConsumeByNameOverwrite(self, item, amount)
		if amount <= 0 then
			return
		end

		for k = 1, self.maxslots do
			local v = self.itemslots[k]
			if v ~= nil and v.prefab == item then
				amount = amount - tryconsume(self, v, amount)
				if amount <= 0 then
					return
				end
			end
		end

		if self.activeitem ~= nil and self.activeitem.prefab == item then
			amount = amount - tryconsume(self, self.activeitem, amount)
			if amount <= 0 then
				return
			end
		end

		local overflow = self:GetOverflowContainer()
		if overflow ~= nil then
			overflow:ConsumeByName(item, amount)
		end
				
		local overflowCasket = self:GetOverflowContainerCasket()
		if overflowCasket ~= nil then
			overflowCasket:ConsumeByName(item, amount)
		end
	end

	local function GiveItemOverwrite(self, inst, slot, src_pos)
		if inst.components.inventoryitem == nil or not inst:IsValid() then
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

		local objectDestroyed = inst.components.inventoryitem:OnPickup(self.inst, src_pos)
		if objectDestroyed then
			return
		end

		local can_use_suggested_slot = false

		if not slot and inst.prevslot and not inst.prevcontainer then
			slot = inst.prevslot
		end

		if not slot and inst.prevslot and inst.prevcontainer then
			if inst.prevcontainer.inst:IsValid() and inst.prevcontainer:IsOpenedBy(self.inst) then
				local item = inst.prevcontainer:GetItemInSlot(inst.prevslot)
				if item == nil then
					if inst.prevcontainer:GiveItem(inst, inst.prevslot) then
						return true
					end
				elseif item.prefab == inst.prefab and item.skinname == inst.skinname and
					item.components.stackable ~= nil and
					inst.prevcontainer:AcceptsStacks() and
					inst.prevcontainer:CanTakeItemInSlot(inst, inst.prevslot) and
					item.components.stackable:Put(inst) == nil then
					return true
				end
			end
			inst.prevcontainer = nil
			inst.prevslot = nil
			slot = nil
		end

		if slot then
			local olditem = self:GetItemInSlot(slot)
			can_use_suggested_slot = slot ~= nil and slot <= self.maxslots and ( olditem == nil or (olditem and olditem.components.stackable and olditem.prefab == inst.prefab and olditem.skinname == inst.skinname)) and self:CanTakeItemInSlot(inst,slot)
		end

		local overflow = self:GetOverflowContainer()
		local overflowCasket = self:GetOverflowContainerCasket()
		local container = self.itemslots
		if not can_use_suggested_slot then
			slot, container = self:GetNextAvailableSlot(inst)
		end

		local itemProcessed = false
		if slot then
			if new_item and not self.ignoresound then
				self.inst:PushEvent("gotnewitem", { item = inst, slot = slot })
			end

			local leftovers = nil
			if overflow ~= nil and container == overflow then
				local itemInSlot = overflow:GetItemInSlot(slot) 
				if itemInSlot then
					leftovers = itemInSlot.components.stackable:Put(inst, src_pos)
				end
			elseif container == self.equipslots then
				if self.equipslots[slot] then
					leftovers = self.equipslots[slot].components.stackable:Put(inst, src_pos)
				end
			elseif overflowCasket ~= nil and container == overflowCasket then
				local casket_itemInSlot = overflowCasket:GetItemInSlot(slot) 
				if casket_itemInSlot then
					leftovers = casket_itemInSlot.components.stackable:Put(inst, src_pos)
				end
			else
				if self.itemslots[slot] ~= nil then
					if self.itemslots[slot].components.stackable:IsFull() then
						leftovers = inst
						inst.prevcontainer = nil
						inst.prevslot = nil
					else
						leftovers = self.itemslots[slot].components.stackable:Put(inst, src_pos)
					end
				else
					inst.components.inventoryitem:OnPutInInventory(self.inst)
					self.itemslots[slot] = inst
					self.inst:PushEvent("itemget", { item = inst, slot = slot, src_pos = src_pos })
				end

				if inst.components.equippable then
					inst.components.equippable:ToPocket()
				end
			end

			if leftovers then
				if not self:GiveItem(leftovers) and self.ignorefull then
					--Hack: should only reach here when moving items between containers
					return false
				end
			end

			return slot
		end
		
		if not itemProcessed and overflow ~= nil and overflow:GiveItem(inst, nil, src_pos) then
			itemProcessed = true
		end

		if not itemProcessed and self.casket and self.casket.components.container then
			if self.casket.components.container:GiveItem(inst, nil, screen_src_pos) then
				itemProcessed = true
			end
		end
		
		if itemProcessed then
			return true
		end

		if self.ignorefull then
			return false
		end

		if not (self.isloading or self.silentfull) and self.maxslots > 0 then
			self.inst:PushEvent("inventoryfull", { item = inst })
		end

		--can't hold it!
		if self.activeitem == nil and
			self.maxslots > 0 and
			not inst.components.inventoryitem.canonlygoinpocket and
			not (self.inst.components.playercontroller ~= nil and
				self.inst.components.playercontroller.isclientcontrollerattached) then
			inst.components.inventoryitem:OnPutInInventory(self.inst)
			self:SetActiveItem(inst)
			return true
		else
			self:DropItem(inst, true, true)
		end
	end

			
		
	-- set up all overwrites here
	inst.SetCasket = SetCasket
	inst.GetOverflowContainerCasket = GetOverflowContainerCasket
	inst.FindItem = FindItemOverwrite
	inst.FindItems = FindItemsOverwrite
	inst.GetNextAvailableSlot = GetNextAvailableSlotOverwrite
	inst.CanAcceptCount = CanAcceptCountOverwrite
	inst.RemoveItem = RemoveItemOverwrite
	inst.Has = HasOverwrite
	inst.HasItemWithTag = HasItemWithTagOverwrite
	inst.GetItemByName = GetItemByNameOverwrite
	inst.ConsumeByName = ConsumeByNameOverwrite
	inst.GiveItem = GiveItemOverwrite
end

local function Casket_inventory_classified(inst)	
	local TIMEOUT = 2

	local function Refresh(inst)
		inst._refreshtask = nil
		inst._busy = false
		inst._activeitem = inst._active:value()
		inst._returningitem = nil
		inst._itemspreview = nil
		inst._equipspreview = nil
		if inst._parent ~= nil then
			inst._parent:PushEvent("refreshinventory")
		end
	end

	local function QueueRefresh(inst, delay)
		if inst._refreshtask == nil then
			inst._refreshtask = inst:DoTaskInTime(delay, Refresh)
			inst._busy = true
		end
	end

	local function SetCasket(inst, casket)
		--print("### SetCasket classified", inst, casket)
		inst.casket = casket
		inst._casket:set(casket)
		--print(inst.casket)
	end
	
	local function GetCasket(inst)	
		--print("### GetCasket", inst)
		--dump(inst)
		if inst._casket then
			--print("---> inst._casket:value()", inst._casket:value())
			--dump(inst._casket:value())
			return inst._casket:value()
		else
			return nil
		end
	end

	local function SlotItem(item, slot)
		return item ~= nil and slot ~= nil and { item = item, slot = slot } or nil
	end
	
	local function SlotEquip(item, eslot)
		return item ~= nil and eslot ~= nil and  { item = item, eslot = eslot } or nil
	end
	
	
	local function PushItemGet(inst, data, ignoresound)
		if data ~= nil then
			if inst._itemspreview == nil then
				inst._itemspreview = inst:GetItems()
			end
			inst._itemspreview[data.slot] = data.item
			if inst._parent ~= nil then
				print('### PushItemGet ignoresound', ignoresound)
				if not ignoresound then
					inst._parent:PushEvent("gotnewitem", data)
				end
				inst._parent:PushEvent("itemget", data)
			end
			QueueRefresh(inst, TIMEOUT)
		end
	end
	
	local function PushStackSize(inst, item, stacksize, animatestacksize, activestacksize, animateactivestacksize, selfonly, sounddata)
		if item ~= nil and item.replica.stackable ~= nil then
			local oldstacksize = item.replica.stackable:StackSize()
			local data =
			{
				stacksize = stacksize,
				animatestacksize = animatestacksize,
				activestacksize = activestacksize,
				animateactivestacksize = animateactivestacksize,
				activecontainer = selfonly and inst._parent or nil,
			}
			if (stacksize ~= nil and stacksize ~= oldstacksize) or
				(activestacksize ~= nil and activestacksize ~= oldstacksize) then
				if inst._itemspreview == nil then
					for i, v in ipairs(inst._items) do
						if v:value() == item then
							inst._itemspreview = inst:GetItems()
							break
						end
					end
				end
				if inst._equipspreview == nil then
					for k, v in pairs(inst._equips) do
						if v:value() == item then
							inst._equipspreview = inst:GetEquips()
						end
					end
				end
				QueueRefresh(inst, TIMEOUT)
			end
			if sounddata ~= nil and inst._parent ~= nil then
				--This is for moving items between containers
				--Normally stack size previews have no sound
				inst._parent:PushEvent("gotnewitem", sounddata)
			end
			item:PushEvent("stacksizepreview", data)
		end
	end
		
	local function GetEquippedItem(inst, eslot)
		--print("### GetEquippedItem", inst)

		if inst._equipspreview ~= nil then
			return inst._equipspreview[eslot]
		end
	
		return inst._equips and inst._equips[eslot] ~= nil and inst._equips[eslot]:value() or nil
	end
	
	local function GetOverflowContainer(inst)
		-- print('### GetOverflowContainer', inst)

		local item = GetEquippedItem(inst, GLOBAL.EQUIPSLOTS.BODY)
		return item ~= nil and item.replica and item.replica.container and item.replica.container.classified or nil
	end

	-- like the backpack container (overflow) I need a own one for the casket to return the container
	local function GetOverflowContainerCasket(inst)
		--print("### GetOverflowContainerCasket", inst)
		local item = GetCasket(inst)
		
		--print("GetOverflowContainerCasket item", item)
		--print("GetOverflowContainerCasket item container", item and item.replica and item.replica.container)
		if item ~= nil and item.replica and item.replica and item.replica.container then
			--dump(item.replica.container)
		end
		return item ~= nil and item.replica and item.replica.container and item.replica.container.classified or nil
	end
	
	local function Count(item)
		return item.replica.stackable ~= nil and item.replica.stackable:StackSize() or 1
	end
	
	local function Has(inst, prefab, amount)	

		--print('### --------------------------------------------> Has prefab: ', prefab)
		--print('check with inst:', inst)
		--dump(inst)
		
		local count =
			inst._activeitem ~= nil and
			inst._activeitem.prefab == prefab and
			Count(inst._activeitem) or 0


		if inst._itemspreview ~= nil then
			for i, v in ipairs(inst._items) do
				local item = inst._itemspreview[i]
				if item ~= nil and item.prefab == prefab then
					count = count + Count(item)
				end
			end
		else
			for i, v in ipairs(inst._items) do
				local item = v:value()
				if item ~= nil and item ~= inst._activeitem and item.prefab == prefab then
					count = count + Count(item)
				end
			end
		end
		local overflow = GetOverflowContainer(inst)
--print('GetOverflowContainer overflow', overflow)
--dump(overflow)
		if overflow ~= nil then
			--print('### HAS recursion overflow')
			local overflowhas, overflowcount = Has(overflow, prefab, amount)
			count = count + overflowcount
		end
		
		local overflowCasket = GetOverflowContainerCasket(inst)
--print('GetOverflowContainerCasket overflowCasket', overflowCasket)
--dump(overflowCasket)
		if overflowCasket ~= nil then
			--print('### HAS recursion overflowCasket')
			local overflowhas, overflowcount = Has(overflowCasket, prefab, amount)
			count = count + overflowcount
		end
		--print('-------------------------------- HAS count ', count)
		return count >= amount, count
	end
	
	local function HasItemWithTag(inst, tag, amount)
		local count =
			inst._activeitem ~= nil and
			inst._activeitem:HasTag(tag) and
			Count(inst._activeitem) or 0

		if inst._itemspreview ~= nil then
			for i, v in ipairs(inst._items) do
				local item = inst._itemspreview[i]
				if item ~= nil and item:HasTag(tag) then
					count = count + Count(item)
				end
			end
		else
			for i, v in ipairs(inst._items) do
				local item = v:value()
				if item ~= nil and item ~= inst._activeitem and item:HasTag(tag) then
					count = count + Count(item)
				end
			end
		end

		local overflow = GetOverflowContainer(inst)
		if overflow ~= nil then
			local overflowhas, overflowcount = overflow:HasItemWithTag(tag, amount)
			count = count + overflowcount
		end
		
		local overflowCasket = GetOverflowContainerCasket(inst)
		if overflowCasket ~= nil then
			local overflowhas, overflowcount = overflowCasket:HasItemWithTag(tag, amount)
			count = count + overflowcount
		end

		return count >= amount, count
	end
	
	local function ReceiveItem(inst, item, count)
		if inst.IsBusy(inst) then
			return
		end
		
		local overflow = GetOverflowContainer(inst)
		overflow = overflow and overflow.classified or nil
		
		local overflowCasket = GetOverflowContainerCasket(inst)
		overflowCasket = overflowCasket and overflowCasket.classified or nil
				
		--print("overflowCasket")		
		--print(overflowCasket)		
		if overflow ~= nil and overflow:IsBusy() then
			return
		end
		
		local isstackable = item.replica.stackable ~= nil
		local originalstacksize = isstackable and item.replica.stackable:StackSize() or 1
		
		if not isstackable or inst._parent.replica.inventory == nil or not inst._parent.replica.inventory:AcceptsStacks() then
			for i, v in ipairs(inst._items) do
				if v:value() == nil then
					local giveitem = SlotItem(item, i)
					PushItemGet(inst, giveitem)
					if originalstacksize > 1 then
						PushStackSize(inst, item, nil, nil, 1, false, true)
						return originalstacksize - 1
					else
						return 0
					end
				end
			end
			
			local overflowGiveResult
			
			if overflow ~= nil then
				local overflowGiveResult = overflow:ReceiveItem(item, count) or nil
			end
			
			if overflowGiveResult ~= nil then
				return overflowGiveResult
			elseif overflowCasket ~= nil then
				return overflowCasket:ReceiveItem(item, count)
			end
		else
			local originalcount = count and math.min(count, originalstacksize) or originalstacksize
			count = originalcount
			if item.replica.equippable ~= nil then
				local eslot = item.replica.equippable:EquipSlot()
				local equip = inst:GetEquippedItem(eslot)
				if equip ~= nil and
					equip.prefab == item.prefab and equip.skinname == item.skinname and
					equip.replica.stackable ~= nil and
					not equip.replica.stackable:IsFull() then
					local stacksize = equip.replica.stackable:StackSize() + count
					local maxsize = equip.replica.stackable:MaxSize()
					
					if stacksize > maxsize then
						count = math.max(stacksize - maxsize, 0)
						stacksize = maxsize
					else
						count = 0
					end
					PushStackSize(inst, equip, stacksize, true, nil, nil, nil, SlotEquip(equip, eslot))
				end
			end
			if count > 0 then
				local emptyslot = nil
				for i, v in ipairs(inst._items) do
					local slotitem = v:value()
					if slotitem == nil then
						if emptyslot == nil then
							emptyslot = i
						end
					elseif slotitem.prefab == item.prefab and slotitem.skinname == item.skinname and
						slotitem.replica.stackable ~= nil and
						not slotitem.replica.stackable:IsFull() then
						local stacksize = slotitem.replica.stackable:StackSize() + count
						local maxsize = slotitem.replica.stackable:MaxSize()
						if stacksize > maxsize then
							count = math.max(stacksize - maxsize, 0)
							stacksize = maxsize
						else
							count = 0
						end
						PushStackSize(inst, slotitem, stacksize, true, nil, nil, nil, SlotItem(slotitem, i))
						if count <= 0 then
							break
						end
					end
				end
				if count > 0 then
					if emptyslot ~= nil then
						local giveitem = SlotItem(item, emptyslot)
						PushItemGet(inst, giveitem)
						if count ~= originalstacksize then
							PushStackSize(inst, item, nil, nil, count, false, true)
						end
						count = 0
					elseif overflow ~= nil then
						local remainder = overflow:ReceiveItem(item, count)
						if remainder ~= nil then
							count = math.max(count - (originalstacksize - remainder), 0)
						end
					elseif overflowCasket ~= nil then
						local remainder = overflowCasket:ReceiveItem(item, count)
						if remainder ~= nil then
							count = math.max(count - (originalstacksize - remainder), 0)
						end
					end
				end
			end
			if count ~= originalcount then
				return originalstacksize - (originalcount - count)
			end
		end
	end
	
	print('### global overwrites')
		inst.SetCasket = SetCasket
		inst.GetCasket = GetCasket
		inst._casket = net_entity(inst.GUID, "inventory._casket", "casketdirty")
		
	
	if not GLOBAL.TheWorld.ismastersim then	
		inst.GetOverflowContainerCasket = GetOverflowContainerCasket
		inst.GetEquippedItem = GetEquippedItem
		inst.Has = Has
		inst.HasItemWithTag = HasItemWithTag
		inst.ReceiveItem = ReceiveItem

		inst:ListenForEvent("casketdirty", function(a, b, c)
			print("### casketdirty")
			print("inst._casket", inst._casket)
			print("inst._casket:value()", inst._casket:value())
		end)
	end
end

AddComponentPostInit("inventory", Casket_inventory)

AddPrefabPostInit("inventory_classified", Casket_inventory_classified)


local InventoryReplica = require 'components/inventory_replica'

function InventoryReplica:_SetCasket(casket, owner)
	print('### replica _SetCasket')
	
	self.casket = casket

	if self.classified ~= nil then
		--print('### replica _SetCasket classified')
		--print(self.prefab)
		--dump(self.prefab)
		--print('------------------')
		--print(self.classified)
		--dump(self.classified)
		self.classified.SetCasket(self.classified, casket)
		--print("self.classified.GetCasket(self.classified)", self.classified.GetCasket(self.classified))
	end
end


function InventoryReplica:_GetCasket()
	print('### replica _GetCasket')	
	return self.casket or nil
end

function InventoryReplica:GetCasket()
	return self.casket
end

function InventoryReplica:GetOverflowContainerCasket(prefab, amount)
	if self.inst.components.inventory ~= nil then
		return self.inst.components.inventory:GetOverflowContainerCasket()
	else
		return self.classified ~= nil and self.classified:GetOverflowContainerCasket() or nil
	end
end

function InventoryReplica:Has(prefab, amount)
    if self.inst.components.inventory ~= nil then
        return self.inst.components.inventory:Has(prefab, amount)
    elseif self.classified ~= nil then
        return self.classified:Has(prefab, amount)
    else
        return amount <= 0, 0
    end
end

function InventoryReplica:HasItemWithTag(tag, amount)
    if self.inst.components.inventory ~= nil then
        return self.inst.components.inventory:HasItemWithTag(tag, amount)
    elseif self.classified ~= nil then
        return self.classified:HasItemWithTag(tag, amount)
    else
        return amount <= 0, 0
    end
end

local containers = require("containers")

local function container_classified(inst)
	print("### container_classified", inst)
	local TIMEOUT = 2

	local function IsBusy(inst)
		return inst._busy or inst._parent == nil
	end

	local function RefreshCrafting(inst)
		local player = ThePlayer
		if player ~= nil and player.replica.inventory ~= nil then
			local overflow = player.replica.inventory:GetOverflowContainer()			
			local overflowCasket = inventory ~= nil and inventory:GetOverflowContainerCasket() or nil
			if (overflow ~= nil and overflow.inst == inst._parent) or (overflowCasket ~= nil and overflowCasket.inst == inst._parent)  then
				player:PushEvent("refreshcrafting")
			end
		end
	end
	
	local function Refresh(inst)
		inst._refreshtask = nil
		inst._busy = false
		inst._itemspreview = nil
		if inst._parent ~= nil then
			inst._parent:PushEvent("refresh")
			RefreshCrafting(inst)
		end
	end

	local function QueueRefresh(inst, delay)
		if inst._refreshtask == nil then
			inst._refreshtask = inst:DoTaskInTime(delay, Refresh)
			inst._busy = true
			RefreshCrafting(inst)
		end
	end

	local function SlotItem(item, slot)
		return item ~= nil and slot ~= nil and { item = item, slot = slot } or nil
	end
	
	local function PushItemGet(inst, data, ignoresound)
		if data ~= nil then
			if inst._parent ~= nil then
				if not ignoresound and
					inst._parent.replica.inventoryitem ~= nil and
					inst._parent.replica.inventoryitem:IsHeldBy(ThePlayer) then
					ThePlayer:PushEvent("gotnewitem", data)
				end
				inst._parent:PushEvent("itemget", data)
			end
			if inst._itemspreview == nil then
				inst._itemspreview = inst:GetItems()
			end
			inst._itemspreview[data.slot] = data.item
			QueueRefresh(inst, TIMEOUT)
		end
	end
	
	local function PushItemLose(inst, data)
		if data ~= nil then
			if inst._parent ~= nil then
				inst._parent:PushEvent("itemlose", data)
			end
			if inst._itemspreview == nil then
				inst._itemspreview = inst:GetItems()
			end
			inst._itemspreview[data.slot] = nil
			QueueRefresh(inst, TIMEOUT)
		end
	end

	local function QueryActiveItem()
		local player = ThePlayer
		local inventory = player ~= nil and player.replica.inventory ~= nil and player.replica.inventory.classified or nil
		return inventory, inventory ~= nil and inventory:GetActiveItem() or nil, inventory == nil or inventory:IsBusy()
	end

	local function PushStackSize(inst, inventory, item, stacksize, animatestacksize, activestacksize, animateactivestacksize, selfonly, sounddata)
		if item ~= nil and item.replica.stackable ~= nil then
			if sounddata ~= nil then
				local player = ThePlayer
				local inventory = player ~= nil and player.replica.inventory ~= nil and player.replica.inventory.classified or nil
				local overflow = inventory ~= nil and inventory:GetOverflowContainer() or nil
				local overflowCasket = inventory ~= nil and inventory:GetOverflowContainerCasket() or nil
				print('### PushStackSize',inst )
				print('overflowCasket ', overflowCasket)
				if (overflow ~= nil and overflow.classified == inst) or (overflowCasket ~= nil and overflowCasket.classified == inst) then
					ThePlayer:PushEvent("gotnewitem", sounddata)
				end
			end
			local oldstacksize = item.replica.stackable:StackSize()
			item:PushEvent("stacksizepreview",
			{
				stacksize = stacksize,
				animatestacksize = animatestacksize,
				activestacksize = activestacksize,
				animateactivestacksize = animateactivestacksize,
				activecontainer = selfonly and inst._parent or nil,
			})
			if (stacksize ~= nil and stacksize ~= oldstacksize) or
				(activestacksize ~= nil and activestacksize ~= oldstacksize) then
				if inst._itemspreview == nil then
					for i, v in ipairs(inst._items) do
						if v:value() == item then
							inst._itemspreview = inst:GetItems()
							break
						end
					end
				end
				QueueRefresh(inst, TIMEOUT)
				if inventory ~= nil then
					inventory:QueueRefresh(TIMEOUT)
				end
			end
		end
	end

	local function ReturnActiveItemToSlot(inst, slot)
		--inventory_classified:ReturnActiveItem will call PushNewActiveItem and SendRPCToServer
		if not IsBusy(inst) then
			local inventory, active_item, busy = QueryActiveItem()
			if not busy and active_item ~= nil then
				local item = inst:GetItemInSlot(slot)
				if item == nil then
					local giveitem = SlotItem(active_item, slot)
					PushItemGet(inst, giveitem, true)
				elseif item.replica.stackable ~= nil and item.prefab == active_item.prefab and item.AnimState:GetSkinBuild() == active_item.AnimState:GetSkinBuild() then --item.skinname == active_item.skinname (this does not work on clients, so we're going to use the AnimState hack instead)
					local stacksize = item.replica.stackable:StackSize() + active_item.replica.stackable:StackSize()
					local maxsize = item.replica.stackable:MaxSize()
					PushStackSize(inst, nil, item, math.min(stacksize, maxsize), true)
				end
			end
		end
	end

	local function PutOneOfActiveItemInSlot(inst, slot)
		if not IsBusy(inst) then
			local inventory, active_item, busy = QueryActiveItem()
			if not busy and active_item ~= nil then
				local giveitem = SlotItem(active_item, slot)
				PushItemGet(inst, giveitem, true)
				PushStackSize(inst, inventory, active_item, 1, false, active_item.replica.stackable:StackSize() - 1, true)
				SendRPCToServer(RPC.PutOneOfActiveItemInSlot, slot, inst._parent)
			end
		end
	end

	local function TakeActiveItemFromHalfOfSlot(inst, slot)
		if not IsBusy(inst) then
			local inventory, active_item, busy = QueryActiveItem()
			if not busy and inventory ~= nil and active_item == nil then
				local item = inst:GetItemInSlot(slot)
				if item ~= nil then
					local takeitem = SlotItem(item, slot)
					inventory:PushNewActiveItem(takeitem, inst, slot)
					local stacksize = item.replica.stackable:StackSize()
					local halfstacksize = math.floor(stacksize / 2)
					PushStackSize(inst, inventory, item, stacksize - halfstacksize, true, halfstacksize, false)
					SendRPCToServer(RPC.TakeActiveItemFromHalfOfSlot, slot, inst._parent)
				end
			end
		end
	end

	local function AddOneOfActiveItemToSlot(inst, slot)
		if not IsBusy(inst) then
			local inventory, active_item, busy = QueryActiveItem()
			if not busy and active_item ~= nil then
				local item = inst:GetItemInSlot(slot)
				if item ~= nil and item.prefab == active_item.prefab and item.AnimState:GetSkinBuild() == active_item.AnimState:GetSkinBuild() then --item.skinname == active_item.skinname (this does not work on clients, so we're going to use the AnimState hack instead)
					PushStackSize(inst, nil, item, item.replica.stackable:StackSize() + 1, true)
					PushStackSize(inst, inventory, active_item, nil, nil, active_item.replica.stackable:StackSize() - 1, true)
					SendRPCToServer(RPC.AddOneOfActiveItemToSlot, slot, inst._parent)
				end
			end
		end
	end

	local function AddAllOfActiveItemToSlot(inst, slot)
		if not IsBusy(inst) then
			local inventory, active_item, busy = QueryActiveItem()
			if not busy and active_item ~= nil then
				local item = inst:GetItemInSlot(slot)
				if item ~= nil and item.prefab == active_item.prefab and item.AnimState:GetSkinBuild() == active_item.AnimState:GetSkinBuild() then --item.skinname == active_item.skinname (this does not work on clients, so we're going to use the AnimState hack instead)
					local stacksize = item.replica.stackable:StackSize() + active_item.replica.stackable:StackSize()
					local maxsize = item.replica.stackable:MaxSize()
					if stacksize <= maxsize then
						inventory:PushNewActiveItem()
						PushStackSize(inst, nil, item, stacksize, true)
					else
						PushStackSize(inst, nil, item, maxsize, true)
						PushStackSize(inst, inventory, active_item, stacksize - maxsize, false)
					end
					SendRPCToServer(RPC.AddAllOfActiveItemToSlot, slot, inst._parent)
				end
			end
		end
	end

	local function SwapOneOfActiveItemWithSlot(inst, slot)
		if not IsBusy(inst) then
			local inventory, active_item, busy = QueryActiveItem()
			if not busy and active_item ~= nil then
				local item = inst:GetItemInSlot(slot)
				if item ~= nil then
					local takeitem = SlotItem(item, slot)
					PushItemLose(inst, takeitem)
					local giveitem = SlotItem(active_item, slot)
					PushItemGet(inst, giveitem, true)
					PushStackSize(inst, inventory, active_item, 1, false, active_item.replica.stackable:StackSize() - 1, true)
					inventory:ReceiveItem(takeitem)
					SendRPCToServer(RPC.SwapOneOfActiveItemWithSlot, slot, inst._parent)
				end
			end
		end
	end

	local function MoveItemFromAllOfSlot(inst, slot, container)
		if not IsBusy(inst) then
			local container_classified = container ~= nil and container.replica.inventory ~= nil and container.replica.inventory.classified or (container.replica.container ~= nil and container.replica.container.classified or nil)
			if container_classified ~= nil and not container_classified:IsBusy() then
				local item = inst:GetItemInSlot(slot)
				if item ~= nil then
					local remainder = nil
					local player = ThePlayer
					if player ~= nil and player.components.constructionbuilderuidata ~= nil and player.components.constructionbuilderuidata:GetContainer() == container then
						local targetslot = player.components.constructionbuilderuidata:GetSlotForIngredient(item.prefab)
						if targetslot ~= nil then
							remainder = container_classified:ReceiveItem(item, nil, targetslot)
						end
					else
						remainder = container_classified:ReceiveItem(item)
					end
					if remainder ~= nil then
						if remainder > 0 then
							PushStackSize(inst, nil, item, nil, nil, remainder, false, true)
						else
							local takeitem = SlotItem(item, slot)
							PushItemLose(inst, takeitem)
						end
						SendRPCToServer(RPC.MoveItemFromAllOfSlot, slot, inst._parent, container.replica.container ~= nil and container or nil)
					end
				end
			end
		end
	end

	local function MoveItemFromHalfOfSlot(inst, slot, container)
		if not IsBusy(inst) then
			local container_classified = container ~= nil and container.replica.inventory ~= nil and container.replica.inventory.classified or (container.replica.container ~= nil and container.replica.container.classified or nil)
			if container_classified ~= nil and not container_classified:IsBusy() then
				local item = inst:GetItemInSlot(slot)
				if item ~= nil then
					local remainder = nil
					local player = ThePlayer
					if player ~= nil and player.components.constructionbuilderuidata ~= nil and player.components.constructionbuilderuidata:GetContainer() == container then
						local targetslot = player.components.constructionbuilderuidata:GetSlotForIngredient(item.prefab)
						if targetslot ~= nil then
							remainder = container_classified:ReceiveItem(item, math.floor(item.replica.stackable:StackSize() / 2), targetslot)
						end
					else
						remainder = container_classified:ReceiveItem(item, math.floor(item.replica.stackable:StackSize() / 2))
					end
					if remainder ~= nil then
						if remainder > 0 then
							PushStackSize(inst, nil, item, nil, nil, remainder, true, true)
						else
							local takeitem = SlotItem(item, slot)
							PushItemLose(inst, takeitem)
						end
						SendRPCToServer(RPC.MoveItemFromHalfOfSlot, slot, inst._parent, container.replica.container ~= nil and container or nil)
					end
				end
			end
		end
	end

	local function ReceiveItem(inst, item, count, forceslot)
		if not IsBusy(inst) and (forceslot == nil or (forceslot >= 1 and forceslot <= #inst._items)) then
			local isstackable = item.replica.stackable ~= nil
			local originalstacksize = isstackable and item.replica.stackable:StackSize() or 1
			local container = inst._parent.replica.container
			if forceslot == nil and container ~= nil then
				forceslot = container:GetSpecificSlotForItem(item)
			end
			if not isstackable or container == nil or not container:AcceptsStacks() then
				for i = forceslot or 1, forceslot or #inst._items do
					if inst._items[i]:value() == nil then
						local giveitem = SlotItem(item, i)
						PushItemGet(inst, giveitem)
						if originalstacksize > 1 then
							PushStackSize(inst, nil, item, nil, nil, 1, false, true)
							return originalstacksize - 1
						else
							return 0
						end
					end
				end
			else
				local originalcount = count and math.min(count, originalstacksize) or originalstacksize
				count = originalcount
				local emptyslot = nil
				for i = forceslot or 1, forceslot or #inst._items do
					local slotitem = inst._items[i]:value()
					if slotitem == nil then
						if emptyslot == nil then
							emptyslot = i
						end
					elseif slotitem.prefab == item.prefab and slotitem.AnimState:GetSkinBuild() == item.AnimState:GetSkinBuild() and --slotitem.skinname == item.skinname (this does not work on clients, so we're going to use the AnimState hack instead)
						slotitem.replica.stackable ~= nil and
						not slotitem.replica.stackable:IsFull() then
						local stacksize = slotitem.replica.stackable:StackSize() + count
						local maxsize = slotitem.replica.stackable:MaxSize()
						if stacksize > maxsize then
							count = math.max(stacksize - maxsize, 0)
							stacksize = maxsize
						else
							count = 0
						end
						PushStackSize(inst, nil, slotitem, stacksize, true, nil, nil, nil, SlotItem(slotitem, i))
						if count <= 0 then
							break
						end
					end
				end
				if count > 0 and emptyslot ~= nil then
					local giveitem = SlotItem(item, emptyslot)
					PushItemGet(inst, giveitem)
					if count ~= originalstacksize then
						PushStackSize(inst, nil, item, nil, nil, count, false, true)
					end
					count = 0
				end
				if count ~= originalcount then
					return originalstacksize - (originalcount - count)
				end
			end
		end
	end

	local function ConsumeByName(inst, prefab, amount)
		if amount <= 0 then
			return
		end
	
		for i, v in ipairs(inst._items) do
			local item = v:value()
			if item ~= nil and item.prefab == prefab then
				local stacksize = item.replica.stackable ~= nil and item.replica.stackable:StackSize() or 1
				if stacksize <= amount then
					local takeitem = SlotItem(item, i)
					PushItemLose(inst, takeitem)
					if amount <= stacksize then
						return
					end
					amount = amount - stacksize
				else
					PushStackSize(inst, nil, item, stacksize - amount, true)
					return
				end
			end
		end
	end
	
	local function TakeActionItem(inst, item, slot)
		if not IsBusy(inst) and inst:GetItemInSlot(slot) == item then
			local takeitem = SlotItem(item, slot)
			PushItemLose(inst, takeitem)
		end
	end

	if not GLOBAL.TheWorld.ismastersim then
		print('### container_classified overwrite')
        --Client interface
        inst.ReturnActiveItemToSlot = ReturnActiveItemToSlot
        inst.PutOneOfActiveItemInSlot = PutOneOfActiveItemInSlot
        inst.TakeActiveItemFromHalfOfSlot = TakeActiveItemFromHalfOfSlot
        inst.AddOneOfActiveItemToSlot = AddOneOfActiveItemToSlot
        inst.AddAllOfActiveItemToSlot = AddAllOfActiveItemToSlot
		inst.SwapOneOfActiveItemWithSlot = SwapOneOfActiveItemWithSlot
        inst.MoveItemFromAllOfSlot = MoveItemFromAllOfSlot
        inst.MoveItemFromHalfOfSlot = MoveItemFromHalfOfSlot

        --Exposed for inventory
        inst.ReceiveItem = ReceiveItem
        inst.ConsumeByName = ConsumeByName
        inst.TakeActionItem = TakeActionItem
        inst.IsBusy = IsBusy
    end
end


AddPrefabPostInit("container_classified", container_classified)