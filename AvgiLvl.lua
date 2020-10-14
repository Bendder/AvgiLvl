local start, max, starttime, startlevel

local f = CreateFrame("frame","AvgiLvl",UIParent,"BackdropTemplate")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)

function f:PLAYER_LOGIN()

	if not AvgiLvl_DB then AvgiLvl_DB = {} end
	if AvgiLvl_DB.bgShown == nil then AvgiLvl_DB.bgShown = 1 end
	if AvgiLvl_DB.scale == nil then AvgiLvl_DB.scale = 1 end

	self:CreateAvg_Frame()
	self:RestoreLayout("AvgiLvl")

	self:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
	self:RegisterEvent("PLAYER_TALENT_UPDATE")
	
	self:PLAYER_EQUIPMENT_CHANGED()
    self:PLAYER_TALENT_UPDATE()
	
	SLASH_AvgiLvl1 = "/avgilvl";
	SlashCmdList["AvgiLvl"] = AvgiLvl_SlashCommand;
	
	local ver = GetAddOnMetadata("AvgiLvl","Version") or '1.0'
	DEFAULT_CHAT_FRAME:AddMessage(string.format("|cFF99CC33%s|r [v|cFFDF2B2B%s|r] loaded:   /avgilvl", "AvgiLvl", ver or "1.0"))
	
	self:UnregisterEvent("PLAYER_LOGIN")
	self.PLAYER_LOGIN = nil
end

function AvgiLvl_SlashCommand(cmd)

	local a,b,c=strfind(cmd, "(%S+)"); --contiguous string of non-space characters
	
	if a then
		if c and c:lower() == "bg" then
			AvgiLvl:BackgroundToggle()
			return true
		elseif c and c:lower() == "reset" then
			DEFAULT_CHAT_FRAME:AddMessage("AvgiLvl: Frame position has been reset!");
			AvgiLvl:ClearAllPoints()
			AvgiLvl:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			return true
		elseif c and c:lower() == "scale" then
			if b then
				local scalenum = strsub(cmd, b+2)
				if scalenum and scalenum ~= "" and tonumber(scalenum) then
					AvgiLvl_DB.scale = tonumber(scalenum)
					AvgiLvl:SetScale(tonumber(scalenum))
					DEFAULT_CHAT_FRAME:AddMessage("AvgiLvl: scale has been set to ["..tonumber(scalenum).."]")
					return true
				end
			end
		end
	end

	DEFAULT_CHAT_FRAME:AddMessage("AvgiLvl");
	DEFAULT_CHAT_FRAME:AddMessage("/avgilvl reset - resets the frame position");
	DEFAULT_CHAT_FRAME:AddMessage("/avgilvl bg - toggles the background on/off");
	DEFAULT_CHAT_FRAME:AddMessage("/avgilvl scale # - Set the scale of the AvgiLvl frame")
end

function f:CreateAvg_Frame()

	f:SetWidth(100)
	f:SetHeight(27)
	f:SetMovable(true)
	f:SetClampedToScreen(true)
	
	f:SetScale(AvgiLvl_DB.scale)
	
	if AvgiLvl_DB.bgShown == 1 then
		f:SetBackdrop( {
			bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground";
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border";
			tile = true; tileSize = 32; edgeSize = 16;
			insets = { left = 5; right = 5; top = 5; bottom = 5; };
		} );
		--f:SetBackdropBorderColor(0.5, 0.5, 0.5);
		--f:SetBackdropColor(0.5, 0.5, 0.5, 0.6)
	else
		f:SetBackdrop(nil)
	end
	
	f:EnableMouse(true);
	
	local t = f:CreateTexture("$parentIcon", "ARTWORK")
	t:SetTexture("Interface\\AddOns\\AvgiLvl\\icon")
	t:SetWidth(16)
	t:SetHeight(16)
	t:SetPoint("TOPLEFT",5,-6)

	local g = f:CreateFontString("$parentText", "ARTWORK", "GameFontNormalSmall")
	g:SetJustifyH("LEFT")
	g:SetPoint("CENTER",8,0)
	g:SetText("iLvL")

	f:SetScript("OnMouseDown",function()
		if (IsShiftKeyDown()) then
			self.isMoving = true
			self:StartMoving();
	 	end
	end)
	f:SetScript("OnMouseUp",function()
		if( self.isMoving ) then

			self.isMoving = nil
			self:StopMovingOrSizing()

			f:SaveLayout(self:GetName());

		end
	end)
	f:SetScript("OnLeave",function()
		GameTooltip:Hide()
	end)

	f:SetScript("OnEnter",function()
	
		GameTooltip:SetOwner(self, "ANCHOR_NONE")
		GameTooltip:SetPoint(self:GetTipAnchor(self))
		GameTooltip:ClearLines()

		GameTooltip:AddLine("AvgiLvl")

		local overall, equipped, pvp = GetAverageItemLevel("player")
		GameTooltip:AddDoubleLine("Equipped:", equipped, nil,nil,nil, 1,1,1)
		GameTooltip:AddDoubleLine("Overall:", overall, nil,nil,nil, 1,1,1)
		--GameTooltip:AddDoubleLine("PvP:", pvp, nil,nil,nil, 1,1,1)
		
		GameTooltip:Show()
	end)
	
	
	f:Show();
end

function f:SaveLayout(frame)
	if type(frame) ~= "string" then return end
	if not _G[frame] then return end
	if not AvgiLvl_DB then AvgiLvl_DB = {} end
	
	local opt = AvgiLvl_DB[frame] or nil

	if not opt then
		AvgiLvl_DB[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = AvgiLvl_DB[frame]
		return
	end

	local point, relativeTo, relativePoint, xOfs, yOfs = _G[frame]:GetPoint()
	opt.point = point
	opt.relativePoint = relativePoint
	opt.xOfs = xOfs
	opt.yOfs = yOfs
end

function f:RestoreLayout(frame)
	if type(frame) ~= "string" then return end
	if not _G[frame] then return end
	if not AvgiLvl_DB then AvgiLvl_DB = {} end

	local opt = AvgiLvl_DB[frame] or nil

	if not opt then
		AvgiLvl_DB[frame] = {
			["point"] = "CENTER",
			["relativePoint"] = "CENTER",
			["xOfs"] = 0,
			["yOfs"] = 0,
		}
		opt = AvgiLvl_DB[frame]
	end

	_G[frame]:ClearAllPoints()
	_G[frame]:SetPoint(opt.point, UIParent, opt.relativePoint, opt.xOfs, opt.yOfs)
end



function f:BackgroundToggle()
	if not AvgiLvl_DB then AvgiLvl_DB = {} end
	if AvgiLvl_DB.bgShown == nil then AvgiLvl_DB.bgShown = 1 end
	
	if AvgiLvl_DB.bgShown == 0 then
		AvgiLvl_DB.bgShown = 1;
		DEFAULT_CHAT_FRAME:AddMessage("AvgiLvl: Background Shown");
	elseif AvgiLvl_DB.bgShown == 1 then
		AvgiLvl_DB.bgShown = 0;
		DEFAULT_CHAT_FRAME:AddMessage("AvgiLvl: Background Hidden");
	else
		AvgiLvl_DB.bgShown = 1
		DEFAULT_CHAT_FRAME:AddMessage("AvgiLvl: Background Shown");
	end

	--now change background
	if AvgiLvl_DB.bgShown == 1 then
		f:SetBackdrop( {
			bgFile = "Interface\\TutorialFrame\\TutorialFrameBackground";
			edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border";
			tile = true; tileSize = 32; edgeSize = 16;
			insets = { left = 5; right = 5; top = 5; bottom = 5; };
		} );
		f:SetBackdropBorderColor(0.5, 0.5, 0.5);
		f:SetBackdropColor(0.5, 0.5, 0.5, 0.6)
	else
		f:SetBackdrop(nil)
	end
	
end

function f:PLAYER_EQUIPMENT_CHANGED()
	local overall, equipped, pvp = GetAverageItemLevel("player")
	-- GetAverageItemLevel still returns a pvp value, but it is always the same as overall.
		
	getglobal("AvgiLvlText"):SetText(string.format("%i/%i", equipped,overall))
end

function f:PLAYER_TALENT_UPDATE()
	local overall, equipped, pvp = GetAverageItemLevel("player")
	-- GetAverageItemLevel still returns a pvp value, but it is always the same as overall.
	
	getglobal("AvgiLvlText"):SetText(string.format("%i/%i", equipped,overall))
end

function f:GetTipAnchor(frame)
	local x,y = frame:GetCenter()
	if not x or not y then return "TOPLEFT", "BOTTOMLEFT" end
	local hhalf = (x > UIParent:GetWidth()*2/3) and "RIGHT" or (x < UIParent:GetWidth()/3) and "LEFT" or ""
	local vhalf = (y > UIParent:GetHeight()/2) and "TOP" or "BOTTOM"
	return vhalf..hhalf, frame, (vhalf == "TOP" and "BOTTOM" or "TOP")..hhalf
end

if IsLoggedIn() then f:PLAYER_LOGIN() else f:RegisterEvent("PLAYER_LOGIN") end
