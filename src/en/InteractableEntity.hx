package en;

import en.player.Player;
import format.tmx.Data.TmxObject;
import h2d.Object;
import h2d.filter.Glow;
import h3d.col.Point;
import h3d.prim.Polygon;
import h3d.scene.Mesh;
import hxGeomAlgo.EarCut;
import hxGeomAlgo.HxPoint;
import hxGeomAlgo.MarchingSquares;
import hxGeomAlgo.PolyTools.Tri;
import hxPixels.Pixels;
import hxd.IndexBuffer;
import ui.player.ButtonIcon;
import ui.s3d.EventInteractive;

/**
	An interactive entity
**/
class InteractableEntity extends Entity {

	public var interact : EventInteractive;
	public var interactable( default, set ) : Bool = false;

	inline function set_interactable( v : Bool ) {
		if ( !v ) {
			turnOffHighlight();
			if ( buttonIcon != null ) buttonIcon.dispose();
			if ( interact != null ) interact.cursor = Default;
		}
		return interactable = v;
	}

	public var useRange : Float = Const.DEF_USE_RANGE;

	var highlightingColor : String;
	var polyPrim : Polygon;
	var buttonIcon : ButtonIcon;
	var filter : Glow;
	var idx : IndexBuffer;
	var translatedPoints : Array<Point> = [];
	var polygonized : Array<Tri>;
	var points : Array<HxPoint>;
	var doHighlight : Bool = true;

	function new( x = 0., y = 0., z = 0., ?tmxObj : TmxObject ) {
		super( x, y, z, tmxObj );
	}

	public override function init( x = 0., y = 0., z = 0., ?tmxObj : TmxObject ) {
		super.init( x, y, z, tmxObj );
	}

	override function alive() {
		super.alive();

		var pixels = Pixels.fromBytes( eSpr.tex.capturePixels().bytes, Std.int( eSpr.spr.tile.width ), Std.int( eSpr.spr.tile.height ) );
		points = new MarchingSquares( pixels ).march();
		polygonized = ( EarCut.triangulate( points ) );

		for ( i in polygonized ) for ( j in i ) translatedPoints.push( new Point( j.x, 0, j.y ) );

		idx = new IndexBuffer();
		for ( poly in 0...polygonized.length ) {
			idx.push( findVertexNumberInArray( polygonized[poly][0], translatedPoints ) );
			idx.push( findVertexNumberInArray( polygonized[poly][1], translatedPoints ) );
			idx.push( findVertexNumberInArray( polygonized[poly][2], translatedPoints ) );
		}

		polyPrim = new Polygon( translatedPoints, idx );
		interact = new EventInteractive( polyPrim.getCollider(), eSpr.mesh );

		interact.rotate( -0.01, hxd.Math.degToRad( 180 ), hxd.Math.degToRad( 90 ) );

		if ( tmxObj != null && tmxObj.flippedHorizontally ) interact.scaleX = -1;

		// var highlightColor = (try tmxTile.properties.get("highlight") catch (e:Dynamic) "ffffffff");
		var highlightColor = null;
		if ( highlightColor == null ) highlightColor = "ffffffff";

		filter = new h2d.filter.Glow( Color.hexToInt( highlightingColor != null ? highlightingColor : highlightColor ), 1.2, 4, 1, 1.5, true );

		Main.inst.delayer.addF(() -> {
			rebuildInteract();

			#if interactive_debug
			debugInteract();
			#end
		}, 10 );
	}

	function debugInteract() {
		polyPrim.addUVs();
		polyPrim.addNormals();

		var isoDebugMesh = new Mesh( polyPrim, interact );
		// isoDebugMesh.rotate(0, M.toRad(180), M.toRad(90));
		isoDebugMesh.material.color.setColor( 0xc09900 );
		isoDebugMesh.material.shadows = false;
		isoDebugMesh.material.mainPass.wireframe = true;
		isoDebugMesh.material.mainPass.depth( true, Less );

		isoDebugMesh.y = -.5;
	}

	/**only x flipping is supported yet**/
	public function rebuildInteract() {
		@:privateAccess polyPrim.translate(-polyPrim.translatedX, 0, -polyPrim.translatedZ );
		interact.scaleX = eSpr.spr.scaleX;
		var facX = ( flippedX ) ? 1 - eSpr.spr.pivot.centerFactorX : eSpr.spr.pivot.centerFactorX;
		polyPrim.translate(-eSpr.spr.tile.width * facX, 0, -eSpr.spr.tile.height * eSpr.spr.pivot.centerFactorY );
		interact.shape = polyPrim.getCollider();
	}

	public function turnOnHighlight() {
		if ( cd != null ) {
			eSpr.spr.filter = filter;
			eSpr.forceDrawTo = true;
			filter.enable = true;
			cd.setS( "keyboardIconInit", .4 );
			cd.setS( "interacted", Const.INFINITE );
		}
	}

	public function turnOffHighlight() {
		if ( cd != null ) {
			cd.unset( "interacted" );
			eSpr.forceDrawTo = false;
			eSpr.spr.filter = null;
			filter.enable = false;
			if ( buttonIcon != null ) buttonIcon.dispose();
		}
	}

	function updateKeyIcon() {
		if ( !cd.has( "keyboardIconInit" ) && cd.has( "interacted" ) ) {
			var pos = Boot.inst.s3d.camera.project( eSpr.mesh.x, 0, eSpr.mesh.z, wScaled, hScaled );
			cd.unset( "interacted" );
			buttonIcon = new ButtonIcon( pos.x, pos.y );
			tw.createS( buttonIcon.container.icon.alpha, 0 > 1, TEaseIn, .4 );
		}
		if ( buttonIcon != null ) {
			var pos = Boot.inst.s3d.camera.project( eSpr.mesh.x, 0, eSpr.mesh.z, wScaled, hScaled );

			buttonIcon.centerFlow.x = pos.x - 1;
			buttonIcon.centerFlow.y = pos.y - 100 / Const.UI_SCALE;

			buttonIcon.container.icon.tile = buttonIcon.buttonSpr.tile;
		}
	}

	function findVertexNumberInArray( point : Dynamic, findIn : Array<Point> ) : Int {
		for ( pts in 0...findIn.length ) {
			if ( point.x == findIn[pts].x && point.y == findIn[pts].z ) return pts;
		}
		throw "Not part of this array";
	}

	override function clientFlipX() {
		super.clientFlipX();

		if ( eSpr.spr != null ) {
			rebuildInteract();
		}
	}

	override function dispose() {
		super.dispose();

		interact.remove();
		buttonIcon.remove();
		filter = null;
		polyPrim.dispose();
	}
}
