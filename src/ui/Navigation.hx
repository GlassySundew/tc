package ui;

import ui.s2d.EventInteractive;
import hxd.Res;
import h2d.Object;

class Navigation extends Window {
	var ca : dn.heaps.Controller.ControllerAccess;
	var navArea : FixedScrollArea;

	public function new(?parent : Object) {
		spr = new HSprite(Assets.ui);
		spr.set("navigation");
		super(parent);

		var textLabel = new ui.TextLabel("Navigation console", Assets.fontPixel, win);
		textLabel.scale(.5);
		textLabel.x = spr.tile.width / 2;

		textLabel.center();
		textLabel.paddingTop += Std.int(textLabel.labelTxt.textHeight) + 3;

		var navConf = uiConf.get("navigation").getObjectByName("navigation");
		navArea = new FixedScrollArea(Std.int(navConf.width), Std.int(navConf.height), win);
		navArea.x = navConf.x;
		navArea.y = navConf.y;

		var scroller = new EventInteractive(1000, 1000, navArea);
		// scroller.

		createDragable("navigation");
		createCloseBut("navigation");

		recenter();
		toggleVisible();
	}
}

class NavigationTarget extends Object {
	var celestialObject : Button;

	public function new(cdbEntry : Navigation_targetsKind, ?parent : Object) {
		super(parent);

		var tileData = Data.navigation_targets.get(cdbEntry).img;
		var file = Res.load(tileData.file);
		
		// celestialObject = new Button(this);
	}
}
