local syncAttempts = {}
local cars = {}

-- http://wiki.multitheftauto.com/wiki/FindRotation
function findRotation(x1,y1,x2,y2)
  local t = -math.deg(math.atan2(x2-x1,y2-y1))
  if t < 0 then t = t + 360 end;
  return t;
end

function getPointFromDistanceRotation(x,y,dist,angle)
    local a = math.rad(angle - 90);
 
    local dx = math.cos(a) * -dist;
    local dy = math.sin(a) * -dist;
 
    return x+dx, y+dy;
end

function getNodeHeight (node,precision)
	if not precision then precision = 0.5 end
	if precision > 10 then return false end
	local hit,x,y,z = processLineOfSight(node.x,node.y,node.z-precision,node.x,node.y,node.z+precision,true,false,false,true,false,true,false,true)
	if hit then
		return z
	else
		return getNodeHeight(node,precision+0.5)
	end
end

function isReachable (next,current,car)
	if not next then return false end
	local info = cars[car]
	if info.history[next] then return false end
	local x,y,z = getElementPosition(car)
	local height = getNodeHeight(next) or 0
	local hit,x,y,z = processLineOfSight(current.x,current.y,z,next.x,next.y,height+getElementDistanceFromCentreOfMassToBaseOfModel(car),true,false,false,true,false,true,false,true,car)
	if hit then return false end
	return true
end

function getNeighbor (current,car)
	local next
	if isReachable(carnodes[current.neighbor],current,car) then
		next = carnodes[current.neighbor]
	elseif isReachable(carnodes[current.closest[1]],current,car) then
		next = carnodes[current.closest[1]]
	elseif isReachable(carnodes[current.closest[2]],current,car) then
		next = carnodes[current.closest[2]]
	else
		--[[
		local x,y,z = getElementPosition(car)
		local _,_,r = getElementRotation(car)
		local distances = {}
		for id,node in pairs (carnodes) do
			local distance = getDistanceBetweenPoints2D(node.x,node.y,x,y)
			local target = findRotation(x,y,node.x,node.y)
			if math.abs(target-r) < 90 then
				table.insert(distances,{distance=distance+math.abs(target-r),node=node})
			end
		end
		table.sort(distances,function (a,b) return a.distance < b.distance end)
		for i,distance in ipairs (distances) do
			local height = getNodeHeight(distance.node) or 0
			if not processLineOfSight(x,y,z,distance.node.x,distance.node.y,height+getElementDistanceFromCentreOfMassToBaseOfModel(car),true,false,false,true,false,true,false,true,car) then
				return distance.node
			end
		end
		]]
		return false
	end
	return next
end

addEventHandler("onClientElementStreamOut",root,
	function ()
		if not isElement(source) then return end -- for some reason this is possible
		if cars[source] then
			triggerServerEvent("stopCarSync",localPlayer,source,false,cars[source].current)
			cars[source] = nil
		end
	end
)

addEventHandler("onClientElementStreamIn",root,
	function ()
		if not isElement(source) then return end -- for some reason this is possible
		if syncAttempts[source] then
			if (getTickCount()-syncAttempts[source]) < 5000 then
				return
			end
		end
		if getElementData(source,"cars.synced") == "nope" then
			syncAttempts[source] = getTickCount()
			triggerServerEvent("startCarSync",localPlayer,source)
			outputDebugString("Attempting to sync a "..tostring(getVehicleName(source)).."...")
		end
	end
)

addEvent("startClientCarSync",true)
addEventHandler("startClientCarSync",resourceRoot,
	function (vehicle,car,precision)
		setElementFrozen(vehicle,true)
		local current = car.current
		local height = getNodeHeight(current)
		if not height then return triggerServerEvent("stopCarSync",localPlayer,vehicle) end
		cars[vehicle] = car
		local x,y,z = getElementPosition(vehicle)
		setElementPosition(vehicle,x,y,height+getElementDistanceFromCentreOfMassToBaseOfModel(vehicle))
		cars[vehicle].history = {}
		local next = getNeighbor(car.current,vehicle)
		cars[vehicle].history = {car.current}
		if next then
			outputDebugString("Now syncing that "..tostring(getVehicleName(vehicle)))
			setElementRotation(vehicle,0,0,findRotation(x,y,next.x,next.y))
			car.next = next
			setPedControlState(car.ped,"accelerate",true)
			setTimer(setElementFrozen,2000,1,vehicle,false)
		else
			cars[vehicle] = nil
			setPedControlState(car.ped,"accelerate",false)
			triggerServerEvent("stopCarSync",localPlayer,vehicle,true)
		end
	end
)

addEventHandler("onClientRender",root,
	function ()
		for car,info in pairs (cars) do
			local x,y,z = getElementPosition(car)
			local a,b,r = getElementRotation(car)
			local current = info.current
			local next = info.next
			if getDevelopmentMode() and current then
				local x,y = getScreenFromWorldPosition(current.x,current.y,z+6)
				if x and y then
					dxDrawText(tostring(current.id).." ("..current.lanes[1].."-"..current.lanes[2]..")",x,y)
				end
				dxDrawLine3D(current.x,current.y,z-5,current.x,current.y,z+5,tocolor(255,0,0))
			end
			if next then
				if getDevelopmentMode() then
					local x,y = getScreenFromWorldPosition(next.x,next.y,z+6)
					if x and y then
						dxDrawText(tostring(next.id).." ("..next.lanes[1].."-"..next.lanes[2]..")",x,y)
					end
					dxDrawLine3D(next.x,next.y,z-5,next.x,next.y,z+5,tocolor(0,255,0))
					dxDrawLine3D(current.x,current.y,z,next.x,next.y,z,tocolor(0,0,255))
				end
				if getDistanceBetweenPoints2D(x,y,next.x,next.y) > 2 then
					local target = findRotation(x,y,next.x,next.y)
					local cx,cy = getPointFromDistanceRotation(x,y,16,r)
					local hit = processLineOfSight(x,y,z,cx,cy,z,true,true,true,false,false,true,false,true,car)
					if getDevelopmentMode() then
						dxDrawLine3D(x,y,z,cx,cy,z,tocolor(255,255,0))
					end
					if hit then
						setPedControlState(info.ped,"vehicle_right",true)
						setPedControlState(info.ped,"horn",true)
					elseif math.abs(target-r) < 3 or math.abs(target-r) > 180 then
						setPedControlState(info.ped,"vehicle_left",false)
						setPedControlState(info.ped,"vehicle_right",false)
						setPedControlState(info.ped,"horn",false)
						setElementRotation(car,a,b,target)
					elseif target > r then
						setPedControlState(info.ped,"vehicle_left",true)
						setPedControlState(info.ped,"vehicle_right",false)
						setPedControlState(info.ped,"horn",false)
					elseif target < r then
						setPedControlState(info.ped,"vehicle_left",false)
						setPedControlState(info.ped,"vehicle_right",true)
						setPedControlState(info.ped,"horn",false)
					end
				else
					info.current = next
					info.history[next] = true
					local next = getNeighbor(info.current,car)
					if next then
						info.next = next
					else
						cars[car] = nil
						setPedControlState(info.ped,"accelerate",false)
						triggerServerEvent("stopCarSync",localPlayer,car,true)
					end
				end
			end
		end
	end
)