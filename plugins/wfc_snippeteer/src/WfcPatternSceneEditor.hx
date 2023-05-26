import hide.Ide;
import hide.comp.cdb.DataFiles;
import hrt.prefab.Prefab;
import hide.comp.ContextMenu.ContextMenuItem;

class WfcPatternSceneEditor extends hide.comp.SceneEditor {

	override private function getNewContextMenu(
		current : Prefab,
		?onMake : Prefab -> Void = null,
		?groupByType : Bool = true
	) : Array<ContextMenuItem> {

		var newItems = new Array<hide.comp.ContextMenu.ContextMenuItem>();
		var allRegs = Library.getRegistered().copy();
		allRegs.remove( "reference" );
		allRegs.remove( "unknown" );
		var parent = current == null ? sceneData : current;

		var groups = [];
		var gother = [];

		for ( g in ( view.config.get( "sceneeditor.newgroups" ) : Array<String> ) ) {
			var parts = g.split( "|" );
			var cl : Dynamic = Type.resolveClass( parts[1] );
			if ( cl == null ) continue;
			groups.push( {
				label : parts[0],
				cl : cl,
				group : [],
			} );
		}
		for ( ptype in allRegs.keys() ) {
			var pinf = allRegs.get( ptype );
			if ( ptype == "UiDisplay" )
				trace( "break" );

			if ( !checkAllowParent( { cl : ptype, inf : pinf.inf }, parent ) ) continue;
			if ( ptype == "shader" ) {
				newItems.push( getNewShaderMenu( parent, onMake ) );
				continue;
			}

			var m = getNewTypeMenuItem( ptype, parent, onMake );
			if ( !groupByType )
				newItems.push( m );
			else {
				var found = false;
				for ( g in groups )
					if ( hrt.prefab.Library.isOfType( ptype, g.cl ) ) {
						g.group.push( m );
						found = true;
						break;
					}
				if ( !found ) gother.push( m );
			}
		}
		function sortByLabel( arr : Array<hide.comp.ContextMenu.ContextMenuItem> ) {
			arr.sort( function ( l1, l2 ) return Reflect.compare( l1.label, l2.label ) );
		}
		for ( g in groups )
			if ( g.group.length > 0 ) {
				sortByLabel( g.group );
				newItems.push( { label : g.label, menu : g.group } );
			}
		sortByLabel( gother );
		sortByLabel( newItems );
		if ( gother.length > 0 ) {
			if ( newItems.length == 0 )
				return gother;
			newItems.push( { label : "Other", menu : gother } );
		}

		return newItems;
	}

	override function getNewTypeMenuItem(
		ptype : String,
		parent : Prefab,
		onMake : Prefab -> Void,
		?label : String,
		?objectName : String,
		?path : String
	) : ContextMenuItem {
		var pmodel = Library.getRegistered().get( ptype );
		return {
			label : label != null ? label : pmodel.inf.name,
			click : function () {
				function make( ?sourcePath ) {
					if ( ptype == "UiDisplay" )
						trace( "Break" );
					var p = Type.createInstance( pmodel.cl, [parent] );
					@:privateAccess p.type = ptype;
					if ( sourcePath != null )
						p.source = sourcePath;
					if ( objectName != null )
						p.name = objectName;
					else
						autoName( p );
					if ( onMake != null )
						onMake( p );
					var recents : Array<String> = ide.currentConfig.get( "sceneeditor.newrecents", [] );
					recents.remove( p.type );
					recents.unshift( p.type );
					var recentSize : Int = view.config.get( "sceneeditor.recentsize" );
					if ( recents.length > recentSize ) recents.splice( recentSize, recents.length - recentSize );
					ide.currentConfig.set( "sceneeditor.newrecents", recents );
					return p;
				}

				if ( pmodel.inf.fileSource != null ) {
					if ( path != null ) {
						var p = make( path );
						addElements( [p] );
						var recents : Array<String> = ide.currentConfig.get( "sceneeditor.newrecents", [] );
						recents.remove( p.type );
					} else {
						ide.chooseFile( pmodel.inf.fileSource, function ( path ) {
							addElements( [make( path )] );
						} );
					}
				}
				else
					addElements( [make()] );
			},
			icon : pmodel.inf.icon,
		};
	}
}
