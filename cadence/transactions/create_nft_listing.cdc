import "NFTStorefront"
import "NonFungibleToken"
import "FungibleToken"
import "ExampleNFT"

transaction {
    let storefront: auth(NFTStorefront.CreateListing) &NFTStorefront.Storefront
    let exampleNFTProvider: Capability<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>
    let tokenReceiver: Capability<&{FungibleToken.Receiver}>
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Retrieve the storefront capability using the public path
        let storefrontCap = signer.capabilities.get<&NFTStorefront.Storefront>(
            NFTStorefront.StorefrontPublicPath
        ) ?? panic("Cannot find storefront capability")

        // Borrow the resource from the capability
        self.storefront = storefrontCap.borrow()
            ?? panic("Cannot borrow storefront resource")

        // Ensure the ExampleNFT Collection capability is published
        if signer.capabilities.get<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(
            ExampleNFT.CollectionPublicPath
        ) == nil {
            let issuedCapability = signer.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(
                ExampleNFT.CollectionStoragePath
            )
            signer.capabilities.publish(issuedCapability, at: ExampleNFT.CollectionPublicPath)
        }

        // Retrieve and verify the ExampleNFT Collection capability
        let nftProviderCap = signer.capabilities.get<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(
            ExampleNFT.CollectionPublicPath
        ) ?? panic("Missing or mis-typed ExampleNFT.Collection capability")
        self.exampleNFTProvider = nftProviderCap

        // Retrieve and verify the FungibleToken receiver capability
        let tokenReceiverCap = signer.capabilities.get<&{FungibleToken.Receiver}>(
            /public/MainReceiver
        ) ?? panic("Missing or mis-typed FlowToken receiver")
        self.tokenReceiver = tokenReceiverCap

        // Create a sale cut
        let saleCut = NFTStorefront.SaleCut(
            receiver: self.tokenReceiver,
            amount: 10.0
        )

        // Create the listing
        let listingID = self.storefront.createListing(
            nftProviderCapability: self.exampleNFTProvider,
            nftType: Type<@{NonFungibleToken.NFT}>(),
            nftID: 1,
            salePaymentVaultType: Type<@{FungibleToken.Vault}>(),
            saleCuts: [saleCut]
        )

        log("Storefront listing created with ID: ".concat(listingID.toString()))
    }
}
