package game.client.debug;

import imgui.ImGuiDrawable;
import core.debug.Accessor;
import haxe.exceptions.NotImplementedException;
import core.debug.imgui.ImGuiDebug;
import core.debug.imgui.controller.SameLineController;
import core.debug.imgui.node.CollapsingHeaderNode;
import core.debug.imgui.node.DragDoubleNode;
import core.debug.imgui.node.LabelTextNode;
import core.debug.imgui.node.WindowNode;
import core.debug.imgui.node.intermediate.ImGuiNode;
import dn.Process;
import hl.Ref;
import util.Const;

@:access( h3d.scene.CameraController )
class ImGuiGameClientDebug extends ImGuiDebug {

	var c : Ref<Float>;
	var zFarRef : Ref<Float>;
	var zNearRef : Ref<Float>;
	var fov : Ref<Float>;

	public function new( parent : Process ) {
		super( parent );
		zNearRef = Ref.make( Boot.inst.s3d.camera.zNear );
		zFarRef = Ref.make( Boot.inst.s3d.camera.zFar );

		this.drawable = new ImGuiDrawable( GameClient.inst.root );
		drawable.scale( 1 / Const.UI_SCALE );

		GameClient.inst.root.add( drawable, Const.DP_IMGUI );
		rootNode = new WindowNode( "game debug" );
		var cameraHeader = new CollapsingHeaderNode( "camera", rootNode );
		var zNearDragDouble = new DragDoubleNode( "zNear", new ZNearAccessor(), 0.1, 0.1, 10000, cameraHeader );
		var zFarDragDouble = new DragDoubleNode( "zFar", new ZFarAccessor(), 1, 0, 400000, cameraHeader );
		var zNearK = new DragDoubleNode( "zNearK", new ZNearKAccessor(), 0.01, 0.01, 180, cameraHeader );
		var zFarK = new DragDoubleNode( "zFarK", new ZFarKAccessor(), 0.1, 1.000, 180, cameraHeader );
		var fovDragDouble = new DragDoubleNode( "fov", new FovAccessor(), 0.1, 0.000, 180, cameraHeader );
	}

	override function update() {
		// zNearRef.set( Boot.inst.s3d.camera.zNear );
		// zFarRef.set( Boot.inst.s3d.camera.zFar );
		// fov.set( GameClient.inst.cameraProc.camera.targetOffset.w );
		super.update();
		// Boot.inst.s3d.camera.zNear = zNearRef.get();
		// Boot.inst.s3d.camera.zFar = zFarRef.get();
		// GameClient.inst.cameraProc.camera.targetOffset.w = fov.get();
	}
}

@:access( h3d.scene.CameraController )
class FovAccessor extends Accessor<Float> {

	override function get_val() {
		return GameClient.inst.cameraProc.camera.targetOffset.w;
	}

	override function set_val( v : Float ) {
		return GameClient.inst.cameraProc.camera.targetOffset.w = v;
	}
}

@:access( h3d.scene.CameraController )
class ZNearAccessor extends Accessor<Float> {

	override function get_val() {
		return Boot.inst.s3d.camera.zNear;
	}

	override function set_val( v : Float ) {
		return Boot.inst.s3d.camera.zNear = v;
	}
}

@:access( h3d.scene.CameraController )
class ZFarAccessor extends Accessor<Float> {

	override function get_val() {
		return Boot.inst.s3d.camera.zFar;
	}

	override function set_val( v : Float ) {
		return Boot.inst.s3d.camera.zFar = v;
	}
}
@:access( h3d.scene.CameraController )
class ZFarKAccessor extends Accessor<Float> {

	override function get_val() {
		return GameClient.inst.cameraProc.camera.zFarK;
	}

	override function set_val( v : Float ) {
		return GameClient.inst.cameraProc.camera.zFarK = v;
	}
}
@:access( h3d.scene.CameraController )
class ZNearKAccessor extends Accessor<Float> {

	override function get_val() {
		return GameClient.inst.cameraProc.camera.zNearK;
	}

	override function set_val( v : Float ) {
		return GameClient.inst.cameraProc.camera.zNearK = v;
	}
}