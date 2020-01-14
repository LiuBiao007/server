#-*- encoding:UTF-8 -*-
import os
import sys
import ConfigParser as cp

def initConfig():

	cf = cp.ConfigParser()
	ret = cf.read("./config/game.ini")
	if len(ret) < 1:

		sys.exit(-1)
	return cf	

cf = initConfig()
cwd = cf.get("game", "startdir")
if len(cwd) < 1:

	sys.exit(-1)

ret = os.system(cwd + "frameWork/3rd/skynet/skynet ./config/config")
if ret == 0 :
	print("master server start ok.")
else:
	print("进程已经存在.")	