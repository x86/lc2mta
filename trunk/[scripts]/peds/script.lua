local standbypeds = {}
local peds = {}

function createPeds ()
	for model,nodes in pairs (pednodes) do
		for i,node in ipairs (nodes) do
			if i > 2 then
				break
			else
				local ped
				repeat
					ped = createPed(math.random(10,288),node.x,node.y,node.z)
				until ped ~= false
				setElementFrozen(ped,true)
				standbypeds[ped] = {object=model,current=node.id,history={node.id},reversing=false}
			end
		end
	end
end

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

function getNeighbor (object,currentid)
	-- default method
	local nextid = pednodes[object][currentid+1].neighbor
	if nextid == -1 then
		return false
	else
		return pednodes[object][nextid+1]
	end
end

addEventHandler("onClientElementStreamOut",root,
	function ()
		if not isElement(source) then return end -- for some reason this is possible
		if peds[source] then
			setElementFrozen(source,true)
			local object,current = peds[source].object,peds[source].current
			peds[source] = nil
			standbypeds[source] = {object=object,current=current,history={current},reversing=false}
		end
	end
)

addEventHandler("onClientElementStreamIn",root,
	function ()
		if not isElement(source) then return end -- for some reason this is possible
		local ped = standbypeds[source]
		if ped then
			peds[source] = ped
			local current = pednodes[ped.object][ped.current+1]
			local hit,x,y,z = processLineOfSight(current.x,current.y,current.z+3,current.x,current.y,current.z-3,true,true,true,true,false,true,false,true,source)
			if hit then
				current.z = z
				local next = getNeighbor(ped.object,ped.current)
				if next then
					setElementFrozen(source,false)
					setElementPosition(source,x,y,z+1)
					setPedControlState(source,"forwards",true)
					setPedControlState(source,"walk",true)
					ped.next = next.id
					setPedRotation(source,findRotation(current.x,current.y,next.x,next.y))
				else
					peds[source] = nil
					destroyElement(source)
				end
			else
				peds[source] = nil
				destroyElement(source)
			end
		end
	end
)

addEventHandler("onClientRender",root,
	function ()
		for ped,info in pairs (peds) do
			if info.next then
				local x,y,z = getElementPosition(ped)
				local current = pednodes[info.object][info.current+1]
				local next = pednodes[info.object][info.next+1]
				if getDevelopmentMode() then
					dxDrawLine3D(current.x,current.y,z,next.x,next.y,z,tocolor(0,0,255))
					dxDrawLine3D(current.x,current.y,z-10,current.x,current.y,z+10,tocolor(255,0,0))
					dxDrawLine3D(next.x,next.y,z-10,next.x,next.y,z+10,tocolor(0,255,0))
				end
				if getDistanceBetweenPoints2D(x,y,next.x,next.y) < 2 then
					info.current = next.id
					if info.reversing then
						info.next = info.history[#info.history]
						if info.next then
							table.remove(info.history,#info.history)
						else
							info.reversing = false
						end
					else
						table.insert(info.history,info.current)
						local next = getNeighbor(info.object,info.current,info.reversing)
						if next then
							info.next = next.id
						else
							info.reversing = true
						end
					end
				else
					setPedRotation(ped,findRotation(x,y,next.x,next.y))
				end
				--[[ evading stuff
				else
					z = z-0.3
					local ltx,lty = getPointFromDistanceRotation(x,y,3,getPedRotation(ped)-15)
					local rtx,rty = getPointFromDistanceRotation(x,y,3,getPedRotation(ped)+15)
					local hitleft,hx,hy,hz,element,nx,ny,nz,material = processLineOfSight(x,y,z-0.5,ltx,lty,z,true,true,true,true,false,true,false,true,ped)
					local hitright,hx,hy,hz,element,nx,ny,nz,material = processLineOfSight(x,y,z-0.5,rtx,rty,z,true,true,true,true,false,true,false,true,ped)
					if hitleft then
						dxDrawLine3D(x,y,z,ltx,lty,z,tocolor(255,0,0))
						dxDrawLine3D(x,y,z,rtx,rty,z,tocolor(0,255,0))
						setPedRotation(ped,getPedRotation(ped)+5)
					elseif hitright then
						dxDrawLine3D(x,y,z,ltx,lty,z,tocolor(0,255,0))
						dxDrawLine3D(x,y,z,rtx,rty,z,tocolor(255,0,0))
						setPedRotation(ped,getPedRotation(ped)-5)
					else
						dxDrawLine3D(x,y,z,ltx,lty,z,tocolor(0,255,0))
						dxDrawLine3D(x,y,z,rtx,rty,z,tocolor(0,255,0))
						setPedRotation(ped,findRotation(x,y,next.x,next.y))
					end
				end
				]]
			else
				peds[ped] = nil
				destroyElement(ped)
			end
		end
	end
)

-- should be replaced with an event later on
function checkIfReady ()
	if getPedContactElement(localPlayer) then
		setTimer(createPeds,5000,1)
	else
		setTimer(checkIfReady,1000,1)
	end
end
checkIfReady()