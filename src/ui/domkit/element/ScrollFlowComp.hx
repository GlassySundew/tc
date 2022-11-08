package ui.domkit.element;

import ui.core.FixedScrollArea;
import h2d.col.Bounds;
import h2d.col.Point;
import h2d.Flow;
import h2d.domkit.Object;
import h2d.Object;
import dn.M;

@:uiComp( "scroll-flow" )
class ScrollFlowComp extends h2d.Flow implements h2d.domkit.Object {

    // @formatter:off
	static var SRC =
		<scroll-flow layout="horizontal" >
			<flow public id="scrollBarNew" fill-height="true" width="10" background="#646464" valign="top" alpha="0.5" >
				<flow public id="scrollBarCursorNew" background="#ffffff" fill-height="true" fill-width="true" valign="top" />
			</flow>
		</scroll-flow>
	;
	// @formatter:on

    var scrollArea : FixedScrollArea;
    var scrollContent : Flow;
    var initialized = false;

    public function new( ?parent : h2d.Object ) {
        super( parent );
        initComponent( );
        scrollBarNew.enableInteractive = enableInteractive = true;
        scrollBarNew.interactive.cursor = Button;
    }

    public function init( scrollArea : FixedScrollArea, scrollContent : Flow ) {
        this.scrollArea = scrollArea;
        this.scrollContent = scrollContent;

        initialized = true;

        var scrollBounds = new Bounds();
        scrollBounds.addPoint( new Point( 0, M.fclamp( scrollContent.innerHeight, scrollArea.height, 1 / 0 ) ) );
        scrollBounds.addPoint( new Point( scrollContent.innerWidth, 0 ) );
        scrollArea.scrollBounds = scrollBounds;

        interactive.onWheel = scrollEvent;

        var handleDy = .0;

        function setCursor( e : hxd.Event ) {
            var cursorY = ( ( e.relY - handleDy ) );
            scrollArea.scrollY = ( ( cursorY * ( scrollContent.innerHeight - scrollArea.height ) ) / ( scrollBarNew.innerHeight - scrollBarCursorNew.minHeight ) );
            updateScrollCursorNew( );
        }

        scrollBarNew.interactive.onPush = ( e : hxd.Event ) -> {
            if ( e.cancel ) return;
            var scene = getScene( );
            if ( scene == null ) return;

            handleDy = if ( e.relY - scrollBarCursorNew.y < 0 || e.relY - scrollBarCursorNew.y > scrollBarCursorNew.innerHeight ) {
                scrollBarCursorNew.innerHeight * 0.5;
            } else e.relY - getDy( );

            function capture( e : hxd.Event ) {
                switch( e.kind ) {
                    case ERelease, EReleaseOutside:
                        scene.stopCapture( );
                        handleDy = 0;
                    case EPush, EMove:
                        setCursor( e );
                    default:
                }
                e.propagate = false;
            }
            capture( e );
            scrollBarNew.interactive.startCapture( capture );
        }
    }

    inline function getDy( ) {
        return
            Math.round( ( scrollArea.scrollY / ( scrollContent.innerHeight - scrollArea.height ) ) * ( scrollBarNew.innerHeight - scrollBarCursorNew.minHeight ) );
    }

    function scrollEvent( e : hxd.Event ) {
        scrollArea.scrollBy( 0, e.wheelDelta );
        updateScrollCursorNew( );
    }

    function updateScrollCursorNew( ) {
        scrollBarCursorNew.y = getDy( );
    }

    override function reflow( ) {
        super.reflow( );

        if ( initialized ) {
            scrollArea.recalcFilling( );

            var scrollBarVisibility = contentHeight <= scrollContent.calculatedHeight;
            scrollBarNew.visible = scrollBarVisibility;

            if ( scrollBarVisibility ) {
                scrollBarCursorNew.minHeight = //
                Std.int( M.fclamp(
                    1 / ( scrollContent.innerHeight / scrollArea.height ) * scrollArea.height,
                    15,
                    scrollArea.height - 0.1
                ) );
                updateScrollCursorNew( );
            }
        }
    }
}
