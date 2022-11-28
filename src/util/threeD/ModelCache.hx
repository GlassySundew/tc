package util.threeD;

class ModelCache extends h3d.prim.ModelCache {

	override public function loadTexture( model : hxd.res.Model, texturePath, async = false ) : h3d.mat.Texture {
		var fullPath = texturePath;
		if ( model != null )
			fullPath = model.entry.path + "@" + fullPath;
		var t = textures.get( fullPath );
		if ( t != null )
			return t;
		var tres;
		try {
			tres = hxd.res.Loader.currentInstance.load( texturePath );
		} catch( error : hxd.res.NotFound ) {
			if ( model == null )
				throw error;
			// try again to load into the current model directory
			var path = model.entry.directory;
			if ( path != "" ) path += "/";

			path += texturePath; // .split("/").pop();
			var testPath = path;
			try {
				tres = hxd.res.Loader.currentInstance.load( path );
			} catch( e : hxd.res.NotFound )
				try {
					// if this still fails, maybe our first letter is wrongly cased
					var name = path.split( "/" ).pop();
					var c = name.charAt( 0 );
					if ( c == c.toLowerCase() )
						name = c.toUpperCase() + name.substr( 1 );
					else
						name = c.toLowerCase() + name.substr( 1 );
					path = path.substr( 0, -name.length ) + name;
					tres = hxd.res.Loader.currentInstance.load( path );
				} catch( e : hxd.res.NotFound ) {
					// force good path error
					throw error + " " + testPath + " " + texturePath;
				}
		}
		var img = tres.toImage();
		img.enableAsyncLoading = async;
		t = img.toTexture();
		textures.set( fullPath, t );

		return t;
	}

}
