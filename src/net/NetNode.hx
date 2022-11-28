package net;

import hxbit.NetworkSerializable;
import core.NodeBase;

class NetNode extends NodeBase<NetNode> implements NetworkSerializable {

	public function new() {
		super();
		init();
	}

	public function init() {
		enableAutoReplication = true;
	}

	public function alive() {
		init();
	}
}
