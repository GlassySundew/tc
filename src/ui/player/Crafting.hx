package ui.player;

import ui.domkit.ScrollbarComp;
import ch2.ui.EventInteractive;
import ch2.ui.ScrollArea;
import en.player.Player;
import h2d.Flow;
import h2d.Object;
import h2d.ScaleGrid;
import h2d.col.Bounds;
import h2d.col.Point;
import hxd.Event;
import ui.InventoryGrid.InventoryCell;
import ui.domkit.CraftingComp;
import ui.domkit.IngredComp;
import ui.domkit.IngredsHintComp;
import ui.domkit.RecipeComp;

class Crafting extends NinesliceWindow {
	var scrollable : ScrollArea;

	public function new( ?parent : Object ) {
		super(( tile, bl, bt, br, bb, parent ) -> {
			new CraftingComp(tile, bl, bt, br, bb, parent);
		}, parent);

		windowComp.window.windowLabel.labelTxt.text = "Crafting";
		var craftingComp = cast(windowComp, CraftingComp);

		// scrollbar for recipes
		var caretUp = new HSprite(Assets.ui, "caret0").tile;
		var caretDown = new HSprite(Assets.ui, "caret1").tile;

		var scrollBar = new Scrollbar();
		var scrollBarComp = cast(scrollBar.windowComp, ScrollbarComp);
		scrollBar.win.removeChild(scrollBarComp.scrollbar);
		craftingComp.scroll_bar.addChild(scrollBarComp.scrollbar);

		var caret = new ScaleGrid(caretUp, 0, 3, 0, 3);

		var slider = new VerticalSlider(craftingComp.scroll_bar.minWidth, craftingComp.scroll_bar.minHeight, caret, scrollBar.windowComp.window);

		slider.addChild(caret);
		scrollBar.windowComp.window.getProperties(slider).isAbsolute = true;
		slider.cursorObj.x = 1;

		// укорочение каретки
		var sliderDelta = 2;
		slider.y += sliderDelta;
		slider.height -= sliderDelta * 2;

		var scroll = ( e : Event ) -> {
			if ( e.kind == EWheel ) {
				scrollable.scrollBy(0, e.wheelDelta);
				slider.value = scrollable.scrollY;
			}
		};

		slider.onWheelEvent.add(scroll);

		scrollable = new FixedScrollArea(0, 0, true, true, Std.downcast(windowComp, CraftingComp).scrollable);
		@:privateAccess scrollable.sync(Boot.inst.s2d.ctx);

		var recipeEntriesFlow = new Flow();
		recipeEntriesFlow.layout = Vertical;
		recipeEntriesFlow.verticalSpacing = 1;
		recipeEntriesFlow.fillWidth = true;
		scrollable.addChild(recipeEntriesFlow);

		for ( recipe in Data.recipes.all ) {
			var rec = new Recipe(recipe, recipeEntriesFlow);
			rec.windowComp.window.minWidth = scrollable.width;
			cast(rec.windowComp, RecipeComp).onWheel.add(scroll);
		}

		var backgroundScroll = new EventInteractive(0, 0);
		scrollable.addChildAt(backgroundScroll, 0);
		backgroundScroll.onWheelEvent.add(scroll);
		backgroundScroll.width = recipeEntriesFlow.innerWidth;
		backgroundScroll.height = recipeEntriesFlow.innerHeight;
		backgroundScroll.cursor = Default;

		var scrollBounds = new Bounds();
		scrollBounds.addPoint(new Point(0, M.fclamp(recipeEntriesFlow.innerHeight, scrollable.height, 1 / 0)));
		scrollBounds.addPoint(new Point(recipeEntriesFlow.innerWidth, 0));
		scrollable.scrollBounds = scrollBounds;

		caret.height = M.fclamp((1 / (recipeEntriesFlow.innerHeight / scrollable.height) * scrollable.height), caretUp.height,
			scrollable.height - sliderDelta * 2 - 0.1);

		slider.maxValue = recipeEntriesFlow.innerHeight > scrollable.height ? recipeEntriesFlow.innerHeight - scrollable.height : 0.1;

		slider.onPushEvent.add(( _ ) -> {
			slider.cursorObj.tile = caretDown;
		});
		slider.onReleaseEvent.add(( _ ) -> {
			slider.cursorObj.tile = caretUp;
		});

		slider.onChange = () -> {
			scrollable.scrollTo(0, slider.value);
		};

		toggleVisible();
	}
}

class Recipe extends NinesliceWindow {
	public var inter : EventInteractive;

	var hint : IngredsHint;

	public function new( recipe : Data.Recipes, ?parent : Object ) {
		super("craft_recipe", ( tile, bl, bt, br, bb, parent ) -> {
			new RecipeComp(recipe, tile, bl, bt, br, bb, parent);
		}, parent);

		windowComp.window.windowLabel.labelTxt.text = recipe.name + (recipe.result.length > 0 ? (" x " + recipe.result[0].amount) : "");

		var recipeComp = Std.downcast(windowComp, RecipeComp);
		recipeComp.onOver.add(( e ) -> {
			hint = new IngredsHint(recipe, Game.inst.root);
		});
		recipeComp.onOut.add(( e ) -> {
			if ( hint != null ) hint.destroy();
		});
		recipeComp.craft = () -> craft(recipe);
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
		if ( hint != null ) hint.destroy();
	}
}
/** Показывает ингредиенты **/
class IngredsHint extends NinesliceWindow {
	public function new( recipe : Data.Recipes, ?parent : Object ) {
		super("ingreds_hint", ( tile, bl, bt, br, bb, parent ) -> {
			new IngredsHintComp(tile, bl, bt, br, bb, parent);
		}, parent);

		var hintComp = Std.downcast(windowComp, IngredsHintComp);

		for ( i in recipe.ingreds ) {
			new Ingred(i, hintComp.ingreds_holder);
		}
	}

	override function update() {
		super.update();

		{
			win.x = (Boot.inst.s2d.mouseX + 20) / Const.SCALE;
			win.y = (Boot.inst.s2d.mouseY + 20) / Const.SCALE;
		}
	}
}

class Ingred extends NinesliceWindow {
	public function new( ingred : Data.Recipes_ingreds, ?parent : Object ) {
		super("craft_recipe", ( tile, bl, bt, br, bb, parent ) -> {
			new IngredComp(tile, bl, bt, br, bb, ingred, parent);
		}, parent);

		var ingredComp = Std.downcast(windowComp, IngredComp);
		ingredComp.window.windowLabel.label = ingred.item != null ? ingred.item.display_name : "zhopa";
		// var baseSpr = new HSprite(Assets.ui, "recipe_comp", this);
		// var iconSpr = new HSprite(Assets.items, ingred.item.atlas_name, this);

		// var nameLabel = new TextLabelComp(ingred.item.display_name, Assets.fontPixel, this);
		// nameLabel.scale(.5);

		// var amountLabel = new TextLabelComp('${ingred.amount}', Assets.fontPixel, this);
		// amountLabel.scale(.5);
		// amountLabel.center();
	}
}
