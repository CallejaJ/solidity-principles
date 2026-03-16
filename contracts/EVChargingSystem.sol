// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EV Charging System v1.0
 * @notice Sistema de carga para vehículos eléctricos con control de usuarios y cobro por tiempo
 * @dev Tres soluciones diferentes con comparación de gas
 */

// ============================================================================
// VERSIÓN 1: ARRAY DE DIRECCIONES (Simple pero ineficiente)
// ============================================================================

contract EVChargingV1_Array {
    // ========== EVENTOS ==========
    event ChargingStarted(
        uint256 indexed chargerId,
        address indexed user,
        uint256 timestamp,
        uint256 endTime
    );
    
    event ChargingEnded(
        uint256 indexed chargerId,
        address indexed user,
        uint256 amountCharged
    );
    
    event WithdrawalMade(address indexed admin, uint256 amount);

    // ========== VARIABLES DE ESTADO ==========
    // TODO 1: Define la variable para el admin
    address admin;

    // TODO 2: Define el coste por minuto
    uint256 costPerMinute;

    // TODO 3: Define un array de direcciones para saber quién está en cada cargador
    address[] chargers;

    // TODO 4: Define la caja del contrato (dinero total)
    uint256 balance;

    // ========== CONSTRUCTOR ==========
    /**
     * @param _numChargers Número de cargadores disponibles
     * @param _costPerMinute Coste en WEI por minuto de carga
     */
    constructor(uint256 _numChargers, uint256 _costPerMinute) {
        // TODO 5: Inicializa admin, costPerMinute, crea el array de cargadores
        admin = msg.sender;
        costPerMinute = _costPerMinute;
        // TODO 6: Usa un loop para llenar el array con direcciones cero (0x0)
                for (uint256 i = 0; i < _numChargers; i++) {
                    chargers.push(address(0));
                }
    }

    // ========== MODIFIERS ==========
    // TODO 6: Crea un modifier onlyAdmin que valide que msg.sender sea el admin
        modifier onlyAdmin() {
          require(msg.sender == admin, "Solo admin");
              _;
          }

    // ========== FUNCIONES SOLUCIÓN 1: PREPAGO (SARE) ==========
    /**
     * @notice Usuario reserva un cargador pagando por adelantado
     * @param _chargerId ID del cargador (0 a numChargers-1)
     * @param _durationMinutes Cuántos minutos quiere cargar
     * @param _minDuration Duración mínima permitida (p.e. 5 minutos)
     * @param _maxDuration Duración máxima permitida (p.e. 480 minutos)
     */
    function reserveChargerSolution1(
        uint256 _chargerId,
        uint256 _durationMinutes,
        uint256 _minDuration,
        uint256 _maxDuration
    ) external payable {
        // TODO 7: Validar que el cargador existe
        require(_chargerId < chargers.length, "Cargador no existe");

        // TODO 8: Validar que el cargador está libre (dirección es 0x0)
         require(chargers[_chargerId] == address(0), "Cargador ocupado");

        // TODO 9: Validar que la duración está en rango [minDuration, maxDuration]
        require(_durationMinutes >= _minDuration && _durationMinutes <= _maxDuration, "Duracion fuera de rango");

        // TODO 10: Calcular el coste total: _durationMinutes * costPerMinute
        uint256 cost = _durationMinutes * costPerMinute;

        // TODO 11: Validar que el usuario pagó exactamente (require msg.value == cost)
        require(msg.value == cost, "Pago incorrecto");

        // TODO 12: Marcar el cargador como ocupado (guardar msg.sender en chargers[_chargerId])
        chargers[_chargerId] = msg.sender;

        // TODO 13: Calcular cuándo termina
        uint256 endTime = block.timestamp + (_durationMinutes * 60);

        // TODO 14: Añadir el dinero a la caja
        balance += msg.value;

        // TODO 15: Emitir evento ChargingStarted
        emit ChargingStarted(_chargerId, msg.sender, block.timestamp, endTime);
    }

    /**
     * @notice Admin o usuario termina la carga cuando el tiempo vence
     * @param _chargerId ID del cargador a liberar
     */
    function endChargingSolution1(uint256 _chargerId) external {
        // TODO 16: Validar que el cargador existe
       require(_chargerId < chargers.lenght, "Cargador no existe") 
        // TODO 17: Validar que el cargador está ocupado (no es address(0))
        
        // TODO 18: Obtener quién era el usuario 
        
        
        // TODO 19: Liberar el cargador 
       
        
        // TODO 20: Emitir evento ChargingEnded con el coste (que fue pagado anticipadamente)
        
        
        // El coste fue pagado al reservar
    }

    // ========== FUNCIONES ADMIN ==========
    function withdrawFunds() external {
        // TODO 21: Usar modifier onlyAdmin
        // TODO 22: Validar que hay dinero para retirar
        // TODO 23: Guardar el balance a retirar
        // TODO 24: Poner balance = 0 (evitar reentrancy)
        // TODO 25: Transferir los fondos con call (Checks-Effects-Interactions)
        // Pista: (bool success, ) = msg.sender.call{value: amountToWithdraw}("");
        //        require(success, "Transferencia fallida");
        // TODO 26: Emitir evento WithdrawalMade
    }

    // ========== FUNCIONES VIEW ==========
    function getChargerStatus(uint256 _chargerId) external view returns (address) {
        // TODO 27: Retorna la dirección del usuario en el cargador (o address(0) si libre)
        return chargers[_chargerId];
    }

    function getBalance() external view returns (uint256) {
        // TODO 28: Retorna el balance total del contrato
        return balance;
    }

    function getNumChargers() external view returns (uint256) {
        // TODO 29: Retorna cuántos cargadores hay
        return chargers.length;
    }
}

// ============================================================================
// VERSIÓN 2: MAPPING + ARRAY DE BOOL (Más eficiente)
// ============================================================================

contract EVChargingV2_MappingBool {
    // ========== EVENTOS ==========
    event ChargingStarted(
        uint256 indexed chargerId,
        address indexed user,
        uint256 timestamp,
        uint256 endTime
    );
    
    event ChargingEnded(
        uint256 indexed chargerId,
        address indexed user,
        uint256 amountCharged
    );
    
    event WithdrawalMade(address indexed admin, uint256 amount);

    // ========== VARIABLES DE ESTADO ==========
    address private admin;
    uint256 private costPerMinute;
    uint256 private numChargers;
    uint256 private balance;

    // TODO 30: Mapping para guardar quién usa cada cargador
    // Pista: mapping(uint256 => address) currentUser;

    // TODO 31: Array de bools para saber qué cargadores están ocupados
    // Pista: bool[] isOccupied;

    // OPCIONAL: Puedes guardar también cuándo termina cada carga
    // mapping(uint256 => uint256) endTime;

    // ========== CONSTRUCTOR ==========
    constructor(uint256 _numChargers, uint256 _costPerMinute) {
        admin = msg.sender;
        costPerMinute = _costPerMinute;
        numChargers = _numChargers;

        // TODO 32: Inicializa el array isOccupied con false para todos los cargadores
        // Pista: for (uint256 i = 0; i < _numChargers; i++) {
        //            isOccupied.push(false);
        //        }
    }

    // ========== MODIFIERS ==========
    modifier onlyAdmin() {
        require(msg.sender == admin, "Solo admin");
        _;
    }

    // ========== FUNCIONES SOLUCIÓN 1: PREPAGO (SARE) ==========
    function reserveChargerSolution2(
        uint256 _chargerId,
        uint256 _durationMinutes,
        uint256 _minDuration,
        uint256 _maxDuration
    ) external payable {
        // TODO 33: Validar que el cargador existe
        // TODO 34: Validar que el cargador está libre (isOccupied[_chargerId] == false)
        // TODO 35: Validar duración en rango
        // TODO 36: Calcular y validar el coste
        // TODO 37: Validar que msg.value == coste
        // TODO 38: Marcar el cargador como ocupado (isOccupied[_chargerId] = true)
        // TODO 39: Guardar el usuario en el mapping (currentUser[_chargerId] = msg.sender)
        // TODO 40: Calcular endTime y guardarlo (OPCIONAL)
        // TODO 41: Actualizar balance
        // TODO 42: Emitir evento
    }

    function endChargingSolution2(uint256 _chargerId) external {
        // TODO 43: Validar cargador existe
        // TODO 44: Validar está ocupado
        // TODO 45: Obtener el usuario
        // TODO 46: Marcar como no ocupado
        // TODO 47: Limpiar del mapping
        // TODO 48: Emitir evento
    }

    // ========== SOLUCIÓN 2: PAGO AL DESCONECTAR ==========
    /**
     * @notice Usuario se conecta sin pagar. Paga después cuando se desconecta
     * @param _chargerId ID del cargador
     */
    function connectChargerSolution2_PayLater(uint256 _chargerId) external {
        // TODO 49: Validaciones similares (existe, está libre)
        // TODO 50: Marcar como ocupado
        // TODO 51: Guardar usuario
        // TODO 52: Guardar cuándo se conectó: mapping(uint256 => uint256) connectionTime;
        //          connectionTime[_chargerId] = block.timestamp;
        // TODO 53: Emitir evento (sin endTime, solo connectionTime)
    }

    /**
     * @notice Usuario se desconecta y paga por lo que consumió
     * @param _chargerId ID del cargador
     */
    function disconnectChargerSolution2_PayNow(uint256 _chargerId) external {
        // TODO 54: Validar que el cargador está ocupado
        // TODO 55: Obtener el usuario conectado
        // TODO 56: Obtener cuándo se conectó
        // TODO 57: Calcular tiempo transcurrido: (block.timestamp - connectionTime[_chargerId]) / 60
        // TODO 58: Calcular coste total: tiempoMinutos * costPerMinute
        // TODO 59: ¿Qué pasa si el usuario no tiene fondos?
        //          - OPCIÓN A: Revertir la transacción
        //          - OPCIÓN B: Permitir débito (usuario debe depositar fondos después)
        //          Para aprender, prueba OPCIÓN A: require(msg.sender envió suficiente antes)
        // TODO 60: Si todo OK, restar del balance del usuario (mapping(address => uint256) userBalance)
        // TODO 61: Liberar el cargador
        // TODO 62: Emitir evento con coste real
    }

    // ========== ADMIN ==========
    function withdrawFunds() external onlyAdmin {
        // TODO 63: Similar a V1, retira fondos
        uint256 amountToWithdraw = balance;
        balance = 0;
        (bool success, ) = admin.call{value: amountToWithdraw}("");
        require(success, "Transferencia fallida");
        emit WithdrawalMade(admin, amountToWithdraw);
    }

    // ========== VIEW ==========
    function getChargerStatus(uint256 _chargerId) external view returns (address) {
        return isOccupied[_chargerId] ? currentUser[_chargerId] : address(0);
    }

    function getBalance() external view returns (uint256) {
        return balance;
    }

    function getNumChargers() external view returns (uint256) {
        return numChargers;
    }
}

// ============================================================================
// VERSIÓN 3: MAPPING + BITMASK (Ulttra-optimizado para <32 cargadores)
// ============================================================================

contract EVChargingV3_Bitmask {
    // ========== EVENTOS ==========
    event ChargingStarted(
        uint256 indexed chargerId,
        address indexed user,
        uint256 timestamp,
        uint256 endTime
    );
    
    event ChargingEnded(
        uint256 indexed chargerId,
        address indexed user,
        uint256 amountCharged
    );
    
    event WithdrawalMade(address indexed admin, uint256 amount);

    // ========== VARIABLES DE ESTADO ==========
    address private admin;
    uint256 private costPerMinute;
    uint256 private numChargers;
    uint256 private balance;

    // TODO 64: Mapping para guardar quién usa cada cargador
    // Pista: mapping(uint256 => address) currentUser;

    // TODO 65: uint256 donde cada bit representa si un cargador está ocupado
    // Pista: uint256 occupiedMask;
    //        Bit 0 = cargador 0
    //        Bit 1 = cargador 1
    //        Bit 31 = cargador 31
    //        Si bit está en 1 -> cargador ocupado
    //        Si bit está en 0 -> cargador libre

    // ========== CONSTRUCTOR ==========
    constructor(uint256 _numChargers, uint256 _costPerMinute) {
        require(_numChargers <= 32, "Máximo 32 cargadores con bitmask");
        admin = msg.sender;
        costPerMinute = _costPerMinute;
        numChargers = _numChargers;
        occupiedMask = 0; // Todos los cargadores libres (todos los bits en 0)
    }

    // ========== MODIFIERS ==========
    modifier onlyAdmin() {
        require(msg.sender == admin, "Solo admin");
        _;
    }

    // ========== FUNCIONES AUXILIARES PARA BITMASK ==========
    /**
     * @notice Retorna true si el bit en posición i está activo (1)
     * @param _mask el uint256 que queremos chequear
     * @param _position la posición del bit (0-31)
     */
    function isBitSet(uint256 _mask, uint256 _position) internal pure returns (bool) {
        // TODO 66: Implementa la función para chequear si un bit está en 1
        // Pista: return (_mask & (1 << _position)) != 0;
        //        Explicación:
        //        - (1 << _position) crea un número con SOLO el bit en _position activo
        //        - (_mask & ...) hace AND lógico
        //        - Si ese bit está activo en _mask, el resultado no es 0
        return false; // REEMPLAZA ESTO
    }

    /**
     * @notice Activa el bit en posición i (lo pone en 1)
     */
    function setBit(uint256 _mask, uint256 _position) internal pure returns (uint256) {
        // TODO 67: Implementa para activar un bit
        // Pista: return _mask | (1 << _position);
        //        | es OR lógico
        return _mask;
    }

    /**
     * @notice Desactiva el bit en posición i (lo pone en 0)
     */
    function clearBit(uint256 _mask, uint256 _position) internal pure returns (uint256) {
        // TODO 68: Implementa para desactivar un bit
        // Pista: return _mask & ~(1 << _position);
        //        ~ es NOT lógico (invierte todos los bits)
        return _mask;
    }

    // ========== FUNCIONES SOLUCIÓN 1: PREPAGO (SARE) ==========
    function reserveChargerSolution3(
        uint256 _chargerId,
        uint256 _durationMinutes,
        uint256 _minDuration,
        uint256 _maxDuration
    ) external payable {
        // TODO 69: Validar que el cargador existe
        // TODO 70: Validar que el cargador está libre (usa isBitSet)
        //          require(!isBitSet(occupiedMask, _chargerId), "Cargador ocupado");
        // TODO 71: Validar duración en rango
        // TODO 72: Calcular y validar coste
        // TODO 73: Marcar el cargador como ocupado usando setBit
        //          occupiedMask = setBit(occupiedMask, _chargerId);
        // TODO 74: Guardar usuario en mapping
        // TODO 75: Actualizar balance
        // TODO 76: Emitir evento
    }

    function endChargingSolution3(uint256 _chargerId) external {
        // TODO 77: Validar que existe
        // TODO 78: Validar que está ocupado (usa isBitSet)
        // TODO 79: Obtener usuario
        // TODO 80: Liberar el cargador usando clearBit
        //          occupiedMask = clearBit(occupiedMask, _chargerId);
        // TODO 81: Limpiar mapping
        // TODO 82: Emitir evento
    }

    // ========== ADMIN ==========
    function withdrawFunds() external onlyAdmin {
        uint256 amountToWithdraw = balance;
        balance = 0;
        (bool success, ) = admin.call{value: amountToWithdraw}("");
        require(success, "Transferencia fallida");
        emit WithdrawalMade(admin, amountToWithdraw);
    }

    // ========== VIEW ==========
    function getChargerStatus(uint256 _chargerId) external view returns (address) {
        return isBitSet(occupiedMask, _chargerId) ? currentUser[_chargerId] : address(0);
    }

    function getBalance() external view returns (uint256) {
        return balance;
    }

    function getNumChargers() external view returns (uint256) {
        return numChargers;
    }

    /**
     * @notice Retorna el bitmask completo (útil para debugging)
     */
    function getOccupiedMask() external view returns (uint256) {
        return occupiedMask;
    }
}

// ============================================================================
// ANÁLISIS DE GAS Y COMPARACIÓN
// ============================================================================
/**
 * RESUMEN: Por qué cada versión es diferente
 * 
 * V1 (Array):
 *   PROS: Muy simple de entender
 *   CONTRAS: 
 *   - Almacenar un address (32 bytes) por cada cargador
 *   - Para buscar un libre, tienes que iterar TODO el array (CARO si 32 cargadores)
 *   - Acceso: ~22k gas por lectura
 * 
 * V2 (Mapping + Bool):
 *   PROS:
 *   - Mapping tiene acceso O(1) en gas (constante, ~2.1k gas por lectura)
 *   - Array de bool es más compacto (1 byte por bool vs 32 bytes por address)
 *   CONTRAS:
 *   - Todavía ocupas 1 byte por cargador en el array
 *   - Dos estructuras que actualizar (mapping + array)
 * 
 * V3 (Mapping + Bitmask):
 *   PROS:
 *   - UN SOLO uint256 para TODOS los cargadores (<32)
 *   - Acceso a ocupación es O(1) y MEGA rápido (operaciones de bits)
 *   - Gas de almacenamiento = 1 slot de 32 bytes para TODOS (vs 32 bools = 1 slot cada uno)
 *   CONTRAS:
 *   - Límite de 32 cargadores
 *   - Código más complejo (operaciones de bits asusta)
 * 
 * COSTES APROXIMADOS (para <32 cargadores):
 *   V1: ~25k gas por operación (iteración + acceso)
 *   V2: ~5k gas por operación (acceso mapping + bool)
 *   V3: ~2.5k gas por operación (operaciones de bits)
 * 
 * CONCLUSIÓN:
 *   - <10 cargadores: V1 está OK
 *   - 10-20 cargadores: V2 es buen balance
 *   - 20-32 cargadores: V3 es la mejor
 */
