package ent;

class Entity {
	public var anim:h2d.Anim;
	public var x:Float;
	public var y:Float;

	var game:Game;

	public var spr:h2d.Anim;

	public function new(posi:Int, x:Int, y:Int) {
		this.x = x + 0.5;
		this.y = y + 0.5;
		game = Game.inst;
		spr = new h2d.Anim(getAnim(), 15);
		game.world.add(spr, posi);
		game.entities.push(this);
	}

	function getAnim() {
		return null;
	}

	public function update(dt:Float) {
		spr.x = Std.int(x);
		spr.y = Std.int(y);
	}

	public function remove() {
		spr.remove();
		game.entities.remove(this);
	}
}
