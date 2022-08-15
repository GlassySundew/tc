package shader;

/**
	depth offset shader for overlapping models
**/
class VoxelDepther extends hxsl.Shader {

	static var SRC = {
		@:import h3d.shader.BaseMesh;
		//
		@param var objZ : Float;
		//
		function __init__() {
			projectedPosition.z -= objZ;
		}
	};

	public function new( objZ : Float ) {
		super();
		this.objZ = objZ;
	}
}
