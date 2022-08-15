package ui;

import en.util.item.InventoryCell;
import pass.CustomRenderer;
import game.client.level.Level;
import game.client.GameClient;
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

	public function new( f : h2d.Font, p : h2d.Object ) {
		super( f, p );
		logTxt = new h2d.HtmlText( f, this );
		logTxt.x = 2;
		logTxt.dropShadow = {
			dx : 0,
			dy : 1,
			color : 0,
			alpha : 0.5
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
		this.addCommand( "set", [{ name : "k", t : AString }], function ( k : String ) {
			setFlag( k, true );
			log( "+ " + k, 0x80FF00 );
		} );
		this.addCommand( "unset", [{ name : "k", t : AString, opt : true }], function ( ?k : String ) {
			if ( k == null ) {
				log( "Reset all.", 0xFF0000 );
				flags = new Map();
			} else {
				log( "- " + k, 0xFF8000 );
				setFlag( k, false );
			}
		} );

		this.addCommand( "giveItem", [
			{ name : "item", t : AString, opt : false },
			{ name : "amount", t : AInt, opt : true }
		], function ( ?k : Data.ItemKind, ?amount : Int = 1 ) {
			if ( Data.item.get( k ) != null ) {
				var cell = new InventoryCell( Cursor, null );
				cell.item = Item.fromCdbEntry( k, Player.inst, amount );
				Player.inst.inventory.giveItem( cell, false );
			}
		} );

		this.addCommand( "connect", [], function ( ?k : String ) {
			// (new Connect());
		} );

		this.addCommand( "hud", [], function ( ?k : String ) {
			Player.inst.pui.root.visible = !Player.inst.pui.root.visible;
		} );

		this.addAlias( "+", "set" );
		this.addAlias( "-", "unset" );

		this.addCommand( "untarget", [], function ( ?k : String ) {
			if ( GameClient.inst != null )
				GameClient.inst.camera.stopTracking();
			var cam = new h3d.scene.CameraController( Boot.inst.s3d );
			cam.lockZPlanes = true;
			cam.loadFromCamera();
		} );

		this.addCommand( "loadlvl", [{ name : "k", t : AString }], function ( name : String, ?manual : Bool = true ) {
			// GameClient.inst.startLevel(name + ".tmx", { manual : true });
		} );
		var pp : Bool = true;
		this.addCommand( "pp", [], function ( ?k : String ) {
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
		} );
		#end
	}

	#if debug
	public function setFlag( k : String, v ) return flags.set( k, v );

	public function hasFlag( k : String ) return flags.get( k ) == true;
	#else
	public function hasFlag( k : String ) return false;
	#end

	override function show() {
		super.show();
		logTxt.visible = true;
		logTxt.alpha = 1;

		if ( Player.inst != null && !Player.inst.isLocked() )
			Player.inst.lock();
	}

	override function hide() {
		super.hide();

		if ( Player.inst != null && Player.inst.isLocked() )
			Player.inst.unlock();
	}

	override function sync( ctx : h2d.RenderContext ) {
		super.sync( ctx );

		var scene = ctx.scene;
		if ( scene != null ) {
			x = 0;
			y = scene.height - height;
			width = scene.width;
			tf.maxWidth = width;
			bg.tile.scaleToSize( width, -logTxt.textHeight );
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
	}

	override function getCommandSuggestion( cmd : String ) : String {
		var hadShortKey = false;
		if ( cmd.charCodeAt( 0 ) == shortKeyChar ) {
			hadShortKey = true;
			cmd = cmd.substr( 1 );
		}

		if ( cmd == "" || !hadShortKey ) {
			return "";
		}

		var closestCommand = "";
		var commandNames = commands.keys();
		for ( command in commandNames ) {
			if ( command.indexOf( cmd ) == 0 ) {
				if ( closestCommand == "" || closestCommand.length > command.length ) {
					closestCommand = command;
				}
			}
		}

		if ( aliases.exists( cmd ) )
			closestCommand = cmd;

		if ( hadShortKey && closestCommand != "" )
			closestCommand = String.fromCharCode( shortKeyChar ) + closestCommand;
		return closestCommand;
	}

	override function handleCommand( command : String ) {
		command = StringTools.trim( command );
		var validCommand = false;
		if ( command.charCodeAt( 0 ) == shortKeyChar ) {
			command = command.substr( 1 );
			validCommand = true;
		}
		if ( command == "" ) {
			hide();
			return;
		}
		logs.push( String.fromCharCode( shortKeyChar ) + command );
		logIndex = -1;

		if ( !validCommand ) {
			log( 'Unknown command "$command"', errorColor );
			return;
		}

		var args = [];
		var c = '';
		var i = 0;

		function readString( endChar : String ) {
			var string = '';

			while( i < command.length ) {
				c = command.charAt( ++i );
				if ( c == endChar ) {
					++i;
					return string;
				}
				string += c;
			}

			return null;
		}

		inline function skipSpace() {
			c = command.charAt( i );
			while( c == ' ' || c == '\t' ) {
				c = command.charAt( ++i );
			}
			--i;
		}

		var last = '';
		while( i < command.length ) {
			c = command.charAt( i );

			switch( c ) {
				case ' ' | '\t':
					skipSpace();

					args.push( last );
					last = '';
				case "'" | '"':
					var string = readString( c );
					if ( string == null ) {
						log( 'Bad formated string', errorColor );
						return;
					}

					args.push( string );
					last = '';

					skipSpace();
				default:
					last += c;
			}

			++i;
		}
		args.push( last );

		var cmdName = args[0];
		if ( aliases.exists( cmdName ) ) cmdName = aliases.get( cmdName );
		var cmd = commands.get( cmdName );
		if ( cmd == null ) {
			log( 'Unknown command "${cmdName}"', errorColor );
			return;
		}
		var vargs = new Array<Dynamic>();
		for ( i in 0...cmd.args.length ) {
			var a = cmd.args[i];
			var v = args[i + 1];
			if ( v == null ) {
				if ( a.opt ) {
					vargs.push( null );
					continue;
				}
				log( 'Missing argument ${a.name}', errorColor );
				return;
			}
			switch( a.t ) {
				case AInt:
					var i = Std.parseInt( v );
					if ( i == null ) {
						log( '$v should be Int for argument ${a.name}', errorColor );
						return;
					}
					vargs.push( i );
				case AFloat:
					var f = Std.parseFloat( v );
					if ( Math.isNaN( f ) ) {
						log( '$v should be Float for argument ${a.name}', errorColor );
						return;
					}
					vargs.push( f );
				case ABool:
					switch( v ) {
						case "true", "1": vargs.push( true );
						case "false", "0": vargs.push( false );
						default:
							log( '$v should be Bool for argument ${a.name}', errorColor );
							return;
					}
				case AString:
					// if we take a single string, let's pass the whole args (allows spaces)
					vargs.push( cmd.args.length == 1 ? StringTools.trim( command.substr( args[0].length ) ) : v );
				case AEnum( values ):
					var found = false;
					for ( v2 in values )
						if ( v == v2 ) {
							found = true;
							vargs.push( v2 );
						}
					if ( !found ) {
						log( '$v should be [${values.join( "|" )}] for argument ${a.name}', errorColor );
						return;
					}
			}
		}

		doCall( cmd.callb, vargs );
	}
}
