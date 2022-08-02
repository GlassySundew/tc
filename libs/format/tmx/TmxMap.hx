package format.tmx;

import format.tmx.Data.TmxLayer;
import format.tmx.Data.TmxTileset;
import format.tmx.Data.TmxProperties;
import format.tmx.Data.TmxStaggerAxis;
import format.tmx.Data.TmxStaggerIndex;
import format.tmx.Data.TmxRenderOrder;
import format.tmx.Data.TmxOrientation;
import hxbit.Serializable;

/** General .tmx map file */
@:structInit
class TmxMap implements Serializable {
	/** The TMX format version, generally 1.0. */
	@:s public var version : String;
	/** The Tiled version used to save the file (since Tiled 1.0.1). May be a date (for snapshot builds). */
	@:s public var tiledVersion : String;
	/** Map orientation. */
	@:s public var orientation : TmxOrientation;
	/** The map width in tiles. */
	@:s public var width : Int;
	/** The map height in tiles. */
	@:s public var height : Int;
	/**
	 * The width of a tile.
	 * 
	 * The tilewidth and tileheight properties determine the general grid size of the map.  
	 * The individual tiles may have different sizes. Larger tiles will extend at the top and right (anchored to the bottom left).
	**/
	@:s public var tileWidth : Int;
	/**
	 * The height of a tile.
	 * 
	 * The tilewidth and tileheight properties determine the general grid size of the map.  
	 * The individual tiles may have different sizes. Larger tiles will extend at the top and right (anchored to the bottom left).
	 */
	@:s public var tileHeight : Int;
	/** The background color of the map. Since 0.9, optional. */
	@:s @:optional public var backgroundColor : Int;
	/** The order in which tiles on tile layers are rendered. Since 0.10, but only for orthogonal orientation. */
	@:s @:optional public var renderOrder : TmxRenderOrder;
	/** For staggered and hexagonal maps, determines whether the "even" or "odd" indexes along the staggered axis are shifted. Since 0.11 */
	@:s @:optional public var staggerIndex : TmxStaggerIndex;
	/**
	 * For staggered and hexagonal maps, determines which axis (x or y) is staggered. (since 0.11);
	 * Ex staggerDirection.
	 */
	@:optional public var staggerAxis : TmxStaggerAxis;
	/** Only for hexagonal maps. Determines the width or height (depending on the staggered axis) of the tile's edge, in pixels. Since 0.11 */
	@:optional public var hexSideLength : Int;
	/** Stores the next available ID for new objects. This number is stored to prevent reuse of the same ID after objects have been removed. (since 0.11) */
	@:s @:optional public var nextObjectId : Int;
	/**  Stores the next available ID for new layers. This number is stored to prevent reuse of the same ID after layers have been removed. (since 1.2)
	 */
	@:s @:optional public var nextLayerId : Int;
	/** Properties of the map */
	@:s @:optional public var properties : TmxProperties; // Map<String, String>;

	/** Tilesets used in map */
	@:s public var tilesets : Array<TmxTileset>;
	/** Array of all layers in map. Tile layers, object groups and image layers.*/
	@:s public var layers : Array<TmxLayer>;
	/** Is that map infinite? */
	@:s public var infinite : Bool;
	/** Local path of the TmxMap supplied during parsing. **/
	@:s public var localPath : Null<String>;
}