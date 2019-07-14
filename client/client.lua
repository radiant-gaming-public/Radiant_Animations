local playerCurrentlyAnimated = false
local playerCurrentlyHasProp = false
local playerCurrentlyHasWalkstyle = false
local LastAD
local mp_pointing = false
local firstAnim = true
local surrendered = false
local keyboarding = false
local playerPropList = {}

Citizen.CreateThread( function()

	while true do
		Citizen.Wait(5)
		if (IsControlJustPressed(0,Config.RadioKey))  then
			local player = PlayerPedId()
			if ( DoesEntityExist( player ) and not IsEntityDead( player ) ) then 
				loadAnimDict( "random@arrests" )
				TaskPlayAnim(player, "random@arrests", "generic_radio_chatter", 2.0, 2.5, -1, 49, 0, 0, 0, 0 )
				RemoveAnimDict("random@arrests")
			end

		elseif (IsControlJustReleased(0,Config.RadioKey))  then
			local player = PlayerPedId()
			if IsEntityPlayingAnim(player, "random@arrests", "generic_radio_chatter", 3) then
				ClearPedSecondaryTask(player)
			end

		elseif (IsControlJustPressed(0,Config.HandsUpKey)) then
			local player = PlayerPedId()
	
			if ( DoesEntityExist( player ) and not IsEntityDead( player ) ) then
	
				loadAnimDict( "random@mugging3" )
	
				if IsEntityPlayingAnim(player, "random@mugging3", "handsup_standing_base", 3) then
					ClearPedSecondaryTask(player)
				else
					TaskPlayAnim(player, "random@mugging3", "handsup_standing_base", 2.0, 2.5, -1, 49, 0, 0, 0, 0 )
					RemoveAnimDict("random@mugging3")
				end
			end

		elseif (IsControlJustPressed(0,Config.HoverHolsterKey)) then
			local player = PlayerPedId()
			if vehiclecheck() then
				if ( DoesEntityExist( player ) and not IsEntityDead( player ) ) then
		
					loadAnimDict( "move_m@intimidation@cop@unarmed" )
		
					if IsEntityPlayingAnim(player, "move_m@intimidation@cop@unarmed", "idle", 3) then
						ClearPedSecondaryTask(player)
						RemoveAnimDict("move_m@intimidation@cop@unarmed")
					else
						TaskPlayAnim(player, "move_m@intimidation@cop@unarmed", "idle", 2.0, 2.5, -1, 49, 0, 0, 0, 0 )
						RemoveAnimDict("move_m@intimidation@cop@unarmed")
					end
				end
			end
		elseif IsControlJustPressed(0, 29) then
			local player = PlayerPedId()
			if IsPedOnFoot(player) then
				if mp_pointing or not (IsPedOnFoot(player)) then
					Citizen.InvokeNative(0xD01015C7316AE176, player, "Stop")
					SetPedConfigFlag(player, 36, 0)
					mp_pointing = false
					ClearPedSecondaryTask(player)
				else
					loadAnimDict("anim@mp_point")
					while not HasAnimDictLoaded("anim@mp_point") do
						Wait(500)
					end
					SetPedConfigFlag(player, 36, 1)
					TaskMoveNetwork(player, "task_mp_pointing", 0.5, 0, "anim@mp_point", 24)
					RemoveAnimDict("anim@mp_point")
					mp_pointing = true
				end
			end
		end
	end
end)

Citizen.CreateThread( function()
	while true do
		Citizen.Wait(25)
		if mp_pointing then
			local ped = PlayerPedId()
			local camPitch = GetGameplayCamRelativePitch()
			if camPitch < -70.0 then
				camPitch = -70.0
			elseif camPitch > 42.0 then
				camPitch = 42.0
			end
			camPitch = (camPitch + 70.0) / 112.0

			local camHeading = GetGameplayCamRelativeHeading()
			local cosCamHeading = Cos(camHeading)
			local sinCamHeading = Sin(camHeading)
			if camHeading < -180.0 then
				camHeading = -180.0
			elseif camHeading > 180.0 then
				camHeading = 180.0
			end
			camHeading = (camHeading + 180.0) / 360.0

			local blocked = 0
			local nn = 0

			local coords = GetOffsetFromEntityInWorldCoords(ped, (cosCamHeading * -0.2) - (sinCamHeading * (0.4 * camHeading + 0.3)), (sinCamHeading * -0.2) + (cosCamHeading * (0.4 * camHeading + 0.3)), 0.6)
			local ray = Cast_3dRayPointToPoint(coords.x, coords.y, coords.z - 0.2, coords.x, coords.y, coords.z + 0.2, 0.4, 95, ped, 7);
			nn,blocked,coords,coords = GetRaycastResult(ray)
			SetTaskPropertyFloat(ped, "Pitch", camPitch)
			SetTaskPropertyFloat(ped, "Heading", camHeading * -1.0 + 1.0)
			SetTaskPropertyBool(ped, "isBlocked", blocked)
			SetTaskPropertyBool(ped, "isFirstPerson", Citizen.InvokeNative(0xEE778F8C7E1142E2, Citizen.InvokeNative(0x19CAFA3C87F7C2FF)) == 4)
		end
	end
end)

RegisterNetEvent('Radiant_Animations:KillProps')
AddEventHandler('Radiant_Animations:KillProps', function()
	for _,v in pairs(playerPropList) do
		DeleteEntity(v)
	end

	playerCurrentlyHasProp = false
end)

RegisterNetEvent('Radiant_Animations:AttachProp')
AddEventHandler('Radiant_Animations:AttachProp', function(prop_one, boneone, x1, y1, z1, r1, r2, r3)
	local player = PlayerPedId()
	local x,y,z = table.unpack(GetEntityCoords(player))

	if not HasModelLoaded(prop_one) then
		loadPropDict(prop_one)
	end

	prop = CreateObject(GetHashKey(prop_one), x, y, z+0.2,  true,  true, true)
	AttachEntityToEntity(prop, player, GetPedBoneIndex(player, boneone), x1, y1, z1, r1, r2, r3, true, true, false, true, 1, true)
	SetModelAsNoLongerNeeded(prop_one)
	table.insert(playerPropList, prop)
	playerCurrentlyHasProp = true
end)

RegisterNetEvent('Radiant_Animations:Animation')
AddEventHandler('Radiant_Animations:Animation', function(ad, anim, body)
	local player = PlayerPedId()
	if playerCurrentlyAnimated then -- Cancel Old Animation

		loadAnimDict(ad)
		TaskPlayAnim( player, ad, "exit", 8.0, 1.0, -1, body, 0, 0, 0, 0 )
		Wait(750)
		ClearPedSecondaryTask(player)
		RemoveAnimDict(LastAD)
		RemoveAnimDict(ad)
		LastAD = ad
		playerCurrentlyAnimated = false
		TriggerEvent('Radiant_Animations:KillProps')
		return
	end

	if firstAnim then
		LastAD = ad
		firstAnim = false
	end

	loadAnimDict(ad)
	TaskPlayAnim(player, ad, anim, 4.0, 1.0, -1, body, 0, 0, 0, 0 )  --- We actually play the animation here
	RemoveAnimDict(ad)
	playerCurrentlyAnimated = true

end)

RegisterNetEvent('Radiant_Animations:StopAnimations')
AddEventHandler('Radiant_Animations:StopAnimations', function()

	local player = PlayerPedId()
	if vehiclecheck() then
		if IsPedUsingAnyScenario(player) then
			--ClearPedSecondaryTask(player)
			ClearPedTasks(player)
			return
		end

		if playerCurrentlyHasWalkstyle then
			ResetPedMovementClipset(player, 0.0)
			playerCurrentlyHasWalkstyle = false
		end

		if playerCurrentlyAnimated then
			if LastAD then
				RemoveAnimDict(LastAD)
			end

			if playerCurrentlyHasProp then
				TriggerEvent('Radiant_Animations:KillProps')
				playerCurrentlyHasProp = false
			end

			if surrendered then
				surrendered = false
			end

			--ClearPedSecondaryTask(player)
			ClearPedTasks(player)
			playerCurrentlyAnimated = false
		end
	end
end)

RegisterNetEvent('Radiant_Animations:Scenario')
AddEventHandler('Radiant_Animations:Scenario', function(ad)
	local player = PlayerPedId()
	TaskStartScenarioInPlace(player, ad, 0, 1)   
end)

RegisterNetEvent('Radiant_Animations:Walking')
AddEventHandler('Radiant_Animations:Walking', function(ad)
	local player = PlayerPedId()
	ResetPedMovementClipset(player, 0.0)
	RequestWalking(ad)
	SetPedMovementClipset(player, ad, 0.25)
	RemoveAnimSet(ad)
end)

RegisterNetEvent('Radiant_Animations:Keyboard')
AddEventHandler('Radiant_Animations:Keyboard', function()
	local ad = "missbigscore2aswitch"
	local player = PlayerPedId()

	if ( DoesEntityExist( player ) and not IsEntityDead( player )) then 
		loadAnimDict( ad )
		if ( IsEntityPlayingAnim( player, ad, "switch_mic_car_fra_laptop_hacker", 3 ) ) then 
			keyboarding = false
			TaskPlayAnim( player, ad, "exit", 3.0, 1.0, -1, 49, 0, 0, 0, 0 )
			RemoveAnimDict(ad)
			Wait (100)
		else
			TaskPlayAnim( player, ad, "switch_mic_car_fra_laptop_hacker", 3.0, 1.0, -1, 49, 0, 0, 0, 0 )
			RemoveAnimDict(ad)
			Wait (2500)
			keyboarding = true
			repeat
				TaskPlayAnim( player, ad, "switch_mic_car_fra_laptop_hacker", 3.0, 1.0, -1, 49, 0, 0, 0, 0 )
				Wait (2500)
			until not keyboarding
			TaskPlayAnim( player, ad, "exit", 3.0, 1.0, -1, 49, 0, 0, 0, 0 )
		end       
	end
end)

RegisterNetEvent('Radiant_Animations:Surrender')  -- Too many waits to make it work properly within the config
AddEventHandler('Radiant_Animations:Surrender', function()
	local player = PlayerPedId()
	local ad = "random@arrests"
	local ad2 = "random@arrests@busted"

	if ( DoesEntityExist( player ) and not IsEntityDead( player )) then 
		loadAnimDict( ad )
		loadAnimDict( ad2 )
		if ( IsEntityPlayingAnim( player, ad2, "idle_a", 3 ) ) then 
			TaskPlayAnim( player, ad2, "exit", 8.0, 1.0, -1, 2, 0, 0, 0, 0 )
			Wait (3000)
			TaskPlayAnim( player, ad, "kneeling_arrest_get_up", 8.0, 1.0, -1, 128, 0, 0, 0, 0 )
			RemoveAnimDict("random@arrests@busted")
			RemoveAnimDict("random@arrests" )
			surrendered = false
			LastAD = ad
			playerCurrentlyAnimated = false
		else

			TaskPlayAnim( player, "random@arrests", "idle_2_hands_up", 8.0, 1.0, -1, 2, 0, 0, 0, 0 )
			Wait (4000)
			TaskPlayAnim( player, "random@arrests", "kneeling_arrest_idle", 8.0, 1.0, -1, 2, 0, 0, 0, 0 )
			Wait (500)
			TaskPlayAnim( player, "random@arrests@busted", "enter", 8.0, 1.0, -1, 2, 0, 0, 0, 0 )
			Wait (1000)
			TaskPlayAnim( player, "random@arrests@busted", "idle_a", 8.0, 1.0, -1, 9, 0, 0, 0, 0 )
			Wait(100)
			surrendered = true
			playerCurrentlyAnimated = true
			LastAD = ad2
			RemoveAnimDict("random@arrests" )
			RemoveAnimDict("random@arrests@busted")
		end     
	end

	Citizen.CreateThread(function() --disabling controls while surrendering
		while surrendered do
			Citizen.Wait(1000)
			if IsEntityPlayingAnim(GetPlayerPed(PlayerId()), "random@arrests@busted", "idle_a", 3) then
				DisableControlAction(1, 140, true)
				DisableControlAction(1, 141, true)
				DisableControlAction(1, 142, true)
				DisableControlAction(0,21,true)
			end
		end
	end)
	
end)

AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		TriggerEvent('Radiant_Animations:StopAnimations')
	end
end)

RegisterCommand("e", function(source, args)

	local player = PlayerPedId()
	local argh = tostring(args[1])

	if argh == 'help' then -- List help commands
		TriggerEvent('chat:addMessage', { args = { '[^1Animations^0]: /e emotes, dances, walkstyles' } })
	elseif argh == 'emotes' then -- list emotes
		TriggerEvent('chat:addMessage', { args = { '[^1Animations^0]: /e {animation}, salute, finger, finger2, phonecall, surrender, facepalm, notes, brief, brief2, foldarms, foldarms2, damn, fail, gang1, gang2, no, pickbutt, grabcrotch, peace, cigar, cigar2, joint, cig, holdcigar, holdcig, holdjoint, dead, holster, aim, aim2, slowclap, box, cheer, bum, leanwall, copcrowd, copcrowd2, copidle, smoking, mechanic, mechanic2, shotbar, drunkbaridle, airplane, shock, lean, leanwall2, leanwall3, sitfloor, sitfloor2, bum2, layback, layback2, layfront, nervous, slowclap2, cheer2, cheer3, cheer4, drinkshot, falloverdrunk, drunkbaridle, waitatbar, fjump1, fjump2, slowclap3, leanback, jumpingjack, jumpingjack2, jumpingjack3, outofbreath, makeitrain' } })
	elseif argh == 'walkstyles' then -- list walkstyles
		TriggerEvent('chat:addMessage', { args = { '[^1Animations^0]: /e walk1-45' } })
	elseif argh == 'dances' then -- list dances
		TriggerEvent('chat:addMessage', { args = { '[^1Animations^0]: /e djidle1-60, djdance1-7, mdance1-54, fdance1-54' } })
	elseif argh == 'delprop' then -- Deletes Clients Props Command
		TriggerEvent('Radiant_Animations:KillProps')
	elseif argh == 'surrender' then -- I'll figure out a better way to do animations with this much depth later.
		TriggerEvent('Radiant_Animations:Surrender')
	elseif argh == 'stop' then -- Cancel Animations
		TriggerEvent('Radiant_Animations:StopAnimations')
	elseif argh == 'keyboard' then
		TriggerEvent('Radiant_Animations:Keyboard')		
	else
		for i = 1, #Config.Anims, 1 do
			local name = Config.Anims[i].name
			if argh == name then				
				local prop_one = Config.Anims[i].data.prop
				local boneone = Config.Anims[i].data.boneone
				if ( DoesEntityExist( player ) and not IsEntityDead( player )) then 

					if Config.Anims[i].data.type == 'prop' then
						if playerCurrentlyHasProp then --- Delete Old Prop

							TriggerEvent('Radiant_Animations:KillProps')
						end

						TriggerEvent('Radiant_Animations:AttachProp', prop_one, boneone, Config.Anims[i].data.x, Config.Anims[i].data.y, Config.Anims[i].data.z, Config.Anims[i].data.xa, Config.Anims[i].data.yb, Config.Anims[i].data.zc)

					elseif Config.Anims[i].data.type == 'brief' then

						if name == 'brief' then
							GiveWeaponToPed(player, 0x88C78EB7, 1, false, true)
						else
							GiveWeaponToPed(player, 0x01B79F17, 1, false, true)
						end
						return
					elseif Config.Anims[i].data.type == 'scenario' then
						local ad = Config.Anims[i].data.ad

						if vehiclecheck() then
							if IsPedActiveInScenario(player) then
								ClearPedTasks(player)
							else
								TriggerEvent('Radiant_Animations:Scenario', ad)
							end 
						end
					elseif Config.Anims[i].data.type == 'walkstyle' then
						local ad = Config.Anims[i].data.ad
						if vehiclecheck() then
							TriggerEvent('Radiant_Animations:Walking', ad)
							if not playerCurrentlyHasWalkstyle then
								playerCurrentlyHasWalkstyle = true
							end
						end
					else

						if vehiclecheck() then
							local ad = Config.Anims[i].data.ad
							local anim = Config.Anims[i].data.anim
							local body = Config.Anims[i].data.body
							
							TriggerEvent('Radiant_Animations:Animation', ad, anim, body) -- Load/Start animation

							if prop_one ~= 0 then
								local prop_two = Config.Anims[i].data.proptwo
								local bonetwo = nil

								loadPropDict(prop_one)
								TriggerEvent('Radiant_Animations:AttachProp', prop_one, boneone, Config.Anims[i].data.x, Config.Anims[i].data.y, Config.Anims[i].data.z, Config.Anims[i].data.xa, Config.Anims[i].data.yb, Config.Anims[i].data.zc)
								if prop_two ~= 0 then
									bonetwo = Config.Anims[i].data.bonetwo
									prop_two = Config.Anims[i].data.proptwo
									loadPropDict(prop_two)
									TriggerEvent('Radiant_Animations:AttachProp', prop_two, bonetwo, Config.Anims[i].data.twox, Config.Anims[i].data.twoy, Config.Anims[i].data.twoz, Config.Anims[i].data.twoxa, Config.Anims[i].data.twoyb, Config.Anims[i].data.twozc)
								end
							end
						end
					end
				end
			end
		end
	end
end)

--[[
RegisterCommand("testanim", function(source, args)
	local ad = 'missheist_agency3aig_13'
	local anim = 'wait_loops_axe'
	local body = 33

	TriggerEvent('Radiant_Animations:Animation', ad, anim, body)
end)
]]
--[[
	RegisterCommand("testanim", function(source, args)
	local ad = 'amb@world_human_janitor@male@idle_a'
	local anim = 'idle_a'
	--local ad = 'amb@world_human_janitor@male@base'
	--local anim = 'base'
	local body = 33
	local prop = 'prop_tool_shovel5'
	local boneone = 57005

	TriggerEvent('Radiant_Animations:Animation', ad, anim, body)
	TriggerEvent('Radiant_Animations:AttachProp', prop, 57005, 0.235, 0.60, 0.30, 65.0, -90.0, -30.0)
	--TriggerEvent('Radiant_Animations:AttachProp', prop, 57005, 0.20, 0.60, 0.30, 65.0, -90.0, -30.0)
end)
]]

function loadAnimDict(dict)
	RequestAnimDict(dict)
	while not HasAnimDictLoaded(dict) do
		Citizen.Wait(500)
	end
end

function loadPropDict(model)
	RequestModel(GetHashKey(model))
	while not HasModelLoaded(GetHashKey(model)) do
		Citizen.Wait(500)
	end
end

function RequestWalking(ad)
	RequestAnimSet( ad )
	while ( not HasAnimSetLoaded( ad ) ) do 
		Citizen.Wait( 500 )
	end 
end


function vehiclecheck()
	local player = PlayerPedId()
	if IsPedInAnyVehicle(player, false) then
		return false
	end
	return true
end