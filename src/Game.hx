import hxd.Key in K;
import hxd.*;
import ent.*;
import camera.*;

@:publicFields
class Game extends hxd.App {
	var world:h2d.Layers;
	var tiles:h2d.Tile;
	var blockLayer:Int = 2;
	var camera:Camera;
	var entities:Array<ent.Entity> = [];

	public static var inst:Game;
	static var save = hxd.Save.load();

	override function init() {
		camera = new Camera(s2d);
		world = new h2d.Layers(camera);
		world.scale(6);
		// engine.window.setFullScreenMod();
		engine.backgroundColor = 0x2c96c6;

		initLevel();
		/*for (e in entities.copy()) {
			e.remove();
		}*/
	}

	override function onResize() {}

	function initLevel(?reload) {
		// world.scale(3);
		var block = hxd.Res.templarcell.toTile();
		var xplacer:Int = 0;
		trace(block.width, block.height);
		for (y in 0...13) {
			for (x in 0...13) {
				new Block(blockLayer, x * (block.width - 2) + xplacer, y * (block.height - 28));
			}
			blockLayer++;
			xplacer += 20;
		}
	}

	override public function update(dt:Float) {
		// trace("FPS: " + inst.engine.fps);
		if (Key.isDown(Key.LEFT)) {
			world.x--;
		} else if (Key.isDown(Key.RIGHT)) {
			world.x++;
		}

		if (Key.isDown(Key.UP)) {
			world.y--;
		} else if (Key.isDown(Key.DOWN)) {
			world.y++;
		}
		for (e in entities.copy())
			e.update(dt);
	}

	static function main() {
		hxd.Res.initEmbed();

		inst = new Game();
	}
}
