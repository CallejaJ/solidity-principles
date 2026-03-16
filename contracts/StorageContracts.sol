// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

// ------------------------------------------------
// Storage1 - Multiplicar el valor guardado por uno nuevo
// Tiene dos formas de hacer la multiplicacion:
//   - una funcion pure (necesita los dos numeros)
//   - una funcion view (solo necesita el nuevo, el otro lo lee sola)
// ------------------------------------------------

contract Storage1 {
    uint storedData;

    // pure: le pasamos los dos numeros, no toca nada del contrato
    function multiplicar(uint a, uint b) public pure returns (uint) {
        return a * b;
    }

    // view: solo le pasamos el nuevo numero, ella sola lee storedData
    function multiplicarConEstado(uint x) public view returns (uint) {
        return storedData * x;
    }

    // guarda el resultado de multiplicar lo que habia por lo nuevo
    function set(uint x) public {
        storedData = multiplicar(storedData, x);
    }

    function get() public view returns (uint) {
        return storedData;
    }
}

// ------------------------------------------------
// Storage2 - Igual que el anterior, pero aqui miramos el gas
//
// Lo importante:
// - set() SI gasta gas porque escribe en el almacenamiento (SSTORE)
//   la primera vez que guardas algo cuesta como 20000 gas
//   si ya habia algo guardado cuesta menos, como 5000
// - multiplicar() y multiplicarConEstado() NO gastan gas
//   porque no cambian nada, solo calculan
//   en Remix se puede ver que el coste es 0 cuando las llamas
// ------------------------------------------------

contract Storage2 {
    uint storedData;

    function multiplicar(uint a, uint b) public pure returns (uint) {
        return a * b;
    }

    function multiplicarConEstado(uint x) public view returns (uint) {
        return storedData * x;
    }

    function set(uint x) public {
        storedData = multiplicar(storedData, x);
    }

    function get() public view returns (uint) {
        return storedData;
    }
}

// ------------------------------------------------
// Storage3 - Comprobar errores: overflow y division por cero
//
// Desde Solidity 0.8 ya no hace falta preocuparse tanto:
// - si sumas dos numeros muy grandes y se pasa del maximo, revierte solo
// - si restas y el resultado seria negativo, revierte solo
// - si divides entre 0, revierte solo
// De todas formas añado un require en la division como ejemplo
// ------------------------------------------------

contract Storage3 {
    uint storedData;

    function sumar(uint a, uint b) public pure returns (uint) {
        return a + b; // si se pasa del maximo, revierte
    }

    function restar(uint a, uint b) public pure returns (uint) {
        return a - b; // si b es mayor que a, revierte
    }

    function multiplicar(uint a, uint b) public pure returns (uint) {
        return a * b; // si el resultado es demasiado grande, revierte
    }

    function dividir(uint a, uint b) public pure returns (uint) {
        require(b != 0, "No se puede dividir entre cero");
        return a / b;
    }

    // versiones view (leen storedData)
    function sumarView(uint x) public view returns (uint) {
        return storedData + x;
    }

    function restarView(uint x) public view returns (uint) {
        return storedData - x;
    }

    function multiplicarView(uint x) public view returns (uint) {
        return storedData * x;
    }

    function dividirView(uint x) public view returns (uint) {
        require(x != 0, "No se puede dividir entre cero");
        return storedData / x;
    }

    function set(uint x) public {
        storedData = multiplicar(storedData, x);
    }

    function get() public view returns (uint) {
        return storedData;
    }
}

// ------------------------------------------------
// Storage4 - Ver si el tipo de dato cambia el coste
//
// La maquina virtual de Ethereum siempre usa bloques de 256 bits
// asi que da igual si guardas un uint8 o un uint256,
// el slot ocupa lo mismo y el gas es parecido
// De hecho uint8 puede salir un poco mas caro porque tiene que
// hacer operaciones extra para limpiar los bits que sobran
//
// La unica ventaja de tipos pequeños es si metes varios
// en el mismo slot (storage packing), pero eso es otro tema
// ------------------------------------------------

contract Storage4 {
    uint8 dato8;
    uint16 dato16;
    uint128 dato128;
    uint256 dato256;

    function setUint8(uint8 x) public {
        dato8 = x;
    }

    function setUint16(uint16 x) public {
        dato16 = x;
    }

    function setUint128(uint128 x) public {
        dato128 = x;
    }

    function setUint256(uint256 x) public {
        dato256 = x;
    }

    function getUint8() public view returns (uint8) {
        return dato8;
    }

    function getUint16() public view returns (uint16) {
        return dato16;
    }

    function getUint128() public view returns (uint128) {
        return dato128;
    }

    function getUint256() public view returns (uint256) {
        return dato256;
    }
}

// ------------------------------------------------
// Storage5 - Solo quien guarda el valor puede leerlo
// Si lo intenta otro usuario, recibe 0
// ------------------------------------------------

contract Storage5 {
    uint storedData;
    address escritor; // quien fue el ultimo en escribir

    function multiplicar(uint a, uint b) public pure returns (uint) {
        return a * b;
    }

    function multiplicarView(uint x) public view returns (uint) {
        return storedData * x;
    }

    function set(uint x) public {
        storedData = multiplicar(storedData, x);
        escritor = msg.sender; // guardamos quien escribio
    }

    function get() public view returns (uint) {
        if (msg.sender == escritor) {
            return storedData;
        } else {
            return 0;
        }
    }
}

// ------------------------------------------------
// Storage6 - Añadimos un constructor para el valor inicial
// ------------------------------------------------

contract Storage6 {
    uint storedData;
    address escritor;

    // el constructor se ejecuta solo una vez, al desplegar el contrato
    constructor(uint valorInicial) {
        storedData = valorInicial;
        escritor = msg.sender;
    }

    function multiplicar(uint a, uint b) public pure returns (uint) {
        return a * b;
    }

    function multiplicarView(uint x) public view returns (uint) {
        return storedData * x;
    }

    function set(uint x) public {
        storedData = multiplicar(storedData, x);
        escritor = msg.sender;
    }

    function get() public view returns (uint) {
        if (msg.sender == escritor) {
            return storedData;
        } else {
            return 0;
        }
    }
}

// ------------------------------------------------
// Storage7 - Solo el que despliega el contrato puede cambiar valores
// Usamos un modifier para no repetir la comprobacion en cada funcion
// ------------------------------------------------

contract Storage7 {
    uint storedData;
    address escritor;
    address immutable propietario; // el que despliega, no cambia nunca

    // modifier: es como un filtro que se pone antes de ejecutar la funcion
    modifier soloPropietario() {
        require(msg.sender == propietario, "Solo el propietario puede hacer esto");
        _; // aqui se ejecuta la funcion que lleva el modifier
    }

    constructor(uint valorInicial) {
        propietario = msg.sender;
        storedData = valorInicial;
        escritor = msg.sender;
    }

    function multiplicar(uint a, uint b) public pure returns (uint) {
        return a * b;
    }

    function multiplicarView(uint x) public view returns (uint) {
        return storedData * x;
    }

    // solo el propietario puede llamar a set
    function set(uint x) public soloPropietario {
        storedData = multiplicar(storedData, x);
        escritor = msg.sender;
    }

    function get() public view returns (uint) {
        if (msg.sender == escritor) {
            return storedData;
        } else {
            return 0;
        }
    }

    function verPropietario() public view returns (address) {
        return propietario;
    }
}
