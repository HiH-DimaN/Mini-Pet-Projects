// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Crowd
 * @author HiH_DimaN
 * @notice Контракт для реализации краудфандинговых кампаний.
 */
contract Crowd {
    /**
     * @dev Структура, представляющая краудфандинговую кампанию.
     */
    struct Campaing {
        /**
         * @dev Адрес владельца кампании.
         */
        address owner;
        /**
         * @dev Цель сбора средств для кампании.
         */
        uint goal;
        /**
         * @dev Сумма собранных средств.
         */
        uint pledged;
        /**
         * @dev Время начала кампании.
         */
        uint startAt;
        /**
         * @dev Время окончания кампании.
         */
        uint endAt;
        /**
         * @dev Флаг, указывающий, были ли средства выведены владельцем.
         */
        bool claimed;
    }

    /**
     * @dev Токен, используемый для сбора средств.
     */
    IERC20 public immutable token;

    /**
     * @dev Отображение кампаний по их ID.
     */
    mapping(uint => Campaing) public campaings; 

    /**
     * @dev Текущий ID кампании.
     */
    uint public currentTd; 

    /**
     * @dev Отображение, хранящее информацию о взносах пользователей в кампании.
     */
    mapping(uint => mapping(address => uint)) public pledges; 

    /**
     * @dev Максимальная продолжительность кампании (100 дней).
     */
    uint public constant MAX_DURATION = 100 days;

    /**
     * @dev Минимальная продолжительность кампании (10 дней).
     */
    uint public constant MIN_DURATION = 10 days;

    /**
     * @dev Событие, которое эмитируется при запуске новой кампании.
     * @param id ID кампании.
     * @param owner Адрес владельца кампании.
     * @param goal Цель сбора средств.
     * @param starAt Время начала кампании.
     * @param endAt Время окончания кампании.
     */
    event Launched(uint id, address owner, uint goal, uint starAt, uint endAt);

    /**
     * @dev Событие, которое эмитируется при отмене кампании.
     * @param id ID кампании.
     */
    event Cancel(uint id);

    /**
     * @dev Событие, которое эмитируется при внесении взноса в кампанию.
     * @param id ID кампании.
     * @param pledger Адрес пользователя, внесшего вклад.
     * @param amount Сумма взноса.
     */
    event Pledged(uint id, address pledger, uint amount);

    /**
     * @dev Событие, которое эмитируется при отмене взноса.
     * @param id ID кампании.
     * @param pledger Адрес пользователя, отменившего вклад.
     * @param amount Сумма отмененного взноса.
     */
    event Unpledged(uint id, address pledger, uint amount);

    /**
     * @dev Событие, которое эмитируется при выводе средств владельцем кампании.
     * @param id ID кампании.
     */
    event Claimed(uint id);

    /**
     * @dev Событие, которое эмитируется при возврате средств пользователю.
     * @param id ID кампании.
     * @param pledger Адрес пользователя, получившего возврат средств.
     * @param amount Сумма возвращенных средств.
     */
    event Refunded(uint id, address pledger, uint amount);

    /**
     * @dev Конструктор контракта.
     * @param _token Адрес токена, используемого для сбора средств.
     */
    constructor(address _token) {
        token = IERC20(_token); // Инициализируем токен, используемый для сбора средств
    }

    /**
     * @dev Функция запуска новой кампании.
     * @param _goal Цель сбора средств.
     * @param _startAt Время начала кампании.
     * @param _endAt Время окончания кампании.
     */
    function launch(uint _goal, uint _startAt, uint _endAt) external {
        require(_startAt >= block.timestamp, "incorrect start at!"); // Проверяем, что время начала кампании не раньше текущего времени
        require(_endAt <= _startAt + MIN_DURATION, "incorrect end at!"); // Проверяем, что время окончания кампании не раньше, чем минимальная продолжительность
        require(_endAt <= _startAt + MAX_DURATION, "too long!"); // Проверяем, что время окончания кампании не позже, чем максимальная продолжительность

        campaings[currentId] = Campaing({
            owner: msg.sender, // Устанавливаем владельца кампании
            goal: _goal, // Устанавливаем цель сбора средств
            pledged: 0, // Инициализируем сумму собранных средств
            startAt: _startAt, // Устанавливаем время начала кампании
            endAt: _endAt, // Устанавливаем время окончания кампании
            claimed: false // Инициализируем флаг вывода средств
        });

        emit Launched(currentId, msg.sender, _goal, _startAt, _endAt); // Эмитируем событие запуска кампании
        currentId += 1; // Увеличиваем текущий ID кампании
    }

    /**
     * @dev Функция отмены кампании.
     * @param _id ID кампании.
     */
    function cancel(uint _id) external {
        Campaing memory campaing = campaings[_id]; // Получаем информацию о кампании
        require(msg.sender == campaing.owner, "not an owner!"); // Проверяем, является ли вызывающий владельцем кампании
        require(block.timestamp <= campaing.startAt, "already started!"); // Проверяем, не началась ли кампания

        delete campaings[_id]; // Удаляем информацию о кампании
        emit Cancel(_id); // Эмитируем событие отмены кампании
    }

    /**
     * @dev Функция внесения взноса в кампанию.
     * @param _id ID кампании.
     * @param _amount Сумма взноса.
     */
    function pledge(uint _id, uint _amount) external {
        Campaing storage campaing = campaings[_id]; // Получаем информацию о кампании (с модификатором `storage` для изменения данных)
        require(block.timestamp >= campaing.startAt, "not started!"); // Проверяем, началась ли кампания
        require(block.timestamp < campaing.endAt, "ended!"); // Проверяем, не закончилась ли кампания

        campaing.pledged += _amount; // Увеличиваем сумму собранных средств
        pledges[_id][msg.sender] += _amount; // Увеличиваем сумму взноса пользователя
        token.transferFrom(msg.sender, address(this), _amount); // Переводим токены с адреса пользователя на адрес контракта
        emit Pledged(_id, msg.sender, _amount); // Эмитируем событие внесения взноса
    }

    /**
     * @dev Функция отмены взноса.
     * @param _id ID кампании.
     * @param _amount Сумма отменяемого взноса.
     */
    function unpledge(uint _id, uint _amount) external {
        Campaing storage campaing = campaings[_id]; // Получаем информацию о кампании (с модификатором `storage` для изменения данных)
        require(block.timestamp < campaing.endAt, "ended!"); // Проверяем, не закончилась ли кампания

        campaing.pledged -= _amount; // Уменьшаем сумму собранных средств
        pledges[_id][msg.sender] -= _amount; // Уменьшаем сумму взноса пользователя
        token.transfer(msg.sender, _amount); // Возвращаем токены на адрес пользователя
        emit Unpledged(_id, msg.sender, _amount); // Эмитируем событие отмены взноса
    }

    /**
     * @dev Функция вывода средств владельцем кампании.
     * @param _id ID кампании.
     */
    function claim(uint _id) external {
        Campaing storage campaing = campaings[_id]; // Получаем информацию о кампании (с модификатором `storage` для изменения данных)
        require(msg.sender == campaing.owner, "not an owner!"); // Проверяем, является ли вызывающий владельцем кампании
        require(block.timestamp > campaing.endAt, "not ended!"); // Проверяем, закончилась ли кампания
        require(campaing.pledged >= campaing.goal, "pledged is too low!"); // Проверяем, достигнута ли цель сбора средств
        require(!campaing.claimed, "already claimed!"); // Проверяем, не были ли средства уже выведены

        campaing.claimed = true; // Устанавливаем флаг вывода средств
        token.transfer(msg.sender, campaing.pledged); // Переводим токены на адрес владельца
        emit Claimed(_id); // Эмитируем событие вывода средств
    }

    /**
     * @dev Функция возврата средств пользователю.
     * @param _id ID кампании.
     */
    function refund(uint _id) external {
        Campaing storage campaing = campaings[_id]; // Получаем информацию о кампании (с модификатором `storage` для изменения данных)
        require(block.timestamp > campaing.endAt, "not ended!"); // Проверяем, закончилась ли кампания
        require(campaing.pledged < campaing.goal, "reached goal!"); // Проверяем, не достигнута ли цель сбора средств

        uint pledgedAmount = pledges[_id][msg.sender]; // Получаем сумму взноса пользователя
        pledges[_id][msg.sender] = 0; // Обнуляем сумму взноса пользователя
        token.transfer(msg.sender, pledgedAmount); // Возвращаем токены на адрес пользователя
        emit Refunded(_id, msg.sender, pledgedAmount); // Эмитируем событие возврата средств
    }
}