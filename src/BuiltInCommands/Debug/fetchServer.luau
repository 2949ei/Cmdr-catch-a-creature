local HttpService = game:GetService("HttpService")

return function(_, url)
	return { line = HttpService:GetAsync(url), color = nil }
end
