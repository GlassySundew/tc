package mapgen;

import haxe.Serializer;
import haxe.Unserializer;
import h3d.Vector;
import format.tmx.Data;

enum SampleType {
	Start;
	/** areas inbetween starting and ending areas with the most content **/
	Midst;
	End;
	Corridor;
}

enum Towards {
	North;
	East;
	South;
	West;
}

typedef Exit = { x : Int, y : Int, towards : Array<Towards> }

typedef GenSample = {
	var type : SampleType;
	var source : TmxGroup;
	var exits : Array<Exit>;
}

class MapGen {
	var sampleMap : TmxMap;
	var autoMapper : AutoMap;
	var groundTile : Int;
	var voidTile : Int;

	var roomList : Array<{x : Int, y : Int, sample : Null<GenSample> }> = [];

	var samples : Array<GenSample> = [];
	/**
		parses map and creates genearting configuration
		@param map config for map generating behaviour
		@param autoTiler is for autotiling generated result
	**/
	public function new( sampleMap : TmxMap, autoMapper : AutoMap ) {
		this.sampleMap = sampleMap;
		this.autoMapper = autoMapper;

		// looking up for void and ground tiles
		for ( i in sampleMap.tilesets ) {}

		groundTile = sampleMap.properties.getInt('ground_tile') + 1;
		voidTile = sampleMap.properties.getInt('void_tile') + 1;

		for ( i in sampleMap.layers ) {
			switch i {
				case LGroup(group):
					if ( group.name == "empty" ) continue;
					var sampleType : SampleType = switch group.name {
						case StringTools.contains(_, 'start') => true: Start;
						case StringTools.contains(_, 'midst') => true: Midst;
						case StringTools.contains(_, 'end') => true: End;
						default: throw("pattern type not supported " + group.name);
					}

					// extracting non-zero samples from groups and grounding them down to zero coords
					// finding the first tile in the group to serve as a beginning
					var lowestTile : Vector = new Vector(sampleMap.width, sampleMap.height);

					for ( i in group.layers ) {
						switch i {
							case LTileLayer(layer):
								for ( tilei => tile in layer.data.tiles ) {
									if ( tile.gid != 0
										&& (tilei % sampleMap.width) < lowestTile.x && M.floor(tilei / sampleMap.width) < lowestTile.y ) {
										// pushing this very tile to storage
										lowestTile.x = tilei % sampleMap.width;
										lowestTile.y = M.floor(tilei / sampleMap.width);
									}
								}
							default:
						}
					}

					// здесь смещаем все остальные слои по наименьшемму найденному тайлу, даже объекты
					for ( i in group.layers ) {
						switch i {
							case LTileLayer(layer):
								for ( tilei => tile in layer.data.tiles ) {
									if ( tile.gid != 0 ) {
										var tileID = Std.int(tilei % sampleMap.width
											- lowestTile.x
											+ (M.floor(tilei / sampleMap.width) - lowestTile.y) * sampleMap.width);
										var tempTile = tile;
										layer.data.tiles[tilei] = layer.data.tiles[tileID];
										layer.data.tiles[tileID] = tempTile;
									}
								}
							case LObjectGroup(group):
								for ( i in group.objects ) {
									i.x -= lowestTile.x * sampleMap.tileHeight;
									i.y -= lowestTile.y * sampleMap.tileHeight;
								}
							default:
						}
					}
					samples.push({ type : sampleType, source : group, exits : findPossibleExits(group, sampleMap) });
				default:
					throw "bad logic";
			}
		}
	}

	public function generate( mapWidth : Int = 80, mapHeight : Int = 80, fail : Int = 100, b1 : Int = 5, mrooms : Int = 60 ) : TmxMap {
		var map : TmxMap = {
			version : sampleMap.version,
			tiledVersion : sampleMap.tiledVersion,
			orientation : Isometric,
			width : mapWidth,
			height : mapHeight,
			tileWidth : sampleMap.tileWidth,
			tileHeight : sampleMap.tileHeight,
			backgroundColor : sampleMap.backgroundColor,
			renderOrder : sampleMap.renderOrder,
			properties : sampleMap.properties,
			tilesets : sampleMap.tilesets,
			layers : [],
			nextObjectId : 0,
			nextLayerId : 0,
			infinite : sampleMap.infinite,
			localPath : ""
		};

		var map = resolveMap('test.tmx');

		map.tilesets = sampleMap.tilesets;

		var startingRoom = Random.fromArray(samples.filter(sample -> sample.type == Start));
		var startingRoomSize = getSampleSize(startingRoom);
		var randomX = Random.int(0, Std.int(mapWidth - startingRoomSize.x));
		var randomY = Random.int(0, Std.int(mapHeight - startingRoomSize.y));

		applySample(startingRoom, startingRoomSize, randomX, randomY, map);

		#if exits_mapgen_debug
		// var startingExits = findPossibleExits(startingRoom, map);

		// for ( i in startingExits ) {
		// 	switch map.getLayersByName("proto")[0] {
		// 		case LTileLayer(layer):
		// 			layer.data.tiles[i.x + randomX + (i.y + randomY) * map.width].gid = 115;
		// 		default:
		// 	}
		// }
		#end

		var failed : Int = 0;
		while( failed < fail ) {

			var chooseRoom = Random.fromArray(roomList);
			var chooseRoomPossibeExits = chooseRoom.sample.exits;
			var chooseExit = Random.fromArray(chooseRoomPossibeExits);
			var chooseExitDirection = Random.fromArray(chooseExit.towards);

			var newMidstSample = Random.fromArray(samples.filter(sample -> sample.type == Midst));
			var newMidstSampleSize = getSampleSize(newMidstSample);
			var newMidstExits = newMidstSample.exits.filter(exit -> switch chooseExitDirection {
				case North: if ( exit.towards.contains(South) ) true else false;
				case West: if ( exit.towards.contains(East) ) true else false;
				case South: if ( exit.towards.contains(North) ) true else false;
				case East: if ( exit.towards.contains(West) ) true else false;
				default: false;
			});

			var newMidstExit = Random.fromArray(newMidstExits);
			var placingX = chooseExit.x + chooseRoom.x;
			var placingY = chooseExit.y + chooseRoom.y;

			switch chooseExitDirection {
				case North:
					placingY -= 2 + newMidstExit.y;
					placingX -= newMidstExit.x;
				case West:
					placingX -= 2 + newMidstExit.x;
					placingY -= newMidstExit.y;
				case South:
					placingY += 2 - newMidstExit.y;
					placingX -= newMidstExit.x;
				case East:
					placingX += 2 - newMidstExit.x;
					placingY -= newMidstExit.y;
			}
			var placingResult = applySample(newMidstSample, newMidstSampleSize, placingX, placingY, map);

			if ( !placingResult ) failed++; else {
				failed = 0;
				// placing bridge
				{
					var bridgeX = chooseExit.x + chooseRoom.x;
					var bridgeY = chooseExit.y + chooseRoom.y;
					switch chooseExitDirection {
						case North:
							bridgeY--;
						case East:
							bridgeX++;
						case South:
							bridgeY++;
						case West:
							bridgeX--;
					}

					switch map.getLayersByName("proto")[0] {
						case LTileLayer(layer):
							layer.data.tiles[bridgeX + bridgeY * map.width].gid = layer.data.tiles[chooseExit.x + chooseRoom.x
								+ (chooseExit.y + chooseRoom.y) * map.width].gid;
						default:
					}
				}
			}

			// if ( placingResult ) for ( i in findPossibleExits(newMidstSample, sampleMap) ) {
			// 	switch map.getLayersByName("proto")[0] {
			// 		case LTileLayer(layer):
			// 			layer.data.tiles[i.x + placingX + (i.y + placingY) * map.width].gid = 115;
			// 		default:
			// 	}
			// }

			// switch map.getLayersByName("proto")[0] {
			// 	case LTileLayer(layer):
			// 		layer.data.tiles[chooseExit.x + chooseRoom.x + (chooseExit.y + chooseRoom.y) * map.width].gid = 115;
			// 		layer.data.tiles[newMidstExit.x + placingX + (newMidstExit.y + placingY) * map.width].gid = 115;
			// 	default:
			// }

			if ( roomList.length >= mrooms ) failed = fail;
		}

		// for ( i in map.tilesets.filter(tileset -> tileset.name == "alpha")[0].tiles ) for ( i in startingRoom.source.layers ) {
		// 	switch i {
		// 		case LTileLayer(layer):

		// 		default:
		// 	}
		// }
		return map;
	}

	function getSampleSize( sample : GenSample ) : Vector {
		var result = new Vector();
		for ( i in sample.source.layers ) {
			switch i {
				case LTileLayer(layer):
					for ( tilei => tile in layer.data.tiles ) {
						if ( tile.gid != 0 ) {
							var x = (tilei) % sampleMap.width;
							var y = M.floor(tilei / sampleMap.width);

							if ( x > result.x ) result.x = x;
							if ( y > result.y ) result.y = y;
						}
					}
				default:
			}
		}
		// result.x++;
		// result.y++;
		return result;
	}
	/** 
		Подразумевается, что выходы ищутся в основном логическом слое - proto
		@param map - карта для конфигов длины и ширины, генерируемая
	**/
	function findPossibleExits( group : TmxGroup, map : TmxMap ) : Array<{x : Int, y : Int, towards : Array<Towards> }> {
		var result : Array<{x : Int, y : Int, ?towards : Array<Towards> }> = [];
		var ents = [];

		// собираем entity чтобы не воткнуть недостижимый выход
		for ( i in group.layers ) {
			switch i {
				case LObjectGroup(group):
					if ( group.name == "entities" ) for ( i in group.objects ) ents.push(i);
				default:
			}
		}

		function findGroundAroundVoid( id : Int, tiles : Array<TmxTile> ) : Array<Null<Int>> {
			var x = id % map.width;
			var y = M.floor(id / map.width);
			var grounds : Array<Null<Int>> = [];

			var coords = [];
			coords.push(x - 1 + (y - 1) * map.width);
			coords.push(x + (y - 1) * map.width);
			coords.push(x + 1 + (y - 1) * map.width);
			coords.push(x - 1 + (y) * map.width);

			coords.push(x + 1 + (y) * map.width);
			coords.push(x - 1 + (y + 1) * map.width);
			coords.push(x + (y + 1) * map.width);
			coords.push(x + 1 + (y + 1) * map.width);

			for ( i in coords ) try {
				if ( result.filter(f -> (f.x == i % map.width && f.y == M.floor(i / map.width))).length == 0
					&& tiles[i].gid == groundTile ) grounds.push(i);
			} catch( e:Dynamic ) {}

			return grounds;
		}

		// Важно: работает только с теми сущностями, которые расположены внизу своего спрайта
		function isNotOccupiedByAnEntity( id : Int, ents : Array<TmxObject>, map : TmxMap ) : Bool {
			var x = id % map.width;
			var y = M.floor(id / map.width);

			for ( ent in ents ) {
				if ( M.inRange(x + 0.5, ent.x / map.tileHeight - .5, ent.x / map.tileHeight)
					&& M.inRange(y + 0.5, ent.y / map.tileHeight - .5, ent.y / map.tileHeight) ) {
					return false;
				}
			}
			return true;
		}

		function determineFacings( id : Int, tiles : Array<TmxTile> ) : Array<Towards> {
			var x = id % map.width;
			var y = M.floor(id / map.width);

			var result = [];
			var coords = [];
			coords.push(x + (y - 1) * map.width);
			coords.push(x - 1 + (y) * map.width);

			coords.push(x + 1 + (y) * map.width);
			coords.push(x + (y + 1) * map.width);

			for ( i => coord in coords ) {
				if ( tiles[coord].gid == voidTile ) {
					result.push(switch i {
						case 0: North;
						case 1: West;
						case 2: East;
						case 3: South;
						case _: throw "bad logic";
					});
				}
			}
			return result;
		}

		for ( i in group.layers ) {
			switch i {
				case LTileLayer(layer):
					for ( tilei => tile in layer.data.tiles ) {
						if ( tile.gid == voidTile ) {
							var grounds = findGroundAroundVoid(tilei, layer.data.tiles);
							for ( ground in grounds ) if ( ground != null && isNotOccupiedByAnEntity(ground, ents, map) ) {
								var facings = determineFacings(ground, layer.data.tiles);
								if ( facings.length > 0 ) result.push({
									x : (ground % map.width),
									y : M.floor(ground / map.width),
									towards : facings
								});
							}
						}
					}
				default:
			}
		}

		return result;
	}
	/** 
		@return false if room was not placed, true if the room is placed
	**/
	function applySample( sample : GenSample, sampleSize : Vector, x : Int, y : Int, to : TmxMap ) : Bool {
		function createLayerIfNotExistsByName( name : String, type : TmxLayer ) : TmxLayer {
			var layer = to.getLayersByName(name)[0];

			if ( layer == null ) {
				layer = switch type {
					case LTileLayer(layer):
						LTileLayer(new TmxTileLayer({
							encoding : null,
							compression : null,
							tiles : emptyTiles(to),
							chunks : null,
							data : null
						}, to.nextLayerId++, name, 0, 0, 0, 0, to.width,
							to.height, 1, true, to.backgroundColor, new TmxProperties()));
					case LObjectGroup(group):
						LObjectGroup(new TmxObjectGroup(Index, [], to.backgroundColor, to.nextLayerId++, name, 0, 0, 0, 0, to.width, to.height, 1, true, null,
							new TmxProperties()));
					default: throw "not supported";
				}
				to.layers.push(layer);
			}
			return layer;
		}

		var toLayersByName = to.mapLayersByName();

		function canBePlaced() : Bool {
			if ( x < 0 || y < 0 || x + sampleSize.x > to.width || y + sampleSize.y > to.height ) return false;
			for ( sampleLayer in sample.source.layers ) {
				switch sampleLayer {
					case LTileLayer(layer):
						var toLayer = toLayersByName[layer.name];
						if ( toLayer != null ) {
							switch toLayer {
								case LTileLayer(extractedTolayer):
									for ( tileI => tile in layer.data.tiles ) {
										if ( tile.gid != 0 ) {
											var lookupTile = extractedTolayer.data.tiles[
												Std.int((tileI) % sampleMap.width
													+ x
													+ (to.width * y)
													+ (M.floor(tileI / sampleMap.width)) * sampleMap.width
													+ (M.floor(tileI / sampleMap.width)) * (to.width - sampleMap.width))
											];
											if ( lookupTile.gid != 0 && lookupTile.gid != voidTile ) {
												return false;
											}
										}
									}
								default:
							}
						}
					default:
				}
			}
			return true;
		}

		if ( canBePlaced() ) {
			// if ( true ) {
			for ( applyFromLayer in sample.source.layers ) {
				switch applyFromLayer {
					case LTileLayer(layer):
						var applyTo = cast(Type.enumParameters(createLayerIfNotExistsByName(layer.name, LTileLayer(null)))[0], TmxTileLayer);

						for ( tileI => tile in layer.data.tiles ) {
							if ( tile.gid != 0 ) {
								applyTo.data.tiles[
									Std.int((tileI) % sampleMap.width
										+ x
										+ (to.width * y)
										+ (M.floor(tileI / sampleMap.width)) * sampleMap.width
										+ (M.floor(tileI / sampleMap.width)) * (to.width - sampleMap.width))
								] = tile;
							}
						}
					case LObjectGroup(group):
						var applyTo = cast(Type.enumParameters(createLayerIfNotExistsByName(group.name, LObjectGroup(null)))[0], TmxObjectGroup);

						for ( i in group.objects ) {
							var ent : TmxObject = Unserializer.run(Serializer.run(i));
							ent.x += x * sampleMap.tileHeight;
							ent.y += y * sampleMap.tileHeight;

							applyTo.objects.push(ent);
						}
					default:
						throw "not supported";
				}
			}
			roomList.push({ x : x, y : y, sample : sample });
			return true;
		} else
			return false;
	}
}
