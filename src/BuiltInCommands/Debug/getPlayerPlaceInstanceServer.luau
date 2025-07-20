local TeleportService = game:GetService("TeleportService")

return function(_, playerId, format)
	format = format or "PlaceIdJobId"

	local ok, _, errorText, placeId, jobId = pcall(function()
		return TeleportService:GetPlayerPlaceInstanceAsync(playerId)
	end)

	if not ok or (errorText and #errorText > 0) then
		if format == "PlaceIdJobId" then
			return { line = "0" .. " -", color = nil }
		elseif format == "PlaceId" then
			return { line = "0", color = nil }
		elseif format == "JobId" then
			return { line = "-", color = nil }
		end
	end

	if format == "PlaceIdJobId" then
		return { line = placeId .. " " .. jobId, color = nil }
	elseif format == "PlaceId" then
		return { line = tostring(placeId), color = nil }
	elseif format == "JobId" then
		return { line = tostring(jobId), color = nil }
	end
end
