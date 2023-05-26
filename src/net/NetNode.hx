package net;

import hxbit.NetworkHost;
import hxbit.NetworkSerializable;
import core.NodeBase;

class NetNode extends NodeBase<NetNode> implements NetworkSerializable {

	public function new( ?parent : NetNode ) {
		super( parent );
		init();
	}

	public function init() {
		enableAutoReplication = true;
	}

	public function alive() {
		init();
	}

	/**
		@param finalize true если с концами отключается ото всех клиентов
	**/
	public function disconnect(
		host : NetworkHost,
		ctx : NetworkSerializer,
		?finalize
	) @:privateAccess {
		host.unregister( this, ctx, finalize );
		for ( child in children ) {
			child.disconnect( host, ctx, finalize );
		}
	}
}