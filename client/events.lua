local mylog = require "base.mylog"
local showitem = require "showItem"

local events = {}

function events.chatmsg(player, args)

    local chatmsg = args.chatmsg
    local str = ""
    local channelId = chatmsg.channelId
    local content = chatmsg.content
    local b = chatmsg.playerbase    

    if channelId == 1 then--世界  
        str = "世界频道"
    elseif channelId == 2 then--队伍
        str = "跨服频道"        
    end 

    local fstr = string.format("收到来自%s的消息:%s",str, content)
    print(fstr)
    fstr = string.format("发消息人信息 name:%s id:%s vip:%d title:%s",b.name,b.guid,b.vipLevel, string.dump(b.title))
    print(fstr)
end 

function events.factionjobchanged(player, args)

    local str = string.format(" factionjobchanged id %s name %s oldjob %s job %s",
        args.id, args.name, args.oldjob, args.job)
    print(str)
end    

function events.unreadmailchanged(player, args)
    print("未读邮件数量变化 unreadMails ", args.unreadMails)
end 

function events.startGuide(player, args)
    mylog.info("引导出现 %s", args.guideId)
end 

function events.vipLevelChanged(player, args)

    local str = string.format("VIP变化 vipLevel %s vipExp %s", args.vipLevel, args.vipExp)
    print(str)
end    

function events.insertNotice(player, args)
    print(string.format("公告插入 type:%d content:%s", args.type, args.content))
end

function events.itemInserts(player, args)
    if args.itemInserts then
        print("物品数据插入成功")
        showitem.additem(player, args)
    end
end

function events.itemRemoves(player, args)
    if args.itemRemoves then
        print("物品数据移除成功")
        showitem.removeitem(player, args)
    end
end

function events.insertMail(player, args)
    print("邮件插入事件")
    local mail = args.mail
    player.mails[mail.id] = mail
end

function events.dynamicActivityInsert(player, args)
    print("动态活动插入事件")
    print(string.dump(args))

    local dynamicActivityParam = args.dynamicActivityParam
    player.dynamicActivityParams[dynamicActivityParam.id] = dynamicActivityParam
end

function events.dynamicActivityRemove(player, args)
    print("动态活动移除事件 activityId:", args.id)
    player.dynamicActivityParams[args.id] = nil
end

function events.dynamicActivityStateChanged(player, args)
    print(string.format("动态活动状态改变事件 activityId:%d state:%d", args.id, args.state))
    if player.dynamicActivityParams[args.id] then
        player.dynamicActivityParams[args.id].state = args.state
    end
end

function events.dynamicActivitySortIndex(player, args)
    print(string.format("动态活动顺序改变事件 activityId:%d sortIndex:%d", args.id, args.sortIndex))
    if player.dynamicActivityParams[args.id] then
        player.dynamicActivityParams[args.id].sortIndex = args.sortIndex
    end
end

function events.activityOpenState(player, args)
    print(string.format("活动开启状态更新事件 activityId:%d isOpened:%d", args.id, args.isOpened and 1 or 0))
    player.activityOpenStates[args.id] = args.isOpened
end 

function events.activityGlobalStateChanged(player, args)
    print("全局活动事件变化")
    print(string.dump(args))
end    

function events.activityStateChanged(player, args)
    print("活动状态更新事件")
    print(string.dump(args))
    if player then
        if not player.activityStates then
            player.activityStates = {}
        end
        local activityState = args.activityState
        player.activityStates[activityState.id] = activityState
        player.activityStatesByActivityId[activityState.activityId] = activityState
        --if player.robot then player.robot:doEvent_Activity(activityState) end--机器人
    end
end

function events.activityStateRemoveChanged(player, args)
    print("活动状态移除事件 活动状态ID:", args.id)
    player.activityStates[args.id] = nil
end

function events.factionActivityStateChanged(player, args)
    print("联盟活动状态更新事件")
    print(string.dump(args))
    if player then
        if not player.factionActivityStates then
            player.factionActivityStates = {}
        end

        local factionActivityState = args.factionActivityState
        player.factionActivityStates[factionActivityState.id] = factionActivityState
        player.factionActivityStatesByActivityId[factionActivityState.activityId] = factionActivityState
    end
end

function events.factionActivityStateRemoveChanged(player, args)
    print("联盟活动状态移除事件 活动状态ID:", args.id)
    player.factionActivityStates[args.id] = nil
end 

function events.finalvaluechanged(player, args)
    print("主角最终属性变化")
end  

function events.bigdata_header(bigdata, args)

    local name = args.name
    local index = args.index
    local len = args.len
    bigdata[index] = {
        name = name,
        len = len,
        data = "",
        index = index,
    }
end

function events.bigdata_content(bigdata, args)

    local index = args.index
    local data = args.data
    local d = bigdata[index]
    assert(d, string.format("error bigdata index %s", index))
    d.data = d.data .. data

    if #d.data >= d.len then
        return d
    end    
    return nil
end    

return events