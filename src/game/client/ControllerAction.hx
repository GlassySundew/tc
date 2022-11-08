package game.client;

enum abstract ControllerAction(Int) to Int {
	var MoveUp;
	var MoveUpRight;
	var MoveRight;
	var MoveDownRight;
	var MoveDown;
	var MoveDownLeft;
	var MoveLeft;
	var MoveUpLeft;

	var Action;
	var DropItem;
	var ToggleInventory;
	var ToggleCraftingMenu;
	var Escape;
}
