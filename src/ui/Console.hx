package ui;

import h2d.Console.ConsoleArgDesc;
import en.player.Player;
import h3d.scene.Renderer;
import h2d.Console.ConsoleArg;
import dn.Lib;

class Console extends h2d.Console {
	public static var inst : Console;

	#if debug
	var flags : Map<String, Bool>;
	#end

	public function new(f : h2d.Font, p : h2d.Object) {
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
		this.addCommand("set", [{name: "k", t: AString}], function(k : String) {
			setFlag(k, true);
			log("+ " + k, 0x80FF00);
		});
		this.addCommand("unset", [{name: "k", t: AString, opt: true}], function(?k : String) {
			if ( k == null ) {
				log("Reset all.", 0xFF0000);
				flags = new Map();
			} else {
				log("- " + k, 0xFF8000);
				setFlag(k, false);
			}
		});
		var pp : Bool = true;
		this.addCommand("pp", [], function(?k : String) {
			if ( pp ) {
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

		this.addCommand("untarget", [], function(?k : String) {
			Game.inst.camera.stopTracking();
			new h3d.scene.CameraController(Boot.inst.s3d).loadFromCamera();
			Level.inst.cursorInteract.visible = false;
		});

		this.addCommand("loadlvl", [{name: "k", t: AEnum(["hui", "hui1"])}], function(?k : String) {
			Game.inst.startLevel(k + ".tmx");
		});
		this.addCommand("giveItem", [{name: "item", t: AString, opt: false}, {name: "amount", t: AInt, opt: true}],
			function(?k : Data.ItemsKind, ?amount : Int = 1) {
				if ( Data.items.get(k) != null ) {
					var newItem = Item.fromCdbEntry(k);
					newItem.amount = amount;
					Game.inst.player.ui.inventory.invGrid.giveItem(newItem);
				}
			});

		this.addCommand("connect", [], function(?k : String) {
			// (new Connect());
		});

		this.addAlias("+", "set");
		this.addAlias("-", "unset");
		#end
	}

	#if debug
	public function setFlag(k : String, v) return flags.set(k, v);

	public function hasFlag(k : String) return flags.get(k) == true;
	#else
	public function hasFlag(k : String) return false;
	#end

	override public function addAlias(name, command) {
		aliases.set("/" + name, command);
	}

	override function addCommand(name : String, ?help : String, args : Array<ConsoleArgDesc>, callb : Dynamic) {
		commands.set("/" + name, {help: help == null ? "" : help, args: args, callb: callb});
	}

	// override function runCommand(commandLine:String) {
	// 	handleCommand(commandLine.split("/")[0]);
	// }
	override function handleCommand(command : String) {
		command = StringTools.trim(command);
		// if( command.charCodeAt(0) == "/".code ) command = command.substr(1);
		if ( command == "" ) {
			hide();
			return;
		}
		logs.push(command);
		logIndex = -1;

		var errorColor = 0xC00000;

		var args = [];
		var c = '';
		var i = 0;

		function readString(endChar : String) {
			var string = '';

			while( i < command.length ) {
				c = command.charAt(++i);
				if ( c == endChar ) {
					++i;
					return string;
				}
				string += c;
			}

			return null;
		}

		inline function skipSpace() {
			c = command.charAt(i);
			while( c == ' ' || c == '\t' ) {
				c = command.charAt(++i);
			}
			--i;
		}

		var last = '';
		while( i < command.length ) {
			c = command.charAt(i);

			switch( c ) {
				case ' ' | '\t':
					skipSpace();

					args.push(last);
					last = '';
				case "'" | '"':
					var string = readString(c);
					if ( string == null ) {
						log('Bad formated string', errorColor);
						return;
					}

					args.push(string);
					last = '';

					skipSpace();
				default:
					last += c;
			}

			++i;
		}
		args.push(last);

		var cmdName = args[0];
		if ( aliases.exists(cmdName) ) cmdName = aliases.get(cmdName);
		var cmd = commands.get(cmdName);
		if ( cmd == null ) {
			log('Unknown command "${cmdName}"', errorColor);
			return;
		}
		var vargs = new Array<Dynamic>();
		for (i in 0...cmd.args.length) {
			var a = cmd.args[i];
			var v = args[i + 1];
			if ( v == null ) {
				if ( a.opt ) {
					vargs.push(null);
					continue;
				}
				log('Missing argument ${a.name}', errorColor);
				return;
			}
			switch( a.t ) {
				case AInt:
					var i = Std.parseInt(v);
					if ( i == null ) {
						log('$v should be Int for argument ${a.name}', errorColor);
						return;
					}
					vargs.push(i);
				case AFloat:
					var f = Std.parseFloat(v);
					if ( Math.isNaN(f) ) {
						log('$v should be Float for argument ${a.name}', errorColor);
						return;
					}
					vargs.push(f);
				case ABool:
					switch( v ) {
						case "true", "1": vargs.push(true);
						case "false", "0": vargs.push(false);
						default:
							log('$v should be Bool for argument ${a.name}', errorColor);
							return;
					}
				case AString:
					// if we take a single string, let's pass the whole args (allows spaces)
					vargs.push(cmd.args.length == 1 ? StringTools.trim(command.substr(args[0].length)) : v);
				case AEnum(values):
					var found = false;
					for (v2 in values) if ( v == v2 ) {
						found = true;
						vargs.push(v2);
					}
					if ( !found ) {
						log('$v should be [${values.join("|")}] for argument ${a.name}', errorColor);
						return;
					}
			}
		}
		try {
			Reflect.callMethod(null, cmd.callb, vargs);
		}
		catch( e:String ) {
			log('ERROR $e', errorColor);
		}
	}

	override function showHelp(?command : String) {
		var all;
		if ( command == null ) {
			all = Lambda.array({iterator: function() return commands.keys()});
			all.sort(Reflect.compare);
			all.remove("/help");
			all.push("/help");
		} else {
			if ( aliases.exists(command) ) command = aliases.get(command);
			if ( !commands.exists(command) ) throw 'Command not found "$command"';
			all = [command];
		}
		for (cmdName in all) {
			var c = commands.get(cmdName);
			var str = cmdName;
			for (a in aliases.keys()) if ( aliases.get(a) == cmdName ) str += "|" + a;
			for (a in c.args) {
				var astr = a.name;
				switch( a.t ) {
					case AInt, AFloat:
						astr += ":" + a.t.getName().substr(1);
					case AString:
					// nothing
					case AEnum(values):
						astr += "=" + values.join("|");
					case ABool:
						astr += "=0|1";
				}
				str += " " + (a.opt ? "[" + astr + "]" : astr);
			}
			if ( c.help != "" ) str += " : " + c.help;
			log(str);
		}
	}

	override function show() {
		super.show();
		logTxt.visible = true;
		logTxt.alpha = 1;
	}

	override function sync(ctx : h2d.RenderContext) {
		var scene = ctx.scene;
		if ( scene != null ) {
			x = 0;
			y = scene.height - height;
			width = scene.width;
			tf.maxWidth = width;

			bg.tile.scaleToSize(width, -logTxt.textHeight);
			bg.tile.dy = logTxt.font.lineHeight;
		}
		var log = logTxt;
		if ( log.visible ) {
			log.y = bg.y - log.textHeight + logDY + log.font.lineHeight;
			var dt = haxe.Timer.stamp() - lastLogTime;
			if ( dt > 2 && !bg.visible ) {
				log.alpha -= ctx.elapsedTime * 4;
				if ( log.alpha <= 0 ) log.visible = false;
			}
		}

		if ( bg.visible ) {
			if ( Player.inst != null && Player.inst.isAlive() && !Player.inst.isLocked() ) Player.inst.lock();
		} else if ( Player.inst != null && Player.inst.isAlive() && Player.inst.isLocked() ) Player.inst.unlock();
	}
}
