package game.server.factory;

import en.Entity;

class EntityFactoryMediator {

	public final entClasses : List<Class<Entity>>;

	public function new( entClasses ) {
		this.entClasses = entClasses;
	}
}
