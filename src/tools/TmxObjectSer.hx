package tools;

import format.tmx.Data.TmxObject;

class TmxObjectSer extends TmxObject implements hxbit.Serializable {
	@:keep
	public function customSerialize(ctx : hxbit.Serializer) {
		ctx.addInt(id);
		ctx.addString(name);
		ctx.addString(type);
		ctx.addFloat(x);
		ctx.addFloat(y);
		ctx.addFloat(width);
		ctx.addFloat(height);
		ctx.addFloat(rotation);
		ctx.addBool(visible);
        ctx.addDynamic(objectType);

    }

	@:keep
	public function customUnserialize(ctx : hxbit.Serializer) {}
}
