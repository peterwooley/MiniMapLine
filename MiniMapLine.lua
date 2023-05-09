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
				  MiniMapLineFrame:Show()
				else
				  MiniMapLineFrame:Hide()
				end
			end,
			disabled = false,
		},
		thickness = {
			type = "range",
			name = L["Thickness"],
			order = 2,
			min = 1,
			max = 10,
			step = 1,
			get = function() return mod.db.profile.thickness end,
			set = function(info, v) mod.db.profile.thickness = v mod:UpdateLayout() end,
			disabled = false,
		},
		opacity = {
			type = "range",
			name = L["Opacity"],
			order = 3,
			min = 0.1,
			max = 1,
			step = 0.1,
			get = function() return mod.db.profile.opacity end,
			set = function(info, v) mod.db.profile.opacity = v mod:UpdateLayout() end,
			disabled = false,
		},
		shape = {
			type = "select",
			name = L["Shape"],
			order = 4,
			values = { [0] = L["Circle"], [1] = L["Square"], },
			get = function() return mod.db.profile.shape end,
			set = function(info, v) mod.db.profile.shape = v mod:UpdateLayout() end,
		}
	}
}

local defaults = {
    profile =  {
		status = true,
		thickness=2,
		shape = 0,
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
    InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
	InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
end

function MiniMapLine:OnEnable()
	MiniMapLineFrame = CreateFrame("Frame", "MiniMapLineFrame", UIParent)
	MiniMapLineFrame:SetSize(1,1)
	MiniMapLineFrame:SetPoint("CENTER")

	local Line = MiniMapLineFrame:CreateLine("MiniMapLineFrameLine", 'OVERLAY')
	MiniMapLineFrame.Line = Line
	Line:Show()
	Line:SetTexture('interface/buttons/white8x8')
	Line:SetAlpha(mod.db.profile.opacity)
	Line:SetThickness(mod.db.profile.thickness)
	Line:SetStartPoint('CENTER', Minimap, 0, 0)
	Line:SetEndPoint('CENTER', MiniMapLineFrame, 0, 0)

	Minimap:HookScript("OnShow", function()
		if mod.db.profile.status then
			MiniMapLineFrame:Show()
			mod:UpdateLayout()
		end
	end)
	Minimap:HookScript("OnHide", function() MiniMapLineFrame:Hide() end)


	if mod.db.profile.status and Minimap:IsVisible() then
		MiniMapLineFrame:Show()
		mod:UpdateLayout()
	end
end

local s2 = sqrt(2);
local cos, sin, rad = math.cos, math.sin, math.rad;
local function CalculateCorner(angle)
    local r = rad(angle);
    return 0.5 + cos(r) / s2, 0.5 + sin(r) / s2;
end

local function CalculateDelta(angle,radius)
	original = radius

	if mod.db.profile.shape == 1 then
		-- Square map line
		edge = angle % 90 / 45;
		if(edge > 1) then edge=1-(edge-1) end
		radius = radius + ((sqrt(2*radius^2)-radius) * edge)
	end

    local r = rad(angle+90);

	local x = radius * cos(r)
	local y = radius * sin(r)

	--print("Radius", original)
	--print(x)
	if (x >= original) then x = original end
	if (x <= -original) then x = -original end
	--print(x)

	--print(y)
	if (y >= original) then y = original end
	if (y <= -original) then y = -original end
	--print(x)

    return x , y 
end

local function RotateTexture(angle)
	local deltax,deltay = CalculateDelta(angle,Minimap:GetWidth()/2)
	MiniMapLineFrame:SetPoint("CENTER", Minimap, "CENTER", deltax, deltay);
	MiniMapLineFrame.Line:SetThickness(mod.db.profile.thickness)
	MiniMapLineFrame.Line:SetAlpha(mod.db.profile.opacity)
end

function MiniMapLine:UpdateLayout()
  MiniMapLineFrame.timer = 0
  MiniMapLineFrame:SetScript("OnUpdate",function(self,elapsed)
    self.timer = self.timer + elapsed
    if self.timer > 0.1 then
	  local facing=GetPlayerFacing()
	  if facing == nil then
		self.Line:Hide()
	  else
		if not self.Line:IsVisible() then self.Line:Show() end
	    RotateTexture(math.deg(facing))
	  end 
    end
  end)
end
