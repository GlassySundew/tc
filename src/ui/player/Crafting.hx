package ui.player;

import ch2.ui.EventInteractive;
import ch2.ui.ScrollArea;
import en.player.Player;
import h2d.Flow;
import h2d.Object;
import h2d.ScaleGrid;
import h2d.col.Bounds;
import h2d.col.Point;
import h3d.Vector;
import hxd.Event;
import ui.InventoryGrid.InventoryCell;
import ui.domkit.CraftingComp;
import ui.domkit.IngredComp;
import ui.domkit.IngredsHintComp;
import ui.domkit.RecipeComp;
import ui.domkit.ScrollbarComp;

class Crafting extends NinesliceWindow {
	var scrollable : ScrollArea;

	public function new( source : Data.Recipe_recipe_source, ?parent : Object ) {
		super(CraftingComp, parent);

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
				slider.value = scrollable.scrollY + e.wheelDelta * scrollable.scrollStep;
				GameClient.inst.tw.createMs(scrollable.scrollY, slider.value, TLinear, 60);
			}
		};

		slider.onWheelEvent.add(scroll);

		scrollable = new FixedScrollArea(0, 0, true, true, Std.downcast(windowComp, CraftingComp).scrollable);
		@:privateAccess scrollable.sync(Boot.inst.s2d.ctx);
		scrollable.scrollStep = 30;

		var recipeEntriesFlow = new Flow();
		recipeEntriesFlow.layout = Vertical;
		recipeEntriesFlow.verticalSpacing = 1;
		recipeEntriesFlow.fillWidth = true;
		scrollable.addChild(recipeEntriesFlow);

		for ( recipe in Data.recipe.all ) {
			if ( recipe.recipe_source.has(source) ) {
				var rec = new Recipe(recipe, recipeEntriesFlow);
				rec.windowComp.window.minWidth = scrollable.width;
				cast(rec.windowComp, RecipeComp).onWheel.add(scroll);
			}
		}

		var backgroundScroll = new EventInteractive(0, 0);
		scrollable.addChildAt(backgroundScroll, 0);
		backgroundScroll.onWheelEvent.add(scroll);
		backgroundScroll.onOverEvent.add(( e ) -> if ( Player.inst != null ) Player.inst.lockBelt());
		backgroundScroll.onOutEvent.add(( e ) -> if ( Player.inst != null ) Player.inst.unlockBelt());
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

		slider.onOverEvent.add(( e ) -> if ( Player.inst != null ) Player.inst.lockBelt());
		slider.onOutEvent.add(( e ) -> if ( Player.inst != null ) Player.inst.unlockBelt());

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

	override function onDispose() {
		super.onDispose();
		if ( Player.inst != null ) Player.inst.unlockBelt();
	}
}

class Recipe extends NinesliceWindow {
	public var inter : EventInteractive;

	var hint : IngredsHint;

	public function new( recipe : Data.Recipe, ?parent : Object ) {
		super("craft_recipe", RecipeComp, parent, recipe);

		// cast(windowComp, Recip)
		windowComp.window.windowLabel.labelTxt.text = recipe.name + (recipe.result.length > 0 ? (" x " + recipe.result[0].amount) : "");

		var recipeComp = Std.downcast(windowComp, RecipeComp);
		recipeComp.onOver.add(( e ) -> {
			hint = new IngredsHint(recipe, GameClient.inst.root);
			if ( Player.inst != null ) Player.inst.lockBelt();
		});
		recipeComp.onOut.add(( e ) -> {
			if ( hint != null ) hint.destroy();
			if ( Player.inst != null ) Player.inst.unlockBelt();
		});
		recipeComp.craft = () -> craft(recipe);
	}

	public function craft( recipe : Data.Recipe ) {
		// checking if player has requiredData.Item
		for ( i in recipe.ingred ) {
			var checkedCells : Array<InventoryCell> = [];

			var amountPitch = i.amount;
			while( amountPitch > 0 ) {
				var targetItemSlot = Player.inst.inventory.findItemKind(i.item, 1, checkedCells);
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
		for ( i in recipe.ingred ) {
			var amountPitch = i.amount;
			while( amountPitch > 0 ) {
				var targetItemSlot = Player.inst.inventory.findItemKind(i.item, 1, []);
				if ( targetItemSlot == null ) {
					return null;
				} else if ( targetItemSlot.item.amount >= i.amount ) {
					targetItemSlot.item.amount -= amountPitch;
					amountPitch = 0;
				} else {
					amountPitch -= targetItemSlot.item.amount;
					if ( targetItemSlot.item.itemSprite != null )
						targetItemSlot.item.itemSprite.remove();
					targetItemSlot.item = null;
				}
			}
		}
		for ( i in recipe.result ) {
			var newItem = Item.fromCdbEntry(i.itemId, Player.inst, i.amount);
			Player.inst.inventory.giveItem(newItem);
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
	public function new( recipe : Data.Recipe, ?parent : Object ) {
		super("ingreds_hint", IngredsHintComp, parent, recipe);

		var hintComp = Std.downcast(windowComp, IngredsHintComp);

		for ( i in recipe.ingred ) {
			new Ingred(i, hintComp.ingreds_holder);
		}
		bringOnTopOfALL();
	}

	override function update() {
		super.update();

		{
			win.x = (Boot.inst.s2d.mouseX + 20) / Const.UI_SCALE;
			win.y = (Boot.inst.s2d.mouseY + 20) / Const.UI_SCALE;
		}
	}
}

class Ingred extends NinesliceWindow {
	public function new( ingred : Data.Recipe_ingred, ?parent : Object ) {
		super("craft_recipe", IngredComp, parent, ingred);

		var ingredComp = Std.downcast(windowComp, IngredComp);
		ingredComp.window.windowLabel.label = ingred.item != null ? ingred.item.display_name : "zhopa";
	}
}
