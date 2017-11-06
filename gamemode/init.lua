EMM = EMM or {}

EMM.server_includes = {}

EMM_GAMEMODE_DIRECTORY = "emm/gamemode/"

AddCSLuaFile "cl_init.lua"
AddCSLuaFile "emm.lua"

function EMM.RequireClientsideLuaDirectory(dir)
	dir = dir and string.TrimLeft(dir, "/") or ""

	local files, child_dirs = file.Find(EMM_GAMEMODE_DIRECTORY..dir.."/*", "LUA")

	for _, file in pairs(files) do
		if string.match(file, "cl.lua$") or string.match(file, "sh.lua$") then
			MsgN("requiring client-side include "..dir.."/"..file)
			AddCSLuaFile(EMM_GAMEMODE_DIRECTORY..dir.."/"..file)
		end
	end

	for _, child_dir in pairs(child_dirs) do
		EMM.RequireClientsideLuaDirectory(dir.."/"..child_dir)
	end
end
EMM.RequireClientsideLuaDirectory()

function EMM.Include(inc)
	if istable(inc) then
		for _, _inc in pairs(inc) do
			EMM.Include(_inc)
		end
	elseif isstring(inc) then
		local inc_path = EMM_GAMEMODE_DIRECTORY..inc
		local sv_inc_file = file.Find(inc_path..".sv.lua", "LUA")[1]
		local sh_inc_file = file.Find(inc_path..".sh.lua", "LUA")[1]

		if sv_inc_file or sh_inc_file then
			MsgN("including "..inc)
		else
			MsgN("could not find include "..inc)

			return
		end

		if sv_inc_file then
			include(inc_path..".sv.lua")
		end

		if sh_inc_file then
			include(inc_path..".sh.lua")
		end

		EMM.server_includes[inc] = true
	end
end

function EMM.AddResourceDirectory(dir)
	local files, child_dirs = file.Find(dir.."/*", "THIRDPARTY")

	for _, file in pairs(files) do
		resource.AddFile(dir.."/"..file)
	end

	for _, child_dir in pairs(child_dirs) do
		EMM.AddResourceDirectory(dir.."/"..child_dir)
	end
end

include "emm.lua"