package mapgen;

import format.tmx.Data;

@:publicFields
@:expose
class AutoTile {
	var layersByName : Map<String, TmxLayer>;
	var map : TmxMap;

	public function new(map : TmxMap) {
		layersByName = map.getLayersByName();
	}

	function splitMap() {
		var regions_inputLayer = layersByName.get("regions_input");
		switch regions_inputLayer {
			case LTileLayer(layer):
            
                for (i in layer.data.tiles) {}
			default:
				throw "wrong autotile markup";
		}
	}
}
