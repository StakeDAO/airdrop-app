const merklize = require("../app/src/merklize")
const csv = require('csvtojson')

async function main(){
  let data = await csv().fromFile(`${__dirname}/sample_distribution.csv`)
  console.log(merklize(data, ["amount"]))
}

main()
