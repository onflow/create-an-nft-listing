/// ExampleNFT.cdc
///
/// This is a complete version of the ExampleNFT contract
/// that includes withdraw and deposit functionalities, as well as a
/// collection resource that can be used to bundle NFTs together.
///
/// Learn more about non-fungible tokens in this tutorial: https://developers.flow.com/cadence/tutorial/non-fungible-tokens-1

access(all) contract ExampleNFT {

    // Declare Path constants so paths do not have to be hardcoded
    // in transactions and scripts

    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) let MinterStoragePath: StoragePath

    // Tracks the unique IDs of the NFTs
    access(all) var idCount: UInt64

    // Declare the NFT resource type
    access(all) resource NFT {
        // The unique ID that differentiates each NFT
        access(all) let id: UInt64

        // Initialize both fields in the initializer
        init(initID: UInt64) {
            self.id = initID
        }
    }

    access(all) entitlement Withdraw

    // The definition of the Collection resource that
    // holds the NFTs that a user owns
    access(all) resource Collection {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        access(all) var ownedNFTs: @{UInt64: NFT}

        // Initialize the NFTs field to an empty collection
        init () {
            self.ownedNFTs <- {}
        }

        // withdraw
        //
        // Function that removes an NFT from the collection
        // and moves it to the calling context
        access(Withdraw) fun withdraw(withdrawID: UInt64): @NFT {
            // If the NFT isn't found, the transaction panics and reverts
            let token <- self.ownedNFTs.remove(key: withdrawID)
                ?? panic("Could not withdraw an ExampleNFT.NFT with id="
                          .concat(withdrawID.toString())
                          .concat("Verify that the collection owns the NFT ")
                          .concat("with the specified ID first before withdrawing it."))

            return <-token
        }

        // deposit
        //
        // Function that takes a NFT as an argument and
        // adds it to the collections dictionary
        access(all) fun deposit(token: @NFT) {
            // add the new token to the dictionary with a force assignment
            // if there is already a value at that key, it will fail and revert
            self.ownedNFTs[token.id] <-! token
        }

        // idExists checks to see if a NFT
        // with the given ID exists in the collection
        access(all) view fun idExists(id: UInt64): Bool {
            return self.ownedNFTs[id] != nil
        }

        // getIDs returns an array of the IDs that are in the collection
        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }
    }

    // creates a new empty Collection resource and returns it
    access(all) fun createEmptyCollection(): @Collection {
        return <- create Collection()
    }

    // mintNFT
    //
    // Function that mints a new NFT with a new ID
    // and returns it to the caller
    access(all) fun mintNFT(): @NFT {

        // create a new NFT
        var newNFT <- create NFT(initID: self.idCount)

        // change the id so that each ID is unique
        self.idCount = self.idCount + 1

        return <-newNFT
    }

	init() {
        self.CollectionStoragePath = /storage/nftTutorialCollection
        self.CollectionPublicPath = /public/nftTutorialCollection
        self.MinterStoragePath = /storage/nftTutorialMinter

        // initialize the ID count to one
        self.idCount = 1

        // store an empty NFT Collection in account storage
        self.account.storage.save(<-self.createEmptyCollection(), to: self.CollectionStoragePath)

        // publish a capability to the Collection in storage
        let cap = self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
        self.account.capabilities.publish(cap, at: self.CollectionPublicPath)
	}
}