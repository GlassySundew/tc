package ui.player;

import dn.Process;
import en.player.Player;
import format.tmx.Data.TmxMap;
import h2d.Flow;
import h2d.Layers;
import h3d.Vector;
import tools.Settings;
import ui.InventoryGrid.CellGrid;
import ui.domkit.SideComp;

class PlayerUI extends Process {
	public var inventory : Inventory;
	public var belt : Belt;

	public var craft : Crafting;

	var flow : Flow;
	var topLeft : SideComp;

	var topRight : SideComp;

	var teleport : Button;

	public function new( parent : Layers ) {
		super(Game.inst);

		createRootInLayers(Game.inst.root, Const.DP_UI);

		flow = new Flow(root);

		if ( Player.inst.invGrid == null ) Player.inst.invGrid = new CellGrid(5, 6, 18, 18, Player.inst);

		inventory = new Inventory(Player.inst.invGrid, root);
		inventory.containmentEntity = Player.inst;

		inventory.win.x = Settings.params.inventoryCoordRatio.toString() == new Vector(-1,
			-1).toString() ? inventory.win.x : Settings.params.inventoryCoordRatio.x * Main.inst.w();
		inventory.win.y = Settings.params.inventoryCoordRatio.toString() == new Vector(-1,
			-1).toString() ? inventory.win.y : Settings.params.inventoryCoordRatio.y * Main.inst.h();

		root.add(inventory.win, Const.DP_UI);
		if ( Settings.params.inventoryVisible ) inventory.toggleVisible();

		belt = new Belt(Player.inst.invGrid.grid[Player.inst.invGrid.grid.length - 1], root);
		root.add(belt, Const.DP_UI_FRONT);

		topLeft = new SideComp(Top, Left, root);
		root.add(topLeft, Const.DP_UI);

		topRight = new SideComp(Top, Right, flow);
		topRight.paddingTop = topRight.paddingRight = 2;

		root.add(topLeft, Const.DP_UI);

		craft = new Crafting(root);
		root.add(craft.win, Const.DP_UI);

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

	public function prepareTeleportDown( name : String ,acceptTmxPlayerCoord:Bool = false) {
		teleport.scaleY = 1;
		prepareTeleport(name, acceptTmxPlayerCoord);
	}

	public function prepareTeleportUp( name : String,acceptTmxPlayerCoord:Bool ) {
		teleport.scaleY = -1;
		prepareTeleport(name, acceptTmxPlayerCoord);
	}

	public inline function prepareTeleport( name : String, acceptTmxPlayerCoord:Bool ) {
		teleport.visible = true;
		teleport.onClickEvent.add(( _ ) -> Game.inst.startLevel(name, false, acceptTmxPlayerCoord));
	}

	public function unprepareTeleport() {
		teleport.visible = false;
		teleport.onClickEvent.removeAll();
	}

	override function onResize() {
		super.onResize();
		topRight.minWidth = wScaled;
	}
}
