/*
 * SPDX-License-Identitifer:    GPL-3.0-or-later
 *
 * This file requires contract dependencies which are licensed as
 * GPL-3.0-or-later, forcing it to also be licensed as such.
 *
 * This is the only file in your project that requires this license and
 * you are free to choose a different license for the rest of the project.
 */

pragma solidity 0.4.24;

import "@aragon/os/contracts/factory/DAOFactory.sol";
import "@aragon/os/contracts/apm/Repo.sol";
import "@aragon/os/contracts/lib/ens/ENS.sol";
import "@aragon/os/contracts/lib/ens/PublicResolver.sol";
import "@aragon/os/contracts/apm/APMNamehash.sol";

import "@aragon/apps-token-manager/contracts/TokenManager.sol";
import "@aragon/apps-shared-minime/contracts/MiniMeToken.sol";
import "@daonuts/token/contracts/Token.sol";

import "./Airdrop.sol";


contract TemplateBase is APMNamehash {
    ENS public ens;
    DAOFactory public fac;

    event DeployDao(address dao);
    event InstalledApp(address appProxy, bytes32 appId);

    constructor(DAOFactory _fac, ENS _ens) public {
        ens = _ens;

        // If no factory is passed, get it from on-chain bare-kit
        if (address(_fac) == address(0)) {
            bytes32 bareKit = apmNamehash("bare-kit");
            fac = TemplateBase(latestVersionAppBase(bareKit)).fac();
        } else {
            fac = _fac;
        }
    }

    function latestVersionAppBase(bytes32 appId) public view returns (address base) {
        Repo repo = Repo(PublicResolver(ens.resolver(appId)).addr(appId));
        (,base,) = repo.getLatest();

        return base;
    }
}


contract Template is TemplateBase {
    /* MiniMeTokenFactory tokenFactory; */

    uint64 constant PCT = 10 ** 16;
    address constant ANY_ENTITY = address(-1);

    constructor(ENS ens) TemplateBase(DAOFactory(0), ens) public {
        /* tokenFactory = new MiniMeTokenFactory(); */
    }

    function newInstance() public {
        Kernel dao = fac.newDAO(this);
        ACL acl = ACL(dao.acl());
        acl.createPermission(this, dao, dao.APP_MANAGER_ROLE(), this);

        bytes32 airdropAppId = keccak256(abi.encodePacked(apmNamehash("open"), keccak256("airdrop-app")));
        bytes32 tokenManagerAppId = apmNamehash("token-manager");

        Airdrop airdrop = Airdrop(dao.newAppInstance(airdropAppId, latestVersionAppBase(airdropAppId)));
        TokenManager tokenManager = TokenManager(dao.newAppInstance(tokenManagerAppId, latestVersionAppBase(tokenManagerAppId)));

        Token token = new Token("Token", 18, "TOKEN", false);
        token.changeController(tokenManager);

        // Initialize apps
        tokenManager.initialize(MiniMeToken(token), false, 0);
        emit InstalledApp(tokenManager, tokenManagerAppId);
        /* bytes32 root = 0x3e2cfb838b2ad1503bf79a4391e990a014b1eaf20f5de80ac5e441b8ee6e90e4; */
        /* string memory dataURI = "ipfs:QmQJa54XQwEPeyPvUg2bCKZD6AK98hMB4zU4gU1EgpQG4P"; */
        /* airdrop.initialize(tokenManager, root, dataURI); */
        airdrop.initialize(tokenManager, bytes32(0), "");
        emit InstalledApp(airdrop, airdropAppId);

        acl.createPermission(msg.sender, tokenManager, tokenManager.BURN_ROLE(), msg.sender);
        acl.createPermission(msg.sender, airdrop, airdrop.START_ROLE(), msg.sender);
        acl.createPermission(this, tokenManager, tokenManager.MINT_ROLE(), this);

        tokenManager.mint(msg.sender, 100000 * 10**18); // Give 1 token to each holder

        // Clean up permissions

        acl.grantPermission(airdrop, tokenManager, tokenManager.MINT_ROLE());
        acl.revokePermission(this, tokenManager, tokenManager.MINT_ROLE());
        acl.setPermissionManager(msg.sender, tokenManager, tokenManager.MINT_ROLE());

        acl.grantPermission(msg.sender, dao, dao.APP_MANAGER_ROLE());
        acl.revokePermission(this, dao, dao.APP_MANAGER_ROLE());
        acl.setPermissionManager(msg.sender, dao, dao.APP_MANAGER_ROLE());

        acl.grantPermission(msg.sender, acl, acl.CREATE_PERMISSIONS_ROLE());
        acl.revokePermission(this, acl, acl.CREATE_PERMISSIONS_ROLE());
        acl.setPermissionManager(msg.sender, acl, acl.CREATE_PERMISSIONS_ROLE());

        emit DeployDao(dao);
    }

}
