package shader;

import h3d.shader.ScreenShader;

/** doesnst work :( **/
class SDFScreenShader extends ScreenShader {
	static var SRC = {
		@param var texture : Sampler2D;

		@const var channel : Int = 6;
		
		@param var alphaCutoff : Float = 0.1;
		
		@param var smoothing : Float = 1.94166666666666666666666666666667;
		
		
		function median( r : Float, g : Float, b : Float ) : Float {
			return max(min(r, g), min(max(r, g), b));
		}

		function fragment() {
			var textureSample : Vec4 = texture.get(calculatedUV);
			
		
			var distance : Float = 
			if (channel == 0) textureSample.r;
				else if (channel == 1) textureSample.g;
				else if (channel == 2) textureSample.b;
				else if (channel == 3) textureSample.a;
				else median(textureSample.r, textureSample.g, textureSample.b);
			
			pixelColor = textureSample * vec4(1.0, 1.0, 1.0, smoothstep(alphaCutoff - smoothing, alphaCutoff + smoothing, distance));
			
		}
	}
}
