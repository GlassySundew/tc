<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.8" tiledversion="1.8.1" name="entities" tilewidth="144" tileheight="134" tilecount="15" columns="10" backgroundcolor="#171717">
 <grid orientation="orthogonal" width="1" height="1"/>
 <tile id="2">
  <properties>
   <property name="className" value="en.player.$Player"/>
  </properties>
  <image width="48" height="48" source="separated/player/idle_down_0.png"/>
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
  <image width="48" height="48" source="separated/structures/workbench.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="24" y="43">
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
  <properties>
   <property name="className" value="en.structures.hydroponics.$Hydroponics"/>
  </properties>
  <image width="96" height="48" source="separated/structures/hydroponics0.png"/>
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
  <properties>
   <property name="className" value="en.structures.$Door"/>
  </properties>
  <image width="48" height="72" source="separated/structures/door0.png"/>
  <objectgroup draworder="index" id="3">
   <object id="5" name="center" x="19" y="57">
    <point/>
   </object>
   <object id="6" x="10" y="63">
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
   <property name="className" value="en.structures.$NavigationConsole"/>
   <property name="interactable" type="bool" value="true"/>
  </properties>
  <image width="144" height="60" source="separated/structures/navigationconsole.png"/>
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
  <properties>
   <property name="className" value="en.structures.$BackDoor"/>
  </properties>
  <image width="48" height="60" source="separated/structures/backdoor0.png"/>
  <objectgroup draworder="index" id="2">
   <object id="4" x="25" y="58">
    <polygon points="0,0 -22,-11 -14,-15 8,-4"/>
   </object>
   <object id="5" name="center" x="20" y="49">
    <point/>
   </object>
  </objectgroup>
 </tile>
 <tile id="19">
  <properties>
   <property name="interactable" type="bool" value="false"/>
  </properties>
  <image width="48" height="48" source="separated/structures/chest.png"/>
  <objectgroup draworder="index" id="3">
   <object id="4" x="22" y="44">
    <polygon points="0,0 20,-10 8,-16 -12,-6"/>
   </object>
   <object id="5" name="center" x="25" y="36">
    <point/>
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
