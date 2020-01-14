package.path = package.path .. ";" .. "../?.lua"
require "class.class"

local fsm = require "fsm.fsm"
local fsmState = require "fsm.fsmState"
local child = require "child"

local c = child:new()

local step1 = fsmState:new()
step1:setState("enter", c.enter, c)
step1:setState("exit", c.exit, c)
step1:setState("update", c.update, c)

local c2 = child:new()

local step2 = fsmState:new()
step2:setState("enter", c2.enter, c2)
step2:setState("exit", c2.exit, c2)
step2:setState("update", c2.update, c2)

local c3 = child:new()

local step3 = fsmState:new()
step3:setState("enter", c3.enter, c3)
step3:setState("exit", c3.exit, c3)
step3:setState("update", c3.update, c3)


local state = fsm:new()

state:registState("step1", step1)
state:registState("step2", step2)
state:registState("step3", step3)

state:initState(step1)


state:toState("step2", "i am come, step2.")
state:toState("step3", "yes, i am step 3.")
state:toState("step1", "ohhh, i am come back, step1.")

state:toUpdate()
