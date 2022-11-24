package en.spr;

import utils.Util;
import utils.Const;
import dn.heaps.slib.SpriteLib;
import dn.heaps.slib.HSprite;
import shader.Perpendicularizer;
import h3d.shader.BaseMesh;
import shader.PlaneDepthNarrower;
import h3d.col.Point;
import ch3.scene.TileSprite;
import en.objs.IsoTileSpr;
import game.client.GameClient;
import game.client.level.Level;
import h2d.Bitmap;
import h2d.Object;
import h2d.Tile;
import h3d.mat.Texture;
import h3d.scene.Sphere;
import shader.DepthOffset;
import ui.domkit.TextLabelComp;
import utils.Assets;
import utils.BoolList;

class EntitySprite {

	public var colorAdd : h3d.Vector;
	public var spr : HSprite;
	public var mesh : IsoTileSpr;
	public var tmpDt : Float;
	public var tmpCur : Float;
	public var curFrame : Float = 0;
	public var pivotChanged = true;

	public var depthOffset : DepthOffset;
	public var perpendicularizer : Perpendicularizer;

	/**
		из-за того, что метод отрисовки, который я добавил в том виде, какой он есть 
		(тайл из spr просто передаётся в mesh ), всякие эффекты и шейдеры не будут 
		работать если forceDrawTo не будет true (спрайт будет рисоваться через spr.drawTo())
	**/
	public var forceDrawTo : Bool = false;
	public var refreshTile : Bool = false;

	/**
		реальный x и y центра спрайта, не в процентах
	**/
	public var pivot : {
		x : Float,
		y : Float
	};
	public var drawToBoolStack : BoolList = new BoolList();

	@:allow( en.Entity )
	private var tex : Texture;
	private var texTile : Tile;
	private var nicknameLabel : TextLabelComp;

	var debugObjs : Array<h3d.scene.Object> = [];

	var entity : Entity;

	public function new( entity : Entity, lib : SpriteLib, parent : Object, ?group : String ) {
		this.entity = entity;

		pivot = { x : 0., y : 0. };

		colorAdd = new h3d.Vector();
		spr = new HSprite( lib, group, parent );
		init();
		refreshForceDrawCheck();
		drawToBoolStack.onLambdasChanged = refreshForceDrawCheck;
	}

	function init() {
		spr.colorAdd = colorAdd;

		tex = new Texture( Std.int( entity.tmxObj.width ), Std.int( entity.tmxObj.height ), [Target] );

		spr.blendMode = Alpha;

		texTile = Tile.fromTexture( tex );

		mesh = new IsoTileSpr( texTile, true, Boot.inst.s3d );

		var s = mesh.material.mainPass.addShader( new h3d.shader.ColorAdd() );
		s.color = colorAdd;

		mesh.material.shadows = false;
		mesh.material.mainPass.enableLights = false;
		mesh.material.mainPass.setBlendMode( Alpha );
		mesh.material.mainPass.depth( false, LessEqual );

		perpendicularizer = new shader.Perpendicularizer();
		mesh.material.mainPass.addShader( perpendicularizer );
		depthOffset = new DepthOffset( 0.1 * entity.tmxObj.height );
		mesh.material.mainPass.addShader( depthOffset );

		if ( entity.tmxObj != null && entity.tmxObj.flippedVertically ) spr.scaleY = -1;

		#if depth_debug
		mesh.renewDebugPts();
		#end
	}

	public inline function setSprGroup( ?l : SpriteLib, ?g : String, ?frame = 0, ?stopAllAnims = false ) {
		inline spr.set( l, g, frame, stopAllAnims );
		spr.drawTo( tex );
	}

	public function refreshForceDrawCheck() {
		forceDrawTo = drawToBoolStack.computeOr();
	}

	public function drawFrame() {
		@:privateAccess var bounds = mesh.plane.getBounds();
		bounds.addPos( entity.footX, entity.footY, entity.footZ );
		var needForDraw = true;
		// var needForDraw = GameClient.inst.camera.s3dCam.frustum.hasBounds( bounds );

		if ( !needForDraw ) {
			mesh.visible = false;
			spr.visible = false;
		} else {
			mesh.visible = true;
			spr.visible = true;

			if ( pivotChanged ) {
				spr.x = spr.scaleX > 0 ? -spr.tile.dx : spr.tile.dx + spr.tile.width;
				spr.y = spr.scaleY > 0 ? -spr.tile.dy : spr.tile.dy + spr.tile.height;
				pivotChanged = false;
				refreshTile = true;
			}

			if ( forceDrawTo ) {
				tex.clear( 0, 0 );
				spr.drawTo( tex );
				texTile.setCenterRatio( spr.pivot.centerFactorX, spr.pivot.centerFactorY );
				// mesh.tile = texTile;
			} else {
				@:privateAccess
				if ( refreshTile
					|| ( spr.tile.u != mesh.plane.u0 && spr.tile.u != mesh.plane.u1 )
					|| ( spr.tile.u2 != mesh.plane.u1 && spr.tile.u2 != mesh.plane.u0 )
					|| spr.tile.v != mesh.plane.v0
					|| spr.tile.v2 != mesh.plane.v1 ) {

					mesh.tile = spr.tile;

					if ( entity.flippedX ) {
						var tmp = mesh.plane.u1;
						mesh.plane.u1 = mesh.plane.u0;
						mesh.plane.u0 = tmp;
						mesh.plane.invalidate();
					}

					refreshTile = false;
				}
			}

			mesh.x = entity.footX.val;
			mesh.y = entity.footY.val;
			mesh.z = entity.footZ.val;

			mesh.material.texture.filter = Nearest;
		}
	}

	public function destroy() {
		spr.remove();

		if ( mesh != null ) {
			mesh.tile.dispose();
			mesh.primitive.dispose();
			mesh.remove();
		}
		for ( i in debugObjs ) i.remove();

		tex.dispose();
		if ( nicknameLabel != null ) {}
	}

	/** generate nickname text **/
	public function initTextLabel( displayText : String ) {
		nicknameLabel = new TextLabelComp( displayText, Assets.fontPixel );
		GameClient.inst.root.add( nicknameLabel, Const.DP_UI_NICKNAMES );
		nicknameLabel.scale( 1 / Const.UI_SCALE );
		entity.onMove.add( refreshNicknameLabel );
		GameClient.inst.cameraProc.camera.onMove.add( refreshNicknameLabel );
		entity.onMove.dispatch();
	}

	function refreshNicknameLabel() {
		if ( nicknameLabel != null ) {
			var entityPt = GameClient.inst.cameraProc.camera.s3dCam.project(
				entity.footX.val,
				entity.footY.val,
				entity.footZ.val + entity.tmxObj.height,
				// entity.footZ.val + pivot.y,
				Util.wScaled,
				Util.hScaled,
				false
			);

			nicknameLabel.x = entityPt.x - nicknameLabel.outerWidth / 2 / Const.UI_SCALE;
			nicknameLabel.y = entityPt.y;
		}
	}

	/** update debug centers and colliders poly**/
	public function updateDebugDisplay() {
		#if entity_centers_debug
		var sphere = new Sphere( 0xf12106, 1, false, mesh );
		sphere.material.mainPass.wireframe = true;
		sphere.material.shadows = false;
		sphere.material.mainPass.depth( true, Less );
		sphere.material.mainPass.addShader( depthOffset );
		debugObjs.push( sphere );
		#end

		#if colliders_debug
		Level.inst.oimoDebug.registerEntity( entity );
		#end
	}
}
