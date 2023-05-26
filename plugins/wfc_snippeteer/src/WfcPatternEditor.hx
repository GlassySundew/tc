import hxd.Res;
import cdb.Data.Column;
import cdb.Sheet;
import h2d.Tile;
import h2d.Bitmap;
import hide.Ide;
import hrt.prefab.Library;
import hide.comp.Scene;
import hide.comp.SceneEditor;
import hide.ui.View.ViewOptions;
import hide.comp.PropsEditor;
import haxe.Json;
import haxe.io.Bytes;
import hide.view.FileTree;
import hide.view.FileView;

/**
	cdb db line
**/
typedef WorldTileset = {
	var id : String;
	var sequences : Array<{startX : Int, startY : Int, palettes : Int }>;
	var texturePath : String;
	var tileSize : Int;
	var type : Array<Dynamic>;
}

@:keep
class WfcPatternEditor extends FileView {

	public static final TILESET_CDB_CONFIG_CONTAINER = "tileset";

	var props : PropsEditor;
	var sceneEditor : SceneEditor;
	var data : hrt.prefab.Library;

	var paletteScene : Scene;

	var scene( get, never ) : Scene;

	function get_scene() : Scene {
		return sceneEditor.scene;
	}

	override function onDisplay() {

		element.html( '
			<div class="flex vertical">
				<div id="prefab-toolbar"></div>
			
				<div
					class="scene-partition"
					style="display: flex; flex-direction: row; flex: 1; overflow: hidden"
				>
					<div class="heaps-scene"></div>
			
					<div class="tree-column">
						<div class="flex vertical">
							<div class="hide-toolbar">
								<div class="toolbar-label">
									<div class="icon ico ico-sitemap"></div>
									Scene
								</div>
							</div>
			
							<div class="hide-scenetree"></div>
						</div>
					</div>
			
					<div>
						<div class="hide-toolbar">
							<div class="toolbar-label">
								<div class="icon ico ico-sitemap"></div>
								Palette
							</div>
						</div>
			
						<div
							class="scene-partition"
							style="
								min-width: 320px;
								display: flex;
								height:98%;
								flex-direction: row;
								flex: 0;
								overflow: hidden;
							"
						>
							<div 
								class="hide-scenetree"
								id="palette-picker"
							></div>
						</div>
			
						<div class="hide-scroll"></div>
					</div>
				</div>
			</div>
			' );

		if ( sceneEditor != null ) sceneEditor.dispose();

		data = new hrt.prefab.Library();
		var content = sys.io.File.getContent( getPath() );
		data.loadData( haxe.Json.parse( content ) );
		currentSign = ide.makeSignature( content );

		sceneEditor = new WfcPatternSceneEditor( this, data );
		element.find( ".hide-scenetree" ).first().append( sceneEditor.tree.element );
		element.find( ".heaps-scene" ).first().append( scene.element );

		paletteScene = new hide.comp.Scene(
			config,
			null,
			element.find( "#palette-picker" )
		);
		paletteScene.onReady = initPaletteScene;
	}

	function fillPaletteWithTilesetConfig(
		tileset : WorldTileset,
		tilesetSheet : Sheet
	) {
		var test = tileset.sequences;
		trace( test );

		var tilesetTypeColumnName = tilesetSheet.columns.filter(
			( column : cdb.Data.Column ) -> return column.name == "type"
		)[0].type.getParameters()[0];

		var blockRendererCustomType : cdb.Data.CustomType = //
			Ide.inst.database.getCustomTypes().filter(
				( customType : cdb.Data.CustomType ) -> {
					return customType.name == tilesetTypeColumnName;
				}
			)[0];

		var tilesetType = tileset.type;
		var cdbCustomType = CdbUtil.parseCustomType(
			tilesetType,
			blockRendererCustomType
		);

		paletteScene.loadTexture( tileset.texturePath, tileset.texturePath, ( t ) -> {
			var tilesetBmp = new Bitmap( Tile.fromTexture( t ), paletteScene.s2d );
		} );
	}

	function initPaletteScene() {
		var tilesetSheet = Ide.inst.database.getSheet(
			TILESET_CDB_CONFIG_CONTAINER
		);
		for ( line in tilesetSheet.lines ) {
			fillPaletteWithTilesetConfig( line, tilesetSheet );
		}
	}

	function init() {}

	override function onResize() {}

	override public function getDefaultContent() : Bytes {
		return
			Bytes.ofString( Json.stringify( { test : 1 } ) );
	}

	override public function save() {
		sys.io.File.saveContent( getPath(), Json.stringify( { test : 1 } ) );
		super.save();
	}

	@:keep
	static var _ = FileTree.registerExtension(
		WfcPatternEditor,
		["wfc"],
		{ icon : "sitemap", createNew : "WFC pattern" }
	);
	// static var __ = ( function () {
	// 	var css = js.Browser.document.createStyleElement();
	// 	css.textContent = cherry.macro.Helper.getContent( "style.css" );
	// 	js.Browser.document.head.appendChild( css );
	// 	return true;
	// } )();
}
