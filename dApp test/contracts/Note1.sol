// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;
contract Note{
 //Default Access Modifier = internal
 //state это переменная которая находится внутри контракта, но не в функциях
 string note; //state variable (состояние)
 //Для public getter функция создается автоматом
 //Access Modifer
 //internal, external, private, public
 //типы
 //primitive (примитивный) = int, uint, bool, byte, address
 //reference (ссылочный) = string, array, mapping, struct, contract
 //Для всех ссылочных и локальных типов переменных нужно указывать memory или calldata
 function setNote(string memory _note) public {
 note = _note;
 }
 //view и pure = 0 газ
 //view = не меняшь state (состояние) и можешь читать данные
 //pure = не меняшь state (состояние) и даже не можешь читать данные
 function getNote() public view returns(string memory){
 return note;
 }
}