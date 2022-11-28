package util;

enum SystemType {
	Windows;
	Linux;
	Mac;
}

class Env {
	public static var system : SystemType;

	public static function init() {
		system = switch Sys.systemName() {
			case "Windows": Windows;
			case "Mac":		Mac;
			case "Linux":	Linux;
			case _:
				throw "Unknown operating system.";
		}
	}
}
