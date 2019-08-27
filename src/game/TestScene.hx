package game;

import h3d.scene.CameraController;
import h3d.Vector;
import h2d.Tile;
import hxd.Res;
import cdb.TileBuilder;
import format.amf3.Tools;
import h2d.Bitmap;
import engine.HPEngine;
import hxd.Key in K;
import h3d.prim.*;
import engine.HXP;
import gasm.core.Entity;
import h3d.scene.Object;
import engine.HScene;
import hxd.fmt.hmd.Library;
import engine.S3DComponent;
import h3d.scene.Mesh;
import h3d.mat.Texture;
import hxd.res.TiledMap;
import game.comps.*;

class TestScene extends HScene {
	public static var instance:TestScene;

	private var time:Float = 0.;
	private var obj:Mesh;
	private var tex:Texture;
	private var anna:Anna;
	private var layers:h2d.Layers;
	private var prim:h3d.prim.PlanePrim;
	private var tiledMapData:TiledMapData;
	// var tiles = hxd.Res.tiled.walls_floors_png.toTile();
	private var tw:Int = 46;
	private var th:Int = 24;
	private var groundGroup:h2d.TileGroup;
	private var mw:Int;
	private var mh:Int;
	private var tilesAr = [];
	private var tiles:Tile;
	private var mesh:S3DComponent;
	private var camOffset:Vector = new Vector(0, 0, 256);
	private var cam:CameraController;

	public var key:{
		left:Bool,
		right:Bool,
		up:Bool,
		down:Bool,
		action:Bool,
	};

	public function new() {
		instance = this;
		super();
	}

	override public function setup() {
		super.setup();

		tiledMapData = hxd.Res.tiled.alphascene.toMap();

		mw = tiledMapData.width;
		mh = tiledMapData.height;

		tiles = hxd.Res.tiled.walls_floor_png.toTile();

		s3d.camera.setFovX(70, s3d.camera.screenRatio);
		new AxesHelper(s3d);
		new GridHelper(s3d, 10, 10);
		for (y in 0...Std.int(tiles.height / th)) {
			for (x in 0...Std.int(tiles.width / tw)) {
				var t = tiles.sub(x * tw, y * th, tw, th, 0, -th);
				tilesAr.push(t);
			}
		}
		layers = new h2d.Layers(HXP.engine.s2d);
		for (layer in tiledMapData.layers) {
			var layerIndex:Int = tiledMapData.layers.indexOf(layer);
			groundGroup = new h2d.TileGroup(tilesAr[0]);
			layers.add(groundGroup, layerIndex);
			for (y in 0...mh) {
				for (x in 0...mw) {
					var tid = layer.data[x + y * mw];
					if (tid != 0) {
						switch (layer.name) {
							case "anna":
								{
									anna = new Anna(this, "Anna", (x - y) * (tw * 0.5 + 1) + mw * (tw + 0.5) / 2 + 1, y * (tw + 2) / 4 + x * th / 2 - 2 * th);
									add(anna.owner);
								}
							case "ground":
								{
									groundGroup.add((x - y) * (tw * 0.5 + 1), y * (tw + 2) / 4 + x * th / 2, tilesAr[tid - 1]);
								}
						}
					}
				}
			}
		}

		layers.x += ((mh) * (tw + 2) / 2) - tw / 2;
		layers.y += th;
		tex = new h3d.mat.Texture(Std.int(layers.getBounds().width), Std.int(layers.getBounds().height), [Target]);
		tex.filter = Nearest;

		layers.drawTo(tex);
		prim = new h3d.prim.PlanePrim(layers.getBounds().width, layers.getBounds().height);
		
		obj = new h3d.scene.Mesh(prim, h3d.mat.Material.create(tex), s3d);
		obj.material.shadows = false;
		obj.material.mainPass.enableLights = false;
		// obj.visible = false;
		//	groundGroup.drawTo(tex);
		layers.visible = false;
		owner.add(mesh = new S3DComponent(obj));
		s3d.camera.target.set(anna.obj.x, anna.obj.y, anna.obj.z);
		s3d.camera.pos = s3d.camera.target.add(camOffset);
	}

	override public function begin() {
		// s3d.lightSystem.ambientLight.set(0.3, 0.3, 0.3);
	}

	override public function update(delta:Float) {
		super.update(delta);
		key = {
			up: K.isDown("W".code),
			left: K.isDown("A".code),
			down: K.isDown("S".code),
			right: K.isDown("D".code),

			action: K.isDown("E".code)
		};

		var desiredPos = new Vector(anna.obj.x, anna.obj.y, anna.obj.z).add(camOffset);

		var smoothPos = new Vector();

		smoothPos.lerp(s3d.camera.pos, desiredPos, 3 * delta);
		s3d.camera.pos.x = smoothPos.x;
		s3d.camera.pos.y = smoothPos.y;

		s3d.camera.target = desiredPos.sub(camOffset);
		if (key.action) {}
	}
}

class AxesHelper extends h3d.scene.Graphics {
	public function new(?parent:h3d.scene.Object, size = 2.0, colorX = 0xEB304D, colorY = 0x7FC309, colorZ = 0x288DF9, lineWidth = 2.0) {
		super(parent);

		// trace(s3d.camera.pos.x, s3d.camera.pos.y, s3d.camera.pos.z, s3d.camera.pos.w);
		material.props = h3d.mat.MaterialSetup.current.getDefaults("ui");

		lineShader.width = lineWidth;

		setColor(colorX);
		lineTo(size, 0, 0);

		setColor(colorY);
		moveTo(0, 0, 0);
		lineTo(0, size, 0);

		setColor(colorZ);
		moveTo(0, 0, 0);
		lineTo(0, 0, size);
	}
}

class GridHelper extends h3d.scene.Graphics {
	public function new(?parent:Object, size = 10.0, divisions = 10, color1 = 0x444444, color2 = 0x888888, lineWidth = 1.0) {
		super(parent);

		material.props = h3d.mat.MaterialSetup.current.getDefaults("ui");

		lineShader.width = lineWidth;

		var hsize = size / 2;
		var csize = size / divisions;
		var center = divisions / 2;
		for (i in 0...divisions + 1) {
			var p = i * csize;
			setColor((i != 0 && i != divisions && i % center == 0) ? color2 : color1);
			moveTo(-hsize + p, -hsize, 0);
			lineTo(-hsize + p, -hsize + size, 0);
			moveTo(-hsize, -hsize + p, 0);
			lineTo(-hsize + size, -hsize + p, 0);
		}
	}
}

class PointLightHelper extends h3d.scene.Mesh {
	public function new(light:h3d.scene.fwd.PointLight, sphereSize = 0.5) {
		var prim = new h3d.prim.Sphere(sphereSize, 4, 2);
		prim.addNormals();
		prim.addUVs();
		super(prim, light);
		material.color = light.color;
		material.mainPass.wireframe = true;
	}
}

class InstancedOffsetShader extends hxsl.Shader {
	static var SRC = {
		@:import h3d.shader.BaseMesh;
		@perInstance(2) @input var offset:Vec2;
		function vertex() {
			transformedPosition.xy += offset;
			transformedPosition.xy += float(instanceID & 1) * vec2(0.2, 0.1);
			transformedPosition.z += float(instanceID) * 0.01;
			pixelColor.r = float(instanceID) / 16.;
			pixelColor.g = float(vertexID) / 8.;
		}
	};
}
