import "NFTStorefront"
import "NonFungibleToken"
import "FungibleToken"
import "ExampleNFT"

transaction {
    let storefront: auth(NFTStorefront.CreateListing) &NFTStorefront.Storefront
    let exampleNFTProvider: Capability<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>
    let tokenReceiver: Capability<&{FungibleToken.Receiver}> // Updated to store Capability

    prepare(signer: auth(Storage, Capabilities) &Account) {
        log("Checking if a storefront resource exists...")

        if signer.storage.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath) != nil {
            log("Existing storefront resource found. Destroying it...")
            
            let oldStorefront <- signer.storage.load<@NFTStorefront.Storefront>(
                from: NFTStorefront.StorefrontStoragePath
            ) ?? panic("Failed to load existing storefront resource for deletion.")
            destroy oldStorefront
            log("Existing storefront resource destroyed.")
        }

        log("Creating a new storefront resource...")
        let newStorefront <- NFTStorefront.createStorefront()
        log("New storefront resource created.")

        log("Saving the new storefront resource to storage...")
        signer.storage.save(
            <-newStorefront,
            to: NFTStorefront.StorefrontStoragePath
        )
        log("New storefront resource successfully saved to storage.")

        log("Publishing the new storefront capability...")
        let publicStorefrontCapability = signer.capabilities.storage.issue<&NFTStorefront.Storefront>(
            NFTStorefront.StorefrontStoragePath
        )
        signer.capabilities.publish(publicStorefrontCapability, at: NFTStorefront.StorefrontPublicPath)
        log("New public storefront capability issued and published successfully.")

        log("Validating the stored storefront resource...")
        let privateStorefrontCap = signer.capabilities.storage.issue<auth(NFTStorefront.CreateListing) &NFTStorefront.Storefront>(
            NFTStorefront.StorefrontStoragePath
        )
        self.storefront = privateStorefrontCap.borrow()
            ?? panic("Cannot borrow storefront resource with auth capability")
        log("Successfully borrowed the new storefront resource with auth capability.")

        log("Retrieving ExampleNFT Collection capability...")
        if signer.capabilities.get<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(
            ExampleNFT.CollectionPublicPath
        ) == nil {
            let issuedCapability = signer.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(
                ExampleNFT.CollectionStoragePath
            )
            signer.capabilities.publish(issuedCapability, at: ExampleNFT.CollectionPublicPath)
            log("ExampleNFT Collection capability issued and published.")
        }

        let nftProviderCap = signer.capabilities.get<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(
            ExampleNFT.CollectionPublicPath
        )
        self.exampleNFTProvider = nftProviderCap

        log("Retrieving FungibleToken receiver capability...")


        let tokenReceiverCap = signer.capabilities.get<&{FungibleToken.Receiver}>(
            /public/MainReceiver
        )
        assert(tokenReceiverCap != nil, message: "FungibleToken receiver capability not found.")
        log("FungibleToken receiver capability retrieved successfully.")
        self.tokenReceiver = tokenReceiverCap
        log("Borrowing the FungibleToken receiver reference...")
        let receiverRef = self.tokenReceiver.borrow()
            ?? panic("Cannot borrow FungibleToken receiver capability")
        log("Successfully borrowed FungibleToken receiver reference.")
        
        let saleCut = NFTStorefront.SaleCut(
            receiver: self.tokenReceiver, // Pass the Capability directly
            amount: 10.0
        )

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
