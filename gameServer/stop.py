#-*- encoding:UTF-8 -*-
import os
import sys
import string 
import psutil
import re
import redis
import ConfigParser as cp

def searchPid(cwd):

	pids = psutil.pids()
	for pid in pids:
		p = psutil.Process(pid)
		if p.name() == "skynet":
			if cwd == p.cwd():
				print(cwd)
				return pid

	return 0

def initConfig():

	cf = cp.ConfigParser()
	ret = cf.read("./config/game.ini")
	if len(ret) < 1:

		sys.exit(-1)
	return cf		


if __name__ == "__main__":
	print("a------------------")
	# 设置文件目录为执行目录
	os.chdir(os.path.split(os.path.realpath(__file__))[0])
	print("b------1------------")
	cf = initConfig()
	print("b-------2-----------")
	cwd = cf.get("game", "stopdir")
	print("b------------------")
	if len(cwd) < 1:

		sys.exit(-1)
	print("c------------------")	
	pid = searchPid(cwd)
	if pid == 0:

		print("======================================")
		print("没有找到进程 [%s] skynet process." % (cwd))	
		print("======================================")
	else:

		host = cf.get("redis","host")
		port = int(cf.get("redis", "port"))
		db = int(cf.get("redis" , "db"))
		password = cf.get("redis", "password")

		redisdb = redis.Redis(host = host, port = port, db = db, password = password)	

		redisdb.hset("serconf","canlogin",0)
		ps = redisdb.pubsub()
		print("开始通知monitor服务安全退出.")
		redisdb.publish("onmonitorclose",1)
		ps.subscribe(["serversafeclose"])
		print("开始等待monitor服务安全退出.")
		for item in ps.listen():
			print("A====", item['type'])
			if item['type'] == "message":
				print("B====", item['data'])			
				if item['data'] == "1":
					print("serversafeclose, start kill skynet process.")
					break
		print("monitor服务安全退出.")			
		os.system("kill -9 %d" % pid)
		print("进程销毁成功 [%s][%d] process." % (cwd,pid))
		

		pidfile = cwd + '/skynet.pid'
		rmpid = 'rm -f ' + pidfile
		os.system(rmpid)
		print("删除 skynet.pid 文件成功.")

		#redisdb.disconnect()
		#info = redisdb.info()
		#for k in info:
			#int("%s:%s"%(k,info[k]))
		print("FINISHED.")		