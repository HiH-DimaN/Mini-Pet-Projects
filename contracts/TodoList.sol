// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title TodoList
 * @author HiH_DimaN
 * @notice Контракт для управления списком задач (TODO).
 */
contract TodoList {
    
    address private owner; // Адрес владельца контракта

    /**
     * @dev Структура для представления задачи.
     */
    struct Todo {
       
        string title; // Заголовок задачи
       
        string description; // Описание задачи
        
        bool completed; // Флаг завершения задачи
    }

    /**
     * @dev Массив задач.
     */
    Todo[] todos; // Массив задач

    /**
     * @dev Модификатор, который проверяет, что вызывающий является владельцем.
     */
    modifier onlyOwner() {
        
        require(msg.sender == owner, "not an owner!"); // Проверяем, что вызывающий является владельцем
        
        _; // Выполняем следующую инструкцию, если вызывающий является владельцем
    }

    /**
     * @dev Конструктор контракта.
     */
    constructor() {
       
        owner = msg.sender; // Устанавливаем владельца контракта в адрес вызывающего
    }

    /**
     * @dev Функция добавления новой задачи.
     * @param _title Заголовок задачи.
     * @param _description Описание задачи.
     * @param _completed Флаг завершения задачи (по умолчанию - `false`).
     */
    function addTodo(string calldata _title, string calldata _description, bool _completed) external onlyOwner {
       
        todos.push(Todo({
           
            title: _title, // Заголовок задачи
            
            description: _description, // Описание задачи
           
            completed: false 
        })); // Добавляем новую задачу в массив `todos`
    }

    /**
     * @dev Функция изменения заголовка задачи.
     * @param _newTitile Новый заголовок задачи.
     * @param index Индекс задачи в массиве `todos`.
     */
    function changeTitle(string calldata _newTitile, uint256 index) external onlyOwner {
        
        todos[index].title = _newTitile; // Изменяем заголовок задачи по индексу `index`
    }

    /**
     * @dev Функция получения информации о задаче.
     * @param index Индекс задачи в массиве `todos`.
     * @return title Заголовок задачи.
     * @return description Описание задачи.
     * @return completed Флаг завершения задачи.
     */
    function getTodo(uint256 index) external view onlyOwner() returns(string memory, string memory, bool) {
        
        Todo storage myTodo = todos[index]; // Получаем задачу из массива по индексу `index`
        
        return (
            myTodo.title, // Заголовок задачи
            myTodo.description, // Описание задачи
            myTodo.completed // Флаг завершения задачи
        ); // Возвращаем заголовок, описание и статус завершения задачи
    }

    /**
     * @dev Функция изменения статуса завершения задачи.
     * @param index Индекс задачи в массиве `todos`.
     */
    function changeTodoStatus(uint index) external onlyOwner {
       
        todos[index].completed = !todos[index].completed; // Меняем статус завершения задачи по индексу `index` на противоположный
    }
}