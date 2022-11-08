package en;

import dn.M;
import utils.Const;
import game.server.GameServer;
import dn.Tweenie;
import oimo.common.Vec3;
import cherry.soup.EventSignal.EventSignal0;
import cherry.soup.EventSignal.EventSignal1;
import en.collide.EntityContactCallback;
import en.spr.EntitySprite;
import en.util.Direction;
import en.util.EntityUtil;
import format.tmx.Data.TmxObject;
import game.client.GameClient;
import game.server.ServerLevel;
import hxbit.NetworkHost;
import hxbit.NetworkSerializable;
import net.Client;
import net.PrimNS;
import oimo.dynamics.rigidbody.RigidBody;
import ui.core.InventoryGrid;
import utils.tools.Save;

@:keep
class Entity implements NetworkSerializable {

	public static var ALL : Array<Entity> = [];
	public static var ServerALL : Array<Entity> = [];

	public static var GC : Array<Entity> = [];

	@:s public var level( default, set ) : ServerLevel;
	@:s public var dir( default, set ) : Direction;
	@:s public var footX : PrimNS<Float>;
	@:s public var footY : PrimNS<Float>;
	@:s public var footZ : PrimNS<Float>;
	@:s public var tmxObj : TmxObject;
	@:s public var flippedX : Bool;
	@:s public var inventory : InventoryGrid;

	public var rigidBody( default, set ) : RigidBody;

	function set_rigidBody( rb : RigidBody ) : RigidBody {
		return rigidBody = rb;
	}

	public var contactCb : EntityContactCallback;

	function set_level( v : ServerLevel ) {
		return level = v;
	}

	public var destroyed( default, null ) = false;
	public var tmod( get, never ) : Float;

	public var dx = 0.;
	public var dy = 0.;
	public var dz = 0.;

	public var frict = 0.62;
	public var gravity = 0.02;
	public var bumpFrict = 0.93;
	public var bumpReduction = 0.;

	inline function set_dir( v : Direction ) {
		if ( v != dir ) onDirChangedSignal.dispatch( v );

		return dir = v;
	}

	inline function get_tmod() {
		return #if headless GameServer.inst.tmod #else if ( GameClient.inst != null ) GameClient.inst.tmod else
			Client.inst.tmod #end;
	}

	public var sqlId : Null<Int>;

	public var eSpr : EntitySprite;

	public var cd : dn.Cooldown;
	public var tw : Tweenie;

	public static var isoCoefficient = 1.2;

	public var cellFlowGrid : InventoryCellFlowGrid;
	public var tmxAppliedInvalidate = false;

	public var flippedOnClient = false;

	public var onDirChangedSignal : EventSignal1<Direction> = new EventSignal1();
	public var onMove : EventSignal0 = new EventSignal0();

	var onMoveInvalidate = false;

	public function new( x = 0., y = 0., z = 0., ?tmxObj : Null<TmxObject>, ?tmxGId : Null<Int> ) {
		ServerALL.push( this );

		footX = new PrimNS( x );
		footY = new PrimNS( y );
		footZ = new PrimNS( z );
		dir = Bottom;
		flippedX = false;

		if ( this.tmxObj == null && tmxObj != null ) {
			this.tmxObj = tmxObj;
		}

		init( x, z, tmxObj );
	}

	public function init( x = 0., y = 0., z = 0., ?tmxObj : Null<TmxObject> ) {
		enableAutoReplication = true;

		cd = new dn.Cooldown( Const.FPS );
		onMove.add(() -> onMoveInvalidate = false );
		tw = new Tweenie( Const.FPS );
	}

	/**
		called only on client-side when replicating entity over network on client side
	**/
	public function alive() {
		init();
		ALL.push( this );
		EntityUtil.refreshPivot( this );

		Main.inst.delayer.addF(() -> {
			// ждём пока придёт уровень с сервера
			if ( Main.inst.clientController.level == null ) {
				GameClient.inst.onLevelChanged.add( applyTmx, true );
			} else applyTmx();
		}, 1 );
	}

	function applyTmx() {
		EntityUtil.clientApplyTmx( this );
		if ( flippedX && flippedOnClient ) clientFlipX();

		#if debug
		if ( eSpr != null )
			eSpr.updateDebugDisplay();
		#end

		if ( rigidBody != null ) {
			contactCb = new EntityContactCallback();
			var shape = rigidBody._shapeList;
			while( shape != null ) {
				shape._contactCallback = contactCb;
				shape = shape._next;
			}
			rigidBody.setPosition( new Vec3( footX.val, footY.val, footZ.val ) );

			// setPosition( new Vec3( footX.val, footY.val, footZ.val ) );

			onMove.add(() -> {
				if ( rigidBody != null ) {
					rigidBody.wakeUp();
				}
			} );
		}

		onMove.dispatch();
	}

	public function isOfType<T : Entity>( c : Class<T> ) return Std.isOfType( this, c );

	public function as<T : Entity>( c : Class<T> ) : T return Std.downcast( this, c );

	public inline function angTo( e : Entity )
		return Math.atan2( e.footY.val - footY.val, e.footX.val - footX.val );

	public inline function angToPxFree( x : Float, y : Float )
		return Math.atan2( y - footY.val, x - footX.val );

	public function blink( ?c = 0xffffff ) {
		eSpr.colorAdd.setColor( c );
		cd.setS( "colorMaintain", 0.03 );
	}

	public var isMoving( get, never ) : Bool;

	function get_isMoving() return M.fabs( dx ) >= 0.01 || M.fabs( dy ) >= 0.01;

	public inline function at( x, y ) return footX == x && footY == y;

	public inline function isAlive() {
		return !destroyed;
	}

	public function isLocked() return cd == null ? true : cd.has( "lock" );

	@:rpc
	public function lock( ?ms : Float ) {
		cd.setMs( "lock", ms != null ? ms : 1 / 0 );
	}

	@:rpc
	public function unlock() if ( cd != null ) cd.unset( "lock" );

	public function dropItem( item : en.Item, ?angle : Float, ?power : Float ) : en.Item {
		angle = angle == null ? Math.random() * M.toRad( 360 ) : angle;
		power = power == null ? Math.random() * .04 * 48 + .01 : power;

		var fItem = new FloatingItem( footX.val, footY.val, item );
		fItem.bump( Math.cos( angle ) * power, Math.sin( angle ) * power, 0 );
		fItem.lock( 1000 );
		if ( item.itemSprite != null )
			item.itemSprite.remove();

		return item;
	}

	@:rpc( clients )
	public function clientFlipX() {
		inline EntityUtil.clientFlipX( this );
	}

	public inline function bumpAwayFrom( e : Entity, spd : Float, ?spdZ = 0., ?ignoreReduction = false ) {
		var a = e.angTo( this );
		bump( Math.cos( a ) * spd, Math.sin( a ) * spd, spdZ, ignoreReduction );
	}

	public function bump( x : Float, y : Float, z : Float, ?ignoreReduction = false ) {
		var f = ignoreReduction ? 1.0 : 1 - bumpReduction;
		dx += x * f;
		dy += y * f;
		dz += z * f;
	}

	public function cancelVelocities() {
		dx = dx = 0;
		dy = dy = 0;
	}

	public function destroy() {
		if ( !destroyed ) {
			destroyed = true;
			GC.push( this );
		}
	}

	public function dispose() {
		ALL.remove( this );

		if ( eSpr != null )
			eSpr.destroy();
		cd.dispose();
		tw.destroy();
	}

	@:rpc
	public function setFeetPos( x : Float, y : Float ) {
		footX.val = x;
		footY.val = y;
		if ( rigidBody != null )
			rigidBody._transform.setPosition( new Vec3( footX.val, footY.val, footZ.val ) );
	}

	public function kill( by : Null<Entity> ) {
		Save.inst.removeEntityById( sqlId );
		destroy();
	}

	public function unreg( host : NetworkHost, ctx : NetworkSerializer, ?finalize ) @:privateAccess {
		host.unregister( this, ctx, finalize );
		host.unregister( footX, ctx, finalize );
		host.unregister( footY, ctx, finalize );
		if ( inventory != null )
			inventory.unreg( host, ctx, finalize );
	}

	public function headlessPreUpdate() {}

	public function headlessUpdate() {}

	public function headlessPostUpdate() {}

	public function headlessFrameEnd() {}

	public function preUpdate() {
		eSpr.spr.anim.update( tmod );
		cd.update( tmod );
		tw.update( tmod );
	}

	public function update() {

		var stepX = dx * tmod;
		if ( stepX != 0 ) onMoveInvalidate = true;
		footX.val += stepX;
		dx *= Math.pow( frict, tmod );
		if ( M.fabs( dx ) <= 0.0005 * tmod ) dx = 0;

		var stepY = dy * tmod;
		if ( stepY != 0 ) onMoveInvalidate = true;
		footY.val += stepY;
		dy *= Math.pow( frict, tmod );
		if ( M.fabs( dy ) <= 0.0005 * tmod ) dy = 0;

		var stepZ = dz * tmod;
		if ( stepZ != 0 ) onMoveInvalidate = true;
		footZ.val += stepZ;
		dz *= Math.pow( frict, tmod );
		if ( M.fabs( dz ) <= 0.0005 * tmod ) dz = 0;

		if ( onMoveInvalidate ) onMove.dispatch();
	}

	public function postUpdate() {}

	public function frameEnd() {
		if ( eSpr != null ) {
			eSpr.drawFrame();
		}
	}
}
