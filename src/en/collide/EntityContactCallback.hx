package en.collide;

import cherry.soup.EventSignal.EventSignal1;
import cherry.soup.EventSignal.EventSignal0;
import oimo.dynamics.Contact;
import oimo.dynamics.callback.ContactCallback;

class EntityContactCallback extends ContactCallback {

	public var beginContactSign = new EventSignal1<Contact>();
	public var preSolveSign = new EventSignal1<Contact>();
	public var postSolveSign = new EventSignal1<Contact>();
	public var endContactSign = new EventSignal1<Contact>();

	override function beginContact( c : Contact ) {
		beginContactSign.dispatch( c );
	}

	override function preSolve( c : Contact ) {
		preSolveSign.dispatch( c );
	}

	override function postSolve( c : Contact ) {
		postSolveSign.dispatch( c );
	}

	override function endContact( c : Contact ) {
		endContactSign.dispatch( c );
	}
}
