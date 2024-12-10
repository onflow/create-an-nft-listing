import "NFTStorefront"
import "NonFungibleToken"
import "FungibleToken"
import "ExampleNFT"
import "FlowToken"

transaction {
    let storefront: auth(NFTStorefront.CreateListing) &NFTStorefront.Storefront
    let exampleNFTProvider: Capability<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>
    let tokenReceiver: Capability<&{FungibleToken.Receiver}>

    prepare(signer: auth(Storage, Capabilities) &Account) {
        // Ensure the storefront exists
        if signer.storage.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath) != nil {
            let oldStorefront <- signer.storage.load<@NFTStorefront.Storefront>(
                from: NFTStorefront.StorefrontStoragePath
            ) ?? panic("Failed to load existing storefront resource for deletion.")
            destroy oldStorefront
        }

        let newStorefront <- NFTStorefront.createStorefront()
        signer.storage.save(<-newStorefront, to: NFTStorefront.StorefrontStoragePath)

        let privateStorefrontCap = signer.capabilities.storage.issue<auth(NFTStorefront.CreateListing) &NFTStorefront.Storefront>(
            NFTStorefront.StorefrontStoragePath
        )
        self.storefront = privateStorefrontCap.borrow()
            ?? panic("Cannot borrow storefront with the correct auth capability.")

        // Ensure the ExampleNFT collection resource exists
        if signer.storage.borrow<&ExampleNFT.Collection>(from: ExampleNFT.CollectionStoragePath) == nil {
            panic("The ExampleNFT collection resource is missing at the expected storage path.")
        }

        // Issue and publish ExampleNFT capability
        if signer.capabilities.get<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(
            ExampleNFT.CollectionPublicPath
        ) == nil {
            let nftCap = signer.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(
                ExampleNFT.CollectionStoragePath
            )
            signer.capabilities.publish(nftCap, at: ExampleNFT.CollectionPublicPath)
        }

        self.exampleNFTProvider = signer.capabilities.get<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(
            ExampleNFT.CollectionPublicPath
        )

        // Ensure FlowToken vault exists
        if signer.storage.borrow<&{FungibleToken.Receiver}>(from: /storage/flowTokenVault) == nil {
            let newVault <- FlowToken.createEmptyVault(vaultType: Type<@FlowToken.Vault>())
            signer.storage.save(<-newVault, to: /storage/flowTokenVault)
        }

        // Publish FlowToken receiver capability if not available
        if signer.capabilities.get<&{FungibleToken.Receiver}>(
            /public/flowTokenReceiver
        ) == nil {
            let receiverCap = signer.capabilities.storage.issue<&{FungibleToken.Receiver}>(
                /storage/flowTokenVault
            )
            signer.capabilities.publish(receiverCap, at: /public/flowTokenReceiver)
        }

        self.tokenReceiver = signer.capabilities.get<&{FungibleToken.Receiver}>(
            /public/flowTokenReceiver
        )
    }

    execute {
        let receiverRef = self.tokenReceiver.borrow()
            ?? panic("Cannot borrow FlowToken receiver capability.")

        let saleCut = NFTStorefront.SaleCut(
            receiver: self.tokenReceiver,
            amount: 10.0
        )

        log(self.exampleNFTProvider)

        let listingID = self.storefront.createListing(
            nftProviderCapability: self.exampleNFTProvider,
            nftType: Type<@ExampleNFT.NFT>(),
            nftID: 1,
            salePaymentVaultType: Type<@FlowToken.Vault>(),
            saleCuts: [saleCut]
        )

        log("Storefront listing created with ID: ".concat(listingID.toString()))
    }
}