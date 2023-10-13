// Pass the repo name
const recipe = "create-an-nft-listing";

//Generate paths of each code file to render
const contractPath = `${recipe}/cadence/contract.cdc`;
const transactionPath = `${recipe}/cadence/transaction.cdc`;

//Generate paths of each explanation file to render
const smartContractExplanationPath = `${recipe}/explanations/contract.txt`;
const transactionExplanationPath = `${recipe}/explanations/transaction.txt`;

export const createAnNFTListing = {
  slug: recipe,
  title: "Create an NFT Listing",
  createdAt: Date(2022, 9, 14),
  author: "Flow Blockchain",
  playgroundLink:
    "https://play.onflow.org/1d11f838-fc0e-4e7f-86e3-6d1a5a1098e3?type=tx&id=22eb2922-b8e0-4817-a345-39929285dff1&storage=none",
  excerpt:
    "List an NFT to be sold using the NFTStorefront contract.",
  smartContractCode: contractPath,
  smartContractExplanation: smartContractExplanationPath,
  transactionCode: transactionPath,
  transactionExplanation: transactionExplanationPath,
};
