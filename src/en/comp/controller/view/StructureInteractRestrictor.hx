package en.comp.controller.view;

import util.Util;
import h3d.Vector;
import oimo.collision.geometry.ConvexHullGeometry;

class StructureInteractRestrictor extends EntityController {

	public function new() {
		super();
	}

	override function attach( ent : Entity ) {
		super.attach( ent );

		ent.onMove.add(() -> {
			for ( str in Structure.CLIENT_STRUCTURES ) {
				if ( !str.canBeInteractedWith.val ) continue;

				var geom = str.model.rigidBody._shapeList.getGeometry();
				if ( Std.isOfType( geom, ConvexHullGeometry ) ) {
					var dist = Util.distToPoly(
						new Vector(
							ent.model.footX.val - str.model.footX.val,
							ent.model.footY.val - str.model.footY.val,
							ent.model.footZ.val - str.model.footZ.val
						),
						cast Std.downcast( geom, ConvexHullGeometry )._vertices );

					str.reachable.val = str.structureModel.structureCdb.use_range > dist;
				}
			}
		} );
	}
}
