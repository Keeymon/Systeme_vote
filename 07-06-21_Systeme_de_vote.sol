// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    struct Proposal {
        string description;
        uint voteCount;
    }
    
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationStarted();
    event ProposalsRegistrationEnded();
    event ProposalRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted (address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    
    uint private winningProposalId;
    uint numberProposals;
    mapping(address => Voter) voters;
    Proposal[] proposals;
    WorkflowStatus private status;
    
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    function getStatus() public view returns(WorkflowStatus) {
        return status;
    }
    
    function changeStatus(WorkflowStatus _status) internal onlyOwner {
        status = _status;
        emit WorkflowStatusChange(status, _status);
    }
    
    function voterRegister(address _voter) public onlyOwner {
        require(status == WorkflowStatus.RegisteringVoters);
        voters[_voter].isRegistered = true;
        emit VoterRegistered(_voter);
    }
    
    function proposalsRegistrationStart() public onlyOwner {
        require(status == WorkflowStatus.RegisteringVoters, "Fire in the hall");
        changeStatus(WorkflowStatus.ProposalsRegistrationStarted);
        emit ProposalsRegistrationStarted();
    }
    
    function proposalRegister(string memory _description) public {
        require(voters[msg.sender].isRegistered == true, "Voter not Registered");
        require(status == WorkflowStatus.ProposalsRegistrationStarted, "YEAH");
        proposals.push(Proposal(_description, 0));
        numberProposals++;
        emit ProposalRegistered(proposals.length);
    }
    
    function proposalsRegistrationEnd() public onlyOwner {
        require(numberProposals > 1, "We need more proposals");
        require(status == WorkflowStatus.ProposalsRegistrationStarted, "");
        changeStatus(WorkflowStatus.ProposalsRegistrationEnded);
        emit ProposalsRegistrationEnded();
    }
    
    function getAllDescription() public view returns(string memory) {
        require(status > WorkflowStatus.ProposalsRegistrationStarted);
        string memory str = "Proposals Description :";
        for (uint i = 0; i < numberProposals; i++) {
            str = string(abi.encodePacked(str, "\n\n", uint2str(i), " - ", proposals[i].description));
        }
        return str;
    }
    
    function votingSessionStart() public onlyOwner {
        require(status == WorkflowStatus.ProposalsRegistrationEnded, "FIIIRE");
        changeStatus(WorkflowStatus.VotingSessionStarted);
        emit VotingSessionStarted();
    }
    
    function vote(uint _proposalId) public {
        require(voters[msg.sender].isRegistered == true, "Voter not Registered");
        require(voters[msg.sender].hasVoted == false, "T'abuses vraiment la");
        require(_proposalId <= numberProposals - 1, "T'abuses");
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        proposals[_proposalId].voteCount++;
        emit Voted(msg.sender, _proposalId);
    }
    
    function votingSessionEnd() public onlyOwner {
        require(status == WorkflowStatus.VotingSessionStarted, "I'm a firestarter, you're a firestarter");
        changeStatus(WorkflowStatus.VotingSessionEnded);
        emit VotingSessionEnded();
    }
    
    function defineWinner() public onlyOwner returns(uint) {
        require(status == WorkflowStatus.VotingSessionEnded, "O");
        require(numberProposals > 0, "On est dans la matrice");
        for (uint i = 0; i < numberProposals; i++) {
            if (proposals[winningProposalId].voteCount < proposals[i].voteCount)
                winningProposalId = i;
        }
        changeStatus(WorkflowStatus.VotesTallied);
        emit VotesTallied();
        return winningProposalId;
    }
    
    function getWinner() public view returns(string memory) {
        require(status == WorkflowStatus.VotesTallied, "Bande de chacaux");
        return string(proposals[winningProposalId].description);
    }
    
    function whoDidYouVoteFor(address _address) public view returns(uint) {
        require(status == WorkflowStatus.VotesTallied, "A faire");
        return voters[_address].votedProposalId;
    }
}
