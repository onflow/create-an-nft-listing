import "FungibleToken"
import "NonFungibleToken"
import "ExampleNFT"
import "NFTStorefront"

transaction {
    let storefront: auth(NFTStorefront.CreateListing) &NFTStorefront.Storefront

     prepare(acct: auth(Storage, Capabilities, NFTStorefront.CreateListing) &Account) {

        // Create and save the storefront
        let storefront <- NFTStorefront.createStorefront()
        acct.storage.save(<-storefront, to: NFTStorefront.StorefrontStoragePath)

        // Publish the storefront capability to the public path
        let storefrontCap = acct.capabilities.storage.issue<&{NFTStorefront.StorefrontPublic}>(
            NFTStorefront.StorefrontStoragePath
        )
        acct.capabilities.publish(storefrontCap, at: NFTStorefront.StorefrontPublicPath)

        // Borrow the storefront reference using the public capability path
        let storefrontRef = acct.capabilities.borrow<&{NFTStorefront.StorefrontPublic}>(
            NFTStorefront.StorefrontPublicPath
        ) ?? panic("Could not borrow Storefront from provided address")
        // Borrow the storefront reference directly from storage
        self.storefront = acct.storage.borrow<auth(NFTStorefront.CreateListing) &NFTStorefront.Storefront>(
            from: NFTStorefront.StorefrontStoragePath
        ) ?? panic("Could not borrow Storefront with CreateListing authorization from storage")

        // Borrow the NFTMinter from the caller's storage
        let minter = acct.storage.borrow<&ExampleNFT.NFTMinter>(
            from: /storage/exampleNFTMinter
        ) ?? panic("Could not borrow the NFT minter reference.")

        // Mint a new NFT with metadata
        let nft <- minter.mintNFT(
            name: "Example NFT",
            description: "Minting a sample NFT",
            thumbnail: "https://example.com/thumbnail.png",
            royalties: [],
            metadata: {
                "Power": "100",
                "Will": "Strong",
                "Determination": "Unyielding"
            },
            
        )

        let nftID = nft.id

        // Borrow the collection from the caller's storage
        let collection = acct.storage.borrow<&ExampleNFT.Collection>(
            from: /storage/exampleNFTCollection
        ) ?? panic("Could not borrow the NFT collection reference.")

        // Deposit the newly minted NFT into the caller's collection
        collection.deposit(token: <-nft)


        let nftProviderCapability = acct.capabilities.storage.issue<auth(NonFungibleToken.Withdraw) &{NonFungibleToken.Collection}>(
            /storage/exampleNFTCollection
        )
        
        // List the NFT
        self.storefront.createListing(
            nftProviderCapability: nftProviderCapability,
            nftType: Type<@ExampleNFT.NFT>(),
            nftID: nftID,
            salePaymentVaultType: Type<@{FungibleToken.Vault}>(),
            saleCuts: [
                NFTStorefront.SaleCut(
                    receiver: acct.capabilities.get<&{FungibleToken.Receiver}>(
                        /public/flowTokenReceiver
                    )!,
                    amount: 1.0
                )
            ]
        )
        log("Listing created successfully")
    }
}