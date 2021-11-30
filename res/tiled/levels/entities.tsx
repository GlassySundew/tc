<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.5" tiledversion="1.7.2" name="entities" tilewidth="144" tileheight="134" tilecount="15" columns="10" backgroundcolor="#171717">
 <grid orientation="orthogonal" width="1" height="1"/>
 <tile id="2">
  <image width="48" height="48" source="separated/player/player.png"/>
  <objectgroup draworder="index" id="2">
   <object id="11" x="22" y="39">
    <polygon points="0,0 3,0 6,-1 7,-3 6,-5 3,-6 0,-6 -3,-5 -4,-3 -3,-1"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="3">
  <properties>
   <property name="highlight" type="color" value="#ffffffff"/>
  </properties>
  <image width="48" height="48" source="separated/structures/pcgmw.png"/>
  <objectgroup draworder="index" id="2">
   <object id="114" x="24" y="43">
    <polygon points="0,0 -14,-7 0,-14 14,-7"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="4">
  <image width="48" height="36" source="separated/structures/emerald.png"/>
  <objectgroup draworder="index" id="2">
   <object id="2" x="21" y="19">
    <polygon points="-1,0 6,0 11,2 13,5 11,8 6,10 -1,10 -6,8 -8,5 -6,2"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="5">
  <properties>
   <property name="highlight" type="color" value="#ffffffff"/>
  </properties>
  <image width="48" height="36" source="separated/structures/amethyst.png"/>
  <objectgroup draworder="index" id="2">
   <object id="2" x="21" y="17">
    <polygon points="-1,0 6,0 11,2 13,5 11,8 6,10 -1,10 -6,8 -8,5 -6,2"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="7">
  <image width="48" height="36" source="separated/structures/iron.png"/>
  <objectgroup draworder="index" id="2">
   <object id="2" x="19" y="20">
    <polygon points="-1,0 6,0 11,2 13,5 11,8 6,10 -1,10 -6,8 -8,5 -6,2"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="9">
  <image width="95" height="48" source="separated/structures/hydroponics.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="-1" y="50">
    <polygon points="32,-14 73,-34 90,-26 49,-6"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="10">
  <image width="96" height="72" source="separated/structures/sleeping_pod.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="16" y="57">
    <polygon points="20,9 -15,-8 34,-32 68,-15"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="12">
  <image width="48" height="77" source="separated/structures/door.png"/>
  <objectgroup draworder="index" id="3">
   <object id="5" name="center" x="18" y="61">
    <point/>
   </object>
   <object id="6" x="10" y="68">
    <polygon points="0,0 -8,-4 14,-15 22,-11"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="13">
  <properties>
   <property name="interactable" type="bool" value="false"/>
  </properties>
  <image width="114" height="134" source="separated/structures/bridge_wall.png"/>
  <objectgroup draworder="index" id="3">
   <object id="8" name="center" x="4" y="138">
    <point/>
   </object>
  </objectgroup>
 </tile>
 <tile id="14">
  <properties>
   <property name="interactable" type="bool" value="false"/>
  </properties>
  <image width="48" height="48" source="separated/structures/bridge_table_2.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="1" y="37">
    <polygon points="0,0 27,14 42,-22"/>
   </object>
   <object id="2" name="center" x="8" y="37">
    <point/>
   </object>
  </objectgroup>
 </tile>
 <tile id="15">
  <properties>
   <property name="interactable" type="bool" value="true"/>
  </properties>
  <image width="144" height="60" source="separated/structures/navigation_console.png"/>
  <objectgroup draworder="index" id="2">
   <object id="6" name="center" x="71" y="32">
    <point/>
   </object>
   <object id="3" x="117" y="28">
    <polygon points="5,3 -22,-14 -45,-4 -45,6 -24,18"/>
   </object>
   <object id="9" x="72" y="34">
    <polygon points="0,0 -1,-16 -50,-9 -48,1 -24,13"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="16">
  <properties>
   <property name="interactable" type="bool" value="false"/>
  </properties>
  <image width="48" height="48" source="separated/structures/bridge_chair.png"/>
  <objectgroup draworder="index" id="2">
   <object id="2" x="18" y="34">
    <polygon points="0,0 3,-2 10,-2 13,0 13,3 10,5 3,5 0,3"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="17">
  <image width="48" height="66" source="separated/structures/back_door.png"/>
  <objectgroup draworder="index" id="2">
   <object id="4" x="25" y="63">
    <polygon points="0,0 -22,-11 -14,-15 8,-4"/>
   </object>
   <object id="5" name="center" x="21" y="53">
    <point/>
   </object>
  </objectgroup>
 </tile>
 <tile id="19">
  <image width="48" height="48" source="separated/structures/chest.png"/>
  <objectgroup draworder="index" id="3">
   <object id="4" x="22" y="44">
    <polygon points="0,0 20,-10 8,-16 -12,-6"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="20">
  <image width="48" height="36" source="separated/structures/teleport.png"/>
  <objectgroup draworder="index" id="2">
   <object id="5" x="24" y="29">
    <polygon points="0,0 -14,-7 0,-14 14,-7"/>
   </object>
  </objectgroup>
 </tile>
</tileset>
