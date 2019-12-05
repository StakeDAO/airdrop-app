const ethers = require('ethers');
const AirdropDuoABI = require('../abi/AirdropDuo.json').abi
const TokenABI = require('../abi/Token.json').abi
const provider = new ethers.providers.Web3Provider(web3.currentProvider, 'mainnet')
const { utils } = ethers;
const { toUtf8Bytes, hexlify, hexZeroPad, bigNumberify, parseUnits, solidityKeccak256 } = utils
const decimals = "1000000000000000000"

// const airdropDuoAddress = "0xa2b6218673bac129127be86106a9d5d205814edc"
// const airdropDuoAddress = "0x224ef947af702cd86f8c74cb79ed5fdbf9c1bb1e"
const airdropDuoAddress = "0xdf3f15162051c992bcf63f0f21f6d66f3d0f1257"

const ipfsGateway = location.hostname === 'localhost' ? 'http://localhost:8080/ipfs' : 'https://ipfs.eth.aragon.network/ipfs'
const id = 1
const batchSize = 50

async function main(){
  await ethereum.enable()
  const airdropDuo = new ethers.Contract(airdropDuoAddress, AirdropDuoABI,  provider.getSigner())

  let airdrop = await airdropDuo.airdrops(id)
  let hash = airdrop.dataURI.split(":")[1]
  let { awards } = await (await fetch(`${ipfsGateway}/${hash}`)).json()

  console.log(awards)

  let idx = 0, recipients = [], amount0s = [], amount1s = [], proofLengths = [], proofs = "0x"
  while (recipients.length < batchSize && idx < awards.length){
    let award = awards[idx++]

    // let valid = await airdropDuo.validate(airdrop.root, award.proof, solidityKeccak256(["address", "uint256", "uint256"],[award.address, award.amount0, award.amount1]))
    // console.log(valid)
    let awarded = await airdropDuo.awarded(1, award.address)
    // console.log("here", awarded, award.username)
    console.log(awarded)

    if(awarded)
      continue

    recipients.push(award.address)
    amount0s.push(award.amount0)
    amount1s.push(award.amount1)
    proofs += award.proof.map(p=>p.slice(2)).join("")
    proofLengths.push(award.proof.length)
  }

  console.log(recipients.length)
  if(recipients.length)
    await airdropDuo.awardToMany(id, recipients, amount0s, amount1s, proofs, proofLengths, {
        // The price (in wei) per unit of gas
        gasLimit: 9500000,
        gasPrice: parseUnits("3.0", 'gwei')
    })

}

main()
