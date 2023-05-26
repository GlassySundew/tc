import cdb.Data.CustomType;

typedef CustomTypeInstance = {
	var name : String;
	var arguments : Array<Dynamic>;
};

class CdbUtil {

	public static function parseCustomType(
		rawTypeInstance : Array<Dynamic>,
		customType : cdb.Data.CustomType
	) : CustomTypeInstance {
		var customCdbType = customType.cases[rawTypeInstance[0]];

		return { name : null, arguments : null };
	}
}
