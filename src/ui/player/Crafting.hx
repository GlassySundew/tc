package ui.player;

import ch2.ui.ScrollArea;
import en.player.Player;
import format.tmx.Data.TmxLayer;
import h2d.Flow;
import h2d.Object;
import h2d.RenderContext;
import h2d.ScaleGrid;
import h2d.Tile;
import h2d.col.Bounds;
import h2d.col.Point;
import hxd.Event;
import ui.InventoryGrid.InventoryCell;
import ch2.ui.EventInteractive;

class Crafting extends NinesliceWindow {
	var scrollable : ScrollArea;

	public function new( ?parent : Object ) {
		super(( tile, bl, bt, br, bb, parent ) -> {
			new CraftingComp(tile, bl, bt, br, bb, parent);
		}, parent);

		windowComp.window.windowLabel.labelTxt.text = "Crafting";

		// var recipeConf = uiConf.get("craft").getObjectByName("recipes");

		// Scrollable shit for recipes
		// var caretUp = new HSprite(Assets.ui, "caret0").tile;
		// var caretDown = new HSprite(Assets.ui, "caret1").tile;

		// var grid = new ScaleGrid(caretUp, 3, 3, win);

		// var sliderConf = uiConf.get("craft").getObjectByName("slider");
		// var slider = new VerticalSlider(Std.int(sliderConf.width), Std.int(sliderConf.height), grid, win);
		// slider.x = sliderConf.x;
		// slider.y = sliderConf.y;

		var scroll = ( e : Event ) -> {
			if ( e.kind == EWheel ) {
				scrollable.scrollBy(0, e.wheelDelta);
				// slider.value = scrollable.scrollY;
			}
		};

		// slider.onWheelEvent.add(scroll);

		scrollable = new FixedScrollArea(0, 0, true, true, Std.downcast(windowComp, CraftingComp).scrollable);
		@:privateAccess scrollable.sync(Boot.inst.s2d.ctx);

		// var temp = new EventInteractive(0, 0, scrollable);
		// temp.onWheelEvent.add(scroll);

		var recipeEntriesFlow = new Flow(scrollable);
		recipeEntriesFlow.layout = Vertical;
		recipeEntriesFlow.verticalSpacing = 1;
		recipeEntriesFlow.fillWidth = true;

		for ( recipe in Data.recipes.all ) {
			var rec = new Recipe(uiConf, recipe, recipeEntriesFlow);
			rec.windowComp.window.minWidth = scrollable.width;
			cast(rec.windowComp, RecipeComp).onWheel.add(scroll);
		}

		// temp.width = recipeEntriesFlow.innerWidth;
		// temp.height = recipeEntriesFlow.innerHeight;
		// temp.cursor = Default;

		var scrollBounds = new Bounds();
		scrollBounds.addPoint(new Point(0, M.fclamp(recipeEntriesFlow.innerHeight, scrollable.height, 1 / 0)));
		scrollBounds.addPoint(new Point(recipeEntriesFlow.innerWidth, 0));
		scrollable.scrollBounds = scrollBounds;

		// grid.height = M.fclamp((1 / (recipeEntriesFlow.innerHeight / recipeConf.height) * recipeConf.height), caretUp.height, sliderConf.height - 0.1);

		// slider.maxValue = recipeEntriesFlow.innerHeight > sliderConf.height ? recipeEntriesFlow.innerHeight - recipeConf.height : 0.1;

		// slider.onPushEvent.add(( _ ) -> slider.cursorObj.tile = caretDown);
		// slider.onReleaseEvent.add(( _ ) -> slider.cursorObj.tile = caretUp);

		// slider.onChange = () -> scrollable.scrollTo(0, slider.value);

		toggleVisible();
	}
}

class Recipe extends NinesliceWindow {
	public var inter : EventInteractive;

	var hint : IngredsHint;

	public function new( configMap : Map<String, TmxLayer>, recipe : Data.Recipes, ?parent : Object ) {
		super("craft_recipe", ( tile, bl, bt, br, bb, parent ) -> {
			new RecipeComp(recipe, tile, bl, bt, br, bb, parent);
		}, parent);

		// inter = new EventInteractive(recSpr.tile.width, recSpr.tile.height, recSpr);
		windowComp.window.windowLabel.labelTxt.text = recipe.name;

		windowComp.window.enableInteractive = true;
		windowComp.window.interactive.cursor = Button;

		// craftButton.x = recipeConf.getObjectByName("craft_but").x;
		// craftButton.y = recipeConf.getObjectByName("craft_but").y;

		// craft_but0.remove();
		// craft_but1.remove();
		// craft_but2.remove();

		// craftButton.onClickEvent.add(( _ ) -> {
		// 	craft(recipe);
		// });

		// inter.onOverEvent.add(( _ ) -> hint = new IngredsHint(configMap, recipe, Boot.inst.s2d));
		// inter.onOutEvent.add(( _ ) -> if ( hint != null ) hint.remove());
	}

	public function craft( recipe : Data.Recipes ) {
		// checking if player has required items
		for ( i in recipe.ingreds ) {
			var checkedCells : Array<InventoryCell> = [];

			var amountPitch = i.amount;
			while( amountPitch > 0 ) {
				var targetItemSlot = Player.inst.ui.inventory.invGrid.findItemKind(i.item, 1, checkedCells);
				if ( targetItemSlot == null ) {
					return null;
				} else if ( targetItemSlot.item.amount >= i.amount ) {
					amountPitch = 0;
				} else {
					amountPitch -= targetItemSlot.item.amount;
					checkedCells.push(targetItemSlot);
				}
			}
		}
		// removing itemns from player inventory
		for ( i in recipe.ingreds ) {
			var amountPitch = i.amount;
			while( amountPitch > 0 ) {
				var targetItemSlot = Player.inst.ui.inventory.invGrid.findItemKind(i.item, 1, []);
				if ( targetItemSlot == null ) {
					return null;
				} else if ( targetItemSlot.item.amount >= i.amount ) {
					targetItemSlot.item.amount -= amountPitch;
					amountPitch = 0;
				} else {
					amountPitch -= targetItemSlot.item.amount;
					targetItemSlot.item.remove();
					targetItemSlot.item = null;
				}
			}
		}
		for ( i in recipe.result ) {
			var newItem = Item.fromCdbEntry(i.itemId, i.amount);

			Player.inst.ui.inventory.invGrid.giveItem(newItem, Player.inst);
		}
		return null;
	}

	override function onDispose() {
		super.onDispose();
		hint.remove();
	}
}
/** Показывает ингредиенты **/
class IngredsHint extends Object {
	var baseGrid : ScaleGrid;

	public function new( configMap : Map<String, TmxLayer>, recipe : Data.Recipes, ?parent : Object ) {
		super(parent);
		scale(2);
		var confLayer = configMap.get("ingreds_hint");

		var baseSpr = new HSprite(Assets.ui, "recipe_hint");
		baseGrid = new ScaleGrid(baseSpr.tile, 0, 11, this);
		baseSpr.remove();

		var textLabel = new TextLabelComp("Ingredients", Assets.fontPixel, this);
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

		for ( i in recipe.ingreds ) {
			new IngredComp(configMap, i, flowCont);
		}

		baseGrid.height = flowCont.outerHeight + 20;
	}

	override function sync( ctx : RenderContext ) {
		x = Boot.inst.s2d.mouseX + 20;
		y = Boot.inst.s2d.mouseY + 20;
		super.sync(ctx);
	}
}

class IngredComp extends Object {
	public function new( configMap : Map<String, TmxLayer>, ingred : Data.Recipes_ingreds, ?parent : Object ) {
		super(parent);

		var conf = configMap.get("ingreds_comp");
		var baseSpr = new HSprite(Assets.ui, "recipe_comp", this);
		var iconSpr = new HSprite(Assets.items, ingred.item.atlas_name, this);
		iconSpr.x = conf.getObjectByName("icon").x;
		iconSpr.y = conf.getObjectByName("icon").y;

		var nameLabel = new TextLabelComp(ingred.item.display_name, Assets.fontPixel, this);
		nameLabel.x = conf.getObjectByName("name").x;
		nameLabel.y = conf.getObjectByName("name").y;
		nameLabel.scale(.5);

		var amountLabel = new TextLabelComp('${ingred.amount}', Assets.fontPixel, this);
		amountLabel.x = conf.getObjectByName("counter").x;
		amountLabel.y = conf.getObjectByName("counter").y;
		amountLabel.scale(.5);
		amountLabel.center();
	}
}
