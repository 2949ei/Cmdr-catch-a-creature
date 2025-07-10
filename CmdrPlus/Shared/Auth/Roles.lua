local ROLES = {
	["Owner"] = {
		["PermissionLevel"] = 999,
		["_IncludeRolesPermissions"] = {
			"Admin",
		},
		["Kickable"] = false,
		["Bannable"] = false,
	},

	["Admin"] = {
		["PermissionLevel"] = 100,
		["_IncludeRolesPermissions"] = {
			"Default",
		},
		["Kickable"] = true,
		["Bannable"] = false,
	},

	["Default"] = {
		["PermissionLevel"] = 1,
	},

	["Help"] = {
		["PermissionLevel"] = 0,
	}
}

function IncludeRolesPermissions(role, addto)
	if not role._IncludeRolesPermissions then
		return
	end

	for _, includerolepermission in role._IncludeRolesPermissions do
		local includerole = ROLES[includerolepermission]

		if not includerole then
			continue
		end

		IncludeRolesPermissions(includerole, role)

		for perm, value in includerole do
			if (addto or role)[perm] ~= nil then
				continue
			end

			(addto or role)[perm] = value
		end
	end
end

local Roles = {}

function Roles.GetRoles()
	for _, role in pairs(ROLES) do
		IncludeRolesPermissions(role)
	end

	for i, role in pairs(ROLES) do
		role._IncludeRolesPermissions = nil
		role.Alias = i
	end

	return ROLES
end

return Roles
