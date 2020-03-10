import React, { useState, useEffect } from 'react'
import { useAragonApi } from '@aragon/api-react'
import {
  AppBar, AppView, Button, Card, CardLayout, Checkbox, Field, GU, Header, IconArrowRight,
  Info, Main, Modal, SidePanel, Text, TextInput, theme
} from '@aragon/ui'
import BigNumber from 'bignumber.js'

function Airdrops({airdrops, onSelect}){

  const { api, connectedAccount } = useAragonApi()

  const [retrieving, setRetrieving] = useState([])
  const [ready, setReady] = useState([])
  const [archived, setArchived] = useState([])
  useEffect(()=>{
    setRetrieving( airdrops.filter(a=>(!a.data)) )
    setReady( airdrops.filter(a=>(a.data && !a.awarded && a.userData)) )
    setArchived( airdrops.filter(a=>(a.data && (a.awarded || !a.userData))) )
  },[airdrops])

  const claimAllAwards = (event) => {
    event.stopPropagation()

    const ids = ready.map(award => award.id)
    const amounts = ready.map(award => award.userData.amount)
    const proofs = ready
      .map(award => award.userData.proof)
      .reduce((allProofs, awardProofs) => allProofs.concat(awardProofs))
      .reduce((proofsString, proof) => proofsString.concat(proof.slice(2)))
    const proofLengths = ready.map(award => award.userData.proof.length)

    api.awardFromMany(ids, connectedAccount, amounts, proofs, proofLengths).toPromise()
  }

  return (
    <React.Fragment>
      {retrieving.length ?
      <section>
        <h2 size="xlarge">Retrieving data:</h2>
        <CardLayout columnWidthMin={30 * GU} rowHeight={250}>
          {retrieving.map((d, i)=><AirdropCard {...d} key={d.id} onSelect={onSelect} />)}
        </CardLayout>
      </section> : null}
      {ready.length ?
      <section>
        <h2 size="xlarge">Ready to claim:</h2>
        <CardLayout columnWidthMin={30 * GU} rowHeight={250}>
          {ready.map((d, i)=><AirdropCard {...d} key={d.id} onSelect={onSelect} />)}
        </CardLayout>

        {ready.length > 1 ?
        < Button mode="strong" emphasis="positive" onClick={(event) => claimAllAwards(event)}>
          Claim All Awards
          </Button> : null
        }

      </section> : null}
      {archived.length ?
      <section css={`
          margin-top: 30px;`}>
        <h2 size="xlarge">Archive:</h2>
        <CardLayout columnWidthMin={30 * GU} rowHeight={150}>
          {archived.map((d, i)=><AirdropCard {...d} key={d.id} onSelect={onSelect} />)}
        </CardLayout>
      </section> : null}
    </React.Fragment>
  )
}

function AirdropCard({id, root, dataURI, data, awarded, userData, onSelect}) {
  const { api, connectedAccount } = useAragonApi()
  // const { id, root, dataURI, data, awarded, userData } = airdrop

  return (
    <Card css={`
        display: grid;
        grid-template-columns: 100%;
        grid-template-rows: auto 1fr auto auto;
        grid-gap: ${1 * GU}px;
        padding: ${3 * GU}px;
        cursor: pointer;
    `} onClick={()=>onSelect(id)}>
      <header style={{display: "flex", justifyContent: "space-between"}}>
        <Text color={theme.textTertiary}>#{id}</Text>
        <IconArrowRight color={theme.textTertiary} />
      </header>
      <section>
        {!awarded && !data &&
        <Info style={{marginBottom: "10px"}}>Retrieving airdrop data...</Info>}
        {data && !userData &&
        <Info style={{marginBottom: "10px"}}>Nothing to claim</Info>}
        {awarded &&
        <Info style={{marginBottom: "10px"}}>You were awarded</Info>}
        {!awarded && userData &&
        <Info style={{marginBottom: "10px"}}>You can claim <br/>{BigNumber(userData.amount).div("1e+18").toFixed()}</Info>}
      </section>
      <footer style={{display: "flex", justifyContent: "flex-end"}}>
        {!awarded && userData &&
        <Button mode="strong" emphasis="positive" onClick={(e)=>{e.stopPropagation();api.award(id, connectedAccount, userData.amount, userData.proof).toPromise()}}>Claim</Button>}
      </footer>
    </Card>
  )
}

export default Airdrops
