pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";

contract StudentCertificate is ERC1155, AccessControl {
    uint256 private _tokenIdTracker = 1;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    struct CertificateMetadata {
        uint256 completionDate;
        string reportURL;
    }

    mapping(uint256 => CertificateMetadata) public certificateMetadata;

    constructor() ERC1155("https://myapi.com/api/token/{id}.json") {
        _setupRole(MINTER_ROLE, msg.sender);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC1155, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mintCertificate(address account, string memory reportURL) external onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenIdTracker;

        _mint(account, tokenId, 1, "");
        certificateMetadata[tokenId] = CertificateMetadata({
            completionDate: block.timestamp,
            reportURL: reportURL
        });

        _tokenIdTracker++;
    }

    function grantMintingPermission(address account) external onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, account);
    }

    function getCertificateMetadata(uint256 tokenId) external view returns (uint256, string memory) {
        CertificateMetadata memory metadata = certificateMetadata[tokenId];
        return (metadata.completionDate, metadata.reportURL);
    }

    function safeTransferFrom(
        address /*from*/,
        address /*to*/,
        uint256 /*id*/,
        uint256 /*amount*/,
        bytes memory /*data*/
    ) public pure override {
        revert("Transfer not allowed.");
    }

    function safeBatchTransferFrom(
        address /*from*/,
        address /*to*/,
        uint256[] memory /*ids*/,
        uint256[] memory /*amounts*/,
        bytes memory /*data*/
    ) public pure override {
        revert("Batch transfer not allowed.");
    }
}
