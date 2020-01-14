#-*- encoding:UTF-8 -*-
import os
import sys
import psutil
import ConfigParser as cp

def searchPid(cwd):

	pids = psutil.pids()
	for pid in pids:
		p = psutil.Process(pid)
		if p.name() == "skynet":
			# print(p.cwd())
			if cwd == p.cwd():
				return pid

	return 0

def initConfig():

	cf = cp.ConfigParser()
	ret = cf.read("./config/game.ini")
	if len(ret) < 1:

		sys.exit(-1)
	return cf	

# 设置文件目录为执行目录
os.chdir(os.path.split(os.path.realpath(__file__))[0])

cf = initConfig()
cwd = cf.get("game", "startdir")
if len(cwd) < 1:

	sys.exit(-1)

pid = searchPid(cwd + "gameserver")
if pid == 0:
	ret = os.system(cwd + "frameWork/3rd/skynet/skynet ./config/config")
	if ret == 0 :
		print("server start ok.")
	else:
		print("进程已经存在.")	
else:
	print("进程已经存在.")