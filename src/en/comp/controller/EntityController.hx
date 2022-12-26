package en.comp.controller;

import net.NetNode;
import i.IUpdatable;
import i.IDestroyable;

abstract class EntityController implements IDestroyable {

	var classType : Class<EntityController>;
	var ent : Entity;

	public function new() {
		classType = Type.getClass( this );
	}

	public function attach( ent : Entity ) {
		this.ent = ent;
		ent.components[classType] = this;
	}

	public function destroy() {
		ent.components[classType] = null;
	}
}
