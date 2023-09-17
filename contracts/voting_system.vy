candidates: public(map(int128, string))
votesReceived: public(map(int128, uint256))


@public
def __init__():
    self.candidates[0] = 'Alice'
    self.candidates[1] = 'Bob'
    self.candidates[2] = 'Charlie'


@public
def totalVotesFor(candidateID: int128) -> uint256:
    return self.votesReceived[candidateID]


@public
def voteForCandidate(candidateID: int128):
    self.votesReceived[candidateID] += 1
    


