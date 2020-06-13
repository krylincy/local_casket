require "prefabutil"

local assets = {
	Asset("ANIM", "anim/casket.zip"),
	Asset("IMAGE", "images/inventoryimages/casket.tex"),
    Asset("ATLAS", "images/inventoryimages/casket.xml"),	
	Asset("IMAGE", "images/casket.tex"),
	Asset("ATLAS", "images/casket.xml"),
}

local slotpos = {}
local spacer = 30
local posX
local poxY


local function onopen(inst)
	inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_open")
end 

local function onclose(inst) 
	inst.SoundEmitter:PlaySound("dontstarve/wilson/chest_close")
end 


local function onPickup(inst, owner) 
	-- set the owner for the casket to check later, if there is one in inventory
    if owner.components ~= nil and owner.components.inventory ~= nil then
		owner.components.inventory:SetCasket(inst)	
	end 
	
	if inst.components.casket ~= nil then
		inst.components.casket:SetOwner(owner)
	end 	
		
	owner.casket = inst
end 


local function onDropped(inst) 
	-- remove the binding to the casket, else items would still get into it while not in inventory
	local casket_owner =  inst.components.casket.owner
	if casket_owner.components ~= nil and casket_owner.components.inventory ~= nil then
		casket_owner.components.inventory:SetCasket(nil)
	end 
	
	if inst.components.casket ~= nil then
		inst.components.casket:SetOwner(nil)
	end 
end 


local function onhammered(inst, worker)	
	inst.components.lootdropper:DropLoot()
	inst.components.container:DropEverything()
	SpawnPrefab("collapse_small").Transform:SetPosition(inst.Transform:GetWorldPosition())
	inst.SoundEmitter:PlaySound("dontstarve/common/destroy_wood")	
	inst:Remove()
end

---------------------------------------------------------------
-- setup container widget with new size for the casket prefab

-- building the slot table and position
for z = 0, 2 do
	for y = 7, 0, -1 do
		for x = 0, 4 do
			posX = 80*x-600 + 80*5*z + spacer*z
			posY = 80*y-100

			if y > 3 then
				posY = posY + spacer
			end

			table.insert(slotpos, Vector3(posX, posY, 0))
		end
	end
end

local containers = require "containers"
local containerparams = {}
containerparams.casket = {
    widget =
    {
        slotpos = slotpos,
        pos = Vector3(0, -100, 0),
		bgatlas = "images/casket-ui.xml",
		bgimage = "casket-ui.tex",
    },
	issidewidget = false,
    type = "casket",
}

containers.MAXITEMSLOTS = math.max(containers.MAXITEMSLOTS, containerparams.casket.widget.slotpos ~= nil and #containerparams.casket.widget.slotpos or 0)

local oldWidgetsetupFunction = containers.widgetsetup

---------------------------------------------------------------
	
containers.widgetsetup = function (container, prefab, data)	
	if prefab == "casket" then
		local t = containerparams.casket or data or params[prefab or container.inst.prefab]
		if t ~= nil then
			for k, v in pairs(t) do
				container[k] = v
			end
			container:SetNumSlots(container.widget.slotpos ~= nil and #container.widget.slotpos or 0)
		end
	
	else
		oldWidgetsetupFunction(container, prefab, data)
	end	
end

local function fn(Sim)	
    local inst = CreateEntity()
		
    inst.entity:AddTransform()
	inst.entity:AddAnimState()
	inst.entity:AddSoundEmitter()
	inst.entity:AddMiniMapEntity()
	inst.entity:AddNetwork()
	
    MakeInventoryPhysics(inst)

    inst.AnimState:SetBank("casket")
    inst.AnimState:SetBuild("casket")
	inst.AnimState:PlayAnimation("idle")	

	inst.MiniMapEntity:SetIcon("casket.tex")
		
	MakeInventoryFloatable(inst, "idle", "idle")	
	
	inst.entity:SetPristine()

	if not TheWorld.ismastersim then
		inst.OnEntityReplicated = function(inst) 
			-- add replica widget for client
			inst.replica.container:WidgetSetup("casket",containerparams.casket)  
		end
		
		return inst
	end	

	
	inst:AddTag("noautopickup") -- for my own other mod to not auto pickup this item with the orange amulet
	
	inst:AddComponent("inventoryitem")
	inst.components.inventoryitem.atlasname = "images/inventoryimages/casket.xml"
    inst.components.inventoryitem.imagename = "casket"	
	
	--print("#####")
	--print(TUNING.CASKETHOST)
	if TUNING.CASKETHOST == 1 then
		--print("add casket functions")
		-- add functions to the casket is host only is playing
		inst:AddComponent("casket")
		
		inst.components.inventoryitem:SetOnDroppedFn(onDropped)
		inst.components.inventoryitem:SetOnPutInInventoryFn(onPickup)
	else
		--print("add chest tag")
		inst:AddTag("chest") -- add to work with "craft from chest" mod
	end		
	
	
	inst:AddComponent("container")
	inst.components.container:WidgetSetup("casket",containerparams.casket)
	
    inst.components.container.onopenfn = onopen
	inst.components.container.onclosefn = onclose

	

	MakeSmallPropagator(inst)

    return inst
end

return Prefab("common/casket", fn, assets)