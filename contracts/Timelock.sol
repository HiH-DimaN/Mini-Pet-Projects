// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.20;

/**
 * @title Timelick
 * @author HiH_DimaN
 * @notice Контракт для отложенного выполнения транзакций.
 */
contract Timelock {
    /**
     * @dev Адрес владельца контракта.
     */
    address public owner; 

    /**
     * @dev Минимальная задержка для отложенной транзакции.
     */
    uint256 public constant MIN_DELAY = 10; 

    /**
     * @dev Максимальная задержка для отложенной транзакции.
     */
    uint256 public constant MAX_DELAY = 100; 

    /**
     * @dev Срок действия отложенной транзакции.
     */
    uint256 public constant EXPIRY_DELAY = 1000; 

    /**
     * @dev Отображение отложенных транзакций.
     */
    mapping(bytes32 => bool) public queuedTxs; 

    /**
     * @dev Событие, которое эмитируется при постановке транзакции в очередь.
     * @param txId Идентификатор транзакции.
     * @param to Адрес получателя транзакции.
     * @param value Сумма транзакции.
     * @param func Имя функции, которая будет вызвана.
     * @param data Данные для функции.
     * @param timestamp Время выполнения транзакции.
     */
    event Queued(
        bytes32 indexed txId, 
        address indexed to, 
        uint256 value, 
        string func, 
        bytes data, 
        uint256 timestamp
    ); // Событие постановки в очередь

    /**
     * @dev Событие, которое эмитируется при выполнении отложенной транзакции.
     * @param txId Идентификатор транзакции.
     * @param to Адрес получателя транзакции.
     * @param value Сумма транзакции.
     * @param func Имя функции, которая была вызвана.
     * @param data Данные для функции.
     * @param timestamp Время выполнения транзакции.
     */
    event Executed(
        bytes32 indexed txId, 
        address indexed to, 
        uint256 value, 
        string func, 
        bytes data, 
        uint256 timestamp
    ); 

    /**
     * @dev Конструктор контракта.
     */
    constructor() {
        owner = msg.sender; // Устанавливаем владельца
    }

    /**
     * @dev Модификатор, который проверяет, что вызывающий является владельцем.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, "not an owner!"); 
        _;
    }

    /**
     * @dev Функция постановки транзакции в очередь.
     * @param _to Адрес получателя транзакции.
     * @param _value Сумма транзакции.
     * @param _func Имя функции, которая будет вызвана.
     * @param _data Данные для функции.
     * @param _timestamp Время выполнения транзакции.
     * @return txId Идентификатор транзакции.
     */
    function queue(
        address _to, 
        uint256 _value, 
        string calldata _func,
        bytes calldata _data, 
        uint256 _timestamp
    ) external onlyOwner returns(bytes32) {
        bytes32 txId = keccak256(
            abi.encode(
                _to, _value, _func, _data, _timestamp
            )
        ); // Генерируем идентификатор транзакции
        require(!queuedTxs[txId], "already queued!"); // Проверяем, не была ли транзакция уже поставлена в очередь
        require(
            _timestamp >= block.timestamp + MIN_DELAY && 
            _timestamp <= block.timestamp + MAX_DELAY,
            "invalid timestamp!"
        ); // Проверяем, находится ли время выполнения в допустимом диапазоне

        queuedTxs[txId] = true; // Отмечаем, что транзакция была поставлена в очередь

        emit Queued(
            txId, 
            _to, 
            _value, 
            _func, 
            _data,
            _timestamp
        ); // Эмитируем событие постановки в очередь

        return txId; // Возвращаем идентификатор транзакции
    }

    /**
     * @dev Функция выполнения отложенной транзакции.
     * @param _to Адрес получателя транзакции.
     * @param _value Сумма транзакции.
     * @param _func Имя функции, которая будет вызвана.
     * @param _data Данные для функции.
     * @param _timestamp Время выполнения транзакции.
     * @return resp Результат выполнения транзакции.
     */
    function execute(
        address _to, 
        uint256 _value, 
        string calldata _func,
        bytes calldata _data, 
           uint256 _timestamp
    ) external payable onlyOwner returns(bytes memory) {
        bytes32 txId = keccak256(
            abi.encode(
                _to, _value, _func, _data, _timestamp
            )
        ); // Генерируем идентификатор транзакции
        require(queuedTxs[txId], "notdy queued!"); // Проверяем, была ли транзакция поставлена в очередь
        require(block.timestamp >= _timestamp,"too early"); // Проверяем, не наступило ли время выполнения
        require(block.timestamp <= _timestamp + EXPIRY_DELAY,"too late"); // Проверяем, не истек ли срок действия

        delete queuedTxs[txId]; // Удаляем транзакцию из очереди

        bytes memory data; // Создаем массив байт для данных
        if(bytes(_func).length > 0) { // Если есть имя функции
            data = abi.encodePacked(
                bytes4(keccak256(bytes(_func))), _data
            ); // Кодируем имя функции и данные
        } else {
            data = _data; // Иначе используем только данные
        }

        (bool success, bytes memory resp) = _to.call{value: _value}(data); // Выполняем транзакцию

        require(success, "tx failed!"); // Проверяем, что транзакция была успешной

        emit Executed(
            txId, 
             _to, 
            _value, 
            _func, 
            _data,
            _timestamp
        ); // Эмитируем событие выполнения

        return resp; // Возвращаем результат выполнения
    }

    /**
     * @dev Функция отмены отложенной транзакции.
     * @param _txId Идентификатор транзакции.
     */
    function cancel(bytes32 _txId) external onlyOwner {
        require(queuedTxs[_txId], "notdy queued!"); // Проверяем, была ли транзакция поставлена в очередь

        delete queuedTxs[_txId]; // Удаляем транзакцию из очереди
    }    
}

/**
 * @title Runner
 * @author HiH_DimaN
 * @notice Контракт, который будет выполнять отложенные транзакции.
 */
contract Runner {
    /**
     * @dev Адрес контракта Timelick.
     */
    address public lock; 

    /**
     * @dev Сообщение, которое будет храниться в контракте.
     */
    string public message; 

    /**
     * @dev Отображение платежей, полученных от контракта Timelick.
     */
    mapping(address => uint) public payments; 

    /**
     * @dev Конструктор контракта.
     * @param _lock Адрес контракта Timelick.
     */
    constructor(address _lock) {
        lock = _lock;        // Устанавливаем адрес контракта Timelock
    }

    /**
     * @dev Функция, которая будет вызываться отложенной транзакцией.
     * @param newMsg Новое сообщение, которое будет сохранено.
     */
    function run(string memory newMsg) external payable {
        require(msg.sender == lock, "invalid address!"); // Проверяем, что вызывающий - контракт Timelock

        payments[msg.sender] += msg.value; // Добавляем платеж от Timelock
        message = newMsg; // Устанавливаем новое сообщение
    }

    /**
     * @dev Функция для получения времени выполнения отложенной транзакции.
     * @return Время выполнения отложенной транзакции.
     */
    function newTimestamp() external view returns(uint) {
        return block.timestamp + 20; // Возвращаем время выполнения
    }

    /**
     * @dev Функция для подготовки данных для отложенной транзакции.
     * @param _msg Новое сообщение, которое будет передано в отложенной транзакции.
     * @return data Данные для отложенной транзакции.
     */
    function prepareData(string calldata _msg) external view returns(bytes memory) {
        return abi.encode(_msg); // Кодируем сообщение в данные
    }

}