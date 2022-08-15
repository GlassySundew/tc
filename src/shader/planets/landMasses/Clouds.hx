package shader.planets.landMasses;

import hxsl.Shader;

class Clouds extends Shader {

	static var SRC = {
		@input var input : {
			position : Vec2,
			uv : Vec2,
		};
		//
		var output : {
			position : Vec4,
			color : Vec4,
		};
		//
		@global var time : Float;
		//
		@param var pixels : Float;
		@param var rotation : Float = 0.0;
		@param var cloud_cover : Float;
		@param var light_origin : Vec2 = vec2( 0.39, 0.39 );
		@param var time_speed : Float = 0.2;
		@param var stretch : Float = 2.0;
		@param var cloud_curve : Float = 1.3;
		@param var light_border_1 : Float = 0.52;
		@param var light_border_2 : Float = 0.62;
		//
		@param var base_color : Vec4;
		@param var outline_color : Vec4;
		@param var shadow_base_color : Vec4;
		@param var shadow_outline_color : Vec4;
		//
		@param var size : Float = 50.0;
		@param var OCTAVES : Int = 2;
		@param var seed : Float;
		//
		function round( v : Float ) : Float {
			return if ( v % 1 > .5 ) ceil( v ) else floor( v );
		}
		//
		function rand( coord : Vec2 ) : Float {
			coord = mod( coord, vec2( 1.0, 1.0 ) * round( size ) );
			return fract( sin( dot( coord.xy, vec2( 12.9898, 78.233 ) ) ) * 15.5453 * seed );
		}
		//
		function noise( coord : Vec2 ) : Float {
			var i : Vec2 = vec2( floor( coord ) );
			var f : Vec2 = vec2( fract( coord ) );

			var a : Float = rand( i );
			var b : Float = rand( i + vec2( 1.0, 0.0 ) );
			var c : Float = rand( i + vec2( 0.0, 1.0 ) );
			var d : Float = rand( i + vec2( 1.0, 1.0 ) );

			var cubic : Vec2 = vec2( f * f * ( 3.0 - 2.0 * f ) );

			return mix( a, b, cubic.x ) + ( c - a ) * cubic.y * ( 1.0 - cubic.x ) + ( d - b ) * cubic.x * cubic.y;
		}
		//
		function fbm( coord : Vec2 ) : Float {
			var value : Float = 0.0;
			var scale : Float = 0.5;

			for ( i in 0...OCTAVES ) {
				value += noise( coord ) * scale;
				coord *= 2.0;
				scale *= 0.5;
			}
			return value;
		}
		//
		function spherify( uv : Vec2 ) : Vec2 {
			var centered : Vec2 = vec2( uv * 2.0 - 1.0 );
			var z : Float = sqrt( 1.0 - dot( centered.xy, centered.xy ) );
			var sphere : Vec2 = vec2( centered / ( z + 1.0 ) );

			return vec2( sphere * 0.5 + 0.5 );
		}
		//
		function rotate( coord : Vec2, angle : Float ) : Vec2 {
			coord -= 0.5;
			coord *= mat2( vec2( cos( angle ), -sin( angle ) ), vec2( sin( angle ), cos( angle ) ) );
			return vec2( coord + 0.5 );
		}
		function dither( uv1 : Vec2, uv2 : Vec2 ) : Bool {
			return mod( uv1.x + uv2.y, 2.0 / pixels ) <= 1.0 / pixels;
		}
		// by Leukbaars from https://www.shadertoy.com/view/4tK3zR
		function circleNoise( uv : Vec2 ) : Float {
			var uv_y : Float = floor( uv.y );
			uv.x += uv_y * .31;
			var f : Vec2 = vec2( fract( uv ) );
			var h : Float = rand( vec2( floor( uv.x ), floor( uv_y ) ) );
			var m : Float = ( length( f - 0.25 - ( h * 0.5 ) ) );
			var r : Float = h * 0.25;
			return smoothstep( 0.0, r, m * 0.75 );
		}
		//
		function cloud_alpha( uv : Vec2 ) : Float {
			var c_noise : Float = 0.0;
			// more iterations for more turbulence
			for ( i in 0...9 ) {
				c_noise += circleNoise( ( uv * size * 0.3 ) + ( float( i + 1 ) + 10. ) + ( vec2( time * time_speed, 0.0 ) ) );
			}
			var fbm : Float = fbm( uv * size + c_noise + vec2( time * time_speed, 0.0 ) );

			return fbm; // step(a_cutoff, fbm);
		}
		//
		function fragment() {
			// pixelize uv
			var uv : Vec2 = floor( input.uv * pixels ) / pixels;

			// distance to light source
			var d_light : Float = distance( uv, light_origin );

			// cut out a circle
			var d_circle : Float = distance( uv, vec2( 0.5 ) );
			var a : Float = step( d_circle, 0.5 );

			var d_to_center : Float = distance( uv, vec2( 0.5 ) );

			uv = rotate( uv, rotation );

			// map to sphere
			uv = spherify( uv );
			// slightly make uv go down on the right, and up in the left
			uv.y += smoothstep( 0.0, cloud_curve, abs( uv.x - 0.4 ) );

			var c : Float = cloud_alpha( uv * vec2( 1.0, stretch ) );

			// assign some colors based on cloud depth & distance from light
			var col : Vec3 = base_color.rgb;
			if ( c < cloud_cover + 0.03 ) {
				col = outline_color.rgb;
			}
			if ( d_light + c * 0.2 > light_border_1 ) {
				col = shadow_base_color.rgb;
			}
			if ( d_light + c * 0.2 > light_border_2 ) {
				col = shadow_outline_color.rgb;
			}

			c *= step( d_to_center, 0.5 );
			output.color = vec4( col, step( cloud_cover, c ) * a );
		}
	}
}
