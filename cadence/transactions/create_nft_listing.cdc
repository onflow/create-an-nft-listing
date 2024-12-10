import "NFTStorefront"
import "NonFungibleToken"
import "FungibleToken"
import "ExampleNFT"


transaction {
    let storefront: auth(NFTStorefront.CreateListing) &NFTStorefront.Storefront
    let exampleNFTProvider: Capability<&{ExampleNFT.CollectionInterface}>
    let tokenReceiver: Capability<&{FungibleToken.Receiver}>
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Retrieve the storefront capability
        let storefrontCap = signer.capabilities.get<&NFTStorefront.Storefront>(
            NFTStorefront.StorefrontStoragePath
        )

        // Borrow the resource from the capability
        self.storefront = storefrontCap.borrow()
            ?? panic("Cannot borrow storefront resource")

        // Ensure the ExampleNFT Collection capability is published
        if signer.capabilities.get<&{ExampleNFT.CollectionInterface}>(
            ExampleNFT.CollectionPublicPath
        ) == nil {
            let issuedCapability = signer.capabilities.storage.issue<&ExampleNFT.Collection>(
                ExampleNFT.CollectionStoragePath
            )
            signer.capabilities.publish(issuedCapability, at: ExampleNFT.CollectionPublicPath)
        }

        // Retrieve and verify the ExampleNFT Collection capability
        let nftProviderCap = signer.capabilities.get<&{ExampleNFT.CollectionInterface}>(
            ExampleNFT.CollectionPublicPath
        )
        self.exampleNFTProvider = nftProviderCap

        // Retrieve and verify the FungibleToken receiver capability
        let tokenReceiverCap = signer.capabilities.get<&{FungibleToken.Receiver}>(
            /public/MainReceiver
        )
        self.tokenReceiver = tokenReceiverCap

        // Create a sale cut
        let saleCut = NFTStorefront.SaleCut(
            receiver: self.tokenReceiver,
            amount: 10.0
        )

        // Create the listing
        let listingID = self.storefront.createListing(
            nftProviderCapability: self.exampleNFTProvider,
            nftType: Type<@ExampleNFT.NFT>(),
            nftID: 1,
            salePaymentVaultType: Type<@FungibleToken.Vault>(),
            saleCuts: [saleCut]
        )

        log("Storefront listing created with ID: ".concat(listingID.toString()))
    }
}
