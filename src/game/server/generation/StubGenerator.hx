package game.server.generation;

import util.TmxUtils;
import util.Util;
import util.MapCache;
import util.EregUtil;
import format.tmx.Tools;
import format.tmx.TmxMap;

using util.Extensions.TmxPropertiesExtension;

/**
	generates a chunk of 1-layer grass
**/
class StubGenerator extends ChunkGenerator {

	public function new() {}

	public function generateChunk( x : Int, y : Int ) {}

	public function placeSnippet( x : Int, y : Int, mapName : String ) {
		var tmxMap : TmxMap = MapCache.inst.get( Util.unifyLevelName( mapName ) );
		tmxMap.properties.propagateTo( level.properties );

		TmxUtils.mapTmxMap(
			tmxMap,
			{
				tmxObjLayerCb : ( ol ) -> {
					if ( ol.name == 'entities' )
						for ( obj in ol.objects ) {
							// Если Entity никак не назван на карте - то ему
							// присваивается имя его картинки без расширения
							if ( obj.name == "" ) {
								obj.name = //
									switch( obj.objectType ) {
										case OTTile( gid ):
											var objTsTile = Tools.getTileByGid( tmxMap, gid );
											objTsTile.properties.getProp( PTString, "name", null, () -> {
												if ( EregUtil.eregFileName.match( objTsTile.image.source ) )
													EregUtil.eregFileName.matched( 1 );
												else
													"";
											} );

										default: "";
									};
							}

							switch obj.objectType {
								case OTTile( gid ):
									Tools.propagateTilePropertiesToObject( obj, tmxMap, gid );
								default:
							}
							if ( obj.name == "player" ) {
								level.player.obj = obj;
								level.player.tsTile = TmxUtils.getTmxObjTsTile( obj, tmxMap );
							} else
								level.entitiesTmxObj.push( obj );
						}
				},
				tmxTileLayerCb : ( tl ) -> {
					var z = tl.properties.getProp( PTFloat, "zHeight", 0 );
					var depthOff = tl.properties.getProp( PTInt, "depthOff", 0 );

					for ( i => tile in tl.data.tiles ) {
						if ( tile.gid != 0 ) {
							level.ctrl.placeBlockTmx( i, z, tile, depthOff, tmxMap );
						}
					}
				}
			}
		);
	}
}
