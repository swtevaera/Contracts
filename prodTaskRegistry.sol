// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title TaskRegistry Contract
/// @notice This contract manages task scores and ranges for a jungle-themed game.
contract TaskRegistry {
    // Error to handle unauthorized access
    error CallerNotTrusted();
    error InvalidPlayerSize();

    // Enum representing different tasks
    enum Task {
        PatchBrokenVines,
        ClearRottenLeaves,
        UploadPlantHealthReports,
        ClearBatSwarm,
        ClearVent,
        PlanJungleTrek,
        AlignSignalDish,
        ClearBlockedChimney,
        HelpDroopyPlants,
        SystemLubrication,
        TheJungleBell,
        VinesOfPower,
        AmplifyJungleResonance,
        AlignTurbineOutput,
        DecryptStellarCode,
        RecallStars,
        DiagnosePlantDisease,
        AnalyzeJungleToxins
    }

    // Define the TaskRange struct
    struct TaskRange {
        uint256 minCommon;
        uint256 maxCommon;
        uint256 minShort;
        uint256 maxShort;
        uint256 minLong;
        uint256 maxLong;
        uint256 minTotal; // this varibale can be removed as no use in overall logic
        uint256 maxTotal; // this varibale can be removed as no use in overall logic
    }

    struct randomNTask {
        uint256 common;
        uint256 short;
        uint256 long;
    }
    // randomNonce
    uint256 private randomNonce = 0;
    // Mapping to store task scores
    mapping(Task => int256) private tasksScore;
    mapping(uint256 => TaskRange) private taskRanges;
    mapping(bytes32 => randomNTask) private randNTasksForMatch;
    // Mapping to store trusted callers
    mapping(address => bool) private trustedCallers;

    // Arrays to store tasks by type
    Task[] private shortTasks;
    Task[] private longTasks;
    Task[] private commonTasks;

    // Event to track the assignment of random tasks
    event RandomNTasksForMatchId(
        bytes32 indexed matchId,
        uint256 shortTask,
        uint256 commonTask,
        uint256 longTask
    );

    /// @notice Constructor to initialize the contract
    constructor() {
        // Add the contract deployer as a trusted caller
        trustedCallers[msg.sender] = true;

        // Initialize scores for jungle tasks
        tasksScore[Task.PatchBrokenVines] = 10;
        tasksScore[Task.ClearRottenLeaves] = 20;
        tasksScore[Task.UploadPlantHealthReports] = 15;
        tasksScore[Task.ClearBatSwarm] = 25;
        tasksScore[Task.ClearVent] = 30;
        tasksScore[Task.PlanJungleTrek] = 20;
        tasksScore[Task.AlignSignalDish] = 35;
        tasksScore[Task.ClearBlockedChimney] = 40;
        tasksScore[Task.HelpDroopyPlants] = 15;
        tasksScore[Task.SystemLubrication] = 20;
        tasksScore[Task.TheJungleBell] = 25;
        tasksScore[Task.VinesOfPower] = 30;
        tasksScore[Task.AmplifyJungleResonance] = 35;
        tasksScore[Task.AlignTurbineOutput] = 40;
        tasksScore[Task.DecryptStellarCode] = 45;
        tasksScore[Task.RecallStars] = 50;
        tasksScore[Task.DiagnosePlantDisease] = 30;
        tasksScore[Task.AnalyzeJungleToxins] = 35;

        // Initialize short tasks
        shortTasks = [
            Task.PatchBrokenVines,
            Task.UploadPlantHealthReports,
            Task.ClearBatSwarm,
            Task.ClearVent,
            Task.PlanJungleTrek,
            Task.AlignSignalDish,
            Task.ClearBlockedChimney,
            Task.HelpDroopyPlants,
            Task.VinesOfPower,
            Task.AmplifyJungleResonance,
            Task.DecryptStellarCode
        ];

        // Initialize long tasks
        longTasks = [
            Task.ClearRottenLeaves,
            Task.SystemLubrication,
            Task.AlignTurbineOutput,
            Task.RecallStars,
            Task.DiagnosePlantDisease,
            Task.AnalyzeJungleToxins
        ];

        // Initialize common tasks
        commonTasks = [Task.PatchBrokenVines, Task.TheJungleBell];

        // Initialize the task ranges based on the provided table
        taskRanges[4] = TaskRange(1, 1, 1, 1, 1, 2, 3, 4);
        taskRanges[5] = TaskRange(1, 1, 1, 1, 1, 2, 3, 4);
        taskRanges[6] = TaskRange(1, 1, 1, 1, 2, 3, 4, 5);
        taskRanges[7] = TaskRange(1, 1, 1, 1, 2, 3, 4, 5);
        taskRanges[8] = TaskRange(2, 2, 1, 2, 2, 4, 5, 8);
        taskRanges[9] = TaskRange(2, 2, 1, 2, 2, 4, 5, 8);

        // set random nonce starting index
        randomNonce = uint256(
            keccak256(
                abi.encodePacked(
                    keccak256(
                        abi.encode(
                            tx.gasprice,
                            block.number,
                            block.timestamp,
                            block.prevrandao,
                            blockhash(block.number - 1),
                            address(this)
                        )
                    )
                )
            )
        );
    }

    /// @notice Modifier to restrict access to trusted callers
    modifier onlyTrustedCallers() {
        if (!trustedCallers[msg.sender]) {
            revert CallerNotTrusted();
        }
        _;
    }

    /// @notice Add a trusted caller
    /// @param _caller The address to be added as a trusted caller
    function addTrustedCaller(address _caller) external onlyTrustedCallers {
        trustedCallers[_caller] = true;
    }

    /// @notice Remove a trusted caller
    /// @param _caller The address to be removed as a trusted caller
    function removeTrustedCaller(address _caller) external onlyTrustedCallers {
        trustedCallers[_caller] = false;
    }

    /// @notice Update the score of a task
    /// @param _task The task to update the score for
    /// @param _score The new score of the task
    function updateTaskScore(
        Task _task,
        int16 _score
    ) external onlyTrustedCallers {
        tasksScore[_task] = _score;
    }

    /// @notice Get the score of a task
    /// @param _task The task to get the score for
    /// @return The score of the task
    function getTaskScore(Task _task) external view returns (int256) {
        return tasksScore[_task];
    }

    // Random Num
    //  Task Assigned

    /// @notice Get the list of Fshort tasks
    /// @return The array of short tasks
    function getShortTasks()
        external
        view
        onlyTrustedCallers
        returns (Task[] memory)
    {
        return shortTasks;
    }

    /// @notice Get the list of long tasks
    /// @return The array of long tasks
    function getLongTasks()
        external
        view
        onlyTrustedCallers
        returns (Task[] memory)
    {
        return longTasks;
    }

    /// @notice Get the list of common tasks
    /// @return The array of common tasks
    function getCommonTasks()
        external
        view
        onlyTrustedCallers
        returns (Task[] memory)
    {
        return commonTasks;
    }

    /// @notice Get the task range for a specific number of players
    /// @param players The number of players
    /// @return The task range for the specified number of players
    function getTaskRange(
        uint256 players
    ) external view onlyTrustedCallers returns (TaskRange memory) {
        if (players < 4 || players > 9) revert InvalidPlayerSize();
        return taskRanges[players];
    }
    function assignRandomNTasksForMatch(
        uint256 _playerCount,
        bytes32 _matchId
    ) external onlyTrustedCallers {
        if (_playerCount < 4 || _playerCount > 9) revert InvalidPlayerSize();
        TaskRange memory taskRange = taskRanges[_playerCount];
        uint256 randN = _generateRandomNumber();
        unchecked {    randomNonce++;}
        randNTasksForMatch[_matchId].short =
            taskRange.minShort +
            (randN % (taskRange.maxShort - taskRange.minShort + 1));
        randNTasksForMatch[_matchId].common =
            taskRange.minCommon +
            (randN % (taskRange.maxCommon - taskRange.minCommon + 1));
        randNTasksForMatch[_matchId].long =
            taskRange.minLong +
            (randN % (taskRange.maxLong - taskRange.minLong + 1));

        // Emit the event
        emit RandomNTasksForMatchId(
            _matchId,
            randNTasksForMatch[_matchId].short,
            randNTasksForMatch[_matchId].common,
            randNTasksForMatch[_matchId].long
        );
    }

    function _generateRandomNumber() internal view returns (uint256) {
        uint256 randomNum =
            uint256(
                keccak256(
                    abi.encodePacked(
                        keccak256(
                            abi.encode(
                                randomNonce,
                                msg.sender,
                                tx.gasprice,
                                block.number,
                                block.timestamp,
                                block.prevrandao, // Uncomment this line if using Solidity 0.8.18 or above
                                blockhash(block.number - 1),
                                address(this)
                            )
                        )
                    )
                )
            );
        return randomNum;
    }
}
