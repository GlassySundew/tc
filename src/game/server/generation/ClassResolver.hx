package game.server.generation;

import game.server.generation.StubGenerator;

inline function resolve( name : String ) : Class<ChunkGenerator> {
	var type = Type.resolveClass( name );
	if ( type == null ) throw 'failed to resolve "$name" generator type';
	return cast type;
}
