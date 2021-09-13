package ui;

// import tools.Save;
import UniformPoissonDisc.UniformPoissonDisk;
import h2d.Bitmap;
import h2d.Object;
import h2d.Tile;
import h2d.col.Point;
import h3d.mat.Texture;
import ui.Dragable;

class Navigation extends Window {
	var ca : dn.heaps.Controller.ControllerAccess;
	var navArea : FixedScrollArea;

	public function new( ?parent : Object ) {
		super(parent);

		var textLabel = new ui.TextLabelComp("Navigation console", Assets.fontPixel, win);
		textLabel.scale(.5);
		textLabel.x = win.getSize().width / 2;

		textLabel.center();
		textLabel.paddingTop += Std.int(textLabel.labelTxt.textHeight) + 3;

		var navConf = uiConf.get("navigation").getObjectByName("navigation");
		navArea = new FixedScrollArea(Std.int(navConf.width), Std.int(navConf.height), win);
		navArea.x = navConf.x;
		navArea.y = navConf.y;

		var scroller = new Dragable(1000, 1000, navArea);
		scroller.cursor = Default;
		// scroller.onDrag.add((x, y) -> {
		// 	scroller.x += x;
		// 	scroller.y += y;
		// });

		// scroller.scale(.5);

		var asteroidField = new NavigationTargetsGen(scroller);
		asteroidField.x = scroller.width / 2;
		asteroidField.y = scroller.height / 2;
		asteroidField.scale(.5);

		asteroidField.initAsteroidField();

		navArea.scrollTo(asteroidField.x - navArea.width / 2, asteroidField.y - navArea.height / 2);

		recenter();
		toggleVisible();
	}
}

class NavigationTargetsGen extends Object {
	public var targets : Array<NavigationTarget> = [];

	public function new( ?parent : Object ) {
		super(parent);
	}

	var jumpReach = 65;

	public function initAsteroidField() {
		var poissonMap = new UniformPoissonDisk(new Point(0, 0));
		var sampledPoints = poissonMap.sample(new Point(-100, -100), new Point(100, 100), ( p : Point ) -> {
			var dist = jumpReach * Math.random();
			return M.fclamp(dist, jumpReach * 0.75, jumpReach);
		}, jumpReach * 1.25);

		for ( i in sampledPoints ) {
			var target = new NavigationTarget(Random.fromArray([asteroid0, asteroid1, asteroid2, asteroid3]), this);
			target.setPosition(i.x, i.y);
			targets.push(target);
		}
	}
}

class NavigationTarget extends Object {
	var celestialObject : Button;
	var cdbEntry : Navigation_targetsKind;

	var tile(get, null) : Tile;

	function get_tile() return loadTileFromCdb(Data.navigation_targets.get(cdbEntry).img);

	public function new( cdbEntry : Navigation_targetsKind, ?parent : Object ) {
		super(parent);
		this.cdbEntry = cdbEntry;

		var tex = new Texture(Data.navigation_targets.get(cdbEntry).img.size, Data.navigation_targets.get(cdbEntry).img.size, [Target]);

		new Bitmap(tile).drawTo(tex);
		new HSprite(Assets.ui, "body_selected").drawTo(tex);

		celestialObject = new Button([tile, Tile.fromTexture(tex)], this);
		celestialObject.x -= celestialObject.width / 2;
		celestialObject.y -= celestialObject.height / 2;
	}
}
