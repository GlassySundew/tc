package game.client.level;

import h3d.scene.Object;
import game.client.level.batch.LUTBatcher;
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
**/
class LevelView extends dn.Process {

	public static var inst(default, null) : LevelView;

	public var lvlName : String;

	/**
		3d x coord of cursor
	**/
	public var cursX : Float;

	/**
		3d y coord of cursor
	**/
	public var cursY : Float;

	public var cursorInteract : Interactive;
	public var world : World;
	public var oimoDebug : OimoDebugRenderer;
	public var tilesetCache : TilesetCache = new TilesetCache();
	public var batcher : LUTBatcher;
	public var root3d : Object;

	public function new( map : TmxMap ) {
		super( GameClient.inst );
		inst = this;
		root3d = new Object( Boot.inst.s3d );
		batcher = new LUTBatcher();
		world = new World( new Vec3( 0, 0, -9.80665 ) ); //
	}

	override function onDispose() {
		super.onDispose();
		root3d.remove();
		inst = null;

		cursorInteract.remove();
	}

	override function preUpdate() {
		super.preUpdate();
	}

	override function update() {
		super.update();
		inline batcher.emitAll();
	}

	override function postUpdate() {
		super.postUpdate();
	}
}
