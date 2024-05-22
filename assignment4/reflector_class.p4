/* -*- P4_16 -*- */
#include <core.p4>
#include <v1model.p4>

/*************************************************************************
*********************** H E A D E R S  ***********************************
*************************************************************************/

typedef bit<9>  egressSpec_t;
typedef bit<48> macAddr_t;

header ethernet_t {
	macAddr_t 	dstAddr;
	macAddr_t 	srcAddr;
	bit<16> 	etherType;
}

header ipv4_t {
	macAddr_t 	dstAddr;
	macAddr_t 	srcAddr;
	bit<16> 	ipv4Type;
}

struct metadata {
    /* empty */
}

struct headers {
	ethernet_t 	ethernet;
	ipv4_t 		ipv4;
}

/*************************************************************************
*********************** P A R S E R  ***********************************
*************************************************************************/

parser MyParser(packet_in packet,
                out headers hdr,
                inout metadata meta,
                inout standard_metadata_t standard_metadata) {

state start {
	transition parse_ethernet;
    }

state parse_ethernet {
	packet.extract(hdr.ethernet);
	transition select(hdr.ethernet.etherType) {
		//0x800: parse_ipv4;
		default: accept;
	}
} 

/*state parse_ipv4 {
	packet.extract(hdr.ipv4);
	}
} 



/*************************************************************************
************   C H E C K S U M    V E R I F I C A T I O N   *************
*************************************************************************/
/*
control MyVerifyChecksum(inout headers hdr, inout metadata meta) {   
    apply {  }
}


/*************************************************************************
**************  I N G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyIngress(inout headers hdr,
                  inout metadata meta,
                  inout standard_metadata_t standard_metadata) {

    action swap_mac_addresses() {
       macAddr_t tmp_mac;
       tmp_mac = hdr.ethernet.dstAddr;
       hdr.ethernet.dstAddr = hdr.ethernet.srcAddr;
       hdr.ethernet.srcAddr = tmp_mac;
       
       standard_metadata.egress_spec = standard_metadata.ingress_port;
    }
    
    action drop() {
	mark_to_drop(standard_metadata);
    }
    
    table src_mac_drop {
        key = {
	   hdr.ethernet.srcAddr:exact;
        }
        actions = {
	   swap_mac_addresses;
	   drop;
	   NoAction;
        }
        size = 1024;
	default_action = NoAction();
    }
    
    apply {
    	src_mac_drop.apply();
    }
}
       
       
    


/*************************************************************************
****************  E G R E S S   P R O C E S S I N G   *******************
*************************************************************************/

control MyEgress(inout headers hdr,
                 inout metadata meta,
                 inout standard_metadata_t standard_metadata) {
    apply {  }
}

/*************************************************************************
*************   C H E C K S U M    C O M P U T A T I O N   **************
*************************************************************************/

control MyComputeChecksum(inout headers hdr, inout metadata meta) {
     apply {

     }
}


/*************************************************************************
***********************  D E P A R S E R  *******************************
*************************************************************************/

control MyDeparser(packet_out packet, in headers hdr) {
    apply {
	packet.emit(hdr.ethernet);
    }
}

/*************************************************************************
***********************  S W I T C H  *******************************
*************************************************************************/

V1Switch(
MyParser(),
MyVerifyChecksum(),
MyIngress(),
MyEgress(),
MyComputeChecksum(),
MyDeparser()
) main;
