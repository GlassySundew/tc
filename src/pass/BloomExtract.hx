package pass;

class BloomExtractShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var texture : Sampler2D;
		@param var brightness : Float;

		function fragment() {
			var color = texture.get(input.uv).rgb;
			var lum   = color.rgb.dot(vec3(0.2126, 0.7152, 0.0722));

			var q = smoothstep(brightness, 1.0, lum);
			output.color.rgb = mix(vec3(0), color, q);
			output.color.a = 1.0;
		}
	};
}

class BloomExtract extends h3d.pass.ScreenFx<BloomExtractShader> {
	public function new() {
		super(new BloomExtractShader());
		shader.brightness = 0.5;
	}

	public function apply(from : h3d.mat.Texture, to : h3d.mat.Texture) {
		engine.pushTarget(to);
		shader.texture = from;
		pass.setBlendMode(None);
		render();
		shader.texture = null;
		engine.popTarget();
	}
}