import hrt.prefab.Prefab;

class Library extends Prefab {

	static var registeredElements = new Map<String, { cl : Class<Prefab> #if editor , inf : hide.prefab.HideProps #end }>();
	static var registeredExtensions = new Map<String, String>();

	public static function getRegistered() {
		return registeredElements;
	}

	public static function register( type : String, cl : Class<Prefab>, ?extension : String ) {
		registeredElements.set( type, { cl : cl #if editor , inf : Type.createEmptyInstance( cl ).getHideProps() #end } );
		if ( extension != null ) registeredExtensions.set( extension, type );
		return true;
	}
}
