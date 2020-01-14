--日志操作类型
LOG_OP_BIGTYPE_CREATECHAR = 0--注册角色data: str:
LOG_OP_BIGTYPE_LOGIN = 1--登陆 data: str:
LOG_OP_BIGTYPE_LOGOUT = 2--登出 data:在线时间 str:
LOG_OP_BIGTYPE_GETSTONE = 3--得到元宝 data:得到前元宝,当前元宝,得到的元宝 str:
LOG_OP_BIGTYPE_COSTSTONE = 4 --消耗元宝 data:消耗前元宝,当前元宝,消耗的元宝 str:
LOG_OP_BIGTYPE_GETGOLDCOIN = 5 --得到金币 data:得到金币,当前金币 str:
LOG_OP_BIGTYPE_COSTGOLDCOIN = 6 --消耗金币 data:消耗金币,当前金币 str:
LOG_OP_BIGTYPE_LEVEL = 7--等级分布 data:等级 str:
LOG_OP_BIGTYPE_ITEMAPPEAR = 8--物品产生 data:子类型,数量,是否新增 str:物品id,原型id
LOG_OP_BIGTYPE_ITEMDISAPPEAR = 9--物品消耗 data:子类型,减少数量,是否消失 str:物品id,原型id
LOG_OP_BIGTYPE_HERO = 10--卡牌 data: str:卡牌id
LOG_OP_BIGTYPE_PAY = 11--充值 data:充值金额(分) 金币 钻石 充值次数 str:服务订单号
LOG_OP_BIGTYPE_GETSILVERCION = 12 --银币增加 data:增加前的银币 增加后的银币 增加的银币 str:
LOG_OP_BIGTYPE_COSTSILVERCION = 13--银币减少 data:减少前的银币 减少后的银币 减少的银币 str:

LOG_OP_BIGTYPE_GETFOOD = 14 --粮草增加 data:增加前的粮草 增加后的粮草 增加的粮草 str:
LOG_OP_BIGTYPE_COSTFOOD = 15--粮草减少 data:减少前的粮草 减少后的粮草 减少的粮草 str:

LOG_OP_BIGTYPE_GETSOLDIERS = 16 --士兵增加 data:增加前的士兵 增加后的士兵 增加的士兵 str:
LOG_OP_BIGTYPE_COSTSOLDIERS= 17--士兵减少 data:减少前的士兵 减少后的士兵 减少的士兵 str:

LOG_OP_BIGTYPE_GETGOVAFFAIRS = 18 --政绩政绩 data:增加前的政绩 增加后的政绩 增加的政绩 str:
LOG_OP_BIGTYPE_COSTGOVAFFAIRS= 19--政绩减少 data:减少前的政绩 减少后的政绩 减少的政绩 str:
LOG_OP_BIGTYPE_GUIDE = 20 --玩家引导分布  data: guideID str:

LOG_OP_BIGTYPE_MAX = 100

--8 9 子类型
--[[
2 物品
4 装备
5 卡牌
10 宝物
25 战宠
]]
