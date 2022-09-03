// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Auction{
    address payable public owner;
    // two variable to calculate when the auction starts and ends
    uint public startBlock;
    uint public endBlock;
    // save all other info like image of the item on IFS - iterplanetary file system
    // ipfs uniquely identifies the information
    string public ipfsHash;
    // declaring enum type to save the state of the auction
    enum State {started,Running,Ended,Cancelled}
    State public auctionState;
  
   // declare variable for highest binding bid
   uint public highestBidingBid;
   
   // making it payable so if auction got cancelled or anything he can get his amount back
   address payable public highestBidder;


   mapping(address=>uint) public bids;

   uint bidIncrement;
   
   constructor(address eoa){
    owner = payable(eoa);
    auctionState= State.Running;

    startBlock = block.number;
    // this means that the auction will be running for a week
    // we can limit the transactions by changing this number
    endBlock = startBlock+40320;
    
    ipfsHash="";
    // bid increment will be 1 ether
    bidIncrement = 1000000000000000000;

   }

   // function modifies - use to modify the function behaviour
   // use modifies to automatically check the condition prior to function
     modifier notOwner(){
        require(owner!= msg.sender);
        _; // if the owner call this function the function will executed otherwise it will give exception

    }

    // another restriction - aution will running in between starts and end
    modifier afterStart(){
        require(block.number>= startBlock);
        _;
    }
     modifier beforeEnd(){
        require(block.number<= endBlock);
        _;
    }


   function min(uint a, uint b) pure internal returns(uint){
    if(a<=b){
        return a;
    }else{
        return b;
    }
   }
   
   function placeBid() public payable notOwner afterStart beforeEnd{
      require(auctionState==State.Running);
      require(msg.value>=100);

// this will be the value sent by current plus
// the value sent with this transanction value
      uint currentBid= bids[msg.sender] + msg.value;
      
      require(currentBid> highestBidingBid);
      bids[msg.sender]= currentBid;
       
      if(currentBid<= bids[highestBidder]){
        highestBidingBid = min(currentBid+bidIncrement,bids[highestBidder]);

      }
      else{
          highestBidingBid = min(currentBid,bids[highestBidder]+bidIncrement);
          highestBidder= payable(msg.sender);
      }
   }
  
    modifier onlyOwner(){
        require(msg.sender==owner);
        _;
    }
   // cancelling the auction
    
    function cancelAuction() public onlyOwner{
        auctionState = State.Cancelled;

    }
    // withdrawal patter - helps to avoid re-entrance attack that could cause unexpected
    // unwxpected behaviour - like financial loss to users


    // now finalizing the auction
    function finalizeAuction() public{
        require(auctionState==State.Cancelled|| block.number>endBlock);
        // check who cancelled the auction is owner or not
        // also the person who want to finalize this should only be biider - by checking their bidding value
        require(msg.sender==owner|| bids[msg.sender]>0);
        address payable recipient;
        uint value;

        if(auctionState==State.Cancelled){ // auction was cancelled
        // then each bidder will get their ether back - by calling this function one by one 
        //- at the frontend
            recipient= payable(msg.sender);
            value = bids[msg.sender];

        }else{ // auction ended (not cancelled)
             if(msg.sender==owner){ // if ended by owner
            
                recipient= owner;
                value= highestBidingBid;
             }else{ // if ender by highest bidder
                 if(msg.sender==highestBidder){
                    recipient= highestBidder;
                    value= bids[highestBidder] = highestBidingBid;
                 }else{ // this is neither the owner nor the highest bidder
                        recipient= payable(msg.sender);
                        value = bids[msg.sender];
                  }
             }
        }
        // resetting the bids of receipient to zero
        // so that they can't repeatedly finalize the auction and gets the value each time
         bids[recipient]= 0;
        recipient.transfer(value);
        
       
    }



    // how to scale application from 1 auction to hundreds of auction

}