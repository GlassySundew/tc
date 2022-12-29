package ui.dialog;

import dn.heaps.slib.HSprite;
import util.Const;
import util.Util;
import dn.M;
import util.tools.Settings;
import ui.core.Button;
import ui.core.ShadowedText;
import ui.core.VerticalSlider;
import ui.core.FixedScrollArea;
import util.Assets;
import net.Client;
import ch2.ui.EventInteractive;
import dn.Process;
import h2d.Bitmap;
import h2d.Flow;
import h2d.Object;
import h2d.ScaleGrid;
import h2d.Tile;
import h2d.col.Bounds;
import h2d.col.Point;
import hxd.Event;
import net.ClientController;
import ui.dialog.FocusMenu;
import ui.domkit.SaveManagerComp;

enum Mode {
	Save;
	Load;
	NewSaveEntry;
}

class SaveManager extends FocusMenu {

	public static var inst : SaveManager;

	public var scrollVoid : Event -> Void;

	var saveEntriesFlow : Flow;

	public var scrollArea : FixedScrollArea;

	var mode : Mode;

	public var entries : Array<SaveEntry> = [];

	public static var colWidth : Int = 300;

	var sliderBack : Bitmap;
	var backgroundScroll : EventInteractive;
	var grid : ScaleGrid;
	var slider : VerticalSlider;
	var areaBarFlow : Flow;

	public var onGameStart : () -> Void;

	override function get_contentTopPadding() : Int
		return 0;

	public function new( mode : Mode, ?onGameStart : () -> Void, ?parent : Object ) {
		super( parent );

		inst = this;

		this.mode = mode;
		this.onGameStart = onGameStart;

		Settings.refreshSaves();
		centrizeContent();

		var comp = new SaveManagerComp( mode, Settings.params.saveFiles, contentFlow );

		// deprecated below

		return;

		var generalFlow = new Flow( h2dObject );
		generalFlow.layout = Vertical;
		generalFlow.horizontalAlign = Middle;

		generalFlow.x += Util.wScaled >> 2;

		var signText = new ShadowedText( Assets.fontPixel, generalFlow );
		signText.text = switch mode {
			case Save: "Save file: ";
			case Load: "Load file: ";
			default: "";
		};

		areaBarFlow = new Flow( generalFlow );
		areaBarFlow.layout = Horizontal;
		areaBarFlow.verticalAlign = Top;
		areaBarFlow.padding = 5;
		areaBarFlow.enableInteractive = true;
		areaBarFlow.overflow = Limit;

		scrollArea = new FixedScrollArea( colWidth, 0, 16, areaBarFlow );
		scrollArea.height = Std.int( Util.hScaled - h2dObject.y - 20 );
		backgroundScroll = new EventInteractive( 0, 0, scrollArea );

		saveEntriesFlow = new Flow( scrollArea );
		saveEntriesFlow.layout = Vertical;

		areaBarFlow.addSpacing( 10 );
		areaBarFlow.backgroundTile = Tile.fromColor( 0x000000, 1, 1, 0.6 );

		sliderBack = new Bitmap( Tile.fromColor( 0x222222, 10, 10, 1 ), areaBarFlow );

		grid = new ScaleGrid( Tile.fromColor( 0x8f8f8f, 1, 1, 1 ), 1, 1, 1, 1, h2dObject );
		slider = new VerticalSlider( 10, scrollArea.height, grid, sliderBack );

		scrollVoid = ( e : Event ) -> {
			scrollArea.scrollBy( 0, e.wheelDelta );
			slider.value = scrollArea.scrollY;
		};

		slider.onWheelEvent.add( scrollVoid );

		addOnSceneAddedCb( refreshEntries );
	}

	public function refreshEntries() {
		for ( e in entries ) e.destroy();
		entries = [];
		saveEntriesFlow.removeChildren();
		displaySaveEntries();
	}

	function displaySaveEntries() {
		for ( i in Settings.params.saveFiles ) {
			var e = new SaveEntry( i, mode, this, saveEntriesFlow );
			entries.push( e );
		}

		if ( mode == Save ) {
			var e = new SaveEntry( "New save...", mode, this, saveEntriesFlow );
			entries.push( e );
		}

		var scrollBounds = new Bounds();
		scrollBounds.addPoint( new Point( 0, M.fclamp( saveEntriesFlow.innerHeight, scrollArea.height, 1 / 0 ) ) );
		scrollBounds.addPoint( new Point( saveEntriesFlow.innerWidth, 0 ) );
		scrollArea.scrollBounds = scrollBounds;

		sliderBack.width = 10;
		sliderBack.height = scrollArea.height;

		backgroundScroll.width = scrollArea.width;
		backgroundScroll.height = hxd.Math.clamp( saveEntriesFlow.innerHeight, scrollArea.height, 1 / 0 );
		backgroundScroll.onWheelEvent.add( scrollVoid );
		// backgroundScroll.onClickEvent.add((e) -> {
		// 	remove();
		// });

		backgroundScroll.cursor = Default;

		grid.width = 10;
		grid.height = M.fclamp( ( 1 / ( saveEntriesFlow.innerHeight / scrollArea.height ) * scrollArea.height ), 15, scrollArea.height - 0.1 );
		slider.onChange = () -> scrollArea.scrollTo( 0, slider.value );
		slider.maxValue = scrollArea.height < saveEntriesFlow.innerHeight ? saveEntriesFlow.innerHeight - scrollArea.height : 0;

		areaBarFlow.maxWidth = areaBarFlow.outerWidth;
	}

	public function selectEntry( e : SaveEntry ) {
		for ( e in entries ) e.selected = false;
		e.selected = true;
	}

	public static function newSave( e : String, seed : String ) @:privateAccess {
		trace( "adding cb" );

		trace(Main.inst.cliCon.val == null);

		Main.inst.cliCon.onAppear(
			( cc ) -> {
				trace( "aksakmskdmaksmk" );
				cc.orderSaveSystem( CreateNewSave( e ),
					( result ) -> {
						cc.spawnPlayer( Settings.params.nickname );
					}
				);
			}
		);
		Main.inst.cliCon.val = null;
		

		Client.inst.repeatConnect( 0.1, 40 );
		Main.inst.startGame( true );

		// Client.inst.addOnConnectionCallback(() -> Client.inst.sendMessage( SaveSystemOrder( CreateNewSave( e ) ) ) );
	};

	public static function save( e : String ) {
		// Client.inst.addOnConnectionCallback(() -> Client.inst.sendMessage( SaveSystemOrder( CreateNewSave( e ) ) ) );
	};

	public static function load( e : String ) {
		// Client.inst.addOnConnectionCallback(() -> Client.inst.sendMessage( SaveSystemOrder( CreateNewSave( e ) ) ) );
	}

	public static function generalDelete( e : String ) {}

	override function onResize() {
		super.onResize();
		// sliderBack.height = scrollArea.height = Std.int( hScaled - h2dObject.y - 20 );
		// grid.height = M.fclamp( ( 1 / ( saveEntriesFlow.innerHeight / scrollArea.height ) * scrollArea.height ), 15, scrollArea.height - 0.1 );
	}

	override function onDispose() {
		super.onDispose();
		// for ( i in entries ) i.destroy();
		// if ( onLoad != null ) onLoad();
	}
}

class SaveEntry extends Process {

	var horflow : Flow;
	var utilityFlow : Flow;
	var dialog : Dialog;

	function set_dialog( v : Dialog ) {
		if ( dialog != null ) dialog.destroy();
		return v;
	}

	public var selected( default, set ) : Bool = false;

	var thisObject : Object;

	function set_selected( v : Bool ) {
		if ( v ) {
			horflow.backgroundTile = Tile.fromColor( 0x222222, 1, 1, .9 );
			utilityFlow.visible = true;
		} else {
			horflow.backgroundTile = null;
			utilityFlow.visible = false;
		}
		return selected = v;
	}

	public function new( name : String, mode : Mode, saveMan : SaveManager, ?parent : Object ) {
		super( Main.inst );
		thisObject = new Object( parent );

		var syncDialog = ( dialog : FocusMenu ) -> {
			Main.inst.root.add( dialog.h2dObject, Const.DP_UI + 2 );
			dialog.h2dObject.x = saveMan.h2dObject.x;
			dialog.h2dObject.y = thisObject.y - saveMan.scrollArea.scrollY + thisObject.getSize().height;
		}

		// save/load file
		// две маленькие кнопочки справа на записи сейва
		var activateEntry = null;
		activateEntry = ( e : Event ) -> {
			switch( mode ) {
				case Save:
					SaveManager.save( name );
				case Load:
					saveMan.destroy();
					if ( saveMan.onGameStart != null ) saveMan.onGameStart();
				// util.tools.Save.inst.loadGame( name );
				default:
			}
		};

		horflow = new Flow( thisObject );
		horflow.verticalAlign = Middle;
		horflow.fillWidth = true;
		horflow.paddingBottom = 2;

		var interactive = new EventInteractive( 0, 0 );
		horflow.addChildAt( interactive, 0 );
		interactive.cursor = Default;
		horflow.getProperties( interactive ).isAbsolute = true;

		interactive.cursor = Button;
		interactive.onWheelEvent.add( saveMan.scrollVoid );
		interactive.onClick = function ( e ) {
			saveMan.selectEntry( this );
			if ( selected )
				if ( cd.has( "doubleClick" ) ) {
					activateEntry( e );
				} else {
					cd.setMs( "doubleClick", 300 );
				}
		}

		var text = new ShadowedText( Assets.fontPixel, horflow );
		text.text = name;

		utilityFlow = new Flow( thisObject );
		utilityFlow.visible = false;
		utilityFlow.horizontalAlign = Right;
		utilityFlow.scale( .5 );
		utilityFlow.minWidth = Std.int( SaveManager.colWidth * Const.UI_SCALE );

		var edit0 = new HSprite( Assets.ui, "edit0" );
		var edit1 = new HSprite( Assets.ui, "edit1" );

		var delete0 = new HSprite( Assets.ui, "trash0" );
		var delete1 = new HSprite( Assets.ui, "trash1" );

		// var start0, start1, start2;
		// switch( mode ) {
		// 	case Save:
		// 		start0 = new HSprite( Assets.ui, "save0" );
		// 		start1 = new HSprite( Assets.ui, "save1" );
		// 		start2 = new HSprite( Assets.ui, "save2" );
		// 	case Load:
		// 		start0 = new HSprite( Assets.ui, "start0" );
		// 		start1 = new HSprite( Assets.ui, "start1" );
		// 		start2 = new HSprite( Assets.ui, "start2" );
		// 		// case New( name ):
		// 		// 	start0 = new HSprite( Assets.ui, "new0" );
		// 		// 	start1 = new HSprite( Assets.ui, "new1" );
		// 		// 	start2 = new HSprite( Assets.ui, "new2" );
		// 	default:
		// }
		// var startButton = new Button( [start0.tile, start1.tile, start2.tile], utilityFlow );
		// startButton.onClickEvent.add( activateEntry, 1 );

		switch mode {
			case Save | Load:
				/*
					var edit = new Button([edit0.tile, edit1.tile, edit0.tile], utilityFlow);
					edit.onClickEvent.add(( e ) -> {
						dialog = new RenameDialog(name, (e) -> {}, mode, Main.inst.root);
						syncDialog(dialog);
					});
				 */
				var delete = new Button( [delete0.tile, delete1.tile, delete0.tile], utilityFlow );
				delete.onClickEvent.add( ( e ) -> {
					// dialog = new DeleteDialog( name, mode, saveMan, Main.inst.root );
					// syncDialog( dialog );
				} );
			// case New( _ ):
			// 	startButton.onClickEvent.add( ( e ) -> {}, 0 );
			default:
		}

		try {
			interactive.width = horflow.outerWidth;
			interactive.height = horflow.outerHeight;
		} catch( e : Dynamic ) {
			trace( "some untrackable bug, probably not attached to s2d: " + e );
		}
	}

	override function onDispose() {
		super.onDispose();

		if ( dialog != null ) dialog.destroy();
		thisObject.remove();
	}
}
