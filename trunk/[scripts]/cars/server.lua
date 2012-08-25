local cars = {}

addEventHandler("onResourceStart",resourceRoot,
	function ()
		for id,node in pairs (carnodes) do
			if math.random(1,8) == 1 and node.neighbor then
				local car
				repeat
					if car then destroyElement(car) end
					car = createVehicle(math.random(400,611),node.x,node.y,node.z)
				until car ~= false and getVehicleType(car) == "Automobile"
				local ped
				repeat
					ped = createPed(math.random(0,288),node.x,node.y,node.z)
				until ped ~= false
				cars[car] = {current=node,ped=ped}
				setElementData(car,"cars.synced","nope",true)
				warpPedIntoVehicle(ped,car)
				setVehicleHandling(car,"maxVelocity",20)
				setVehicleRespawnPosition(car,node.x,node.y,node.z)
				setVehicleRespawnDelay(car,30000)
			end
		end
	end
)

addEvent("startCarSync",true)
addEventHandler("startCarSync",root,
	function (car)
		setElementFrozen(car,false)
		setElementSyncer(car,source)
		setElementSyncer(cars[car].ped,source)
		setElementData(car,"cars.synced",source,true)
		triggerClientEvent("startClientCarSync",resourceRoot,car,cars[car])
	end
)

addEvent("stopCarSync",true)
addEventHandler("stopCarSync",root,
	function (car,reset,current)
		local node = cars[car].current
		if reset then
			setElementPosition(car,5000,5000,5000)
			blowVehicle(car,false)
		end
		setElementFrozen(car,true)
		setElementSyncer(car,false)
		setElementSyncer(cars[car].ped,false)
		setElementData(car,"cars.synced","nope",true)
		if current then
			cars[car].current = current
		end
	end
)