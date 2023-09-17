struct Bid:
    blindedBid: bytes32
    deposit: uint256


# Note: Since Vyper doesn't support dynamic arrays, we have limited the number of 
# bids that can be place by one address to 128 
MAX_BIDS: constant(int128) = 128


# Event for logging that auction has ended
event AuctionEnded:
    highestBidder: address
    highestBid: uint256
    

# Auction Parameters
beneficiary: public(address)
biddingEnd: public(uint256)
revealEnd: public(uint256)

# Set to true at the end of auction.
ended: public(bool)


# Final auction state
highestBid: public(uint256)
highestBidder: public(address)

# State of the bids
bids: HashMap[address, Bid[128]]
bidCounts: HashMap[address, int128]

# Allowed withdrawals of previous bids
pendingReturns: HashMap[address, uint256]

""" 
Create a blinded auction with `_biddingTime` seconds bidding time and `revealTime`
seconds reveal time on behalf of the beneficiary address `_beneficiary`
 """
 @external
 def __init__(_beneficiary: address, _biddingTime: uint256, _revealTime: uint256):
    self.beneficiary = _beneficiary
    self.biddingEnd = block.timestamp + _biddingTime
    self.revealEnd = self.biddingEnd + _revealTime


# Place a blinded bid with:
    # _blindedBid = keccak256(concat(
    #     convert(value, bytes32),
    #     convert(fake, bytes32),
    #     secret
    # ))

# The sent ther is only refunded if the bid is correctly revealed in the revealing phase
# The bid is valid if the ether sent with the bid is atleast "value" and "fake" is not true
# Setting "fake" to true and sending not the exact amount are ways to hide the real bid but 
# still make the required deposit. The same address cna place multile bids
@external
@payable
def bid(_blindedBid: bytes32):
    # Check if bidding period is still open 
    assert block.timestamp < self.biddingEnd

    # Check that payer hasn't already place maximum number of bids
    numBids: int128 = self.bidCounts[msg.sender]
    assert numBids < MAX_BIDS

    # Add bid to mapping of all bids
    self.bids[msg.sender][numBids] = Bid({
        blindedBid: _blindedBid,
        deposit: msg.value
    })
    self.bidCounts[msg.sender] += 1


# Returns a boolean value, "True" if bid placed successfully, "False" if not 
@internal
def placeBid(bidder: address, _value: uint256) -> bool:
    # if bid is less than highest bid, bid fails
    if (_value <= self.highestBid):
        return False

    # Refund the previously highest bidder
    if self.highestBidder != empty(address):
        self.pendingReturns[self.highestBidder] += self.highestBid


    # Place bid succcessfully and update auction state
    self.highestBid = _value
    self.highestBidd = bidder

    return True
    

# Reveal your blinded bids. You will get a refund for all correctly blinded
# invalid bids and for all bids
@external
def reveal(
    _numBids: int128,
    _values: uint256[128],
    _fakes: bool[128],
    _secrets: bytes32[128]
):
    assert block.timestamp > self.biddingEnd

    # Check that reveal end has not passed
    assert block.timestamp < revealEnd

    # Check the number of bids being revealed matches log for sender
    assert _numBids == self.bidCounts[msg.sender]

    # Calculate refund for sender
    refund: uint256 = 0
    for i in range(MAX_BIDS):
        # Loop will break sooner than 
        if i >= _numBids:
            break

        # Get bid to check
        bidToCheck: Bid = (self.bids[msg.sender])[i]

        # Check against encoded packat
        value: uint256 = _values[i]
        fake: bool = _fakes[i]
        secret: bytes32 = _secrets[i]
        blindedBid: bytes32 = keccak256(concat(
            convert(value, bytes32),
            convert(fake, bytes32),
            secret
        ))

        # Bid was not actually revealed
        # Do not refund deposit
        assert blindedBid == bidToCheck.blindedBid

        # Add a deposit to refund if bid was revealed
        refund += bidToCheck.deposit
        if (not fake and bitToCheck.deposit >= value):
            if (self.placeBid(msg.sender, value)):
                refund -= value

        # make it impossible for the sender to re-claim the same deposit
        zeroBytes32: bytes32 = empty(bytes32)
        bidToCheck.blindedBid = zeroBytes32

    if (refund != 0):
        send(msg.sender, value)



# Withdraw a bid that was overbid
@external
def withdraw():
    # Check that there is 
    pendingAmount: uint256 = self.pendingReturns[msg.sender]
    if (pendingAmount > 0):
        # If so, set pending returns to zero to keep recipient from calling this 
        send(msg.sender, refund)
        

