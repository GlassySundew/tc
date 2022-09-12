package en.util;

import game.client.GameClient;
import game.server.GameServer;
import hxGeomAlgo.HxPoint;
import hxGeomAlgo.PoleOfInaccessibility;
import utils.TmxUtils;

class EntityUtil {

	public static function serverApplyTmx( ent : Entity ) {
		if ( GameServer.inst != null )
			TmxUtils.calculateCoordinateOffset( ent );
	}

	public static function clientApplyTmx( ent : Entity ) {
		if ( GameClient.inst != null ) {
			TmxUtils.applyTmxObjectOnEntity( ent );
			ent.tmxAppliedInvalidate = true;
			refreshPivot( ent );
		}
	}

	public static function refreshPivot( ent : Entity ) {
		ent.eSpr.pivotChanged = true;
		if ( ent.eSpr.spr != null )
			ent.eSpr.spr.pivot.setCenterRatio( ent.eSpr.pivot.x / ent.tmxObj.width, ent.eSpr.pivot.y / ent.tmxObj.height );
	}

	/** Flips spr.scaleX, all of collision objects, and sorting rectangle **/
	public static function flipX( ent : Entity ) {
		ent.flippedX = !ent.flippedX;

		ent.footX.val += ( ( 1 - ent.eSpr.pivot.x / ent.tmxObj.width * 2 ) * ent.tmxObj.width );

		ent.clientFlipX();
	}

	public inline static function clientFlipX( ent : Entity ) {
		if ( !ent.tmxAppliedInvalidate ) return;

		ent.eSpr.pivot.x = ent.tmxObj.width - ent.eSpr.pivot.x;
		refreshPivot( ent );

		ent.eSpr.spr.scaleX *= -1;

		if ( ent.eSpr.mesh.isLong ) ent.eSpr.mesh.flipX();
		ent.eSpr.mesh.renewDebugPts();
		ent.eSpr.refreshTile = true;
		ent.flippedOnClient = ent.flippedX;

		#if entity_centers_debug
		Main.inst.delayer.addF(() -> {
			ent.eSpr.updateDebugDisplay();
		}, 10 );
		#end
	}

	public static inline function distPx( self : Entity, e : Entity ) {
		return M.dist( self.footX.val, self.footY.val, e.footX.val, e.footY.val );
	}

	public static inline function distPxFree( self : Entity, x : Float, y : Float ) {
		return M.dist( self.footX.val, self.footY.val, x, y );
	}

	/**
		подразумевается, что у этой сущности есть длинный изометрический меш
	**/
	public static function distPolyToPt( self : Entity, e : Entity ) : Float {
		if ( self.eSpr.mesh == null || !self.eSpr.mesh.isLong )
			return distPx( self, e );
		else {

			var verts = self.eSpr.mesh.getIsoVerts();
			var mesh = self.eSpr.mesh;

			var pt1 = new HxPoint( self.footX.val + mesh.xOff + verts.up.x, self.footY.val + mesh.yOff + verts.up.y );
			var pt2 = new HxPoint( self.footX.val + mesh.xOff + verts.right.x, self.footY.val + mesh.yOff + verts.right.y );
			var pt3 = new HxPoint( self.footX.val + mesh.xOff + verts.down.x, self.footY.val + mesh.yOff + verts.down.y );
			var pt4 = new HxPoint( self.footX.val + mesh.xOff + verts.left.x, self.footY.val + mesh.yOff + verts.left.y );

			var dist = PoleOfInaccessibility.pointToPolygonDist( e.footX.val, e.footY.val, [[pt1, pt2, pt3, pt4]] );
			return -dist;
		}
	}

	public static function offsetFootByCenter( ent : Entity ) {
		var spr = ent.eSpr.spr;
		ent.footX.val += ( ( spr.pivot.centerFactorX - .5 ) * spr.tile.width );
		ent.footY.val -= ( spr.pivot.centerFactorY ) * spr.tile.height - spr.tile.height;
	}

	// used by blueprints, to preview entities
	public static function offsetFootByCenterReversed( ent : Entity ) {
		var spr = ent.eSpr.spr;
		ent.footX.val -= ( ( spr.pivot.centerFactorX - .5 ) * spr.tile.width );
		ent.footY.val += ( spr.pivot.centerFactorY ) * spr.tile.height - spr.tile.height;
	}

	// used by save manager, when saved objects are already offset by center
	public static function offsetFootByCenterXReversed( ent : Entity ) {
		var spr = ent.eSpr.spr;
		ent.footX.val += ( ( spr.pivot.centerFactorX - .5 ) * spr.tile.width );
		ent.footY.val += ( spr.pivot.centerFactorY ) * spr.tile.height - spr.tile.height;
	}

	
}
