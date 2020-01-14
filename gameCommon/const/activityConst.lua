
-- 常规活动
ACTIVITYID_DEMO1                     = 100   -- 个人常规Demo 
ACTIVITYID_DEMO2                     = 101   -- 全局活动Demo 
ACTIVITYID_DEMO3                     = 1000004   -- 公告 运营活动 
ACTIVITYID_DEMO4                     = 401   -- 跨服活动demo

-- 运营活动
ACTIVITYID_DYNAMICBEG               = 1000000
ACTIVITYCLASZ_DYNAMICDEMO           = 1000000   -- 动态活动演示
ACTIVITYCLASZ_RANKINGLIST           = 1000001   -- 排行榜
ACTIVITYCLASZ_RECHARGEBONUSES       = 1000002   -- 充值奖励
ACTIVITYCLASZ_TIMELIMITBONUSES      = 1000003   -- 限时奖励
ACTIVITYCLASZ_NOTICE                = 1000004   -- 公告
ACTIVITYCLASZ_OPENWELFARE           = 1000005   -- 开服福利
ACTIVITYID_DYNAMICEND               = 1999999




DYNAMICACTIVITYSTATE_HIDDEN         = 0  -- 运营活动隐藏
DYNAMICACTIVITYSTATE_ENABLED        = 1  -- 运营活动激活
DYNAMICACTIVITYSTATE_AUTOVISIBLE    = 2  -- 运营活动自动可见(一般根据时间判断)
DYNAMICACTIVITYSTATE_VISIBLE        = 3  -- 运营活动可见
DYNAMICACTIVITYSTATE_RUNNING        = 4  -- 运营活动进行
DYNAMICACTIVITYSTATE_PENDING        = 5  -- 运营活动挂起
DYNAMICACTIVITYSTATE_EXPIRED        = 6  -- 运营活动过期


--  活动类型
ACTIVITYTYPE_UNKNOWN             = 0     -- 
ACTIVITYTYPE_MIN                 = 1     -- 
ACTIVITYTYPE_PLAYER              = 1     -- 个人活动
ACTIVITYTYPE_UNIQUE              = 2     -- 全服活动
ACTIVITYTYPE_FACTION             = 3     -- 联盟活动
ACTIVITYTYPE_MASTER              = 4     -- 跨服活动
ACTIVITYTYPE_DYNAMIC             = 5     -- 运营活动
ACTIVITYTYPE_MAX                 = 5     -- 


-- 活动状态
ACTIVITYSTATE_INITIAL            = 0    -- 初始
ACTIVITYSTATE_ACTIVATED          = 1    -- 激活
ACTIVITYSTATE_DONE               = 2    -- 完成

--type活动类型
--create是否进游戏就需要创建activityState
--name活动文件名字
--statekey 进游戏下发的activityState 跟sproto保持一致 个人活动不可以有globalkey
--globalkey 进游戏下发的activityGlobalState 跟sproto保持一致 配置了就下发globalState
ACTIVITY_CONFIG = {
    
    [ACTIVITYID_DEMO1] =  {type = ACTIVITYTYPE_PLAYER,  create = true, name = "activity_playerdemo", statekey = "demo1"},
    [ACTIVITYID_DEMO2] =  {type = ACTIVITYTYPE_UNIQUE,  create = true, name = "activity_uniquedemo", statekey = "demo2", globalkey = "gdemo2"},     
    [ACTIVITYID_DEMO3] =  {type = ACTIVITYTYPE_DYNAMIC, create = true, name = "activity_dynamicdemo", statekey = "demo3", globalkey = "gdemo3"},        
    [ACTIVITYID_DEMO4] =  {type = ACTIVITYTYPE_MASTER,  create = true, name = "activity_masterdemo", statekey = "demo4", globalkey = "gdemo4"}           

}



-- 运营需全局活动状态(需要下发客户端)
DynamicActivityGlobalStateEnterSend = 
{

}

