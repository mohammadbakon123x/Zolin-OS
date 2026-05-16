-- Clock ModuleScript | @Sky_Attacker
local v1 = {};
local MainUI = script:FindFirstAncestor("ZolinOS") and script:FindFirstAncestorOfClass("ScreenGui");
local Runtime = MainUI:FindFirstChild("__Zolin"):FindFirstChild("Runtime");
local Clock = Runtime:FindFirstChild("Clock") or Instance.new("StringValue", Runtime);
Clock.Value = "03:00 AM";
Clock.Name = "Clock";
function v1.Update()
	local t = os.date("*t")
	local hour12 = t.hour % 12
	if hour12 == 0 then hour12 = 12 end
	local ampm = t.hour < 12 and "AM" or "PM"
	Clock.Value = string.format("%02d:%02d %s", hour12, t.min, ampm)
	for i, v in pairs(MainUI:GetDescendants()) do
		if v:IsA("TextButton") or v:IsA("TextLabel") then
			if v:GetAttribute("Clock") and v:GetAttribute("Clock") == true and v.Visible == true then
				v.Text = Clock.Value;
			end
		end
	end
end

function v1.Init()
	v1.Update();
	while true do
		task.wait(1);
		v1.Update();
	end
end
return v1;
