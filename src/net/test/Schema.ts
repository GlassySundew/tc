import { Schema, type, ArraySchema, MapSchema } from "@colyseus/schema";

class Player extends Schema {
  @type("number")
  x: number = 0;

  @type("number")
  y: number = 0;
}

class State extends Schema {
  @type({ map: Player })
  players = new MapSchema<Player>();

  something = "This attribute won't be sent to the client-side";

  createPlayer (id: string) {
      this.players[ id ] = new Player();
  }

  removePlayer (id: string) {
      delete this.players[ id ];
  }

  movePlayer (id: string, movement: any) {
      if (movement.x) {
          this.players[ id ].x += movement.x * 10;

      } else if (movement.y) {
          this.players[ id ].y += movement.y * 10;
      }
  }
}
