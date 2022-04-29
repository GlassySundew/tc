package ui;

import cherry.soup.EventSignal.EventSignal0;
import h2d.Object;

class OnSceneAddedObject extends Object {
	public var onAddedToSceneEvent = new EventSignal0();

	override function onAdd() {
		super.onAdd();
		if ( getScene() != null )
			onAddedToSceneEvent.dispatch();
	}

	override function onRemove() {
		super.onRemove();
		onAddedToSceneEvent.removeAll();
		onAddedToSceneEvent = null;
	}
}