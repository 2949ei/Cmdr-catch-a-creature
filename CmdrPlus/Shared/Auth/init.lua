local Players = game:GetService("Players")
local GroupService = game:GetService("GroupService")
local ROLES = require(script.Roles).GetRoles()

local PLAYERS = nil
local GROUPS = nil

local Auth = {
	Roles = ROLES
}
local Cache = {}

function Auth.IsPlayerPermitted(identifier)
	if typeof(identifier) == "number" then
		return PLAYERS[identifier]
	elseif typeof(identifier) == "string" then
		return PLAYERS[identifier]
	end

	return false
end

function Auth.IsRankPermitted(identifier)
	if typeof(identifier) ~= "number" then
		return false
	end
	local now = DateTime.now().UnixTimestamp

	local success, groups, update = pcall(function()
		local Cached = Cache[identifier]
		if Cached and Cached.UnixTimestamp >= now then
			return Cached.groups, false
		end

		return GroupService:GetGroupsAsync(identifier), true
	end)

	if groups then
		if update then
			Cache[identifier] = {
				UnixTimestamp = now + 100,
				groups = groups,
			}
		end

		local ranks = {}
		for _, main_group in pairs(groups) do
			if GROUPS[main_group.Id] then
				if GROUPS[main_group.Id].Ranks[main_group.Rank] then
					local role = GROUPS[main_group.Id].Ranks[main_group.Rank]
					table.insert(ranks, {
						Role = role,
						PermissionCount = Auth.PermissionCount(role)
					})
				end
			end
		end

		table.sort(ranks, function(a, b)
			if a and b then  
				return a.PermissionCount > b.PermissionCount
			end

			return a.PermissionCount > 0
		end)

		if #ranks == 0 then
			return false
		end

		return ranks[1].Role
	end

	return false
end

function Auth.IsAuthorized(id, Permission)
	local player = Auth.IsPlayerPermitted(id)
	local rank = Auth.IsRankPermitted(id)

	if Permission and player then
		return Auth.GetRolePermission(player, Permission)
	elseif Permission and rank then
		return Auth.GetRolePermission(rank, Permission)
	elseif player then
		return player
	elseif rank then
		return rank
	else
		return false
	end
end

function Auth.IsAuthorizedLevel(id, role)
	local permissionlevel = Auth.GetRolePermissionLevel(role)
	local player = Auth.IsPlayerPermitted(id)
	local rank = Auth.IsRankPermitted(id)

	local playerlevel = Auth.GetRolePermissionLevel(player)
	local rankevel = Auth.GetRolePermissionLevel(rank)

	if playerlevel <= permissionlevel then
		return true
	elseif rankevel <= permissionlevel then
		return true
	end

	return false
end

function Auth.GetRolePermission(role, Permission)
	if typeof(role) == "table" then
		role = role.Alias
	end

	return Auth.Roles[role][Permission]
end

function Auth.GetRolePermissionLevel(role)
	if typeof(role) == "table" then
		role = role.Alias
	end

	
	if typeof(role) ~= "string" then
		return 1
	end
	
	if Auth.Roles[role] and Auth.Roles[role].PermissionLevel then
		return Auth.Roles[role].PermissionLevel
	else
		return 1
	end
end

function Auth.PermissionCount(role)
	if typeof(role) == "table" then
		role = role.Alias
	end
	
	role = ROLES[role]

	if not role then
		return 0
	end

	local permissionCount = 0

	for _, permission in pairs(role) do
		if type(permission) == "boolean" and permission then
			permissionCount = permissionCount + 1
		end
	end

	return permissionCount
end

Players.PlayerRemoving:Connect(function(Player)
	Cache[Player.UserId] = nil
end)

return function(Cmdr)
	local Settings = Cmdr.Settings

	PLAYERS = Settings.UserRanks
	GROUPS = Settings.GroupRanks

	return Auth
end