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
			order = 4,
			min = 1,
			max = 10,
			step = 1,
			get = function() return mod.db.profile.thickness end,
			set = function(info, v) mod.db.profile.thickness = v mod:UpdateLayout() end,
			disabled = false,
		}
	}
}

local defaults = {
    profile =  {
		status = true,
		thickness=2
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
	MiniMapLineFrame = CreateFrame("Frame", "MiniMapLineFrameFrame", Minimap)
	MiniMapLineFrame:SetSize(1,1)
	MiniMapLineFrame:SetPoint("CENTER")

	local Line = MiniMapLineFrame:CreateLine(nil, 'OVERLAY')
	MiniMapLineFrame.Line = Line
	Line:Show()
	Line:SetTexture('interface/buttons/white8x8')
	Line:SetGradientAlpha('HORIZONTAL', 1, 1, 1, 0.1, 1, 1, 1, 0.75)
	Line:SetThickness(mod.db.profile.thickness)
	Line:SetStartPoint('CENTER', Minimap, 0, 0)
	Line:SetEndPoint('CENTER', MiniMapLineFrame, 0, 0)

	if mod.db.profile.status then
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
    local r = rad(angle+90);
    return radius * cos(r) , radius *sin(r) ;
end

local function RotateTexture(angle)
	local deltax,deltay = CalculateDelta(angle,Minimap:GetWidth()/2)
	MiniMapLineFrame:SetPoint("CENTER", "Minimap", "CENTER", deltax, deltay);
	MiniMapLineFrame.Line:SetThickness(mod.db.profile.thickness)
end

function MiniMapLine:UpdateLayout()
  MiniMapLineFrame.timer = 0
  MiniMapLineFrame:SetScript("OnUpdate",function(self,elapsed)
    self.timer = self.timer + elapsed
    if self.timer > 0.1 then
	  local facing=GetPlayerFacing()
	  if facing == nil then
	    facing=0
	  end 
      RotateTexture(math.deg(facing))
    end
  end)
end
