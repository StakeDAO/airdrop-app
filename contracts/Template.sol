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

import "@aragon/apps-shared-minime/contracts/MiniMeToken.sol";
import "@daonuts/token/contracts/Token.sol";
import "@aragon/apps-agent/contracts/Agent.sol";
import "@aragon/apps-finance/contracts/Finance.sol";

import "./ICycleManager.sol";
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
    address public sctAddress;

    constructor(ENS ens, address _sctAddress) TemplateBase(DAOFactory(0), ens) public {
        /* tokenFactory = new MiniMeTokenFactory(); */
        sctAddress = _sctAddress;
    }

    function newInstance() public {
        Kernel dao = fac.newDAO(this);
        ACL acl = ACL(dao.acl());
        acl.createPermission(this, dao, dao.APP_MANAGER_ROLE(), this);

        ICycleManager cycleManager = _setupCycleManager(dao, acl);
        Agent agent = _setupAgent(dao, acl);
        Finance finance = _setupFinance(dao, acl, agent);
        Airdrop airdrop = _setupAirdop(dao, acl, agent, cycleManager, sctAddress);

//        Token token = new Token("Token", 18, "TOKEN", false);

        // Clean up permissions

        acl.grantPermission(msg.sender, dao, dao.APP_MANAGER_ROLE());
        acl.revokePermission(this, dao, dao.APP_MANAGER_ROLE());
        acl.setPermissionManager(msg.sender, dao, dao.APP_MANAGER_ROLE());

        acl.grantPermission(msg.sender, acl, acl.CREATE_PERMISSIONS_ROLE());
        acl.revokePermission(this, acl, acl.CREATE_PERMISSIONS_ROLE());
        acl.setPermissionManager(msg.sender, acl, acl.CREATE_PERMISSIONS_ROLE());

        emit DeployDao(dao);
    }

    function _setupAirdop(Kernel _dao, ACL _acl, Agent _agent, ICycleManager _cycleManager, address _sctAddress) internal returns (Airdrop) {
        bytes32 airdropAppId = keccak256(abi.encodePacked(apmNamehash("open"), keccak256("airdrop-app-sc")));
        Airdrop airdrop = Airdrop(_dao.newAppInstance(airdropAppId, latestVersionAppBase(airdropAppId)));
        airdrop.initialize(_agent, _cycleManager, _sctAddress, bytes32(0), "");
        emit InstalledApp(airdrop, airdropAppId);

        _acl.createPermission(msg.sender, airdrop, airdrop.START_ROLE(), msg.sender);

        return airdrop;
    }

    function _setupAgent(Kernel _dao, ACL _acl) internal returns (Agent) {
        bytes32 appId = apmNamehash("agent");
        Agent agent = Agent(_dao.newAppInstance(appId, latestVersionAppBase(appId)));
        agent.initialize();

        _acl.createPermission(ANY_ENTITY, agent, agent.TRANSFER_ROLE(), ANY_ENTITY);

        return agent;
    }

    function _setupFinance(Kernel _dao, ACL _acl, Agent _agent) internal returns (Finance) {
        bytes32 appId = apmNamehash("finance");
        Finance finance = Finance(_dao.newAppInstance(appId, latestVersionAppBase(appId)));
        finance.initialize(_agent, uint64(1 days));

        _acl.createPermission(ANY_ENTITY, finance, finance.CREATE_PAYMENTS_ROLE(), ANY_ENTITY);

        return finance;
    }

    function _setupCycleManager(Kernel _dao, ACL _acl) internal returns (ICycleManager) {
        bytes32 appId = keccak256(abi.encodePacked(apmNamehash("open"), keccak256("cycle-manager")));
        bytes memory initializeData = abi.encodeWithSelector(ICycleManager(0).initialize.selector, 60);
        address latestBaseAppAddress = latestVersionAppBase(appId);
        ICycleManager cycleManager = ICycleManager(_dao.newAppInstance(appId, latestBaseAppAddress, initializeData, false));

        _acl.createPermission(ANY_ENTITY, cycleManager, cycleManager.UPDATE_CYCLE_ROLE(), ANY_ENTITY);
        _acl.createPermission(ANY_ENTITY, cycleManager, cycleManager.START_CYCLE_ROLE(), ANY_ENTITY);

        return cycleManager;
    }

}
