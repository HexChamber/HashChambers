# Overview of the transaction:
#   1. Seller posts item for sale and posts safety deposit of double the item value. 
#   balance is 2*value.
#   (1.1. seller can reclaim deposit and close the sale as long as nothing was purchased.)
#   2. Buyer purchases item (value) plus posts an additional safety deposit (Item value).
#   Balance is 4*value.
#   3. Seller ships item.
#   4. Buyer confirms receiving the item. Buyer's deposit (value) is returned.
#       Seller's deposit (2*value) + item's value is returned. Balance is 0.

value: public(uint256)
seller: public(address)
buyer: public(address)
unlocked: public(bool)
ended: public(bool)


@external
@payable
def __init__():
    assert (msg.value % 2) == 0
    self.value = msg.value / 2 # Seller initializes the contract by posting a safety deposit
        # of 2 * value of the item for sale
    self.seller = msg.sender
    self.unlocked = True


@external
def abort():
    assert self.unlocked # Is the contract still refundable?
    assert msg.sender == self.seller # Only the seller can refund
    selfdestruct(self.seller) # Refunds the seller and deletes the contract


@external
@payable
def purchase():
    assert self.unlocked # Is the item still up for sale?
    assert msg.value == (2 * self.value) # Is the deposit correct?
    self.buyer = msg.sender
    self.unlocked = False


@external
def received():
    # 1. Conditions
    assert not self.unlocked # is the item already purchased and pending confirmation from the buyer
    assert msg.sender = self.buyer
    assert not self.ended

    # 2 Effects
    self.ended = True

    # 3 Interaction
    send(self.buyer, self.value) # Return the buyer's deposit (=value) to the buyer
    selfdestruct(self.seller) # Return the seller's deposit (=2*value) and the 
        # purchase price to the seller