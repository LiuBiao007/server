local fsm = class("fsm")

function fsm:init()

	self.curState = nil
	self.states   = {}
end	

function fsm:initState(state)

	self.curState = state
end	

function fsm:registState(name, state)

	assert(not self.states[name], string.format("name [%s] has registed.", name))
	assert(type(state) == 'table')
	self.states[name] = state
end	

function fsm:toState(name, ...)

	local state = self.states[name]
	assert(state, string.format("to state name [%s] error.", name))
	if self.curState and type(self.curState.onExit) == 'function' then
		self.curState:onExit(...)
	end	
	self.curState = state
	if type(state.onEnter) == 'function' then
		state:onEnter(...)
	end	
end	

function fsm:toUpdate(...)

	if self.curState and type(self.curState.onUpdate) == 'function' then
		self.curState:onUpdate(...)
	end	
end	

return fsm
