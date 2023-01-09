package game.client.level;

import cherry.soup.EventSignal.EventSignal0;
import dn.Process;
import en.objs.IsoTileSpr;
import format.tmx.*;
import format.tmx.Data;
import h3d.mat.Texture;
import h3d.scene.Interactive;
import i.IDestroyable;
import oimo.common.Vec3;
import oimo.dynamics.World;
import util.oimo.OimoDebugRenderer;

using util.TmxUtils;

/**
	client-side level rendering
	Level parses tmx entities maps, renders tie layers into mesh
**/
class LevelView extends dn.Process {

	public static var inst : LevelView;

	public var lvlName : String;
	public var entities : Array<TmxObject> = [];

	var levelRenderer : IDestroyable;

	/**
		3d x coord of cursor
	**/
	public var cursX : Float;

	/**
		3d z coord of cursor
	**/
	public var cursY : Float;

	public var cursorInteract : Interactive;
	public var world : World;
	public var oimoDebug : OimoDebugRenderer;
	public var onRenderedSignal = new EventSignal0();

	public function new( map : TmxMap ) {
		super( GameClient.inst );
		world = new World( new Vec3( 0, 0, -9.80665 ) ); //
		inst = this;

		render();
	}

	// function get_lid() {
	// 	var reg = ~/[A-Z\-_.]*([0-9]+)/gi;
	// 	if ( !reg.match(Game.inst.lvlName) ) return -1; else
	// 		return Std.parseInt(reg.matched(1));
	// }

	override function onDispose() {
		super.onDispose();
		
		cursorInteract.remove();
		if ( levelRenderer != null ) levelRenderer.destroy();
		entities = null;
	}

	public function getEntities( id : String ) {
		var a = [];
		for ( e in entities ) if ( e.name == id ) a.push( e );
		return a;
	}

	function render() {
		render3d();
		onRenderedSignal.dispatch();
	}

	/**
		CONGRUENT tileset
	**/
	function render3d() {
		levelRenderer = new VoxelLevel( this ).render();

		#if colliders_debug
		oimoDebug = new OimoDebugRenderer( this ).initWorld( world );
		#end
	}

	override function preUpdate() {
		super.preUpdate();
	}

	override function update() {
		super.update();
	}

	override function postUpdate() {
		super.postUpdate();
	}
}
