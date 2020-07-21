package ui;

import en.player.Player;
import net.Connect;
import h3d.scene.Renderer;
import h2d.Console.ConsoleArg;
import dn.Lib;

class Console extends h2d.Console {
	public static var inst:Console;

	#if debug
	var flags:Map<String, Bool>;
	#end

	public function new(f:h2d.Font, p:h2d.Object) {
		super(f, p);
		logTxt = new h2d.HtmlText(f, this);
		logTxt.x = 2;
		logTxt.dropShadow = {
			dx: 0,
			dy: 1,
			color: 0,
			alpha: 0.5
		};
		logTxt.visible = false;
		// scale(2); // TODO smarter scaling for 4k screens

		// Settings
		inst = this;
		#if debug
		h2d.Console.HIDE_LOG_TIMEOUT = 30;
		#end
		// Lib.redirectTracesToH2dConsole(this);

		// Debug flags
		#if debug
		flags = new Map();
		this.addCommand("set", [{name: "k", t: AString}], function(k:String) {
			setFlag(k, true);
			log("+ " + k, 0x80FF00);
		});
		this.addCommand("unset", [{name: "k", t: AString, opt: true}], function(?k:String) {
			if (k == null) {
				log("Reset all.", 0xFF0000);
				flags = new Map();
			} else {
				log("- " + k, 0xFF8000);
				setFlag(k, false);
			}
		});
		var pp:Bool = true;
		this.addCommand("pp", [], function(?k:String) {
			if (pp) {
				Boot.inst.s3d.renderer = h3d.mat.MaterialSetup.current.createRenderer();
				pp = false;
			} else {
				Boot.inst.renderer = new CustomRenderer();
				Boot.inst.s3d.renderer = Boot.inst.renderer;
				Boot.inst.renderer.depthColorMap = hxd.Res.gradients.test.toTexture();
				Boot.inst.renderer.enableFXAA = false;
				Boot.inst.renderer.enableSao = false;
				pp = true;
			}
		});

		this.addCommand("untarget", [], function(?k:String) {
			Game.inst.camera.stopTracking();
			new h3d.scene.CameraController(Boot.inst.s3d).loadFromCamera();
		});

		this.addCommand("connect", [], function(?k:String) {
			(new Connect());
		});

		this.addAlias("+", "set");
		this.addAlias("-", "unset");
		#end
	}

	#if debug
	public function setFlag(k:String, v)
		return flags.set(k, v);

	public function hasFlag(k:String)
		return flags.get(k) == true;
	#else
	public function hasFlag(k:String)
		return false;
	#end

	override function sync(ctx:h2d.RenderContext) {
		var scene = ctx.scene;
		if (scene != null) {
			x = 0;
			y = scene.height - height;
			width = scene.width;
			tf.maxWidth = width;
			bg.tile.scaleToSize(width, -logTxt.textHeight);
		}
		var log = logTxt;
		if (log.visible) {
			log.y = bg.y - log.textHeight + logDY;
			var dt = haxe.Timer.stamp() - lastLogTime;
			if (dt > 2 && !bg.visible) {
				log.alpha -= ctx.elapsedTime * 4;
				if (log.alpha <= 0)
					log.visible = false;
			}
		}

		if (bg.visible) {
			if (Player.inst != null && !Player.inst.isLocked())
				Player.inst.lock();
		} else if (Player.inst != null && Player.inst.isLocked())
			Player.inst.unlock();

		// bg.y = logTxt.y;
		// super.sync(ctx);
	}
}
