## basemo-contracts

This repo contains the smart contracts used to power [basemo](https://basemo.vercel.app/), a dapp built on the Base network that enables p2p payment requests and debt settlements.

The mission of this project is to provide an open source protocol for anyone to build a Venmo/Cashapp/Zelle like client. Its far from complete so use at your own risk.

The contract is currently deployed on Base Sepolia at [0xc6a51510147405fa576C2D81b741F976C732a537](https://sepolia.basescan.org/address/0xc6a51510147405fa576C2D81b741F976C732a537)

Functionality is currently limited to request a payment, settle a debt, and a cancel debt. More to come.

## Deployment

You'll need to have Foundry set up, checkout the docs here: https://book.getfoundry.sh/

You'll also need a .env, here is a sample:

```
BASE_SEPOLIA_USDC_CONTRACT_ADDRESS=0x036CbD53842c5426634e7929541eC2318f3dCF7e
BASE_SEPOLIA_RPC_URL=https://sepolia.base.org
BASESCAN_API_KEY=<YOU'LL NEED TO GET YOUR OWN API KEY>

```

There is a deployment script you can use once your env is properly set up.

```bash
forge script script/DeployBasedmo.s.sol --rpc-url $BASE_SEPOLIA_RPC_URL --account deployer --broadcast
```

## Contact me

Reach out X: https://x.com/stevegodlewski
