--[[
	Project:   LC2MTA (Liberty City mod for MTA:SA)
	Developer: x86dev <x86dev@gmx.com>
]]--


addEventHandler ( "onClientResourceStart", resourceRoot,
	function ( )
		local x, y, z = getElementPosition ( localPlayer )

		setCloudsEnabled ( false )
		setBlurLevel ( 0 )
		setBirdsEnabled ( false )
		setJetpackMaxHeight ( 9001 )
		setAircraftMaxHeight ( 9001 )
		setHeatHaze ( 0 )
		setGameSpeed ( 1 )
		setGravity ( 0.008 )
		setCameraTarget ( localPlayer )
		showPlayerHudComponent ( "radar", true )
		showPlayerHudComponent ( "vehicle_name", false )
		showPlayerHudComponent ( "area_name", false )

		-- change our pos, so we can remove the SA map
		setElementFrozen ( localPlayer, true )
		setElementPosition ( localPlayer, 6000, 6000, 100 )

		-- Remove all world models
		for i = 550, 20000 do
			removeWorldModel ( i, 10000, 0, 0, 0 )
		end

		-- Turn off occlusions
		setOcclusionsEnabled ( false )
		
		-- change it back
		setElementFrozen ( localPlayer, false )
		setElementPosition ( localPlayer, x, y, z + 20 )
		fadeCamera ( true )
		
		-- Does the player have a bad videocard ?
		local videoRam = tonumber ( dxGetStatus ( ) [ "VideoCardRAM" ] )
		if videoRam then
			if videoRam < 512 then
				outputChatBox ( "WARNING: As I can see your videocard RAM is lower than " .. videoRam .. " MB, this mod will lag on such old cards.", 255, 0, 0 )
			end
		end
		
		-- Enough streaming memory ?
		local streamingRam = tonumber ( dxGetStatus ( ) [ "SettingStreamingVideoMemoryForGTA" ] )
		if streamingRam then
			if streamingRam < 128 then
				outputChatBox ( "WARNING: As I can see your streaming RAM is lower than " .. videoRam .. " MB, note that you'll get lag.", 255, 0, 0 )
			end
		end
		
		-- Help (Remove after RELEASE)
		-- outputChatBox ( "Use /debug to debug (you could also press F2 to show all streamed in objects, and F3 to see ghost objects)" )
		
		-- realtime clock (Remove after RELEASE)
		local tRealTime =  getRealTime ( )
		setTime ( tRealTime.hour, tRealTime.minute )
		setMinuteDuration ( 60000 )
	end
)

-- Download check
addEventHandler ( "onClientResourceStart", root,
	function ( resource )
		if getResourceName ( resource ) == "lc" or getResourceName ( resource ) == "utils" then
			-- Load the object streamer!
			checkTransfer ( )
		end
	end
)

function checkTransfer ( )
	if isTransferBoxActive ( ) then
		setElementData ( localPlayer, "doneDownloading", false )
		setTimer ( checkTransfer, 2000, 1 )
	else
		-- We are done downloading !
		setElementData ( localPlayer, "doneDownloading", true )
		triggerEvent ( "onClientDoneDownloading", root, true )
	end
end


--[[
	Debug shit
]]
local screenWidth, screenHeight = guiGetScreenSize ( )
local isDebugging  = false
local doWantObject = false
local doWantGhosts = false

addCommandHandler ( "debug",
	function ( )
		if isDebugging then
			outputChatBox ( "You have turned DEBUG mode _OFF_", 0, 255, 0 )
			
			-- Hide other debug stuff
			doWantObject = false
			doWantGhosts = false
		else
			outputChatBox ( "You have turned DEBUG mode _ON_", 0, 255, 0 )
		end

		isDebugging = not isDebugging
		setElementData ( localPlayer, "isDebugging", isDebugging )
	end
)


-- No damage pls
addCommandHandler ( "god",
	function ( )
		if isDebugging then
			addEventHandler ( "onClientPlayerDamage", localPlayer, cancelEvent )
			outputChatBox ( "* Protection enabled!", 0, 255, 0, false )
		else
			outputChatBox ( "* Do /debug first!", 255, 0, 0, false )
		end
	end
)


addEventHandler ( "onClientPreRender", root,
	function ( fTimeSlice )
		if isDebugging then
			-- Do we want to show all custom models ?
			if doWantObject then
				for _, object in ipairs ( getElementsByType ( "object", root, true ) ) do
					if getElementData ( object, "customModel" ) then
						local x, y, z      = getElementPosition ( object )
						local textX, textY = getScreenFromWorldPosition ( x, y, z, 10, false )
						local objString = tostring ( getElementData ( object, "dffModel" ) ) .. "[#" .. tostring ( getElementModel ( object ) ) .. "]"
						
						if textX and textY then
							dxDrawText ( objString, textX, textY, screenWidth, screenHeight, tocolor ( 255, 255, 255, 255 ), 1, "default" )
							dxDrawLine3D ( x, y, 0, x, y, 50, tocolor ( 255, 0, 0, 255 ), 3, false )
						end
					end
				end
			end
			
			-- Ghost objects tag
			if doWantGhosts then
				for _, object in ipairs ( getElementsByType ( "object", root, true ) ) do
					if not getElementData ( object, "customModel" ) then
						local x, y, z      = getElementPosition ( object )
						local textX, textY = getScreenFromWorldPosition ( x, y, z, 10, false )
						local objString = tostring ( getElementData ( object, "dffModel" ) ) .. "[#" .. tostring ( getElementModel ( object ) ) .. "]"
							
						if textX and textY then
							dxDrawText ( objString, textX, textY, screenWidth, screenHeight, tocolor ( 255, 255, 255, 255 ), 1, "default" )
							dxDrawLine3D ( x, y, 0, x, y, 50, tocolor ( 255, 0, 0, 255 ), 3, false )
						end
					end
				end
			end
		
			-- "Walking on" debug information
			local object = getPedContactElement ( localPlayer )
			if object then
				if getElementType ( object ) == "object" then
					local objString = "You are walking on: " .. tostring ( getElementData ( object, "dffModel" ) ) .. "[#" .. tostring ( getElementModel ( object ) ) .. "]"
					dxDrawText ( objString, screenWidth-350, screenHeight-60, screenWidth, screenHeight, tocolor ( 255, 255, 255, 255 ), 1, "default" )
				end
			end
		end
	end
)


-- Show all "custom" objects
bindKey ( "F2", "down",
	function ( )
		if isDebugging then
			doWantObject = not doWantObject
			outputChatBox ( "Custom objects tags are now " .. IfElse ( doWantObject, "shown", "hidden" ) .. "!" )
		end
	end
)


-- Show all objects without custom DFF or TXD (ghosts)
bindKey ( "F3", "down",
	function ( )
		if isDebugging then
			doWantGhosts = not doWantGhosts
			outputChatBox ( "Ghost objects tags are now " .. IfElse ( doWantGhosts, "shown", "hidden" ) .. "!" )
		end
	end
)


--[[
	Functions
]]

-- By Neon
function IfElse(condition, trueReturn, falseReturn)
    if (condition) then return trueReturn
    else return falseReturn end
end
