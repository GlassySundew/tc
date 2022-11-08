package shader;

import hxsl.Shader;

class Perpendicularizer extends Shader {

	static var SRC = {
		@:import h3d.shader.BaseMesh;
		//
		function vertex() {
			var center : Vec3 = vec3( 0, 0, 0 ) * global.modelView.mat3x4();
			var pos = center + camera.view[0].xyz * relativePosition.x + vec3( 0, 0, relativePosition.z );
			projectedPosition.z = vec4( vec4( pos, 1 ) * camera.viewProj ).z;
		}
	};
}
