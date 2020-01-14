LOGSQL = [[create table if not exists %s(
      `guid` char(24) NOT NULL comment 'guid',
      `userid` varchar(40) NOT NULL comment '账号id',
      `platform` int(4) NOT NULL comment '平台id',
      `serverid` int(4)  NOT NULL comment '服id',
      `name` varchar(24) NOT NULL comment '名字',
      `dotime` datetime NOT NULL DEFAULT '2012-01-01 00:00:00' comment '操作时间',  
      `bigtype` int(4) NOT NULL comment '大类型',  
      `cmd` varchar(32) NOT NULL comment '命令',
      `data1` bigint(20) NOT NULL comment '数值1',
      `data2` bigint(20)  NOT NULL comment '数值2',   
      `data3` int(4) NOT NULL comment '数值3',
      `data4` int(4)  NOT NULL comment '数值4',   
      `data5` int(4) NOT NULL comment '数值5',
      `data6` int(4)  NOT NULL comment '数值6',       
      `str1` varchar(32)  NOT NULL comment '字符串1',  
      `str2` varchar(32) NOT NULL comment '字符串2',
      `str3` varchar(32)  NOT NULL comment '字符串3',
      
      KEY `ind_e_guid` (`guid`),
      KEY `ind_e_userid` (`userid`),
      KEY `ind_e_platform` (`platform`),
      KEY `ind_e_serverid` (`serverid`),    
      KEY `ind_e_name` (`name`),        
      KEY `ind_e_cmd` (`cmd`)                 
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8;
replace into %s values('%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s','%s');]]