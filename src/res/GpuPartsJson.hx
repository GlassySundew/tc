package res;

import cherry.res.JsonFile;
import h3d.parts.GpuParticles;

private typedef GpuSave = {
	var type : String;
	var version : Int;
	var bounds : Array<Float>;
	var groups : Array<Dynamic>;
	var name : String;
	@:optional var hide : Dynamic;
}

class GpuPartsJson extends JsonFile {

	public function toGpuParticles( ?parent : h3d.scene.Object ) : GpuParticles {
		var json = toJson();
		if ( json.type != "particles3D" ) throw "Not a particles json!";
		var parts = new GpuParticles( parent );

		parts.load( json, entry.path );
		return parts;
	}

	public function toGpuParticlesClamped( ?parent : h3d.scene.Object ) : utils.tools.GpuPartsClamed.GpuParticles {
		var json = toJson();
		if ( json.type != "particles3D" ) throw "Not a particles json!";
		var parts = new utils.tools.GpuPartsClamed.GpuParticles( parent );
		parts.load( json, entry.path );
		return parts;
	}
}
