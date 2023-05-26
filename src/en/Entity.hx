package en;

import game.server.level.Chunk;
import core.ClassMap;
import i.IDestroyable;
import en.comp.controller.EntityController;
import net.NSArray;
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
import net.NSVO;
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

	/**
		client
	**/
	public var components = //
		new ClassMap<Class<EntityController>, EntityController>();

	@:s public var model : EntityModel = new EntityModel();

	public var clientConfig : EntityTmxDataParser;

	public var eSpr : EntityView;
	public var destroyed( default, null ) = false;

	public var onFrame : EventSignal0 = new EventSignal0();
	public var onMove : EventSignal0 = new EventSignal0();

	public var tmod( get, never ) : Float;

	inline function get_tmod() {
		return
			#if headless GameServer.inst.tmod; #else //
			if ( GameClient.inst != null ) GameClient.inst.tmod else
				Client.inst.tmod; #end
	}

	public var isMoving( get, never ) : Bool;

	inline function get_isMoving()
		return M.fabs( model.dx ) >= 0.01 || M.fabs( model.dy ) >= 0.01;

	public function new( ?tmxObj : Null<TmxObject> ) {

		ServerALL.push( this );

		if ( model.tmxObj == null && tmxObj != null ) {
			model.tmxObj = tmxObj;
		}

		super();
	}

	public override function init() {
		super.init();
		model.footX.addOnVal(
			( oldVal ) -> if ( M.fabs( model.footX.val - oldVal ) > 0 )
				model.onMoveInvalidate = true
		);
		model.footY.addOnVal(
			( oldVal ) -> if ( M.fabs( model.footY.val - oldVal ) > 0 ) {
				model.onMoveInvalidate = true;
			}
		);
		model.footZ.addOnVal(
			( oldVal ) -> if ( M.fabs( model.footZ.val - oldVal ) > 0 )
				model.onMoveInvalidate = true
		);
	}

	/**
		called only on client-side when
		replicating entity over network on client side
	**/
	public override function alive() {
		super.alive();
		ALL.push( this );

		clientConfig = EntityTmxDataParser.fromTsTile( model.tsTile );

		Main.inst.delayer.addF(() -> {
			// Main.inst.clientController.level.onAppear(  );
			createView();
			applyTmx();
		}, 1 );
	}

	/** to be overriden **/
	function createView() {}

	function applyTmx( ?v ) {
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

	public function dropItem(
		item : en.Item,
		?angle : Float,
		?power : Float
	) : en.Item {
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

	public inline function bumpAwayFrom(
		e : Entity,
		spd : Float,
		?spdZ = 0.,
		?ignoreReduction = false
	) {
		var a = e.angTo( this );
		bump( Math.cos( a ) * spd, Math.sin( a ) * spd, spdZ, ignoreReduction );
	}

	public function bump(
		x : Float,
		y : Float,
		z : Float,
		?ignoreReduction = false
	) {
		var f = ignoreReduction ? 1.0 : 1 - model.bumpReduction;
		model.dx += x * f;
		model.dy += y * f;
		model.dz += z * f;
	}

	public function cancelVelocities() {
		model.dx = model.dx = 0;
		model.dy = model.dy = 0;
	}

	@:rpc
	public function destroy() {
		trace( "destroying " + this );

		if ( !destroyed ) {
			destroyed = true;
			GC.push( this );
		}
	}

	override function disconnect(
		host : NetworkHost,
		ctx : NetworkSerializer,
		?finalize : Bool
	) {
		if ( finalize ) model.level.entities.remove( this );
		super.disconnect( host, ctx, finalize );
	}

	@:allow( game.client.GameClient, game.server.GameServer )
	function dispose() {
		destroyed = true;
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
		host.unregister( model.footX, ctx, finalize );
		host.unregister( model.footY, ctx, finalize );
	}

	public function headlessPreUpdate() {}

	public function headlessUpdate() {
		onFrame.dispatch();
	}

	public function headlessPostUpdate() {
		if ( model.onMoveInvalidate ) {
			onMove.dispatch();
			model.onMoveInvalidate = false;
		}
	}

	public function headlessFrameEnd() {}

	public function preUpdate() {
		if ( eSpr != null )
			eSpr.spr.anim.update( tmod );
		model.cd.update( tmod );
		model.tw.update( tmod );
	}

	public function update() {
		if ( model.forceRBCoords ) {
			model.forceRBCoords = false;
			model.footX.val = model.rigidBody._transform._positionX;
			model.footY.val = model.rigidBody._transform._positionY;
			model.footZ.val = model.rigidBody._transform._positionZ;
		} else {
			var stepX = model.dx * tmod;
			model.footX.val += stepX;

			var stepY = model.dy * tmod;
			model.footY.val += stepY;

			var stepZ = model.dz * tmod;
			model.footZ.val += stepZ;
		}
	}

	public function postUpdate() {
		model.dx *= Math.pow( model.frict, tmod );
		if ( M.fabs( model.dx ) <= 0.0005 * tmod ) model.dx = 0;
		model.dy *= Math.pow( model.frict, tmod );
		if ( M.fabs( model.dy ) <= 0.0005 * tmod ) model.dy = 0;
		model.dz *= Math.pow( model.frict, tmod );
		if ( M.fabs( model.dz ) <= 0.0005 * tmod ) model.dz = 0;

		if ( model.onMoveInvalidate ) {
			onMove.dispatch();
			model.onMoveInvalidate = false;
		}
	}

	public function frameEnd() {
		if ( eSpr != null ) {
			eSpr.drawFrame();
		}
	}
}
