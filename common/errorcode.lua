local errorcode = {
	param_error = 1, --参数错误
	cannot_create_ingame = 2, --当前不可创建角色
	char_is_exist = 3, --角色已经存在
	server_is_maintenance = 4,--服务器禁止登陆
	user_platform_err = 5,--平台错误
	user_sex_error = 6,--性别错误
	user_serverid_err = 7,--区服错误
	user_string_errorlen = 8,--账号长度非法
	name_has_exist = 9,--名字已经存在
	userid_has_black = 10,--账号有空格
	name_has_black = 11,--名字有空格
	userid_len_err = 12,--账号长度错误
	server_version_error = 13,--版本号错误
	user_state_error_noentry = 14,--用户状态错误
	user_login_ing = 15,--正在登陆中
	user_login_nochar = 16,--还未有角色
	user_data_error = 17,--用户数据错误
	user_player_forbit = 18,--用户禁止登陆
	user_not_ingame = 19,--账号不存在
	chat_content_len_err = 20,--聊天内容长度非法
	chat_too_frequent = 21,--发送消息过于频繁	
	unknown_error = 24,--未知错误
	item_not_exist = 25,--物品不存在
	item_num_no_enough = 26,--物品个数不足	
	bag_item_not_enough = 48,--物品背包不足
	user_exit_ing = 117,--您正在退出游戏
	player_not_exist 						= 119, -- 玩家不存在

	master_server_close	= 120,--跨服已关闭
	master_server_cmd_error = 121,--跨服命令错误
	item_split_num_err = 122,--物品分割数量错误
	item_split_num_no_enough  = 123,--物品分割数量不足
	bonus_proto_not_exist = 124,--奖励原型不存在
	space_no_enough = 125,--空间不足
	mail_title_length_error = 126,--邮件标题长度错误
	mail_content_length_error = 127,--邮件内容长度错误
	mail_send_max_count_error = 128,--邮件已到最大发送数量
	ingot_not_enough = 129,--元宝不足
	silverCoin_not_enough = 130,--银币不足
	data_error = 131,--数据错误

		-- 消耗结构
	cost_string_empty 				= 132, -- 消耗数据为空
	cost_type_error 				= 133, -- 消耗类型错误
	cost_size_error 				= 134, -- 消耗数据数组个数错误
	cost_proto_not_exist 			= 135, -- 消耗数据原型ID不存在

	-- 奖励 消耗
	bonus_string_error 				= 136, -- 奖励数据错误
	bonus_string_empty 				= 137, -- 奖励数据为空
	bonus_type_error 				= 138, -- 奖励类型错误
	bonus_size_error 				= 139, -- 奖励数据数组个数错误
	bonus_proto_not_exist 			= 140, -- 奖励数据原型ID不存在
	bonus_drop_must_aloneRate 		= 141, -- 奖励掉落模式需为独立随机
	bonus_round_must_once 			= 142, -- 奖励回合数需为1次
	bonus_rate_must_drop 			= 143, -- 奖励概率需必掉	

	globalReward_id_error			= 144, -- 全服补偿奖励ID错误
	globalReward_time_error			= 145, -- 全服补偿奖励时间错误
	globalReward_title_error		= 146, -- 全服补偿奖励邮件标题错误
	globalReward_content_error		= 147, -- 全服补偿奖励邮件内容错误
	globalReward_attaches_error		= 148, -- 全服补偿奖励邮件附件错误
	globalReward_id_not_exist		= 149, -- 全服补偿奖励ID不存在

	-- 循环公告
	recycleNotice_time_error		= 150, -- 循环公告时间错误
	recycleNotice_interval_error	= 151, -- 循环公告间隔时间错误
	recycleNotice_content_error		= 152, -- 循环公告内容错误
	recycleNotice_id_error			= 153, -- 循环公告id错误或已有
	recycleNotice_id_not_exist		= 154, -- 循环公告id不存在

	-- 背包
	bag_space_no_enough 					= 271, -- 背包空间不足


	-- 激活码
	activationCode_not_exist 				= 301, -- 无此激活码
	activationCode_used 					= 302, -- 激活码已使用
	activationCode_not_used 				= 303, -- 玩家已使用过此批次激活码
	activationCode_expired 					= 304, -- 激活码已过期
	activationCode_channel_error			= 305, -- 非此渠道专属激活码
	activationCode_vip_error				= 306, -- vip专属激活码	



	-- 活动错误范围值(活动多  错误码范围要大  5200开始为每个活动错误码 每个活动占用100个错误码)
	activity_error_min 						= 5000, -- 活动错误码最小值

	activity_error_id						= 5001,	-- ID必须在有效范围之内
	activity_id_used						= 5002,	-- ID已经被使用
	activity_size32_error					= 5003,	-- 字符长度必须在1到32之间
	activity_size4000_error					= 5004,	-- 字符长度必须在1到4000之间
	activity_year_month_day_error			= 5005,	-- 年月日不正确
	activity_hour_min_sec_error				= 5006,	-- 时分秒不正确
	activity_start_dayu_end					= 5007,	-- 开始时间不能晚于结束时间
	activity_week_format_error				= 5008,	-- 每周时间段格式不正确
	activity_week_start_dayu_end			= 5009,	-- 每周时间段中起始时间不能高于结束时间
	activity_day_format_error				= 5010,	-- 每天时间段格式不正确
	activity_day_value_error				= 5011,	-- 每天时间段数值不正确
	activity_day_start_dayu_end				= 5012,	-- 每天时间段中起始时间不能高于结束时间
	activity_json_error						= 5013,	-- data json 数据错误
	activity_clasz_error					= 5014,	-- clasz 无此类型活动
	activity_not_exist						= 5015,	-- 活动不存在
	activity_not_dynamic_operation			= 5016,	-- 无法对非动态活动进行设置
	activity_state_value_error				= 5017,	-- 只能设置隐藏、启用、自动可见、可见状态
	activity_state_used						= 5018,	-- 状态未变
	activity_not_state_rollback				= 5019,	-- 状态不能回滚
	activity_data_not_exist					= 5020, -- 玩家活动未参与
	activity_player_error 					= 5021, -- 玩家错误(不在线)
	activity_opened_level_not_enough		= 5022, -- 玩家参与活动等级不足
	activity_not_open						= 5023, -- 活动未开启
	activity_oppPlayer_level_not_enough		= 5024, -- 目标玩家等级不足
	activity_finished						= 5025, -- 活动已完成

	-- dynamic data json check
	activity_not_table						= 5100,	-- 不是table数据
	activity_not_hash						= 5101,	-- 不是 Hash 数据
	activity_not_array						= 5102,	-- 不是 Array 数据
	activity_array_len_error				= 5103,	-- 数组长度不在取值范围内
	activity_not_string						= 5104,	-- 不是字符串
	activity_not_number						= 5105,	-- 不是数字
	activity_number_error					= 5106,	-- 不在取值范围内

	admin_protocol_not_exist				= 5107,	--管理协议不存在
	admin_param_error						= 5108,	--参数错误
	startTime_error							= 5109, --开始时间错误	
}

return errorcode
