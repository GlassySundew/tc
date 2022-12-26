package pass;

import util.Util;
import h3d.scene.Mesh;
import h3d.Vector;
import en.objs.IsoTileSpr;
import h3d.pass.PassObject;
import h3d.pass.PassList;

typedef Point = { var x : Float; var y : Float; }

typedef Line = { var pt1 : Point; var pt2 : Point; }

class CustomRenderer extends h3d.scene.fwd.Renderer {

	public var saoBlur : h3d.pass.Blur;
	public var enableSao : Bool;
	public var enableFXAA : Bool;

	public var all : h3d.pass.Output;
	public var fog : pass.Fog;
	public var sao : h3d.pass.ScalableAO;
	public var emissive : pass.Emissive;
	public var fxaa : h3d.pass.FXAA;
	public var post : pass.PostProcessing;
	public var depthColorMap( default, set ) : h3d.mat.Texture;
	public var acceptedMeshes : Array<Dynamic> = [];

	public static var inst : CustomRenderer;

	var depthColorMapId : Int;
	var depthColorMax : Int;
	var out : h3d.mat.Texture;

	public function new() {
		super();
		inst = this;
		var engine = h3d.Engine.getCurrent();
		if ( !engine.driver.hasFeature( MultipleRenderTargets ) ) throw "engine must have MRT";
		all = new h3d.pass.Output( "mrt", [
			Value( "output.color" ),
			PackFloat( Value( "output.depth" ) ),
			PackNormal( Value( "output.normal" ) )
		]
		);

		allPasses.push( all );
		depthColorMap = h3d.mat.Texture.fromColor( 0xFFFFFF );
		depthColorMapId = hxsl.Globals.allocID( "depthColorMap" );
		sao = new h3d.pass.ScalableAO();
		saoBlur = new h3d.pass.Blur( 3, 3, 2 );

		sao.shader.sampleRadius = 0.2;
		fog = new pass.Fog();

		fxaa = new h3d.pass.FXAA();
		emissive = new pass.Emissive( "emissive" );
		emissive.reduceSize = 1;
		// emissive.blur.passes = 5;
		emissive.blur.quality = 4;

		// emissive.blur.sigma = 2;
		post = new pass.PostProcessing();

		frontToBack = depthSort.bind( true );
		backToFront = depthSort.bind( false );
	}

	function set_depthColorMap( v : h3d.mat.Texture ) {
		var pixels = v.capturePixels();
		depthColorMax = pixels.getPixel( pixels.width - 1, 0 );
		// all.clearColors[0] = depthColorMax;
		return depthColorMap = v;
	}

	override function renderPass( p : h3d.pass.Base, passes, ?sort ) {
		return super.renderPass( p, passes, sort );
	}

	function sortIsoPoly( passes : PassList ) {
		passes.sort( function ( o1, o2 ) {
			return -1;
		} );
	}

	override function render() {
		if ( has( "shadow" ) ) renderPass( shadow, get( "shadow" ) );

		var colorTex = allocTarget( "color" );
		var depthTex = allocTarget( "depth" );
		var normalTex = allocTarget( "normal" );
		var additiveTex = allocTarget( "additive" );

		setTargets( [colorTex, depthTex, normalTex, additiveTex] );
		clear( h3d.Engine.getCurrent().backgroundColor, 1 );
		renderPass( defaultPass, get( "default" ) );
		renderPass( defaultPass, get( "alpha" ), backToFront );
		resetTarget();

		setTarget( additiveTex );
		clear( 0 );
		draw( "additive" );
		resetTarget();

		emissive.setContext( ctx );
		emissive.draw( get( "emissive" ) );

		post.setGlobals( ctx );
		post.apply( colorTex, ctx.time );
	}

	public function flash( color : Int, duration : Float ) {
		post.flash( color, ctx.time, duration );
	}

	@:access( h3d.scene.Object )
	public override function depthSort( frontToBack : Bool, passes : PassList ) {
		passes.sort( sortPasses );
	}

	function sortPasses( p1 : PassObject, p2 : PassObject ) {
		return
			if ( Std.isOfType( p1.obj, IsoTileSpr )
				&& Std.isOfType( p2.obj, IsoTileSpr ) )
				getFrontPassIso( p1, p2 );
			else
				( p1.depth > p2.depth ? -1 : 1 );
	}

	#if !debug inline #end
	function getFrontPassIso( p1 : PassObject, p2 : PassObject ) : Int {
		var a = cast( p1.obj, IsoTileSpr ).getIsoBounds();
		var b = cast( p2.obj, IsoTileSpr ).getIsoBounds();

		var p1Iso = Util.isoToCart( p1.obj.x, p1.obj.y );
		var p2Iso = Util.isoToCart( p2.obj.x, p2.obj.y );

		var aIsoMax = Util.isoToCart( a.xMax, a.yMax );
		var aIsoMin = Util.isoToCart( a.xMin, a.yMin );

		var bIsoMax = Util.isoToCart( b.xMax, b.yMax );
		var bIsoMin = Util.isoToCart( b.xMin, b.yMin );

		a = {
			xMin : Std.int( aIsoMin.x ),
			xMax : Std.int( aIsoMax.x ),
			yMin : Std.int( aIsoMin.y ),
			yMax : Std.int( aIsoMax.y ),
		};

		b = {
			xMin : Std.int( bIsoMin.x ),
			xMax : Std.int( bIsoMax.x ),
			yMin : Std.int( bIsoMin.y ),
			yMax : Std.int( bIsoMax.y ),
		};

		// point to point
		return if ( b.yMax == b.yMin && a.yMax == a.yMin ) {
			p1Iso.y > p2Iso.y ? 1 : -1;
		} else if ( b.xMax == b.xMin ) {
			-comparePointAndLine(
				{ x : p2Iso.x, y : p2Iso.y },
				{
					pt1 : { x : a.xMin, y : a.yMin },
					pt2 : { x : a.xMax, y : a.yMax }
				}
			);
		} else if ( a.yMax == a.yMin ) {
			-comparePointAndLine(
				{ x : p1Iso.x, y : p1Iso.y },
				{
					pt1 : { x : b.xMin, y : b.yMin },
					pt2 : { x : b.xMax, y : b.yMax }
				}
			);
		} else {
			-( compareLineAndLine(
				{
					pt1 : { x : b.xMin, y : b.yMin },
					pt2 : { x : b.xMax, y : b.yMax }
				},
				{
					pt1 : { x : a.xMin, y : a.yMin },
					pt2 : { x : a.xMax, y : a.yMax }
				}
			) );
		}
	}

	inline function comparePointAndLine( pt : Point, line : Line ) : Int {
		if ( pt.y > line.pt1.y && pt.y > line.pt2.y ) {
			return -1;
		} else if ( pt.y < line.pt1.y && pt.y < line.pt2.y ) {
			return 1;
		} else {
			var slope = ( line.pt2.y - line.pt1.y ) / ( line.pt2.x - line.pt1.x );
			var intercept = line.pt1.y - ( slope * line.pt1.x );
			return ( ( slope * pt.x ) + intercept ) > pt.y ? 1 : -1;
		}
	}

	inline function compareLineAndLine( line1 : Line, line2 : Line ) {
		var comp1 = comparePointAndLine( line1.pt1, line2 );
		var comp2 = comparePointAndLine( line1.pt2, line2 );
		var oneVStwo = comp1 == comp2 ? comp1 : -2;

		var comp3 = comparePointAndLine( line2.pt1, line1 );
		var comp4 = comparePointAndLine( line2.pt2, line1 );
		var twoVSone = comp3 == comp4 ? -comp3 : -2;

		if ( oneVStwo != -2 && twoVSone != -2 ) {
			if ( oneVStwo == twoVSone ) {
				return oneVStwo;
			}
			return compareLineCenters( line1, line2 );
		} else if ( oneVStwo != -2 ) return oneVStwo;
		else if ( twoVSone != -2 ) return twoVSone;
		else return compareLineCenters( line1, line2 );
	}

	inline function compareLineCenters( line1 : Line, line2 : Line ) {
		return centerHeight( line1 ) > centerHeight( line2 ) ? -1 : 1;
	}

	inline function centerHeight( line : Line ) return ( line.pt1.y + line.pt2.y ) / 2;
}
