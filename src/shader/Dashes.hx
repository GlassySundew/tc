package shader;

import hxsl.Shader;

/**object must be locally transformed, i.e. Graphics must always be starting with a point of 0, 0**/
class Dashes extends Shader {
	static var SRC = {

		@:import h3d.shader.Base2d;
		@param var u_dashSize : Float;
		@param var u_gapSize : Float;
		
		function fragment() {
			if ( fract(length(spritePosition.xy) / (u_dashSize + u_gapSize)) > u_dashSize / (u_dashSize + u_gapSize) ) {
				output.color.a = 0;
			}

		}
	}

}
