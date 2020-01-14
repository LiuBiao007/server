/*
Navicat MySQL Data Transfer

Source Server         : ubuntu
Source Server Version : 50547
Source Host           : 120.26.6.154:3306
Source Database       : testgame

Target Server Type    : MYSQL
Target Server Version : 50547
File Encoding         : 65001

Date: 2016-06-06 10:15:55
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for player
-- ----------------------------
DROP TABLE IF EXISTS `player`;
CREATE TABLE `player` (
  `guid` char(24) NOT NULL comment 'guid',
  `userid` varchar(128) NOT NULL comment '账号id',
  `platform` int(4) NOT NULL comment '平台id',
  `serverid` int(4)  NOT NULL comment '服id',
  `name` varchar(24) NOT NULL comment '名字',
  `headicon` int(11) NOT NULL DEFAULT '0' comment '头像',
  `sex` tinyint(4) NOT NULL DEFAULT '0' comment '性别',
  `vipLevel` int(11) NOT NULL DEFAULT '0' comment 'vip等级', 
  `vipExp` int(11) NOT NULL DEFAULT '0' comment 'vip经验', 
  `power` bigint(20) NOT NULL comment '势力',
  `force` bigint(20) NOT NULL comment '武力',
  `wit` bigint(20) NOT NULL comment '智力',
  `politics` bigint(20) NOT NULL comment '政治',
  `charm` bigint(20) NOT NULL comment '魅力',
  `trackRecord` int(11) NOT NULL comment '政绩',
  `official` int(11) NOT NULL comment '官职',
  `silverCoin` bigint(20) NOT NULL comment '银币',
  `goldCoin` bigint(20) NOT NULL comment '金币',
  `ingot` bigint(20) NOT NULL comment '元宝',
  `food` bigint(20) NOT NULL comment '粮草',
  `soldier` bigint(20) NOT NULL comment '士兵',
  `salaryTime` int(4) NOT NULL comment '俸禄领取刷新时间',
  `assetsTime` int(4) NOT NULL comment '资产恢复刷新时间',
  `createTime` datetime NOT NULL DEFAULT '2019-01-01 00:00:00' comment '创建时间',
  `forbidTime` int(4) NOT NULL comment '禁止登陆时间',
  `version` int(11) NOT NULL comment '版本号',
  `welcome` int(11) NOT NULL comment '是否首次登陆',
  `firstChargeTime` int(11) NOT NULL  comment '第一次充值时间',
  `firstChargeLevel` int(11) NOT NULL comment '第一次充值等级',
  `chargeNum` int(11) NOT NULL comment '充值次数',
  `totalCharge` int(11) NOT NULL comment '总共充值金额 分',
  `day` int(4) NOT NULL comment '天数',
  `lastOfflineTime` int(4) NOT NULL  comment '下线时间',
  `assetsLeftCount` int(4) NOT NULL comment '经营商产资产剩余次数',
  `assetsUpdateTime` int(4) NOT NULL  comment '经营商产刷新时间',
  `farmLeftCount` int(4) NOT NULL comment '经营农产资产剩余次数',
  `farmUpdateTime` int(4) NOT NULL comment '经营农产刷新时间',
  `pumpLeftCount` int(4) NOT NULL comment '经营招募剩余次数',
  `pumpUpdateTime` int(4) NOT NULL comment '经营招募刷新时间',
  `affairsUpdateTime` int(4) NOT NULL comment '政务刷新时间',
  `affairsId` int(4) NOT NULL comment '当前政务Id',
  `leftAffairsCount` int(4) NOT NULL comment '剩余政务次数',
  `physical` int(4) NOT NULL comment '体力',
  `physicalTime` int(4) NOT NULL comment '体力恢复时间',  
  `vigor` int(4) NOT NULL comment '精力',
  `vigorTime` int(4) NOT NULL comment '精力恢复时间',
  `fortune` int(4) NOT NULL comment '运势',
  `fortuneCount` int(4) NOT NULL comment '增加运势次数(每天重置)',     
  `number` int(4) NOT NULL comment '玩家编号',    
  `icon` varchar(24) NOT NULL comment '头像',
  `greetCount`   int(4) NOT NULL comment '问候次数',    
  `lookforData` varchar(512) NOT NULL comment '#JSON#寻访记录', 
  `totalBosom` bigint  NOT NULL comment '所有红颜亲密度', 
  `factionName` char(48) NOT NULL comment '联盟名称',
  `title` text  NOT NULL comment '#JSON#所有称号ID,隔开',
  `stage` int(4) NOT NULL comment '大章节ID*10000+小关ID',
  `blackList` longtext NOT NULL comment '#JSON#聊天黑名单列表 ,',
  `bookSlotOpen` int(4)  NOT NULL comment '学习槽开启次数',
  `taskScore` int(4) NOT NULL comment '任务积分',
  `curTaskGroup` int(4) NOT NULL comment '任务组',
  `taskStates` text NOT NULL comment '任务数据',
  `taskScoreStates` text NOT NULL comment '任务领取积分奖励数据',
  `achievement` text NOT NULL comment '成就数据',  
  `herosInfo` text NOT NULL comment '门客简易信息',
  `loginTime` int(4)  NOT NULL comment '最近登录时间',
  `popular` int(4)  NOT NULL comment '人气',
  `childPosCount` int(4) NOT NULL comment '剩余子嗣位个数',
  `openCount` int(4) NOT NULL comment '扩充子嗣位次数',   
  `vipLookfor` int(4) NOT NULL comment '扩充子嗣位次数',   
  `vipLearnHero` int(4) NOT NULL comment '扩充子嗣位次数',     
  `vipSoulmateExp` int(4) NOT NULL comment '扩充子嗣位次数',   
  `vipTakesalary` int(4) NOT NULL comment '扩充子嗣位次数',   
  `vipChildExp` int(4) NOT NULL comment '扩充子嗣位次数',   
  `vipHeroLevel` int(4) NOT NULL comment '扩充子嗣位次数',   
  `vipAsserts` int(4) NOT NULL comment '扩充子嗣位次数',   
  `guideStates` varchar(512) NOT NULL comment '#JSON#引导数据(引导ID,引导ID)',
  `setFortune` int(4) NOT NULL comment '自动赈灾阈值',   
  `isGoldFortune` int(4) NOT NULL comment '是否金币赈灾',   
  `isFoodFortune` int(4) NOT NULL comment '是否粮草赈灾',   
  `fortuneTime` int(4) NOT NULL comment '运势恢复时间',
  `heroLearnRecord` text NOT NULL comment '#JSON#上次学习门客记录',
  `soulmateSendPower` bigint(20) NOT NULL comment '已经赠送红颜时的战力 初始-1',
  `lastQuitFactionTime` int(4) NOT NULL comment '退出联盟时间',
  `devote` int(4) NOT NULL comment '个人联盟贡献',

  PRIMARY KEY (`guid`),
  KEY `ind_character_id` (`guid`),
  KEY `ind_character_name` (`name`),
  KEY `ind_character_userid` (`userid`),
  KEY `ind_character_official_trackRecord` (`official`,`trackRecord`),
  KEY `ind_character_ingot` (`ingot`),
  KEY `ind_character_viplevel` (`vipLevel`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


DROP TABLE IF EXISTS `item`;
CREATE TABLE `item`                    
(
  `id` char(24) PRIMARY KEY NOT NULL comment '物品id',
  `protoId` int NOT NULL comment '原型id',
  `ownerId` char(24) NOT NULL comment '所有者id',
  `container` int NOT NULL comment '容器',
  `slot` int NOT NULL comment '槽',
  `binding` int NOT NULL comment '是否绑定',
  `count` int NOT NULL comment '叠加数量',
  `data` varchar(256) NOT NULL comment '扩展数据'
) ENGINE=InnoDB;
CREATE INDEX ind_item_id on `item`(id);
CREATE INDEX ind_itemownerid on `item`(ownerId);

-- ----------------------------
-- Table structure for activitystates
-- ----------------------------
DROP TABLE IF EXISTS `activitystates`;
CREATE TABLE `activitystates` (
  `id` char(24) PRIMARY KEY NOT NULL,
  `activityId` int NOT NULL,
  `playerId` char(24) NOT NULL,
  `state` int NOT NULL,
  `data` longtext NOT NULL comment '#JSON#活动数据',
  `resetTime` datetime NOT NULL DEFAULT '2012-01-01 00:00:00',

  KEY `ind_activitystates_id` (`id`),
  KEY `ind_activitystates_activityId` (`activityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- ----------------------------
-- Table structure for playerstates
-- ----------------------------
DROP TABLE IF EXISTS `playerstates`;
CREATE TABLE `playerstates` (
  `id` char(24) PRIMARY KEY NOT NULL,
  `activityId` int NOT NULL,
  `playerId` char(24) NOT NULL,
  `state` int NOT NULL,
  `data` longtext NOT NULL comment '#JSON#活动数据',
  `resetTime` datetime NOT NULL DEFAULT '2012-01-01 00:00:00',

  KEY `ind_playerstates_id` (`id`),
  KEY `ind_playerstates_activityId` (`activityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for dynamicstates
-- ----------------------------
DROP TABLE IF EXISTS `dynamicstates`;
CREATE TABLE `dynamicstates` (
  `id` char(24) PRIMARY KEY NOT NULL,
  `activityId` int NOT NULL,
  `playerId` char(24) NOT NULL,
  `state` int NOT NULL,
  `data` longtext NOT NULL comment '#JSON#活动数据',
  `resetTime` datetime NOT NULL DEFAULT '2012-01-01 00:00:00',

  KEY `ind_dynamicstates_id` (`id`),
  KEY `ind_dynamicstates_activityId` (`activityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- ----------------------------
-- Table structure for activityglobalstates
-- ----------------------------
DROP TABLE IF EXISTS `activityglobalstates`;
CREATE TABLE `activityglobalstates` (
  `id` char(24) PRIMARY KEY NOT NULL,
  `activityId` int NOT NULL,
  `data` longtext NOT NULL comment '#JSON#活动数据',
  `state` int NOT NULL,
  `resetTime` datetime NOT NULL DEFAULT '2012-01-01 00:00:00',

  KEY `ind_activityglobalstates_id` (`id`),
  KEY `ind_activityglobalstates_activityId` (`activityId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for dynamicactivityparams
-- ----------------------------
DROP TABLE IF EXISTS `dynamicactivityparams`;
CREATE TABLE `dynamicactivityparams`                  /* 动态活动参数 */
(
  `id` int PRIMARY KEY NOT NULL,                      /* ID，注意此值不可和以往的活动ID重复，非自增长ID */
  `name` varchar(32) NOT NULL,                        /* 名称 */
  `icon` varchar(32) NOT NULL,                        /* 活动图标 */
  `desc` varchar(4000) NOT NULL,                      /* 描述 */
  `detail` varchar(4000) NOT NULL,                    /* 详述 */
  `needLevel` int NOT NULL,                           /* 需要等级 */
  `sortIndex` int NOT NULL,                           /* 排序索引 */
  `startTime` datetime NOT NULL,                      /* 开始时间 */
  `endTime` datetime NOT NULL,                        /* 结束时间 */
  `segmentsPerWeek` varchar(16) NOT NULL,             /* 每周时间段 */
  `segmentsPerDay` varchar(256) NOT NULL,             /* 每天时间段 */
  `clasz` int NOT NULL,                               /* 活动类别 */
  `data` longtext NOT NULL comment '#JSON#活动数据',                           /* 活动数据 */
  `state` int NOT NULL,                               /* 状态 0:不可见 1:可见 2:启用 3:运行中 4:挂起 5:过期 */
  `updateTime` datetime NOT NULL,                      /* 更新时间 */

  KEY `ind_dynamicactivityparams_id` (`id`),
  KEY `ind_dynamicactivityparams_clasz` (`clasz`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for mail
-- ----------------------------
DROP TABLE IF EXISTS `mail`;
CREATE TABLE `mail`                     /* 邮件 */
(
  `id` char(24) PRIMARY KEY NOT NULL comment '24位ID',
  `type` int NOT NULL DEFAULT '0' comment '邮件类型(0:消息邮件  1:附件邮件)',
  `senderId` char(24) NOT NULL comment '发送者ID',
  `senderName` char(24) NOT NULL comment '发送者名',
  `receiverId` char(24) NOT NULL comment '接受者ID',
  `state` int NOT NULL DEFAULT '0' comment '邮件状态(0:未读  1:已读  2:已领取)',
  `sourceType` int NOT NULL DEFAULT '0' comment '邮件来源类型(0:玩家)',
  `title` varchar(64) NOT NULL comment '邮件标题',
  `content` varchar(512) NOT NULL comment '邮件内容',
  `createTime` datetime NOT NULL DEFAULT '2012-01-01 00:00:00' comment '创建时间',
  `attaches` varchar(512) NOT NULL comment '附件(奖励结构)',

  KEY `ind_mail_id` (`id`),
  KEY `ind_mail_receiverid` (`receiverId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- ----------------------------
-- Table structure for recyclenotice
-- ----------------------------
DROP TABLE IF EXISTS `recyclenotice`;
CREATE TABLE `recyclenotice`                     /* 循环公告 */
(
  `id` int PRIMARY KEY NOT NULL comment '公告id',
  `type` int NOT NULL comment '类型(1:后台 2:游戏)',
  `startTime` datetime NOT NULL DEFAULT '2012-01-01 00:00:00' comment '开始时间',
  `endTime` datetime NOT NULL DEFAULT '2012-01-01 00:00:00' comment '结束时间',
  `interval` int NOT NULL DEFAULT '2' comment '间隔时间(秒)',
  `content` text NOT NULL comment '公告内容',

  KEY `ind_recyclenotice_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for globalreward
-- ----------------------------
DROP TABLE IF EXISTS `globalreward`;
CREATE TABLE `globalreward`                     /* 全服补偿 */
(
  `id` int PRIMARY KEY NOT NULL comment '补偿id',
  `limitLevel` int NOT NULL DEFAULT '1' comment '限制等级',
  `serverIds` varchar(1024) NOT NULL comment '能领的服务器ids(空表示全服领取)',
  `platformIds` varchar(512) NOT NULL comment '能领的平台ids(空表示全服领取)',
  `startTime` datetime NOT NULL DEFAULT '2012-01-01 00:00:00' comment '开始时间',
  `endTime` datetime NOT NULL DEFAULT '2012-01-01 00:00:00' comment '结束时间',
  `title` varchar(64) NOT NULL comment '邮件标题',
  `content` varchar(512) NOT NULL comment '邮件内容',
  `attaches` varchar(512) NOT NULL comment '附件(奖励结构)',

  KEY `ind_globalreward_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for playerrewardrecord
-- ----------------------------
DROP TABLE IF EXISTS `playerrewardrecord`;
CREATE TABLE `playerrewardrecord`                     /* 玩家领取补偿记录 */
(
  `id` char(24) PRIMARY KEY NOT NULL comment '记录ID',
  `playerId` char(24) NOT NULL comment '玩家ID',
  `rewardId` int NOT NULL comment '补偿奖励ID',
  `sendTime` datetime NOT NULL DEFAULT '2012-01-01 00:00:00' comment '奖励邮件时间',

  KEY `ind_playerrewardrecord_id` (`id`),
  KEY `ind_playerrewardrecord_rewardId` (`rewardId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for serverorder
-- ----------------------------
DROP TABLE IF EXISTS `serverorder`;
CREATE TABLE `serverorder`                     /* 服务订单 */
(
  `guid` char(24) NOT NULL comment '服务订单',
  `userid` varchar(128) NOT NULL comment '账号id',
  `serverid` int(4)  NOT NULL comment '服id',
  `name` varchar(24) NOT NULL comment '名字',
  `playerId` char(24) NOT NULL comment '玩家id',
  `state` int(4) NOT NULL comment '状态',
  `bid` varchar(64) NOT NULL comment '包名--ios',
  `product_id` varchar(64) NOT NULL comment '商品id--ios',
  `goodsId` int(4) NOT NULL comment '商品id 充值--ios',
  PRIMARY KEY (`guid`),
  KEY `ind_serverorder_guid` (`guid`),
  KEY `ind_serverorder_playerId` (`playerId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

-- ----------------------------
-- Table structure for serials
-- ----------------------------
DROP TABLE IF EXISTS `serials`;
CREATE TABLE `serials` (
  `id` int PRIMARY KEY NOT NULL comment 'id',
  `playerguid` bigint(20) NOT NULL DEFAULT '1',
  `itemguid` bigint(20) NOT NULL DEFAULT '1',
  `activitystatesguid` bigint(20) NOT NULL DEFAULT '1',
  `activityglobalstatesguid` bigint(20) NOT NULL DEFAULT '1',
  `mailguid` bigint(20) NOT NULL DEFAULT '1',
  `playerRewardRecordGuid` bigint(20) NOT NULL DEFAULT '1',
  `serverOrderGuid` bigint(20) NOT NULL DEFAULT '1',
  `factionActivityStatesGuid` bigint(20) NOT NULL DEFAULT '1',
  `playerstateguid` bigint(20) NOT NULL DEFAULT '1',
  `factionstate_guid` bigint(20) NOT NULL DEFAULT '1'
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


-- ----------------------------
-- Table structure for version
-- ----------------------------
DROP TABLE IF EXISTS `version`;
CREATE TABLE `version`                          /* 版本 */
(
  `id` int PRIMARY KEY NOT NULL comment 'ID(此值只出现一个)',
  `version` int NOT NULL comment '版本号',

  KEY `ind_version_id` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT INTO `version` VALUES ('1', '3');
INSERT INTO `serials` VALUES ('0', '1', '1', '1', '1', '1', '1', '1', '1', '1'
                             ,'1');

