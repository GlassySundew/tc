package mapgen;

import h3d.pass.Default;
import haxe.Unserializer;
import haxe.Serializer;
import format.tmx.Data;

typedef ExtractedLayer = Array<Array<Null<TmxTile>>>;

typedef CoordinatedTile = {tile : Null<TmxTile>, x : Int, y : Int};

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
}

class AutoMap {
	public var rules : Map<{regions_input : CoordinatedIsland, regions_output : CoordinatedIsland},
		{inputs : Array<Map<String, Array<TmxGeneratable>>>, outputs : Array<Map<String, Array<TmxGeneratable>>>}> = [];

	var layersByName : Map<String, TmxLayer>;
	/** rulemap **/
	var map : TmxMap;
	/** Generates autotile rules from rules.tmx **/
	public function new( map : TmxMap ) {
		this.map = map;
		layersByName = map.getLayersByName();

		var regions_input = extractFromLayer(layersByName.get("regions_input"));
		var regions_output = extractFromLayer(layersByName.get("regions_output"));

		var inputs : Map<String, TmxExtracted> = [];
		var outputs : Map<String, TmxExtracted> = [];

		for ( name => layer in layersByName ) {
			if ( StringTools.startsWith(name, "input_") ) inputs.set(name, extractFromLayer(layer));
			if ( StringTools.startsWith(name, "output_") ) outputs.set(name, extractFromLayer(layer));
		}

		compileRules(cast(Type.enumParameters(regions_input)[0]), cast(Type.enumParameters(regions_output)[0]), inputs, outputs);
	}

	function debugRules() {
		for ( key => value in rules ) {
			trace(key);
			for ( index => value in value.inputs ) {
				trace(index, value);
			}
			for ( index => value in value.outputs ) {
				trace(index);
				for ( key => value in value ) {
					trace(key);
					for ( index => value in value ) {
						if ( Type.enumParameters(value)[0] != null ) {
							trace(index, value, Type.enumParameters(value)[0].id, Type.enumParameters(value)[0].x, Type.enumParameters(value)[0].y);
						} else
							trace(index, value);
					}
				}
			}
			trace('=========================================');
		}
	}

	public function applyRulesToMap( map : TmxMap ) {

		function getLayerIndexByName( name : String ) : Int {
			for ( index => i in this.map.layers ) switch i {
				case LTileLayer(layer):
					if ( layer.name == name ) return index;
				case LObjectGroup(group):
					if ( group.name == name ) return index;
				default:
					throw "unsupported";
			}
			return 0;
		}

		function purgeOutputLayers() {
			for ( i in map.layers ) {
				switch i {
					case LTileLayer(layer):
						if ( getLayerIndexByName('output_${layer.name}') != 0 ) map.layers.remove(i);
					case LObjectGroup(group):
						if ( getLayerIndexByName('output_${group.name}') != 0 ) map.layers.remove(i);
					default:
				}
			}
		}

		function ruleMatchesOnLayer( rule : Array<TmxGeneratable>, layer : TmxExtracted, layerTile0x : Int, layerTile0y : Int ) : Bool {
			switch layer {
				case TileLayer(layer):
					var rule0x = Type.enumParameters(rule[0])[0].x;
					var rule0y = Type.enumParameters(rule[0])[0].y;

					for ( ruleTile in rule ) {
						switch ruleTile {
							case TileGeneratable(tile):
								try {
									var layerTile = layer[tile.y - rule0y + layerTile0y][tile.x - rule0x + layerTile0x];
									if ( tile.tile.gid != layerTile.gid || layerTile.gid == 0 ) return false;
								} catch( e:Dynamic ) {
									return false;
								}
							default:
						}
					}
				default:
			}
			return true;
		}

		function applyRuleToLayer( rule : {regions_input : CoordinatedIsland, regions_output : CoordinatedIsland},
				outputs : Array<Map<String, Array<TmxGeneratable>>>, layer : TmxTileLayer, layerTile0x : Int, layerTile0y : Int ) {

			function createLayerIfNotExistsByName( name : String, type : TmxGeneratable ) {
				var layerByName = map.layers.filter(layer -> switch layer {
					case LTileLayer(layer):
						layer.name == name;
					case LObjectGroup(group):
						group.name == name;
					default: false;
				})[0];

				function emptyTiles() return [for ( i in 0...(map.height * map.width) ) new TmxTile(0)];

				if ( layerByName == null ) {
					layerByName = switch type {
						case TileGeneratable(tile):
							LTileLayer(new TmxTileLayer({
								encoding : null,
								compression : null,
								tiles : emptyTiles(),
								chunks : null,
								data : null
							}, 0, name, 0, 0, 0, 0, map.width, map.height, 1, true, 0xFFFFFF,
								new TmxProperties()));
						case ObjectGeneratable(object):
							LObjectGroup(new TmxObjectGroup(TmxObjectGroupDrawOrder.Topdown, [], 0xffffff, 0, name, 0, 0, 0, 0, map.height, map.width, 1,
								true, 0xffffff, new TmxProperties()));
					};

					map.layers.push(layerByName);
				}
				return layerByName;
			}

			function isLayerNull( layer : Array<TmxGeneratable> ) : Bool {
				var result = true;
				for ( i in layer ) {
					switch( i ) {
						case TileGeneratable(tile):
							if ( tile != null || tile.tile.gid == 0 ) result = false;
						case ObjectGeneratable(object):
							if ( object != null ) result = false;
					}
				}
				return result;
			}

			for ( output in outputs.reversedKeyValues() ) {
				for ( layerName => tiles in output.value ) {
					if ( tiles.length > 0 && !isLayerNull(tiles) ) {
						var currentLayer = createLayerIfNotExistsByName(StringTools.replace(layerName, "output_", ""), tiles[0]);

						switch currentLayer {
							case LTileLayer(layer):
								// первый тайл в output хранилище
								var params = Type.enumParameters(tiles[0])[0];
								var rule0x = params.x;
								var rule0y = params.y;
								for ( i in tiles ) {
									switch i {
										case TileGeneratable(tile):
											if ( tile.tile.gid != 0 ) layer.data.tiles[tile.x
												- rule0x
												+ layerTile0x
												+ rule.regions_output[0].x - rule.regions_input[0].x + (tile.y - rule0y + layerTile0y
													+ rule.regions_output[0].y - rule.regions_input[0].y) * map.width] = tile.tile;
										default:
											throw "Guaranteed to be tile layer but its not";
									}
								}
							case LObjectGroup(group):

								for ( i in tiles ) {
									switch i {
										case ObjectGeneratable(object):
											if ( object != null ) {
												// creating new TmxObject
												group.objects.push({
													id : object.id,
													name : object.name,
													type : object.type,
													x : object.x % map.tileHeight + (M.floor(object.x / map.tileHeight) - rule.regions_input[0].x
														+ layerTile0x) * map.tileHeight,
													y : object.y % map.tileHeight + (M.floor(object.y / map.tileHeight) - rule.regions_input[0].y
														+ layerTile0y) * map.tileHeight,
													width : object.width,
													height : object.height,
													rotation : object.rotation,
													visible : object.visible,
													objectType : object.objectType,
													properties : object.properties,
													flippedHorizontally : object.flippedHorizontally,
													flippedVertically : object.flippedVertically,
													template : object.template,
												});
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
		}

		purgeOutputLayers();

		for ( layer in map.layers ) {
			switch( layer ) {
				case LTileLayer(tileLayer):
					for ( region => rule in rules ) {
						for ( inputs in rule.inputs ) {
							for ( layerName => inputTiles in inputs ) { // rule
								if ( StringTools.endsWith(layerName, tileLayer.name) ) {
									var extractedLayer = extractFromLayer(layer);
									for ( i => tile in tileLayer.data.tiles ) { // appliable layer
										if ( tile.gid != 0 ) {
											var layerTile0x = Std.int(i % map.width);
											var layerTile0y = Std.int(i / map.width);
											if ( ruleMatchesOnLayer(inputTiles, extractedLayer, layerTile0x, layerTile0y) ) {
												applyRuleToLayer(region, rule.outputs, tileLayer, layerTile0x, layerTile0y);
											}
										}
									}
								}
							}
						}
					}
				default:
			}
		}

		// ordering layers in the way that is present in rule map
		map.layers.sort(( layer1 : TmxLayer, layer2 : TmxLayer ) -> {
			var layer1indexInRule = getLayerIndexByName('output_${Type.enumParameters(layer1)[0].name}');
			var layer2indexInRule = getLayerIndexByName('output_${Type.enumParameters(layer2)[0].name}');

			if ( layer1indexInRule == 0 || layer2indexInRule == 0 ) {
				return 0;
			} else if ( layer1indexInRule < layer2indexInRule ) {
				return -1;
			} else
				return 1;
		});

		return map;
	}

	function extractFromLayer( layer : TmxLayer ) : TmxExtracted {
		switch layer {
			case LObjectGroup(group):
				return ObjectLayer(group.objects);
			case LTileLayer(layer):
				return TileLayer(extractTiles(layer.data.tiles, map, layer.width));
			default:
				throw "wrong autotile markup";
		}
	}
	/** for auto-tiling needs, does not provide ortho coodinates **/
	public function extractTiles( tiles : Array<TmxTile>, map : TmxMap, width : Int ) : ExtractedLayer {
		var output : ExtractedLayer = [];
		var xArray : Array<Null<TmxTile>> = [];
		var i : Int = 0;
		var ix : Int = 0;
		var tile : TmxTile;
		for ( i => tile in tiles ) {
			if ( tile.gid != 0 ) {
				xArray.push(tile);
			} else
				xArray.push(null);
			i++;
			if ( ++ix == width ) {
				ix = 0;
				output.push(xArray);
				xArray = [];
			}
		}
		return output;
	}
	/** Whole rule layers are put in here **/
	function compileRules( regions_input : ExtractedLayer, regions_output : ExtractedLayer, inputs : Map<String, TmxExtracted>,
			outputs : Map<String, TmxExtracted> ) {
		var passedTiles : Array<String> = [];
		function checkTile( i : Int, j : Int, array : ExtractedLayer ) : CoordinatedTile {
			return try {
				var tile = {tile : array[i][j], x : j, y : i};
				if ( !passedTiles.contains(Serializer.run(tile)) ) tile else {tile : null, x : j, y : i};
			} catch( e:Dynamic ) {
				{tile : null, x : j, y : i};
			}
		}
		function getNearTiles( i : Int, j : Int, array : ExtractedLayer ) : CoordinatedIsland {
			return [
				checkTile(i - 1, j, array),
				checkTile(i, j + 1, array),
				checkTile(i + 1, j, array),
				checkTile(i, j - 1, array),
			];
		}
		function areTilesPresentAround( i : Int, j : Int, array : ExtractedLayer ) : Bool {
			var nearTiles = getNearTiles(i, j, array);
			for ( tile in nearTiles ) if ( tile.tile != null ) return true;
			return false;
		}
		function prowlIslandFromCoords( i : Int, j : Int, layer : ExtractedLayer ) : CoordinatedIsland {
			var nextRuleset : CoordinatedIsland = [];
			var forks : Array<String> = [];
			passedTiles.push(Serializer.run({tile : layer[i][j], x : j, y : i}));
			nextRuleset.push({tile : layer[i][j], x : j, y : i});
			var islandI = i;
			var islandJ = j;
			// Singular island
			while( areTilesPresentAround(islandI, islandJ, layer) ) {
				var nearTiles = getNearTiles(islandI, islandJ, layer);
				for ( i in nearTiles ) if ( i.tile != null && !forks.contains(Serializer.run(i)) ) {
					forks.push(Serializer.run(i));
				}
				for ( tile in nearTiles ) {
					if ( tile.tile != null ) {
						islandI = tile.y;
						islandJ = tile.x;
						if ( !passedTiles.contains(Serializer.run({tile : layer[islandI][islandJ], x : islandJ, y : islandI})) ) {
							passedTiles.push(Serializer.run({tile : layer[islandI][islandJ], x : islandJ, y : islandI}));
							nextRuleset.push({tile : layer[islandI][islandJ], x : islandJ, y : islandI});
						}
						nearTiles.remove(tile);
						forks.remove(Serializer.run(tile));
						break;
					}
				}
				while( !areTilesPresentAround(islandI, islandJ, layer) && forks.length > 0 ) {
					var fork : CoordinatedTile = Unserializer.run(forks.pop());
					islandI = fork.y;
					islandJ = fork.x;
					if ( !passedTiles.contains(Serializer.run({tile : layer[islandI][islandJ], x : islandJ, y : islandI})) ) {
						passedTiles.push(Serializer.run({tile : layer[islandI][islandJ], x : islandJ, y : islandI}));
						nextRuleset.push({tile : layer[islandI][islandJ], x : islandJ, y : islandI});
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
					if ( tile != null ) if ( !passedTiles.contains(Serializer.run({tile : tile, x : j, y : i})) ) {
						var nextRuleset = prowlIslandFromCoords(i, j, layer);
						rulesets.push(nextRuleset);
						nextRuleset = [];
					}
				}
			}
			passedTiles = [];
			return rulesets;
		}
		function areIslandsTouching( island1 : CoordinatedIsland, island2 : CoordinatedIsland ) : Bool {
			for ( i in island1 ) for ( j in island2 ) {
				if ( (i.x == j.x && i.y == j.y) ) return true;
			}
			return false;
		}
		/** Used to convert input/output layers to coord **/
		function coordLayer( island : ExtractedLayer ) : CoordinatedIsland {
			var result : CoordinatedIsland = [];
			for ( i in 0...island.length ) { // y
				for ( j in 0...island[i].length ) { // x
					if ( island[i][j] != null ) result.push({tile : island[i][j], x : j, y : i});
				}
			}
			return result;
		}
		function generateRules( regions_input : Array<CoordinatedIsland>, regions_output : Array<CoordinatedIsland>, inputs : Map<String, TmxCoordinated>,
				outputs : Map<String, TmxCoordinated> ) {
			function getRuleByName( name : String, rule : Array<Map<String, Array<TmxGeneratable>>> ) : Array<TmxGeneratable> {
				for ( i in rule ) {
					var result = i.get(name);
					if ( result != null ) return result;
				}
				return null;
			}
			var objsCount : Array<Int> = [];
			function createLayerIfNotExistsAndAdd( generatable : TmxGeneratable, name : String, to : Array<Map<String, Array<TmxGeneratable>>>,
					from : Array<Map<String, Array<TmxGeneratable>>> ) {
				var outputRuleByName = getRuleByName(name, from);

				if ( outputRuleByName == null ) {
					to.push([name => [generatable]]);
				} else if ( !outputRuleByName.contains(generatable) ) {
					outputRuleByName.push(generatable);
				}
			}

			function fillLayerWith( object : TmxCoordinated, regionTile : CoordinatedTile, whereTo : Array<Map<String, Array<TmxGeneratable>>>,
					from : Array<Map<String, Array<TmxGeneratable>>>, layerName : String ) {
				switch object {
					case CoordinatedTileLayer(layer):
						var isTileSet = false;
						for ( tile in layer ) {
							if ( tile.x == regionTile.x && tile.y == regionTile.y ) {
								isTileSet = true;
								createLayerIfNotExistsAndAdd(TileGeneratable(tile), layerName, whereTo, from);
							}
						}
						if ( !isTileSet ) {
							createLayerIfNotExistsAndAdd(TileGeneratable({tile : cast(0, Null<TmxTile>), x : regionTile.x, y : regionTile.y}), layerName,
								whereTo, from);
						}
					case CoordinatedObjectLayer(layer):
						var isObjSet = false;
						for ( object in layer ) {
							if ( M.inRange(object.x + 1, map.tileHeight * regionTile.x, map.tileHeight * (regionTile.x + 1))
								&& M.inRange(object.y + 1, map.tileHeight * regionTile.y, map.tileHeight * (regionTile.y + 1)) ) {
								isObjSet = true;
								objsCount.push(object.id);
								createLayerIfNotExistsAndAdd(ObjectGeneratable(object), layerName, whereTo, from);
							}
						}
						if ( !isObjSet ) {
							createLayerIfNotExistsAndAdd(ObjectGeneratable(null), layerName, whereTo, from);
						}
				}
			}

			for ( inputRegion in regions_input ) for ( outputRegion in regions_output ) {
				if ( areIslandsTouching(inputRegion, outputRegion)
					&& rules.get({regions_input : inputRegion, regions_output : outputRegion}) == null ) rules.set({
						regions_input : inputRegion,
						regions_output : outputRegion
					}, {inputs : [], outputs : []});
			}

			for ( region => put in rules ) for ( outputName => output in outputs ) for ( regionTile in region.regions_output ) {
				fillLayerWith(output, regionTile, rules.get(region).outputs, put.outputs, outputName);
			}

			for ( region => put in rules ) for ( inputName => input in inputs ) for ( regionTile in region.regions_input ) {
				fillLayerWith(input, regionTile, rules.get(region).inputs, put.inputs, inputName);
			}
		}
		var regions_input_extracted = extractRulesFromLayer(regions_input);
		var regions_output_extracted = extractRulesFromLayer(regions_output);

		function fillMap( map : Map<String, TmxCoordinated>, from : Map<String, TmxExtracted> ) {
			for ( name => layer in from ) {
				map.set(name, switch layer {
					case TileLayer(layer):
						CoordinatedTileLayer(coordLayer(layer));
					case ObjectLayer(layer):
						CoordinatedObjectLayer(layer);
				});
			}
		}

		var inputs_extracted : Map<String, TmxCoordinated> = [];
		fillMap(inputs_extracted, inputs);
		var outputs_extracted : Map<String, TmxCoordinated> = [];
		fillMap(outputs_extracted, outputs);

		generateRules(regions_input_extracted, regions_output_extracted, inputs_extracted, outputs_extracted);
	}
}
