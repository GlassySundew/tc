<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.5" tiledversion="1.7.1" name="colls" tilewidth="114" tileheight="134" tilecount="15" columns="10" backgroundcolor="#171717">
 <grid orientation="orthogonal" width="1" height="1"/>
 <tile id="2">
  <image width="48" height="48" source="separated/player/player.png"/>
  <objectgroup draworder="index" id="2">
   <object id="6" x="18" y="32" width="11" height="6">
    <ellipse/>
   </object>
   <object id="7" name="center" x="24" y="35">
    <point/>
   </object>
  </objectgroup>
 </tile>
 <tile id="3">
  <properties>
   <property name="highlight" type="color" value="#ffffffff"/>
  </properties>
  <image width="48" height="48" source="separated/structures/pcgmw.png"/>
  <objectgroup draworder="index" id="3">
   <object id="113" x="9" y="36">
    <polygon points="1,0 15,7 29,0 15,-7"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="4">
  <image width="48" height="36" source="separated/structures/emerald.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="13" y="18" width="21" height="10">
    <ellipse/>
   </object>
  </objectgroup>
 </tile>
 <tile id="5">
  <properties>
   <property name="highlight" type="color" value="#ffffffff"/>
  </properties>
  <image width="48" height="36" source="separated/structures/amethyst.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="13" y="17" width="21" height="10">
    <ellipse/>
   </object>
  </objectgroup>
 </tile>
 <tile id="7">
  <image width="48" height="36" source="separated/structures/iron.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="11" y="18" width="22" height="11">
    <properties>
     <property name="highilightColor" type="color" value=""/>
    </properties>
    <ellipse/>
   </object>
  </objectgroup>
 </tile>
 <tile id="9">
  <image width="96" height="48" source="separated/structures/hydroponics.png"/>
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
   <object id="3" x="2" y="65">
    <polygon points="0,0 24,-12 30,-9 6,3"/>
   </object>
   <object id="5" name="center" x="19" y="62">
    <point/>
   </object>
  </objectgroup>
 </tile>
 <tile id="13">
  <properties>
   <property name="interactable" type="bool" value="false"/>
  </properties>
  <image width="114" height="134" source="separated/structures/bridge_wall.png"/>
  <objectgroup draworder="index" id="3">
   <object id="8" name="center" x="0" y="134">
    <point/>
   </object>
  </objectgroup>
 </tile>
 <tile id="14">
  <properties>
   <property name="interactable" type="bool" value="false"/>
  </properties>
  <image width="60" height="50" source="separated/structures/bridge_table_2.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="8" y="37">
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
  <image width="104" height="44" source="separated/structures/navigation_console.png"/>
  <objectgroup draworder="index" id="2">
   <object id="6" name="center" x="78" y="27">
    <point/>
   </object>
   <object id="3" x="103" y="24">
    <polygon points="5,3 -22,-14 -45,-4 -45,6 -24,18"/>
   </object>
   <object id="9" x="58" y="30">
    <polygon points="0,0 -1,-16 -50,-9 -47,0 -24,13"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="16">
  <properties>
   <property name="interactable" type="bool" value="false"/>
  </properties>
  <image width="48" height="45" source="separated/structures/bridge_chair.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="17" y="30" width="12" height="7">
    <ellipse/>
   </object>
  </objectgroup>
 </tile>
 <tile id="17">
  <image width="48" height="66" source="separated/structures/back_door.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="33" y="51" rotation="180">
    <polygon points="0,-9 24,3 30,0 6,-12"/>
   </object>
   <object id="2" name="center" x="21" y="56">
    <point/>
   </object>
  </objectgroup>
 </tile>
 <tile id="19">
  <image width="48" height="36" source="separated/structures/chest.png"/>
  <objectgroup draworder="index" id="3">
   <object id="2" x="9" y="26">
    <polygon points="0,0 13,6 33,-4 20,-10"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="20">
  <image width="48" height="36" source="separated/structures/teleport.png"/>
  <objectgroup draworder="index" id="2">
   <object id="2" name="center" x="24" y="24">
    <point/>
   </object>
   <object id="3" x="24" y="31">
    <polygon points="0,0 -17,-9 0,-17 17,-8"/>
   </object>
  </objectgroup>
 </tile>
</tileset>
