package shader;

import hxsl.Shader;

class PlaneDepthNarrower extends Shader {

	static var SRC = {

		@:import h3d.shader.BaseMesh;

		function vertex() {
			projectedPosition.x = 0;
		}
	};

	public function new() {
		super();
	}
}
