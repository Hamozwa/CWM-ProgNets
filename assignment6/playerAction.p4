/*
 * P4 Coordinate World
 * 
 * This program runs the 2D world in which each player moves, storing both the map of
 * positive locations and walls as well as all player locations
 *
 * +-------+-------+-------+
 * |   0   |   1   |   2   |
 * +-------+-------+-------+
 * |   3   |   4   |   5   |
 * +-------+-------+-------+
 * |   6   |   7   |   8   |
 * +-------+-------+-------+
 *
 * The above table corresponds to one field per area around the player (located at 4).
 * Each field is made up of a 2 bit unsigned int indicating what is around the player:
 * 
 * -> 0: empty space
 * -> 1: another player - this takes away from the score of the player
 * -> 2: positive location (i.e. food) - this adds to the score of the player
 * -> 3: wall
 * 
 * The player header is designed like this :
 *
 * Byte:	0		1		2		3
 *		ID,Move,F0	F1,F2,F3,F4,	F5,F6,F7,F8,	X,Y
 *
 * ID (4 bits)
 *   -> indicates which player is making the move
 *   -> For initialisation, player sends ID 0 and then is assigned back an ID
 *   -> Max. 15 players
 *
 * Move (2 bits)
 *   -> indicates where the player decides to move
 *   -> 0 - Up, 1 - Left, 2 - Down, 3 - Right
 *
 * Fx (2 bits)
 *   -> xth field around player (see above)
 *
 * X (4 bits)
 *   -> indicates x coordinate of player
 *
 * Y (4 bits)
 *   -> indicates y coordinate of player 
 *
 * The switch, upon receiving a packet, creates, moves or removes players accordingly,
 * before sending back the new coordinates of the player and the fields around it.
 */
 
// ___________________________________   SETUP__________________________________
 
#include <core.p4>
#include <v1model.p4>

//set up map and players in register
//map is 16x16 grid laid out in lines -i.e. (0,0), (1,0), (2,0), ... , (15,0), (0,1), (1,1), ...

//           CURRENT MAP
// 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3
// 3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3 
// 3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3
// 3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3
// 3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3
// 3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3
// 3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3
// 3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3
// 3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3
// 3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3
// 3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3
// 3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3
// 3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3		
// 3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3		32-47
// 3 0 0 0 0 0 0 0 0 0 0 0 0 0 0 3		16-31
// 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3 3		0-15

register<bit<2>>(256) map;
//register<bit<4>>(15) players_x;
//register<bit<4>>(15) players_y;
register<bit<4>>(1) num_of_players;


// ___________________________________   HEADERS   ___________________________________

//Ethernet Header

header ethernet_t {
	bit<48> dstAddr;
	bit<48> srcAddr;
	bit<16> etherType;
}

//Player Header

header playerAction_t {
	bit<4> player_id;
	bit<2> player_move;
	bit<2> F0;
	bit<2> F1;
	bit<2> F2;
	bit<2> F3;
	bit<2> F4;
	bit<2> F5;
	bit<2> F6;
	bit<2> F7;
	bit<2> F8;
	bit<4> player_x;
	bit<4> player_y;
}
	
//Header Struct

struct headers {
	ethernet_t ethernet;
	playerAction_t playerAction;
}

//Metadata Struct

struct metadata {
	//so much metadata here..
}

// ___________________________________   Parser   ____________________________________

parser WorldParser(packet_in packet,
		   out headers hdr,
		   inout metadata meta,
		   inout standard_metadata_t standard_metadata) {

	state start{
		packet.extract(hdr.ethernet);
		packet.extract(hdr.playerAction);
		transition accept;
	}
}

// ______________________________   Checksum Verification  ___________________________

control WorldVerifyChecksum(inout headers hdr,
                            inout metadata meta) {
    apply { }
}

// ______________________________   Ingress Processing  ______________________________

control WorldIngress(inout headers hdr,
		     inout metadata meta,
		     inout standard_metadata_t standard_metadata) {     
       	action move_up() {
       		
       		//initialise player if id is 0 
       		bit<4> player_num;
       		num_of_players.read(player_num, 0);
       		if (hdr.playerAction.player_id == 0){ 
       			player_num = player_num + 1;
       			hdr.playerAction.player_id = player_num;     
       			
       			//send initialised player to (8,8)
       			hdr.playerAction.player_x = 8;
       			hdr.playerAction.player_y = 8;  			
       		}
       		else {
       			hdr.playerAction.player_y = hdr.playerAction.player_y + 1;
       		}
       		num_of_players.write(0, player_num);
       	}
       	
       	action move_left() {
       		hdr.playerAction.player_x = hdr.playerAction.player_x - 1;
       	}
       	
       	action move_down() {
       		hdr.playerAction.player_y = hdr.playerAction.player_y - 1;
       	}
       	
       	action move_right() {
       		hdr.playerAction.player_x = hdr.playerAction.player_x + 1;
       	}
       	
       	action drop_packet() {
       	    mark_to_drop(standard_metadata);
       	    
       	}
       	
       	table find_next_position {
       		key = {
       			hdr.playerAction.player_move	:exact;
       		}
       		
       		actions = {
       			move_up();
       			move_left();
       			move_down();
       			move_right();
       			drop_packet();
       		}
       		
       		const default_action = drop_packet();
       		const entries = {
       			0x00:	move_up();
       			0x01:	move_left();
       			0x02:	move_down();
       			0x03:	move_right();
       		}
    	}
    	
    	apply {
    		
    		//POPULATE MAP - this is the only place it would work
    		
    		//create walls (3)
		map.write(0,3);//bottom wall
		map.write(1,3);
		map.write(2,3);
		map.write(3,3);
		map.write(4,3);
		map.write(5,3);
		map.write(6,3);
		map.write(7,3);
		map.write(8,3);
		map.write(9,3);
		map.write(10,3);
		map.write(11,3);
		map.write(12,3);
		map.write(13,3);
		map.write(14,3);
		map.write(15,3);

		map.write(240,3);//top wall
		map.write(241,3);
		map.write(242,3);
		map.write(243,3);
		map.write(244,3);
		map.write(245,3);
		map.write(246,3);
		map.write(247,3);
		map.write(248,3);
		map.write(249,3);
		map.write(250,3);
		map.write(251,3);
		map.write(252,3);
		map.write(253,3);
		map.write(254,3);
		map.write(255,3);

		map.write(16,3); //left wall
		map.write(32,3);
		map.write(48,3);
		map.write(64,3);
		map.write(80,3);
		map.write(96,3);
		map.write(112,3);
		map.write(128,3);
		map.write(144,3);
		map.write(160,3);
		map.write(176,3);
		map.write(192,3);
		map.write(208,3);
		map.write(224,3);

		map.write(31,3); //right wall
		map.write(47,3);
		map.write(63,3);
		map.write(79,3);
		map.write(95,3);
		map.write(111,3);
		map.write(127,3);
		map.write(143,3);
		map.write(159,3);
		map.write(175,3);
		map.write(191,3);
		map.write(207,3);
		map.write(223,3);
		map.write(239,3);

    		
    	
    		//Apply table
    		find_next_position.apply();
    		
    		bit<48> tmp_mac;
    		tmp_mac = hdr.ethernet.dstAddr;
       		hdr.ethernet.dstAddr = hdr.ethernet.srcAddr;
       		hdr.ethernet.srcAddr = tmp_mac;
       	
       		standard_metadata.egress_spec = standard_metadata.ingress_port;
       		
       		
       		//set new fields around player
       		
       		bit<32> tmp_thing0 = (bit<32>)(hdr.playerAction.player_x) - (bit<32>)1 + ((bit<32>)16 * (bit<32>)(hdr.playerAction.player_y + (bit<4>)1));
       		map.read(hdr.playerAction.F0, tmp_thing0);
       		
       		bit<32> tmp_thing1 = (bit<32>)(hdr.playerAction.player_x) + ((bit<32>)16 * (bit<32>)(hdr.playerAction.player_y + (bit<4>)1));
       		map.read(hdr.playerAction.F1, tmp_thing1);
       		
       		bit<32> tmp_thing2 = (bit<32>)(hdr.playerAction.player_x) + (bit<32>)1 + ((bit<32>)16 * (bit<32>)(hdr.playerAction.player_y + (bit<4>)1));
       		map.read(hdr.playerAction.F2, tmp_thing2);
       		
       		bit<32> tmp_thing3 = (bit<32>)(hdr.playerAction.player_x) - (bit<32>)1 + ((bit<32>)16 * (bit<32>)hdr.playerAction.player_y);
       		map.read(hdr.playerAction.F3, tmp_thing3);
       		
       		bit<32> tmp_thing4 = (bit<32>)(hdr.playerAction.player_x) + ((bit<32>)16 * (bit<32>)hdr.playerAction.player_y);
       		map.read(hdr.playerAction.F4, tmp_thing4);
       		
       		bit<32> tmp_thing5 = (bit<32>)(hdr.playerAction.player_x) + (bit<32>)1 + ((bit<32>)16 * (bit<32>)hdr.playerAction.player_y);
       		map.read(hdr.playerAction.F5, tmp_thing5);
       		
       		bit<32> tmp_thing6 = (bit<32>)(hdr.playerAction.player_x) - (bit<32>)1 + ((bit<32>)16 * (bit<32>)(hdr.playerAction.player_y - (bit<4>)1));
       		map.read(hdr.playerAction.F6, tmp_thing6);
       		
       		bit<32> tmp_thing7 = (bit<32>)(hdr.playerAction.player_x) + ((bit<32>)16 * (bit<32>)(hdr.playerAction.player_y - (bit<4>)1));
       		map.read(hdr.playerAction.F7, tmp_thing7);
       		
       		bit<32> tmp_thing8 = (bit<32>)(hdr.playerAction.player_x) + (bit<32>)1 + ((bit<32>)16 * (bit<32>)(hdr.playerAction.player_y - (bit<4>)1));
       		map.read(hdr.playerAction.F8, tmp_thing8);
    	}
}

// ______________________________   Egress Processing  ______________________________

control WorldEgress(inout headers hdr,
                    inout metadata meta,
                    inout standard_metadata_t standard_metadata) {
    apply { }
}

// _____________________________   Checksum Computation  _____________________________

control WorldComputeChecksum(inout headers hdr, inout metadata meta) {
    apply { }
}

// __________________________________   Deparser   ___________________________________

control WorldDeparser(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.playerAction);
    }
}

// ___________________________________   Switch   ____________________________________

V1Switch(
WorldParser(),
WorldVerifyChecksum(),
WorldIngress(),
WorldEgress(),
WorldComputeChecksum(),
WorldDeparser()
) main;
