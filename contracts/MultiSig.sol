// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title IterMapping
 * @dev Контракт, реализующий мультиподписной кошелек с функцией итерируемого отображения.
 * @notice Контракт MultiSig обеспечивает возможность выполнения транзакции, только если она была подтверждена несколькими владельцами.
 * @dev Данный контракт расширяет функциональность через контракт Ownable, который задает владельцев и проверяет их полномочия.
 * @author HiH_DimaN
 */
contract Ownable {
    address[] public owners; // Массив владельцев контракта
    mapping(address => bool) public isOwner; // Карта для проверки статуса владельца по адресу

    /**
     * @dev Устанавливает владельцев контракта при развертывании.
     * @param _owners Массив адресов владельцев.
     */
    constructor(address[] memory _owners) { // Конструктор, принимающий массив адресов владельцев
        require(_owners.length > 0, "no owners!"); // Проверка, что количество владельцев больше нуля
        for(uint i = 0; i < _owners.length; i++) { // Проход по каждому адресу в массиве
            address owner = _owners[i]; // Получение текущего адреса владельца
            require(owner != address(0), "zero address!"); // Проверка, что адрес не нулевой
            require(!isOwner[owner], "not unique!"); // Проверка, что адрес уникальный

            owners.push(owner); // Добавление адреса в массив владельцев
            isOwner[owner] = true; // Установка статуса владельца на true
        }
    }

    /**
     * @dev Модификатор, разрешающий выполнение функции только владельцам.
     */
    modifier onlyOwners() { // Модификатор для функций, доступных только владельцам
        require(isOwner[msg.sender], "not an owner"); // Проверка, что отправитель является владельцем
        _; // Продолжение выполнения функции
    }
}

/**
 * @title MultiSig
 * @dev Контракт мультиподписного кошелька с возможностью утверждения и выполнения транзакций.
 */
contract MultiSig is Ownable {
    uint public requiredApprovals; // Количество необходимых подтверждений
    struct Transaction { // Структура для хранения информации о транзакции
        address _to; // Адрес назначения для транзакции
        uint _value; // Сумма, которая будет отправлена
        bytes _data; // Данные для выполнения транзакции
        bool _executed; // Статус выполнения транзакции
    }

    Transaction[] public transactions; // Массив транзакций
    mapping(uint => uint) public approvalsCount; // Карта для хранения числа подтверждений для каждой транзакции
    mapping(uint => mapping(address => bool)) public approved; // Карта подтверждений по транзакциям и адресам

    event Deposit(address indexed _from, uint _amount); // Событие для депозита средств
    event Submit(uint indexed _txId); // Событие подачи транзакции
    event Approve(address indexed _owner, uint indexed _txId); // Событие утверждения транзакции
    event Revoke(address indexed _owner, uint indexed _txId); // Событие отзыва утверждения
    event Executed(uint indexed _txId); // Событие выполнения транзакции

    /**
     * @dev Конструктор, устанавливающий владельцев и необходимое количество подтверждений.
     * @param _owners Адреса владельцев.
     * @param _requiredApprovals Необходимое количество подтверждений.
     */
    constructor(address[] memory _owners, uint _requiredApprovals) Ownable(_owners) { // Конструктор контракта MultiSig
        require(_requiredApprovals > 0 && _requiredApprovals <= _owners.length, "invalid approvals count"); // Проверка допустимого числа подтверждений
        requiredApprovals = _requiredApprovals; // Установка количества необходимых подтверждений
    }

    /**
     * @dev Отправка новой транзакции на утверждение.
     * @param _to Адрес получателя.
     * @param _value Сумма перевода.
     * @param _data Данные транзакции.
     */
    function submit(address _to, uint _value, bytes calldata _data) external onlyOwners { // Функция подачи новой транзакции
        Transaction memory newTx = Transaction({ // Создание новой транзакции
            _to: _to, // Установка адреса назначения
            _value: _value, // Установка суммы перевода
            _data: _data, // Установка данных транзакции
            _executed: false // Установка статуса выполнения на false
        });
        transactions.push(newTx); // Добавление транзакции в массив
        emit Submit(transactions.length - 1); // Вызов события Submit с ID транзакции
    }

    /**
     * @dev Функция для внесения депозита в контракт.
     */
    function deposit() public payable { // Функция депозита средств на контракт
        emit Deposit(msg.sender, msg.value); // Вызов события Deposit с информацией о депозите
    }

    /**
     * @dev Кодирует данные для вызова функции.
     * @param _func Название функции.
     * @param _arg Аргумент функции.
     * @return Закодированные данные.
     */
    function encode(string memory _func, string memory _arg) public pure returns(bytes memory) { // Функция кодирования данных для вызова
        return abi.encodeWithSignature(_func, _arg); // Кодирование данных с использованием сигнатуры функции
    }

    modifier txExists(uint _txId) { // Модификатор для проверки существования транзакции
        require(_txId < transactions.length, "not exist!"); // Проверка, что ID транзакции существует
        _;
    }

    modifier notApproved(uint _txId) { // Модификатор для проверки, что транзакция еще не подтверждена
        require(!_isApproved(_txId, msg.sender), "tx already approved!"); // Проверка, что транзакция еще не подтверждена
        _;
    }

    /**
     * @dev Проверяет, был ли подтвержден адресом.
     * @param _txId ID транзакции.
     * @param _adr Адрес, проверяющий наличие подтверждения.
     * @return bool Было ли подтверждено.
     */
    function _isApproved(uint _txId, address _adr) private view returns(bool) { // Функция для проверки, что транзакция подтверждена
        return approved[_txId][_adr]; // Возвращает результат подтверждения транзакции данным адресом
    }

    modifier notExecuted(uint _txId) { // Модификатор для проверки, что транзакция не была выполнена
        require(!transactions[_txId]._executed, "tx already executed!"); // Проверка, что транзакция еще не выполнена
        _;
    }

    modifier wasApproved(uint _txId) { // Модификатор для проверки, что транзакция была подтверждена
        require(_isApproved(_txId, msg.sender), "tx not yet approved!"); // Проверка, что транзакция подтверждена
        _;
    }

    /**
     * @dev Подтверждает транзакцию.
     * @param _txId ID транзакции.
     */
    function approve(uint _txId) external onlyOwners txExists(_txId) notApproved(_txId) notExecuted(_txId) { // Функция подтверждения транзакции
        approved[_txId][msg.sender] = true; // Установка подтверждения для данной транзакции и адреса
        approvalsCount[_txId] += 1; // Увеличение количества подтверждений
        emit Approve(msg.sender, _txId); // Вызов события Approve
    }

    /**
     * @dev Отзывает подтверждение транзакции.
     * @param _txId ID транзакции.
     */
    function revoke(uint _txId) external onlyOwners txExists(_txId) notExecuted(_txId) wasApproved(_txId) { // Функция отзыва подтверждения
        approved[_txId][msg.sender] = false; // Установка флага подтверждения в false
        approvalsCount[_txId] -= 1; // Уменьшение количества подтверждений
        emit Revoke(msg.sender, _txId); // Вызов события Revoke
    }

    modifier enoughApprovals(uint _txId) { // Модификатор для проверки наличия достаточного числа подтверждений
        require(approvalsCount[_txId] >= requiredApprovals, "not enough approvals!"); // Проверка, что количество подтверждений достаточно
        _;
    }

    /**
     * @dev Выполняет транзакцию, если собрано достаточно подтверждений.
     * @param _txId ID транзакции.
     */
    function execute(uint _txId) external txExists(_txId) notExecuted(_txId) enoughApprovals(_txId) { // Функция выполнения транзакции
        Transaction storage myTx = transactions[_txId]; // Получение транзакции из массива

        (bool success,) = myTx._to.call{value: myTx._value}(myTx._data); // Вызов транзакции с переводом средств и данных
        require(success, "tx failed"); // Проверка успешности выполнения

        myTx._executed = true; // Установка статуса выполнения транзакции
        emit Executed(_txId); // Вызов события Executed
    }

    /**
     * @dev Функция для получения средств контрактом.
     */
    receive() external payable { // Функция получения средств контрактом
        deposit(); // Вызов функции депозита
    }
}

contract Receiver { // Контракт-получатель для тестирования перевода средств и сообщений
    string public message; // Переменная для хранения сообщения

    /**
     * @dev Возвращает баланс контракта.
     * @return Баланс контракта.
     */
    function getBalance() public view returns(uint) { // Функция для получения баланса контракта
        return address(this).balance; // Возвращает баланс данного контракта
    }

    /**
     * @dev Получает сообщение и средства.
     * @param _msg Сообщение.
     */
    function getMoney(string memory _msg) external payable { // Функция для получения сообщения и средств
        message = _msg; // Сохраняет полученное сообщение в переменной
    }
}
