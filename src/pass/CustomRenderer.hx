package pass;

import h3d.scene.Mesh;
import h3d.Vector;
import en.objs.IsoTileSpr;
import h3d.pass.PassObject;
import h3d.pass.PassList;

typedef Point = { var x : Float; var y : Float; var z : Float; }

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
		if ( has( "shadow" ) ) {
			shadow.draw( get( "shadow" ) );
			renderPass( shadow, get( "shadow" ) );
		}

		if ( has( "depth" ) ) renderPass( depth, get( "depth" ), backToFront );

		// ctx.setGlobalID(depthColorMapId, depthColorMap);

		all.setContext( ctx );

		var colorTex = allocTarget( "color" );
		var depthTex = allocTarget( "depth" );
		var normalTex = allocTarget( "normal" );
		var additiveTex = allocTarget( "additive" );

		setTargets( [colorTex, depthTex, normalTex, additiveTex] );
		clear( h3d.Engine.getCurrent().backgroundColor, 1 );

		all.draw( get( "default" ) );

		renderPass( defaultPass, get( "alpha" ), backToFront );
		// setTarget(colorTex);
		// draw("alpha");
		resetTarget();

		setTarget( additiveTex );
		clear( 0 );
		// draw("additive");
		resetTarget();

		emissive.setContext( ctx );
		emissive.draw( get( "emissive" ) );

		if ( enableSao ) {
			// apply sao
			var saoTarget = allocTarget( "sao", false );
			setTarget( saoTarget );
			sao.apply( depthTex, normalTex, ctx.camera );
			resetTarget();
			saoBlur.apply( ctx, saoTarget, allocTarget( "saoBlurTmp", false ) );
			h3d.pass.Copy.run( saoTarget, colorTex, Multiply );
		}
		{ // apply fog
			// post.apply(colorTex, ctx.time);
			// var fogTarget = allocTarget("fog", false, 1);
			// fog.setGlobals(ctx);
			// setTarget(fogTarget);
			// fog.apply(colorTex, depthTex, normalTex, ctx.camera);
			// resetTarget();
			// colorTex = fogTarget;
		}

		h3d.pass.Copy.run( ctx.textures.allocTarget( "emissive", colorTex.width, colorTex.height ), colorTex, Add );
		h3d.pass.Copy.run( additiveTex, colorTex, Add );

		if ( enableFXAA ) {
			var t = allocTarget( "fxaaOut", false, 0 );
			setTarget( t );
			fxaa.apply( colorTex );
			resetTarget();
			colorTex = t;
		}
		post.setGlobals( ctx );
		post.apply( colorTex, ctx.time );
	}

	public function flash( color : Int, duration : Float ) {
		post.flash( color, ctx.time, duration );
	}

	@:access( h3d.scene.Object )
	public override function depthSort( frontToBack : Bool, passes : PassList ) {
		var cam = ctx.camera.m;
		for ( p in passes ) {
			var z = p.obj.absPos._41 * cam._13 + p.obj.absPos._42 * cam._23 + p.obj.absPos._43 * cam._33 + cam._43;
			var w = p.obj.absPos._41 * cam._14 + p.obj.absPos._42 * cam._24 + p.obj.absPos._43 * cam._34 + cam._44;
			p.depth = z / w;
		}

		passes.sort( function ( p1, p2 ) {
			return try {
				getFrontPassIso( p1, p2 );
			}
			catch( e : Dynamic ) {
				( p1.depth > p2.depth ? -1 : 1 );
			};
		} );
	}

	function getFrontPassIso( p1 : PassObject, p2 : PassObject ) : Int {
		var a = cast( p1.obj, IsoTileSpr ).getIsoBounds();
		var b = cast( p2.obj, IsoTileSpr ).getIsoBounds();
		return if ( b.zMax - b.zMin == 0 && a.zMax - a.zMin == 0 ) // point to point
		{
			p1.obj.z > p2.obj.z ? -1 : 1;
			// - comparePointAndLine({x : p1.obj.x, y : 0, z : p1.obj.z}, {pt1 : {x : b.xMin, y : 0, z : b.zMin}, pt2 : {x : b.xMax, y : 0, z : b.zMax}});
		} else if ( b.xMax - b.xMin == 0 || b.zMax - b.zMin == 0 ) { // point to long iso obj
			- comparePointAndLine( { x : p2.obj.x, y : 0, z : p2.obj.z }, { pt1 : { x : a.xMin, y : 0, z : a.zMin }, pt2 : { x : a.xMax, y : 0, z : a.zMax } } );
		} else {
			-( compareLineAndLine( { pt1 : { x : b.xMin, y : 0, z : b.zMin }, pt2 : { x : b.xMax, y : 0, z : b.zMax } },
				{ pt1 : { x : a.xMin, y : 0, z : a.zMin }, pt2 : { x : a.xMax, y : 0, z : a.zMax } } ) );
		}
	}

	function comparePointAndLine( pt : Point, line : Line ) : Int {
		if ( pt.z > line.pt1.z && pt.z > line.pt2.z ) {
			return -1;
		} else if ( pt.z < line.pt1.z && pt.z < line.pt2.z ) {
			return 1;
		} else {
			var slope = ( line.pt2.z - line.pt1.z ) / ( line.pt2.x - line.pt1.x );
			var intercept = line.pt1.z - ( slope * line.pt1.x );
			return ( ( slope * pt.x ) + intercept ) > pt.z ? 1 : -1;
		}
	}

	function compareLineAndLine( line1 : Line, line2 : Line ) {
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
		} else if ( oneVStwo != -2 ) return oneVStwo; else if ( twoVSone != -2 ) return twoVSone; else
			return compareLineCenters( line1, line2 );
	}

	function compareLineCenters( line1 : Line, line2 : Line ) {
		return centerHeight( line1 ) > centerHeight( line2 ) ? -1 : 1;
	}

	function centerHeight( line : Line ) return ( line.pt1.z + line.pt2.z ) / 2;
}
