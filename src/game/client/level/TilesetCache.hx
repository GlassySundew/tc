package game.client.level;

import h3d.mat.Texture;

class TilesetCache {

	var tilesets : Map<Data.TilesetKind, TilesetCacheElement> = [];

	public function new() {
		for ( tileset in Data.tileset.all ) {
			switch( tileset.type ) {
				case LUT( tileW ):
					tilesets[tileset.id] = new LUTTilesetCacheElement( tileset );
			}
		}
	}

	public inline function getLUT( tileset : Data.Tileset ) : LUTTilesetCacheElement {
		return cast( tilesets[tileset.id], LUTTilesetCacheElement );
	}
}

class TilesetCacheElement {

	public final texture : Texture;

	public function new( tileset : Data.Tileset ) {
		texture = hxd.Res.load( tileset.texturePath ).toTexture();
	}
}

/**
	a stack of a same figure in a different palette variations, 
	yet only vertical( CONGRUENT ) is supported
**/
typedef Figure = {
	var figStartX : Int;
	var figStartY : Int;
	var palettes : Int;
}

class LUTTilesetCacheElement extends TilesetCacheElement {

	public var figuresAmount = 0;
	public var figures : Array<Figure> = [];
	public var blockCache : Map<Int, Int> = [];
	public var lutRows : Int;

	public function new( tileset : Data.Tileset ) {
		super( tileset );

		switch tileset.type {
			case LUT( lutRows ):
				this.lutRows = lutRows;
			default:
		}

		for ( seq in tileset.sequences ) {
			figuresAmount += seq.amount;
			for ( figi in 0...seq.amount ) {
				figures.push( {
					figStartX : tileset.orientation == vertical ? figi + seq.startX : seq.startX,
					figStartY : tileset.orientation == horizontal ? figi + seq.startY : seq.startY,
					palettes : seq.palettes,
				} );
			}
		}
	}
}
