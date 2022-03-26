const chai = require('chai')

const BN = web3.utils.BN
const chaiBN = require('chai-bn')(BN)
chai.use(chaiBN)

const chaiAsPromised = require('chai-as-promised')
chai.use(chaiAsPromised)

const { expect } = chai

const SharkOutlawSquadVX = artifacts.require('SharkOutlawSquadVX')
const SharkOutlawSquadContract = artifacts.require('SharkOutlawSquad')
const SharkOutlawSquadPixelContract = artifacts.require('SharkOutlawSquadPixel')

contract('SharkOutlawSquadVX', (addresses) => {
  const [deployerAddress, ownerAddress, randomAddress] = addresses
  let instance
  let SharkOutlawSquad
  let SharkOutlawSquadPixel

  before(async () => {
    instance = await SharkOutlawSquadVX.deployed()
    await instance.togglePublicSalesStatus()
    SharkOutlawSquad = await SharkOutlawSquadContract.deployed()
    SharkOutlawSquadPixel = await SharkOutlawSquadPixelContract.deployed()
    await instance.setGenesisContractAddress(SharkOutlawSquad.address)
    await instance.setPixelContractAddress(SharkOutlawSquadPixel.address)
    await SharkOutlawSquad.gift([ownerAddress]) // id 1
    await SharkOutlawSquad.gift([ownerAddress]) // id 2
    await SharkOutlawSquad.gift([ownerAddress]) // id 3
    await SharkOutlawSquadPixel.gift([ownerAddress]) // id 1
    await instance.transferOwnership(ownerAddress, { from: deployerAddress })
  })

  describe('setContractURI', () => {
    it('owner can setContractURI', async () => {
      const uri = 'http://example.com'
      await instance.setContractURI(uri, { from: ownerAddress })
      const response = await instance.contractURI()
      expect(response).to.be.equal(uri)
    })

    it('random address cannot setContractURI', async () => {
      const uri = 'http://example.com'
      const fn = instance.setContractURI(uri, { from: randomAddress })
      return expect(fn).to.be.rejectedWith('Ownable: caller is not the owner')
    })
  })

  describe('setBaseURI', () => {
    it('owner can setBaseURI', async () => {
      const uri = '0x0'
      const fn = instance.setBaseURI(uri, { from: ownerAddress })
      return expect(fn).to.be.fulfilled
    })

    it('random address cannot setBaseURI', async () => {
      const uri = '0x0'
      const fn = instance.setBaseURI(uri, { from: randomAddress })
      return expect(fn).to.be.rejectedWith('Ownable: caller is not the owner')
    })
  })

  describe('mintWithPixel', () => {
    it('owner cannot mint free without having pixel nft', async () => {
      const tokenId = 2
      const fn = instance.mintWithPixel(tokenId, { from: ownerAddress })
      return expect(fn).to.be.rejected
    })

    it('non nft owner cannot mint the vx nft', async () => {
      const tokenId = 1
      const fn = instance.mintWithPixel(tokenId, { from: randomAddress })
      return expect(fn).to.be.rejected
    })

    it('owner can mint free with having pixel nft', async () => {
      const tokenId = 1
      const fn = instance.mintWithPixel(tokenId, { from: ownerAddress })
      return expect(fn).to.be.fulfilled
    })
  })

  describe('mintWithoutPixel', () => {
    it('owner can mint with paying 0.2 ETH', async () => {
      const tokenId = 2
      const fn = instance
        .mintWithoutPixel(tokenId, {
          value: 200000000000000000,
          from: ownerAddress,
        })
      return expect(fn).to.be.fulfilled
    })
    it('non owner cannot mint with paying 0.2 ETH', async () => {
      const tokenId = 3
      const fn = instance
        .mintWithoutPixel(tokenId, {
          value: 200000000000000000,
          from: randomAddress,
        })
      return expect(fn).to.be.rejected
    })
  })

  // describe('gift', () => {
  //   it('random address cannot gift', async () => {
  //     const receivers = [randomAddress]

  //     const fn = instance.gift(receivers, { from: randomAddress })

  //     return expect(fn).to.be.rejectedWith('Ownable: caller is not the owner')
  //   })

  //   it('allow owner to gift', async () => {
  //     const qty = 10
  //     const receivers = []
  //     for (let i = 0; i < qty; i++) {
  //       receivers.push(randomAddress)
  //     }

  //     const fn = instance.gift(receivers, { from: ownerAddress })

  //     return expect(fn).to.be.fulfilled
  //   })
  // })
})
