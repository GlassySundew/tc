package shader;

import h3d.shader.GpuParticle;

class GpuParticleClamped extends GpuParticle {
	static var SRC = {
		@param var stopAt : Float = 0;
		function __init__() {
			{
				var totTime = props.time + time;
				t = totTime % (props.life * loopCounter);
				visibility = float(totTime >= 0) * float(totTime - t < props.time + maxTime);
				var clampedTime = clamp(totTime, 0, stopAt) % (props.life * loopCounter);
				transformedPosition = relativePosition + (input.normal * (1 + speedIncr * clampedTime)) * clampedTime + offset;
			}
			
			normT = t / props.life;
			randProp = -props.time / props.life;
			if ( clipBounds ) transformedPosition = (transformedPosition - volumeMin) % volumeSize + volumeMin;
			transformedPosition *= transform;
			transformedPosition.z -= gravity * t * t;
			transformedNormal = camera.dir;
			calculatedUV = vec2(props.uv.x, 1 - props.uv.y);
			{
				frame = (t / props.life) * animationRepeat + float(int(animationFixedFrame * randProp));
				frameBlending = frame.fract();
				frame -= frameBlending;
				frame %= totalFrames;
				var nextFrame = (frame + 1) % totalFrames;
				var delta = vec2(frame % frameDivision.x, float(int(frame / frameDivision.x)));
				frameUV = (calculatedUV + delta) * frameDivision.yz;
				var delta = vec2(nextFrame % frameDivision.x, float(int(nextFrame / frameDivision.x)));
				frameUV2 = (calculatedUV + delta) * frameDivision.yz;
			}
		}
	};
}
