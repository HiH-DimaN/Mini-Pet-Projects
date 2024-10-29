// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title StakingALg
 * @author HiH_DimaN
 * @notice Контракт для стейкинга токенов с начислением вознаграждений.
 */
contract StakingALg {
    /**
     * @dev Токен, используемый для начисления вознаграждений.
     */
    IERC20 public rewardsToken; 

    /**
     * @dev Токен, используемый для стейкинга.
     */
    IERC20 public stakingToken; 

    /**
     * @dev Ставка начисления вознаграждений в секунду (в единицах rewardsToken).
     */
    uint256 public rewardRate = 10; 

    /**
     * @dev Время последнего обновления ставки вознаграждений.
     */
    uint256 public lastUpdateTime; 

    /**
     * @dev Сохраненное значение вознаграждения на токен.
     */
    uint256 public rewardPerTokenStored; 

    /**
     * @dev Отображение, хранящее начисленное вознаграждение на токен для каждого пользователя.
     */
    mapping(address => uint256) public userRewardPerTokenPaid; 

    /**
     * @dev Отображение, хранящее накопленное вознаграждение для каждого пользователя.
     */
    mapping(address => uint256) public rewards; 


    /**
     * @dev Отображение, хранящее баланс стейкинга для каждого пользователя.
     */
    mapping(address => uint256) private balances; 
    
     * @dev Общий стейкинг.
     */
    uint256 public _totalSupply; // Общий стейкинг

    /**
     * @dev Конструктор контракта.
     * @param _stakingToken Адрес токена для стейкинга.
     * @param _rewardsToken Адрес токена для начисления вознаграждений.
     */
    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken); // Устанавливаем токен для стейкинга
        rewardsToken = IERC20(_rewardsToken); // Устанавливаем токен для начисления вознаграждений
    }

    /**
     * @dev Модификатор, который обновляет информацию о вознаграждении перед выполнением функции.
     */
    modifier updateReward(address _account) {
        rewardPerTokenStored = rewardPerToken(); // Обновляем сохраненное значение вознаграждения на токен
        lastUpdateTime = block.timestamp; // Обновляем время последнего обновления
        userRewardPerTokenPaid[_account] = rewardPerTokenStored; // Обновляем начисленное вознаграждение на токен для пользователя
        _;
    }

    /**
     * @dev Функция вычисления вознаграждения на токен.
     * @return Вознаграждение на токен.
     */
    function rewardPerToken() public view returns(uint256) {
        if(_totalSupply == 0) { // Проверяем, есть ли стейкинг
            return 0; // Если нет стейкинга, то вознаграждение равно 0
        }
        return rewardPerTokenStored + (
            rewardRate * (block.timestamp - lastUpdateTime) // Вычисляем изменение вознаграждения за прошедшее время
        ) * 1e18 / _totalSupply; // Делим на общий стейкинг для получения вознаграждения на токен
    }

    /**
     * @dev Функция вычисления накопленного вознаграждения для пользователя.
     * @param _account Адрес пользователя.
     * @return Накопленное вознаграждение для пользователя.
     */
    function earned(address _account) public view returns(uint256) {
        return (
            _balances[_account] * ( // Умножаем баланс пользователя на 
                rewardPerToken() - userRewardTokenPaid[_account] // Разницу между текущим и начисленным вознаграждением на токен
            ) / 1e18 // Делим на 1e18 для корректного масштабирования
        ) + rewards[_account]; // Добавляем накопленное вознаграждение
    }

    /**
     * @dev Функция стейкинга токенов.
     * @param _amount Количество токенов для стейкинга.
     */
    function stake(uint _amount) external updateReward(msg.sender){
        _totalSupply += _amount; // Увеличиваем общий стейкинг
        _balances[msg.sender] += _amount; // Увеличиваем баланс пользователя
        stakingToken.transferFrom(msg.sender, address(this), _amount); // Переводим токены из кошелька пользователя в контракт
    }

    /**
     * @dev Функция вывода токенов из стейкинга.
     * @param _amount Количество токенов для вывода.
     */
    function withdraw(_amount) external updateReward(msg.sender){
        _totalSupply -= _amount; // Уменьшаем общий стейкинг
        _balances[msg.sender] -= _amount; // Уменьшаем баланс пользователя
        stakingToken.transfer(msg.sender, _amount); // Переводим токены из контракта в кошелек пользователя
    } 

    /**
     * @dev Функция получения накопленных вознаграждений.
     */
    function getReward() external updateReward(msg.sender){
        uint256 reward = rewards[msg.sender]; // Получаем накопленное вознаграждение
        rewards[msg.sender] = 0; // Обнуляем накопленное вознаграждение
        rewardsToken.transfer(msg.sender, reward); // Переводим вознаграждение пользователю
    } 
        
}