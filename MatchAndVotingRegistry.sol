// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TaskRegistry.sol";
import "./UserRegistry.sol";

contract MatchAndVotingRegistry {
    // Define error codes
    error CallerNotTrusted();
    error InvalidMatchID();
    error InvalidVoteID();
    error VoterNotInMatch();
    error VotedPlayerNotInMatch();
    error VotingHasEnded();
    error PlayerNotInMatch();
    error SameSize();
    error InvalidVote();
    error ZeroAddress();
    error NotCrewmate();
    error MatchHasEnded();
    error ProofNotSubmitted();
    error TaskNotAssigned();
    struct Match {
        uint16 matchStartTime;
        uint8 playerCount;
        uint8 impostorCount;
        uint8 crewmateCount;
        uint8 activeImpostorCount;
        uint8 activeCrewmateCount;
        bool isStarted;
        bool isEnd;
    }

    enum VoteStatus {
        ELIMINATE_PLAYER,
        TIE
    }

    struct Vote {
        uint256 matchId;
        uint256 voteId;
        bool isStarted;
        bool isEnd;
        VoteStatus status;
    }
    TaskRegistry public immutable taskRegistry;

    UserRegistry public immutable userRegistry;

    uint256 private salt;

    // Mapping from match ID to Match struct
    mapping(uint256 => Match) public matches;

    // Mapping matchId to crewmateScore
    mapping(uint256 => int16) public collectiveCrewmateScore;

    // Mapping matchId to impostorScore
    mapping(uint256 => int16) public collectiveImpostorScore;

    // Mapping from match ID to array of player addresses present
    mapping(uint256 => mapping(address => bool)) private playersPresent;
    mapping(uint256 => address[]) private playersForMatchId;
    mapping(uint256 => address[]) private impostorsForMatchId;
    mapping(uint256 => mapping(address => bool)) private isImpostorForMatchId;
    mapping(uint256 => address[]) private crewmateForMatchId;
    mapping(uint256 => mapping(address => bool)) private isCrewmateForMatchId;

    // assigned tasks to players
    mapping(uint256 => mapping(address => mapping(TaskRegistry.CrewmateTask => bool)))
        private isCrewmateTaskAssigned;

    mapping(uint256 => mapping(address => uint8)) private cntTaskAssigned;

    mapping(uint256 => mapping(address => TaskRegistry.CrewmateTask[]))
        private assignedCrewmateTasks;

    mapping(uint256 => mapping(TaskRegistry.CrewmateTask => int8))
        private cntCrewmateTaskProofVerified;

    mapping(uint256 => mapping(TaskRegistry.ImpostorTask => int8))
        private cntImpostorTaskProofVerified;

    // Mapping from match ID to array of player addresses killedOrEliminate
    mapping(uint256 => mapping(address => bool))
        private playersKilledOrEliminateOrDisable;

    // Mapping from address to trusted callers
    mapping(address => bool) private trustedCallers;

    // Mapping from match ID to voting ID to Vote struct
    mapping(uint256 => mapping(uint256 => Vote)) public votes;

    // Mapping from match ID to voting ID to Vote struct
    mapping(uint256 => mapping(uint256 => mapping(address => mapping(address => bool))))
        public castedVote;

    // Variable to track the match ID counter
    uint256 public matchIdCounter;

    // Variable to track the voting ID counter
    uint256 public votingIdCounter;

    // Event to be emitted when a match is created
    event MatchCreated(
        uint256 indexed matchId,
        uint256 matchStartTime,
        uint256 playerCount,
        uint256 impostorCount,
        uint256 crewmateCount
    );

    // Event to be emitted when a player's kill count is updated
    event PlayerKilled(uint256 indexed matchId, address indexed player);

    // Event to be emitted when a player's kill count is updated
    event PlayerEliminatedOrDisabled(
        uint256 indexed matchId,
        address indexed player
    );

    // Event to be emitted when a match is ended
    event MatchEnded(uint256 indexed matchId);

    // Event to be emitted when a trusted caller is added
    event TrustedCallerAdded(address indexed caller);

    // Event to be emitted when a trusted caller is removed
    event TrustedCallerRemoved(address indexed caller);

    // Event to be emitted when voting is started
    event VotingStarted(uint256 indexed matchId, uint256 indexed voteId);

    // Event to be emitted when a vote is casted
    event VoteCasted(
        uint256 indexed matchId,
        uint256 indexed voteId,
        address indexed voter,
        address votedPlayer
    );
    // Event to be emitted when voting is ended
    event VotingEnded(
        uint256 indexed matchId,
        uint256 indexed voteId,
        VoteStatus status
    );

    // Modifier to check if the caller is trusted
    modifier onlyTrustedCaller() {
        if (!trustedCallers[msg.sender]) {
            revert CallerNotTrusted();
        }
        _;
    }

    constructor(address _taskRegistry, address _userRegistry, uint256 _salt) {
        taskRegistry = TaskRegistry(_taskRegistry);
        userRegistry = UserRegistry(_userRegistry);
        salt = _salt;
        trustedCallers[msg.sender] = true;
    }

    // Function to add a trusted caller (only callable by trusted callers)
    function addTrustedCaller(address _caller) external onlyTrustedCaller {
        trustedCallers[_caller] = true;
        emit TrustedCallerAdded(_caller);
    }

    // Function to remove a trusted caller (only callable by trusted callers)
    function removeTrustedCaller(address _caller) external onlyTrustedCaller {
        trustedCallers[_caller] = false;
        emit TrustedCallerRemoved(_caller);
    }

    // Function to create a new match
    function startMatch(
        uint256 _matchStartTime,
        uint8 _impostorCount,
        uint8 _crewmateCount
    ) external onlyTrustedCaller {
        matchIdCounter++;
        matches[matchIdCounter] = Match({
            matchStartTime: _matchStartTime,
            playerCount: _impostorCount + _crewmateCount,
            impostorCount: _impostorCount,
            crewmateCount: _crewmateCount,
            isStarted: true,
            isEnd: false,
            activeImpostorCount: _impostorCount,
            activeCrewmateCount: _crewmateCount
        });
        emit MatchCreated(
            matchIdCounter,
            _matchStartTime,
            _impostorCount + _crewmateCount,
            _impostorCount,
            _crewmateCount
        );
    }

    // Function to create a new match
    function createRole(
        uint16 _matchId,
        address _player
    ) external onlyTrustedCaller returns (bool) {
        if (_matchId > matchIdCounter || _matchId == 0) {
            revert InvalidMatchID();
        }
        Match storage matchDetails = matches[_matchId];
        // if(playersForMatchId[_matchId].length >= matchDetails.playerCount) revert PlayerNotInMatch();
        bool isTrue;
        uint8 randNum = _generateRandomNumber(2);
        if (
            randNum == 0 &&
            impostorsForMatchId[matchIdCounter].length <
            matchDetails.impostorCount
        ) {
            isImpostorForMatchId[matchIdCounter][_player] = true;
            impostorsForMatchId[matchIdCounter].push(_player);
            isTrue = true;
        } else if (
            randNum == 1 &&
            crewmateForMatchId[matchIdCounter].length <
            matchDetails.crewmateCount
        ) {
            isCrewmateForMatchId[matchIdCounter][_player] = true;
            crewmateForMatchId[matchIdCounter].push(_player);
            isTrue = true;
        }
        if (isTrue) {
            playersForMatchId[_matchId].push(_player);
            playersPresent[_matchId][_player] = true;
            return true;
        }
        return false;
    }

    // assigned role
    function assignedTasks(
        uint256 _matchId,
        address _player
    ) external onlyTrustedCaller returns (bool) {
        if (_matchId > matchIdCounter || _matchId == 0) {
            revert InvalidMatchID();
        }
        if (!playersPresent[_matchId][_player]) {
            revert PlayerNotInMatch();
        }
        if (isCrewmateForMatchId[_matchId][_player]) {
            uint8 taskIdx = _generateRandomNumber(10);
            salt++;
            if (
                !isCrewmateTaskAssigned[_matchId][_player][
                    TaskRegistry.CrewmateTask(taskIdx)
                ]
            ) {
                isCrewmateTaskAssigned[_matchId][_player][
                    TaskRegistry.CrewmateTask(taskIdx)
                ] = true;
                assignedCrewmateTasks[_matchId][_player].push(
                    TaskRegistry.CrewmateTask(taskIdx)
                );
                cntTaskAssigned[_matchId][_player] += 1;
                return true;
            }
        } else if (isImpostorForMatchId[_matchId][_player]) {
            cntTaskAssigned[_matchId][_player] += 1;
            return true;
        }
        return false;
    }

    // Function to Eliminate or Disable a Player
    function eliminateOrDisablePlayer(
        uint256 _matchId,
        address _player
    ) external onlyTrustedCaller {
        if (_matchId > matchIdCounter || _matchId == 0) {
            revert InvalidMatchID();
        }
        if (!playersPresent[_matchId][_player]) {
            revert PlayerNotInMatch();
        }
        Match memory matchDetails = matches[_matchId];
        if (isCrewmateForMatchId[_matchId][_player] == true) {
            matchDetails.activeCrewmateCount =
                matchDetails.activeCrewmateCount -
                1;
            playersKilledOrEliminateOrDisable[_matchId][_player] = true;
        } else if (isImpostorForMatchId[_matchId][_player] == true) {
            matchDetails.activeImpostorCount =
                matchDetails.activeImpostorCount -
                1;
            playersKilledOrEliminateOrDisable[_matchId][_player] = true;
        }
        if (
            matchDetails.activeCrewmateCount +
                matchDetails.activeImpostorCount <
            3 ||
            matchDetails.activeCrewmateCount == 0 ||
            matchDetails.activeImpostorCount == 0
        ) {
            matchDetails.isEnd = true;
            emit MatchEnded(_matchId);
        }
        matches[_matchId] = matchDetails;
        emit PlayerEliminatedOrDisabled(_matchId, _player);
    }

    function killedWithProof(
        uint256 _matchId,
        address _player
    ) external onlyTrustedCaller {
        if (_matchId > matchIdCounter || _matchId == 0) {
            revert InvalidMatchID();
        }
        if (!isCrewmateForMatchId[_matchId][_player]) revert NotCrewmate();
        playersKilledOrEliminateOrDisable[_matchId][_player] = true;
        Match memory matchDetails = matches[_matchId];
        matchDetails.activeCrewmateCount = matchDetails.activeCrewmateCount - 1;
        if (
            matchDetails.activeCrewmateCount +
                matchDetails.activeImpostorCount <
            3 ||
            matchDetails.activeCrewmateCount == 0
        ) {
            matchDetails.isEnd = true;
            emit MatchEnded(_matchId);
        }
        matches[_matchId] = matchDetails;
        cntImpostorTaskProofVerified[_matchId][TaskRegistry.ImpostorTask.KillCrewmate] += 1;
        emit PlayerKilled(_matchId, _player);
    }

    // Function to end a match
    function endMatch(uint256 _matchId) external onlyTrustedCaller {
        if (_matchId > matchIdCounter || _matchId == 0) {
            revert InvalidMatchID();
        }
        matches[_matchId].isEnd = true;
        emit MatchEnded(_matchId);
    }

    // Function to start voting in a match
    function startVoting(uint256 _matchId) external onlyTrustedCaller {
        if (_matchId > matchIdCounter || _matchId == 0) {
            revert InvalidMatchID();
        }
        if (matches[_matchId].isEnd) revert MatchHasEnded();
        votingIdCounter++;
        votes[_matchId][votingIdCounter] = Vote({
            matchId: _matchId,
            voteId: votingIdCounter,
            isStarted: true,
            isEnd: false,
            status: VoteStatus.TIE // Default status, can be updated later
        });
        emit VotingStarted(_matchId, votingIdCounter);
    }

    // Function to cast a vote during a match
    function castVote(
        uint256 _matchId,
        uint256 _voteId,
        address _voter,
        address _votedPlayer
    ) external {
        if (_matchId > matchIdCounter || _matchId == 0) {
            revert InvalidMatchID();
        }
        if (_voteId > votingIdCounter || _voteId == 0) {
            revert InvalidVoteID();
        }
        if (!playersPresent[_matchId][_voter]) {
            revert PlayerNotInMatch();
        }
        if (!playersPresent[_matchId][_votedPlayer]) {
            revert PlayerNotInMatch();
        }
        if (votes[_matchId][_voteId].isEnd) revert VotingHasEnded();

        // Update the vote count for the voted player
        castedVote[_matchId][_voteId][_voter][_votedPlayer] = true;

        emit VoteCasted(_matchId, _voteId, _voter, _votedPlayer);
    }

    // Function to end voting in a match
    function endVoting(
        uint256 _matchId,
        uint256 _voteId,
        VoteStatus _status,
        address _eliminatedPlayer,
        address[] memory _voters,
        address[] memory _votedPlayer
    ) external onlyTrustedCaller {
        if (_matchId > matchIdCounter || _matchId == 0) {
            revert InvalidMatchID();
        }
        if (!playersPresent[_matchId][_eliminatedPlayer]) {
            revert PlayerNotInMatch();
        }
        if (!votes[_matchId][_voteId].isStarted) {
            revert VotingHasEnded();
        }
        if (_voters.length != _votedPlayer.length) {
            revert SameSize();
        }
        // uint8 countVoteForEliminatedPlayer =0;
        for (uint8 i = 0; i < _voters.length; i++) {
            if (!playersPresent[_matchId][_voters[i]]) {
                revert PlayerNotInMatch();
            }
            if (!playersPresent[_matchId][_votedPlayer[i]]) {
                revert PlayerNotInMatch();
            }
            if (!castedVote[_matchId][_voteId][_voters[i]][_votedPlayer[i]])
                revert InvalidVote();
            // if(_eliminatedPlayer ==_votedPlayer[i]) countVoteForEliminatedPlayer++;
        }

        votes[_matchId][_voteId].isEnd = true;
        votes[_matchId][_voteId].status = _status;
        if (_status == VoteStatus.ELIMINATE_PLAYER) {
            if (_eliminatedPlayer == address(0)) revert ZeroAddress();
            Match memory matchDetails = matches[_matchId];
            if (isCrewmateForMatchId[_matchId][_eliminatedPlayer] == true) {
                matchDetails.activeCrewmateCount =
                    matchDetails.activeCrewmateCount -
                    1;
                playersKilledOrEliminateOrDisable[_matchId][
                    _eliminatedPlayer
                ] = true;
            } else if (
                isImpostorForMatchId[_matchId][_eliminatedPlayer] == true
            ) {
                matchDetails.activeImpostorCount =
                    matchDetails.activeImpostorCount -
                    1;
                playersKilledOrEliminateOrDisable[_matchId][
                    _eliminatedPlayer
                ] = true;
            }
            if (
                matchDetails.activeCrewmateCount +
                    matchDetails.activeImpostorCount <
                3 ||
                matchDetails.activeImpostorCount == 0 ||
                matchDetails.activeCrewmateCount == 0
            ) {
                matchDetails.isEnd = true;
                emit MatchEnded(_matchId);
            }
            matches[_matchId] = matchDetails;
        }

        emit VotingEnded(_matchId, _voteId, _status);
    }

    // Function to add crewmate score for a match
    function crewmateTaskCompletion(
        uint256 _matchId,
        TaskRegistry.CrewmateTask _task
    ) external onlyTrustedCaller {
        if (_matchId > matchIdCounter || _matchId == 0) {
            revert InvalidMatchID();
        }
        int16 score = taskRegistry.getCrewmateTaskScore(_task);
        collectiveCrewmateScore[_matchId] += score;
        cntCrewmateTaskProofVerified[_matchId][_task] += 1;
    }

    // Function to add impostor score for a match
    function impostorTaskCompletion(
        uint256 _matchId,
        TaskRegistry.ImpostorTask _task
    ) external onlyTrustedCaller {
        if (_matchId > matchIdCounter || _matchId == 0) {
            revert InvalidMatchID();
        }
        int16 score = taskRegistry.getImpostorTaskScore(_task);
        collectiveImpostorScore[_matchId] += score;
        cntImpostorTaskProofVerified[_matchId][_task] += 1;
    }

    // Function to get players for a given match ID
    function getPlayersForMatchId(
        uint256 _matchId
    ) external view onlyTrustedCaller returns (address[] memory) {
        if (_matchId > matchIdCounter || _matchId == 0) {
            revert InvalidMatchID();
        }
        return playersForMatchId[_matchId];
    }

    // assigned tasks to players

    // Function to get impostors for a given match ID
    function getImpostorsForMatchId(
        uint256 _matchId
    ) external view onlyTrustedCaller returns (address[] memory) {
        if (_matchId > matchIdCounter || _matchId == 0) {
            revert InvalidMatchID();
        }
        return impostorsForMatchId[_matchId];
    }

    function getAssignedTasks(
        uint256 _matchId,
        address _player
    )
        external
        view
        onlyTrustedCaller
        returns (TaskRegistry.CrewmateTask[] memory)
    {
        if (_matchId > matchIdCounter || _matchId == 0) {
            revert InvalidMatchID();
        }
        if (!isCrewmateForMatchId[_matchId][_player]) revert NotCrewmate();
        return assignedCrewmateTasks[_matchId][_player];
    }

    function checkTaskAssigned(
        uint256 _matchId,
        address _player,
        TaskRegistry.CrewmateTask _task
    ) external view onlyTrustedCaller returns (bool) {
        return
            isCrewmateTaskAssigned[_matchId][_player][_task];
    }

    // Function to check if a player is an impostor for a given match ID
    function playerIsImpostorForMatchId(
        uint256 _matchId,
        address _player
    ) external view onlyTrustedCaller returns (bool) {
        if (_matchId > matchIdCounter || _matchId == 0) {
            revert InvalidMatchID();
        }
        return isImpostorForMatchId[_matchId][_player];
    }

    // Function to get impostors for a given match ID
    function getCrewmateForMatchId(
        uint256 _matchId
    ) external view onlyTrustedCaller returns (address[] memory) {
        if (_matchId > matchIdCounter || _matchId == 0) {
            revert InvalidMatchID();
        }
        return crewmateForMatchId[_matchId];
    }

    // Function to check if a player is an impostor for a given match ID
    function playerIsCrewmateForMatchId(
        uint256 _matchId,
        address _player
    ) external view onlyTrustedCaller returns (bool) {
        if (_matchId > matchIdCounter || _matchId == 0) {
            revert InvalidMatchID();
        }
        return isCrewmateForMatchId[_matchId][_player];
    }

    // Add the collective score to
    function addScoreToUser(
        uint256 _matchId,
        address _player,
        TaskRegistry.CrewmateTask[] memory _crewmateTasks,
        TaskRegistry.ImpostorTask[] memory _impostorTasks
    ) external onlyTrustedCaller {
        if (_matchId > matchIdCounter || _matchId == 0) {
            revert InvalidMatchID();
        }
        if (!matches[_matchId].isEnd) revert MatchHasEnded();
        int16 overallScore = 0;
        if (
            isCrewmateForMatchId[_matchId][_player] == true &&
            _crewmateTasks.length != 0
        ) {
            for (uint8 i = 0; i < _crewmateTasks.length; i++) {
                // player assigned task
                if (
                    !isCrewmateTaskAssigned[_matchId][_player][
                        _crewmateTasks[i]
                    ]
                ) revert TaskNotAssigned();
                if (
                    cntCrewmateTaskProofVerified[_matchId][_crewmateTasks[i]] ==
                    0
                ) revert ProofNotSubmitted();
                // proof should not be zero
                int16 taskScore = taskRegistry.getCrewmateTaskScore(
                    _crewmateTasks[i]
                );
                overallScore += taskScore;
                cntCrewmateTaskProofVerified[_matchId][_crewmateTasks[i]] -= 1;
            }
            if (collectiveCrewmateScore[_matchId] - overallScore < 0)
                revert ProofNotSubmitted();
            collectiveCrewmateScore[_matchId] -= overallScore;
        } else if (
            isImpostorForMatchId[_matchId][_player] == true &&
            _impostorTasks.length != 0
        ) {
            for (uint8 i = 0; i < _impostorTasks.length; i++) {
                if (
                    cntImpostorTaskProofVerified[_matchId][_impostorTasks[i]] ==
                    0
                ) revert ProofNotSubmitted();
                // proof should not be zero
                int16 taskScore = taskRegistry.getImpostorTaskScore(
                    _impostorTasks[i]
                );
                overallScore += taskScore;
                cntImpostorTaskProofVerified[_matchId][_impostorTasks[i]] -= 1;
            }
            if (collectiveImpostorScore[_matchId] - overallScore < 0)
                revert ProofNotSubmitted();
            collectiveImpostorScore[_matchId] -= overallScore;
        }
        userRegistry.addReward(_player, int256(overallScore));
    }

    function _generateRandomNumber(uint8 mod) internal view returns (uint8) {
        uint8 randomNum = uint8(
            uint256(
                keccak256(
                    abi.encodePacked(
                        keccak256(
                            abi.encode(
                                salt,
                                msg.sender,
                                tx.gasprice,
                                block.number,
                                block.timestamp,
                                // block.prevrandao, // Uncomment this line if using Solidity 0.8.18 or above
                                blockhash(block.number - 1),
                                address(this)
                            )
                        )
                    )
                )
            ) % mod
        );
        return randomNum;
    }
}
