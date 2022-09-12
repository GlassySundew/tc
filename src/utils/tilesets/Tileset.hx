package utils.tilesets;

import h3d.mat.Texture;

/**
	a stack of a same figure in a different palette variations, only vertical( CONGRUENT ) is supported
**/
typedef Figure = {
	var figStartX : Int;
	var figStartY : Int;
	var palettes : Int;
}

/**
	a packed tileset with a set of figures in different palettes, 
	used to turn them 3d through LUT
	based on CONGRUENT layout
**/
class Tileset {

	public var texture( default, null ) : Texture;
	public var figures( default, null ) : Array<Figure>;
	public var tileW( default, null ) : Int;
	public var tileH( default, null ) : Int;
	public var lutRows( default, null ) : Int;

	public function new(
		texture : Texture,
		tileW : Int,
		tileH : Int,
		figures : Array<Figure>,
		?lutRows : Int
	) {
		this.texture = texture;
		this.tileW = tileW;
		this.tileH = tileH;
		this.figures = figures;
	}

	public function bSearchModel(
		x : Int, y : Int,
		?figi : Null<Int>,
		?start : Null<Int>,
		?end : Null<Int>
	) : Int {
		if ( figi == null )
			figi = figures.length >> 1;
		if ( start == null )
			start = 0;
		if ( end == null )
			end = figures.length;

		var fig = figures[figi];

		if ( x == fig.figStartX && y >= fig.figStartY && y < ( fig.figStartY + fig.palettes ) ) {
			return figi;
		}
		if ( ( x < fig.figStartX || y < fig.figStartY ) && y < fig.figStartY + fig.palettes ) {
			return bSearchModel( x, y, figi - ( ( figi - start ) >> 1 ) - 1, start, figi );
		} else {
			return bSearchModel( x, y, figi + ( ( end - figi + 1 ) >> 1 ), figi, end );
		}
	}
}
