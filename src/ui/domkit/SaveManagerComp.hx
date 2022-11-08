package ui.domkit;

import h2d.domkit.Style;
import ui.dialog.DeleteDialog;
import ui.dialog.SaveManager.Mode;
import ui.domkit.element.ButtonComp;
import ui.domkit.element.FixedScrollAreaComp;
import ui.domkit.element.ShadowedTextComp;
import ui.domkit.element.ScrollFlowComp;

class SaveManagerComp extends h2d.Flow implements h2d.domkit.Object {

	// @formatter:off
	static var SRC =
		<save-manager-comp layout="vertical" margin="5">
			<flow layout="vertical" halign="middle" margin-bottom="5" id="marginBottomFrom">
				<shadowed-text( titleText ) />
			</flow>

			<scroll-flow id="scrollFlow" fill-height="true" background="#222222" padding="5" overflow="limit" >
				<fixed-scroll-area( 300, 10, false, true ) id="scrollArea" valign="top" halign="left" margin-right="5" >
					<flow id="scrollContent" layout="vertical" vspacing="4" max-width={scrollArea.width} >
						for( file in saveFiles ) {
							<save-entry( ${file}, mode ) />
						}
					</flow>
				</fixed-scroll-area>
			</scroll-flow>
		</save-manager-comp>
	;
		
	// @formatter:on
	var titleText : String;

	public function new( mode : Mode, saveFiles : Array<String>, ?parent : h2d.Object ) {
		super( parent );

		titleText = switch mode {
			case Save: "Save file: ";
			case Load: "Load file: ";
			default: "";
		};

		initComponent();

		var style = new Style();
		style.addObject( this );
		style.allowInspect = true;

		// костыль потому что почему-то список сейвов вылезает за пределы maxHeight
		scrollFlow.dom.setAttribute( "margin-bottom", VInt( marginBottomFrom.outerHeight + 10 ) );
		scrollFlow.addChild( scrollFlow.scrollBarNew );
		scrollFlow.init( scrollArea, scrollContent );
	}

	override function reflow() {
		super.reflow();
		scrollContent.maxHeight = scrollArea.height;
	}
}

@:uiComp( "save-entry" )
class SaveEntryComp extends h2d.Flow implements h2d.domkit.Object {

	// @formatter:off
	static var SRC = 
		<save-entry fill-width="true" background="#393939" padding-bottom="2" >
			<shadowed-text(file) valign="middle" />

			<flow halign="right" valign="middle" scale="0.5" position="absolute" margin-right="3" > // buttons
				${
					switch mode {
						case Load: 
							<button("start", 3, load) />
						case Save:
							<button("save", 3, save) />
						case NewSaveEntry:
							<button("new", 3, newSave) />
					}
					switch mode {
						case Load | Save : <button("trash", 2, delete) />
						default:
					}
				}
			</flow>
		</save-entry>
	;
	// @formatter:on
	var file : String;

	public function new( file : String, mode : Mode, ?parent : h2d.Object ) {
		super( parent );
		initComponent();

		this.file = file;
	}

	function load() {}

	function newSave() {
		// new NewSaveDialog();

	}

	function save() {}

	function delete() {
		new DeleteDialog( file );
	}
}
