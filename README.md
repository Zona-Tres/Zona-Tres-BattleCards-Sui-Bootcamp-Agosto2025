# BattleCards
BattleCards es un juego de cartas implementado en el lenguaje Move para la blockchain Sui. Este juego consiste en que los jugadores deben enfrentarse contra una IA (cuya decisiones son tomadas aprovechando la aleatoriedad de la blockchain) en partidas por turnos donde en cada turno se selecciona una carta de ataque, que disminuye la vida del contrincante o una de defensa, que mitiga o anula el daño enemigo. La partida termina cuando la vida de alguno de los dos participantes (la IA o el usuario) llega a cero.

## Publicar el proyecto en testnet
1. Una vez hecha la copia del proyecto en local, es necesario realizar la compulación del proyecto mediante el siguiente comando en la terminal: 

```bash
sui move build

```

**NOTA:** Es importante estar en la carpeta raiz del proyecto mediante el uso de `cd`.

2. Subir el proyecto a testnet mediante:

```bash
sui client publish --gas-budget 100000000
```

**NOTA:** Para esto es necesario tener un address con gas, en dado caso de no tener uno se puede crear un address nuevo mediante: `sui client new-address ed25519 MY_ALIAS` y solicitar tokens mediante: `sui client faucet`. Como consecuencia, esto le otorgará al address un `UpgradeCap`, visible desde `sui client objects`, que es un objeto de pertenencia relacionado con el paquete desplegado en la blockchain con el cual se pueden hacer modificaciones y actualizaciones a los paquetes.

3. Ya realizada la transacción es importante obtener el `OBJECT ID` que se muestra en el apartado `OBJECT CHANGES` en `PUBLISH OBJECTS`. Posteriormente, como recomendación, es importante exportarla como variable local:
```bash
export PACKAGE_ID= 0x...
```

## Iniciar una nueva partida 
4. Para iniciar una nueva partida es necesario realizar una llamada al metódo `nueva_partida`:
```bash
sui client call \
  --package $PACKAGE_ID \
  --module battlecards \
  --function nueva_partida \
  --gas-budget 100000000
```

Como resultado, se transferirá la partida al address del caller. Es importante respaldar la ID de la partida, ya que sin el ID no podremos tomar acción en ella.

5. Una vez creada la partida lo siguiente es seleccionar una carta, ya sea de `ataque`:
```bash
sui client call \
  --package $PACKAGE_ID\
  --module battlecards \
  --function carta_ataque \
  --args "0x.. ID Partida" 0x8\
  --gas-budget 100000000
```

O de defensa:
```bash
sui client call \
  --package $PACKAGE_ID\
  --module battlecards \
  --function carta_defensa \
  --args "0x.. ID Partida" 0x8\
  --gas-budget 100000000
```

6. Finalmente, se debe llamar al metodo `jugador_listo` para terminar el turno:
```bash
sui client call \
  --package $PACKAGE_ID\
  --module battlecards \
  --function jugador_listo \
  --args "0x.. ID Partida" 0x8\
  --gas-budget 100000000
```
