local cnf = {}

cnf.db = {

    host="127.0.0.1",
    port=3306,--数据库端口
    database="mergegame",
    user="root",
    password="1986109",
}

cnf.redis = {
    host = "0.0.0.0",
    port = 6379,--redis端口
    db   = 0,
    auth = "lebronjames"
 }

cnf.watchdog = {

    port = 8889,
    maxclient = 8000,
    nodelay = true,
}

cnf.admin = {
    host = "0.0.0.0",
    port = 7000,
}

cnf.logdb = {
    host="127.0.0.1",
    port=3306,--数据库端口
    database="logdb_10002",
    user="root",
    password="1986109",    
}

cnf.debug           = true
cnf.guide_mode      = true
cnf.agent_count     = 4
cnf.debug_port      = 8001--debug控制台端口
cnf.platform        = 1010
cnf.serverId        = 10005
cnf.serverName      = "刘彪的服务器"
cnf.openTime        = "2020-01-13 11:00:00"
cnf.payPort         = 8011--充值服务端口   
cnf.connectMaster   = true--是否连接跨服服务器
cnf.mergeServerIds  = {}--min max 预留合服字段供跨服使用
cnf.isMaster        = false--是否是跨服服务器
cnf.webport         = 9123--ws or wss 端口
cnf.cacheTime       = 1 --分钟 玩家下线后数据在redis中的缓存时间
cnf.debugSql        = true--开启SQL监控
cnf.activeDay       = 3--用于活动装载数据的限制 3表示装载最近3天活跃的活动数据
cnf.bgsave          = 3--秒 定时存储SQL的间隔时间


return cnf
