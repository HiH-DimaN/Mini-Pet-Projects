//SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title IterMapping
 * @author HiH_DimaN
 * @notice Контракт, реализующий итерируемое отображение (mapping).
 */
contract IterMapping {
    /**
     * @dev Отображение имен на возраст.
     */
    mapping(string => uint) public ages; 

    /**
     * @dev Массив ключей (имен) для итерации по отображению.
     */
    string[] public keys; 

    /**
     * @dev Отображение, указывающее, был ли ключ уже добавлен в массив ключей.
     */
    mapping(string => bool) public isInserted;

    /**
     * @dev Функция установки возраста для имени.
     * @param _name Имя.
     * @param _age Возраст.
     */
    function set(string memory _name, uint _age) public {
        ages[_name] = _age; // Устанавливаем возраст для имени

        if(!isInserted[_name]) { // Проверяем, был ли ключ уже добавлен
            isInserted[_name] = true; // Отмечаем, что ключ добавлен
            keys.push(_name); // Добавляем ключ в массив ключей
        }
    }

    /**
     * @dev Функция получения длины массива ключей.
     * @return Длина массива ключей.
     */
    function length() public view returns(uint) {
        return keys.length; // Возвращаем длину массива ключей
    }

    /**
     * @dev Функция получения возраста по индексу в массиве ключей.
     * @param _index Индекс в массиве ключей.
     * @return Возраст, соответствующий ключу по индексу.
     */
    function get(uint _index) public view returns(uint) {
        string memory key = keys[_index]; // Получаем ключ по индексу
        return ages[key]; // Возвращаем возраст по ключу
    }

    /**
     * @dev Функция получения массива всех возрастов.
     * @return Массив возрастов, соответствующих всем ключам.
     */
    function values() public view returns(uint[] memory) {
        uint[] memory vals = new uint[](keys.length); // Создаем массив для хранения возрастов

        for(uint i = 0; i < keys.length; i++) { // Итерируемся по массиву ключей
            vals[i] = ages[keys[i]]; // Получаем возраст по ключу и добавляем его в массив
        }

        return vals; // Возвращаем массив возрастов
    }
}