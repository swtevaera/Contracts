// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TaskRegistry.sol";
import "./UserRegistry.sol";
import "./MatchAndVotingRegistry.sol";
interface CVerifier {
    function verifyProof(bytes memory proof) external view returns (bool);
}
interface IVerifier {
    function verifyProof(bytes memory proof) external view returns (bool);
}
contract GameEvent {

    // Address of the verifier contract
    // IVerifier public verifierContract;
    MatchAndVotingRegistry public immutable matchAndVotingRegistry;
    constructor(address _verifierAddress, address _matchAndVotingRegistry) {
        // verifierContract = IVerifier(_verifierAddress);
        matchAndVotingRegistry = MatchAndVotingRegistry(_matchAndVotingRegistry);
    }
    // Function to submit kill proof
    function submitCrewmateTask(bytes memory proof, uint256 _matchId, TaskRegistry.CrewmateTask _task) public {
        // Verify the proof by calling the external contract
        // bool isValid = verifierContract.verifyProof(proof);
        // require(isValid, "Invalid proof provided");
        matchAndVotingRegistry.crewmateTaskCompletion(_matchId,_task);
    }

    // Function to submit task proof
    function submitImpostorTask(bytes memory proof,uint256 _matchId, TaskRegistry.ImpostorTask _task) public {
        // Verify the proof by calling the external contract
        // bool isValid = verifierContract.verifyProof(proof);
        // require(isValid, "Invalid proof provided");
        // Call the external contract to reward the crewmate
        matchAndVotingRegistry.impostorTaskCompletion(_matchId,_task);


    }
}
