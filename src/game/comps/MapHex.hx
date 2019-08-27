package game.comps;

import hxd.snd.Channel;
import hxd.Key;
import msignal.Signal;
import h3d.mat.Data;
import h3d.mat.BlendMode;
import hxd.Event;
import h3d.scene.Interactive;
import hxd.Timer;
import h3d.shader.BaseMesh;
import engine.shaders.PlayStationShader;
import hxd.Res;
import h3d.scene.Object;
import engine.HXP;
import engine.S3DComponent;
// import game.HexType;
import engine.HComp;

class MapHex extends HComp {
	// public var type:HexType;
	private var mesh:S3DComponent;

	public var destroyed:Bool;
	
	public var type:HexType;
	public var x:Int;
	public var y:Int;

	private static inline var DESTROY_TIME:Float = 3.7;

	public var interact:Interactive;

	public function new(x:Int, y:Int) {
		super();
		this.x = x;
		this.y = y;

		HXP.wrap(this);
	}

	public static inline var TILE_WIDTH:Float = 46; // - .57;
	public static inline var TILE_HEIGHT:Float = 24; // - .55;

	override public function setup() {
		//owner.add(mesh = new S3DComponent(interact = new Interactive(HXP.loadCollider(Res.tile))));
		
	
		// setType(type);
	}


	

	override public function update(delta:Float) {
		
	}

	

	
	

	public function setType(type:HexType):Void {
		this.type = type;
		getMesh();
	}

	private function getMesh():Object {
		var obj:Object = null;
		var z:Float = Math.random() * 4;

		
		if (obj != null) {
			
			
		}
		return null;
	}
}
