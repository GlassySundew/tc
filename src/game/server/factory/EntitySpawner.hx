package game.server.factory;

import net.Server;
import en.Entity;
import en.SpriteEntity;
import util.EregUtil;
import format.tmx.Data;

using en.util.EntityUtil;
using util.Extensions.TmxPropertiesExtension;

class EntitySpawner {

	public var mediator : EntityFactoryMediator;
	public var tmxData : EntityTmxData;
	public var sLevel : ServerLevel;

	public inline function new( mediator ) {
		this.mediator = mediator;
	}

	/**
		Search for name from parsed entNames Entity 
		classes and spawn it, creates static SpriteEntity 
		and puts name into spr group if not found
	**/
	public function spawn() : Entity {

		var resultEntity : Entity = null;

		var footZ : Float =
			sLevel.properties.getProp(
				PTInt,
				"defaultEntitySpawnLevel",
				0,
				() -> return tmxData.obj.properties.getProp( PTInt, "z" )
			) * sLevel.cdb.tileHeight + 1;

		var x = tmxData.obj.x + footZ;
		var y = tmxData.obj.y + footZ;

		if ( tmxData.tsTile == null ) throw "no tstile";

		// Парсим все классы - наследники en.Entity и спавним их
		for ( eClass in mediator.entClasses ) {
			// смотрим во всех наследников Entity и спавним, если совпадает. Если не совпадает, то
			// значит что потом мы смотрим настройку className тайла из тайлсета, который мы пытаемся заспавнить
			if ( //
				(
					EregUtil.eregCompTimeClass.match( '$eClass'.toLowerCase() )
					&& EregUtil.eregCompTimeClass.matched( 1 ) == tmxData.obj.name
				) || (
					tmxData.tsTile.properties.existsType( "className", PTString )
					&& tmxData.tsTile.properties.getString( "className" ) == '$eClass'
				)
			) {
				resultEntity = Type.createInstance( eClass, [tmxData.obj] );
			}
		}

		// если не найдено подходящего класса, то спавним spriteEntity, который является просто спрайтом
		if (
			resultEntity == null
			&& EregUtil.eregFileName.match( tmxData.tsTile.image.source )
			&& !tmxData.tsTile.properties.existsType( "className", PTString ) //
		) {
			resultEntity = new SpriteEntity(
				EregUtil.eregFileName.matched( 1 ),
				tmxData.obj
			);
		}

		if ( resultEntity != null ) @:privateAccess {
			resultEntity.model.tsTile = tmxData.tsTile;
			resultEntity.setFeetPos( x, y, footZ );
			submitToLevel( resultEntity, sLevel );
		}
		Inventorizer.inventorize( resultEntity );


		// resultEntity.enableAutoReplication = true;
		return resultEntity;
	}

	function submitToLevel( resultEntity : Entity, sLevel : ServerLevel ) {
		resultEntity.model.level = sLevel;
		sLevel.entities.push( resultEntity );
		resultEntity.serverApplyTmx();
		resultEntity.onMove.dispatch();
	}
}
