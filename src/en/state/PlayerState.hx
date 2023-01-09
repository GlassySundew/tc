package en.state;

import en.state.EntityState.IEntityState;

abstract class IPlayerState extends IEntityState {}

@:structInit
class PlayerRunningState extends IPlayerState {}

@:structInit
class PlayerIdlingState extends IPlayerState {}
