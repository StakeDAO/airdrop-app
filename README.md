# Airdrop

Airdrop is an Aragon app to facilitate the efficient distribution of tokens.

### How it works

1. Airdrop data is uploaded as a csv or pulled from an online source
2. A merkle tree is generated and uploaded to ipfs
3. A transaction is submitted, protected by `START_ROLE`, to the Airdrop contract which includes the ipfs hash and merkle root
4. Once accepted the tokens from that distribution are available to `award`. These tx can be submitted by either the recipient or a third party on their behalf.
5. `awardFromMany` allows for combining the amounts from multiple airdrops
6. `awardToMany` allows for bulk awarding to recipients from a single airdrop

## Local Deployment

1) Install dependencies:
```
$ npm install
```
May require `npm install node-gyp` first

2) In a separate terminal start the devchain:
```
$ npx aragon devchain
```

3) Deploy the CycleManager app to the devchain as it's not installed by default like the other main apps (Voting, Token Manager, Agent etc):
- Download https://github.com/StakeDAO/cycle-manager-aragon-app
- Run `npm install` in the root folder
- Execute `npm run build` in the root folder
- Execute `npm run publish:major` in the root folder

5) Deploy mock SCT tokens:
```
$ truffle exec scripts/deployToken.js --network rpc
```
Copy the SCT token addresses output to the `package.json` script `start:http:template` directly after the `@ARAGON_ENS` template init arg
replacing the address that is there already.

6) In a separate terminal start the client (the web portion of the app):
```
$ npm run start:client
```
7) In a separate terminal deploy a DAO including the app with:
```
$ npm run start:http:template
```