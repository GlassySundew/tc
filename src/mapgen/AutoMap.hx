package mapgen;

import haxe.Unserializer;
import haxe.Serializer;
import sys.thread.Tls;
import h3d.shader.GenTexture;
import format.tmx.Data;

typedef ExtractedLayer = Array<Array<Null<TmxTile>>>;

typedef CoordinatedTile = {tile : Null<TmxTile>, x : Int, y : Int};

typedef CoordinatedIsland = Array<CoordinatedTile>;

class AutoMap {
	public var rules : Map<{regions_input : CoordinatedIsland, regions_output : CoordinatedIsland},
		{inputs : Array<Map<String, CoordinatedIsland>>, outputs : Array<Map<String, CoordinatedIsland>>}> = [];

	var layersByName : Map<String, TmxLayer>;
	var map : TmxMap;
	/** Generates autotile rules from rules.tmx **/
	public function new( map : TmxMap ) {
		layersByName = map.getLayersByName();
		this.map = map;

		var regions_input = extractTilesFromLayer(layersByName.get("regions_input"));
		var regions_output = extractTilesFromLayer(layersByName.get("regions_output"));

		var inputs : Map<String, ExtractedLayer> = [];
		var outputs : Map<String, ExtractedLayer> = [];

		for ( name => layer in layersByName ) {
			if ( StringTools.startsWith(name, "input_") ) inputs.set(name, extractTilesFromLayer(layer));
			if ( StringTools.startsWith(name, "output_") ) outputs.set(name, extractTilesFromLayer(layer));
		}

		compileRules(regions_input, regions_output, inputs, outputs);
	}

	function extractTilesFromLayer( layer : TmxLayer ) : ExtractedLayer {
		switch layer {
			case LObjectGroup(group):
				throw "TODO";
			case LTileLayer(layer):
				return extractTiles(layer.data.tiles, map, layer.width);
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

		while( i < tiles.length ) {
			tile = tiles[i];
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
	function compileRules( regions_input : ExtractedLayer, regions_output : ExtractedLayer, inputs : Map<String, ExtractedLayer>,
			outputs : Map<String, ExtractedLayer> ) {
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
			for ( i in 0...layer.length ) { // y
				for ( j in 0...layer[i].length ) { // x

					if ( layer[i][j] != null && !passedTiles.contains(Serializer.run({tile : layer[i][j], x : j, y : i})) ) {
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

		function isTileBelongOnIsland( tile : CoordinatedTile, island : CoordinatedIsland ) {
			for ( i in island ) if ( i.x == tile.x && i.y == tile.y ) return true;
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

		function getRuleByName( name : String, rule : Array<Map<String, CoordinatedIsland>> ) : CoordinatedIsland {
			for ( i in rule ) {
				var result = i.get(name);
				if ( result != null ) return result;
			}
			return null;
		}

		function generateRules( regions_input : Array<CoordinatedIsland>, regions_output : Array<CoordinatedIsland>, inputs : Map<String, CoordinatedIsland>,
				outputs : Map<String, CoordinatedIsland> ) {

			for ( inputRegion in regions_input ) for ( outputRegion in regions_output ) {
				if ( areIslandsTouching(inputRegion, outputRegion)
					&& rules.get({regions_input : inputRegion, regions_output : outputRegion}) == null ) rules.set({
						regions_input : inputRegion,
						regions_output : outputRegion
					}, {inputs : [], outputs : []});
			}

			for ( region => put in rules ) for ( outputName => output in outputs ) for ( outputTile in output ) {
				if ( isTileBelongOnIsland(outputTile, region.regions_output) ) {

					var outputRuleByName = getRuleByName(outputName, put.outputs);
					if ( outputRuleByName == null ) {
						rules.get(region).outputs.push([outputName => [outputTile]]);
					} else {
						outputRuleByName.push(outputTile);
					}
				}
			}

			for ( region => put in rules ) for ( inputName => input in inputs ) for ( inputTile in input ) {
				if ( isTileBelongOnIsland(inputTile, region.regions_input) ) {

					var inputRuleByName = getRuleByName(inputName, put.inputs);
					if ( inputRuleByName == null ) {
						rules.get(region).inputs.push([inputName => [inputTile]]);
					} else {
						inputRuleByName.push(inputTile);
					}
				}
			}
		}

		var regions_input_extracted = extractRulesFromLayer(regions_input);
		var regions_output_extracted = extractRulesFromLayer(regions_output);

		var inputs_extracted : Map<String, CoordinatedIsland> = [];
		for ( name => layer in inputs ) inputs_extracted.set(name, coordLayer(layer));

		var outputs_extracted : Map<String, CoordinatedIsland> = [];
		for ( name => layer in outputs ) outputs_extracted.set(name, coordLayer(layer));

		generateRules(regions_input_extracted, regions_output_extracted, inputs_extracted, outputs_extracted);


	}
}
