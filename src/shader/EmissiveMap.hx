package shader;

class EmissiveMap extends hxsl.Shader {

	static var SRC = {
		@param var texture : Sampler2D;
		var calculatedUV   : Vec2;
		var emissiveColor  : Vec4;

		function fragment() {
			emissiveColor = texture.get(calculatedUV);
		}
	}

	public function new(tex) {
		super();
		this.texture = tex;
	}

}