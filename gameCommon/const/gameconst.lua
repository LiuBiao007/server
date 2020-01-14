local const = {}
--容器类型
const.container ={--背包容器
	hero_container 				= 1,	--门客
	item_container 				= 2,	--物品容器
	soulmate_container			= 3,	--红颜容器
}

--容器类型对应错误码
const.containerErr = {
	[const.container.hero_container] 			= "bag_hero_not_enough",
	[const.container.item_container] 			= "bag_item_not_enough",
	[const.container.soulmate_container] 			= "bag_soulmate_not_enough",
}

--原型类型
const.protos = {	
	hero_proto 					= 1,
	equip_proto 				= 2,
	skill_proto 				= 3,
	item_proto 					= 4,
	heroequip_proto 			= 5,
}

--资质类型
const.talent = {
	force 		= 1,--武力
	wit 		= 2,--智力
	politics 	= 3,--政治
	charm 		= 4,--魅力
}

--实例类型
const.insttype = {
	heroinst_type 				= 1,
	iteminst_type				= 2,
	soulmate_type				= 3,
}

--guid类型
const.serialtype = {
	player_guid 				= 1,
	item_guid 					= 2,
	hero_guid 					= 3,
	activitystates_guid 		= 4,
	activityglobalstates_guid	= 5,
	mail_guid 					= 6,
	playerRewardRecord_guid 	= 7,
	serverOrder_guid 			= 8, --服务订单号
	soulmate_guid				= 9,
	child_guid					= 10,
	marryapply_guid				= 11,
	stageRecord_guid			= 12,
	yamen_guid					= 13,
	yamenBattleRecord_guid		= 14,
	faction_guid				= 15,
	factionapply_guid			= 16,
	factiondynamic_guid         = 17,
	playerstate_guid			= 18,
	factionstate_guid			= 19,
}

--guid对应的string
const.serialtype2str = {
	[const.serialtype.player_guid] 					= "playerguid",
	[const.serialtype.item_guid] 					= "itemguid",
	[const.serialtype.hero_guid] 					= "heroguid",	
	[const.serialtype.activitystates_guid] 			= "activitystatesguid",
	[const.serialtype.activityglobalstates_guid]	= "activityglobalstatesguid",
	[const.serialtype.mail_guid] 					= "mailguid",
	[const.serialtype.playerRewardRecord_guid] 		= "playerRewardRecordGuid",
	[const.serialtype.serverOrder_guid] 			= "serverOrderGuid",
	[const.serialtype.soulmate_guid] 				= "soulmateguid",
	[const.serialtype.child_guid] 					= "childguid",
	[const.serialtype.marryapply_guid] 				= "marryapplyguid",	
	[const.serialtype.stageRecord_guid] 			= "stageRecordGuid",
	[const.serialtype.yamen_guid] 					= "yamenGuid",
	[const.serialtype.yamenBattleRecord_guid] 		= "yamenBattleRecordGuid",
	[const.serialtype.faction_guid] 				= "factionId",
	[const.serialtype.factionapply_guid] 			= "faId",	
	[const.serialtype.factiondynamic_guid] 			= "fdcId",
	[const.serialtype.playerstate_guid] 			= "playerstateguid",
	[const.serialtype.factionstate_guid] 			= "factionstateguid",
}

const.factionJob = {
	min = 1,
	member = 1,--成员
	elite  = 2,--精英
	subHeader = 3,--副盟主
	header = 4,--盟主
	max = 4,
}

--怪物类型
const.monstertype = {
}

--物品子类型
const.itemtype = {
	min 				= 10001,
	govAffairs			= 10001, --政务令
	scrollForce			= 10002, --武力卷轴
	scrollWit			= 10003, --智力卷轴
	scrollPolitics		= 10004, --政治卷轴
	scrollCharm			= 10005, --魅力卷轴
	politicsBall		= 10006, --政治丸 data:增加政治属性
	randomBall			= 10007, --属性散 data:最小值,最大值
	book1star			= 10008, --一星宝典
	book2star			= 10009, --二星宝典
	book3star			= 10010, --三星宝典
	book4star			= 10011, --四星宝典
	book5star			= 10012, --五星宝典
	breakCost			= 10013, --突破消耗道具
	fixedChest          = 10014, --固定宝箱
	randomChest         = 10015, --随机宝箱
	chooseChest         = 10016, --选择宝箱
	physicalItem		= 10017, --体力丹 data: 增加子嗣体力
	vigorItem			= 10018, --精力丹 data: 增加精力
	energyItem			= 10019, --活力丹 data: 增加活力
	bosomItem			= 10020, --亲密道具 data: 增加红颜亲密度
	charmItem			= 10021, --魅力道具 data: 增加红颜魅力
	proposeItem			= 10022, --提亲道具
	masterHorn			= 10023, --跨服喇叭
	battlePlate			= 10024, -- 出使令
	challengePlate		= 10025, -- 挑战令
	manhuntPlate		= 10026, -- 追捕令
	addLearnTimeItem	= 10027, --增加学习时间道具 data:增加学习时间 分钟
	titleItem			= 10028, --称号物品 data:称号ID
	stageBattlePlate	= 10029, -- 关卡出战令
	heroBookExpPack		= 10030, --书籍经验包
	heroSkillExpPack	= 10031, --技能经验包
	randomBosomItem		= 10032, --随机红颜亲密包
	randomCharmItem		= 10033, --随机红颜魅力包
	forceBall			= 10034, --武力丸
	charmBall			= 10035, --魅力丸
	witBall				= 10036, --智力丸
	collItem			= 10037, --征收令
	heroBookExpRandom	= 10038, --书籍经验包1
	heroSkillExpRandom	= 10039, --技能经验包2
	factionToken		= 10040, --联盟令
	superFactionToken	= 10041, --高级联盟令
	foodMaterial		= 10042, --宴会食材
	max 				= 10042,
}

-- 掉落类型
const.dropType = {
	min 				= 1,
	totalRate			= 1,  -- 累计随机(一轮固定掉落一次)
	aloneRate			= 2,  -- 独立计算随机(一轮掉落次数不固定)
	max 				= 2,
}

-- 奖励类型 银，娘兵元宝  B为政绩
const.bonusType = {
	min 				= 1,
	item 				= 1,  -- 物品
	silverCoin			= 2,  --银币
	goldCoin            = 3,  --金币
	ingot				= 4,  --元宝
	food				= 5,  --粮草
	soldiers            = 6,  --士兵
	trackRecord         = 7,  --政绩
	max 				= 7,
}

-- 消耗类型
const.costType = {
	min 				= 1,
	item 				= 1,  -- 物品
	silverCoin			= 2,  --银币
	goldCoin            = 3,  --金币
	ingot				= 4,  --元宝
	food				= 5,  --粮草
	soldiers            = 6,  --士兵
	max 				= 6,
}

--性别
const.sex = {
	min = 1,
	male = 1,--男
	female = 2,--女
	max = 2,
}

--门客颜色
const.herocolor = {
	min = 1,
	write = 1,--白
	green = 2,--绿
	blue = 3,--蓝
	purple = 4,--紫
	orange = 5,--橙
	red = 6,--红
	gold = 7,--金
	max = 7,
}

-- 颜色对应名字
const.color2Name = {
	[const.herocolor.write] 		= "白色",
	[const.herocolor.green] 		= "绿色",
	[const.herocolor.blue] 			= "蓝色",
	[const.herocolor.purple] 		= "紫色",
	[const.herocolor.orange] 		= "橙色",
	[const.herocolor.red] 			= "红色",
	[const.herocolor.gold] 			= "金色",
}


--聊天频道
const.channels = {
	world	= 1,--世界
	master 	= 2,--跨服
	faction = 3,--联盟
}

--战斗类型
const.battletype = {
	pvp = 1,--pvp
	pve = 2,--pve
	boss = 3,--boss
}


-- 邮件来源类型
const.mailSourceType = {
	player 	      		= 0,  -- 玩家
	system 		  		= 1,  -- 后台
	powerRank 	  		= 2,  --
	stageRank     		= 3,
	bosomRank	  		= 4,
	title 		  		= 5,  -- 称号
	firstRecharge 		= 6,  -- 首冲
	rankingList   		= 7,  -- 排行榜(运营)
	rechargeBonuses   	= 8,  -- 充值奖励(运营)
	vipLevel			= 9,  -- vip升级
	officialLevel		= 10, -- 官职升级
	marryTimeout		= 11, --结婚请求到期
	marryReject			= 12, --结婚请求被拒绝
	faction 			= 13, --联盟
}

const.taskType = { --任务类型

}

-- 循环公告类型
const.recycleNoticeType = {
	min 		= 1,
	admin 		= 1, -- 后台插入
	game 		= 2, -- 游戏产出
	max 		= 2,
}

-- 数字转中文
const.numberToChinese = {'一', '二', '三', '四', '五', '七', '八', '九', '十'}

--------------- 排行榜(运营)配置 ---------------
-- 排行榜类型
const.rankingListType = {
	min 					= 1,
	power 					= 1, -- 势力
	stage 					= 2, -- 关卡
	yamen 					= 3, -- 衙门
	bosom 					= 4, -- 亲密度
	costGoldCoin 			= 5, -- 金币消耗
	costFood 				= 6, -- 粮食消耗
	costSoldier 			= 7, -- 士兵消耗
	max 					= 7,
}

--------------- 限时奖励(运营)配置 ---------------
-- 限时奖励类型
const.timeLimitType = {
	min 					= 1,
	costIngot 				= 1, -- 元宝消耗
	costSoldier 			= 2, -- 士兵消耗
	costGoldCoin 			= 3, -- 金币消耗
	costScroll 				= 4, -- 强化卷轴消耗(武力,智力,政治,魅力)
	costChallengePlate 		= 5, -- 挑战令消耗
	costManhuntPlate 		= 6, -- 追捕令消耗
	addPower 				= 7, -- 势力涨幅
	doneAffairs 			= 8, -- 政务次数
	login 					= 9, -- 连续登陆
	addYamenScore 			= 10,-- 衙门分数涨幅
	addMarry 				= 11,-- 联姻次数
	addLearn 				= 12,-- 书院学习次数
	asserts 				= 13,-- 经营商产次数
	farm 					= 14,-- 凝聚结晶次数
	soldiers 				= 15,-- 招募魔灵次数
	max 					= 15,
}

--------------- 开服福利(运营)配置 ---------------
-- 开服福利任务类型
const.openWelfareTaskTypes = {
	min 					= 1,
	power 					= 1, -- 势力
	official 				= 2, -- 官职
	yamenScore 				= 3, -- 衙门分数获得 0
	yamenBattle 			= 4, -- 衙门战斗次数 0
	borderInvasionWinCount	= 5, -- 副本攻打胜利次数 0
	borderInvasionBossDamage= 6, -- 副本Boss伤害 0
	passStage 				= 7, -- 关卡通关章节
	soulmateBosom 			= 8, -- 红颜个数Y达到好感度X 
	totalSoulmateBosom		= 9, -- 全体红颜累积好感度
	childCount 				= 10,-- 子嗣个数
	heroLevel 				= 11,-- 门客个数Y达到X等级 
	affairsCount 			= 12,-- 政务次数 0
	learnCount 				= 13,-- 学习次数 0
	max 					= 13,
}

-- 开服福利每日类型
const.openWelfareDaysTypes = {
	min 					= 1,
	login 					= 1, -- 登陆
	recharge 				= 2, -- 单笔充值
	totalRecharge 			= 3, -- 累计充值
	max 					= 3,
}

--玩家独有数据表		表名    角色ID字段	
const.loadPlayerData = {mail 		= "receiverId",
						item 		= "ownerId",
						playerstates = "playerId"}

--需要装载的简单玩家信息
const.simplePlayer = {'guid', 'userid', 'serverid', 'name', 'totalBosom', 'factionName', 'title', 'stage', 'headicon', 'icon',
         			   'vipLevel', 'vipExp', 'power', 'force', 'wit', 'politics', 'charm', 'trackRecord', 'sex', 'official',
            		'forbidTime', 'number', 'herosInfo', 'popular', 'ingot', 'platform', "devote", "lastOfflineTime"}

return const