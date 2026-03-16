// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

// ------------------------------------------------
// Agenda1 - Cada entrada tiene una direccion ETH y un nombre
// Por ahora es una agenda global, sin distinguir usuarios
// ------------------------------------------------

contract Agenda1 {
    // esto es una entrada de la agenda
    struct Contact {
        address addr;
        string name;
    }

    // guardamos los contactos en un array
    Contact[] public contacts;

    // agregar un contacto
    function addContact(address _addr, string memory _name) public {
        contacts.push(Contact(_addr, _name));
    }

    // ver cuantos contactos hay
    function totalContacts() public view returns (uint) {
        return contacts.length;
    }

    // ver un contacto por su posicion en el array
    function getContact(uint index) public view returns (address, string memory) {
        require(index < contacts.length, "That contact does not exist");
        Contact memory c = contacts[index];
        return (c.addr, c.name);
    }
}

// ------------------------------------------------
// Agenda2 - Cada usuario tiene su propia agenda
// Usamos un mapping: cada direccion de usuario apunta a su array de contactos
// ------------------------------------------------

contract Agenda2 {
    struct Contact {
        address addr;
        string name;
    }

    // cada usuario (msg.sender) tiene su propio array de contactos
    mapping(address => Contact[]) books;

    function addContact(address _addr, string memory _name) public {
        books[msg.sender].push(Contact(_addr, _name));
    }

    function totalContacts() public view returns (uint) {
        return books[msg.sender].length;
    }

    function getContact(uint index) public view returns (address, string memory) {
        require(index < books[msg.sender].length, "That contact does not exist");
        Contact memory c = books[msg.sender][index];
        return (c.addr, c.name);
    }
}

// ------------------------------------------------
// Agenda3 - Cada usuario solo puede ver, editar y borrar SUS contactos
// Como usamos msg.sender como clave del mapping, ya esta resuelto:
//   nadie puede acceder al array de otro usuario
// Agregamos funciones para editar y borrar
// ------------------------------------------------

contract Agenda3 {
    struct Contact {
        address addr;
        string name;
    }

    mapping(address => Contact[]) books;

    function addContact(address _addr, string memory _name) public {
        books[msg.sender].push(Contact(_addr, _name));
    }

    function totalContacts() public view returns (uint) {
        return books[msg.sender].length;
    }

    function getContact(uint index) public view returns (address, string memory) {
        require(index < books[msg.sender].length, "That contact does not exist");
        Contact memory c = books[msg.sender][index];
        return (c.addr, c.name);
    }

    // editar un contacto existente
    function editContact(uint index, address _newAddr, string memory _newName) public {
        require(index < books[msg.sender].length, "That contact does not exist");
        books[msg.sender][index].addr = _newAddr;
        books[msg.sender][index].name = _newName;
    }

    // borrar un contacto: movemos el ultimo al hueco y quitamos el ultimo
    // asi no dejamos huecos vacios en el array
    function deleteContact(uint index) public {
        uint total = books[msg.sender].length;
        require(index < total, "That contact does not exist");

        // si no es el ultimo, lo intercambiamos con el ultimo
        if (index < total - 1) {
            books[msg.sender][index] = books[msg.sender][total - 1];
        }
        // quitamos el ultimo elemento
        books[msg.sender].pop();
    }
}

// ------------------------------------------------
// Agenda4 - Delegar acceso de solo lectura a otro usuario por tiempo limitado
// El dueño de la agenda puede decir:
//   "le doy permiso a esta direccion para ver mi agenda hasta tal momento"
// ------------------------------------------------

contract Agenda4 {
    struct Contact {
        address addr;
        string name;
    }

    mapping(address => Contact[]) books;

    // permisos: dueño => (delegado => timestamp hasta cuando tiene acceso)
    mapping(address => mapping(address => uint)) permissions;

    function addContact(address _addr, string memory _name) public {
        books[msg.sender].push(Contact(_addr, _name));
    }

    function editContact(uint index, address _newAddr, string memory _newName) public {
        require(index < books[msg.sender].length, "That contact does not exist");
        books[msg.sender][index].addr = _newAddr;
        books[msg.sender][index].name = _newName;
    }

    function deleteContact(uint index) public {
        uint total = books[msg.sender].length;
        require(index < total, "That contact does not exist");
        if (index < total - 1) {
            books[msg.sender][index] = books[msg.sender][total - 1];
        }
        books[msg.sender].pop();
    }

    // dar permiso a alguien para ver mi agenda durante X segundos
    function grantAccess(address _delegate, uint _durationSeconds) public {
        permissions[msg.sender][_delegate] = block.timestamp + _durationSeconds;
    }

    // quitar el permiso antes de que expire
    function revokeAccess(address _delegate) public {
        permissions[msg.sender][_delegate] = 0;
    }

    // comprobar si alguien tiene permiso para ver la agenda de un dueño
    function hasAccess(address _owner, address _delegate) public view returns (bool) {
        return permissions[_owner][_delegate] > block.timestamp;
    }

    // ver cuantos contactos tiene una agenda
    // funciona para tu propia agenda o para una que te han delegado
    function totalContacts(address _owner) public view returns (uint) {
        require(
            _owner == msg.sender || permissions[_owner][msg.sender] > block.timestamp,
            "You don't have permission to see this book"
        );
        return books[_owner].length;
    }

    // ver un contacto de una agenda (propia o delegada)
    function getContact(address _owner, uint index) public view returns (address, string memory) {
        require(
            _owner == msg.sender || permissions[_owner][msg.sender] > block.timestamp,
            "You don't have permission to see this book"
        );
        require(index < books[_owner].length, "That contact does not exist");
        Contact memory c = books[_owner][index];
        return (c.addr, c.name);
    }
}

// ------------------------------------------------
// Agenda5 - Buscar por direccion o por nombre
// Recorremos el array del dueño buscando coincidencias
// ------------------------------------------------

contract Agenda5 {
    struct Contact {
        address addr;
        string name;
    }

    mapping(address => Contact[]) books;
    mapping(address => mapping(address => uint)) permissions;

    function addContact(address _addr, string memory _name) public {
        books[msg.sender].push(Contact(_addr, _name));
    }

    function editContact(uint index, address _newAddr, string memory _newName) public {
        require(index < books[msg.sender].length, "That contact does not exist");
        books[msg.sender][index].addr = _newAddr;
        books[msg.sender][index].name = _newName;
    }

    function deleteContact(uint index) public {
        uint total = books[msg.sender].length;
        require(index < total, "That contact does not exist");
        if (index < total - 1) {
            books[msg.sender][index] = books[msg.sender][total - 1];
        }
        books[msg.sender].pop();
    }

    function grantAccess(address _delegate, uint _durationSeconds) public {
        permissions[msg.sender][_delegate] = block.timestamp + _durationSeconds;
    }

    function revokeAccess(address _delegate) public {
        permissions[msg.sender][_delegate] = 0;
    }

    function hasAccess(address _owner, address _delegate) public view returns (bool) {
        return permissions[_owner][_delegate] > block.timestamp;
    }

    function totalContacts(address _owner) public view returns (uint) {
        require(
            _owner == msg.sender || permissions[_owner][msg.sender] > block.timestamp,
            "You don't have permission to see this book"
        );
        return books[_owner].length;
    }

    function getContact(address _owner, uint index) public view returns (address, string memory) {
        require(
            _owner == msg.sender || permissions[_owner][msg.sender] > block.timestamp,
            "You don't have permission to see this book"
        );
        require(index < books[_owner].length, "That contact does not exist");
        Contact memory c = books[_owner][index];
        return (c.addr, c.name);
    }

    // buscar un contacto por su direccion ETH
    // devuelve si se encontro, su posicion y su nombre
    function searchByAddress(address _owner, address _addr) public view returns (bool found, uint index, string memory name) {
        require(
            _owner == msg.sender || permissions[_owner][msg.sender] > block.timestamp,
            "You don't have permission to see this book"
        );

        for (uint i = 0; i < books[_owner].length; i++) {
            if (books[_owner][i].addr == _addr) {
                return (true, i, books[_owner][i].name);
            }
        }
        return (false, 0, "");
    }

    // buscar un contacto por nombre
    // en solidity no se pueden comparar strings con ==
    // asi que comparamos el hash de los dos strings con keccak256
    function searchByName(address _owner, string memory _name) public view returns (bool found, uint index, address addr) {
        require(
            _owner == msg.sender || permissions[_owner][msg.sender] > block.timestamp,
            "You don't have permission to see this book"
        );

        for (uint i = 0; i < books[_owner].length; i++) {
            if (keccak256(bytes(books[_owner][i].name)) == keccak256(bytes(_name))) {
                return (true, i, books[_owner][i].addr);
            }
        }
        return (false, 0, address(0));
    }
}
