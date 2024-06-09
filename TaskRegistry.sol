// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TaskRegistry {

    // Define the tasks that crewmates need to complete
    enum CrewmateTask { FixWiring, EmptyChute, SwipeCard, AlignEngineOutput, CalibrateDistributor }

    // Define the tasks that impostors need to complete
    enum ImpostorTask { SabotageOxygen, SabotageReactor, FakeTask, KillCrewmate }

    // Define the scores for each task
    mapping(CrewmateTask => int16) public crewmateTaskScores;
    mapping(ImpostorTask => int16) public impostorTaskScores;

    // Define a mapping to store trusted callers
    mapping(address => bool) trustedCallers;

    // Constructor to add the contract deployer as a trusted caller
    constructor() {
        trustedCallers[msg.sender] = true;

        // Initialize scores for crewmate tasks
        crewmateTaskScores[CrewmateTask.FixWiring] = 10;
        crewmateTaskScores[CrewmateTask.EmptyChute] = 20;
        crewmateTaskScores[CrewmateTask.SwipeCard] = 15;
        crewmateTaskScores[CrewmateTask.AlignEngineOutput] = 25;
        crewmateTaskScores[CrewmateTask.CalibrateDistributor] = 30;

        // Initialize scores for impostor tasks
        impostorTaskScores[ImpostorTask.SabotageOxygen] = 50;
        impostorTaskScores[ImpostorTask.SabotageReactor] = 50;
        impostorTaskScores[ImpostorTask.FakeTask] = 10;
        impostorTaskScores[ImpostorTask.KillCrewmate] = 100;
    }

    // Define a modifier to restrict access to trusted callers
    modifier onlyTrustedCallers() {
        require(trustedCallers[msg.sender], "Caller is not trusted");
        _;
    }

    // Define a function to add trusted callers
    function addTrustedCaller(address _caller) external onlyTrustedCallers {
        trustedCallers[_caller] = true;
    }

    // Define a function to remove trusted callers
    function removeTrustedCaller(address _caller) external onlyTrustedCallers {
        trustedCallers[_caller] = false;
    }

    // Function to get the score of a crewmate task
    function getCrewmateTaskScore(CrewmateTask _task) external view returns (int16) {
        return crewmateTaskScores[_task];
    }

    // Function to get the score of an impostor task
    function getImpostorTaskScore(ImpostorTask _task) external view returns (int16) {
        return impostorTaskScores[_task];
    }

    // Function to update the score of a crewmate task
    function updateCrewmateTaskScore(CrewmateTask _task, int16 _score) external onlyTrustedCallers {
        crewmateTaskScores[_task] = _score;
    }

    // Function to update the score of an impostor task
    function updateImpostorTaskScore(ImpostorTask _task, int16 _score) external onlyTrustedCallers {
        impostorTaskScores[_task] = _score;
    }
    
}
