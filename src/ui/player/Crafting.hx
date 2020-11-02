package ui.player;

import ui.InventoryGrid.InventoryCell;
import en.player.Player;
import ui.s2d.EventInteractive;
import hxd.Event;
import hxPixels.Pixels.TargetType;
import h3d.mat.Texture;
import h2d.ScaleGrid;
import h2d.Tile;
import h2d.Mask;
import h2d.RenderContext;
import h2d.Slider;
import ch2.ui.CustomButton;
import ch2.ui.Button;
import h2d.Flow;
import h2d.col.Point;
import h2d.col.Bounds;
import ch2.ui.ScrollArea;
import format.tmx.Data.TmxLayer;
import h2d.Object;

class Crafting extends Object {
	var configMap: Map<String, TmxLayer>;
	var sprCraft: HSprite;
	var scrollable: ScrollArea;

	public function new(configMap: Map<String, TmxLayer>, ?parent: Object) {
		super(parent);
		this.configMap = configMap;
		toggleVisible();
		sprCraft = new HSprite(Assets.ui, this);
		sprCraft.set("crafting");

		var textLabel = new ui.TextLabel("Crafting", Assets.fontPixel, sprCraft);
		// textLabel.minWidth = Std.int(sprCraft.tile.width * Const.SCALE);
		textLabel.scale(.5);
		// textLabel.paddingTop = 4 + textLabel.outerHeight >> 1 ;
		textLabel.x = configMap.get("craft").getObjectByName("sign").x;
		textLabel.y = configMap.get("craft").getObjectByName("sign").y;
		textLabel.paddingLeft = -textLabel.innerWidth >> 1;
		textLabel.paddingTop = -textLabel.innerHeight >> 1;

		var recipeConf = configMap.get("craft").getObjectByName("recipes");

		// Scrollable shit for recipesa
		var caretUp = new HSprite(Assets.ui, "caret0").tile;
		var caretDown = new HSprite(Assets.ui, "caret1").tile;

		var grid = new ScaleGrid(caretUp, 3, 3, this);

		var sliderConf = configMap.get("craft").getObjectByName("slider");
		var slider = new VerticalSlider(Std.int(sliderConf.width), Std.int(sliderConf.height), grid, this);
		slider.x = sliderConf.x;
		slider.y = sliderConf.y;

		var scrollVoid = (e: Event) -> {
			scrollable.scrollBy(0, e.wheelDelta);
			slider.value = scrollable.scrollY;
		};
		slider.onWheelEvent.add(scrollVoid);

		scrollable = new FixedScrollArea(Std.int(recipeConf.width), Std.int(recipeConf.height), sprCraft);
		scrollable.x = recipeConf.x;
		scrollable.y = recipeConf.y;

		var temp = new EventInteractive(0, 0, scrollable);
		temp.onWheelEvent.add(scrollVoid);

		var flowCont = new Flow(scrollable);
		flowCont.layout = Vertical;
		flowCont.verticalSpacing = 1;

		for (recipe in Data.recipes.all) {
			var rec = new Recipe(configMap, recipe, flowCont);
			rec.inter.onWheelEvent.add(scrollVoid);
		}

		temp.width = flowCont.innerWidth;
		temp.height = flowCont.innerHeight;
		temp.cursor = Default;

		var scrollBounds = new Bounds();
		scrollBounds.addPoint(new Point(0, M.fclamp(flowCont.innerHeight, recipeConf.height, 1 / 0)));
		scrollBounds.addPoint(new Point(flowCont.innerWidth, 0));
		scrollable.scrollBounds = scrollBounds;

		grid.height = M.fclamp((1 / (flowCont.innerHeight / recipeConf.height) * recipeConf.height), caretUp.height, sliderConf.height - 0.1);

		slider.maxValue = flowCont.innerHeight > sliderConf.height ? flowCont.innerHeight - recipeConf.height : 0.1;

		slider.onPushEvent.add((_) -> slider.cursorObj.tile = caretDown);
		slider.onReleaseEvent.add((_) -> slider.cursorObj.tile = caretUp);

		slider.onChange = () -> scrollable.scrollTo(0, slider.value);
	}

	public function toggleVisible() {
		visible = !visible;
		// recenter();
	}
}

class Recipe extends Object {
	public var inter: EventInteractive;

	var hint: IngredsHint;

	public function new(configMap: Map<String, TmxLayer>, recipe: Data.Recipes, ?parent: Object) {
		super(parent);
		var recSpr = new HSprite(Assets.ui, "recipe", this);
		var recipeConf = configMap.get("craft_recipe");
		inter = new EventInteractive(recSpr.tile.width, recSpr.tile.height, recSpr);
		var iconSpr = new HSprite(Assets.items, recipe.item_icon.atlas_name, this);
		iconSpr.x = recipeConf.getObjectByName("icon").x;
		iconSpr.y = recipeConf.getObjectByName("icon").y;

		var sign = new TextLabel(recipe.name, Assets.fontPixel, this);
		sign.scale(.5);
		sign.x = recipeConf.getObjectByName("name").x;
		sign.y = recipeConf.getObjectByName("name").y;

		var craft_but0 = new HSprite(Assets.ui, "craft_but0");
		var craft_but1 = new HSprite(Assets.ui, "craft_but1");
		var craft_but2 = new HSprite(Assets.ui, "craft_but2");

		var craftButton = new ui.Button([craft_but0.tile, craft_but1.tile, craft_but2.tile], this);
		craftButton.x = recipeConf.getObjectByName("craft_but").x;
		craftButton.y = recipeConf.getObjectByName("craft_but").y;

		craft_but0.remove();
		craft_but1.remove();
		craft_but2.remove();

		craftButton.onClickEvent.add((_) -> {
			craft(recipe);
		});

		inter.onOverEvent.add((_) -> hint = new IngredsHint(configMap, recipe, Boot.inst.s2d));
		inter.onOutEvent.add((_) -> if (hint != null) hint.remove());
	}

	public function craft(recipe: Data.Recipes) {
		// checking if player has required items
		for (i in recipe.ingreds) {
			var checkedCells: Array<InventoryCell> = [];

			var amountPitch = i.amount;
			while (amountPitch > 0) {
				var targetItemSlot = Player.inst.ui.inventory.invGrid.findItemKind(i.item, 1, checkedCells);
				if (targetItemSlot == null) {
					return null;
				} else if (targetItemSlot.item.amount >= i.amount) {
					amountPitch = 0;
				} else {
					amountPitch -= targetItemSlot.item.amount;
					checkedCells.push(targetItemSlot);
				}
			}
		}
		for (i in recipe.ingreds) {
			var amountPitch = i.amount;
			while (amountPitch > 0) {
				var targetItemSlot = Player.inst.ui.inventory.invGrid.findItemKind(i.item, 1, []);
				if (targetItemSlot == null) {
					return null;
				} else if (targetItemSlot.item.amount >= i.amount) {
					targetItemSlot.item.amount -= amountPitch;
					amountPitch = 0;
				} else {
					amountPitch -= targetItemSlot.item.amount;
					targetItemSlot.item.remove();
					targetItemSlot.item = null;
				}
			}
		}
		for (i in recipe.result) {
			var newItem = new Item(i.itemId);
			newItem.amount = i.amount;
			Player.inst.ui.inventory.invGrid.giveItem(newItem);
		}
		return null;
	}

	override function onRemove() {
		super.onRemove();
		hint.remove();
	}
}
/** Показывает ингредиенты **/
class IngredsHint extends Object {
	var baseGrid: ScaleGrid;

	public function new(configMap: Map<String, TmxLayer>, recipe: Data.Recipes, ?parent: Object) {
		super(parent);
		scale(2);
		var confLayer = configMap.get("ingreds_hint");

		var baseSpr = new HSprite(Assets.ui, "recipe_hint");
		baseGrid = new ScaleGrid(baseSpr.tile, 0, 11, this);
		baseSpr.remove();

		var textLabel = new TextLabel("Ingredients", Assets.fontPixel, this);
		textLabel.x = confLayer.getObjectByName("sign").x;
		textLabel.y = confLayer.getObjectByName("sign").y;
		textLabel.scale(.5);
		textLabel.center();

		var flowCont = new Flow(this);
		flowCont.x = confLayer.getObjectByName("flow").x;
		flowCont.y = confLayer.getObjectByName("flow").y;
		flowCont.addSpacing(1);
		flowCont.verticalSpacing = 1;
		flowCont.layout = Vertical;

		for (i in recipe.ingreds) {
			new IngredComp(configMap, i, flowCont);
		}

		baseGrid.height = flowCont.outerHeight + 20;
	}

	override function sync(ctx: RenderContext) {
		x = Boot.inst.s2d.mouseX + 20;
		y = Boot.inst.s2d.mouseY + 20;
		super.sync(ctx);
	}
}

class IngredComp extends Object {
	public function new(configMap: Map<String, TmxLayer>, ingred: Data.Recipes_ingreds, ?parent: Object) {
		super(parent);

		var conf = configMap.get("ingreds_comp");
		var baseSpr = new HSprite(Assets.ui, "recipe_comp", this);
		var iconSpr = new HSprite(Assets.items, ingred.item.atlas_name, this);
		iconSpr.x = conf.getObjectByName("icon").x;
		iconSpr.y = conf.getObjectByName("icon").y;

		var nameLabel = new TextLabel(ingred.item.display_name, Assets.fontPixel, this);
		nameLabel.x = conf.getObjectByName("name").x;
		nameLabel.y = conf.getObjectByName("name").y;
		nameLabel.scale(.5);

		var amountLabel = new TextLabel('${ingred.amount}', Assets.fontPixel, this);
		amountLabel.x = conf.getObjectByName("counter").x;
		amountLabel.y = conf.getObjectByName("counter").y;
		amountLabel.scale(.5);
		amountLabel.center();
	}
}

class VerticalSlider extends EventInteractive {
	public var tile: h2d.Tile;
	public var cursorObj: ScaleGrid;
	public var minValue(default, set): Float = 0;
	public var maxValue(default, set): Float = 1;
	public var value(default, set): Float = 0;

	public function new(?width: Int = 50, ?height: Int = 10, cursorObj: ScaleGrid, ?parent) {
		super(width, height, parent);

		tile = h2d.Tile.fromColor(Color.addAlphaI(0x00000000), width, height, 0);
		// tile.dy = (width - 4) >> 1;
		this.cursorObj = cursorObj;
		addChild(this.cursorObj);
	}

	function set_minValue(v) {
		if (value < v) value = v;
		return minValue = v;
	}

	function set_maxValue(v) {
		if (value > v) value = v;
		return maxValue = v;
	}

	function set_value(v) {
		if (v < minValue) v = minValue;
		if (v > maxValue) v = maxValue;
		return value = v;
	}

	override function getBoundsRec(relativeTo, out, forSize) {
		super.getBoundsRec(relativeTo, out, forSize);
		if (forSize) addBounds(relativeTo, out, 0, 0, width, height);
		if (tile != null) addBounds(relativeTo, out, tile.dx, tile.dy, tile.width, tile.height);
		if (cursorObj != null) addBounds(relativeTo, out, cursorObj.y + getDy(), cursorObj.y, cursorObj.width, cursorObj.height);
	}

	override function draw(ctx: RenderContext) {
		super.draw(ctx);
		if (tile.height != Std.int(height)) tile.setSize(Std.int(width), tile.height);
		emitTile(ctx, tile);
		var px = getDy();
		cursorObj.y = px;
	}

	var handleDX = 0.0;

	inline function getDy() {
		return Math.round((value - minValue) * (height - cursorObj.height) / (maxValue - minValue));
	}

	inline function getValue(cursorX: Float): Float {
		return ((cursorX - handleDX) / (height - cursorObj.height)) * (maxValue - minValue) + minValue;
	}

	override function handleEvent(e: hxd.Event) {
		super.handleEvent(e);
		if (e.cancel) return;
		switch (e.kind) {
			case EPush:
				var dx = getDy();
				handleDX = e.relY - dx;

				// If clicking the slider outside the handle, drag the handle
				// by the center of it.
				if (handleDX - cursorObj.tile.dy < 0 || handleDX - cursorObj.tile.dy > cursorObj.height) {
					handleDX = cursorObj.height * 0.5;
				}

				value = getValue(e.relY);
				onChange();
				var scene = scene;
				startDrag(function(e) {
					if (this.scene != scene || e.kind == ERelease) {
						scene.stopDrag();
						return;
					}
					value = getValue(e.relY);
					onChange();
				});
			default:
		}
	}

	public dynamic function onChange() {}
}

class FixedScrollArea extends ScrollArea {
	override function drawRec(ctx: h2d.RenderContext) @:privateAccess {
		if (!visible) return;
		// fallback in case the object was added during a sync() event and we somehow didn't update it
		if (posChanged) {
			// only sync anim, don't update() (prevent any event from occuring during draw())
			// if( currentAnimation != null ) currentAnimation.sync();
			calcAbsPos();
			for (c in children) c.posChanged = true;
			posChanged = false;
		}

		var x1 = absX + scrollX * 2;
		var y1 = absY + scrollY * 2;

		var x2 = width * matA + height * matC + x1;
		var y2 = width * matB + height * matD + y1;

		var tmp;
		if (x1 > x2) {
			tmp = x1;
			x1 = x2;
			x2 = tmp;
		}

		if (y1 > y2) {
			tmp = y1;
			y1 = y2;
			y2 = tmp;
		}

		ctx.flush();
		ctx.pushRenderZone(x1, y1, x2 - x1, y2 - y1);
		objDrawRec(ctx);
		ctx.flush();
		ctx.popRenderZone();
	}
}
