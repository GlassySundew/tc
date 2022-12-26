package ui.player;

import util.Util;
import dn.heaps.slib.HSprite;
import util.tools.Settings;
import util.Const;
import dn.Process;
import en.player.Player;
import en.util.item.InventoryCell;
import game.client.GameClient;
import h2d.Flow;
import h2d.Layers;
import h2d.Object;
import h3d.Vector;
import ui.core.Button;
import ui.core.InventoryGrid.InventoryCellFlowGrid;
import ui.domkit.SideComp;
import util.Assets;

class PlayerUI extends Process {

	public var cellFlowGrid : InventoryCellFlowGrid;
	public var inventory : Inventory;
	public var belt : Belt;

	public var craft : PlayerCrafting;

	var baseFlow : Flow;

	var topLeft : SideComp;
	var topRight : SideComp;
	var botLeft : SideComp;

	var teleport : Button;

	/**
		всегда последний массив в инвентаре
	**/
	public var beltLayer( get, never ) : Array<InventoryCell>;

	function get_beltLayer() : Array<InventoryCell> {
		return player.inventoryModel.inventory.grid[player.inventoryModel.inventory.grid.length - 1];
	}

	var player : Player;

	public function new( parent : Layers, player : Player ) {
		super( GameClient.inst );
		this.player = player;

		baseFlow = new Flow( GameClient.inst.root );

		topLeft = new SideComp( Top, Left, baseFlow );
		topRight = new SideComp( Top, Right, baseFlow );
		topRight.paddingTop = topRight.paddingRight = 2;
		topRight.verticalSpacing = 2;
		topRight.layout = Vertical;

		botLeft = new SideComp( Bottom, Left, baseFlow );

		baseFlow.getProperties( topLeft ).isAbsolute = true;
		baseFlow.getProperties( topRight ).isAbsolute = true;
		baseFlow.getProperties( botLeft ).isAbsolute = true;
		baseFlow.getProperties( topLeft ).align( Top, Left );
		baseFlow.getProperties( topRight ).align( Top, Right );
		baseFlow.getProperties( botLeft ).align( Bottom, Left );

		if ( player.inventoryModel.inventory != null ) {
			cellFlowGrid = new InventoryCellFlowGrid(
				player.inventoryModel.inventory, 20, 20
			);
			belt = new Belt( beltLayer, botLeft );
		}

		inventory = new Inventory( cellFlowGrid, GameClient.inst.root );
		inventory.containmentEntity = player;

		inventory.recenter();

		inventory.win.x = Settings.params.inventoryCoordRatio.toString() == new Vector( -1,
			-1 ).toString() ? inventory.win.x : Settings.params.inventoryCoordRatio.x * Main.inst.w();
		inventory.win.y = Settings.params.inventoryCoordRatio.toString() == new Vector( -1,
			-1 ).toString() ? inventory.win.y : Settings.params.inventoryCoordRatio.y * Main.inst.h();

		GameClient.inst.root.add( inventory.win, Const.DP_UI );
		if ( Settings.params.inventoryVisible ) inventory.toggleVisible();

		craft = new PlayerCrafting( Player, GameClient.inst.root );
		GameClient.inst.root.add( craft.win, Const.DP_UI );

		var craftWinToggle = new Button( [
			new HSprite( Assets.ui, "craftWinToggle0" ).tile,
			new HSprite( Assets.ui, "craftWinToggle1" ).tile
		],
			topRight );

		craftWinToggle.onClickEvent.add( ( e ) -> {
			craft.toggleVisible();
		} );

		var inventoryWinToggle = new Button( [
			new HSprite( Assets.ui, "inventoryWinToggle0" ).tile,
			new HSprite( Assets.ui, "inventoryWinToggle1" ).tile
		],
			topRight );

		inventoryWinToggle.onClickEvent.add( ( e ) -> {
			inventory.toggleVisible();
		} );

		teleport = new Button(
			[
				new HSprite( Assets.ui, "tp0" ).tile,
				new HSprite( Assets.ui, "tp1" ).tile
			],
			topRight );
		teleport.visible = false;

		onResize();

		// new StatView(Health, topLeft);

		// var style = new h2d.domkit.Style();
		// style.load(hxd.Res.domkit.side);
		// style.addObject(topLeft);
	}

	override function onResize() {
		super.onResize();
		baseFlow.minWidth = Util.wScaled;
		baseFlow.minHeight = Util.hScaled;
	}
}

class PlayerCrafting extends Crafting {

	public function new( source : Data.Recipe_recipe_source, ?parent : Object ) {
		super( source, parent );

		windowComp.window.onDrag.add( ( x, y ) -> {
			Settings.params.playerCrafting.x = win.x / Main.inst.w();
			Settings.params.playerCrafting.y = win.y / Main.inst.h();
		} );
	}

	override function toggleVisible() {
		super.toggleVisible();

		win.x = Settings.params.playerCrafting.toString() == new Vector( -1, -1 ).toString() ? win.x : Settings.params.playerCrafting.x * Main.inst.w();
		win.y = Settings.params.playerCrafting.toString() == new Vector( -1, -1 ).toString() ? win.y : Settings.params.playerCrafting.y * Main.inst.h();
	}
}
