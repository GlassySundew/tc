package shader;

import h3d.mat.Texture;
import hxsl.Shader;

class LUT extends Shader {

	static var SRC = {
		//
		var output : {
			position : Vec4,
			color : Vec4,
		};
		//
		var pixelColor : Vec4;
		//
		@param var lookup : Sampler2D;
		//
		@perInstance @param var lutRows : Int; // 8
		@param var lutSize : Int; // 64
		//
		@perInstance @param var offsetX : Int;
		@perInstance @param var offsetY : Int;
		//
		function lutUV( color : Vec4 ) : Vec2 {
			var z = color.z * 256; // 17
			var fz = z / ( 256 / lutSize ); // 17 / (256/16) = 1 ; 17 - 16
			var y = fz / ( lutRows );
			var x = fz % ( lutRows * 2 );
			return
				( ( ( color.xy ) * 256 ) / 8 + vec2( offsetX, offsetY ) ) / lookup.size();

			// ( color.xy * 256 + vec2( fb % lutRows, floor( fb / lutRows ) ) * 256 ) / ( 256 / lutSize ) / lookup.size();
			//     * ( 256 / lutSize )
		}
		//
		function fragment() {
			output.color = lookup.get( lutUV( pixelColor ) );
		}
	}

	public function new( lookup : Texture, rows = 4, offsetX = 0, offsetY = 0 ) {
		this.lookup = lookup;
		lutRows = rows;
		lutSize = lutRows * lutRows;
		this.offsetX = offsetX;
		this.offsetY = offsetY;

		super();
	}
}
