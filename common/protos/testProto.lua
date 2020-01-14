local types = [[
]]

local c2s =[[
testTakeBonuses %d {            # 测试领取奖励
    request {
        dropType 0 : integer    # 掉落模式
    }
    response {
        errorcode 0 : integer
        bonusesResult 1 : bonusesResult
    }
}

additem %d {
    request {
        protoId 0 : integer
        count 1 : integer
    }
    response {
        errorcode 0 : integer
        itemInserts 1 : *itemInsert
    }
}

removeitem %d {
    request {
        protoId 0 : integer
        count 1 : integer
    }
    response {
        errorcode 0 : integer
        itemRemoves 1 : *itemRemove
    }   
}

removeinst %d {
    request {
        instId 0 : string
    }
    response {
        errorcode 0 : integer
        instId 1 : string
    }   
}


testPayIngot %d {                       # 测试加充值
    request {
        money 0 : integer
        payType 1 : integer             # 0:普通充值 1:月卡
    }
    response {
        errorcode 0 : integer
    }
}

addIngot %d {                       # 增加元宝
    request {
        ingot 0 : integer
    }
    response {
        errorcode 0 : integer
    }
}

addGoldCoin %d {                       # 测试金币
    request {
        goldCoin 0 : integer
    }
    response {
        errorcode 0 : integer
    }
}

addSilverCoin %d {                       # 测试银币
    request {
        silverCoin 0 : integer
    }
    response {
        errorcode 0 : integer
    }
}

addFood %d {                       # 增加粮草
    request {
        food 0 : integer
    }
    response {
        errorcode 0 : integer
    }
}

addSoldiers %d {                       # 测试士兵
    request {
        soldiers 0 : integer
    }
    response {
        errorcode 0 : integer
    }
}

addTrackRecord %d {                       # 增加政绩
    request {
        trackRecord 0 : integer
    }
    response {
        errorcode 0 : integer
    }
}

addheroskillexp %d {
    request {
        id 0 : string #门客ID
        exp 1: integer #经验
}
    response {
        errorcode 0 : integer
        id 1 : string
        exp 2: integer #门客当前技能经验
}
}

addvipexp %d { #增加VIP经验
    request {
    exp 0:integer
}
    response {
    errorcode 0:integer
}
}

sendsoulmate %d {
     request {
    power 0:integer
}
    response {
    errorcode 0:integer
}   
}

addfactionexp %d {
    request {
    exp 0:integer
}
    response {
    errorcode 0:integer
}
}

debugtime %d {
    request {
    hour 0:integer
    min 1:integer
    sec 2:integer
}
    response {
    errorcode 0:integer
}
}

playeractivity %d {
    request {
    a 0:integer
    b 1:integer
    c 2:integer
}
    response {
    errorcode 0:integer
}
}

uniqueactivity %d {
    request {
    a 0:integer
    b 1:integer
    c 2:integer
}
    response {
    errorcode 0:integer
}
}

dkick %d {
      request {
    a 0:integer
    b 1:integer
    c 2:integer
    activityId 3:integer
}
    response {
    errorcode 0:integer
}  
}

mkick %d {
    request {
        a 0:integer
        b 1:integer
        c 2:integer
    }
    response {
        errorcode 0:integer
    }   
}
]]

local s2c =[[
]]

return {
    types = types,
    c2s = c2s,
    s2c = s2c,
}