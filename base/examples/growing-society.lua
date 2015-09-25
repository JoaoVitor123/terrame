-- @example A model with static Agents that can reproduce to neighbor Cells.
-- @image growing-society.bmp

singleFooAgent = Agent{
	execute = function(self)
		local cell = self:getCell():getNeighborhood():sample()
		if cell:isEmpty() and math.random() < 0.3 then
			local child = self:reproduce()
			child:move(cell)
		end
	end
}

soc = Society{
	instance = singleFooAgent,
	quantity = 10
}

cs = CellularSpace{
	xdim = 100
}

cs:createNeighborhood()

e = Environment{
	cs,
	soc
}

e:createPlacement{max = 1}

Chart{
	target = soc
}

soc:notify(0)

t = Timer{
	Event{action = soc},
	Event{action = cs},
	Event{action = function(e)
		soc:notify(e)
	end}
}

map = Map{
	target = cs,
	grouping = "placement",
	value = {0, 1},
	color = {"black", "white"}
}

t:execute(120)

