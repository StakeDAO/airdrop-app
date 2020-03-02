# Airdrop

Airdrop is an Aragon app to facilitate the efficient distribution of tokens.

### How it works

1. Airdrop data is uploaded as a csv or pulled from an online source
2. A merkle tree is generated and uploaded to ipfs
3. A transaction is submitted, protected by `START_ROLE`, to the Airdrop contract which includes the ipfs hash and merkle root
4. Once accepted the tokens from that distribution are available to `award`. These tx can be submitted by either the recipient or a third party on their behalf.
5. `awardFromMany` allows for combining the amounts from multiple airdrops
6. `awardToMany` allows for bulk awarding to recipients from a single airdrop
