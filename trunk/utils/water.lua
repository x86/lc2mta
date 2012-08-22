--[[ conversion script (water.dat to lua)

local offsetX,offsetY,offsetZ = -335,0,0
local file = fileOpen("water.dat")
local content = fileRead(file,fileGetSize(file))
fileClose(file)

function cleanup (table)
	for i,v in ipairs (table) do
		if v then
			table[i] = tonumber(v)
		else
			table.remove(table,i)
		end
	end
end

for i,line in ipairs (split(content,"\n")) do
	if string.sub(line,1,1) ~= ";" and string.sub(line,1,1) ~= "*" then
		local args = split(line,",")
		cleanup(args)
		if #args == 5 then
			local Level = args[1]+offsetZ
			local xLeft = args[2]+offsetX
			local yBottom = args[3]+offsetY
			local xRight = args[4]+offsetX
			local yTop = args[5]+offsetY
			outputServerLog("createWater("..xLeft..","..yBottom..","..Level..","..xRight..","..yBottom..","..Level..","..xLeft..","..yTop..","..Level..","..xRight..","..yTop..","..Level..")")
		else
			outputServerLog("problem at line #"..i)
		end
	end
end
]]

local hidden = true
local water = {
{37,-2239,0,432,-2239,0,37,-84,0,432,-84,0},
{-320,119.81,0,415,119.81,0,-320,2239,0,415,2239,0},
{415,300,0,462,300,0,415,2239,0,462,2239,0},
{462,210,0,1904,210,0,462,2239,0,1904,2239,0},
{-427.85,128.746,0,-320,128.746,0,-427.85,2239,0,-320,2239,0},
{994,20,0,1145,20,0,994,210,0,1145,210,0},
{881.7,53.273,0,994,53.273,0,881.7,210,0,994,210,0},
{705.05,144.139,0,881.702,144.139,0,705.05,210,0,881.702,210,0},
{669.455,153.449,0,705.05,153.449,0,669.455,210,0,705.05,210,0},
{628.383,184.976,0,669.455,184.976,0,628.383,210,0,669.455,210,0},
{27,-84,0,432,-84,0,27,210,0,432,210,0},
{1105.5,-657.995,0,1145,-657.995,0,1105.5,20,0,1145,20,0},
{-1760.3,252.983,63.2,-1587.838,252.983,63.2,-1760.3,1054.988,63.2,-1587.838,1054.988,63.2},
{-1587.838,543.63,63.2,-1219.034,543.63,63.2,-1587.838,1054.988,63.2,-1219.034,1054.988,63.2},
{-1587.838,512.66,63.2,-1367.67,512.66,63.2,-1587.838,543.63,63.2,-1367.67,543.63,63.2},
{-1587.838,397.067,63.2,-1552.883,397.067,63.2,-1587.838,512.66,63.2,-1552.883,512.66,63.2},
{-1552.883,447.465,63.2,-1520.633,447.465,63.2,-1552.883,512.66,63.2,-1520.633,512.66,63.2},
{-1520.633,480.701,63.2,-1463.2,480.701,63.2,-1520.633,512.66,63.2,-1463.2,512.66,63.2},
{-1448.878,414.652,0,-1345.074,414.652,0,-1448.878,471.8,0,-1345.074,471.8,0},
{-1760.3,1054.988,0,-816.33,1054.988,0,-1760.3,2239,0,-816.33,2239,0},
{432,-2240,0,1905,-2240,0,432,-900,0,1905,-900,0},
{1145,-900,0,1904,-900,0,1145,210,0,1904,210,0},
{-2574,252.983,0,-1760.3,252.983,0,-2574,2239,0,-1760.3,2239,0},
{-2573.568,-2239,0,-1619.418,-2239,0,-2573.568,252.983,0,-1619.418,252.983,0},
{-1619.418,-2239,0,-816.33,-2239,0,-1619.418,-988.388,0,-816.33,-988.388,0},
{-1023.937,-988.388,0,-816.33,-988.388,0,-1023.937,-66.836,0,-816.33,-66.836,0},
{-1233.197,-244.724,0,-1023.937,-244.724,0,-1233.197,7.85,0,-1023.937,7.85,0},
{-1345.074,7.85,0,-1096.689,7.85,0,-1345.074,198.645,0,-1096.689,198.645,0},
{-1345.074,198.645,0,-1264.443,198.645,0,-1345.074,471.578,0,-1264.443,471.578,0},
{-1513.885,198.645,0,-1345.074,198.645,0,-1513.885,414.652,0,-1345.074,414.652,0},
{-816.33,-2239,0,-427.85,-2239,0,-816.33,2239,0,-427.85,2239,0},
{-427.85,-2239,0,37,-2239,0,-427.85,-1538.1,0,37,-1538.1,0}
}

addEventHandler("onClientResourceStart",root,
	function ()
		setWaterLevel(-6000)
	end
)

-- fix for tunnels
addEventHandler("onClientRender",root,
	function ()
		if getPedOccupiedVehicle(localPlayer) or getPedContactElement(localPlayer) then
			local x,y,z = getElementPosition(localPlayer)
			if not x then return end
			if hidden and z > -5 then
				hidden = false
				outputDebugString("Showing water")
				for i,w in ipairs (water) do
					createWater(unpack(w))
				end
			end
			if not hidden and z < -8 then
				hidden = true
				outputDebugString("Hiding water")
				for i,water in ipairs (getElementsByType("water")) do
					destroyElement(water)
				end
			end
		end
	end
)