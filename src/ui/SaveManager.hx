package ui;

import cherry.soup.EventSignal.EventSignal1;
import MainMenu.TextButton;
import dn.Process;
import h2d.Bitmap;
import h2d.Flow;
import h2d.Object;
import h2d.RenderContext;
import h2d.ScaleGrid;
import h2d.Text;
import h2d.Tile;
import h2d.col.Bounds;
import h2d.col.Point;
import hxd.Event;
import hxd.File;
import hxd.Key;
import ui.s2d.EventInteractive;

enum Mode {
	Save;
	Load;
	New(name : String);
}

class SaveManager extends SecondaryMenu {
	public static var inst : SaveManager;

	public static var scrollVoid : Event -> Void;

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
	var onLoad : () -> Void;

	public function new(mode : Mode, ?onLoad : () -> Void, ?parent : Object) {
		super(parent);
		this.mode = mode;
		if ( inst != null ) inst.remove();
		inst = this;
		this.onLoad = onLoad;

		refreshSaves();
		var generalFlow = new Flow(this);
		generalFlow.layout = Vertical;
		generalFlow.horizontalAlign = Middle;

		var signText = new Text(Assets.fontPixel, generalFlow);
		signText.text = switch mode {
			case Save: "Save file: ";
			case Load: "Load file: ";
			default: "";
		}

		areaBarFlow = new Flow(generalFlow);
		areaBarFlow.layout = Horizontal;
		areaBarFlow.verticalAlign = Top;
		areaBarFlow.padding = 5;
		areaBarFlow.enableInteractive = true;
		areaBarFlow.overflow = Limit;

		scrollArea = new FixedScrollArea(colWidth, 0, 16, areaBarFlow);
		scrollArea.height = Std.int(hScaled - y - 20);
		backgroundScroll = new EventInteractive(0, 0, scrollArea);

		saveEntriesFlow = new Flow(scrollArea);
		saveEntriesFlow.layout = Vertical;

		areaBarFlow.addSpacing(10);
		areaBarFlow.backgroundTile = Tile.fromColor(0x000000, 1, 1, 0.6);

		sliderBack = new Bitmap(Tile.fromColor(0x222222, 10, 10, 1), areaBarFlow);

		grid = new ScaleGrid(Tile.fromColor(0x8f8f8f, 1, 1, 1), 1, 1, 1, 1, this);
		slider = new VerticalSlider(10, scrollArea.height, grid, sliderBack);
		scrollVoid = (e : Event) -> {
			scrollArea.scrollBy(0, e.wheelDelta);
			slider.value = scrollArea.scrollY;
		};

		slider.onWheelEvent.add(scrollVoid);

		displaySaveEntries();
	}

	public function refreshEntries() {
		for (e in entries) e.destroy();
		entries = [];
		saveEntriesFlow.removeChildren();
		displaySaveEntries();
	}

	function displaySaveEntries() {
		for (i in params.saveFiles) {
			var e = new SaveEntry(i, mode, saveEntriesFlow);
			entries.push(e);
		}
		if ( mode == Save ) {
			var e = new SaveEntry("New save...", New("null"), saveEntriesFlow);
			entries.push(e);
		}

		var scrollBounds = new Bounds();
		scrollBounds.addPoint(new Point(0, M.fclamp(saveEntriesFlow.innerHeight, scrollArea.height, 1 / 0)));
		scrollBounds.addPoint(new Point(saveEntriesFlow.innerWidth, 0));
		scrollArea.scrollBounds = scrollBounds;

		sliderBack.width = 10;
		sliderBack.height = scrollArea.height;

		backgroundScroll.width = scrollArea.width;
		backgroundScroll.height = hxd.Math.clamp(saveEntriesFlow.innerHeight, scrollArea.height, 1 / 0);
		backgroundScroll.onWheelEvent.add(scrollVoid);
		// backgroundScroll.onClickEvent.add((e) -> {
		// 	remove();
		// });

		backgroundScroll.cursor = Default;

		grid.width = 10;
		grid.height = M.fclamp((1 / (saveEntriesFlow.innerHeight / scrollArea.height) * scrollArea.height), 15, scrollArea.height - 0.1);
		slider.onChange = () -> scrollArea.scrollTo(0, slider.value);
		slider.maxValue = scrollArea.height < saveEntriesFlow.innerHeight ? saveEntriesFlow.innerHeight - scrollArea.height : 0;

		areaBarFlow.maxWidth = areaBarFlow.outerWidth;
	}

	public function selectEntry(e : SaveEntry) {
		for (e in entries) e.selected = false;
		e.selected = true;
	}

	override function onRemove() {
		super.onRemove();
		for (i in entries) i.destroy();
		if ( onLoad != null ) onLoad();
	}
}

class SaveEntry extends Process {
	var horflow : Flow;
	var utilityFlow : Flow;
	var dialog : Dialog;

	function set_dialog(v : Dialog) {
		if ( dialog != null ) dialog.remove();
		return v;
	}

	public var selected(default, set) : Bool = false;

	var thisObject : Object;

	function set_selected(v : Bool) {
		if ( v ) {
			horflow.backgroundTile = Tile.fromColor(0x454545, 1, 1, .9);
			utilityFlow.visible = true;
		} else {
			horflow.backgroundTile = null;
			utilityFlow.visible = false;
		}
		return selected = v;
	}

	public function new(name : String, mode : Mode, ?parent : Object) {
		super(Main.inst);
		thisObject = new Object(parent);

		var syncDialog = (dialog : SecondaryMenu) -> {
			Main.inst.root.add(dialog, Const.DP_UI + 2);
			dialog.x = SaveManager.inst.x;
			dialog.y = thisObject.y - SaveManager.inst.scrollArea.scrollY + thisObject.getSize().height;
		}
		// save/load file
		var activateEntry = null;
		activateEntry = (e : Event) -> {
			switch( mode ) {
				case Save:
					tools.Save.inst.saveGame(name);
				case Load:
					SaveManager.inst.remove();
					tools.Save.inst.loadGame(name);
				case New(name):
					dialog = new NewSaveDialog((e) -> {}, mode, Main.inst.root);
					syncDialog(dialog);
			}
		};

		horflow = new Flow(thisObject);
		horflow.verticalAlign = Middle;
		horflow.fillWidth = true;
		horflow.paddingBottom = 2;

		var interactive = new EventInteractive(0, 0);
		horflow.addChildAt(interactive, 0);
		interactive.cursor = Default;
		horflow.getProperties(interactive).isAbsolute = true;

		interactive.cursor = Button;
		interactive.onWheel = SaveManager.scrollVoid;
		interactive.onClick = function(e) {
			SaveManager.inst.selectEntry(this);
			if ( selected ) if ( cd.has("doubleClick") ) {
				activateEntry(e);
			} else {
				cd.setMs("doubleClick", 300);
			}
		}

		var text = new Text(Assets.fontPixel, horflow);
		text.text = name;

		utilityFlow = new Flow(thisObject);
		utilityFlow.visible = false;
		utilityFlow.horizontalAlign = Right;
		utilityFlow.scale(.5);
		utilityFlow.minWidth = Std.int(SaveManager.colWidth * Const.UI_SCALE);

		var edit0 = new HSprite(Assets.ui, "edit0");
		var edit1 = new HSprite(Assets.ui, "edit1");

		var delete0 = new HSprite(Assets.ui, "trash0");
		var delete1 = new HSprite(Assets.ui, "trash1");

		var start0, start1, start2;
		switch( mode ) {
			case Save:
				start0 = new HSprite(Assets.ui, "save0");
				start1 = new HSprite(Assets.ui, "save1");
				start2 = new HSprite(Assets.ui, "save2");
			case Load:
				start0 = new HSprite(Assets.ui, "start0");
				start1 = new HSprite(Assets.ui, "start1");
				start2 = new HSprite(Assets.ui, "start2");
			case New(name):
				start0 = new HSprite(Assets.ui, "new0");
				start1 = new HSprite(Assets.ui, "new1");
				start2 = new HSprite(Assets.ui, "new2");
		}
		var start = new Button([start0.tile, start1.tile, start2.tile], utilityFlow);
		start.onClickEvent.add(activateEntry, 1);

		switch mode {
			case Save | Load:
				var edit = new Button([edit0.tile, edit1.tile, edit0.tile], utilityFlow);
				edit.onClickEvent.add((e) -> {
					dialog = new RenameDialog(name, activateEntry, mode, Main.inst.root);
					syncDialog(dialog);
				});

				var delete = new Button([delete0.tile, delete1.tile, delete0.tile], utilityFlow);
				delete.onClickEvent.add((e) -> {
					dialog = new DeleteDialog(name, activateEntry, mode, Main.inst.root);
					syncDialog(dialog);
				});
			case New(_):
				start.onClickEvent.add((e) -> {}, 0);
		}

		interactive.width = horflow.innerWidth;
		interactive.height = horflow.innerHeight;
	}

	override function onDispose() {
		super.onDispose();

		if ( dialog != null ) dialog.remove();
		thisObject.remove();
	}
}

class Dialog extends SecondaryMenu {
	var activateEvent : EventSignal1<Event>;

	public function new(activateEvent : Event -> Void, mode : Mode, ?parent : Object) {
		super(parent);
		this.activateEvent = new EventSignal1<Event>();

		this.activateEvent.add((e) -> {
			activateEvent(e);
			refreshSaves();
			if ( SaveManager.inst != null ) SaveManager.inst.refreshEntries();
			remove();
		});
	}

	override function sync(ctx : RenderContext) {
		super.sync(ctx);
		x = hxd.Math.clamp(x, 0, wScaled - getSize().width - 1);
		y = hxd.Math.clamp(y, 0, hScaled - getSize().height - 1);
	}
}

class NewSaveDialog extends Dialog {
	var buttonsFlow : Flow;
	var generalFlow : Flow;

	public var textInput : TextInput;

	public function new(activateEvent : Event -> Void, mode : Mode, ?parent : Object) {
		super(activateEvent, mode, parent);
		generalFlow = new Flow(this);
		generalFlow.layout = Vertical;

		var dialogFlow = new Flow(generalFlow);
		dialogFlow.verticalAlign = Middle;
		dialogFlow.padding = 2;

		var dialogText = new Text(Assets.fontPixel, dialogFlow);
		dialogText.text = 'Enter new save name: ';

		 textInput = new TextInput(Assets.fontPixel, dialogFlow);

		textInput.onKeyDown = function(e) {
			if ( e.keyCode == Key.ENTER ) this.activateEvent.dispatch(e);
		}

		buttonsFlow = new Flow(generalFlow);
		buttonsFlow.horizontalAlign = Right;
		buttonsFlow.verticalAlign = Middle;
		buttonsFlow.horizontalSpacing = 5;
		buttonsFlow.minWidth = generalFlow.outerWidth;

		var newSaveCount = 0;
		for (i in params.saveFiles) {
			if ( StringTools.startsWith(i, "new_save") ) newSaveCount++;
		}
		textInput.text = "new_save" + newSaveCount;

		this.activateEvent.add((e) -> {
			mode = New(textInput.text);
			try {
				tools.Save.inst.makeFreshSave(textInput.text);
				// tools.Save.inst.saveGame(textInput.text);
			}
			catch( e:Dynamic ) {
				var errorText = new Text(Assets.fontPixel, generalFlow);
				errorText.text = '$e'.split(":")[1];
			}
			refreshSaves();
			if ( SaveManager.inst != null ) SaveManager.inst.refreshEntries();

			remove();
		});

		var yesBut = new TextButton("ok", (e) -> {
			this.activateEvent.dispatch(e);
		}, buttonsFlow);
		var noBut = new TextButton("cancel", (e) -> {
			remove();
		}, buttonsFlow);

		generalFlow.minWidth = generalFlow.innerWidth;
		generalFlow.minHeight = generalFlow.innerHeight;
	}

	override function sync(ctx : RenderContext) {
		super.sync(ctx);
	}
}

class RenameDialog extends Dialog {
	public function new(name : String, activateEvent : Event -> Void, mode : Mode, ?parent : Object) {
		super(activateEvent, mode, parent);

		var generalFlow = new Flow(this);
		generalFlow.layout = Vertical;

		var dialogFlow = new Flow(generalFlow);
		dialogFlow.verticalAlign = Middle;
		dialogFlow.padding = 2;

		var dialogText = new Text(Assets.fontPixel, dialogFlow);
		dialogText.text = 'Enter new save name: ';

		var textInput = new TextInput(Assets.fontPixel, dialogFlow);

		var buttonsFlow = new Flow(generalFlow);
		buttonsFlow.horizontalAlign = Middle;
		buttonsFlow.verticalAlign = Middle;
		buttonsFlow.horizontalSpacing = 2;
		buttonsFlow.minWidth = generalFlow.outerWidth;

		textInput.text = name;
		textInput.onKeyDown = function(e) if ( e.keyCode == Key.ENTER ) this.activateEvent.dispatch(e);

		var yesBut = new TextButton("ok", (e) -> {
			this.activateEvent.dispatch(e);
		}, buttonsFlow);
		var noBut = new TextButton("cancel", (e) -> {
			remove();
		}, buttonsFlow);
	}
}

class DeleteDialog extends Dialog {
	public function new(name : String, activateEvent : Event -> Void, mode : Mode, ?parent : Object) {
		super(activateEvent, mode, parent);

		var dialogFlow = new Flow(this);
		dialogFlow.verticalAlign = Middle;
		dialogFlow.horizontalSpacing = 6;

		var deleteText = new TextLabel('Are you sure?', Assets.fontPixel, dialogFlow);

		var yesBut = new TextButton("yes", (e) -> {
			remove();
			File.delete(Settings.SAVEPATH + name + Const.SAVEFILE_EXT);
			refreshSaves();
			SaveManager.inst.refreshEntries();
		}, 0xbe3434, 0x6d2a45, dialogFlow);
		var noBut = new TextButton("no", (e) -> {
			remove();
		}, dialogFlow);
	}
}
