package en.comp.controller.view;

import i.IUpdatable;
import i.IDestroyable;

abstract class ViewController
implements IDestroyable {

	public function new() {}

	public function attach( ent : Entity ) {}

	public function destroy() {}
}
