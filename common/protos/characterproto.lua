local types = [[

.affairs { #政务数据
	id 0 : integer #政务ID ID为-1代表政务已经被处理 等待下次刷新出来
	clock 1: integer #刷新时间
	bonusesType 2: integer #奖励类型
	bonusesValue 3: integer #奖励值
}

.titleItem {
	title 0:integer #称号ID
	time 1:integer #称号获取时间
	takeTime 2:integer #称号邮件的发送时间
	addTime 3:integer #额外增加时间 秒 倒计时 = cnftime - (now - time) + addTime
}

.vip {
	vipLookfor 0:integer #每日寻访免费次数
	vipLearnHero 1:integer #学而不倦
	vipSoulmateExp 2:integer #红颜赐福
	vipTakesalary 3:integer #天赐元宝
	vipChildExp 4:integer #天资聪慧
	vipHeroLevel 5:integer #连升三级
	vipAsserts 6:integer #十倍商产	
}

.blackInfo {
	guid 0:string
	name 1:string
	number 2:integer	
}

.learnitem {
	id 1:string
	learnTime 2:integer #-1未学习 >0 表示学习开始的时间
	learnSlot 3:integer
}

.playerbase { #角色基础数据
	guid 1: string #id
	name 2: string #名字
	sex 3: integer #性别 1男 2女
	headicon 4: string #官职头像
}
   
.chatBaseInfo {
	guid 0:string #角色guid
	serverid 1:integer #区服ID
	name 2:string	#名字
	official 3:integer	#官职
	vipLevel 4:integer	#VIP
	time 5:integer	#发言时间
	title 6: *titleItem #所有称号
}

.chatmsg {
	channelId 1 : integer #频道id
	content 2 : string #聊天内容	
	playerbase 3:chatBaseInfo #基础信息
}

.finalvalues {
	force 0 : string #武力
	wit 1 : string #智力
	politics 2 : string #政治
	charm 3 : string #魅力
	power 4 : string #势力
}

.payitem {
	order 0: string #CP订单号
	goodsId 1: integer #商品ID
}

.playerfullinfo { #角色完整数据
	base 0 : playerbase
	finalvalues 1 : finalvalues
	items 2 : *item(id) 							#物品
    mails 3 : *mail(id)							    # 邮件数据
    activityStates 4: *activityState(activityId)
    dynamicActivityParams 5:*dynamicActivityParam(id)
    activityOpenStates 6:*activityOpenState(id)
    activityGlobalStates 7:*activityGlobalState(activityId)
}

.viewinfo {
	guid 0 : string #角色ID
	serverid 1 : integer #区服
	name 2 : string #名字
	official 3 : integer #官职
	vipLevel  4 : integer #VIP
	icon 5 : string #头像 创建角色传递的
	headicon 6 : integer #头像
	number 7 : integer #编号
	power 8 : string #势力
	force 9: string #武力
	politics 10 : string #政治
	charm 11 : string #魅力
	wit 12 : string #智力
	factionName 13 : string #联盟
	trackRecord 14 : integer #政绩
	totalBosom 15 : integer #亲密
	stage 16: string #关卡
	title 17 : *titleItem #称号	
	sex 18: integer #性别
}

.rankItem {
	name 0:string #角色名
	official 1:integer #官职
	value 2: string # 关卡 势力 属性  亲密度
	guid 3:string #角色ID 查询玩家信息 门客榜时对应的是门客ID
	serverid 4:integer #区服ID 跨服
	heroName 5:string #门客名称 跨服
	title 6:string
	playerId 7:string #门客榜时角色ID
}

.learnHeroData {
	id 0:string #门客ID
	learnTime 1:integer #-1未学习 >0 表示学习开始的时间
	skillExp 2:integer #技能经验
	bookExp 3:integer #书籍经验
	learnSlot 4:integer #学习槽
}

.popularRank {
	guid 0 : string #角色ID
	name 1:string #名字
	serverid 2:integer #区服ID
	official 3:integer #官职
	popular 4:integer #人气
	sex 5:integer #性别
	icon 6:string #头像
	title 7:integer #称号 可能为nil
}

.mainTask {
	mainTaskId 1:integer #任务ID
	mainTaskCount 2:integer #任务完成次数
	mainTaskState 3:integer #任务状态 0初始 1可领 2已领
}

.propertyItems {
	gold 0: integer #金币 可能未空
	food 1:integer #粮草 可能未空 可能未负
	soldiers 2:integer #士兵  可能未空
}


]]

local c2s = [[

createcharcter %d{ #创建角色 名字 性别 平台 账号id
	request {
		name 0 : string
		sex 1 : integer
		platform 2 : integer
		userid 3 : string
		serverid 4 : integer
		token 5 : string
		serverName 6 : string
		version 7 : string #版本号
		icon 8 : string
	}

	response {
		errorcode 0 : integer
		time 1 : integer #时间戳
		info 2 : playerfullinfo		
	}
}

entergame %d { #进入游戏 账号id 平台
	request {
		userid 0 : string
		serverid 1 : integer
		token 2 : string
		version 3 : string #版本号
		serverName 4 : string #区服名字
	}
	response {
		errorcode 0 : integer
		time 1 : integer #时间戳
		info 2 : playerfullinfo
	}
}

outgame %d { #退出游戏
	response {
		errorcode 0 : integer
	}		
}

applyServerOrder %d {#申请充值服务订单
	request {
	goodsId 0 : integer #非nil为ios正版充值
	bid 1 : string
	product_id 2: string
}	
	response {
	errorcode 0 : integer
	order 1 : string 
}
}

takeAffairs %d { #领取政务
	request {
	type 1 : string # A B 
}
	response {
	errorcode 0 : integer
	id 1 : integer #政务ID 
}
}

takeProperty %d { #经营资产
	request {
		type 1:integer # 1商产 2农产 3士兵
}
	response {
		errorcode 0 : integer
}
}

officialPromotion %d { #升职
	request {

}
	response {
		errorcode 0 : integer
}		
}

quickTakeProperty %d { #一键征收
	request {

}
	response {
		errorcode 0 : integer
		r 1: propertyItems
}		
}

takeSalary %d { #领取俸禄
	request {
	id 0 :string #膜拜对象角色ID
}
	response {
	errorcode 0:integer
	ingot 1:integer
	salaryTime 2:integer #领取俸禄时间
}
}

chat %d { #聊天
	request {
	channelId 0 : integer #1世界 2跨服
	content 1 : string
}
	response {
	errorcode 0 : integer
	content 1 : string
	channelId 2 : integer
	itemRemoves 4: *itemRemove #跨服聊天 其他频道为nil 
}
}

addchatblack %d { #添加聊天黑名单
	request {
	id 0:string #对方角色ID
}
	response {
	errorcode 0 : integer
	blackInfo 1 : blackInfo
}
}

decchatblack %d { #取消黑明单
	request {
	id 0:string #取消黑明单ID 不传则全部取消
}
	response {
	errorcode 0 : integer
	id 1:string
}
}

viewplayerinfo %d { #查看玩家信息
	request {
	id 0:string #玩家ID
}
	response {
	errorcode 0:integer
	info 1: viewinfo #玩家信息
}
}

viewranks %d { #查看排行榜 跨服暂时没实现
	request {
	type 1:integer #类型 1本服势力 2本服亲密度 3本服关卡 4跨服势力 5跨服门客
}
	response {
	errorcode 0:integer
	ranks 2: *rankItem #排名数组 榜可能为空 最多100个数组 自己是否上榜以及排名客户端遍历下
	type 3:integer #类型
}
}

openlearnslot %d { #扩展学习槽
	request {

}
	response {
	errorcode 0:integer
	count 1:integer #扩展次数 槽的数量 = 初始数量 + 扩展次数
}
}

learnhero %d { #门客学习
	request {
		param 1:string # heroId,slot;heroId,slot...
}
	response {
	errorcode 0:integer
	r 1: *learnitem
}
}

getherolearnexp %d { #收货技能学习经验
	request {
	id 0:string #门客ID
}	
	response {
	errorcode 0:integer
	learnHeroData 1:learnHeroData
}	
}

quickgetherolearnexp %d {#一键收割
	request {

}
	response {
	errorcode 0:integer
	datas 1:*learnHeroData
}
}

viewpopularrank %d { #查看人气榜
	request {

}
	response {
	errorcode 0:integer
	ranks 1:*popularRank
	index 2:integer
}
}

viewtitleplayer %d { #查看拥有此称号的玩家
	request {
	title 0:integer #-1时查看已有称号第一名的信息
}
	response {
	errorcode 0 : integer
	arr 1:*popularRank
}
}

takemaintaskbonuses %d {
	request {

}	
	response {
	errorcode 0:integer
	bonusesResult 1 : bonusesResult
}
}

finishGuide %d { 					# 完成引导
	request {
		guideId 0 : integer 		# 引导ID
	}
	response {
		errorcode 0 : integer
		guideId 1 : integer
	}
}

useActivationCode %d { 				# 使用激活码
	request {
		activationCode 0 : string 	# 激活码
	}
	response {
		errorcode 0 : integer
	}
}

]]

local s2c = [[
heartbeat %d {}

logout %d {}

ingotChanged %d { #元宝变化事件
	request {
	ingot 1 : integer
}
}

goldCoinChanged %d { #金币变化事件
	request {
	goldCoin 1 : string
}
}

silverCoinChanged %d { #银币变化事件
	request {
		silverCoin 1 : string
}
}

foodChanged %d { #粮草变化事件
	request {
		food 1 : string
}
}

govAffairsChanged %d { #政绩变化事件
	request {
		affairs 1 : string
}
}

soldiersChanged %d { #士兵变化事件
	request {
		soldier 1 : string
}	
}

payIngotSuccess %d { #元宝充值成功
	request {
		money 1: string #充值金额 分
		ingot 2: string #增加元宝
}
}

finalvaluechanged %d { #角色最终属性变化事件
	request {
	finalvalues 1 : finalvalues #最终属性
}
}

trackRecordChanged %d { #政绩变化事件
	request {
		trackRecord 1 : integer
}	
}

insertNotice %d { 				# 走马灯插入
	request {
		type 1 : integer 		# 公告类型(1:后台插入 2:游戏产出)
		content 2 : string 		# 公告内容
	}
}

affairsChanged %d { #政务变化事件
	
	request {
		affairsId 1 : integer #政务ID
		leftAffairsCount 2 : integer #剩余政务数量
		affairsUpdateTime 3 : integer #政务刷新时间 -1代表初始时间
	}
}

propertyChanged %d { #资产变化事件
	
	request {
		pumpLeftCount 1 : integer #剩余招募次数
		pumpUpdateTime 2 : integer #招募刷新时间 -1不刷新
		farmUpdateTime 3 : integer #农产刷新时间 -1不刷新
		farmLeftCount 4 : integer #剩余农产次数
		assetsUpdateTime 5 : integer #商产刷新时间 -1不刷新
		assetsLeftCount 6 : integer #剩余商产次数
	}
}

officialChanged %d { #官职变化
	request {
	official 1 : integer #官职
	trackRecord 2: integer #政绩
	finalvalues 3:finalvalues
}
}

resetdata %d { #角色重置数据
	request {
	greetCount 1: integer #问候次数
}
}

vigorChanged %d { #精力变化
	request {
	vigor 1: integer #当前精力
	vigorTime 2: integer #精力刷新时间
}
}

physicalChanged %d { #体力变化
	request {
	physical 1: integer #当前体力
	physicalTime 2: integer #体力刷新时间
}	
}

fortuneChanged %d { #运势变化
	request {
	fortune 1: integer #当前运势
	fortuneCount 2 : integer #增加运势次数
}		
}

chatmsg %d { #聊天消息
	request {
	chatmsg 1 : chatmsg #聊天消息体
}
}

titleChanged %d { #称号变化事件
	request {
	title 0: *titleItem
}
}

popularChanged %d { #人气变化
	request {
	popular 0:integer #人气
}
}

mainTaskStateChanged %d { #主线任务变化事件
	request {
	task 0 : mainTask
}
}

vipChanged %d { #vip神迹变化
	request {
	vip 0:vip
}
}

vipLevelChanged %d { #vip等级经验变化
	request {
	vipLevel 0:integer
	vipExp 1:integer
}
}

totalChildPosCountChanged %d { #总子嗣位数量变化
	request {
	count 0:integer
}
}

startGuide %d { 				# 引导激活事件
	request {
		guideId 1 : integer 	# 引导ID
	}
}

vipluxurychanged %d {		   #vip神迹变化
	request {
		id 1:integer			#神迹ID xml数据
}
}

devotechanged %d { #联盟贡献变化
	request {
	devote 1:integer
}
}
]]

return {
    types = types,
    c2s = c2s,
    s2c = s2c,
}