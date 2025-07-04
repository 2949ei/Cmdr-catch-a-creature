local ROLES = {
	["Owner"] = {
		["_IncludeRolesPermissions"] = {
			"Admin",
		},
		["Kickable"] = false,
		["Bannable"] = false,
	},

	["Admin"] = {
		["_IncludeRolesPermissions"] = {
			"Default",
		},
		["Kickable"] = true,
		["Bannable"] = false,
	},

	["Default"] = {
		["DefaultAdmin"] = true,
		["DefaultDebug"] = true,
		["DefaultUtil"] = true,
		["Help"] = true, --dont remove
		["UserAlias"] = true, --dont remove
	},
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
	for i, role in pairs(ROLES) do
		IncludeRolesPermissions(role)
	end

	for i, role in pairs(ROLES) do
		role._IncludeRolesPermissions = nil
		role.Alias = i
	end

	return ROLES
end

return Roles
