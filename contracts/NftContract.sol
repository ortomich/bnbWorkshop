// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);
        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)
            for {
                let i := 0
            } lt(i, len) {
            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)
                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)
                mstore(resultPtr, out)
                resultPtr := add(resultPtr, 4)
            }
            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
            mstore(result, encodedLen)
        }
        return string(result);
    }
}

contract NftContract is ERC721, Ownable {
    using Strings for uint256;

    // =================================
	// Storage
	// =================================

    uint256 public constant maxSupply = 1000;
    uint256 public numMinted;  

    bool public saleIsActive;

    // =================================
	// Metadata
	// =================================

    function generateHTMLandSVG() internal pure returns (string memory Html, string memory Svg) {
        Html = '<!DOCTYPE html> <html lang="en"> <head> <meta charset="UTF-8"> <style> canvas { background-color: black; } </style> </head> <body> <canvas></canvas> <script> var canvas = document.querySelector("canvas"); canvas.width = window.innerWidth; canvas.height = window.innerHeight; var g = canvas.getContext("2d"); var nodes = [[-1, -1, -1], [-1, -1, 1], [-1, 1, -1], [-1, 1, 1], [1, -1, -1], [1, -1, 1], [1, 1, -1], [1, 1, 1]]; var edges = [[0, 1], [1, 3], [3, 2], [2, 0], [4, 5], [5, 7], [7, 6], [6, 4], [0, 4], [1, 5], [2, 6], [3, 7]]; function scale(factor0, factor1, factor2) { nodes.forEach(function (node) { node[0] *= factor0; node[1] *= factor1; node[2] *= factor2; }); } function rotateCuboid(angleX, angleY) { var sinX = Math.sin(angleX); var cosX = Math.cos(angleX); var sinY = Math.sin(angleY); var cosY = Math.cos(angleY); nodes.forEach(function (node) { var x = node[0]; var y = node[1]; var z = node[2]; node[0] = x * cosX - z * sinX; node[2] = z * cosX + x * sinX; z = node[2]; node[1] = y * cosY - z * sinY; node[2] = z * cosY + y * sinY; }); } function drawCuboid() { g.save(); g.clearRect(0, 0, canvas.width, canvas.height); g.translate(canvas.width / 2, canvas.height / 2); g.strokeStyle = "#FFFFFF"; g.beginPath(); edges.forEach(function (edge) { var p1 = nodes[edge[0]]; var p2 = nodes[edge[1]]; g.moveTo(p1[0], p1[1]); g.lineTo(p2[0], p2[1]); }); g.closePath(); g.stroke(); g.restore(); } scale(200, 200, 200); rotateCuboid(Math.PI / 4, Math.atan(Math.sqrt(2))); setInterval(function() { rotateCuboid(Math.PI / 180, 0); drawCuboid(); }, 17); </script> </body> </html>';
        Svg = '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350"> <rect x="125" y="125" width="100" height="100" style="fill:rgb(0,0,0)" /> </svg>';
    }

    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }

    function htmlToImageURI(string memory html) internal pure returns (string memory) {
        string memory baseURL = "data:text/html;base64,";
        string memory htmlBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(html))));
        return string(abi.encodePacked(baseURL,htmlBase64Encoded));
    }

    function svgToImageURI(string memory svg) internal pure returns (string memory) {
        string memory baseURL = "data:image/svg+xml;base64,";
        string memory svgBase64Encoded = Base64.encode(bytes(string(abi.encodePacked(svg))));
        return string(abi.encodePacked(baseURL,svgBase64Encoded));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        (string memory html, string memory svg) = generateHTMLandSVG();

        string memory imageURIhtml = htmlToImageURI(html);
        string memory imageURIsvg = svgToImageURI(svg);

        return string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{"name":"',
                                "NFTBNB | ", uint2str(tokenId),"",
                                '", "description":"", "attributes":"", "image":"', imageURIsvg,'", "animation_url":"', imageURIhtml,'"}'
                            )
                        )
                    )
                )
            );
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    // =================================
	// Mint
	// =================================

    function mint() public payable {
        require(saleIsActive, "Sale must be active to mint");
        require(numMinted < maxSupply, "Sale has already ended");

        numMinted += 1;
        _safeMint(_msgSender(), numMinted);
    }

    // =================================
	// Owner functions
	// =================================

    function setSaleStatus(bool state) public onlyOwner {
        saleIsActive = state;
    }

    // =================================
	// Constructor
	// =================================
    
    constructor() ERC721("NFTBNB", "NFTBNB") {}

}
