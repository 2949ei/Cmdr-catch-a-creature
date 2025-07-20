return function(registry)
	registry:RegisterHook("BeforeRun", function(context)
		if not context:ExecutorHasPermissions(context.Permissions) then
			return { line = "You don't have permission to run this command", color = Color3.fromRGB(255, 153, 153) }
		end
	end, math.huge)
end
