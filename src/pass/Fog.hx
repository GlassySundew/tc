package pass;

class FogShader extends h3d.shader.ScreenShader {
	static var SRC = {
		@param var colorTexture    : Sampler2D;
		@param var depthTexture	   : Sampler2D;
		@param var normalTexture   : Sampler2D;
		
		@param var cameraInverseViewProj : Mat4;
		@param var cameraPosition : Vec3;
		@param var zNear : Float;
		@param var zFar : Float;

		@global var depthColorMap : Sampler2D;

		function getPosition(uv : Vec2) : Vec3 {
			var depth = unpack(depthTexture.get(uv));
			var uv2   = (uv - 0.5) * vec2(2, -2);
			var temp  = vec4(uv2, depth, 1) * cameraInverseViewProj;
			return vec3(temp.xyz / temp.w);
		}

		function getDist(uv : Vec2) : Float {
			var p = getPosition(uv);
			return (p - cameraPosition).length();
		}

		function fragment() {
			var dist   = getDist(input.uv);
			var normal = unpackNormal(normalTexture.get(input.uv));

			var fogIntensity = saturate((dist - zNear) / (zFar - zNear));
			var color = mix(
				colorTexture.get(input.uv), 
				depthColorMap.get(vec2(fogIntensity, 0.5)),
				fogIntensity);
			output.color = color;
		}
	};
}

class Fog extends h3d.pass.ScreenFx<FogShader> {
	public function new() {
		super(new FogShader());
	}

	public function apply(
		color    : h3d.mat.Texture,
		depth	 : h3d.mat.Texture, 
		normal   : h3d.mat.Texture,
		camera	 : h3d.Camera)
	{
		camera.update();
		shader.colorTexture  = color;
		shader.normalTexture = normal;
		shader.depthTexture	 = depth;
		shader.zNear = camera.zNear;
		shader.zFar  = camera.zFar;
		shader.cameraInverseViewProj = camera.getInverseViewProj();
		shader.cameraPosition = camera.pos;
		
		render();
	}
}