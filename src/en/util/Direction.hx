package en.util;

@:forward
enum abstract Direction( Int ) from Int to Int {

	var Right = 0;
	var TopRight = 1;
	var Top = 2;
	var TopLeft = 3;
	var Left = 4;
	var BottomLeft = 5;
	var Bottom = 6;
	var BottomRight = 7;
}
