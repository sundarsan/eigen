import Foundation
import Interstellar
import SwiftyJSON

/*
Independent of sockets:
- time elapsed

Based on socket events:
- lot state (bidding not yet, bidding open, bidding closed)
- reserve status
- # of bids
- # of watchers
- next bid amount $
- bid history
*/

class LiveAuctionStateManager: NSObject {
    typealias SocketCommunicatorCreator = (host: String, causalitySaleID: String, jwt: JWT) -> LiveAuctionSocketCommunicatorType
    typealias StateReconcilerCreator = (saleArtworks: [LiveAuctionLotViewModel]) -> LiveAuctionStateReconcilerType

    let sale: LiveSale
    let bidderID: String?

    private let socketCommunicator: LiveAuctionSocketCommunicatorType
    private let stateReconciler: LiveAuctionStateReconcilerType
    private var biddingStates = [String: LiveAuctionBiddingViewModelType]()

    var bidderStatus: ArtsyAPISaleRegistrationStatus {
        let loggedIn = User.currentUser() != nil
        let hasBidder = bidderID != nil

        if !loggedIn { return .NotLoggedIn }
        return hasBidder ? .Registered : .NotRegistered
    }

    init(host: String,
         sale: LiveSale,
         saleArtworks: [LiveAuctionLotViewModel],
         jwt: JWT,
         bidderID: String?,
         socketCommunicatorCreator: SocketCommunicatorCreator = LiveAuctionStateManager.defaultSocketCommunicatorCreator(),
         stateReconcilerCreator: StateReconcilerCreator = LiveAuctionStateManager.defaultStateReconcilerCreator()) {

        self.sale = sale
        self.bidderID = bidderID
        self.socketCommunicator = socketCommunicatorCreator(host: host, causalitySaleID: sale.causalitySaleID, jwt: jwt)
        self.stateReconciler = stateReconcilerCreator(saleArtworks: saleArtworks)

        super.init()

        socketCommunicator.updatedAuctionState.subscribe { [weak self] state in
            self?.stateReconciler.updateState(state)
        }

        socketCommunicator.lotUpdateBroadcasts.subscribe { [weak self] broadcast in
            self?.stateReconciler.processLotEventBroadcast(broadcast)
        }

        socketCommunicator.currentLotUpdate.subscribe { [weak self] update in
            self?.stateReconciler.processCurrentLotUpdate(update)
        }

        socketCommunicator.postEventResponses.subscribe { [weak self] response in
            print("ws response: \(response)")

            let json = JSON(response)
            let bidUUID = json["key"].stringValue
            let biddingViewModel = self?.biddingStates.removeValueForKey(bidUUID)
            biddingViewModel?.bidPendingSignal.update(false)
        }
    }
}

private typealias PublicFunctions = LiveAuctionStateManager
extension PublicFunctions {

    func bidOnLot(lotID: String, amountCents: UInt64, biddingViewModel: LiveAuctionBiddingViewModelType) {
        guard let bidderID = bidderID else {
            return print("Tried to bid without a bidder ID on account")
        }

        biddingViewModel.bidPendingSignal.update(true)
        let bidID = NSUUID().UUIDString
        biddingStates[bidID] = biddingViewModel
        socketCommunicator.bidOnLot(lotID, amountCents: amountCents, bidderID: bidderID, bidUUID: bidID)
    }

    func leaveMaxBidOnLot(lotID: String, amountCents: UInt64, biddingViewModel: LiveAuctionBiddingViewModelType) {
        guard let bidderID = bidderID else {
            return print("Tried to leave a max bid without a bidder ID on account")
        }

        biddingViewModel.bidPendingSignal.update(true)
        let bidID = NSUUID().UUIDString
        biddingStates[bidID] = biddingViewModel
        socketCommunicator.leaveMaxBidOnLot(lotID, amountCents: amountCents, bidderID: bidderID, bidUUID: bidID)
    }

    var debugAllEventsSignal: Observable<LotEventJSON> {
        return stateReconciler.debugAllEventsSignal
    }
}

private typealias ComputedProperties = LiveAuctionStateManager
extension ComputedProperties {
    var currentLotSignal: Observable<LiveAuctionLotViewModelType?> {
        return stateReconciler.currentLotSignal
    }
}


private typealias DefaultCreators = LiveAuctionStateManager
extension DefaultCreators {
    class func defaultSocketCommunicatorCreator() -> SocketCommunicatorCreator {
        return { host, causalitySaleID, jwt in
            return LiveAuctionSocketCommunicator(host: host, causalitySaleID: causalitySaleID, jwt: jwt)
        }
    }

    class func stubbedSocketCommunicatorCreator() -> SocketCommunicatorCreator {
        return { host, causalitySaleID, jwt in
            return Stubbed_SocketCommunicator(state: loadJSON("live_auctions_socket"))
        }
    }

    class func defaultStateReconcilerCreator() -> StateReconcilerCreator {
        return { saleArtworks in
            return LiveAuctionStateReconciler(saleArtworks: saleArtworks)
        }
    }
}

private class Stubbed_SocketCommunicator: LiveAuctionSocketCommunicatorType {
    let updatedAuctionState: Observable<AnyObject>
    let lotUpdateBroadcasts = Observable<AnyObject>()
    let currentLotUpdate = Observable<AnyObject>()
    let postEventResponses = Observable<AnyObject>()

    init (state: AnyObject) {
        updatedAuctionState = Observable(state)
    }

    func bidOnLot(lotID: String, amountCents: UInt64, bidderID: String, bidUUID: String) {

    }

    func leaveMaxBidOnLot(lotID: String, amountCents: UInt64, bidderID: String, bidUUID: String) {

    }

}
