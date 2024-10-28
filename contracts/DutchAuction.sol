// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title DutchAuction
 * @author HiH_DimaN
 * @notice Контракт, реализующий голландский аукцион.
 */
contract DutchAuction {
    /**
     * @dev Продолжительность аукциона (1 день).
     */
    uint256 private constant DURATION = 1 days; 

    /**
     * @dev Адрес продавца (неизменяемый).
     */
    address payable public immutable seller; 

    /**
     * @dev Начальная цена предмета аукциона.
     */
    uint256 public immutable startingPrice; 

    /**
     * @dev Время начала аукциона.
     */
    uint256 public immutable startAt; 

    /**
     * @dev Время окончания аукциона.
     */
    uint256 public immutable endsAt; 

    /**
     * @dev Размер скидки за каждый блок времени.
     */
    uint256 public immutable discountRate; 

    /**
     * @dev Название предмета аукциона.
     */
    string public item; 
    
    /**
     * @dev Флаг, указывающий на то, что аукцион остановлен.
     */
    bool public stoped; 

    /**
     * @dev Конструктор контракта.
     * @param _startingPrice Начальная цена предмета аукциона.
     * @param _discountRate Размер скидки за каждый блок времени.
     * @param _item Название предмета аукциона.
     */
    constructor(
        uint256 _startingPrice, // Начальная цена предмета аукциона
        uint256 _discountRate, // Размер скидки за каждый блок времени
        string memory _item // Название предмета аукциона
    ) {
        seller = payable(msg.sender); // Устанавливаем адрес продавца
        startingPrice = _startingPrice; // Устанавливаем начальную цену
        discountRate = _discountRate; // Устанавливаем размер скидки
        startAt = block.timestamp; // Устанавливаем время начала аукциона
        endsAt = block.timestamp + DURATION; // Устанавливаем время окончания аукциона
        require(
            startingPrice >= _discountRate * DURATION, // Проверяем корректность начальной цены и скидки
            "starting price and discount is incorrect "
        );
        item = _item; // Устанавливаем название предмета аукциона
    }

    /**
     * @dev Модификатор, который проверяет, что аукцион не остановлен.
     */
    modifier notStoped() {
        require(!stoped, "stoped"); // Проверяем, что аукцион не остановлен
        _;
    }

    /**
     * @dev Функция получения текущей цены предмета аукциона.
     * @return Текущая цена предмета аукциона.
     */
    function getPrice() public view notStoped returns (uint256) {
        uint256 timeElapsed = block.timestamp - startAt; // Время, прошедшее с начала аукциона
        uint256 discount = discountRate * timeElapsed; // Скидка за прошедшее время
        return startingPrice - discount; // Возвращаем текущую цену
    }

    /**
     * @dev Функция покупки предмета аукциона.
     */
    function buy() external payable notStoped {
        require(block.timestamp < endsAt, "ended"); // Проверяем, не закончился ли аукцион
        uint256 price = getPrice(); // Получаем текущую цену
        require(msg.value >= price, "not enough founds"); // Проверяем, достаточно ли средств у покупателя

        uint256 refund = msg.value - price; // Рассчитываем сумму возврата
        if (refund > 0) {
            payable(msg.sender).transfer(refund); // Возвращаем излишние средства
        }

        seller.transfer(address(this).balance); // Переводим деньги продавцу
        stoped = true; // Останавливаем аукцион
    }
}