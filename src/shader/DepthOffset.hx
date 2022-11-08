package shader;

/**
	depth offset shader for overlapping models
**/
class DepthOffset extends hxsl.Shader {

	static var SRC = {
		@:import h3d.shader.BaseMesh;
		//
		@perInstance @param var offset : Float;
		//
		function vertex() {
			projectedPosition.z -= offset;
		}
	};

	public function new( offset : Float ) {
		super();
		this.offset = offset;
	}
}
