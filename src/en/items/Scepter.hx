package en.items;


import h2d.Object;

class Scepter extends Item {
	public function new(?x:Float = 0, ?y:Float = 0, ?parent:Object) {
		super(x, y, parent);
		spr.set("scepter");
        displayText = "Scepter of Necromancy";
        spr.scale(.5);
	}
}
