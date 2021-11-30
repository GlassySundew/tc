package ui;

import haxe.macro.Expr;
import h2d.filter.Bloom;
import h2d.filter.Ambient;
import haxe.CallStack;
import UniformPoissonDisc.UniformPoissonDisk;
import cherry.soup.EventSignal.EventSignal0;
import en.player.Player;
import format.tmx.Data.TmxMap;
import h2d.Graphics;
import h2d.Object;
import h2d.Tile;
import h2d.col.Point;
import h2d.filter.Blur;
import h3d.mat.Texture;
import haxe.Unserializer;
import haxe.crypto.Base64;
import haxe.ds.Map;
import hx.concurrent.Future.FutureResult;
import hx.concurrent.executor.Executor;
import hxbit.Serializable;
import hxbit.Serializer;
import mapgen.MapGen;
import seedyrng.Random;
import ui.domkit.NavigationComp;

@:forward
abstract NavigationFields( Array<NavigationField> ) {

	public function new( array : Array<NavigationField> ) {
		this = array;
	}

	@:arrayAccess
	inline function get( key : Int ) return this[key];

	public inline function push( field : NavigationField ) {
		@:privateAccess Navigation.inst.bodiesContainer.addChild(field.object);
		this.push(field);
	}
}

class Navigation extends NinesliceWindow {
	public static var inst : Navigation;

	var ca : dn.heaps.Controller.ControllerAccess;
	var navMask : FixedScrollArea;
	var bodiesContainer : Object;

	@:s var jumpReach : Float;

	public var locked(default, set) : Bool;

	function set_locked( locked : Bool ) : Bool {
		return this.locked = locked;
	}

	@:s public var fields : NavigationFields = new NavigationFields([]);

	public static var playersHeads : Map<Player, Object> = [];
	/** твинеры для бошек игроков **/
	public static var headsTweeners : Map<Player, { xTw : Tween, yTw : Tween }> = [];

	public static final fieldWidth : Int = 200;
	public static final fieldHeight : Int = 200;
	/**
		@param seed seed for icons generation
		@param parent must be existing object, otherwise there will be huge glitches
	**/
	public function new(
		jumpReach : Float,
		seed : String,
		?parent : Object
	) {
		super(
			NavigationComp,
			parent
		);

		this.jumpReach = jumpReach;
	}

	override function initLoad( ?parent : Object ) {
		super.initLoad(parent);
		inst = this;

		windowComp.window.windowLabel.labelTxt.text = "Navigation console";
		var navigationComp = cast(windowComp, NavigationComp);

		navMask = new FixedScrollArea(0, 0, true, true, navigationComp.nav_win);
		@:privateAccess navMask.sync(Boot.inst.s2d.ctx);
		navMask.fillHeight = navMask.fillWidth = false; // отключаем заполнение из-за бага, когда окно мерцает при добавлении arrowButton

		var scroller = new Dragable(navMask.width, navMask.height);
		scroller.cursor = Default;
		navigationComp.nav_win.addChildAt(scroller, 0);
		navigationComp.nav_win.getProperties(scroller).isAbsolute = true;

		bodiesContainer = new Object(navMask);
		bodiesContainer.scale(0.5);

		scroller.onDrag.add(( x, y ) -> navMask.scrollPixels(-x, -y));

		scroller.onClickEvent.add(( _ ) -> NavigationTarget.disposeArrowButton());
		// belt lock
		Game.inst.delayer.addF(() -> {
			if ( backgroundInter != null ) {
				backgroundInter.onOverEvent.add(( e ) -> {
					if ( Player.inst != null ) Player.inst.lockBelt();
				});
				backgroundInter.onOutEvent.add(( e ) -> {
					if ( Player.inst != null ) Player.inst.unlockBelt();
				});
			}
		}, 2);

		scroller.propagateEvents = true;
		recenter();

		toggleVisible();
		if ( parent != null ) {
			refreshLinks(Const.jumpReach);
		}

		NavigationTarget.onClick = ( x, y ) -> {
			var time = 500; // ms

			scroller.visible = false;
			Game.inst.tw.createMs(navMask.scrollX, Std.int((x) / Const.UI_SCALE - navMask.width / 2), time);
			Game.inst.tw.createMs(navMask.scrollY, Std.int((y) / Const.UI_SCALE - navMask.height / 2), time).end(
				() -> {
					scroller.visible = true;
				}
			);
		}
	}

	public function scrollToField( field : NavigationField ) {

		navMask.scrollTo(field.object.x
			- navMask.width / 2
			+ (fieldWidth / 2) * bodiesContainer.scaleX,
			field.object.y
			- navMask.height / 2
			+ (fieldHeight / 2) * bodiesContainer.scaleX);
	}

	override function toggleVisible() {
		super.toggleVisible();

		if ( win.parent != null ) refreshLinks(Const.jumpReach);

		// focus on player's cluster
		for ( field in fields ) {
			if ( Lambda.exists(field.targets, ( target ) -> target.id == Player.inst.residesOnId) ) {
				scrollToField(field);
				return;
			}
		}
	}

	public function refreshLinks( jumpReach : Float ) {

		if ( playersHeads[Player.inst] == null ) {
			// adding player's head
			for ( field in fields ) {
				for ( target in field.targets ) {
					if ( target.id == Player.inst.residesOnId ) {
						var head = new HSprite(Assets.ui, "player_head", target.object);
						head.scale(2);
						playersHeads[Player.inst] = head;
						break;
					}
				}
			}
		}

		if ( playersHeads[Player.inst] != null ) {
			for ( field in fields ) {
				for ( target in field.targets ) {
					if ( target.id == Player.inst.residesOnId ) {
						target.object.addChild(playersHeads[Player.inst]);
						playersHeads[Player.inst].x = 0;
						playersHeads[Player.inst].y = 0;
						break;
					}
				}
			}
		}

		for ( field in fields ) {
			for ( target in field.targets ) {
				for ( link in target.links ) link.graphics.remove();
				target.links = [];
			}
		}

		for ( field in fields ) {
			for ( i => targetI in field.targets ) {
				for ( j => targetJ in field.targets ) {
					if ( i < j // && !(Lambda.exists(targetI.links, ( link ) -> link.target == targetJ)
						// 	|| Lambda.exists(targetJ.links, ( link ) -> link.target == targetI))
						&& M.dist(targetI.object.x, targetI.object.y, targetJ.object.x, targetJ.object.y) < jumpReach ) {
						var line = new Graphics();

						bodiesContainer.addChildAt(line, 0);
						// line.smooth = true;
						line.x = targetI.object.x;
						line.y = targetI.object.y;
						var blur = new Bloom(2, 3, 1, 1, 1);

						line.filter = blur;
						line.lineStyle(3, 0xffffff, 0.55);
						line.beginFill(0xffffff);

						line.addVertex(0, 0, 255, 255, 255, 1);
						line.addVertex(targetJ.object.x - line.x, targetJ.object.y - line.y, 255, 255, 255, 1);
						line.endFill();
						if ( Player.inst.residesOnId != targetI.id && Player.inst.residesOnId != targetJ.id ) {
							line.visible = false;
							var dashes = new shader.Dashes();
							dashes.u_dashSize = 5;
							dashes.u_gapSize = 12;
							line.addShader(dashes);
						}
						targetI.links.push({
							target : targetJ,
							graphics : line
						});
						targetJ.links.push({
							target : targetI,
							graphics : line
						});
					}
				}
			}
		}
	}

	@:keep
	public override function customSerialize( ctx : hxbit.Serializer ) {
		super.customSerialize(ctx);
	}

	@:keep
	public override function customUnserialize( ctx : hxbit.Serializer ) {
		inst = this;
		super.customUnserialize(ctx);
	}

	public function getTargetById( id : String ) : NavigationTarget {
		for ( field in fields ) {
			for ( target in field.targets ) {
				if ( target.id == id ) return target;
			}
		}
		return null;
	}

	override function postUpdate() {
		super.postUpdate();

		if ( navMask != null ) {
			navMask.scrollX = navMask.scrollX - navMask.scrollX % bodiesContainer.scaleX;
			navMask.scrollY = navMask.scrollY - navMask.scrollY % bodiesContainer.scaleX;
		}
	}

	public function flushHeads() {
		for ( head in playersHeads ) {
			if ( head != null ) head.remove();
		}
	}

	override function onDispose() {
		super.onDispose();
		inst = null;
		flushHeads();
	}
}

class NavigationField implements Serializable {
	@:s public var targets : Array<NavigationTarget>;

	@:s var seed : String;

	@:s public var fieldX : Int;
	@:s public var fieldY : Int;

	public var object : Object;

	public function new(
		seed : String,
		fieldX : Int,
		fieldY : Int,
		?parent : Object
	) {
		this.fieldX = fieldX;
		this.fieldY = fieldY;
		this.seed = seed;

		initLoad(parent);
	}

	function initLoad( ?parent : Object ) {
		object = new Object(parent);

		targets = [];
		var points : Array<Point> = genAsteroidField(
			Navigation.fieldWidth,
			Navigation.fieldHeight,
			seed + 'field:$fieldX,$fieldY'
		);
		var random = new Random();
		random.setStringSeed(seed);

		for ( i => pt in points ) {
			var target : NavigationTarget = null;
			target = new NavigationTarget(
				random.choice([asteroid0, asteroid1, asteroid2, asteroid3]),
				seed,
				Std.int(pt.x),
				Std.int(pt.y),
				object);
			targets.push(target);
		}
	}

	@:keep
	public function customSerialize( ctx : hxbit.Serializer ) {}

	@:keep
	public function customUnserialize( ctx : hxbit.Serializer ) {
		initLoad();
	}

	public static function genAsteroidField( ?fieldWidth : Int = 200, ?fieldHeight = 200, seed : String ) : Array<Point> {
		var poissonMap = new UniformPoissonDisk(seed);
		var sampledPoints = poissonMap.sample(new Point(0, 0), new Point(fieldWidth, fieldWidth), ( p : Point, r : Random ) -> {
			return r.uniform(0.75, 1) * Const.jumpReach;
		}, Const.jumpReach);

		return sampledPoints;
	}
}

class NavigationTarget implements Serializable {
	var celestialObject : Button;

	@:s public var cdbEntry : Navigation_targetsKind;

	@:s public var id : String;
	/** string, под которым лежит карта в базе данных **/
	public var bodyLevelName(get, never) : String;

	inline function get_bodyLevelName() : String {
		return "asteroid_" + id;
	}

	@:s var seed : String;

	public var object : Object;

	static var arrowButton : Button;

	public var links : Array<{target : NavigationTarget, graphics : Graphics }> = [];

	public var generator : AsteroidGenerator;

	public static var onClick : Float -> Float -> Void;
	/**
		@param seed needed for generating id
		@param x needed for generating id
		@param y needed for generating id
	**/
	public function new( cdbEntry : Navigation_targetsKind, seed : String, x : Int, y : Int, ?parent : Object ) {
		this.cdbEntry = cdbEntry;
		this.seed = seed;

		initLoad(seed, x, y, parent);
	}

	function initLoad( seed : String, x : Int, y : Int, ?parent : Object ) {
		object = new Object(parent);
		object.setPosition(x, y);

		var r = new Random();
		r.setStringSeed(seed + x + y);
		id = r.seededString(10);

		createGenerator();

		var sprite = new HSprite(Assets.ui, Data.navigation_targets.get(cdbEntry).atlas_name);

		// selected frame
		var selectedTex = new Texture(Std.int(sprite.tile.width), Std.int(sprite.tile.height), [Target]);
		sprite.drawTo(selectedTex);
		new HSprite(Assets.ui, "body_selected").drawTo(selectedTex);

		celestialObject = new Button([sprite.tile, Tile.fromTexture(selectedTex)], object);
		celestialObject.x -= celestialObject.width / 2;
		celestialObject.y -= celestialObject.height / 2;
		celestialObject.propagateEvents = true;

		celestialObject.onClickEvent.add(( e ) -> {
			if ( Navigation.inst.locked ) return;

			// when click, all other arrow buttons must be removed
			disposeArrowButton();

			if ( Lambda.exists(links, ( link ) -> Player.inst.residesOnId == link.target.id) ) {
				arrowButton = new Button([
					new HSprite(Assets.ui, "travel_but0").tile,
					new HSprite(Assets.ui, "travel_but1").tile,
					new HSprite(Assets.ui, "travel_but2").tile
				]);
				parent.addChild(arrowButton);
				arrowButton.scale(2);
				arrowButton.x = -arrowButton.width + x;
				arrowButton.y = -arrowButton.height - sprite.tile.height - 8 + y;

				arrowButton.onClickEvent.add(( _ ) -> {
					travelToThis();
				});
			}

			onClick(x, y);
		});

		celestialObject.onOverEvent.add(( e ) -> {
			for ( l in links ) l.graphics.visible = true;
		});

		celestialObject.onOutEvent.add(( e ) -> {
			if ( Player.inst.residesOnId != id ) for ( l in links ) if ( Player.inst.residesOnId != l.target.id ) l.graphics.visible = false;
		});
	}

	function travelToThis() {
		disposeArrowButton();
		Player.inst.ui.unprepareTeleport();
		Navigation.inst.locked = true;

		// creating tweener for head
		createTweener(Player.inst, new h3d.col.Point(object.x, object.y));
	}

	function createTweener( player : Player, to : h3d.col.Point ) {
		var wherePlayerIs = Navigation.playersHeads[player].parent;
		var time = M.dist(wherePlayerIs.x, wherePlayerIs.y, to.x, to.y) * 50;


		Navigation.headsTweeners[player] = {
			xTw : Game.inst.tw.createMs(
				Navigation.playersHeads[player].x,
				Std.int(to.x - Navigation.playersHeads[player].parent.x),
				time),
			yTw : Game.inst.tw.createMs(
				Navigation.playersHeads[player].y,
				Std.int(to.y - Navigation.playersHeads[player].parent.y),
				time)
		};

		Game.inst.delayer.addMs(() -> {
			stopHeadTweeners(player);
			Player.inst.residesOnId = id;
			Player.inst.checkTeleport(true);
			Navigation.inst.refreshLinks(Const.jumpReach);
			Navigation.inst.locked = false;
		}, time);
	}

	public function stopHeadTweeners( player : Player ) {
		var head = Navigation.headsTweeners[player];

		if ( head.xTw != null ) {
			head.xTw.endWithoutCallbacks();
			head.xTw = null;
		}

		if ( head.yTw != null ) {
			head.yTw.endWithoutCallbacks();
			head.yTw = null;
		}
	}

	public function createGenerator() {
		generator = new AsteroidGenerator(bodyLevelName);
	}

	@:keep
	public function customSerialize( ctx : hxbit.Serializer ) {
		ctx.addInt(Std.int(object.x));
		ctx.addInt(Std.int(object.y));
	}

	@:keep
	public function customUnserialize( ctx : hxbit.Serializer ) {
		var x = ctx.getInt();
		var y = ctx.getInt();

		generator = new AsteroidGenerator(bodyLevelName);

		Game.inst.delayer.addF(() -> {
			initLoad(seed, x, y);
		}, 1);
	}

	public static function disposeArrowButton() {
		if ( arrowButton != null ) {
			arrowButton.remove();
		}
	}
}
/** если инстанс живой, но tmxMap null, то она генерируется**/
class AsteroidGenerator {
	public var onGeneration : EventSignal0;
	public var name : String;
	public var tmxMap : TmxMap;
	public var mapIsGenerating(get, never) : Bool;

	static var executor : Executor;

	inline function get_mapIsGenerating() : Bool return tmxMap == null;

	public function new( name : String, ?onGeneration : Void -> Void ) {
		this.name = name;
		this.onGeneration = new EventSignal0();
		if ( onGeneration != null ) this.onGeneration.add(onGeneration);
		if ( executor == null ) executor = Executor.create(3);

		var lvl = tools.Save.inst.getLevelByName(name);
		if ( lvl != null ) {
			tmxMap = Unserializer.run(Base64.decode(lvl.tmx).toString());
		} else {
			generateAsteroid();
		}
	}

	public function generateAsteroid() {
		var future : TaskFuture<TmxMap> = null;
		future = executor.submit(() -> {
			var autoMapper = new mapgen.AutoMap("tiled/levels/rules.txt");
			var mapGen = new MapGen(Unserializer.run(haxe.Serializer.run(MapCache.inst.get('procgen/asteroids.tmx'))), autoMapper);
			return autoMapper.applyRulesToMap(mapGen.generate(50, 50, 100, 5, 15));
		});

		future.onResult = ( result : FutureResult<TmxMap> ) -> {
			switch result {
				case SUCCESS(tmxMap, time, future):
					this.tmxMap = tmxMap;
					tools.Save.inst.upsertLevelMap(name, tmxMap);
					onGeneration.dispatch();
				case FAILURE(ex, time, future):
					throw "unexpected result";
				default:
			}
		}
	}
}
