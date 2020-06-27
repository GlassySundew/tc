package pass;

// inspired by https://www.shadertoy.com/view/Ms23DR
// and https://www.shadertoy.com/view/ldjGzV

class PostProcessingShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var colorTexture:Sampler2D;
		@param var noiseTexture:Sampler2D;
		@param var time:Float;
		@param var bugPower:Float;
		@param var flashPower:Float;
		@param var flashColor:Vec3;
		@param var crtPower:Float;
		@param var tsize:Vec2;
		@param var h:Float;
		@param var opacity:Float;
		function curve(uv:Vec2):Vec2 {
			uv = (uv - 0.5) * 2.0;
			uv *= 1.1;
			uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
			uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
			uv = (uv / 2.0) + 0.5;
			uv = uv * 0.92 + 0.04;
			return uv;
		}
		function vignette(uv:Vec2):Float {
			var vig = 16 * uv.x * uv.y * (1.0 - uv.x) * (1.0 - uv.y);
			return pow(vig, 0.8);
		}
		function onOff(a:Float, b:Float, c:Float):Float {
			return step(c, sin(time + a * cos(time * b)));
		}
		function readColor(uv:Vec2, chromaticRate:Float):Vec3 {
			var window = 1. / (1. + 20. * (uv.y - mod(time / 4., 1.)) * (uv.y - mod(time / 4., 1.)));

			{ // buggify uvs
				uv.x += sin(uv.y * 10. + time) / 50.0 * (1.0 + cos(time * 80.)) * onOff(4.0, 4.0, 0.3) * (1.0 + cos(time * 80.)) * window * bugPower * 0.5;
				var vShift = 0.1 * onOff(4.0, 5.0, 0.9) * (sin(time) * sin(time * 15.) + (0.5 + 0.1 * sin(time * 150.) * cos(time)));
				vShift *= cos(time * 50) * sin(time * 20);
				uv.y = mod(uv.y + vShift * bugPower, 1.);
			}

			// chromatic abberation
			var r = colorTexture.get(uv + vec2(-0.005, 0.0) * chromaticRate).r;
			var g = colorTexture.get(uv).g;
			var b = colorTexture.get(uv + vec2(0.005, 0.0) * chromaticRate).b;

			return vec3(r, g, b);
		}
		function fragment() {
			var uv = input.uv;
			var vig = vignette(uv);

			uv = mix(uv, curve(uv), crtPower);
			var chromaRate = (1.0 - vig) * crtPower;
			var color = readColor(uv, chromaRate);

			{ // noise
				var nuv = uv * tsize.y * 0.004;
				nuv += vec2(sin(time * 20.0), cos(time * 10.0) * 2);
				var noise = noiseTexture.get(nuv).rgb;
				color += (noise - 0.4) * 0.3 * bugPower;
			}

			color = saturate(color + flashColor * flashPower);
			if (uv.x < 0.0 || uv.x > 1.0)
				color *= 0.0;
			if (uv.y < 0.0 || uv.y > 1.0)
				color *= 0.0;

			// scanlines
			// var s = sin(time * -10.0 + uv.y * tsize.y);
			// s = mix(1.0, s, crtPower);
			// color *= vec3(0.96 + 0.04 * s);

			// vignette
			var vig = vignette(input.uv);
			color *= vig;

			output.color = vec4(color, 1.0);
		}
	};
}

class PostProcessing extends h3d.pass.ScreenFx<PostProcessingShader> {
	var flashStart:Float;
	var flashDuration:Float;

	public function new() {
		super(new PostProcessingShader());
		shader.noiseTexture = hxd.Res.maps.noise.toTexture();
		shader.noiseTexture.wrap = Repeat;
		shader.noiseTexture.filter = Nearest;
		shader.bugPower = 0.0;
		shader.flashPower = 0.0;
		shader.crtPower = 1.0;
		shader.h = Game.inst.h();
		
		flashStart = 0.0;
		flashDuration = 0.0;
	}

	function easeOutCubic(t:Float) {
		return (--t) * t * t + 1;
	}

	public function apply(from:h3d.mat.Texture, time:Float, ?to:h3d.mat.Texture) {
		engine.pushTarget(to);
		pass.setBlendMode(None);
		shader.colorTexture = from;
		shader.time = time;
		shader.tsize.set(from.width, from.height);

		if (flashDuration > 0)
			shader.flashPower = 1.0 - easeOutCubic((time - flashStart) / flashDuration);

		if (shader.flashPower < 0.0) {
			shader.flashPower = 0.0;
			flashDuration = 0;
		}

		render();
		engine.popTarget();
	}

	public function flash(color:Int, time:Float, duration:Float) {
		flashDuration = duration;
		flashStart = time;
		shader.flashColor.setColor(color);
	}
}
