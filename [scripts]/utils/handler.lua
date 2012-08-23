--[[
	Project:   LC2MTA (Liberty City mod for MTA:SA)
	Developer: x86dev <x86dev@gmx.com>
]]--


addEventHandler ( "onPlayerWasted", root,
	function ( )
		local player = source
		
		setTimer (
			function ( player )
				spawnPlayer ( player, 0, 0, 17 )
				setCameraTarget ( player, player )
				fadeCamera ( player, true )
			end
		, 1500, 1, source )
	end
)

addCommandHandler ( "kill",
	function ( player )
		killPed ( player ) -- doesnt work ?
		setElementHealth ( player, 0 )
	end
)

