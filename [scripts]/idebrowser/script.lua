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
local pednodeID = 0
local carnodeID = 0
local pedNodes = {}
local carNodes = {}
local currentType = false
local currentSubType = false
for i,ide in ipairs (ides) do
	local file = fileOpen("ide/"..ide)
	local content = fileRead(file,fileGetSize(file))
	local lines = split(content,"\n\r")
	for i,line in ipairs (lines) do
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
				pednodeID = 0
				carnodeID = 0
			end
			if currentSubType == "ped" then
				if #words == 9 and words[1] ~= 0 then
					local object = allObjects[currentObject][1]
					local offsetx,offsety,offsetz = words[4]/16,words[5]/16,0 -- not sure about offsetz
					table.insert(pedNodes[currentObject],{id=pednodeID,x=object.x+offsetx,y=object.y+offsety,z=object.z+offsetz,neighbor=tonumber(words[2])})
					pednodeID = pednodeID+1
				end
			end
			if currentSubType == "car" then
				if #words == 9 and words[1] ~= 0 and allObjects[currentObject] then
					local object = allObjects[currentObject][1]
					local offsetx,offsety,offsetz = words[4]/16,words[5]/16,0 -- not sure about offsetz
					local id = tostring(currentObject)..tostring(carnodeID)
					if words[2] == -1 then
						carNodes[id] = {id=id,x=object.x+offsetx,y=object.y+offsety,z=object.z+offsetz,neighbor=false,closest=false,lanes="{"..words[8]..","..words[9].."}"}
					else
						carNodes[id] = {id=id,x=object.x+offsetx,y=object.y+offsety,z=object.z+offsetz,neighbor=tostring(currentObject)..tostring(words[2]),closest=false,lanes="{"..words[8]..","..words[9].."}"}
					end
					carnodeID = carnodeID+1
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
					fileWrite(file,k.."="..tostring(v))
				else
					fileWrite(file,k.."="..tostring(v)..",")
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


for id,node in pairs (carNodes) do
	local distances = {}
	for checkid,checknode in pairs (carNodes) do
		if checkid ~= id and checkid ~= node.neighbor then
			local distance = getDistanceBetweenPoints2D(node.x,node.y,checknode.x,checknode.y)
			table.insert(distances,{id=checknode.id,distance=distance})
		end
	end
	table.sort(distances,function (a,b) return a.distance < b.distance end)
	node.closest = "{"..distances[1].id..","..distances[2].id.."}"
end				
if fileExists("carnodes.lua") then
	fileDelete("carnodes.lua")
end
local file = fileCreate("carnodes.lua")
fileWrite(file,"carnodes = {\r\n")
for id,node in pairs (carNodes) do
	fileWrite(file,"	["..id.."] = {")
	for k,v in pairs (node) do
		if k == "closest" then
			fileWrite(file,k.."="..tostring(v))
		else
			fileWrite(file,k.."="..tostring(v)..",")
		end
	end
	fileWrite(file,"},\r\n")
end
fileWrite(file,"}")
fileFlush(file)
fileClose(file)