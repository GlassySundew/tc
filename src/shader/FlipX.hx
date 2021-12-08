package shader;

class FlipX extends hxsl.Shader {

	static var SRC = {
		@:import h3d.shader.BaseMesh;
		
		function vertex() {
			projectedPosition = vec4(transformedPosition, 1) * camera.viewProj;
		}
	};
}
