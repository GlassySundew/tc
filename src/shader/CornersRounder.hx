package shader;

class CornersRounder extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture : Sampler2D;
		@param var radius : Float;
		@param var edgeSoftness : Float;

		function roundedBoxSDF( centerPosition : Vec2, size : Vec2, radius : Float ) : Float {
			return length(max(abs(centerPosition) - size + radius, 0.0)) - radius;
		}

		function fragment() {
			var halfSize = texture.size() / 2;
			var coord = input.uv * texture.size(); 

			var distance = roundedBoxSDF(coord - halfSize, halfSize, abs(radius));

			var smoothedAlpha = 1 - smoothstep(0., edgeSoftness * 2., distance);
			
			var pixel : Vec4 = texture.get(input.uv);

			pixelColor = mix(vec4(0.), vec4(pixel.rgb, pixel.a * smoothedAlpha), smoothedAlpha);
		}
	}

	public function new(?radius : Float = 5, ?edgeSoftness : Float = 1 ) {
		super();
		this.radius = radius;
		this.edgeSoftness = edgeSoftness;
	}
}