<?xml version="1.0" encoding="UTF-8"?>
<tileset version="1.4" tiledversion="2020.09.22" name="colls" tilewidth="114" tileheight="134" tilecount="14" columns="10">
 <grid orientation="orthogonal" width="1" height="1"/>
 <tile id="2">
  <image width="32" height="32" source="../separated/q/player.png"/>
  <objectgroup draworder="index" id="2">
   <object id="6" x="11" y="26" width="11" height="5">
    <ellipse/>
   </object>
  </objectgroup>
 </tile>
 <tile id="3">
  <properties>
   <property name="highlight" type="color" value="#ffffffff"/>
  </properties>
  <image width="46" height="46" source="../separated/structures/pcgmw.png"/>
  <objectgroup draworder="index" id="3">
   <object id="113" x="9" y="32">
    <polygon points="1,0 15,7 29,0 15,-7"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="4">
  <image width="46" height="36" source="../separated/structures/emerald.png"/>
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
  <image width="46" height="36" source="../separated/structures/amethyst.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="13" y="19" width="21" height="10">
    <ellipse/>
   </object>
  </objectgroup>
 </tile>
 <tile id="7">
  <image width="46" height="36" source="../separated/structures/iron.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="13" y="16" width="22" height="11">
    <properties>
     <property name="highilightColor" type="color" value=""/>
    </properties>
    <ellipse/>
   </object>
  </objectgroup>
 </tile>
 <tile id="9">
  <image width="90" height="50" source="../separated/structures/hydroponics.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="-5" y="50">
    <polygon points="35,-14 74,-33 88,-26 49,-7"/>
   </object>
   <object id="2" name="center" x="56" y="29">
    <point/>
   </object>
  </objectgroup>
 </tile>
 <tile id="10">
  <image width="92" height="50" source="../separated/structures/sleeping_pod.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="48" y="46">
    <polygon points="0,0 -15,-8 25,-28 40,-20"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="11">
  <image width="32" height="32" source="../separated/q/webplayer.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="11" y="26" width="11" height="5">
    <ellipse/>
   </object>
  </objectgroup>
 </tile>
 <tile id="12">
  <image width="56" height="77" source="../separated/structures/door.png"/>
  <objectgroup draworder="index" id="3">
   <object id="4" name="center" x="29" y="58">
    <point/>
   </object>
   <object id="3" x="11" y="60">
    <polygon points="0,0 24,-12 30,-9 6,3"/>
   </object>
  </objectgroup>
 </tile>
 <tile id="13">
  <properties>
   <property name="interactable" type="bool" value="false"/>
  </properties>
  <image width="114" height="134" source="../separated/structures/bridge_wall.png"/>
  <objectgroup draworder="index" id="3">
   <object id="7" name="center" x="15" y="130">
    <point/>
   </object>
  </objectgroup>
 </tile>
 <tile id="14">
  <properties>
   <property name="interactable" type="bool" value="false"/>
  </properties>
  <image width="60" height="50" source="../separated/structures/bridge_table_2.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="8" y="37">
    <polygon points="0,0 27,14 42,-22"/>
   </object>
   <object id="2" name="center" x="8" y="40">
    <point/>
   </object>
  </objectgroup>
 </tile>
 <tile id="15">
  <properties>
   <property name="interactable" type="bool" value="true"/>
  </properties>
  <image width="104" height="44" source="../separated/structures/bridge_table_1.png"/>
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
  <image width="33" height="45" source="../separated/structures/bridge_chair.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="11" y="32" width="12" height="7">
    <ellipse/>
   </object>
  </objectgroup>
 </tile>
 <tile id="17">
  <image width="56" height="77" source="../separated/structures/back_door.png"/>
  <objectgroup draworder="index" id="2">
   <object id="1" x="41" y="51" rotation="180">
    <polygon points="0,-9 24,3 30,0 6,-12"/>
   </object>
   <object id="2" name="center" x="29" y="54">
    <point/>
   </object>
  </objectgroup>
 </tile>
</tileset>
