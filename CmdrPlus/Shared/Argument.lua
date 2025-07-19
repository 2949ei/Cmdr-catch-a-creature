local Util = require(script.Parent.Util)

local function unescapeOperators(text)
	for _, operator in ipairs({ "%.", "%?", "%*", "%*%*" }) do
		text = text:gsub("\\" .. operator, operator:gsub("%%", ""))
	end

	return text
end

local Argument = {}
Argument.__index = Argument

function Argument.new(command, argumentDefinition, value)
	local self = {
		Command = command,
		Type = nil,
		Name = argumentDefinition.Name,
		Object = argumentDefinition,
		Required = argumentDefinition.Default == nil and argumentDefinition.Optional ~= true,
		Executor = command.Executor,
		RawValue = value,
		RawSegments = {},
		TransformedValues = {},
		Prefix = "",
		TextSegmentInProgress = "",
		RawSegmentsAreAutocomplete = false,
	}

	if type(argumentDefinition.Type) == "table" then
		self.Type = argumentDefinition.Type
	else
		local parsedType, parsedRawValue, prefix =
			Util.ParsePrefixedUnionType(command.Cmdr.Registry:GetTypeName(argumentDefinition.Type), value)

		self.Type = command.Dispatcher.Registry:GetType(parsedType)
		self.RawValue = parsedRawValue
		self.Prefix = prefix

		if self.Type == nil then
			error((`[Cmdr] {self.Name or "none"} has an unregistered type %q`):format(parsedType or "<none>"))
		end
	end

	setmetatable(self, Argument)

	self:Transform()

	return self
end

function Argument:GetDefaultAutocomplete()
	if self.Type.Autocomplete then
		local strings, options = self.Type.Autocomplete(self:TransformSegment(""))
		return strings, options or {}
	end

	return {}
end

function Argument:Transform()
	if #self.TransformedValues ~= 0 then
		return
	end

	local rawValue = self.RawValue
	if self.Type.ArgumentOperatorAliases then
		rawValue = self.Type.ArgumentOperatorAliases[rawValue] or rawValue
	end

	if rawValue == "." and self.Type.Default then
		rawValue = self.Type.Default(self.Executor) or ""
		self.RawSegmentsAreAutocomplete = true
	end

	if rawValue == "?" and self.Type.Autocomplete then
		local strings, options = self:GetDefaultAutocomplete()

		if not options.IsPartial and #strings > 0 then
			rawValue = strings[math.random(1, #strings)]
			self.RawSegmentsAreAutocomplete = true
		end
	end

	if self.Type.Listable and #self.RawValue > 0 then
		local randomMatch = rawValue:match("^%?(%d+)$")
		if randomMatch then
			local maxSize = tonumber(randomMatch)

			if maxSize and maxSize > 0 then
				local items = {}
				local remainingItems, options = self:GetDefaultAutocomplete()

				if not options.IsPartial and #remainingItems > 0 then
					for _ = 1, math.min(maxSize, #remainingItems) do
						table.insert(items, table.remove(remainingItems, math.random(1, #remainingItems)))
					end

					rawValue = table.concat(items, ",")
					self.RawSegmentsAreAutocomplete = true
				end
			end
		elseif rawValue == "*" or rawValue == "**" then
			local strings, options = self:GetDefaultAutocomplete()

			if not options.IsPartial and #strings > 0 then
				if rawValue == "**" and self.Type.Default then
					local defaultString = self.Type.Default(self.Executor) or ""

					for i, string in ipairs(strings) do
						if string == defaultString then
							table.remove(strings, i)
						end
					end
				end

				rawValue = table.concat(strings, ",")
				self.RawSegmentsAreAutocomplete = true
			end
		end

		rawValue = unescapeOperators(rawValue)

		local rawSegments = Util.SplitStringSimple(rawValue, ",")

		if #rawSegments == 0 then
			rawSegments = { "" }
		end

		if rawValue:sub(#rawValue, #rawValue) == "," then
			rawSegments[#rawSegments + 1] = "" -- makes auto complete tick over right after pressing ,
		end

		for i, rawSegment in ipairs(rawSegments) do
			self.RawSegments[i] = rawSegment
			self.TransformedValues[i] = { self:TransformSegment(rawSegment) }
		end

		self.TextSegmentInProgress = rawSegments[#rawSegments]
	else
		rawValue = unescapeOperators(rawValue)

		self.RawSegments[1] = unescapeOperators(rawValue)
		self.TransformedValues[1] = { self:TransformSegment(rawValue) }
		self.TextSegmentInProgress = self.RawValue
	end
end

function Argument:TransformSegment(rawSegment): any
	if self.Type.Transform then
		return self.Type.Transform(rawSegment, self.Executor)
	else
		return rawSegment
	end
end

function Argument:GetTransformedValue(segment: number): ...any
	return unpack(self.TransformedValues[segment])
end

function Argument:Validate(isFinal: boolean?): (boolean, string?)
	if self.RawValue == nil or #self.RawValue == 0 and self.Required == false then
		return true
	end

	if self.Required and (self.RawSegments[1] == nil or #self.RawSegments[1] == 0) then
		return false, "This argument is required."
	end

	if self.Type.Validate or self.Type.ValidateOnce then
		for i = 1, #self.TransformedValues do
			if self.Type.Validate then
				local valid, errorText = self.Type.Validate(self:GetTransformedValue(i))

				if not valid then
					return valid, errorText or "Invalid value"
				end
			end

			if isFinal and self.Type.ValidateOnce then
				local validOnce, errorTextOnce = self.Type.ValidateOnce(self:GetTransformedValue(i))

				if not validOnce then
					return validOnce, errorTextOnce
				end
			end
		end

		return true
	else
		return true
	end
end

function Argument:GetAutocomplete()
	if self.Type.Autocomplete then
		return self.Type.Autocomplete(self:GetTransformedValue(#self.TransformedValues))
	else
		return {}
	end
end

function Argument:ParseValue(i: number)
	if self.Type.Parse then
		return self.Type.Parse(self:GetTransformedValue(i))
	else
		return self:GetTransformedValue(i)
	end
end

function Argument:GetValue(): any
	if #self.RawValue == 0 and not self.Required and self.Object.Default ~= nil then
		return self.Object.Default
	end

	if not self.Type.Listable then
		return self:ParseValue(1)
	end

	local values = {}

	for i = 1, #self.TransformedValues do
		local parsedValue = self:ParseValue(i)

		if type(parsedValue) ~= "table" then
			error(`[Cmdr] Listable types must return a table from Parse {self.Type.Name}`)
		end

		for _, value in pairs(parsedValue) do
			values[value] = true -- Put them into a dictionary to ensure uniqueness
		end
	end

	local valueArray = {}

	for value in pairs(values) do
		valueArray[#valueArray + 1] = value
	end

	return valueArray
end

return Argument
