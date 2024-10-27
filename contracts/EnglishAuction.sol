// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title EnglishAuction
 * @author HiH_DimaN
 * @notice Контракт, реализующий английский аукцион.
 */
contract EnglishAuction {

    /**
     * @dev Название предмета аукциона.
     */
    string public item; 

    /**
     * @dev Адрес продавца (неизменяемый).
     */
    address payable public immutable seller; 

    /**
     * @dev Время окончания аукциона.
     */
    uint256 public endAt; 

    /**
     * @dev Флаг, указывающий на начало аукциона.
     */
    bool public started; 

    /**
     * @dev Флаг, указывающий на окончание аукциона.
     */
    bool public ended; 

    /**
     * @dev Самая высокая ставка.
     */
    uint256 public highestBid; 

    /**
     * @dev Адрес участника, сделавшего самую высокую ставку.
     */
    address public highestBidder; 

    /**
     * @dev Отображение ставок участников.
     */
    mapping(address => uint256) public bids; 

    /**
     * @dev Событие, которое эмитируется при начале аукциона.
     * @param item Название предмета аукциона.
     * @param highestBid Начальная ставка.
     */
    event Start(string item, uint256 highestBid); 

    /**
     * @dev Событие, которое эмитируется при каждой новой ставке.
     * @param biddrer Адрес участника, сделавшего ставку.
     * @param bid Сумма ставки.
     */
    event Bid(address biddrer, uint256 bid); 

    /**
     * @dev Событие, которое эмитируется при окончании аукциона.
     * @param biddrer Адрес победителя аукциона.
     * @param bid Сумма выигрышной ставки.
     */
    event End(address biddrer, uint256 bid); 
    
    /**
     * @dev Событие, которое эмитируется при выводе средств.
     * @param sender Адрес участника, выводящего средства.
     * @param amount Сумма выводимых средств.
     */
    event Withdraw(address sender, uint256 amount); // Событие вывода средств

    /**
     * @dev Конструктор контракта.
     * @param _item Название предмета аукциона.
     * @param _startBid Начальная ставка.
     */
    constructor(string memory _item, uint256 _startBid) {
        item = _item; // Устанавливаем название предмета аукциона
        highestBid = _startBid; // Устанавливаем начальную ставку
        seller = payable(msg.sender); // Устанавливаем адрес продавца
    }

    /**
     * @dev Модификатор, который проверяет, что вызывающий является продавцом.
     */
    modifier onlySeller() {
        require(msg.sender == seller, "not a seller"); 
        _;
    }

    /**
     * @dev Модификатор, который проверяет, что аукцион уже начался.
     */
    modifier hasStarted() {
        require(started, "has not started yet"); 
        _;
    }

    /**
     * @dev Модификатор, который проверяет, что аукцион ещё не закончился.
     */
    modifier notEnded() {
        require(block.timestamp < endAt, "has ended"); // Проверяем, не закончился ли аукцион
        _;
    }

    /**
     * @dev Функция запуска аукциона.
     */
    function start() external onlySeller {
        require(!started, "has already started!"); // Проверяем, не начался ли уже аукцион
        started = true; // Устанавливаем флаг начала аукциона
        endAt = block.timestamp + 3 days; // Устанавливаем время окончания аукциона
        emit Start(item, highestBid); // Эмитируем событие начала аукциона
    }

    /**
     * @dev Функция совершения ставки.
     */
    function bid() external payable hasStarted notEnded {
        require(msg.value > highestBid, "too low"); // Проверяем, больше ли новая ставка текущей
        if (highestBidder != address(0)) { // Если уже была сделана ставка
            bids[highestBidder] += highestBid; // Возвращаем предыдущую ставку
        }
        highestBid = msg.value; // Устанавливаем новую ставку
        highestBidder = msg.sender; // Устанавливаем адрес участника, сделавшего ставку
        emit Bid(msg.sender, msg.value); // Эмитируем событие новой ставки
    }

    /**
     * @dev Функция окончания аукциона.
     */
    function end() external hasStarted {
        require(!ended, "already ended"); // Проверяем, не закончился ли аукцион
        require(block.timestamp >= endAt, "can't stop auction yet"); // Проверяем, истекло ли время аукциона
        ended = true; // Устанавливаем флаг окончания аукциона
        if (highestBidder != address(0)) { // Если была сделана ставка
            seller.transfer(highestBid); // Переводим средства продавцу
        }
        emit End(highestBidder, highestBid); // Эмитируем событие окончания аукциона
    }

    /**
     * @dev Функция вывода средств.
     */
    function withdraw() external {
        uint256 refundAmount = bids[msg.sender]; // Получаем сумму возврата
        require(refundAmount > 0, "incorrect amount"); // Проверяем, есть ли средства для возврата
        bids[msg.sender] = 0; // Обнуляем сумму возврата
        payable(msg.sender).transfer(refundAmount); // Возвращаем средства
        emit Withdraw(msg.sender, refundAmount); // Эмитируем событие вывода средств
    }
}