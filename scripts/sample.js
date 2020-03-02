const Web3 = require("web3")
const web3 = new Web3("wss://rinkeby.infura.io/ws")
const abi = require("../build/contracts/Airdrop.json").abi
const Airdrop = new web3.eth.Contract(abi, "0x03a4Ad30730a205C286aFE2aB069E5eddF102D8a")

Airdrop.events.UserAwarded({fromBlock: 0}, (err, e)=>{
  if(err) throw err;
  // excuse the following line. e.returnValues should be used but isn't showing correct values. something i don't understand. so i'm just parsing raw
  let [root, username, award] = e.raw.data.substring(2).match(/.{1,64}/g).map(h=>`0x${h}`)
  username = web3.utils.hexToUtf8(username)
  award = web3.utils.toBN(award)
  console.log(`${username} was awarded ${award}`)
  // > dummy02 was awarded 1500000000000000000000000
})
