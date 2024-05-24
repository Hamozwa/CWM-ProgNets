import re
from scapy.all import *
import time
import random

interface = "enx0c37965f8a1c"
ID = 0
move = 2

#Define packet layout

class PlayerAction(Packet):
	name = "PlayerAction"
	fields_desc = [	BitField("player_id", 0, 4),
			BitField("player_move",0, 2),
			BitField("F0",0, 2),
			BitField("F1",0, 2),
			BitField("F2",0, 2),
			BitField("F3",0, 2),
			BitField("F4",0, 2),
			BitField("F5",0, 2),
			BitField("F6",0, 2),
			BitField("F7",0, 2),
			BitField("F8",0, 2),
			BitField("player_x",0, 4),
			BitField("player_y",0, 4),
	]
	
#Create packet

bind_layers(Ether, PlayerAction, type = 0x1234)

if __name__ == "__main__" :
	while True:
		time.sleep(5)
		x = random.randint(1,14)
		y = random.randint(1,14)
		print(str(x) + ", "+str(y))
		pkt = Ether(dst = "00:04:00:00:00:00", type = 0x1234) / PlayerAction(player_id = ID,
									     player_move = move,
									     player_x = x,
									     player_y = y
									     )
		resp = srp1(pkt,
		    iface = interface,
		    timeout = 1,
		    verbose = False)
	
		if resp:
			pass
