    
module battlecards::battlecards {
    ////////////////////////////////// Importacion de librerias //////////////////////////////////
    use std::string::{String, utf8};
    use sui::random::{Random, new_generator};
    ////////////////////////////////// Definicion de constantes //////////////////////////////////
    const VIDA: u8 = 20;
    const MAX_ATAQUE: u8 = 10;
    const MAX_DEFENSA: u8 = 10;

    ////////////////////////////////// Definicion de estructuras //////////////////////////////////
    public struct CartaAtaque has store, copy, drop {
        valor: u8
    }

    public struct CartaDefensa has store, copy, drop {
        valor: u8
    }

    public enum CartaJugada has store, copy, drop {
        ataque(CartaAtaque),
        defensa(CartaDefensa)
    }


    public struct Partida has key, store {
        id: UID,
        jugador: address,
        vida_jugador: u8,
        carta_jugada: Option<CartaJugada>,
        terminada: bool,
        decision_ia: Option<CartaJugada>,
        vida_ia: u8,
        ganador: String
    }

    ////////////////////////////////// Creacion de una nueva partida //////////////////////////////////
    #[allow(lint(self_transfer))]
    public fun nueva_partida(ctx: &mut TxContext) {
        let partida = Partida {
            id: object::new(ctx),
            jugador: tx_context::sender(ctx),
            vida_jugador: VIDA,
            carta_jugada: option::none(),
            terminada: false,
            decision_ia: option::none(),
            vida_ia: VIDA,
            ganador: utf8(b"Nadie aun")
        };

        transfer::transfer(partida, tx_context::sender(ctx));
    }

    ////////////////////////////////// Codigos de error //////////////////////////////////
    #[error]
    const JUEGO_TERMINADO: vector<u8> = b"ERROR: Juego terminado";
    #[error]
    const DEBES_SELECCIONAR_CARTA: vector<u8> = b"ERROR: Selecciona una carta primero";
    #[error]
    const NO_ES_TU_PARTIDA: vector<u8> = b"PACKAGE_ID ERROR: No es tu partida";

    ////////////////////////////////// Validacion //////////////////////////////////
    fun validar_partida(partida: &Partida, sender: address) {
        assert!(!partida.terminada, JUEGO_TERMINADO);
        assert!(sender == partida.jugador, NO_ES_TU_PARTIDA);
    }

    ////////////////////////////////// Generador de valores pseudoaleatorios //////////////////////////////////
    #[allow(lint(public_random))]
    public fun generar_aleatorio(random: &Random, max: u8, ctx: &mut TxContext): u8 {
        let mut generator = new_generator(random, ctx);

        generator.generate_u8_in_range(1, max)
    }

    ////////////////////////////////// Seleccionar carta de ataque //////////////////////////////////
    #[allow(lint(public_random))]
    public fun carta_ataque(partida: &mut Partida, r: &Random, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        validar_partida(partida, sender);   

        let valor_ataque = generar_aleatorio(r, MAX_ATAQUE, ctx);
        let nueva_carta = CartaJugada::ataque(CartaAtaque { valor: valor_ataque });

        partida.carta_jugada = option::some(nueva_carta);
    
    }

    ////////////////////////////////// Seleccionar carta de defensa //////////////////////////////////
    #[allow(lint(public_random))]
    public fun carta_defensa(partida: &mut Partida, r: &Random, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        validar_partida(partida, sender);   

        let valor_defensa = generar_aleatorio(r, MAX_DEFENSA, ctx); 
        let nueva_carta = CartaJugada::defensa(CartaDefensa { valor: valor_defensa });

        partida.carta_jugada = option::some(nueva_carta);
        
    }

    ////////////////////////////////// Marcar jugador como listo //////////////////////////////////
    #[allow(lint(public_random))]
    public fun jugador_listo(partida: &mut Partida, r: &Random, ctx: &mut TxContext) {
        let sender = tx_context::sender(ctx);
        validar_partida(partida, sender);
        assert!(option::is_some(&partida.carta_jugada), DEBES_SELECCIONAR_CARTA);
        
        let decision_ia = if (generar_aleatorio(r, 2, ctx) == 1) {
            let valor_ataque = generar_aleatorio(r, MAX_ATAQUE, ctx);
            CartaJugada::ataque(CartaAtaque { valor: valor_ataque })
        } else {
            let valor_defensa = generar_aleatorio(r, MAX_DEFENSA, ctx);
            CartaJugada::defensa(CartaDefensa { valor: valor_defensa })
        };
        partida.decision_ia = option::some(decision_ia);

        resolver_turno(partida, ctx);
    }

    ////////////////////////////////// Resolución de turno //////////////////////////////////
    #[allow(unused_mut_parameter, unused_variable)]
    fun resolver_turno(partida: &mut Partida, ctx: &mut TxContext) {
        let danio_jugador_a_ia = calcular_danio_jugador(&partida.carta_jugada, &partida.decision_ia);
        let danio_ia_a_jugador = calcular_danio_ia(&partida.decision_ia, &partida.carta_jugada);
        
        partida.vida_ia = partida.vida_ia - danio_jugador_a_ia;
        partida.vida_jugador = partida.vida_jugador - danio_ia_a_jugador;
        
        
        if (partida.vida_jugador == 0 || partida.vida_ia == 0) {
            partida.terminada = true;

            if (partida.vida_jugador == 0) {
                partida.ganador = utf8(b"Felicidades, ganaste!");
            } else { 
                partida.ganador = utf8(b"Perdiste, mejor suerte la proxima");
            }
            
        }
    }

    ////////////////////////////////// Cálculo de daño (jugador a IA) //////////////////////////////////
   fun calcular_danio_jugador(carta_jugador: &Option<CartaJugada>, carta_ia: &Option<CartaJugada>): u8 {
        let mut ataque_valor = 0;
        let carta = option::borrow(carta_jugador);
        ataque_valor = match (carta) {
            CartaJugada::ataque(a) => a.valor,
            _ => 0
        };

        let mut defensa_valor = 0;
        let carta = option::borrow(carta_ia);
        defensa_valor = match (carta) {
            CartaJugada::defensa(d) => d.valor,
            _ => 0
        };

        if (ataque_valor > defensa_valor) { ataque_valor - defensa_valor } else { 0 }
    }

    ////////////////////////////////// Cálculo de daño (IA a jugador) //////////////////////////////////
    fun calcular_danio_ia(carta_ia: &Option<CartaJugada>, carta_jugador: &Option<CartaJugada>): u8 {
        let mut ataque_valor = 0;
        let carta = option::borrow(carta_ia);
        ataque_valor = match (carta) {
            CartaJugada::ataque(a) => a.valor,
            _ => 0
        };

        let mut defensa_valor = 0;
        let carta = option::borrow(carta_jugador);
        defensa_valor = match (carta) {
            CartaJugada::defensa(d) => d.valor,
            _ => 0
        };

        if (ataque_valor > defensa_valor) { ataque_valor - defensa_valor } else { 0 }
    }
}