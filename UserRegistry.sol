// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract UserRegistry {
    // Revert when the caller is required to have an sid but does not have one.
    error HasNoId();

    // Struct to hold user details
    struct User {
        string name;
        string icon;
    }
    // Users Ids Count For Anon World Game
    uint256 private userId;

    // Mapping from user's eoa to User struct
    mapping(address => User) public users;

    // Mapping of userIdOf
    mapping(address => uint256) private userIdOf;

    // Mapping of addressOf
    mapping(uint256 => address) private addressOf;

    // Mapping Overall Score of User
    mapping(address => uint256) public usersOverallScore;

    // Mapping from user's eoa to user skills
    mapping(address => string[]) public userSkills;

    // Mapping from user's eoa to user rewards
    mapping(address => int256) public rewards;

    // Mapping from user's eoa to trusted callers
    mapping(address => bool) private trustedCallers;

    // Event to be emitted when a new user is registered
    event UserRegistered(address indexed userAddress, string name);

    // Event to be emitted when user details are updated
    event UserDetailsUpdated(address indexed userAddress, string name);

    // Event to be emitted when a trusted caller is added or removed
    event TrustedCallerAdded(address indexed caller);
    event TrustedCallerRemoved(address indexed caller);

    // Event to be emitted when skills are added to a user
    event SkillsAdded(address indexed userAddress, string[] skills);

    // Event to be emitted when rewards are added to a user
    event Reward(address indexed userAddress, int256 amount);

    // Event to be emitted when skill are added to a user
    event SkillAdded(address indexed userAddress, string skill);

    // // Modifier to check if the user is registered
    // modifier isRegistered() {
    //     require(
    //         bytes(users[msg.sender].name).length != 0,
    //         "User not registered"
    //     );
    //     _;
    // }

    // Modifier to check if the caller is trusted
    modifier onlyTrustedCaller() {
        require(trustedCallers[msg.sender], "Caller is not trusted");
        _;
    }

    // Constructor that passes the initial owner to the Ownable constructor
    constructor() {
        trustedCallers[msg.sender] = true;
    }

    // Function to add a trusted caller (only callable by the contract owner)
    function addTrustedCaller(address _caller) public onlyTrustedCaller{
        trustedCallers[_caller] = true;
        emit TrustedCallerAdded(_caller);
    }

    // Function to remove a trusted caller (only callable by the contract owner)
    function removeTrustedCaller(address _caller) public onlyTrustedCaller {
        trustedCallers[_caller] = false;
        emit TrustedCallerRemoved(_caller);
    }

    // Function to register a new user (only callable by trusted callers)
    function registerUser(
        string memory _name,
        string memory _icon,
        address _user
    ) public onlyTrustedCaller {
        require(
            bytes(users[_user].name).length == 0,
            "User already registered"
        );

        users[_user] = User({name: _name, icon: _icon});
        // Perf: inlining this can save ~ 20-40 gas per call at the expense of readability
        if (userIdOf[_user] != 0) revert HasNoId();

        unchecked {
            userId++;
        }

        // Incrementing before assigning ensures that 0 is never issued as a valid ID.
        userIdOf[_user] = userId;
        addressOf[userId] = _user;

        emit UserRegistered(_user, _name);
    }

    // Function to get user details
    function getUser(
        address _userAddress
    ) public view returns (string memory, string memory) {
        User storage user = users[_userAddress];
        return (user.name, user.icon);
    }

    // Function to get user reward
    function getUserReward(address _userAddress) public view returns (int256) {
        return rewards[_userAddress];
    }

    // Function to add reward to a user
    function addReward(
        address _userAddress,
        int256 _amount
    ) public onlyTrustedCaller {
        rewards[_userAddress] += _amount;
        emit Reward(_userAddress, _amount);
    }

    // Function to add skill to a user
    function addSkill(
        string memory _skill
    ) public onlyTrustedCaller {
        userSkills[msg.sender].push(_skill);
        emit SkillAdded(msg.sender, _skill);
    }

    // Function to add skills to a user
    function addSkills(
        string[] memory _skills
    ) public onlyTrustedCaller {
        for (uint256 i = 0; i < _skills.length; i++) {
            userSkills[msg.sender].push(_skills[i]);
        }
        emit SkillsAdded(msg.sender, _skills);
    }

    // Function to get skills of a user
    function getSkills(
        address _userAddress
    ) public view returns (string[] memory) {
        return userSkills[_userAddress];
    }

    // Function to get userIdOf a user (only callable by trusted callers)
    function getUserIdOf(
        address _userAddress
    ) public view onlyTrustedCaller returns (uint256) {
        return userIdOf[_userAddress];
    }

    // Function to get addressOf a userId (only callable by trusted callers)
    function getAddressOf(
        uint256 _userId
    ) public view onlyTrustedCaller returns (address) {
        return addressOf[_userId];
    }

    // Function to get userId (only callable by trusted callers)
    function getuserId() public view onlyTrustedCaller returns (uint256) {
        return userId;
    }
}
