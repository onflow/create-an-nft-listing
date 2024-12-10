/// ExampleNFT.cdc
///
/// This is a complete version of the ExampleNFT contract
/// that includes withdraw and deposit functionalities, as well as a
/// collection resource that can be used to bundle NFTs together.
///
/// Learn more about non-fungible tokens in this tutorial: https://developers.flow.com/cadence/tutorial/non-fungible-tokens-1

access(all) contract ExampleNFT {

    // Declare Path constants
    access(all) let CollectionStoragePath: StoragePath
    access(all) let CollectionPublicPath: PublicPath
    access(all) let MinterStoragePath: StoragePath

    // Tracks the unique IDs of the NFTs
    access(all) var idCount: UInt64

    access(all) resource NFT {
        access(all) let id: UInt64
        init(initID: UInt64) {
            self.id = initID
        }
    }

    access(all) entitlement Withdraw

    // Interface defining required methods for the Collection
    access(all) resource interface CollectionInterface {
        access(all) fun deposit(token: @NFT)
        access(Withdraw) fun withdraw(withdrawID: UInt64): @NFT
        access(all) view fun getIDs(): [UInt64]
    }

    // Collection resource conforming to CollectionInterface
    access(all) resource Collection: CollectionInterface {
        access(all) var ownedNFTs: @{UInt64: NFT}

        init () {
            self.ownedNFTs <- {}
        }

        access(Withdraw) fun withdraw(withdrawID: UInt64): @NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID)
                ?? panic("Could not withdraw NFT with id=".concat(withdrawID.toString()))
            return <-token
        }

        access(all) fun deposit(token: @NFT) {
            self.ownedNFTs[token.id] <-! token
        }

        access(all) view fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }
    }

    access(all) fun createEmptyCollection(): @Collection {
        return <- create Collection()
    }

    access(all) fun mintNFT(): @NFT {
        let newNFT <- create NFT(initID: self.idCount)
        self.idCount = self.idCount + 1
        return <-newNFT
    }

	init() {
        self.CollectionStoragePath = /storage/nftTutorialCollection
        self.CollectionPublicPath = /public/nftTutorialCollection
        self.MinterStoragePath = /storage/nftTutorialMinter

        self.idCount = 1

        self.account.storage.save(<-self.createEmptyCollection(), to: self.CollectionStoragePath)
        let cap = self.account.capabilities.storage.issue<&Collection>(self.CollectionStoragePath)
        self.account.capabilities.publish(cap, at: self.CollectionPublicPath)
	}
}
