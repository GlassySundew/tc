package ui.player;

import h2d.Object;
import Game.LevelLoadPlayerConfig;
import dn.Process;
import en.player.Player;
import format.tmx.Data.TmxMap;
import h2d.Flow;
import h2d.Layers;
import h3d.Vector;
import tools.Settings;
import ui.InventoryGrid.CellGrid;
import ui.domkit.SideComp;

enum JumpDirection {
	Up;
	Down;
}

class PlayerUI extends Process {
	public var inventory : Inventory;
	public var belt : Belt;

	public var craft : PlayerCrafting;

	var baseFlow : Flow;

	var topLeft : SideComp;
	var topRight : SideComp;

	var teleport : Button;

	public function new( parent : Layers ) {
		super(Game.inst);

		createRootInLayers(Game.inst.root, Const.DP_UI);

		baseFlow = new Flow(root);

		if ( Player.inst.cellGrid == null ) Player.inst.cellGrid = new CellGrid(5, 6, 18, 18, Player.inst);

		inventory = new Inventory(Player.inst.cellGrid, root);
		inventory.containmentEntity = Player.inst;

		inventory.recenter();

		inventory.win.x = Settings.params.inventoryCoordRatio.toString() == new Vector(-1,
			-1).toString() ? inventory.win.x : Settings.params.inventoryCoordRatio.x * Main.inst.w();
		inventory.win.y = Settings.params.inventoryCoordRatio.toString() == new Vector(-1,
			-1).toString() ? inventory.win.y : Settings.params.inventoryCoordRatio.y * Main.inst.h();

		root.add(inventory.win, Const.DP_UI);
		if ( Settings.params.inventoryVisible ) inventory.toggleVisible();

		belt = new Belt(Player.inst.cellGrid.grid[Player.inst.cellGrid.grid.length - 1], root);
		root.add(belt, Const.DP_UI_FRONT);

		topLeft = new SideComp(Top, Left, root);
		root.add(topLeft, Const.DP_UI);

		topRight = new SideComp(Top, Right, baseFlow);
		topRight.paddingTop = topRight.paddingRight = 2;
		topRight.verticalSpacing = 2;
		topRight.layout = Vertical;

		root.add(topLeft, Const.DP_UI);

		craft = new PlayerCrafting(Player, root);
		root.add(craft.win, Const.DP_UI);

		var craftWinToggle = new Button([
			new HSprite(Assets.ui, "craftWinToggle0").tile,
			new HSprite(Assets.ui, "craftWinToggle1").tile
		],
			topRight);
		craftWinToggle.onClickEvent.add(( e ) -> {
			craft.toggleVisible();
		});

		var inventoryWinToggle = new Button([
			new HSprite(Assets.ui, "inventoryWinToggle0").tile,
			new HSprite(Assets.ui, "inventoryWinToggle1").tile
		],
			topRight);
		inventoryWinToggle.onClickEvent.add(( e ) -> {
			inventory.toggleVisible();
		});

		teleport = new Button(
			[
				new HSprite(Assets.ui, "tp0").tile,
				new HSprite(Assets.ui, "tp1").tile
			],
			topRight);
		teleport.visible = false;

		onResize();

		// new StatView(Health, topLeft);

		// var style = new h2d.domkit.Style();
		// style.load(hxd.Res.domkit.side);
		// style.addObject(topLeft);
	}

	public function prepareTeleportDown( name : String, acceptTmxPlayerCoord : Bool = false ) {
		teleport.scaleY = 1;
		topRight.getProperties(teleport).offsetY = 0;
		prepareTeleport(name, { acceptTmxPlayerCoord : acceptTmxPlayerCoord }, Down);
	}

	public function prepareTeleportUp( name : String, acceptTmxPlayerCoord : Bool ) {
		teleport.scaleY = -1;
		topRight.getProperties(teleport).offsetY = Std.int(teleport.height);
		prepareTeleport(name, { acceptTmxPlayerCoord : acceptTmxPlayerCoord, acceptSqlPlayerCoord : true }, Up);
	}

	public inline function prepareTeleport( name : String, playerLoadConf : LevelLoadPlayerConfig, jumpDirection : JumpDirection ) {
		teleport.visible = true;
		teleport.y = 0;
		teleport.onClickEvent.add(( _ ) -> {
			Player.inst.onBoard = switch jumpDirection {
				case Up: true;
				case Down: false;
			}
			Game.inst.startLevel(name, playerLoadConf);
		});
	}

	public function unprepareTeleport() {
		teleport.visible = false;
		Player.onGenerationCallback = () -> {};
		teleport.onClickEvent.removeAll();
	}

	override function onResize() {
		super.onResize();
		topRight.minWidth = wScaled;
	}
}

class PlayerCrafting extends Crafting {
	public function new( source : Data.Recipes_recipe_source, ?parent : Object ) {
		super(source, parent);

		windowComp.window.onDrag.add(( x, y ) -> {
			Settings.params.playerCrafting.x = win.x / Main.inst.w();
			Settings.params.playerCrafting.y = win.y / Main.inst.h();
		});
	}

	override function toggleVisible() {
		super.toggleVisible();

		win.x = Settings.params.playerCrafting.toString() == new Vector(-1, -1).toString() ? win.x : Settings.params.playerCrafting.x * Main.inst.w();
		win.y = Settings.params.playerCrafting.toString() == new Vector(-1, -1).toString() ? win.y : Settings.params.playerCrafting.y * Main.inst.h();
	}
}
