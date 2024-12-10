import "NFTStorefront"
import "NonFungibleToken"
import "ExampleNFT"
import "FungibleToken"

transaction {

    // Reference to the NFTStorefront.Storefront resource.
    let storefront: &NFTStorefront.Storefront 

    // Capability for the ExampleNFT.Collection, allowing NFT interactions.
    let exampleNFTProvider: Capability<&ExampleNFT.Collection>

    // Capability for the FungibleToken.Vault, allowing token interactions.
    let tokenReceiver: Capability<&FungibleToken.Vault>
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Borrow the storefront reference.
        self.storefront = signer.storage.borrow<&NFTStorefront.Storefront>(at: NFTStorefront.StorefrontStoragePath)
            ?? panic("Cannot borrow storefront")

        // Check and link the ExampleNFT.Collection capability if it doesn't exist.
        if signer.capabilities.storage.get<&ExampleNFT.Collection>(at: ExampleNFT.CollectionPrivatePath).check() == false {
            let cap = signer.capabilities.storage.issue<&ExampleNFT.Collection>(ExampleNFT.CollectionPrivatePath, target: ExampleNFT.CollectionStoragePath)
            signer.capabilities.publish(cap, at: ExampleNFT.CollectionPublicPath)
        }

        // Retrieve the ExampleNFT.Collection capability.
        self.exampleNFTProvider = signer.capabilities.storage.get<&ExampleNFT.Collection>(at: ExampleNFT.CollectionPrivatePath)!
        assert(self.exampleNFTProvider.borrow() != nil, message: "Missing or mis-typed ExampleNFT.Collection provider")

        // Retrieve the FungibleToken.Vault receiver capability.
        self.tokenReceiver = signer.capabilities.get<&FungibleToken.Vault>(/public/MainReceiver)!
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
