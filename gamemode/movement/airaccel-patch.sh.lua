AiraccelPatchService = AiraccelPatchService or {}

function AiraccelPatchService.SetMoveType(ply, move)
	local z_vel = move:GetVelocity().z

	if
		z_vel > 0 and
		z_vel < 140 and
		ply:GetMoveType() == MOVETYPE_WALK
	then
		ply:SetMoveType(MOVETYPE_LADDER)
	end
end
hook.Add("SetupMove", "AiraccelPatchService.SetMoveType",AiraccelPatchService.SetMoveType)


function AiraccelPatchService.RemoveLadderSound(sound)
	if IsValid(sound.Entity) then
		local z_vel = sound.Entity:GetVelocity().z

		if
			z_vel ~= 200 and
			z_vel ~= -200 and
			string.StartWith(sound.SoundName, "player/footsteps/ladder")
		then
			  return false
		end
	end
end
hook.Add("EntityEmitSound", "AiraccelPatchService.RemoveLadderSound", AiraccelPatchService.RemoveLadderSound)