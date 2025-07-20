local GroupService = game:GetService("GroupService")
local Roles: Roles | { [string]: RoleData } = {
	["Owner"] = {
		["Alias"] = "Owner",
		["PermissionLevel"] = math.huge,
		["Permissions"] = {
			"*",
		},
		["Checks"] = {
			["Kickable"] = false,
			["Bannable"] = false,
		},
	},

	["Default"] = {
		["Alias"] = "Default",
		["Permissions"] = {},
		["PermissionLevel"] = 0,
		["Checks"] = {
			["Kickable"] = true,
			["Bannable"] = true,
		},
	},
}

local Cache = {}
local Auth: Auth = {
	Roles = Roles,
	Players = {},
	Groups = {} :: { [number]: GroupData },
}

if game.CreatorType == Enum.CreatorType.User then
	Auth.Players[game.CreatorId] = "Owner"
end

function Auth.RegisterRoles(self: Auth, roles: Roles)
	for role, roledata in roles do
		roledata.Alias = role
		self.Roles[role] = roledata
	end
end

function Auth.RegisterRole(self: Auth, role: string, data: RoleData)
	data.Alias = role
	self.Roles[role] = data
end

function Auth.RegisterGroups(self: Auth, groups: { GroupData? })
	for _, group in groups do
		self.Groups[group.GroupId] = group
	end
end

function Auth.RegisterGroup(self: Auth, group: GroupData)
	self.Groups[group.GroupId] = group
end

function Auth.RegisterUsers(self: Auth, users: { [number | string]: string? })
	for user, role in users do
		self.Players[user] = role
	end
end

function Auth.RegisterUser(self: Auth, user: number | string, role: string)
	self.Players[user] = role
end

function Auth.IsPlayerPermitted(self: Auth, identifier: number | string | Player): RoleData
	if (typeof(identifier) == "number" or typeof(identifier) == "string") and self.Players[identifier] then
		return self.Players[identifier]
	elseif typeof(identifier) == "Instance" and identifier:IsA("Player") and self.Players[identifier.UserId] then
		return self.Players[identifier.UserId]
	end

	return self.Roles.Default
end

function Auth.IsRankPermitted(self: Auth, identifier: number | string): RoleData
	if typeof(identifier) ~= "number" then
		return self.Roles.Default
	end

	local now = DateTime.now().UnixTimestamp

	local success, groups, update = pcall(function()
		local Cached = Cache[identifier]
		if Cached and Cached.UnixTimestamp >= now then
			return Cached.groups, false
		end

		return GroupService:GetGroupsAsync(identifier), true
	end)

	if not success or not groups then
		return self.Roles.Default
	end

	if update then
		Cache[identifier] = {
			UnixTimestamp = now + 100,
			groups = groups,
		}
	end

	local ranks = {}
	local RegisteredGroups = self.Groups
	for _, group in pairs(groups) do
		if RegisteredGroups[group.Id] and RegisteredGroups[group.Id].Ranks[group.Rank] then
			local role = RegisteredGroups[group.Id].Ranks[group.Rank]
			table.insert(ranks, {
				Role = role,
				PermissionLevel = self:GetRolePermissionLevel(role),
			})
		end
	end

	table.sort(ranks, function(a, b)
		if a and b then
			return a.PermissionLevel > b.PermissionLevel
		end

		return a.PermissionLevel > 0
	end)

	if #ranks == 0 then
		return self.Roles.Default
	end

	return self.Roles[ranks[1].Role] or self.Roles.Default
end

function Auth.IsPlayerAuthorized(self: Auth, id: number | string, permission: string? | { string? }): boolean
	local player = Auth:IsPlayerPermitted(id)
	local rank = Auth:IsRankPermitted(id)

	local playerLevel = self:GetRolePermissionLevel(player)
	local rankLevel = self:GetRolePermissionLevel(rank)
	local defaultLevel = self:GetRolePermissionLevel(self.Roles.defaultLevel)

	if type(permission) == "string" then
		permission = { permission }
	end

	if playerLevel > rankLevel and permission then
		return self:HasRolePermissions(player, permission :: { string })
	elseif playerLevel < rankLevel and permission then
		return self:HasRolePermissions(rank, permission :: { string })
	elseif playerLevel > defaultLevel then
		return true
	elseif rankLevel > defaultLevel then
		return true
	end

	return false
end

function Auth.HasRolePermission(self: Auth, role: string | RoleData, permission: string?)
	if typeof(role) == "string" then
		role = self.Roles[role]
	end

	local HasStar = table.find((role :: RoleData).Permissions, "*")

	return HasStar ~= nil or table.find((role :: RoleData).Permissions, permission) ~= nil
end

function Auth.HasRolePermissions(self: Auth, role: string | RoleData, permissions: { string? })
	for _index, permission in permissions do
		if not self:HasRolePermission(role, permission) then
			return false
		end
	end

	return true
end

function Auth.GetRolePermissionLevel(self: Auth, role: string | RoleData): number
	if typeof(role) == "string" then
		role = self.Roles[role]
	end

	if not role then
		return 0
	end

	return (role :: RoleData).PermissionLevel
end

export type Auth = typeof(Auth) & {}

export type GroupData = {
	GroupId: number,
	Ranks: {
		[number]: string,
	},
}

export type RoleData = {
	Alias: string?,
	Permissions: { string? },
	PermissionLevel: number,
	Checks: {
		[string]: boolean,
	},
}

export type Roles = { [string]: RoleData? }

return Auth :: Auth
