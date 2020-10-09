package ui.player;

import h2d.Font;

@:uiComp("beltCont")
class BeltCont extends h2d.Flow implements h2d.domkit.Object {
	static var SRC =
		<beltCont>
			<flow class="beltSlot" public id="beltSlot">
				<flow class="itemContainer" public id="itemContainer" />
				<flow class="hotkeyContainer">
				<text
					class="beltSlotNumber"
					public
					id="beltSlotNumber"
					text={Std.string(slotNumber)}
					font={font}
				/>
				</flow>
			</flow>
		</beltCont>;
	public function new(?font:Font, ?slotNumber:Int, ?parent) {
		super(parent);
		initComponent();
	}
}