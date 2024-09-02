// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import "@thirdweb-dev/contracts/drop/DropERC1155.sol"; // importing the Pickaxe Contract from thirdweb.
import "@thirdweb-dev/contracts/token/TokenERC20.sol"; // importing the ERC token from thirdweb.

// OpenZeppelin (ReentrancyGuard)
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/tokens/token/ERC1155/utils/ERC1155Holder.sol";


contract Mining is ReentrancyGuard, ERC1155Holder
 {
    DropERC1155 public immutable pickaxeNftCollection; // stores address of contracts (Pickaxe and Tokens)
    TokenERC20 public immutable rewardsToken;

    constructor(DropERC1155 pickaxeContractAddress,TokenERC20 gemsContractAddress)
    {
        pickaxeNftCollection = pickaxeContractAddress; // accepts the address of the contract of Pickaxe and Tokens
        rewardsToken = gemsContractAddress;
    }

    struct MapValue 
    {
        bool isData; // will be true if the coins are being staked
        uint256 value; // stores the nft ID of the token
    }


    mapping(address => MapValue) public playerPickaxe; // maps if the player has a pickaxe currenlt or not

    mapping(address => MapValue) public playerLastUpdate; // maps to where the status of the player the previous time the player was rewarded


//creating function for various tasks such as Stake,Withdraw,Claim and Calculate.


    function stake(uint256 _tokenId) external nonReentrant
     {
        require(pickaxeNftCollection.balanceOf(msg.sender, _tokenId) >= 1,"You must have at least 1 of the pickaxe you are trying to stake"); // checks if the user has atleast 1 pickaxe

        if (playerPickaxe[msg.sender].isData) 
        {
            pickaxeNftCollection.safeTransferFrom(address(this),msg.sender,playerPickaxe[msg.sender].value,1,"Returning your old pickaxe");// If they have a pickaxe already, send it back to them.
        }


        uint256 reward = calculateRewards(msg.sender);//calculates the rewards and pays the user out.
        rewardsToken.transfer(msg.sender, reward);

       // Transfer the pickaxe to the contract.
        pickaxeNftCollection.safeTransferFrom(msg.sender,address(this),_tokenId,1, "Staking your pickaxe"); 

        // Update the player Pickaxe value 
        playerPickaxe[msg.sender].value = _tokenId;
        playerPickaxe[msg.sender].isData = true;

        // Update the player Last  Update value
        playerLastUpdate[msg.sender].isData = true;
        playerLastUpdate[msg.sender].value = block.timestamp;
    }

    function withdraw() external nonReentrant 
    {
        require(playerPickaxe[msg.sender].isData,"You do not have a pickaxe to withdraw."); //ensure the player has an axe

        uint256 reward = calculateRewards(msg.sender); //calculates the rewards and pays the user out.
        rewardsToken.transfer(msg.sender, reward);

        // Sends the pickaxe back to the player
        pickaxeNftCollection.safeTransferFrom(address(this),msg.sender,playerPickaxe[msg.sender].value,1,"Returning your old pickaxe");

        // Update the player Pickaxe contract 
        playerPickaxe[msg.sender].isData = false;

        // Update the player LastUpdate comtract 
        playerLastUpdate[msg.sender].isData = true;
        playerLastUpdate[msg.sender].value = block.timestamp;
    }

    function claim() external nonReentrant 
    {
        uint256 reward = calculateRewards(msg.sender); //calculates the rewards and pays the user out.
        rewardsToken.transfer(msg.sender, reward);

        // Update the player LastUpdate value
        playerLastUpdate[msg.sender].isData = true;
        playerLastUpdate[msg.sender].value = block.timestamp;
    }

// functions created for collecting rewards, 
    function calculateRewards(address _player)  //calculates if the player was paid previously using playerLastUpdate
        public
        view
        returns (uint256 _rewards)
    {
    
        if (!playerLastUpdate[_player].isData || !playerPickaxe[_player].isData) //checks if the player has any rewards.
        {
            return 0;
        }

        // Calculate the time difference between now and the last time they staked/withdrew/claimed their rewards
        uint256 timeDifference = block.timestamp - playerLastUpdate[_player].value; //checks the time difference between the last time the player was rewarded 

        uint256 rewards = timeDifference *10_000_000_000_000 *(playerPickaxe[_player].value + 1); //calculates the rewards required for the user. 
// 18 decimal digit as mentioned in the gem contract hence "10_000_000_000_000"
        return rewards; // returns the value
    }
}
