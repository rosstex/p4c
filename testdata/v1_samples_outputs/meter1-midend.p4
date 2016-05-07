#include "/home/mbudiu/barefoot/git/p4c/build/../p4include/core.p4"
#include "/home/mbudiu/barefoot/git/p4c/build/../p4include/v1model.p4"

struct intrinsic_metadata_t {
    bit<4>  mcast_grp;
    bit<4>  egress_rid;
    bit<16> mcast_hash;
    bit<32> lf_field_list;
}

struct meta_t {
    bit<32> meter_tag;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

struct metadata {
    @name("intrinsic_metadata") 
    intrinsic_metadata_t intrinsic_metadata;
    @name("meta") 
    meta_t               meta;
}

struct headers {
    @name("ethernet") 
    ethernet_t ethernet;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name("parse_ethernet") state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition accept;
    }
    @name("start") state start {
        transition parse_ethernet;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    action NoAction_0() {
    }
    action NoAction_1() {
    }
    DirectMeter<bit<32>>(CounterType.Packets) @name("my_meter") my_meter_0;
    @name("_drop") action _drop_0() {
        mark_to_drop();
    }
    @name("_nop") action _nop_1() {
    }
    @name("m_filter") table m_filter_0() {
        actions = {
            _drop_0;
            _nop_1;
            NoAction_0;
        }
        key = {
            meta.meta.meter_tag: exact;
        }
        size = 16;
        default_action = NoAction_0();
    }
    @name("m_action") action m_action(bit<9> meter_idx) {
        standard_metadata.egress_spec = meter_idx;
        standard_metadata.egress_spec = 9w1;
        my_meter_0.read(meta.meta.meter_tag);
    }
    @name("_nop") action _nop_2() {
        my_meter_0.read(meta.meta.meter_tag);
    }
    @name("m_table") table m_table_0() {
        actions = {
            m_action;
            _nop_2;
            NoAction_1;
        }
        key = {
            hdr.ethernet.srcAddr: exact;
        }
        size = 16384;
        default_action = NoAction_0();
        meters = my_meter_0;
    }
    apply {
        m_table_0.apply();
        m_filter_0.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
    }
}

control verifyChecksum(in headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    apply {
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
