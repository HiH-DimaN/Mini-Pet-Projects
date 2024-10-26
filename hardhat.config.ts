import "dotenv/config";
import type { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
	solidity: {
		version: "0.8.26",
		settings: {
			evmVersion: "cancun",
			optimizer: {
				enabled: true,
				runs: 2000,
			},
		},
	},
	networks: {
		hardhat: {
			chainId: 1337,
			initialBaseFeePerGas: 0,
		},
  }
};

export default config;
