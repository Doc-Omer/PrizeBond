// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./erc1155.sol";
import "hardhat/console.sol";

contract PrizeBond is erc1155{

    

    struct user{
        address  userAddress;
        uint userId;
        uint bondAmount;
    }

    struct DrawWinners{
        address winner1;
        address winner2;
        address winner3;
        bool isTrueW1;
        bool isTrueW2;
        bool isTrueW3;
    }

    struct WinningAmount{
        uint firstPrize;
        uint secondPrize;
        uint thirdPrize;
        bool _isTrue;
    }

    mapping (uint =>mapping (uint=>user)) public  _prizeBond;

    mapping (uint=>mapping (uint=>DrawWinners)) public _winners;

    mapping (uint=>mapping (uint=>WinningAmount)) public _winnningAmount;

    mapping (uint =>uint []) public _redeemedIds;

    mapping(uint => bool) public _checkPrize;

                               
    function GenericBuy(uint _BondPrize, uint _amount, uint arrayLength, uint totalcount) public {     // change to internal
        if(arrayLength >0 && arrayLength <= _amount){
 
            for(uint i =1; i <= _amount; i++){
                uint index = _redeemedIds[_BondPrize][arrayLength - i];
                _prizeBond[_BondPrize][index]=user(msg.sender,index,_BondPrize);
                  _redeemedIds[_BondPrize].pop();
                }

            _safeTransferFrom(address(this), msg.sender, _BondPrize ,   _amount,  "0x0");   //here
        }

        else{ 
            require(totalcount + _amount <= 100, "Supply limit exceeded");
            for(uint i =1; i <= _amount; i++){
                _prizeBond[_BondPrize][totalcount + i]=user(msg.sender,totalcount + i,_BondPrize);
                }
            _mint(msg.sender, _BondPrize, _amount, " ");
        }
    }

    function BuyPB(uint _BondPrize, uint _amount)  payable  public {
        require(msg.sender!=owner(),"Owner can't buy Bond");
        require(msg.value ==  _BondPrize*_amount, "insufficent amount");
        require(_checkPrize[_BondPrize] == true, "not set");

        uint totalcount = totalSupply(_BondPrize);
        uint arrayLength= _redeemedIds[_BondPrize].length;

        if(_BondPrize==500){
            GenericBuy(_BondPrize, _amount, arrayLength, totalcount);
        }

        else if (_BondPrize==700){
            GenericBuy(_BondPrize, _amount, arrayLength, totalcount);
        }

        else if (_BondPrize==1000){
            GenericBuy(_BondPrize, _amount, arrayLength, totalcount);
        }

        else { 
            revert("Invalid id");
        }
    }

    function randomwinner(uint _bondId) public view returns(uint random1, uint random2, uint random3) {
        random1 = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty + 2, msg.sender))) % totalSupply(_bondId) + 1;
        random2 = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty + 4, msg.sender))) % totalSupply(_bondId) + 1;
        random3 = uint(keccak256(abi.encodePacked(block.timestamp, block.difficulty + 6, msg.sender))) % totalSupply(_bondId) + 1;
    }

    function draw(uint _BondPrize, uint wins) public  payable onlyOwner {
        require(_winnningAmount[_BondPrize][wins]._isTrue == true, "You have not set the values");  //change public to internal
        uint prize1 = _winnningAmount[_BondPrize][wins].firstPrize;
        uint prize2 = _winnningAmount[_BondPrize][wins].secondPrize;
        uint prize3 = _winnningAmount[_BondPrize][wins].thirdPrize;
        uint totalprize = prize1 + prize2 + prize3;
        require(msg.value == totalprize, "You must deposit the required money");
    
        (uint random1, uint random2, uint random3) = randomwinner(_BondPrize);
        _winners[_BondPrize][wins].winner1 =  _prizeBond[_BondPrize][random1].userAddress;
        _winners[_BondPrize][wins].winner2 =  _prizeBond[_BondPrize][random2].userAddress;
        _winners[_BondPrize][wins].winner3 =  _prizeBond[_BondPrize][random3].userAddress;

        address owner = owner();
        if(_winners[_BondPrize][wins].winner1==address(this)){
            payable (owner).transfer(prize1);
        } 

        if( _winners[_BondPrize][wins].winner2==address(this)){
             payable (owner).transfer(prize2);
        }

        if( _winners[_BondPrize][wins].winner3==address(this)){
             payable (owner).transfer(prize3);
        }
    }

    function claimRewards(uint _BondPrize, uint wins) public {
        uint prize1 = _winnningAmount[_BondPrize][wins].firstPrize;
        uint prize2 = _winnningAmount[_BondPrize][wins].secondPrize;
        uint prize3 = _winnningAmount[_BondPrize][wins].thirdPrize;

        DrawWinners memory withdrawBool = _winners[_BondPrize][wins];

        if(msg.sender == withdrawBool.winner1){
            require(withdrawBool.isTrueW1 == false, "You have already claimed your reward");
            payable(msg.sender).transfer(prize1);
            withdrawBool.isTrueW1 = true;
        }
        else if(msg.sender == withdrawBool.winner2){
            require(withdrawBool.isTrueW2 == false, "You have already claimed your reward");
            payable(msg.sender).transfer(prize2);
            withdrawBool.isTrueW2 = true;
        }
        else if(msg.sender == withdrawBool.winner3){
            require(withdrawBool.isTrueW3 == false, "You have already claimed your reward");
            payable(msg.sender).transfer(prize3);
            withdrawBool.isTrueW3 = true;
        }
        else{
            revert("You are not the winner");
        }
    }

    function redeem(uint _BondPrize, uint _BondId) public {
        address bondOwner=_prizeBond[_BondPrize][_BondId].userAddress;
        require(msg.sender==bondOwner);
        uint bondPrize=_prizeBond[_BondPrize][_BondId].bondAmount;
        require(bondPrize==_BondPrize,"invalid Bond Price");        
        uint bondId=_prizeBond[_BondPrize][_BondId].userId;
        require(bondId==_BondId,"Invaild Bond Id ");
        _safeTransferFrom( msg.sender,address(this),_BondPrize,1,"0x0");
        _prizeBond[_BondPrize][_BondId].userAddress= address(this);
        _redeemedIds[_BondPrize].push(_BondId);
        payable(msg.sender).transfer(_BondPrize);
    }


    function setWinningAmount(uint _BondPrize, uint _drawNumber, uint _winningAmount1,uint _winningAmount2,uint _winningAmount3) public onlyOwner{
        require(_winnningAmount[_BondPrize][_drawNumber]._isTrue == false, "You cannot set the prize now");

        WinningAmount memory winningAmount = _winnningAmount[_BondPrize][_drawNumber];
        winningAmount.firstPrize = _winningAmount1;
        winningAmount.secondPrize = _winningAmount2;
        winningAmount.thirdPrize = _winningAmount3;
        winningAmount._isTrue = true;

         _checkPrize[_BondPrize] = true;
    }


    function deposit()  public payable onlyOwner{}

    
    function withdrawOwner() public onlyOwner{
        payable(owner()).transfer(address(this).balance);
    }


    function contractBalance() public view returns(uint){
        return address(this).balance;
    }
}
