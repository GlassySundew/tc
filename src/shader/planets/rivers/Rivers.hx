package shader.planets.rivers;

import hxsl.Shader;
import h3d.shader.ScreenShader;

class Rivers extends Shader {
	static var SRC = {

		@input var input : {
			position : Vec2,
			uv : Vec2,
		};
		
		var output : {
			position : Vec4,
			color : Vec4,
		};

		@global var time : Float;

		@param var pixels : Float;
		@param var rotation : Float = 0;
		@param var light_origin : Vec2 = vec2(.39, .39);
		@param var time_speed : Float = .2;
		@param var dither_size : Float = 2;
		@param var light_border_1 : Float = .4;
		@param var light_border_2 : Float = .5;
		@param var river_cutoff : Float;

		@param var col1 : Vec4;
		@param var col2 : Vec4;
		@param var col3 : Vec4;
		@param var col4 : Vec4;
		@param var river_col : Vec4;
		@param var river_col_dark : Vec4;

		@param var size : Float = 50;
		@param var OCTAVES : Int;
		@param var seed : Float;

		var pixelColor : Vec4;
		var calculatedUV : Vec2;

		@param var flipY : Float;

		function round(v : Float) : Float {
			return if ( v % 1 > .5 ) ceil(v) else floor(v);
		}

		function rand(coord : Vec2) : Float {
			coord = mod(coord, vec2(1.0, 1.0) * round(size));
			return fract(sin(dot(coord.xy, vec2(12.9898, 78.233))) * 15.5453 * seed);
		}

		function noise(coord : Vec2) : Float {
			var i : Vec2 = vec2(floor(coord));
			var f : Vec2 = vec2(fract(coord));

			var a : Float = rand(i);
			var b : Float = rand(i + vec2(1.0, 0.0));
			var c : Float = rand(i + vec2(0.0, 1.0));
			var d : Float = rand(i + vec2(1.0, 1.0));

			var cubic : Vec2 = vec2(f * f * (3.0 - 2.0 * f));

			return mix(a, b, cubic.x) + (c - a) * cubic.y * (1.0 - cubic.x) + (d - b) * cubic.x * cubic.y;
		}

		function fbm(coord : Vec2) : Float {
			var value : Float = 0.0;
			var scale : Float = 0.5;

			for (i in 0...OCTAVES) {
				value += noise(coord) * scale;
				coord *= 2.0;
				scale *= 0.5;
			}
			return value;
		}

		function spherify(uv : Vec2) : Vec2 {
			var centered : Vec2 = vec2(uv * 2.0 - 1.0);
			var z : Float = sqrt(1.0 - dot(centered.xy, centered.xy));
			var sphere : Vec2 = vec2(centered / (z + 1.0));

			return vec2(sphere * 0.5 + 0.5);
		}

		function rotate(coord : Vec2, angle : Float) : Vec2 {
			coord -= 0.5;
			coord *= mat2(vec2(cos(angle), -sin(angle)), vec2(sin(angle), cos(angle)));
			return vec2(coord + 0.5);
		}

		function dither(uv1 : Vec2, uv2 : Vec2) : Bool {
			return mod(uv1.x + uv2.y, 2.0 / pixels) <= 1.0 / pixels;
		}

		function __init__() {
			output.color = pixelColor;
		}

		function fragment() {
			var uv : Vec2 = vec2(floor(input.uv * pixels) / pixels);

			var d_light : Float = distance(uv, light_origin);
			var dith : Bool = dither(uv, input.uv);
			var a : Float = step(distance(vec2(0.5), uv), 0.5);

			// give planet a tilt
			uv = rotate(uv, rotation);

			// map to sphere
			uv = spherify(uv);

			// some scrolling noise for landmasses
			var base_fbm_uv : Vec2 = vec2((uv) * size + vec2(time * time_speed, 0.0));

			// use multiple fbm's at different places so we can determine what color land gets
			var fbm1 : Float = fbm(base_fbm_uv);
			var fbm2 : Float = fbm(base_fbm_uv - light_origin * fbm1);
			var fbm3 : Float = fbm(base_fbm_uv - light_origin * 1.5 * fbm1);
			var fbm4 : Float = fbm(base_fbm_uv - light_origin * 2.0 * fbm1);

			var river_fbm : Float = fbm(base_fbm_uv + fbm1 * 6.0);
			river_fbm = step(river_cutoff, river_fbm);

			// size of edge in which colors should be dithered
			var dither_border : Float = (1.0 / pixels) * dither_size;
			// lots of magic numbers here
			// you can mess with them, it changes the color distribution
			if ( d_light < light_border_1 ) {
				fbm4 *= 0.9;
			}
			if ( d_light > light_border_1 ) {
				fbm2 *= 1.05;
				fbm3 *= 1.05;
				fbm4 *= 1.05;
			}
			if ( d_light > light_border_2 ) {
				fbm2 *= 1.3;
				fbm3 *= 1.4;
				fbm4 *= 1.8;
				if ( d_light < light_border_2 + dither_border && dith ) {
					fbm4 *= 0.5;
				}
			} 
			
			// increase contrast on d_light
			d_light = pow(d_light, 2.0) * 0.4;
			var col : Vec3 = col4.xyz;
			if ( fbm4 + d_light < fbm1 * 1.5 ) {
				col = col3.xyz;
			}
			if ( fbm3 + d_light < fbm1 * 1.0 ) {
				col = col2.xyz;
			}
			if ( fbm2 + d_light < fbm1 ) {
				col = col1.xyz;
			}
			if ( river_fbm < fbm1 * 0.5 ) {
				col = river_col_dark.xyz;
				if ( fbm4 + d_light < fbm1 * 1.5 ) {
					col = river_col.xyz;
				}
			}

			output.color = vec4(col, a);
		}
	}
}
