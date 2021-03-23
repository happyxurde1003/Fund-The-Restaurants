pragma solidity ^0.6.12;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./Token.sol";
import "./AggregatorV3Interface.sol";

contract Restaurants is ERC721 {
  uint public restaurantCount = 0;
  mapping(uint => Restaurant) public restaurants;
  mapping(uint => NFT) public nft;
  AggregatorV3Interface internal priceFeed;
  Token private token;

  /**
   * Network: Kovan
   * Aggregator: ETH/USD
   * Address: 0x9326BFA02ADD2366b30bacB125260Af641031331
   */
  /**
   * Network: Mumbai Testnet
   * Aggregator: MATIC/USD
   * Address: 0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada
   */
  constructor(Token _token) ERC721("FundRestaurantsToken", "FRT") public {
    token = _token;
    priceFeed = AggregatorV3Interface(0xd0D5e3DB44DE05E9F294BB0a3bEEaF030DE24Ada);
  }

  struct Restaurant {
    uint restaurantId;
    string name;
    string description;
    string location;
    string imageURL;
    uint donationNeeded;
    uint date;
    address payable owner;
  }

  struct NFT {
    string name;
    uint red;
    uint green;
    uint blue;
    uint amount;
  }

  event RestaurantCreated (
    uint restaurantId,
    string name,
    string description,
    string location,
    string imageURL,
    uint donationNeeded,
    uint date,
    address payable owner
  );

  event DonationForRestaurant (
    uint restaurantId,
    uint amount,
    uint donationNeeded,
    uint date,
    address from,
    address payable owner
  );

  function createRestaurant(string memory _name, string memory _description, string memory _location, string memory _imageURL, uint _donationNeeded) public {
    require(_donationNeeded > 0);
    require(bytes(_name).length > 0);
    require(bytes(_description).length > 0);
    require(bytes(_location).length > 0);

    restaurantCount++;

    restaurants[restaurantCount] = Restaurant(restaurantCount, _name, _description, _location, _imageURL, _donationNeeded, now, msg.sender);
    emit RestaurantCreated(restaurantCount, _name, _description, _location, _imageURL, _donationNeeded, now, msg.sender);
  }

  function donateETHToRestaurant(uint _restaurantId, string memory _tokenURI) public payable {
    Restaurant memory _restaurant = restaurants[_restaurantId];

    require(_restaurant.donationNeeded >= msg.value);
    _restaurant.owner.transfer(msg.value);

    _restaurant.donationNeeded -= msg.value;
    restaurants[_restaurantId] = _restaurant;

    // Create NFT
    uint _tokenId = totalSupply().add(1);
    _safeMint(msg.sender, _tokenId);
    _setTokenURI(_tokenId, _tokenURI);

    // Random color
    uint red = getRandomValue(253);
    uint green = getRandomValue(254);
    uint blue = getRandomValue(255);
    nft[_tokenId] = NFT(_restaurant.name, red, green, blue, msg.value);

    emit DonationForRestaurant(_restaurantId, msg.value, _restaurant.donationNeeded, now, msg.sender, _restaurant.owner);
  }

  function donateETHToRestaurantWithReferrer(uint _restaurantId, string memory _tokenURI, address _referrer) public payable {
    Restaurant memory _restaurant = restaurants[_restaurantId];

    require(_restaurant.donationNeeded >= msg.value);
    _restaurant.owner.transfer(msg.value);

    _restaurant.donationNeeded -= msg.value;
    restaurants[_restaurantId] = _restaurant;

    // Create NFT for donator
    uint _tokenId = totalSupply().add(1);
    _safeMint(msg.sender, _tokenId);
    _setTokenURI(_tokenId, _tokenURI);

    // Random color
    uint red = getRandomValue(253);
    uint green = getRandomValue(254);
    uint blue = getRandomValue(255);
    nft[_tokenId] = NFT(_restaurant.name, red, green, blue, msg.value);

    // Give 1 token (FTR) to the referrer
    token.transfer(_referrer, 1000000000000000000);

    emit DonationForRestaurant(_restaurantId, msg.value, _restaurant.donationNeeded, now, msg.sender, _restaurant.owner);
  }

  function getRandomValue(uint mod) internal view returns(uint) {
    return uint(keccak256(abi.encodePacked(now, block.difficulty, msg.sender))) % mod;
  }

  function getLatestPrice() public view returns (int) {
    (
      uint80 roundID, 
      int price,
      uint startedAt,
      uint timeStamp,
      uint80 answeredInRound
    ) = priceFeed.latestRoundData();
    return price;
  }
}