debug.sethook(nil)

local ides = {"comnbtm.ide",                                  
"comntop.ide",                                   
"comroad.ide",                                   
"comse.ide",                                     
"comsw.ide",                                     
"generic.ide",                                   
"gta3.IDE",                                      
"indroads.ide",                                  
"industne.ide",                                  
"industnw.ide",                                  
"industse.ide",                                  
"industsw.ide",                                  
"landne.ide",                                    
"landsw.ide",                                    
"making.ide",                                    
"subroads.ide",                                  
"temppart.ide"
}

local ipls = {"comNbtm.ipl",                                   
"comNtop.ipl",                                   
"comroad.ipl",                                   
"comSE.ipl",                                     
"comSW.ipl",                                     
"cull.ipl",                                      
"indroads.ipl",                                  
"industNE.ipl",                                  
"industNW.ipl",                                  
"industSE.ipl",                                  
"industSW.ipl",                                  
"landne.ipl",                                    
"landsw.ipl",                                    
"making.ipl",                                    
"overview.ipl",                                  
"props.IPL",                                     
"subroads.ipl",                                  
"suburbne.ipl",                                  
"suburbsw.ipl",                                  
"temppart.ipl"
}     

function cleanup (table)
	for i,v in ipairs (table) do
		if not v then
			table.remove(table,i)
		elseif tonumber(v) then
			table[i] = tonumber(v)
		else
			table[i] = string.gsub(v," ","")
		end
	end
	return table
end

-- read ipls
local allObjects = {}
local currentType = false
local currentSubType = false
for i,ipl in ipairs (ipls) do
	local file = fileOpen("ipl/"..ipl)
	local content = fileRead(file,fileGetSize(file))
	local lines = split(content,"\n\r")
	for i,line in ipairs (lines) do
		local words = split(line,",")
		words = cleanup(words)
		if #words == 1 then
			if words[1] == "end" then
				currentType = false
				currentSubType = false
			else
				currentType = words[1]
			end
		end
		if currentType == "inst" then
			if #words > 1 then
				if not allObjects[tonumber(words[1])] then
					allObjects[tonumber(words[1])] = {}
				end
				table.insert(allObjects[tonumber(words[1])],{x=tonumber(words[3])-335,y=tonumber(words[4]),z=tonumber(words[5])})
			end
		end
	end
end

-- read ides
local nodeID = 0
local pedNodes = {}
local currentType = false
local currentSubType = false
for i,ide in ipairs (ides) do
	local file = fileOpen("ide/"..ide)
	local content = fileRead(file,fileGetSize(file))
	local lines = split(content,"\n\r")
	for i,line in ipairs (lines) do
		if #getElementsByType("ped") + #getElementsByType("vehicle") > 255 then return end
		local words = split(line,",")
		cleanup(words)
		if #words == 1 then
			if words[1] == "end" then
				currentType = false
				currentSubType = false
			else
				currentType = words[1]
			end
		end
		if currentType == "path" then
			if #words == 3 then
				currentObject = tonumber(words[2])
				currentSubType = words[1]
				pedNodes[currentObject] = {}
				nodeID = 0
			end
			if currentSubType == "ped" then
				if #words == 9 and words[1] ~= 0 then
					local object = allObjects[currentObject][1]
					local offsetx,offsety,offsetz = words[4]/16,words[5]/16,0 -- not sure about offsetz
					table.insert(pedNodes[currentObject],{id=nodeID,x=object.x+offsetx,y=object.y+offsety,z=object.z+offsetz,neighbor=tonumber(words[2])})
					nodeID = nodeID+1
				end
			end
			if currentSubType == "car" then
				if #words == 9 then
					for i,object in ipairs (allObjects[currentObject] or {}) do
						local offsetx,offsety,offsetz = words[4]*16,words[5]*16,0 -- not sure about offsetz
						--local vehicle = createVehicle(411,object.x+offsetx,object.y+offsety,object.z+offsetz)
						--createBlipAttachedTo(vehicle)
						--setElementFrozen(vehicle,true)
					end
				end
			end
		end
	end
end

if fileExists("pednodes.lua") then
	fileDelete("pednodes.lua")
end
local file = fileCreate("pednodes.lua")
fileWrite(file,"pednodes = {\r\n")
for model,content in pairs (pedNodes) do
	if #content ~= 0 then
		fileWrite(file,"	["..model.."] = {\r\n")
		for i,node in ipairs (content) do
			fileWrite(file,"		{")
			for k,v in pairs (node) do
				if k == "neighbor" then
					fileWrite(file,k.."="..v)
				else
					fileWrite(file,k.."="..v..",")
				end
			end
			if i == #content then
				fileWrite(file,"}\r\n")
			else
				fileWrite(file,"},\r\n")
			end
		end
		fileWrite(file,"	},\r\n")
	end
end
fileWrite(file,"}")
fileFlush(file)
fileClose(file)