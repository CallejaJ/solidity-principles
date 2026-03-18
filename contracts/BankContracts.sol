// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

// ------------------------------------------------
// Bank1 - Lo mas basico: depositar, retirar y consultar saldo
// Cualquiera puede meter ETH y sacarlo cuando quiera
// ------------------------------------------------

contract Bank1 {
    // saldo de cada usuario
    mapping(address => uint) public balances;

    // depositar ETH: el usuario envia WEI con la transaccion
    function deposit() public payable {
        require(msg.value > 0, "Must send some ETH");
        balances[msg.sender] += msg.value;
    }

    // retirar ETH: el usuario pide sacar una cantidad
    function withdraw(uint _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Not enough balance");

        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    // consultar mi saldo
    function getMyBalance() public view returns (uint) {
        return balances[msg.sender];
    }
}

// ------------------------------------------------
// Bank2 - Prestamos basicos
// El banco presta dinero de los depositos
// Quien pide prestado entra en la lista de deudores
// No sale hasta que devuelve todo
// ------------------------------------------------

contract Bank2 {
    mapping(address => uint) public balances;
    mapping(address => uint) public debts;     // lo que debe cada uno
    mapping(address => bool) public isDebtor;  // si esta en la lista de deudores

    function deposit() public payable {
        require(msg.value > 0, "Must send some ETH");
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Not enough balance");
        // comprobar que el banco tiene suficiente dinero real
        require(address(this).balance >= _amount, "Bank does not have enough liquidity");

        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    // pedir un prestamo
    function borrow(uint _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        // el banco necesita tener ese dinero disponible
        require(address(this).balance >= _amount, "Bank does not have enough liquidity");

        debts[msg.sender] += _amount;
        isDebtor[msg.sender] = true;

        payable(msg.sender).transfer(_amount);
    }

    // devolver parte o todo el prestamo
    function repay() public payable {
        require(msg.value > 0, "Must send some ETH");
        require(isDebtor[msg.sender], "You have no debt");

        // si envia mas de lo que debe, devolver el sobrante
        if (msg.value > debts[msg.sender]) {
            uint change = msg.value - debts[msg.sender];
            debts[msg.sender] = 0;
            payable(msg.sender).transfer(change);
        } else {
            debts[msg.sender] -= msg.value;
        }

        // si ya no debe nada, sale de la lista de deudores
        if (debts[msg.sender] == 0) {
            isDebtor[msg.sender] = false;
        }
    }

    // consultar mi saldo
    function getMyBalance() public view returns (uint) {
        return balances[msg.sender];
    }

    // consultar la deuda de cualquier cuenta (es informacion publica)
    function getDebt(address _account) public view returns (uint) {
        return debts[_account];
    }

    // ver cuanto dinero real tiene el banco
    function getBankBalance() public view returns (uint) {
        return address(this).balance;
    }
}

// ------------------------------------------------
// Bank3 - Problema de liquidez
// Cuando el banco presta dinero puede que no quede para retirar
// Solucion: avisar al usuario de que el banco no tiene liquidez
// y permitir retiradas parciales (lo que haya disponible)
// ------------------------------------------------

contract Bank3 {
    mapping(address => uint) public balances;
    mapping(address => uint) public debts;
    mapping(address => bool) public isDebtor;

    function deposit() public payable {
        require(msg.value > 0, "Must send some ETH");
        balances[msg.sender] += msg.value;
    }

    // retirar: si el banco no tiene todo, retira lo que pueda
    function withdraw(uint _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Not enough balance");

        uint available = address(this).balance;
        if (available >= _amount) {
            // hay suficiente, retirada normal
            balances[msg.sender] -= _amount;
            payable(msg.sender).transfer(_amount);
        } else {
            // no hay suficiente, retirar lo que haya
            // el resto sigue en el saldo del usuario como "pendiente"
            balances[msg.sender] -= available;
            payable(msg.sender).transfer(available);
        }
    }

    function borrow(uint _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Bank does not have enough liquidity");

        debts[msg.sender] += _amount;
        isDebtor[msg.sender] = true;

        payable(msg.sender).transfer(_amount);
    }

    function repay() public payable {
        require(msg.value > 0, "Must send some ETH");
        require(isDebtor[msg.sender], "You have no debt");

        if (msg.value > debts[msg.sender]) {
            uint change = msg.value - debts[msg.sender];
            debts[msg.sender] = 0;
            payable(msg.sender).transfer(change);
        } else {
            debts[msg.sender] -= msg.value;
        }

        if (debts[msg.sender] == 0) {
            isDebtor[msg.sender] = false;
        }
    }

    function getMyBalance() public view returns (uint) {
        return balances[msg.sender];
    }

    function getDebt(address _account) public view returns (uint) {
        return debts[_account];
    }

    function getBankBalance() public view returns (uint) {
        return address(this).balance;
    }

    // ver cuanto puedo retirar realmente ahora mismo
    function getAvailableToWithdraw() public view returns (uint) {
        uint myBalance = balances[msg.sender];
        uint bankBalance = address(this).balance;
        if (bankBalance >= myBalance) {
            return myBalance;
        } else {
            return bankBalance;
        }
    }
}

// ------------------------------------------------
// Bank4 - ETH precargado en el constructor + coeficiente de caja
// El banco empieza con dinero propio (no pertenece a nadie)
// El coeficiente de caja es del 5%: el banco debe guardar
// al menos el 5% de los depositos totales y no puede prestarlo
// ------------------------------------------------

contract Bank4 {
    mapping(address => uint) public balances;
    mapping(address => uint) public debts;
    mapping(address => bool) public isDebtor;

    uint public totalDeposits;   // suma de todos los depositos
    uint public totalLoaned;     // suma de todos los prestamos activos
    uint public reserveRate;     // coeficiente de caja (5 = 5%)

    // el constructor recibe ETH al desplegar (dinero inicial del banco)
    constructor(uint _reserveRate) payable {
        require(_reserveRate > 0 && _reserveRate <= 100, "Rate must be between 1 and 100");
        reserveRate = _reserveRate;
    }

    function deposit() public payable {
        require(msg.value > 0, "Must send some ETH");
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }

    function withdraw(uint _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Not enough balance");

        uint available = address(this).balance;
        if (available >= _amount) {
            balances[msg.sender] -= _amount;
            totalDeposits -= _amount;
            payable(msg.sender).transfer(_amount);
        } else {
            balances[msg.sender] -= available;
            totalDeposits -= available;
            payable(msg.sender).transfer(available);
        }
    }

    // calcular cuanto puede prestar el banco
    // tiene que guardar el 5% de los depositos como reserva
    function getLoanableAmount() public view returns (uint) {
        uint reserve = (totalDeposits * reserveRate) / 100;
        uint bankBalance = address(this).balance;

        // el banco no puede prestar si lo que queda es menor que la reserva
        if (bankBalance <= reserve) {
            return 0;
        }
        return bankBalance - reserve;
    }

    function borrow(uint _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= getLoanableAmount(), "Exceeds loanable amount (reserve limit)");

        debts[msg.sender] += _amount;
        totalLoaned += _amount;
        isDebtor[msg.sender] = true;

        payable(msg.sender).transfer(_amount);
    }

    function repay() public payable {
        require(msg.value > 0, "Must send some ETH");
        require(isDebtor[msg.sender], "You have no debt");

        if (msg.value > debts[msg.sender]) {
            uint change = msg.value - debts[msg.sender];
            totalLoaned -= debts[msg.sender];
            debts[msg.sender] = 0;
            payable(msg.sender).transfer(change);
        } else {
            debts[msg.sender] -= msg.value;
            totalLoaned -= msg.value;
        }

        if (debts[msg.sender] == 0) {
            isDebtor[msg.sender] = false;
        }
    }

    function getMyBalance() public view returns (uint) {
        return balances[msg.sender];
    }

    function getDebt(address _account) public view returns (uint) {
        return debts[_account];
    }

    function getBankBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getAvailableToWithdraw() public view returns (uint) {
        uint myBalance = balances[msg.sender];
        uint bankBalance = address(this).balance;
        if (bankBalance >= myBalance) {
            return myBalance;
        } else {
            return bankBalance;
        }
    }
}

// ------------------------------------------------
// Bank5 - Limite individual de prestamo
// Solo puedes pedir prestado una cantidad proporcional
// al maximo saldo que hayas tenido en el banco
// Por ejemplo: si tu maximo saldo fue 10 ETH,
// puedes pedir prestado hasta 10 ETH (1:1)
// Esto incentiva a depositar antes de pedir prestado
// ------------------------------------------------

contract Bank5 {
    mapping(address => uint) public balances;
    mapping(address => uint) public debts;
    mapping(address => bool) public isDebtor;
    mapping(address => uint) public maxBalanceEver;  // el maximo saldo que ha tenido cada uno

    uint public totalDeposits;
    uint public totalLoaned;
    uint public reserveRate;

    constructor(uint _reserveRate) payable {
        require(_reserveRate > 0 && _reserveRate <= 100, "Rate must be between 1 and 100");
        reserveRate = _reserveRate;
    }

    function deposit() public payable {
        require(msg.value > 0, "Must send some ETH");
        balances[msg.sender] += msg.value;
        totalDeposits += msg.value;

        // actualizar el maximo saldo si es el mas alto hasta ahora
        if (balances[msg.sender] > maxBalanceEver[msg.sender]) {
            maxBalanceEver[msg.sender] = balances[msg.sender];
        }
    }

    function withdraw(uint _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(balances[msg.sender] >= _amount, "Not enough balance");

        uint available = address(this).balance;
        if (available >= _amount) {
            balances[msg.sender] -= _amount;
            totalDeposits -= _amount;
            payable(msg.sender).transfer(_amount);
        } else {
            balances[msg.sender] -= available;
            totalDeposits -= available;
            payable(msg.sender).transfer(available);
        }
    }

    function getLoanableAmount() public view returns (uint) {
        uint reserve = (totalDeposits * reserveRate) / 100;
        uint bankBalance = address(this).balance;

        if (bankBalance <= reserve) {
            return 0;
        }
        return bankBalance - reserve;
    }

    // cuanto puede pedir prestado este usuario como maximo
    // es igual a su maximo saldo historico menos lo que ya debe
    function getMyBorrowLimit() public view returns (uint) {
        uint maxAllowed = maxBalanceEver[msg.sender];
        uint currentDebt = debts[msg.sender];

        if (currentDebt >= maxAllowed) {
            return 0;
        }
        return maxAllowed - currentDebt;
    }

    function borrow(uint _amount) public {
        require(_amount > 0, "Amount must be greater than 0");
        require(_amount <= getLoanableAmount(), "Exceeds loanable amount (reserve limit)");
        require(_amount <= getMyBorrowLimit(), "Exceeds your personal borrow limit");

        debts[msg.sender] += _amount;
        totalLoaned += _amount;
        isDebtor[msg.sender] = true;

        payable(msg.sender).transfer(_amount);
    }

    function repay() public payable {
        require(msg.value > 0, "Must send some ETH");
        require(isDebtor[msg.sender], "You have no debt");

        if (msg.value > debts[msg.sender]) {
            uint change = msg.value - debts[msg.sender];
            totalLoaned -= debts[msg.sender];
            debts[msg.sender] = 0;
            payable(msg.sender).transfer(change);
        } else {
            debts[msg.sender] -= msg.value;
            totalLoaned -= msg.value;
        }

        if (debts[msg.sender] == 0) {
            isDebtor[msg.sender] = false;
        }
    }

    function getMyBalance() public view returns (uint) {
        return balances[msg.sender];
    }

    function getDebt(address _account) public view returns (uint) {
        return debts[_account];
    }

    function getBankBalance() public view returns (uint) {
        return address(this).balance;
    }

    function getAvailableToWithdraw() public view returns (uint) {
        uint myBalance = balances[msg.sender];
        uint bankBalance = address(this).balance;
        if (bankBalance >= myBalance) {
            return myBalance;
        } else {
            return bankBalance;
        }
    }
}
