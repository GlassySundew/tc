package mapgen;

import format.tmx.Data;
import haxe.Serializer;
import haxe.Unserializer;

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
/** небольшое расхождение с оригинальным алгоритмом tiled: если указано случайное распределение тайлов через output{номер}_layerName, и в карте присутствует карта с layerName но без номера, в случайном распределении она учавствовать не будет

**/
class AutoMap {
	public var rules : Map<{regions_input : CoordinatedIsland, regions_output : CoordinatedIsland },
		{ inputs : Array<Map<String, Array<TmxGeneratable>>>, outputs : Array<Map<String, Array<TmxGeneratable>>> }> = [];

	var layersByName : Map<String, TmxLayer>;
	/** rulemap **/
	var ruleMaps : Array<TmxMap>;
	/** Generates autotile rules from rules.tmx **/
	public function new( rulePath : String ) {
		var ruleFiles : String = sys.io.File.getContent(rulePath);

		ruleMaps = [];

		for ( i in ruleFiles.split('\n') ) {
			if ( i != "" && !StringTools.startsWith(i, "//") && !StringTools.startsWith(i, "#") ) {
				trace(i, i == "");
				ruleMaps.push(resolveMap(StringTools.replace(i, "./", "")));
			}
		}

		for ( ruleMap in ruleMaps ) {
			layersByName = ruleMap.mapLayersByName();

			var regions_input = extractFromLayer(layersByName.get("regions_input"), ruleMap);
			var regions_output = extractFromLayer(layersByName.get("regions_output"), ruleMap);

			var inputs : Map<String, TmxExtracted> = [];
			var outputs : Map<String, TmxExtracted> = [];

			for ( name => layer in layersByName ) {
				if ( StringTools.startsWith(name, "input") ) inputs.set(name, extractFromLayer(layer, ruleMap));
				if ( StringTools.startsWith(name, "output") ) outputs.set(name, extractFromLayer(layer, ruleMap));
			}

			compileRules(cast(Type.enumParameters(regions_input)[0]), cast(Type.enumParameters(regions_output)[0]), inputs, outputs, ruleMap);

			debugRules();
		}
	}

	function debugRules() {
		for ( regions => puts in rules ) {
			trace(regions);
			for ( inputIndex => input in puts.inputs ) {
				trace(inputIndex, input);
			}
			for ( outputIndex => outputs in puts.outputs ) {
				trace(outputIndex, outputs);
				
			}
			trace('=========================================');
		}
	}

	public function applyRulesToMap( map : TmxMap ) {

		function getLayerIndexByName( name : String, ruleMap : TmxMap ) : Int {
			for ( index => i in ruleMap.layers ) switch i {
				case LTileLayer(layer):
					if ( layer.name == name ) return index;
				case LObjectGroup(group):
					if ( group.name == name ) return index;
				default:
					throw "unsupported";
			}
			return 0;
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

		for ( ruleMap in ruleMaps ) {

			var deleteTiles : Bool = ruleMap.properties.exists("DeleteTiles") ? ruleMap.properties.getBool("DeleteTiles") : false;
			var noOverlappingRules : Bool = ruleMap.properties.exists("NoOverlappingRules") ? ruleMap.properties.getBool("NoOverlappingRules") : false;
			var appliedTiles : Array<{x : Int, y : Int }> = [];

			function applyRuleToLayer( rule : { regions_input : CoordinatedIsland, regions_output : CoordinatedIsland },
					outputs : Array<Map<String, Array<TmxGeneratable>>>, layer : TmxTileLayer, layerTile0x : Int, layerTile0y : Int ) {

				function createLayerIfNotExistsByName( name : String, type : TmxGeneratable ) {
					var layerByName = map.getLayersByName(name)[0];

					function newTileLayer() return LTileLayer(new TmxTileLayer({
						encoding : null,
						compression : null,
						tiles : emptyTiles(map),
						chunks : null,
						data : null
					}, 0, name, 0, 0, 0, 0, map.width, map.height, 1, true, 0xFFFFFF,
						new TmxProperties()));

					function newObjectLayer() return LObjectGroup(new TmxObjectGroup(TmxObjectGroupDrawOrder.Topdown, [], 0xffffff, 0, name, 0, 0, 0, 0,
						map.height, map.width, 1, true, 0xffffff, new TmxProperties()));

					if ( layerByName == null ) {
						layerByName = switch type {
							case TileGeneratable(tile): newTileLayer();
							case ObjectGeneratable(object): newObjectLayer();
							case Random(tmxGen):
								switch tmxGen {
									case TileGeneratable(tile): newTileLayer();
									case ObjectGeneratable(object): newObjectLayer();
									default: throw "bad logic";
								}
						};

						map.layers.push(layerByName);
					}
					return layerByName;
				}

				function isLayerNull( layer : Array<TmxGeneratable> ) : Bool {
					for ( i in layer ) {
						switch( i ) {
							case TileGeneratable(tile):
								if ( tile != null || tile.tile.gid != 0 ) return false;
							case ObjectGeneratable(object):
								if ( object != null ) return false;
							case Random(tmxGen):
								switch tmxGen {
									case TileGeneratable(tile):
										if ( tile != null || tile.tile.gid != 0 ) return false;
									case ObjectGeneratable(object):
										if ( object != null ) return false;
									default:
								}
						}
					}
					return true;
				}

				function extractRandom( outputTiles : Array<TmxGeneratable> ) {
					var result = [];
					for ( i in outputTiles ) {
						switch i {
							case Random(tmxGen):
								result.push(tmxGen);
							default:
								throw "bad logic";
						}
					}
					return result;
				}

				for ( output in outputs.reversedKeyValues() ) {
					for ( layerName => outputGeneratable in output.value ) {
						if ( outputGeneratable.length > 0 ) {

							// random distribution, here we make a choice
							var randomCheck = layerName.split("%random%");
							if ( randomCheck[1] != null && randomCheck[1] != "" ) {
								var pool : Map<String, Array<TmxGeneratable>> = [];
								var rawPool = [];
								for ( output in outputs ) {
									for ( layerName => outputGeneratable in output ) {
										if ( layerName.split("%random%")[1] != "" )
											pool[layerName] = pool[layerName] == null ? extractRandom(outputGeneratable) : pool[layerName].concat((extractRandom(outputGeneratable)));
									}
								}
								for ( key => value in pool ) rawPool.push(value);

								outputGeneratable = std.Random.fromArray(rawPool);
								layerName = randomCheck[0];
							}

							var currentLayer = createLayerIfNotExistsByName(StringTools.replace(layerName, "output_", ""), outputGeneratable[0]);

							switch currentLayer {
								case LTileLayer(layer):
									// первый тайл в output хранилище
									var params = Type.enumParameters(outputGeneratable[0])[0];
									var rule0x = params.x;
									var rule0y = params.y;
									for ( i in outputGeneratable ) {
										switch i {
											case TileGeneratable(tile):

												if ( tile.tile.gid != 0 ) {
													var x = tile.x - rule0x + layerTile0x + rule.regions_output[0].x - rule.regions_input[0].x;
													var y = tile.y - rule0y + layerTile0y + rule.regions_output[0].y - rule.regions_input[0].y;

													if ( layer.data.tiles[x + y * map.width].gid != 0 || deleteTiles ) {
														if ( noOverlappingRules ) appliedTiles.push({ x : x, y : y });
														layer.data.tiles[x + y * map.width] = tile.tile;
													}
												}
											default:
												throw "Guaranteed to be tile layer but its not";
										}
									}
								case LObjectGroup(group):

									for ( i in outputGeneratable ) {
										switch i {
											case ObjectGeneratable(object):
												if ( object != null ) {
													// creating new TmxObject
													group.objects.push({
														id : object.id,
														name : object.name,
														type : object.type,
														x : object.x % map.tileHeight + (M.floor(object.x / map.tileHeight)
															- rule.regions_input[0].x + layerTile0x) * map.tileHeight,
														y : object.y % map.tileHeight + (M.floor(object.y / map.tileHeight)
															- rule.regions_input[0].y + layerTile0y) * map.tileHeight,
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

			function isOverlapping( rule : { regions_input : CoordinatedIsland, regions_output : CoordinatedIsland },
					outputs : Array<Map<String, Array<TmxGeneratable>>>, layerTile0x : Int, layerTile0y : Int ) : Bool {
				for ( output in outputs ) {
					for ( outputName => outputTiles in output ) {
						for ( outputTileI => outputTile in outputTiles ) {
							var params = Type.enumParameters(outputTiles[0])[0];
							var rule0x = params.x;
							var rule0y = params.y;
							switch outputTile {
								case TileGeneratable(tile):
									if ( appliedTiles.contains({
										x : (tile.x - rule0x + layerTile0x + rule.regions_output[0].x - rule.regions_input[0].x),
										y : (tile.y - rule0y + layerTile0y + rule.regions_output[0].y - rule.regions_input[0].y)
									}) ) return true;
								default:
							}
						}
					}
				}
				return false;
			}

			for ( layerTo in map.layers ) {
				switch( layerTo ) {
					case LTileLayer(tileLayerTo):
						for ( region => rule in rules ) {
							for ( inputs in rule.inputs ) {
								for ( layerName => inputTilesFrom in inputs ) { // rule
									if ( StringTools.endsWith(layerName, tileLayerTo.name) ) {
										var extractedLayerTo = extractFromLayer(layerTo, ruleMap);
										for ( iTo => tileTo in tileLayerTo.data.tiles ) { // appliable layer
											if ( tileTo.gid != 0 ) {
												var layerTile0x = Std.int(iTo % map.width);
												var layerTile0y = Std.int(iTo / map.width);
												if ( ruleMatchesOnLayer(inputTilesFrom, extractedLayerTo, layerTile0x, layerTile0y)
													&& !(noOverlappingRules
														&& !isOverlapping(region, rule.outputs, layerTile0x, layerTile0y)) ) {
													applyRuleToLayer(region, rule.outputs, tileLayerTo, layerTile0x, layerTile0y);
												}
											}
										}
									}
								}
								if ( noOverlappingRules ) appliedTiles = [];
							}
						}
					default:
				}
			}

			// ordering layers in the way that is present in rule map
			map.layers.sort(( layer1 : TmxLayer, layer2 : TmxLayer ) -> {
				var layer1indexInRule = getLayerIndexByName('output_${Type.enumParameters(layer1)[0].name}', ruleMap);
				var layer2indexInRule = getLayerIndexByName('output_${Type.enumParameters(layer2)[0].name}', ruleMap);

				if ( layer1indexInRule == 0 || layer2indexInRule == 0 ) {
					return 0;
				} else if ( layer1indexInRule < layer2indexInRule ) {
					return -1;
				} else
					return 1;
			});
		}
		return map;
	}

	function extractFromLayer( layer : TmxLayer, ruleMap : TmxMap ) : TmxExtracted {
		switch layer {
			case LObjectGroup(group):
				return ObjectLayer(group.objects);
			case LTileLayer(layer):
				return TileLayer(extractTiles(layer.data.tiles, ruleMap, layer.width));
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
	/** raw rule layers are put in here **/
	function compileRules( regions_input : ExtractedLayer, regions_output : ExtractedLayer, inputs : Map<String, TmxExtracted>,
			outputs : Map<String, TmxExtracted>, ruleMap : TmxMap ) {
		var passedTiles : Array<String> = [];
		function checkTile( i : Int, j : Int, array : ExtractedLayer ) : CoordinatedTile {
			return try {
				var tile = { tile : array[i][j], x : j, y : i };
				if ( !passedTiles.contains(Serializer.run(tile)) ) tile else { tile : null, x : j, y : i };
			} catch( e:Dynamic ) {
				{ tile : null, x : j, y : i };
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
			passedTiles.push(Serializer.run({ tile : layer[i][j], x : j, y : i }));
			nextRuleset.push({ tile : layer[i][j], x : j, y : i });
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
						if ( !passedTiles.contains(Serializer.run({ tile : layer[islandI][islandJ], x : islandJ, y : islandI })) ) {
							passedTiles.push(Serializer.run({ tile : layer[islandI][islandJ], x : islandJ, y : islandI }));
							nextRuleset.push({ tile : layer[islandI][islandJ], x : islandJ, y : islandI });
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
					if ( !passedTiles.contains(Serializer.run({ tile : layer[islandI][islandJ], x : islandJ, y : islandI })) ) {
						passedTiles.push(Serializer.run({ tile : layer[islandI][islandJ], x : islandJ, y : islandI }));
						nextRuleset.push({ tile : layer[islandI][islandJ], x : islandJ, y : islandI });
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
					if ( tile != null ) if ( !passedTiles.contains(Serializer.run({ tile : tile, x : j, y : i })) ) {
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
					if ( island[i][j] != null ) result.push({ tile : island[i][j], x : j, y : i });
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
			function createRuleIfNotExistsAndAdd( generatable : TmxGeneratable, name : String, to : Array<Map<String, Array<TmxGeneratable>>> ) {
				var outputRuleByName = getRuleByName(name, to);

				if ( outputRuleByName == null ) {
					to.push([name => [generatable]]);
				} else if ( !outputRuleByName.contains(generatable) ) {
					outputRuleByName.push(generatable);
				}
			}
			// TODO
			var randomedLayers = [];

			function fillLayerWith( object : TmxCoordinated, regionTile : CoordinatedTile, whereTo : Array<Map<String, Array<TmxGeneratable>>>,
					layerName : String ) {
				// random check
				var randomMatched = false;
				if ( eregAutoMapLayer.match(layerName) && eregAutoMapLayer.matched(1) != "" ) {
					randomMatched = true;
					layerName = StringTools.replace(layerName, eregAutoMapLayer.matched(1), "");
					randomedLayers.push(layerName);
					layerName += "%random%" + eregAutoMapLayer.matched(1);
				}

				switch object {
					case CoordinatedTileLayer(layer):
						var isTileSet = false;
						for ( tile in layer ) {
							if ( tile.x == regionTile.x && tile.y == regionTile.y ) {
								isTileSet = true;
								createRuleIfNotExistsAndAdd((randomMatched && eregAutoMapLayer.matched(1) != "") ? Random(TileGeneratable(tile)) : TileGeneratable(tile),
									layerName,
									whereTo);
							}
						}
						if ( !isTileSet ) {
							createRuleIfNotExistsAndAdd(TileGeneratable({ tile : cast(0, Null<TmxTile>), x : regionTile.x, y : regionTile.y }), layerName,
								whereTo);
						}
					case CoordinatedObjectLayer(layer):

						for ( object in layer ) {
							if ( M.inRange(object.x + 1, ruleMap.tileHeight * regionTile.x, ruleMap.tileHeight * (regionTile.x + 1))
								&& M.inRange(object.y + 1, ruleMap.tileHeight * regionTile.y, ruleMap.tileHeight * (regionTile.y + 1)) ) {
								createRuleIfNotExistsAndAdd((randomMatched && eregAutoMapLayer.matched(1) != "") ? Random(ObjectGeneratable(object)) : ObjectGeneratable(object),
									layerName, whereTo);
							}
						}
				}
			}

			function isLayerNull( layer : Array<TmxGeneratable> ) : Bool {
				for ( i in layer ) {
					switch( i ) {
						case TileGeneratable(tile):
							if ( tile != null && tile.tile.gid != 0 ) return false;
						case ObjectGeneratable(object):
							if ( object != null ) return false;
						case Random(tmxGen):
							switch tmxGen {
								case TileGeneratable(tile):
									if ( tile != null && tile.tile.gid != 0 ) return false;
								case ObjectGeneratable(object):
									if ( object != null ) return false;
								default:
							}
					}
				}
				return true;
			}

			for ( inputRegion in regions_input ) for ( outputRegion in regions_output ) {
				if ( areIslandsTouching(inputRegion, outputRegion)
					&& rules.get({ regions_input : inputRegion, regions_output : outputRegion }) == null ) rules.set({
						regions_input : inputRegion,
						regions_output : outputRegion
					}, { inputs : [], outputs : [] });
			}

			for ( region => put in rules ) for ( inputName => input in inputs ) for ( regionTile in region.regions_input ) {
				fillLayerWith(input, regionTile, put.inputs, inputName);
			}

			for ( region => put in rules ) for ( outputName => output in outputs ) for ( regionTile in region.regions_output ) {
				fillLayerWith(output, regionTile, put.outputs, outputName);
			}

			for ( region => put in rules ) for ( output in put.outputs ) for ( outputName => i in output ) {
				if ( isLayerNull(i) ) {
					// output.remove(outputName);
				}
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
