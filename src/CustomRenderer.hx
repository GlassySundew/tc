class CustomRenderer extends h3d.scene.fwd.Renderer {
	public var saoBlur:h3d.pass.Blur;
	public var enableSao:Bool;
	public var enableFXAA:Bool;

	public var all:h3d.pass.Output;
	public var fog:pass.Fog;
	public var sao:h3d.pass.ScalableAO;
	public var emissive:pass.Emissive;
	public var fxaa:h3d.pass.FXAA;
	public var post:pass.PostProcessing;
	public var depthColorMap(default, set):h3d.mat.Texture;

	var depthColorMapId:Int;
	var depthColorMax:Int;
	var out:h3d.mat.Texture;

	public function new() {
		super();

		var engine = h3d.Engine.getCurrent();
		if (!engine.driver.hasFeature(MultipleRenderTargets))
			throw "engine must have MRT";
		all = new h3d.pass.Output("mrt", [
			Value("output.color"),
			PackFloat(Value("output.depth")),
			PackNormal(Value("output.normal"))

		]);

		allPasses.push(all);
		depthColorMap = h3d.mat.Texture.fromColor(0xFFFFFF);

		depthColorMapId = hxsl.Globals.allocID("depthColorMap");
		sao = new h3d.pass.ScalableAO();
		saoBlur = new h3d.pass.Blur(3, 3, 2);

		sao.shader.sampleRadius = 0.2;
		fog = new pass.Fog();

		fxaa = new h3d.pass.FXAA();
		emissive = new pass.Emissive("emissive");
		emissive.reduceSize = 1;
		// emissive.blur.passes = 5;
		emissive.blur.quality = 4;

		// emissive.blur.sigma = 2;
		post = new pass.PostProcessing();
	}

	function set_depthColorMap(v:h3d.mat.Texture) {
		var pixels = v.capturePixels();
		depthColorMax = pixels.getPixel(pixels.width - 1, 0);
		// all.clearColors[0] = depthColorMax;
		return depthColorMap = v;
	}

	override function renderPass(p:h3d.pass.Base, passes, ?sort) {
		return super.renderPass(p, passes, sort);
	}

	override function render() {
		if (has("depth"))
			renderPass(depth, get("depth"));

		ctx.setGlobalID(depthColorMapId, depthColorMap);

		shadow.draw(get("shadow"));
		all.setContext(ctx);

		renderPass(shadow, get("shadow"));
		var colorTex = allocTarget("color");
		var depthTex = allocTarget("depth");
		var normalTex = allocTarget("normal");
		var additiveTex = allocTarget("additive");

		setTargets([colorTex, depthTex, normalTex, additiveTex]);
		clear(0, 1);

		all.draw(get("default"));

		renderPass(defaultPass, get("alpha"), backToFront);

		// setTarget(colorTex);
		// draw("alpha");
		// resetTarget();

		setTarget(additiveTex);
		clear(0);
		draw("additive");
		resetTarget();

		emissive.setContext(ctx);
		emissive.draw(get("emissive"));

		if (enableSao) {
			// apply sao
			var saoTarget = allocTarget("sao", false);
			setTarget(saoTarget);
			sao.apply(depthTex, normalTex, ctx.camera);
			resetTarget();
			saoBlur.apply(ctx, saoTarget, allocTarget("saoBlurTmp", false));
			h3d.pass.Copy.run(saoTarget, colorTex, Multiply);
		} { // apply fog\post.apply(colorTex, ctx.time);
			var fogTarget = allocTarget("fog", false, 1);
			fog.setGlobals(ctx);
			setTarget(fogTarget);
			fog.apply(colorTex, depthTex, normalTex, ctx.camera);
			resetTarget();
			colorTex = fogTarget;
		}

		h3d.pass.Copy.run(ctx.textures.allocTarget("emissive", colorTex.width, colorTex.height), colorTex, Add);
		h3d.pass.Copy.run(additiveTex, colorTex, Add);

		if (enableFXAA) {
			var t = allocTarget("fxaaOut", false, 0);
			setTarget(t);
			fxaa.apply(colorTex);
			resetTarget();
			colorTex = t;
		}
		post.setGlobals(ctx);
		post.apply(colorTex, ctx.time);
	}

	public function flash(color:Int, duration:Float) {
		post.flash(color, ctx.time, duration);
	}
}
