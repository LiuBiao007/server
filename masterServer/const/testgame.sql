
SET FOREIGN_KEY_CHECKS=0;

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
-- Table structure for serials
-- ----------------------------
DROP TABLE IF EXISTS `serials`;
CREATE TABLE `serials` (
  `id` int PRIMARY KEY NOT NULL comment 'id',
  `activitystatesguid` bigint(20) NOT NULL DEFAULT '1',
  `activityglobalstatesguid` bigint(20) NOT NULL DEFAULT '1'
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
INSERT INTO `version` VALUES ('1', '1');
INSERT INTO `serials` VALUES ('0', '1', '1');

