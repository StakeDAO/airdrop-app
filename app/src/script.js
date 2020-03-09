import 'core-js/stable'
import 'regenerator-runtime/runtime'
import AragonApi from '@aragon/api'

const DEBUG = true;
const debugLog = async (message) => {if (DEBUG) {console.log(message)}}

const api = new AragonApi()
let account

api.store(
  async (state, event) => {
    let newState

    // console.log("airdrop", event)

    switch (event.event) {
      case 'ACCOUNTS_TRIGGER':
        account = event.returnValues.account
        newState = state
        break
      case 'Start':
        debugLog("START EVENT")
        let airdrop = await marshalAirdrop(parseInt(event.returnValues.id))
        newState = { ...state, rawAirdrops: [airdrop].concat(state.rawAirdrops || []) }
        break
      case 'Award':
        debugLog("AWARD")
        const {id, recipient} = event.returnValues
        newState = { ...state }
        break
      default:
        newState = state
    }

    return newState
  },
  {
    init: async function(cachedState){
      return {
        rawAirdrops: [],
      ...cachedState
      }
    }
  }
)

async function marshalAirdrop(id) {
  let {root, dataURI} = await api.call('airdrops', id).toPromise()
  return { id, root, dataURI }
}
