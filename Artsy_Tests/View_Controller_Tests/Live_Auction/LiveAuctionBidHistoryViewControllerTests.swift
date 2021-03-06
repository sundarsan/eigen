import Quick
import Nimble
import Nimble_Snapshots
import Interstellar
import UIKit

@testable
import Artsy

class LiveAuctionBidHistoryViewControllerTests: QuickSpec {

    func setupCellWithEvent(event: LiveEvent) -> LiveAuctionHistoryCell {
        let viewModel = LiveAuctionEventViewModel(event: event, currencySymbol: "$")
        let subject = LiveAuctionHistoryCell(style: .Value1, reuseIdentifier: "")
        subject.frame = CGRect(x: 0, y: 0, width: 320, height: 50)

        subject.updateWithEventViewModel(viewModel)
        return subject
    }

    override func spec() {
        describe("cells") {
            var subject: LiveAuctionHistoryCell!

            it("looks right for open") {
                let event = LiveEvent(JSON: ["type" : "BiddingOpened", "id" : "OK"])

                subject = self.setupCellWithEvent(event)
                expect(subject) == snapshot()
            }

            it("looks right for closed") {
                let event = LiveEvent(JSON: ["type" : "BiddingClosed", "id" : "OK"])

                subject = self.setupCellWithEvent(event)
                expect(subject) == snapshot()
            }

            it("looks right for closed state") {
                let event = LiveEvent(JSON: ["type" : "BiddingClosed", "id" : "OK", "cancelled" : true])

                subject = self.setupCellWithEvent(event)
                expect(subject) == snapshot()
            }

            it("looks right for bid") {
                let event = LiveEvent(JSON: [
                    "type" : "FirstPriceBidPlaced",
                    "id" : "ok",
                    "amountCents" : 555_000,
                    "bidder" : ["type": "ArtsyBidder", "bidderId": "LmnBN-aEci"]
                ])

                subject = self.setupCellWithEvent(event)
                expect(subject) == snapshot()
            }

            it("looks right for floor bid") {
                let event = LiveEvent(JSON: [
                    "type" : "FirstPriceBidPlaced",
                    "id" : "ok",
                    "amountCents" : 555_000,
                    "bidder" : ["type": "OfflineBidder"]
                    ])

                subject = self.setupCellWithEvent(event)
                expect(subject) == snapshot()
            }


            it("looks right for a cancelled floor bid") {
                let event = LiveEvent(JSON: [
                    "type" : "FirstPriceBidPlaced",
                    "id" : "ok",
                    "cancelled" : true,
                    "amountCents" : 555_000,
                    "bidder" : ["type": "OfflineBidder"]
                    ])

                subject = self.setupCellWithEvent(event)
                expect(subject) == snapshot()
            }

            it("looks right for final call") {
                let event = LiveEvent(JSON: ["type" : "FinalCall", "id" : "ok"])

                subject = self.setupCellWithEvent(event)
                expect(subject) == snapshot()
            }

            it("looks right for fair warning") {
                let event = LiveEvent(JSON: ["type" : "FairWarning", "id" : "ok"])

                subject = self.setupCellWithEvent(event)
                expect(subject) == snapshot()
            }
        }
    }
}
