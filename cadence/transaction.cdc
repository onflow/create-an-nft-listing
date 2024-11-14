import NFTStorefront from 0x03
import NonFungibleToken from 0x02
import ExampleNFT from 0x04
import FungibleToken from 0x01

// This transaction sets up account 0x01 for the marketplace tutorial
// by publishing a Vault reference and creating an empty NFT Collection.
transaction {

    // Reference to the NFTStorefront.Storefront resource.
    let storefront: &NFTStorefront.Storefront 

    // Capability for the ExampleNFT.Collection, allowing NFT interactions.
    let exampleNFTProvider: Capability<&ExampleNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>

    // Capability for the FungibleToken.Vault, allowing token interactions.
    let tokenReceiver: Capability<&FungibleToken.Vault{FungibleToken.Receiver}>
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Borrow the storefront reference.
        self.storefront = signer.storage.borrow<&NFTStorefront.Storefront>(at: NFTStorefront.StorefrontStoragePath)
            ?? panic("Cannot borrow storefront")

        // Check and link the ExampleNFT.Collection capability if it doesn't exist.
        if signer.capabilities.storage.get<&ExampleNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(at: ExampleNFT.CollectionPrivatePath).check() == false {
            signer.capabilities.storage.issue<&ExampleNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(ExampleNFT.CollectionPrivatePath, target: ExampleNFT.CollectionStoragePath)
        }

        // Retrieve the ExampleNFT.Collection capability.
        self.exampleNFTProvider = signer.capabilities.storage.get<&ExampleNFT.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(at: ExampleNFT.CollectionPrivatePath)!
        assert(self.exampleNFTProvider.borrow() != nil, message: "Missing or mis-typed ExampleNFT.Collection provider")

        // Retrieve the FungibleToken.Vault receiver capability.
        self.tokenReceiver = signer.capabilities.get<&FungibleToken.Vault{FungibleToken.Receiver}>(/public/MainReceiver)!
        assert(self.tokenReceiver.borrow() != nil, message: "Missing or mis-typed FlowToken receiver")

        // Define a SaleCut with the token receiver and amount.
        let saleCut = NFTStorefront.SaleCut(
            receiver: self.tokenReceiver,
            amount: 10.0
        )

        // Create a new listing in the storefront.
        self.storefront.createListing(
            nftProviderCapability: self.exampleNFTProvider, 
            nftType: Type<@NonFungibleToken.NFT>(), 
            nftID: 0, 
            salePaymentVaultType: Type<@FungibleToken.Vault>(), 
            saleCuts: [saleCut]
        )

        log("Storefront listing created")
    }
}
