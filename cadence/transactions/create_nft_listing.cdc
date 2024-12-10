import "NFTStorefront"
import "NonFungibleToken"
import "FungibleToken"
import "ExampleNFT"

transaction {
    let storefront: auth(NFTStorefront.CreateListing) &NFTStorefront.Storefront
    let exampleNFTProvider: Capability<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>
    let tokenReceiver: Capability<&{FungibleToken.Receiver}>
    
    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Retrieve the storefront capability with the correct entitlement
        let storefrontCap = signer.capabilities.get<auth(NFTStorefront.CreateListing) &NFTStorefront.Storefront>(
            NFTStorefront.StorefrontPublicPath
        )
        
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
            nftType: Type<@{NonFungibleToken.NFT}>(),
            nftID: 1,
            salePaymentVaultType: Type<@{FungibleToken.Vault}>(),
            saleCuts: [saleCut]
        )

        log("Storefront listing created with ID: ".concat(listingID.toString()))
    }
}