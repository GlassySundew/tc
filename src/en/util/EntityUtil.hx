package en.util;

import oimo.common.Vec3;
import dn.M;
import game.client.GameClient;
import game.server.GameServer;
import hxGeomAlgo.HxPoint;
import hxGeomAlgo.PoleOfInaccessibility;
import util.TmxUtils;
import format.tmx.Data;

@:structInit
class EntityTmxData {

	@:optional public var obj : TmxObject;
	@:optional public var tsTile : TmxTilesetTile;
}

class EntityUtil {

	public static function serverApplyTmx( ent : Entity ) {
		if ( GameServer.inst != null )
			TmxUtils.calculateCoordinateOffset( ent );
	}

	public static function clientApplyTmx( ent : Entity ) {
		if ( GameClient.inst != null ) {
			TmxUtils.applyTmxObjectOnEntity( ent );
			ent.model.tmxAppliedInvalidate = true;
			refreshPivot( ent );

			if ( ent.model.flippedX && ent.model.flippedOnClient ) ent.clientFlipX();

			#if debug
			if ( ent.eSpr != null )
				ent.eSpr.updateDebugDisplay();
			#end

			if ( ent.model.rigidBody != null ) {
				ent.model.contactCb = new en.collide.EntityContactCallback();
				var shape = ent.model.rigidBody._shapeList;
				while( shape != null ) {
					shape._contactCallback = ent.model.contactCb;
					shape = shape._next;
				}
				ent.model.rigidBody.setPosition(
					new Vec3(
						ent.model.footX.val,
						ent.model.footY.val,
						ent.model.footZ.val
					)
				);

				ent.onMove.add(() -> {
					if ( ent.model.rigidBody != null ) {
						ent.model.rigidBody.wakeUp();
					}
				} );
			}

			ent.onMove.dispatch();
		}
	}

	public static inline function angTo( ethis : Entity, e : Entity )
		return Math.atan2( e.model.footY.val - ethis.model.footY.val, e.model.footX.val - ethis.model.footX.val );

	public static inline function angToPxFree( ent : Entity, x : Float, y : Float )
		return Math.atan2( y - ent.model.footY.val, x - ent.model.footX.val );

	public static function refreshPivot( ent : Entity ) {
		ent.eSpr.pivotChanged = true;
		if ( ent.eSpr.spr != null )
			ent.eSpr.spr.pivot.setCenterRatio(
				ent.eSpr.pivot.x / ent.model.tmxObj.width,
				ent.eSpr.pivot.y / ent.model.tmxObj.height
			);
	}

	/** Flips spr.scaleX, all of collision objects, and sorting rectangle **/
	public static function flipX( ent : Entity ) {
		ent.model.flippedX = !ent.model.flippedX;

		ent.model.footX.val += ( ( 1 - ent.eSpr.pivot.x / ent.model.tmxObj.width * 2 ) * ent.model.tmxObj.width );

		ent.clientFlipX();
	}

	public inline static function clientFlipX( ent : Entity ) {
		if ( !ent.model.tmxAppliedInvalidate ) return;

		ent.eSpr.pivot.x = ent.model.tmxObj.width - ent.eSpr.pivot.x;
		refreshPivot( ent );

		ent.eSpr.spr.scaleX *= -1;

		if ( ent.eSpr.mesh.isLong ) ent.eSpr.mesh.flipX();
		ent.eSpr.mesh.renewDebugPts();
		ent.eSpr.refreshTile = true;
		ent.model.flippedOnClient = ent.model.flippedX;

		#if entity_centers_debug
		Main.inst.delayer.addF(() -> {
			ent.eSpr.updateDebugDisplay();
		}, 10 );
		#end
	}

	public static inline function distPx( self : Entity, e : Entity ) {
		return M.dist(
			self.model.footX.val,
			self.model.footY.val,
			e.model.footX.val,
			e.model.footY.val );
	}

	public static inline function distPxFree( self : Entity, x : Float, y : Float ) {
		return M.dist(
			self.model.footX.val,
			self.model.footY.val,
			x,
			y
		);
	}

	/**
		подразумевается, что у этой сущности есть длинный изометрический меш
	**/
	public static function distPolyToPt( self : Entity, e : Entity ) : Float {
		return distPx( self, e );
	}

	public static function offsetFootByCenter( ent : Entity ) {
		var spr = ent.eSpr.spr;
		ent.model.footX.val += ( ( spr.pivot.centerFactorX - .5 ) * spr.tile.width );
		ent.model.footY.val -= ( spr.pivot.centerFactorY ) * spr.tile.height - spr.tile.height;
	}

	// used by blueprints, to preview entities
	public static function offsetFootByCenterReversed( ent : Entity ) {
		var spr = ent.eSpr.spr;
		ent.model.footX.val -= ( ( spr.pivot.centerFactorX - .5 ) * spr.tile.width );
		ent.model.footY.val += ( spr.pivot.centerFactorY ) * spr.tile.height - spr.tile.height;
	}

	// used by save manager, when saved objects are already offset by center
	public static function offsetFootByCenterXReversed( ent : Entity ) {
		var spr = ent.eSpr.spr;
		ent.model.footX.val += ( ( spr.pivot.centerFactorX - .5 ) * spr.tile.width );
		ent.model.footY.val += ( spr.pivot.centerFactorY ) * spr.tile.height - spr.tile.height;
	}
}
