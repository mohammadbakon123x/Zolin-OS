-- CooldownManager.lua
local CooldownManager = {}
local cooldowns = {}

function CooldownManager.CanFire(key, cooldownTime)
	local last = cooldowns[key]
	local now = tick()
	if not last or now - last >= cooldownTime then
		cooldowns[key] = now
		return true
	end
	return false
end

function CooldownManager.Reset(key)
	cooldowns[key] = nil
end

return CooldownManager