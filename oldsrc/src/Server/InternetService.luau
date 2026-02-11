local HttpService = game:GetService("HttpService")

local InternetService = {}

function InternetService.HandleRequest(player, method, url, headers, body)
	-- Basic security: We could whitelist domains here if needed.
	-- For a kernel service, we provide the raw capability.

	local success, result = pcall(function()
		return HttpService:RequestAsync({
			Url = url,
			Method = method,
			Headers = headers,
			Body = body,
		})
	end)

	if not success then
		warn("[InternetService] Request failed:", result)
		return {
			Success = false,
			StatusCode = 500,
			StatusMessage = "Internal Server Error",
			Body = tostring(result),
		}
	end

	return result -- Returns the response dictionary (Body, Success, StatusCode, etc.)
end

return InternetService
