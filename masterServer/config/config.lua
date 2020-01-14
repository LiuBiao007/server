local cnf = {}

cnf.db = {

    host="127.0.0.1",
    port=3306,--数据库端口
    database="mastergame",
    user="root",
    password="1986109",
        
}

cnf.redis = {
    host = "127.0.0.1",
    port = 6380,--redis端口
    db   = 0,
    auth = "lebronjames"
 }

cnf.platform = 0
cnf.serverId = 20001--master server guid
cnf.isMaster = true
cnf.debugSql  = true--开启SQL监控
cnf.activeDay = 3--用于活动装载数据的限制 3表示装载最近3天活跃的活动数据
cnf.bgsave   = 3--秒 定时存储SQL的间隔时间
return cnf
