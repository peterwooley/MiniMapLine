MiniMapLine = LibStub("AceAddon-3.0"):NewAddon("MiniMapLine", "AceConsole-3.0", "AceEvent-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("MiniMapLine")
local mod = MiniMapLine

local options = {
	type = "group",
	name = "MiniMapLine",
	args = {
		status = {
			type = "toggle",
			order = 1,
			name = L["Show Line"],
			width = "full",
			get = function()
				return mod.db.profile.status
			end,
			set = function(info, v)
				mod.db.profile.status = v
				if v == true then
					mod:UpdateLayout()
					MiniMapLineFrame:Show()
				else
				  MiniMapLineFrame:Hide()
				end
			end,
			disabled = false,
		},
		shape = {
			type = "select",
			name = L["Shape"],
			order = 2,
			values = { [0] = L["Circle"], [1] = L["Square"], },
			get = function() return mod.db.profile.shape end,
			set = function(info, v) mod.db.profile.shape = v mod:UpdateLayout() end,
		},
		lineAppearanceHeading = {
			type = "header",
			name = L["Line Appearance"],
			order = 3,
		},
		thickness = {
			type = "range",
			name = L["Thickness"],
			order = 3.1,
			min = 1,
			max = 10,
			step = 1,
			get = function() return mod.db.profile.thickness end,
			set = function(info, v) mod.db.profile.thickness = v mod:UpdateLayout() end,
			disabled = false,
			width = 1.3,
		},
		
		length = {
			type = "range",
			name = L["Length"],
			order = 3.2,
			min = 0.75,
			max = 1.25,
			step = 0.01,
			get = function() return mod.db.profile.length end,
			set = function(info, v) mod.db.profile.length = v mod:UpdateLayout() end,
			disabled = false,
			width = 1.3,
		},
		color = {
			type = "color",
			name = L["Color"],
			order = 3.3,
			get = function() return unpack(mod.db.profile.color) end,
			set = function(info, r, g, b, a) mod.db.profile.color = {r, g, b, a} mod:UpdateLayout() end,
			disabled = false,
			width = 1.3,
		},
		opacity = {
			type = "range",
			name = L["Opacity"],
			order = 3.4,
			min = 0.1,
			max = 1,
			step = 0.1,
			get = function() return mod.db.profile.opacity end,
			set = function(info, v) mod.db.profile.opacity = v mod:UpdateLayout() end,
			disabled = false,
			width = 1.3,
		},
		
	}
}

local defaults = {
    profile =  {
		status = true,
		thickness=2,
		shape = 0,
		length = 0.95,
		color = {1,1,1,1},
		opacity = 0.4
    },
}

function MiniMapLine:OnInitialize()
    -- Called when the addon is loaded
    mod.db = LibStub("AceDB-3.0"):New("MiniMapLineDB", defaults, true)
    LibStub("AceConfig-3.0"):RegisterOptionsTable("MiniMapLine", options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MiniMapLine", "MiniMapLine")
    self:RegisterChatCommand("mml", "ChatCommand")
    self:RegisterChatCommand("minimapline", "ChatCommand")
end


function MiniMapLine:ChatCommand(input)
    Settings.OpenToCategory("MiniMapLine")
end

function MiniMapLine:OnEnable()
	MiniMapLineFrame = CreateFrame("Frame", "MiniMapLineFrame", UIParent)
	MiniMapLineFrame:SetSize(1,1)
	MiniMapLineFrame:SetPoint("CENTER")

	-- track last facing to avoid redundant renders
	MiniMapLineFrame.lastFacing = nil

	local Line = MiniMapLineFrame:CreateLine("MiniMapLineFrameLine", 'OVERLAY')
	MiniMapLineFrame.Line = Line
	Line:SetStartPoint('CENTER', Minimap, 0, 0)
	Line:SetEndPoint('CENTER', MiniMapLineFrame, 0, 0)

	Minimap:HookScript("OnShow", function()
		if mod.db.profile.status then
			mod:UpdateLayout()
			MiniMapLineFrame:Show()
		end
	end)
	Minimap:HookScript("OnHide", function() MiniMapLineFrame:Hide() end)

	if mod.db.profile.status and Minimap:IsVisible() then
		mod:UpdateLayout()
		MiniMapLineFrame:Show()
	else
		MiniMapLineFrame:Hide()
	end
end

local s2 = math.sqrt(2);
local cos, sin, rad = math.cos, math.sin, math.rad;
local function CalculateCorner(angle)
    local r = rad(angle);
    return 0.5 + cos(r) / s2, 0.5 + sin(r) / s2;
end

local function CalculateDelta(angle,radius)
	local original = radius

	-- apply user length multiplier
	radius = radius * (mod.db.profile.length or 0.95)

	local r = rad(angle+90);

	-- If the minimap is square, compute the exact intersection distance with the square edge
	-- along the given angle. For an axis-aligned square centered at the origin, the distance
	-- from center to edge along a direction (cos(r), sin(r)) is scaledRadius / max(|cos|, |sin|).
	if mod.db.profile.shape == 1 then
		local cosr, sinr = math.abs(cos(r)), math.abs(sin(r))
		local maxv = math.max(cosr, sinr)
		if maxv > 0 then
			radius = radius / maxv
		end
	end

	local x = radius * cos(r)
	local y = radius * sin(r)

    return x , y 
end

local function RotateTexture(angle)
	local deltax,deltay = CalculateDelta(angle,Minimap:GetWidth()/2)
	MiniMapLineFrame:SetPoint("CENTER", Minimap, "CENTER", deltax, deltay);
	MiniMapLineFrame.Line:SetColorTexture(unpack(mod.db.profile.color))
	MiniMapLineFrame.Line:SetThickness(mod.db.profile.thickness)
	MiniMapLineFrame.Line:SetAlpha(mod.db.profile.opacity)
end

function MiniMapLine:UpdateLayout()
	if not MiniMapLineFrame then return end

	-- If the user has disabled the line, remove any OnUpdate handler and exit
	if not mod.db.profile.status then
		MiniMapLineFrame:SetScript("OnUpdate", nil)
		return
	end

	-- Perform an immediate, synchronous update so manual calls refresh the line right away
	local facing = GetPlayerFacing()
	if facing ~= nil then
		RotateTexture(math.deg(facing))
	end

	-- If an OnUpdate is already set, do nothing more
	-- This prevents multiple OnUpdate handlers from being set if UpdateLayout is called multiple times
	local existing = MiniMapLineFrame:GetScript("OnUpdate")
	if existing then return end

	MiniMapLineFrame:SetScript("OnUpdate", function(self, elapsed)
		local facing = GetPlayerFacing()

		if facing == nil then
			if self.Line:IsVisible() then self.Line:Hide() end
			self.lastFacing = nil
		else
			-- Only update when the facing actually changes
			if self.lastFacing == nil or facing ~= self.lastFacing then
				self.lastFacing = facing
				if not self.Line:IsVisible() then self.Line:Show() end
				RotateTexture(math.deg(facing))
			end
		end
	end)
end
