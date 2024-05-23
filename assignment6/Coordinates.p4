/*
 * P4 Coordinate World
 * 
 * This program runs the 2D world in which each player moves, storing both the map of
 * positive and negative locations as well as all player locations
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
 * -> 2: positive location (e.g. food) - this adds to the score of the player
 * -> 3: negative location (e.g. danger) - this kills the player (removed from world)
 * 
 * The player header is designed like this :
 *
 * Byte:	0		1		2		3
 *		ID,Move,F0	F1,F2,F3,F4,	F5,F6,F7,F8,	X,Y
 *
 * ID (4 bits)
 *   -> indicates which player is making the move
 *   -> For initialisation, player sends ID 0 and then is assigned back an ID
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
 
#include <core.p4>
#include <v1model.p4>

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

parser ActionParser(packet_in packet,
		    out headers hdr,
		    inout metadata meta,
		    inout standard_metadata_t standard_metadata) {

	state start{
		packet.extract(hdr.ethernet);
		packet.extract(hdr.playerAction);
		transition accept;
	}
}

// ______________________________   Ingress Processing  ______________________________


