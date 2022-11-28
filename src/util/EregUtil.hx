package util;

class EregUtil {

	/** Regex to get class name provided by CompileTime libs, i.e. en.$Entity -> Entity **/
	public static var eregCompTimeClass = ~/\$([a-zA-Z_0-9]+)+$/gi; // regexp to remove 'en.' prefix

	/** regex to match automapping random rules **/
	public static var eregAutoMapRandomLayer = ~/(?:output|input)([0-9]+)_([a-z]+)$/gi;

	/** regex to match automapping inputnot rules **/
	public static var eregAutoMapInputNotLayer = ~/(?:input)not_([a-z]+)$/gi;

	/** Regex to get '$this' class name i.e. en.Entity -> Entity **/
	public static var eregClass = ~/\.([a-z_0-9]+)+$/gi; // regexp to remove 'en.' prefix

	/** Регулярка чтобы взять из абсолютного пути название файла без расширения **/
	public static var eregFileName = ~/\/*([a-z_0-9]+)\./;

	public static function getMatches( ereg : EReg, input : String, index : Int = 0 ) : Array<String> {
		var matches = [];
		while( ereg.match( input ) ) {
			matches.push( ereg.matched( index ) );
			input = ereg.matchedRight();
		}
		return matches;
	}

	public static function decapitalizeWithUnderscore( string : String ) {
		var ereg = ~/[A-Z]+/g;
		for ( i => upperCase in getMatches( ereg, string ) ) {
			string = StringTools.replace( string, upperCase, ( i == 0 ? "" : "_" ) + upperCase.toLowerCase() );
		}
		return string;
	}
}
