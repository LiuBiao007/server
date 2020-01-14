local types = [[
.activityDemo {
    doneCount 0 : integer
    testCount 1 : integer
}

.activityDynamicDemo {
    doneCount 0 : integer
}

.dc {
    m 1:integer
    n 2:string
}

.dtest3 {
    a 1:integer
    b 2:integer
    c 3:dc
}

.demo1 {
   test1 1:integer
   test2 2:string
   test3 3: dtest3 
}

.activityData {
    demo 0 : activityDemo
    dynamicDemo 1 : activityDynamicDemo
    demo1 2: demo1
    demo2 3: demo1
    demo3 4: demo1
    demo4 5: demo1
}

.activityState {
    id 0 : string
    activityId 1 : integer
    clasz 2 : integer
    playerId 3 : string
    state 4 : integer
    resetTime 5 : integer
    isPlayerUnique 6 : integer
    data 7 : activityData
}

.activityOpenState {
    id 0 : integer
    isOpened 1 : boolean
}

.activityGlobalDemo {
    test 0 : integer
    test2 1 : integer
}

.activityGlobalData {
    demo 0 : activityGlobalDemo

}

.activityGlobalState {
    id 0 : string
    activityId 1 : integer
    clasz 2 : integer
    state 3 : integer
    resetTime 4 : integer
    data 5 : activityGlobalData
}

.dynamicActivityParam {
    id 0 : integer
    name 1 : string
    icon 2 : string
    desc 3 : string
    detail 4 : string
    needLevel 5 : integer
    sortIndex 6 : integer
    startTime 7 : integer
    endTime 8 : integer
    segmentsPerWeek 9 : string
    segmentsPerDay 10 : string
    clasz 11 : integer
    data 12 : string
    state 13 : integer
    updateTime 14 : integer
}


]]

local s2c = [[
activityStateChanged %d {
    request {
        activityState 0 : activityState
    }
}

activityStateRemoveChanged %d {
    request {
        id 0 : string
        activityId 1 : integer
    }
}

activityOpenState %d {
    request {
        id 0 : integer
        isOpened 1 : boolean
    }
}

activityGlobalStateChanged %d {
    request {
        activityGlobalState 0 : activityGlobalState
    }
}

dynamicActivityInsert %d {
    request {
        dynamicActivityParam 0 : dynamicActivityParam
    }
}

dynamicActivityRemove %d {
    request {
        id 0 : integer
    }
}

dynamicActivityStateChanged %d {
    request {
        id 0 : integer
        state 1 : integer
    }
}

dynamicActivitySortIndex %d {
    request {
        id 0 : integer
        sortIndex 1 : integer
    }
}

]]

local c2s = [[

activityDemoTest %d {
    request {
    }

    response {
        errorcode 0 : integer
    }
}

dynamicActivityDemoTakeExp %d {
    request {
        activityId 0 : integer
    }

    response {
        errorcode 0 : integer
    }
}



]]


return {
    types = types,
    c2s = c2s,
    s2c = s2c,
}