package en.spr;

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
	public var pivot : { x : Float, y : Float };
	public var drawToBoolStack : BoolList = new BoolList();

	@:allow( en.Entity )
	private var tex : Texture;
	private var texTile : Tile;

	var debugObjs : Array<h3d.scene.Object> = [];

	var entity : Entity;

	public function new( entity : Entity, lib : SpriteLib, ?group : String, parent : Object ) {
		this.entity = entity;

		pivot = { x : 0, y : 0 };

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

		mesh.material.mainPass.setBlendMode( Alpha );

		var s = mesh.material.mainPass.addShader( new h3d.shader.ColorAdd() );
		s.color = colorAdd;
		mesh.material.mainPass.enableLights = false;
		mesh.material.mainPass.depth( false, Less );
		mesh.material.mainPass.addShader( new DepthOffset( 0.001 ) );

		if ( entity.tmxObj != null && entity.tmxObj.flippedVertically ) spr.scaleY = -1;

		#if depth_debug
		mesh.renewDebugPts();
		#end
	}

	public function refreshForceDrawCheck() {
		forceDrawTo = drawToBoolStack.computeOr();
	}

	public function drawFrame() {
		@:privateAccess
		var bounds = mesh.plane.getBounds();

		bounds.xMax = spr.tile.width + entity.footX.val;
		bounds.xMin = entity.footX.val;

		var needForDraw = GameClient.inst.camera.s3dCam.frustum.hasBounds( bounds );

		if ( !needForDraw ) {
			mesh.culled = true;
			mesh.visible = false;
			spr.visible = false;
		} else {
			mesh.culled = false;
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
				mesh.tile = texTile;
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
	}

	/** generate nickname text **/
	public function initTextLabel( displayText : String ) {
		var nicknameLabel = new TextLabelComp( displayText, Assets.fontPixel );
		@:privateAccess nicknameLabel.sync( Boot.inst.s2d.ctx );

		var nicknameTex = new Texture( nicknameLabel.outerWidth + 20, nicknameLabel.outerHeight, [Target] );

		nicknameLabel.drawTo( nicknameTex );
		var nicknameMesh = new TileSprite( Tile.fromTexture( nicknameTex ), false, mesh );
		nicknameMesh.material.mainPass.setBlendMode( AlphaAdd );
		nicknameMesh.material.mainPass.enableLights = false;
		nicknameMesh.material.mainPass.depth( false, LessEqual );
		nicknameMesh.scale( .5 );
		nicknameMesh.z += 40;
		nicknameMesh.y += 1;
		@:privateAccess nicknameMesh.plane.ox = (-nicknameLabel.outerWidth >> 1 ) + 2;
	}

	/** update debug centers and colliders poly**/
	public function updateDebugDisplay() {
		#if entity_centers_debug
		var sphere = new Sphere( 0x5640d4, 1, false, mesh );
		sphere.material.mainPass.wireframe = true;
		sphere.material.shadows = false;
		sphere.material.mainPass.depth( true, Less );
		sphere.x = 0.25;
		debugObjs.push( sphere );
		#end

		#if colliders_debug
		Level.inst.oimoDebug.registerEntity( entity );
		#end
	}
}
