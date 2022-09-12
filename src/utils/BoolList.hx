package utils;

/**
	container of bool checks
**/
class BoolList {

	var lambdas : Array<Void -> Bool> = [];

	public function new() {}

	public dynamic function onLambdasChanged() {}

	public function addLambda( lambda : Void -> Bool ) {
		lambdas.push( lambda );
		onLambdasChanged();
	}

	public function removeLambda( lambda : Void -> Bool ) {
		lambdas.remove( lambda );
		onLambdasChanged();
	}

	public function computeAnd() {
		for ( lambda in lambdas ) {
			if ( !lambda() ) return false;
		}
		return true;
	}

	public function computeOr() {
		for ( lambda in lambdas ) {
			if ( lambda() ) return true;
		}
		return false;
	}
}
