// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

/**
 * @title MerkleTree
 * @author HiH_DimaN
 * @notice Контракт, реализующий дерево Меркла.
 */
contract MerkleTree {
    /**
     * @dev Массив хэшей узлов дерева Меркла.
     */
    bytes32[] public hashes; 

    /**
     * @dev Массив имен героев, которые будут использоваться в качестве листьев дерева.
     */
    string[4] heroes = ["Sherlock", "John", "Mary", "Lestrade"]; 

    /**
     * @dev Конструктор контракта.
     */
    constructor() {
        // Инициализируем массив хэшей листьев дерева
        for(uint i = 0; i < heroes.length; i++) {
            hashes.push(keccak256(abi.encodePacked(heroes[i])));
        }
    }

    /**
     * @dev Число листьев в дереве.
     */
    uint n = heroes.length; 

    /**
     * @dev Смещение в массиве хэшей для текущего уровня дерева.
     */
    uint offset = 0; 

    // Построение дерева Меркла
    while (n > 0) {
        for(uint i = 0; i < n - 1; i += 2) {
            // Вычисляем хэш нового узла как хэш от двух дочерних узлов
            bytes32 newHash = keccak256(abi.encodePacked(
                hashes[i + offset], hashes[i + offset + 1]
            ));
            // Добавляем новый узел в массив хэшей
            hashes.push(newHash);
        }
        // Обновляем смещение и число листьев для следующего уровня дерева
        offset += n;
        n = n / 2;
    }

    /**
     * @dev Функция для проверки принадлежности листа дереву Меркла.
     * @param root Хэш корня дерева.
     * @param leaf Хэш листа.
     * @param index Индекс листа в дереве.
     * @param proof Массив хэшей узлов доказательства.
     * @return True, если лист принадлежит дереву, иначе False.
     */
    function verify(bytes32 root, bytes32 leaf, uint index, bytes32[] memory proof) public pure returns(bool) {
        // Инициализируем хэш текущего узла
        bytes32 hash = leaf;
        // Итерируемся по элементам доказательства
        for(uint i = 0; i < proof.length; i++) {
            // Получаем элемент доказательства
            bytes32 proofElement = proof[i];
            // Если индекс четный, то хэш вычисляется от текущего узла и элемента доказательства
            if(index % 2 == 0) {
                hash = keccak256(abi.encodePacked(
                    hash, proofElement
                ));
            } else {
                // Иначе хэш вычисляется от элемента доказательства и текущего узла
                hash = keccak256(abi.encodePacked(
                    proofElement, hash
                ));    
            }
            // Обновляем индекс для следующего уровня дерева
            index = index / 2;
        }
        // Проверяем, совпадает ли хэш корня дерева с вычисленным хэшем
        return hash == root;
    }

    /**
     * @dev Функция для получения хэша корня дерева.
     * @return Хэш корня дерева.
     */
    function getRoot() public view returns(bytes32) {
        // Возвращаем хэш последнего элемента массива хэшей
        return hashes[hashes.length - 1];        
    }
}