// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.20;

import "./MGROW.sol";
import "./nftMinter.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract Management {
    IMGrow mgrow;
    IMinter minter;

    uint nftCount; 

    mapping(address =>uint) public minted;
    mapping (address => uint) public burnt;

    string[] public baseURIs;
  

    mapping(address => uint []) public userNFTs;

    constructor(address _minter, address _token /*, address _dao */) {
        require(_minter != address(0) && _token!=address(0), "Invalid Addresses");
        mgrow = IMGrow(_token);
        minter = IMinter(_minter);
        nftCount = 0;
    }

    function addBaseURI(string memory _URI) external {
      require(baseURIs.length <3, "Cannot have more than 3 URIs");
        baseURIs.push(_URI);  
    }
    
    function checkUserNFTs(address _user) public view returns (uint){
        return userNFTs[_user].length;
    }

    function checklength() public view returns (uint){
        return baseURIs.length;
    }

    function checkStats(address _address) public view returns(uint _minted, uint _burnt){
        _minted = minted[_address];
        _burnt = burnt[_address];

        return (_minted, _burnt);
        
    }

    function mintTokens(address _receiver, uint _tokens) external {
        //only DAO can call this function
        mgrow.mintTokens(_receiver, _tokens);
        minted[_receiver] +=_tokens;



    }

    function burnTokens(uint _tokens) external{
        mgrow.burnTokens(msg.sender, _tokens);    
        burnt[msg.sender]+=_tokens;
    }

    //NFT Update URI 
    //URI 0 --> X==Y
    //URI 1 --> X > Y
    //URI 2 --> Y >X
    function mintNFTs() public {
        uint nftId = ++nftCount;
        string memory _uri = baseURIs[0];
        minter.safeMint(msg.sender, nftId);
        minter.updateURI(nftId, _uri);

        userNFTs[msg.sender].push(nftId);

    }
    function updateNFTs(address _address) public {
        uint [] memory tokens = userNFTs[_address];
        (uint _minted, uint _burnt) = checkStats(_address);
        string storage _baseURI;

        if(_minted == _burnt){
            _baseURI = baseURIs[0];
            setURIs(tokens, _baseURI);
          
        }else if (_minted >_burnt) {
            _baseURI = baseURIs[1];
             _setURI(_baseURI, _minted, _burnt, tokens);
        


        } else {
            _baseURI = baseURIs[2];
             _setURI(_baseURI, _burnt, _minted, tokens);
    }
    }

    function setURIs(uint[] memory _tokenIds, string memory uri ) internal {

        uint len = _tokenIds.length;

        for(uint i; i<len; ){
            uint _token =_tokenIds[i];
            minter.updateURI(_token, uri);

            unchecked {
                i++;
            }
        }

    }
    function _setURI(string memory _baseURI, uint x, uint y, uint [] memory tokens) internal {
         uint imageID = getImageId(x);
         uint z = x % y;
         
              uint prop = (x - z)/y;
            if(prop>5){
                prop = 5;
            }
            string memory props = Strings.toString(prop);
            string memory finalURI ;
            
              

            //to set the brightness in the specific proportion, we make a 50 tree difference
            
           
            finalURI = string(abi.encodePacked(_baseURI, props, '/', Strings.toString(imageID)));
             setURIs(tokens, finalURI);

        

    }

    function getImageId(uint x) internal pure returns (uint imageID) {
            // the uint x is in ether, hence is 'x' * 10^^18

            uint _x = x/ 1 ether;
         if( _x<= 50){
                imageID = 1;
               return imageID;
              
               
            }
            else if( _x <= 100){
                imageID = 2; 
               return imageID;
             
                
            }
             else if( _x <= 150){
                 imageID = 3;
               return imageID;
            
            }
             else if( _x <= 200){
                 imageID = 4;
               return imageID;
          
            }
             else if( _x <= 250){
                 imageID = 5;
               return imageID;
     
            } else {
                return x;
            }

    }



   
}