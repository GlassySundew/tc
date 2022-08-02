package mapgen;

import format.tmx.TmxMap;
import utils.MapCache;
import format.tmx.Data;
import haxe.Serializer;
import haxe.Unserializer;
import hxd.Res;

typedef Rules = Map<{regions_input : CoordinatedIsland, regions_output : CoordinatedIsland },
	{ inputs : Map<String, Array<TmxGeneratable>>, outputs : Map<String, Array<TmxGeneratable>>, mapProps : TmxProperties }>;

typedef ExtractedLayer = Array<Array<Null<TmxTile>>>;

typedef CoordinatedTile = { tile : Null<TmxTile>, x : Int, y : Int };

typedef CoordinatedIsland = Array<CoordinatedTile>;

enum TmxExtracted {
	TileLayer( layer : ExtractedLayer );
	ObjectLayer( layer : Array<TmxObject> );
}

enum TmxCoordinated {
	CoordinatedTileLayer( layer : CoordinatedIsland );
	CoordinatedObjectLayer( layer : Array<TmxObject> );
}

enum TmxGeneratable {
	TileGeneratable( tile : CoordinatedTile );
	ObjectGeneratable( object : TmxObject );
	Random( tmxGen : TmxGeneratable );
}

/** 
	небольшое расхождение с оригинальным алгоритмом tiled: если указано случайное распределение тайлов через 
	output{номер}_layerName, и в карте присутствует карта с layerName но без номера, в случайном распределении она участвовать не будет
**/
class AutoMap {

	public var rules : Rules = [];

	var layersByName : Map<String, TmxLayer>;

	/** rulemap **/
	var ruleMaps : Array<TmxMap>;

	/** Generates autotile rules from rules.tmx **/
	public function new( rulePath : String ) {
		var ruleFiles : String = Res.loader.load( rulePath ).entry.getText();
		ruleMaps = [];

		for ( i in ruleFiles.split( '\n' ) ) {
			if ( i != "" && !StringTools.startsWith( i, "//" ) && !StringTools.startsWith( i, "#" ) ) {
				ruleMaps.push( MapCache.inst.get( StringTools.replace( i, "./", "" ) ) );
			}
		}

		for ( ruleMap in ruleMaps ) {
			layersByName = ruleMap.mapLayersByName();

			var regions_input = extractFromLayer( layersByName.get( "regions_input" ), ruleMap );
			var regions_output = extractFromLayer( layersByName.get( "regions_output" ), ruleMap );

			var inputs : Map<String, TmxExtracted> = [];
			var outputs : Map<String, TmxExtracted> = [];

			for ( name => layer in layersByName ) {
				if ( StringTools.startsWith( name, "input" ) ) inputs.set( name, extractFromLayer( layer, ruleMap ) );
				if ( StringTools.startsWith( name, "output" ) ) outputs.set( name, extractFromLayer( layer, ruleMap ) );
			}

			compileRules( cast( Type.enumParameters( regions_input )[0] ), cast( Type.enumParameters( regions_output )[0] ), inputs, outputs, ruleMap );

			// debugRules();
		}
	}

	function debugRules() {
		for ( regions => puts in rules ) {
			for ( region in regions.regions_input ) {
				trace( "reg input" + region );
			}
			for ( region in regions.regions_output ) {
				trace( "reg output" + region );
			}

			for ( inputIndex => input in puts.inputs ) {
				trace( inputIndex );
				for ( tile in input ) {
					trace( tile );
				}
			}
			for ( outputIndex => output in puts.outputs ) {
				trace( outputIndex );
				for ( tile in output ) {
					trace( tile );
				}
			}
			trace( '=========================================' );
		}
	}

	public function applyRulesToMap( map : TmxMap ) {

		function getLayerIndexByName( name : String, ruleMap : TmxMap ) : Int {
			for ( index => i in ruleMap.layers ) switch i {
				case LTileLayer( layer ):
					if ( layer.name == name ) return index;
				case LObjectGroup( group ):
					if ( group.name == name ) return index;
				default:
					throw "unsupported";
			}
			return 0;
		}

		function ruleMatchesOnLayer( rule : Array<TmxGeneratable>, layer : TmxExtracted, isNot : Bool, layerTile0x : Int, layerTile0y : Int ) : Bool {
			switch layer {
				case TileLayer( layerTo ):
					var rule0x = Type.enumParameters( rule[0] )[0].x;
					var rule0y = Type.enumParameters( rule[0] )[0].y;

					for ( ruleTile in rule ) {
						switch ruleTile {
							case TileGeneratable( tileFrom ):
								try {
									var layerTileTo = layerTo[tileFrom.y - rule0y + layerTile0y][tileFrom.x - rule0x + layerTile0x];
									if ( isNot ) {
										if ( ( tileFrom.tile.gid != 0 && tileFrom.tile.gid == layerTileTo.gid ) ) return true;
									} else if ( tileFrom.tile.gid != 0 && tileFrom.tile.gid != layerTileTo.gid ) return false;
								} catch( e : Dynamic ) {
									return false;
								}
							default:
						}
					}
				default:
			}
			return isNot ? false : true;
		}

		// noOverlapping parameter utility, must to be cleared every rule check
		var appliedTiles : Array<{x : Int, y : Int }> = [];

		function applyRuleToLayer( rule : { regions_input : CoordinatedIsland, regions_output : CoordinatedIsland },
			outputs : Map<String, Array<TmxGeneratable>>, layerTile0x : Int, layerTile0y : Int,
			props : { deleteTiles : Bool, noOverlappingRules : Bool } ) {

			function createLayerIfNotExistsByName( name : String, type : TmxGeneratable ) {
				var layerByName = map.getLayersByName( name )[0];

				function newTileLayer() return LTileLayer( new TmxTileLayer( {
					encoding : null,
					compression : null,
					tiles : emptyTiles( map ),
					chunks : null,
					data : null
				}, 0, name, 0, 0, 0, 0, map.width, map.height, 1, true, 0xFFFFFF,
					new TmxProperties() ) );

				function newObjectLayer() return LObjectGroup( new TmxObjectGroup( TmxObjectGroupDrawOrder.Topdown, [], 0xffffff, 0, name, 0, 0, 0, 0,
					map.height, map.width, 1, true, 0xffffff, new TmxProperties() ) );

				if ( layerByName == null ) {

					layerByName = switch type {
						case TileGeneratable( tile ): newTileLayer();
						case ObjectGeneratable( object ): newObjectLayer();
						case Random( tmxGen ):
							switch tmxGen {
								case TileGeneratable( tile ): newTileLayer();
								case ObjectGeneratable( object ): newObjectLayer();
								default: throw "bad logic";
							}
					};

					map.layers.push( layerByName );
				}
				return layerByName;
			}

			function extractRandom( outputTiles : Array<TmxGeneratable> ) {
				var result = [];
				for ( i in outputTiles ) {
					switch i {
						case Random( tmxGen ):
							result.push( tmxGen );
						default:
							throw "bad logic";
					}
				}
				return result;
			}

			for ( layerName => output in outputs ) {
				if ( output.length > 0 ) {
					// random distribution, here we make a choice
					var randomCheck = layerName.split( "%random%" );
					if ( randomCheck[1] != null && randomCheck[1] != "" ) {
						var pool : Map<String, Array<TmxGeneratable>> = [];
						var rawPool = [];
						for ( layerName => output in outputs ) {
							if ( layerName.split( "%random%" )[1] != "" )
								pool[layerName] = pool[layerName] == null ? extractRandom( output ) : pool[layerName].concat( extractRandom( output ) );
						}
						for ( value in pool ) rawPool.push( value );
						output = std.Random.fromArray( rawPool );
						layerName = randomCheck[0];
					}

					var currentLayer = createLayerIfNotExistsByName( StringTools.replace( layerName, "output_", "" ), output[0] );

					switch currentLayer {
						case LTileLayer( layer ):
							// первый тайл в output хранилище
							var params = Type.enumParameters( output[0] )[0];
							var rule0x = params.x;
							var rule0y = params.y;
							for ( i in output ) {
								switch i {
									case TileGeneratable( tile ):
										if ( tile.tile.gid != 0 ) {
											var x = tile.x - rule0x + layerTile0x + rule.regions_output[0].x - rule.regions_input[0].x;
											var y = tile.y - rule0y + layerTile0y + rule.regions_output[0].y - rule.regions_input[0].y;

											if ( layer.data.tiles[x + y * map.width].gid == 0 || props.deleteTiles ) {

												if ( props.noOverlappingRules ) appliedTiles.push( { x : x, y : y } );
												layer.data.tiles[x + y * map.width] = tile.tile;
											}
										}
									default:
										throw "Guaranteed to be tile layer but its not";
								}
							}
						case LObjectGroup( group ):

							for ( i in output ) {
								switch i {
									case ObjectGeneratable( object ):
										if ( object != null ) {
											// creating new TmxObject
											group.objects.push( {
												id : object.id,
												name : object.name,
												type : object.type,
												x : object.x % map.tileHeight + ( M.floor( object.x / map.tileHeight ) - rule.regions_input[0].x
													+ layerTile0x ) * map.tileHeight,
												y : object.y % map.tileHeight + ( M.floor( object.y / map.tileHeight ) - rule.regions_input[0].y
													+ layerTile0y ) * map.tileHeight,
												width : object.width,
												height : object.height,
												rotation : object.rotation,
												visible : object.visible,
												objectType : object.objectType,
												properties : object.properties,
												flippedHorizontally : object.flippedHorizontally,
												flippedVertically : object.flippedVertically,
												template : object.template,
											} );
										}
									default:
										throw "Guaranteed to be object layer but its not";
								}
							}
						default:
					}
				}
			}
		}

		function isOverlapping( rule : { regions_input : CoordinatedIsland, regions_output : CoordinatedIsland },
			outputs : Map<String, Array<TmxGeneratable>>, layerTile0x : Int, layerTile0y : Int ) : Bool {

			for ( output in outputs ) {
				if ( output.length > 0 ) {
					var params = try {
						Type.enumParameters( output[0] )[0];
					} catch( e : Dynamic ) {
						Type.enumParameters( Type.enumParameters( output[0] )[0] )[0];
					}

					var rule0x = params.x;
					var rule0y = params.y;

					for ( outputTileI => outputTile in output ) {

						switch outputTile {
							case TileGeneratable( tile ):
								var x = ( tile.x - rule0x + layerTile0x + rule.regions_output[0].x - rule.regions_input[0].x );
								var y = ( tile.y - rule0y + layerTile0y + rule.regions_output[0].y - rule.regions_input[0].y );

								if ( tile.tile.gid != 0 && Lambda.exists( appliedTiles, tile -> {
									return tile.x == x && tile.y == y;
								} ) ) return true;
							default:
						}
					}
				}
			}
			return false;
		}

		// proto layer usually
		for ( layerTo in map.layers.copy() ) {
			var extractedLayerTo = extractFromLayer( layerTo, map );
			for ( region => rule in rules ) {
				var ruleProps = {
					deleteTiles : rule.mapProps.exists( 'DeleteTiles' ) ? rule.mapProps.getBool( 'DeleteTiles' ) : false,
					noOverlappingRules : rule.mapProps.exists( 'NoOverlappingRules' ) ? rule.mapProps.getBool( 'NoOverlappingRules' ) : false
				};
				switch( layerTo ) {
					case LTileLayer( tileLayerTo ):
						for ( iTo => tileTo in tileLayerTo.data.tiles ) { // appliable layer
							if ( tileTo.gid != 0 ) {
								var layerTile0x = iTo % map.width;
								var layerTile0y = M.floor( iTo / map.width );

								var ruleMatched = true;
								var ruleMatchedOnce = false;

								for ( inputLayerName => inputTilesFrom in rule.inputs ) { // input rule check
									if ( StringTools.endsWith( inputLayerName, tileLayerTo.name ) ) {

										var isNot = false; // inputnot_
										if ( StringTools.startsWith( inputLayerName, "%not%" ) ) {
											isNot = true;
											inputLayerName = StringTools.replace( inputLayerName, "%not%", "" );
										}

										var ruleMatches = ruleMatchesOnLayer( inputTilesFrom, extractedLayerTo, isNot, layerTile0x, layerTile0y );

										if ( ( ( isNot && ruleMatches ) || !( isNot || ruleMatches ) )
											|| ( ruleProps.noOverlappingRules
												&& isOverlapping( region, rule.outputs, layerTile0x, layerTile0y ) ) ) {
											ruleMatched = false;
										} else
											ruleMatchedOnce = true;
									}
								}

								if ( ruleMatched && ruleMatchedOnce ) applyRuleToLayer( region, rule.outputs, layerTile0x, layerTile0y, ruleProps );
							}
						}
					default:
				}
				if ( ruleProps.noOverlappingRules ) appliedTiles = [];
			}
		}

		// ordering layers in the way that is present in rule map
		for ( ruleMap in ruleMaps ) {
			map.layers.sort( ( layer1 : TmxLayer, layer2 : TmxLayer ) -> {
				var layer1indexInRule = getLayerIndexByName( 'output_${Type.enumParameters( layer1 )[0].name}', ruleMap );
				var layer2indexInRule = getLayerIndexByName( 'output_${Type.enumParameters( layer2 )[0].name}', ruleMap );

				return switch [layer1indexInRule, layer2indexInRule] {
					case [0, _] | [_, 0]: 0;
					case [x1, x2] if ( x1 < x2 ): -1;
					default: 1;
				}
			} );
		}
		return map;
	}

	function extractFromLayer( layer : TmxLayer, ruleMap : TmxMap ) : TmxExtracted {
		switch layer {
			case LObjectGroup( group ):
				return ObjectLayer( group.objects );
			case LTileLayer( layer ):
				return TileLayer( extractTiles( layer.data.tiles, ruleMap, layer.width ) );
			case LGroup( group ):
				trace( group.name );
				throw "wrong autotile markup";

			default:
				trace( layer );
				throw "wrong autotile markup";
		}
	}

	/** for auto-tiling needs, does not provide ortho coodinates **/
	public function extractTiles( tiles : Array<TmxTile>, map : TmxMap, width : Int ) : ExtractedLayer {
		var output : ExtractedLayer = [];
		var xArray : Array<Null<TmxTile>> = [];
		var ix : Int = 0;
		for ( i => tile in tiles ) {
			if ( tile.gid != 0 ) {
				xArray.push( tile );
			} else
				xArray.push( null );
			i++;
			if ( ++ix == width ) {
				ix = 0;
				output.push( xArray );
				xArray = [];
			}
		}
		return output;
	}

	/** raw rule layers are put in here **/
	function compileRules( regions_input : ExtractedLayer, regions_output : ExtractedLayer, inputs : Map<String, TmxExtracted>,
		outputs : Map<String, TmxExtracted>, ruleMap : TmxMap ) {
		var passedTiles : Array<String> = [];
		function checkTile( i : Int, j : Int, array : ExtractedLayer ) : CoordinatedTile {
			return try {
				var tile = { tile : array[i][j], x : j, y : i };
				if ( !passedTiles.contains( Serializer.run( tile ) ) ) tile else { tile : null, x : j, y : i };
			} catch( e : Dynamic ) {
				{ tile : null, x : j, y : i };
			}
		}
		function getNearTiles( i : Int, j : Int, array : ExtractedLayer ) : CoordinatedIsland {
			return [
				checkTile( i - 1, j, array ),
				checkTile( i, j + 1, array ),
				checkTile( i + 1, j, array ),
				checkTile( i, j - 1, array ),
			];
		}
		function areTilesPresentAround( i : Int, j : Int, array : ExtractedLayer ) : Bool {
			var nearTiles = getNearTiles( i, j, array );
			for ( tile in nearTiles ) if ( tile.tile != null ) return true;
			return false;
		}
		function prowlIslandFromCoords( i : Int, j : Int, layer : ExtractedLayer ) : CoordinatedIsland {
			var nextRuleset : CoordinatedIsland = [];
			var forks : Array<String> = [];
			passedTiles.push( Serializer.run( { tile : layer[i][j], x : j, y : i } ) );
			nextRuleset.push( { tile : layer[i][j], x : j, y : i } );
			var islandI = i;
			var islandJ = j;
			// Singular island
			while( areTilesPresentAround( islandI, islandJ, layer ) ) {
				var nearTiles = getNearTiles( islandI, islandJ, layer );
				for ( i in nearTiles ) if ( i.tile != null && !forks.contains( Serializer.run( i ) ) ) {
					forks.push( Serializer.run( i ) );
				}
				for ( tile in nearTiles ) {
					if ( tile.tile != null ) {
						islandI = tile.y;
						islandJ = tile.x;
						if ( !passedTiles.contains( Serializer.run( { tile : layer[islandI][islandJ], x : islandJ, y : islandI } ) ) ) {
							passedTiles.push( Serializer.run( { tile : layer[islandI][islandJ], x : islandJ, y : islandI } ) );
							nextRuleset.push( { tile : layer[islandI][islandJ], x : islandJ, y : islandI } );
						}
						nearTiles.remove( tile );
						forks.remove( Serializer.run( tile ) );
						break;
					}
				}
				while( !areTilesPresentAround( islandI, islandJ, layer ) && forks.length > 0 ) {
					var fork : CoordinatedTile = Unserializer.run( forks.pop() );
					islandI = fork.y;
					islandJ = fork.x;
					if ( !passedTiles.contains( Serializer.run( { tile : layer[islandI][islandJ], x : islandJ, y : islandI } ) ) ) {
						passedTiles.push( Serializer.run( { tile : layer[islandI][islandJ], x : islandJ, y : islandI } ) );
						nextRuleset.push( { tile : layer[islandI][islandJ], x : islandJ, y : islandI } );
					}
				}
			}
			return nextRuleset;
		}
		function extractRulesFromLayer( layer : ExtractedLayer ) : Array<CoordinatedIsland> {
			var rulesets : Array<Array<CoordinatedTile>> = [];
			/** island detecting algorithm **/
			for ( i => island in layer ) { // y
				for ( j => tile in island ) { // x
					if ( tile != null ) if ( !passedTiles.contains( Serializer.run( { tile : tile, x : j, y : i } ) ) ) {
						var nextRuleset = prowlIslandFromCoords( i, j, layer );
						rulesets.push( nextRuleset );
						nextRuleset = [];
					}
				}
			}
			passedTiles = [];
			return rulesets;
		}
		function areIslandsTouching( island1 : CoordinatedIsland, island2 : CoordinatedIsland ) : Bool {
			for ( i in island1 ) for ( j in island2 ) {
				if ( ( i.x == j.x && i.y == j.y ) ) return true;
			}
			return false;
		}

		/** Used to convert input/output layers to coord **/
		function coordLayer( island : ExtractedLayer ) : CoordinatedIsland {
			var result : CoordinatedIsland = [];
			for ( i in 0...island.length ) { // y
				for ( j in 0...island[i].length ) { // x
					if ( island[i][j] != null ) result.push( { tile : island[i][j], x : j, y : i } );
				}
			}
			return result;
		}

		function generateRules( regions_input : Array<CoordinatedIsland>, regions_output : Array<CoordinatedIsland>, inputs : Map<String, TmxCoordinated>,
			outputs : Map<String, TmxCoordinated> ) {

			var localRules : Rules = [];

			function createRuleIfNotExistsAndAdd( generatable : TmxGeneratable, name : String, to : Map<String, Array<TmxGeneratable>> ) {
				var outputRuleByName = to[name];

				if ( outputRuleByName == null ) {
					to[name] = [generatable];
				} else if ( !outputRuleByName.contains( generatable ) ) {
					outputRuleByName.push( generatable );
				}
			}
			// TODO

			function fillLayerWith( object : TmxCoordinated, regionTile : CoordinatedTile, whereTo : Map<String, Array<TmxGeneratable>>, layerName : String ) {
				// random check
				var randomMatched = false;

				/** regex to match automapping random rules **/
				var eregRandom = ~/(?:output|input)([0-9]+)_([a-z]+)$/gi;
				if ( eregRandom.match( layerName ) ) {
					randomMatched = true;
					layerName = StringTools.replace( layerName, eregRandom.matched( 1 ), "" );
					layerName += "%random%" + eregRandom.matched( 1 );
				}

				var notIsMatched = false;
				if ( eregAutoMapInputNotLayer.match( layerName ) ) {
					notIsMatched = true;
					layerName = "%not%" + StringTools.replace( layerName, "not", "" );
				}

				switch object {
					case CoordinatedTileLayer( layer ):
						var isTileSet = false;
						for ( tile in layer ) {
							if ( tile.x == regionTile.x && tile.y == regionTile.y ) {
								isTileSet = true;
								createRuleIfNotExistsAndAdd( randomMatched ? Random( TileGeneratable( tile ) ) : TileGeneratable( tile ), layerName, whereTo );
							}
						}
						if ( !isTileSet ) {
							createRuleIfNotExistsAndAdd( TileGeneratable( { tile : cast( 0, Null<TmxTile> ), x : regionTile.x, y : regionTile.y } ), layerName,
								whereTo );
						}
					case CoordinatedObjectLayer( layer ):

						for ( object in layer ) {
							if ( M.inRange( object.x + 1, ruleMap.tileHeight * regionTile.x, ruleMap.tileHeight * ( regionTile.x + 1 ) )
								&& M.inRange( object.y + 1, ruleMap.tileHeight * regionTile.y, ruleMap.tileHeight * ( regionTile.y + 1 ) ) ) {
								createRuleIfNotExistsAndAdd( randomMatched ? Random( ObjectGeneratable( object ) ) : ObjectGeneratable( object ), layerName, whereTo );
							}
						}
				}
			}

			function isLayerNull( layer : Array<TmxGeneratable> ) : Bool {
				for ( i in layer ) {
					switch( i ) {
						case TileGeneratable( tile ):
							if ( tile != null && tile.tile.gid != 0 ) return false;
						case ObjectGeneratable( object ):
							if ( object != null ) return false;
						case Random( tmxGen ):
							switch tmxGen {
								case TileGeneratable( tile ):
									if ( tile != null && tile.tile.gid != 0 ) return false;
								case ObjectGeneratable( object ):
									if ( object != null ) return false;
								default:
							}
					}
				}
				return true;
			}

			for ( inputRegion in regions_input ) for ( outputRegion in regions_output ) {
				if ( areIslandsTouching( inputRegion, outputRegion )
					&& localRules.get( { regions_input : inputRegion, regions_output : outputRegion } ) == null ) localRules.set( {
						regions_input : inputRegion,
						regions_output : outputRegion
					}, { inputs : [], outputs : [], mapProps : ruleMap.properties } );
			}

			for ( region => put in localRules ) for ( inputName => input in inputs ) for ( regionTile in region.regions_input ) {
				fillLayerWith( input, regionTile, put.inputs, inputName );
			}

			for ( region => put in localRules ) for ( outputName => output in outputs ) for ( regionTile in region.regions_output ) {
				fillLayerWith( output, regionTile, put.outputs, outputName );
			}

			// purge empty rules
			{
				for ( region => put in localRules ) for ( outputName => output in put.outputs ) if ( isLayerNull( output ) ) put.outputs.remove( outputName );

				for ( region => put in localRules ) for ( inputName => input in put.inputs ) if ( isLayerNull( input ) ) put.inputs.remove( inputName );
			}

			for ( localRegions => localPuts in localRules ) rules[localRegions] = localPuts;
		}
		var regions_input_extracted = extractRulesFromLayer( regions_input );
		var regions_output_extracted = extractRulesFromLayer( regions_output );

		function fillMap( map : Map<String, TmxCoordinated>, from : Map<String, TmxExtracted> ) {
			for ( name => layer in from ) {
				map.set( name, switch layer {
					case TileLayer( layer ):
						CoordinatedTileLayer( coordLayer( layer ) );
					case ObjectLayer( layer ):
						CoordinatedObjectLayer( layer );
				} );
			}
		}

		var inputs_extracted : Map<String, TmxCoordinated> = [];
		fillMap( inputs_extracted, inputs );
		var outputs_extracted : Map<String, TmxCoordinated> = [];
		fillMap( outputs_extracted, outputs );

		generateRules( regions_input_extracted, regions_output_extracted, inputs_extracted, outputs_extracted );
	}
}
