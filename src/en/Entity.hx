package en;

import cherry.soup.EventSignal.EventSignal0;
import cherry.soup.EventSignal.EventSignal1;
import dn.M;
import dn.Tweenie;
import en.collide.EntityContactCallback;
import en.model.EntityModel;
import en.spr.EntityView;
import en.util.EntityUtil;
import format.tmx.Data.TmxObject;
import game.client.GameClient;
import game.server.GameServer;
import game.server.ServerLevel;
import hxbit.NetworkHost;
import hxbit.NetworkSerializable;
import net.Client;
import net.NetNode;
import net.PrimNS;
import oimo.common.Vec3;
import oimo.dynamics.rigidbody.RigidBody;
import ui.core.InventoryGrid;
import util.Const;
import util.Direction;
import util.EregUtil;
import util.Util;
import util.tools.Save;

using en.EntityTmxDataParser;
using en.util.EntityUtil;
using util.TmxUtils;

@:keep
@:autoBuild( util.Macros.buildEntityCdbAssign() )
class Entity extends NetNode {

	public static var ALL : Array<Entity> = [];
	public static var ServerALL : Array<Entity> = [];
	public static var GC : Array<Entity> = [];

	@:s public var model : EntityModel;

	public var clientConfig : EntityTmxDataParser;

	public var eSpr : EntityView;
	public var destroyed( default, null ) = false;

	public var onMove : EventSignal0 = new EventSignal0();
	public var onDirChangedSignal : EventSignal1<Direction> = new EventSignal1();

	public var tmod( get, never ) : Float;

	inline function get_tmod() {
		return #if headless GameServer.inst.tmod #else if ( GameClient.inst != null ) GameClient.inst.tmod else
			Client.inst.tmod #end;
	}

	public var isMoving( get, never ) : Bool;

	function get_isMoving() return M.fabs( model.dx ) >= 0.01 || M.fabs( model.dy ) >= 0.01;

	public function new( ?tmxObj : Null<TmxObject> ) {

		ServerALL.push( this );
		model = new EntityModel();

		model.dir.onVal.add( onDirChangedSignal.dispatch );

		if ( model.tmxObj == null && tmxObj != null ) {
			model.tmxObj = tmxObj;
		}

		super();
	}

	public override function init() {
		super.init();
		onMove.add(() -> model.onMoveInvalidate = false );
	}

	/**
		called only on client-side when
		replicating entity over network on client side
	**/
	public override function alive() {
		super.alive();
		ALL.push( this );
		clientConfig = EntityTmxDataParser.fromTsTile(
			this.getEntityTsTile( model.level.tmxMap )
		);
		createView();
		applyTmx();
	}

	/** to be overriden **/
	function createView() {}

	function applyTmx() {
		EntityUtil.clientApplyTmx( this );
	}

	public function blink( ?c = 0xffffff ) {
		eSpr.colorAdd.setColor( c );
		model.cd.setS( "colorMaintain", 0.03 );
	}

	public inline function isAlive() {
		return !destroyed;
	}

	public function isLocked() return model.cd == null ? true : model.cd.has( "lock" );

	@:rpc
	public function lock( ?ms : Float ) {
		model.cd.setMs( "lock", ms != null ? ms : 1 / 0 );
	}

	@:rpc
	public function unlock() if ( model.cd != null ) model.cd.unset( "lock" );

	public function dropItem( item : en.Item, ?angle : Float, ?power : Float ) : en.Item {
		angle = angle == null ? Math.random() * M.toRad( 360 ) : angle;
		power = power == null ? Math.random() * .04 * 48 + .01 : power;

		var fItem = new FloatingItem( item );
		fItem.bump( Math.cos( angle ) * power, Math.sin( angle ) * power, 0 );
		fItem.lock( 1000 );
		if ( item.itemSprite != null )
			item.itemSprite.remove();

		return item;
	}

	@:rpc( clients )
	public function clientFlipX() {
		EntityUtil.clientFlipX( this );
	}

	public inline function bumpAwayFrom( e : Entity, spd : Float, ?spdZ = 0., ?ignoreReduction = false ) {
		var a = e.angTo( this );
		bump( Math.cos( a ) * spd, Math.sin( a ) * spd, spdZ, ignoreReduction );
	}

	public function bump( x : Float, y : Float, z : Float, ?ignoreReduction = false ) {
		var f = ignoreReduction ? 1.0 : 1 - model.bumpReduction;
		model.dx += x * f;
		model.dy += y * f;
		model.dz += z * f;
	}

	public function cancelVelocities() {
		model.dx = model.dx = 0;
		model.dy = model.dy = 0;
	}

	public function destroy() {
		if ( !destroyed ) {
			destroyed = true;
			GC.push( this );
		}
	}

	public function dispose() {
		ALL.remove( this );

		if ( eSpr != null ) eSpr.destroy();
		model.cd.dispose();
		model.tw.destroy();
	}

	@:rpc
	public function setFeetPos( x : Float, y : Float, z : Float ) {
		model.footX.val = x;
		model.footY.val = y;
		model.footZ.val = z;
		if ( model.rigidBody != null )
			model.rigidBody._transform.setPosition(
				new Vec3(
					model.footX.val,
					model.footY.val,
					model.footZ.val
				)
			);
	}

	public function kill( by : Null<Entity> ) {
		Save.inst.removeEntityById( model.sqlId );
		destroy();
	}

	public function unreg( host : NetworkHost, ctx : NetworkSerializer, ?finalize ) @:privateAccess {
		host.unregister( this, ctx, finalize );
		host.unregister( model.footX, ctx, finalize );
		host.unregister( model.footY, ctx, finalize );
	}

	public function headlessPreUpdate() {}

	public function headlessUpdate() {}

	public function headlessPostUpdate() {}

	public function headlessFrameEnd() {}

	public function preUpdate() {
		if ( eSpr != null )
			eSpr.spr.anim.update( tmod );
		model.cd.update( tmod );
		model.tw.update( tmod );
	}

	public function update() {
		if ( !model.forceRBCoords ) {
			var stepX = model.dx * tmod;
			if ( stepX != 0 ) model.onMoveInvalidate = true;
			model.footX.val += stepX;
			var stepY = model.dy * tmod;
			if ( stepY != 0 ) model.onMoveInvalidate = true;
			model.footY.val += stepY;
			var stepZ = model.dz * tmod;
			if ( stepZ != 0 ) model.onMoveInvalidate = true;
			model.footZ.val += stepZ;
		}
		model.dx *= Math.pow( model.frict, tmod );
		if ( M.fabs( model.dx ) <= 0.0005 * tmod ) model.dx = 0;
		model.dy *= Math.pow( model.frict, tmod );
		if ( M.fabs( model.dy ) <= 0.0005 * tmod ) model.dy = 0;
		model.dz *= Math.pow( model.frict, tmod );
		if ( M.fabs( model.dz ) <= 0.0005 * tmod ) model.dz = 0;

		if ( model.forceRBCoords ) {
			model.onMoveInvalidate = true;
			model.forceRBCoords = false;
			model.footX.val = model.rigidBody._transform._positionX;
			model.footY.val = model.rigidBody._transform._positionY;
			model.footZ.val = model.rigidBody._transform._positionZ;
		}

		if ( model.onMoveInvalidate ) onMove.dispatch();
	}

	public function postUpdate() {}

	public function frameEnd() {
		if ( eSpr != null ) {
			eSpr.drawFrame();
		}
	}
}
