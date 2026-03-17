// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

// ------------------------------------------------
// EVCharging1 - Base del sistema
// Solo el esqueleto: constructor con numero de cargadores,
// coste por minuto y administrador
// ------------------------------------------------

contract EVCharging1 {
    address public admin;
    uint public costPerMin;
    uint public totalChargers;

    constructor(uint _totalChargers, uint _costPerMin) {
        require(_totalChargers > 0 && _totalChargers < 32, "Must be between 1 and 31 chargers");
        require(_costPerMin > 0, "Cost must be greater than 0");

        admin = msg.sender;
        totalChargers = _totalChargers;
        costPerMin = _costPerMin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can do this");
        _;
    }

    // el admin puede sacar todo el dinero del contrato
    function withdraw() public onlyAdmin {
        uint bal = address(this).balance;
        require(bal > 0, "No funds to withdraw");
        payable(admin).transfer(bal);
    }

    // ver cuanto dinero tiene el contrato
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

// ------------------------------------------------
// EVCharging2 - Modelo PREPAGO (tipo zona azul)
// El usuario paga por adelantado un bono de X minutos
// El contrato emite un evento para que el cargador empiece
// Cuando pasa el tiempo, el cargador queda libre
// ------------------------------------------------

contract EVCharging2 {
    address public admin;
    uint public costPerMin;
    uint public totalChargers;
    uint public minDuration;    // minimo de minutos que puedes reservar
    uint public maxDuration;    // maximo de minutos que puedes reservar

    // informacion de cada cargador
    struct ChargerInfo {
        address user;       // quien lo esta usando
        uint endTime;       // cuando termina la reserva (timestamp)
    }

    // numero de cargador => info de quien lo usa
    mapping(uint => ChargerInfo) public chargers;

    // evento que se emite cuando alguien reserva un cargador
    // el sistema fisico escucha esto para empezar a cargar
    event ChargingStarted(
        uint indexed chargerId,
        address indexed user,
        uint duration,
        uint endTime
    );

    // evento cuando se libera un cargador
    event ChargingEnded(uint indexed chargerId, address indexed user);

    constructor(
        uint _totalChargers,
        uint _costPerMin,
        uint _minDuration,
        uint _maxDuration
    ) {
        require(_totalChargers > 0 && _totalChargers < 32, "Must be between 1 and 31 chargers");
        require(_costPerMin > 0, "Cost must be greater than 0");
        require(_minDuration > 0, "Min duration must be greater than 0");
        require(_maxDuration > _minDuration, "Max must be greater than min");

        admin = msg.sender;
        totalChargers = _totalChargers;
        costPerMin = _costPerMin;
        minDuration = _minDuration;
        maxDuration = _maxDuration;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can do this");
        _;
    }

    // comprobar si un cargador esta libre
    // esta libre si nunca se uso o si ya paso su tiempo
    function isAvailable(uint _id) public view returns (bool) {
        require(_id < totalChargers, "Charger does not exist");
        ChargerInfo memory info = chargers[_id];
        return info.user == address(0) || block.timestamp >= info.endTime;
    }

    // reservar un cargador pagando por adelantado
    // _id = numero de cargador, _dur = cuantos minutos quieres
    // hay que enviar WEI con la transaccion (msg.value)
    function startCharging(uint _id, uint _dur) public payable {
        require(_id < totalChargers, "Charger does not exist");
        require(isAvailable(_id), "Charger is busy");
        require(_dur >= minDuration, "Below minimum time");
        require(_dur <= maxDuration, "Above maximum time");

        // calcular cuanto cuesta
        uint totalCost = _dur * costPerMin;
        require(msg.value >= totalCost, "Not enough WEI sent");

        // si envio de mas, devolver el cambio
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }

        // guardar la reserva
        uint end = block.timestamp + (_dur * 60);
        chargers[_id] = ChargerInfo(msg.sender, end);

        // emitir evento para que el cargador fisico empiece
        emit ChargingStarted(_id, msg.sender, _dur, end);
    }

    // liberar un cargador manualmente (si el usuario quiere irse antes)
    // en prepago no se devuelve dinero, ya pago
    function stopCharging(uint _id) public {
        require(_id < totalChargers, "Charger does not exist");
        ChargerInfo memory info = chargers[_id];
        require(info.user == msg.sender, "Not your charger");

        delete chargers[_id];
        emit ChargingEnded(_id, msg.sender);
    }

    // ver cuanto tiempo le queda a un cargador (en segundos)
    function timeLeft(uint _id) public view returns (uint) {
        require(_id < totalChargers, "Charger does not exist");
        ChargerInfo memory info = chargers[_id];

        if (info.user == address(0) || block.timestamp >= info.endTime) {
            return 0;
        }
        return info.endTime - block.timestamp;
    }

    function withdraw() public onlyAdmin {
        uint bal = address(this).balance;
        require(bal > 0, "No funds to withdraw");
        payable(admin).transfer(bal);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}

// ------------------------------------------------
// EVCharging3 - Modelo POSTPAGO
// El usuario conecta el coche, carga, y cuando se va paga lo consumido
// El pago se hace al desconectar basandose en el tiempo real usado
// ------------------------------------------------

contract EVCharging3 {
    address public admin;
    uint public costPerMin;
    uint public totalChargers;

    struct ChargerInfo {
        address user;       // quien lo esta usando
        uint startTime;     // cuando empezo a cargar (timestamp)
    }

    mapping(uint => ChargerInfo) public chargers;

    event ChargingStarted(uint indexed chargerId, address indexed user, uint startTime);
    event ChargingEnded(uint indexed chargerId, address indexed user, uint usedMins, uint totalCost);

    constructor(uint _totalChargers, uint _costPerMin) {
        require(_totalChargers > 0 && _totalChargers < 32, "Must be between 1 and 31 chargers");
        require(_costPerMin > 0, "Cost must be greater than 0");

        admin = msg.sender;
        totalChargers = _totalChargers;
        costPerMin = _costPerMin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can do this");
        _;
    }

    // comprobar si un cargador esta libre
    function isAvailable(uint _id) public view returns (bool) {
        require(_id < totalChargers, "Charger does not exist");
        return chargers[_id].user == address(0);
    }

    // conectar el coche a un cargador (no paga nada todavia)
    function startCharging(uint _id) public {
        require(_id < totalChargers, "Charger does not exist");
        require(isAvailable(_id), "Charger is busy");

        chargers[_id] = ChargerInfo(msg.sender, block.timestamp);
        emit ChargingStarted(_id, msg.sender, block.timestamp);
    }

    // ver cuantos minutos lleva cargando
    function getUsedMins(uint _id) public view returns (uint) {
        require(_id < totalChargers, "Charger does not exist");
        ChargerInfo memory info = chargers[_id];
        require(info.user != address(0), "Charger is not in use");

        // dividimos entre 60 para pasar de segundos a minutos
        return (block.timestamp - info.startTime) / 60;
    }

    // ver cuanto costaria desconectar ahora
    function getCurrentCost(uint _id) public view returns (uint) {
        uint used = getUsedMins(_id);
        // minimo 1 minuto para que no sea gratis
        if (used == 0) {
            used = 1;
        }
        return used * costPerMin;
    }

    // desconectar el coche y pagar lo consumido
    // el usuario envia los WEI con esta transaccion
    function stopCharging(uint _id) public payable {
        require(_id < totalChargers, "Charger does not exist");
        ChargerInfo memory info = chargers[_id];
        require(info.user == msg.sender, "Not your charger");

        // calcular lo que debe
        uint used = (block.timestamp - info.startTime) / 60;
        if (used == 0) {
            used = 1;
        }
        uint totalCost = used * costPerMin;

        require(msg.value >= totalCost, "Not enough WEI sent");

        // devolver cambio si envio de mas
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }

        // liberar el cargador
        delete chargers[_id];
        emit ChargingEnded(_id, msg.sender, used, totalCost);
    }

    function withdraw() public onlyAdmin {
        uint bal = address(this).balance;
        require(bal > 0, "No funds to withdraw");
        payable(admin).transfer(bal);
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
