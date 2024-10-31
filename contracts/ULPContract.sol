// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./LayerZero/contracts/lzApp/NonblockingLzApp.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";


contract CrossChainTransfer is NonblockingLzApp {
    enum TokenType { NATIVE, ERC20, ERC721, ERC1155 }

    event CrossChainTransferInitiated(
        uint16 indexed dstChainId,
        TokenType tokenType,
        address indexed tokenContract,
        uint256 tokenIdOrAmount,
        address indexed recipient
    );

    event CrossChainTransferReceived(
        uint16 indexed srcChainId,
        TokenType tokenType,
        address indexed tokenContract,
        uint256 tokenIdOrAmount,
        address indexed recipient
    );

    constructor(address _lzEndpoint, address initialOwner) NonblockingLzApp(_lzEndpoint) Ownable(initialOwner) {}

    function sendCrossChain(
        uint16 _dstChainId,
        TokenType _tokenType,
        address _tokenContract,
        uint256 _tokenIdOrAmount,
        address _recipient,
        bytes calldata _data
    ) external payable {
        if (_tokenType == TokenType.ERC20) {
            _safeERC20TransferFrom(_tokenContract, msg.sender, address(this), _tokenIdOrAmount);
        } else if (_tokenType == TokenType.ERC721) {
            _safeERC721TransferFrom(_tokenContract, msg.sender, address(this), _tokenIdOrAmount);
        } else if (_tokenType == TokenType.ERC1155) {
            _safeERC1155TransferFrom(_tokenContract, msg.sender, address(this), _tokenIdOrAmount, 1, _data);
        } else if (_tokenType == TokenType.NATIVE) {
            require(msg.value == _tokenIdOrAmount, "Incorrect native token amount");
        }

        bytes memory payload = abi.encode(_tokenType, _tokenContract, _tokenIdOrAmount, _recipient, _data);
        (uint256 messageFee, ) = lzEndpoint.estimateFees(_dstChainId, address(this), payload, false, bytes(""));
        require(msg.value >= messageFee, "Insufficient fee");

        emit CrossChainTransferInitiated(_dstChainId, _tokenType, _tokenContract, _tokenIdOrAmount, _recipient);
        _lzSend(_dstChainId, payload, payable(msg.sender), address(0), bytes(""), msg.value - messageFee);
    }

    /**
     * @dev Implements the required _nonblockingLzReceive function from NonblockingLzApp.
     * This function is called when a cross-chain message is received.
     * @param _srcChainId The source chain ID.
     * @param _srcAddress The address of the contract on the source chain.
     * @param _nonce The message nonce.
     * @param _payload The message payload.
     */
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal override {
        (TokenType tokenType, address tokenContract, uint256 tokenIdOrAmount, address recipient, bytes memory data) = abi.decode(
            _payload,
            (TokenType, address, uint256, address, bytes)
        );

        if (tokenType == TokenType.ERC20) {
            _safeERC20Transfer(tokenContract, recipient, tokenIdOrAmount);
        } else if (tokenType == TokenType.ERC721) {
            _safeERC721Transfer(tokenContract, recipient, tokenIdOrAmount);
        } else if (tokenType == TokenType.ERC1155) {
            _safeERC1155Transfer(tokenContract, recipient, tokenIdOrAmount, 1, data);
        } else if (tokenType == TokenType.NATIVE) {
            (bool success, ) = recipient.call{value: tokenIdOrAmount}("");
            require(success, "Native token transfer failed");
        }

        emit CrossChainTransferReceived(_srcChainId, tokenType, tokenContract, tokenIdOrAmount, recipient);
    }

    function _safeERC20Transfer(
        address _token,
        address _to,
        uint256 _amount
    ) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(IERC20.transfer.selector, _to, _amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ERC20 transfer failed");
    }

    function _safeERC20TransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        (bool success, bytes memory data) = _token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, _from, _to, _amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ERC20 transferFrom failed");
    }

    function _safeERC721Transfer(
        address _token,
        address _to,
        uint256 _tokenId
    ) internal {
        (bool success, ) = _token.call(
            abi.encodeWithSelector(
                bytes4(keccak256("safeTransferFrom(address,address,uint256)")),
                address(this),
                _to,
                _tokenId
            )
        );
        require(success, "ERC721 transfer failed");
    }

    function _safeERC721TransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal {
        (bool success, ) = _token.call(
            abi.encodeWithSelector(
                bytes4(keccak256("safeTransferFrom(address,address,uint256)")),
                _from,
                _to,
                _tokenId
            )
        );
        require(success, "ERC721 transferFrom failed");
    }

    function _safeERC1155Transfer(
        address _token,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal {
        (bool success, ) = _token.call(
            abi.encodeWithSelector(
                IERC1155.safeTransferFrom.selector,
                address(this),
                _to,
                _id,
                _amount,
                _data
            )
        );
        require(success, "ERC1155 transfer failed");
    }

    function _safeERC1155TransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal {
        (bool success, ) = _token.call(
            abi.encodeWithSelector(
                IERC1155.safeTransferFrom.selector,
                _from,
                _to,
                _id,
                _amount,
                _data
            )
        );
        require(success, "ERC1155 transferFrom failed");
    }
}
