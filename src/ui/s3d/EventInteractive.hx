package ui.s3d;

import cherry.soup.EventSignal;
import h3d.scene.Interactive;
import hxd.Event;

/**
	Simple wrapper to h3d.scene.Interactive that allows multiple subscriptions to on* events.
	Overriding on* functions still possible.

	ported to 3d from yanrishatum's code
**/
class EventInteractive extends Interactive {
	public var onOverEvent:EventSignal1<Event> = new EventSignal1();
	public var onOutEvent:EventSignal1<Event> = new EventSignal1();
	public var onPushEvent:EventSignal1<Event> = new EventSignal1();
	public var onReleaseEvent:EventSignal1<Event> = new EventSignal1();
	public var onReleaseOutsideEvent:EventSignal1<Event> = new EventSignal1();
	public var onClickEvent:EventSignal1<Event> = new EventSignal1();
	public var onMoveEvent:EventSignal1<Event> = new EventSignal1();
	public var onWheelEvent:EventSignal1<Event> = new EventSignal1();
	public var onFocusEvent:EventSignal1<Event> = new EventSignal1();
	public var onFocusLostEvent:EventSignal1<Event> = new EventSignal1();
	public var onKeyUpEvent:EventSignal1<Event> = new EventSignal1();
	public var onKeyDownEvent:EventSignal1<Event> = new EventSignal1();
	public var onCheckEvent:EventSignal1<Event> = new EventSignal1();
	public var onTextInputEvent:EventSignal1<Event> = new EventSignal1();

	override public function handleEvent(e:Event) {
		if (propagateEvents)
			e.propagate = true;
		if (cancelEvents)
			e.cancel = true;
		switch (e.kind) {
			case EMove:
				onMoveEvent.dispatch(e);
				onMove(e);
			case EPush:
				if (enableRightButton || e.button == 0) {
					mouseDownButton = e.button;
					onPushEvent.dispatch(e);
					onPush(e);
				}
			case ERelease:
				if (enableRightButton || e.button == 0) {
					onReleaseEvent.dispatch(e);
					onRelease(e);
					if (mouseDownButton == e.button) {
						onClickEvent.dispatch(e);
						onClick(e);
					}
				}
				mouseDownButton = -1;
			case EReleaseOutside:
				if (enableRightButton || e.button == 0) {
					onReleaseEvent.dispatch(e);
					onRelease(e);
					if (mouseDownButton == e.button) {
						onReleaseOutsideEvent.dispatch(e);
						onReleaseOutside(e);
					}
				}
				mouseDownButton = -1;
			case EOver:
				onOverEvent.dispatch(e);
				onOver(e);
				if (!e.cancel && cursor != null)
					hxd.System.setCursor(cursor);
			case EOut:
				mouseDownButton = -1;
				onOutEvent.dispatch(e);
				onOut(e);
				if (!e.cancel)
					hxd.System.setCursor(Default);
			case EWheel:
				onWheelEvent.dispatch(e);
				onWheel(e);
			case EFocusLost:
				onFocusLostEvent.dispatch(e);
				onFocusLost(e);
			case EFocus:
				onFocusEvent.dispatch(e);
				onFocus(e);
			case EKeyUp:
				onKeyUpEvent.dispatch(e);
				onKeyUp(e);
			case EKeyDown:
				onKeyDownEvent.dispatch(e);
				onKeyDown(e);
			case ECheck:
				onCheckEvent.dispatch(e);
				onCheck(e);
			case ETextInput:
				onTextInputEvent.dispatch(e);
				onTextInput(e);
		}
	}
}
