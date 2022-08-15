package shader;

class PolyDedepther extends hxsl.Shader {

	static var SRC = {
		@:import h3d.shader.BaseMesh;

		@param var objZ : Float;
		@param var xRotAngle : Float = 0;
		
		function vertex() {
			transformedPosition.y = objZ - relativePosition.z * tan( xRotAngle * 2 / 3 );
		}
	};

	public function new( objZ : Float ) {
		super();
		this.objZ = objZ;
	}
}
