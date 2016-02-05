GateActions("Arithmetic")
GateActions["DeltaNeb"] = {
	name = "Delta2",
	inputs = { "A","Multiplier","TargetValue" },
	outputs = { "Positive", "Negative" },
	output = function(gate, A,Multiplier,Target)
		gate.PrevValue = gate.PrevValue or 0
		if Multiplier == 0 then Multiplier = 6 end
		local temp = A - Target
		local delta = temp + (temp - gate.PrevValue) * Multiplier
		gate.PrevValue = temp
		return delta, -delta
	end,
	reset = function(gate)
		gate.PrevValue = 0
	end,
	label = function(Out, A,Multiplier,Target)
		return "("..Target.."-"..A..") + $("..Target.."-"..A..")*"..Multiplier.. " = " .. Out.Positive
	end
}