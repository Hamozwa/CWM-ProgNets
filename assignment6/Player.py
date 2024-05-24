import re
from scapy.all import *

x = 0
y = 0
ID = 0
interface = "enx0c37965f8a1c"

up = 0
left = 0
down = 0
right = 0

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

def initialise():
	send_packet(0)

def send_packet(move):
	global ID
	global x
	global y
	global up
	global left
	global down
	global right
	
	pkt = Ether(dst = "00:04:00:00:00:00", type = 0x1234) / PlayerAction(player_id = ID,
									     player_move = move,
									     player_x = x,
									     player_y = y
									     )
	
	#send and receive packet to p4 file
	resp = srp1(pkt,
		    iface = interface,
		    timeout = 5,
		    verbose = False)
	
	if resp:
		playerAction = resp[PlayerAction]
		if playerAction:
			print('x', playerAction.player_x, ', y', playerAction.player_y)
			ID = playerAction.player_id
			x = playerAction.player_x
			y = playerAction.player_y
			
			up = playerAction.F1
			left = playerAction.F3
			down = playerAction.F7
			right = playerAction.F5
			print('id', ID)
			#TODO: Print fields around player
			
			print(" +-------+-------+-------+")
			print(" |   {}   |   {}   |   {}   |".format(playerAction.F0,playerAction.F1,playerAction.F2))
			print(" +-------+-------+-------+")
			print(" |   {}   |  You  |   {}   |".format(playerAction.F3,playerAction.F5))
			print(" +-------+-------+-------+")
			print(" |   {}   |   {}   |   {}   |".format(playerAction.F6,playerAction.F7,playerAction.F8))
			print(" +-------+-------+-------+")
		else:
		
			print("player header not found in packet")

if __name__ == "__main__" :
	
	initialise()
	
	while True:
		#get user input
		print("Next action? (u/l/d/r)")
		inp = input("> ")
		
		match (inp):
			case "u":
				if up == 3:
					print("Wall is in the way!")
					pass
				else:
					send_packet(0)
			case "l":
				if left == 3:
					print("Wall is in the way!")
					pass
				else:
					send_packet(1)
			case "d":
				if down == 3:
					print("Wall is in the way!")
					pass
				else:
					send_packet(2)
			case "r":
				if right == 3:
					print("Wall is in the way!")
					pass
				else:
					send_packet(3)
			case _:
				print("Invalid action.")
		
		
