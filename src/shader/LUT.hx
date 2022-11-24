package shader;

import h3d.mat.Texture;
import hxsl.Shader;

class LUT extends Shader {

	static var SRC = {
		@input var input : {
			var uv : Vec2;
			var position : Vec3;
			var normal : Vec3;
		};
		//
		var output : {
			position : Vec4,
			color : Vec4,
		};
		//
		var pixelColor : Vec4;
		//
		@param var lookup : Sampler2D;
		@param var texture : Sampler2D;
		//
		@perInstance @param var lutRows : Float; // 8
		@param var lutSize : Float; // 64
		//
		@perInstance @param var offsetX : Float;
		@perInstance @param var offsetY : Float;
		//
		function lutUV( color : Vec4 ) : Vec2 {
			var z = color.z * 256; // 17
			var fz = z / ( 256 / lutSize ); // 17 / (256/16) = 1 ; 17 - 16
			var y = fz / ( lutRows );
			var x = fz % ( lutRows * 2 );
			return
				( ( ( color.xy ) * 256 ) / lutRows / 4 + vec2( offsetX, offsetY ) ) / lookup.size();

			// ( color.xy * 256 + vec2( fb % lutRows, floor( fb / lutRows ) ) * 256 ) / ( 256 / lutSize ) / lookup.size();
			//     * ( 256 / lutSize )
		}
		//
		function fragment() {
			output.color = lookup.get( lutUV( texture.get( input.uv ) ) );
			// output.color = lookup.get( lutUV( texture.get( input.uv ) ) );
		}
	}

	public function new( lookup : Texture, texture : Texture, rows = 4, offsetX = 0, offsetY = 0 ) {
		this.lookup = lookup;
		this.texture = texture;
		lutRows = rows;
		lutSize = lutRows * lutRows;
		this.offsetX = offsetX;
		this.offsetY = offsetY;

		super();
	}
}
