package shader;

// based on https://learnopengl.com/#!Lighting/Light-casters (soft spot light)

class SpotLight extends hxsl.Shader {
	static var SRC = {
		@const var enableSpecular : Bool;
		@param var lightPosition : Vec3;
		@param var lightDirection : Vec3;

		@param var innerCutOff : Float;
		@param var outerCutOff : Float;

		@param var color : Vec3;
		@param var params : Vec3;
		@global var camera : {
			var position : Vec3;
		};

		var lightColor : Vec3;
		var lightPixelColor : Vec3;
		var transformedPosition : Vec3;
		var pixelTransformedPosition : Vec3;
		var transformedNormal : Vec3;
		var specPower : Float;
		var specColor : Vec3;

		function calcLighting(position : Vec3) : Vec3 {
			var dvec  = lightPosition - position;
			var dist2 = dvec.dot(dvec);
			var dist  = dist2.sqrt();
			var dir   = normalize(dvec);

			var theta  = dot(dir, normalize(-lightDirection));
			var intensity = saturate((theta - outerCutOff) / (innerCutOff - outerCutOff));

			var factor = 1 / vec3(dist, dist2, dist * dist2).dot(params);
			if (!enableSpecular)
				return color * intensity * factor;
				
			var r = reflect(-dir, transformedNormal).normalize();
			var specValue = r.dot((camera.position - position).normalize()).max(0.);
			return color * (intensity * factor + specColor * pow(specValue, specPower));
		}

		function vertex() {
			lightColor.rgb += calcLighting(transformedPosition);
		}

		function fragment() {
			lightPixelColor.rgb += calcLighting(pixelTransformedPosition);
		}
	};

	public function new() {
		super();
		color.set(1, 1, 1);
		params.set(0, 0, 1);
	}
}