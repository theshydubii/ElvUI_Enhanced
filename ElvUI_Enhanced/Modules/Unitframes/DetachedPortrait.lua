local E, L, V, P, G = unpack(ElvUI)
local UFDP = E:NewModule("Enhanced_DetachedPortrait", "AceHook-3.0")
local UF = E:GetModule("UnitFrames")

local function PortraitPostUpdate(portrait)
	local frame = portrait:GetParent()
	if not frame then return end
	if not frame.unitframeType then
		frame = frame:GetParent()
	end
	if not frame or not frame.unitframeType then return end

	local db = E.db.enhanced.unitframe.portraitOverlay[frame.unitframeType]
	if db and frame.USE_PORTRAIT_OVERLAY then
		portrait:SetAlpha(db.portraitAlpha)
	end
end

local function Configure_Portrait(self, frame)
	if frame.unitframeType == "player" or frame.unitframeType == "target" then
		local db = E.db.enhanced.unitframe.detachPortrait[frame.unitframeType]
		local overlayDB = E.db.enhanced.unitframe.portraitOverlay[frame.unitframeType]

		frame.PORTRAIT_DETACHED = frame.USE_PORTRAIT and db.enable and not frame.USE_PORTRAIT_OVERLAY
		frame.PORTRAIT_WIDTH = (frame.USE_PORTRAIT_OVERLAY or frame.PORTRAIT_DETACHED or not frame.USE_PORTRAIT) and 0 or frame.db.portrait.width
		frame.CLASSBAR_WIDTH = frame.UNIT_WIDTH - (frame.BORDER + frame.SPACING) * 2 - frame.PORTRAIT_WIDTH - frame.POWERBAR_OFFSET

		if frame.USE_PORTRAIT then
			local portrait = frame.Portrait
			if not self:IsHooked(portrait, "PostUpdate") then
				self:SecureHook(portrait, "PostUpdate", PortraitPostUpdate)
			end

			if frame.PORTRAIT_DETACHED then
				if not portrait.Holder or (portrait.Holder and not portrait.Holder.mover) then
					portrait.Holder = CreateFrame("Frame", nil, UIParent)
					portrait.Holder:Size(db.width, db.height)

					if frame.ORIENTATION == "LEFT" then
						portrait.Holder:Point("RIGHT", frame, "LEFT", -frame.BORDER, 0)
					elseif frame.ORIENTATION == "RIGHT" then
						portrait.Holder:Point("LEFT", frame, "RIGHT", frame.BORDER, 0)
					end

					portrait:SetInside(portrait.Holder)
					portrait.backdrop:SetOutside(portrait)

					if frame.unitframeType == "player" then
						E:CreateMover(portrait.Holder, "PlayerPortraitMover", L["Player Portrait"], nil, nil, nil, "ALL,SOLO")
					elseif frame.unitframeType == "target" then
						E:CreateMover(portrait.Holder, "TargetPortraitMover", L["Target Portrait"], nil, nil, nil, "ALL,SOLO")
					end
				else
					portrait.Holder:Size(db.width, db.height)
					portrait:SetInside(portrait.Holder)
					portrait.backdrop:SetOutside(portrait)
					E:EnableMover(portrait.Holder.mover:GetName())
				end
			end

			if not frame.PORTRAIT_DETACHED and portrait.Holder and portrait.Holder.mover then
				E:DisableMover(portrait.Holder.mover:GetName())
			end

			self:Configure_HealthBar(frame)
			self:Configure_Power(frame)

			if frame.USE_PORTRAIT_OVERLAY then
				portrait:SetAlpha(overlayDB.portraitAlpha)
				if overlayDB.higherPortrait then
					if not frame.Health.HigherPortrait then
						frame.Health.HigherPortrait = CreateFrame("Frame", nil, frame.Health)
						frame.Health.HigherPortrait:SetAllPoints(frame.Health)
					end
					frame.Health.HigherPortrait:SetFrameLevel(frame.Health:GetFrameLevel() + 4)
					portrait:ClearAllPoints()
					portrait:SetAllPoints(frame.Health.HigherPortrait)
					if frame.db.portrait.style == "3D" then
						portrait:SetFrameLevel(frame.Health.HigherPortrait:GetFrameLevel())
					end
				end
			end
		end
	end
end

function UFDP:ToggleState(unit)
	local playerOverlay = E.db.enhanced.unitframe.portraitOverlay.player
	local targetOverlay = E.db.enhanced.unitframe.portraitOverlay.target
	local enabled = E.db.enhanced.unitframe.detachPortrait.player.enable or E.db.enhanced.unitframe.detachPortrait.target.enable
		or playerOverlay.higherPortrait or targetOverlay.higherPortrait
		or playerOverlay.portraitAlpha ~= 0.35 or targetOverlay.portraitAlpha ~= 0.35
	if enabled then
		if not self:IsHooked(UF, "Configure_Portrait") then
			self:SecureHook(UF, "Configure_Portrait", Configure_Portrait)
		end

		if unit then
			UF:CreateAndUpdateUF(unit)
		end
	else
		UF:CreateAndUpdateUF(unit)
		self:Unhook(UF, "Configure_Portrait")
	end
end

function UFDP:Initialize()
	if not E.private.unitframe.enable then return end
	local playerOverlay = E.db.enhanced.unitframe.portraitOverlay.player
	local targetOverlay = E.db.enhanced.unitframe.portraitOverlay.target
	if not (E.db.enhanced.unitframe.detachPortrait.player.enable or E.db.enhanced.unitframe.detachPortrait.target.enable
		or playerOverlay.higherPortrait or targetOverlay.higherPortrait
		or playerOverlay.portraitAlpha ~= 0.35 or targetOverlay.portraitAlpha ~= 0.35) then return end

	self:ToggleState()
end

local function InitializeCallback()
	UFDP:Initialize()
end

E:RegisterModule(UFDP:GetName(), InitializeCallback)