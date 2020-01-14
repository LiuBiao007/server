#-*- encoding:UTF-8 -*-
import os
import sys
import string 
import psutil
import re
import redis
import ConfigParser as cp
import time
def searchPid(cwd):

	pids = psutil.pids()
	for pid in pids:
		p = psutil.Process(pid)
		if p.name() == "skynet":
			print(p.cwd())
			if cwd == p.cwd():
				return pid

	return 0

def initConfig():

	cf = cp.ConfigParser()
	ret = cf.read("./config/game.ini")
	if len(ret) < 1:

		sys.exit(-1)
	return cf		


if __name__ == "__main__":

	cf = initConfig()
	cwd = cf.get("game", "stopdir")
	if len(cwd) < 1:

		sys.exit(-1)

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
		print(host, port, db, password)
		redisdb = redis.Redis(host = host, port = port, db = db, password = password)	

		ps = redisdb.pubsub()
		print("开始通知跨服服务退出.")
		redisdb.publish("onmonitorclose",1)
		#ps.subscribe(["masterCLose"])
		print("开始等待跨服服务安全退出.")
		while 1:
			time.sleep(1)
			masterCLose = redisdb.get("masterCLose")
			if masterCLose == "1":
				break
	
		print("跨服服务安全退出.")			
		os.system("kill -9 %d" % pid)
		print("进程销毁成功 [%s][%d] process." % (cwd,pid))
		
		print("FINISHED.")		