// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

contract App {
    address[] internal addresses;
    mapping(string => address) internal names;
    mapping(address => Profile) public profiles;
    mapping(address => mapping(address => Profile)) internal followers;
    mapping(address => mapping(address => Profile)) internal following;
    mapping(address => Post[]) internal posts;

    // Profile
    struct Profile {
        address owner;
        string name;
        uint timeCreated;
        uint id;
        uint postCount;
        uint followerCount;
        uint followingCount;
        address[] followers;
        address[] following;
    }

    // Post
    struct Post {
        address author;
        string content;
        uint timeCreated;
        uint id;
    }

    // Check if message sender has a created profile
    modifier senderHasProfile() {
        require(profiles[msg.sender].owner != address(0x0), "ERROR: <Must create a profile to perform this action>");
        _;
    }

    // Check if a specified address has created a profile
    modifier profileExists(address _address) {
        require(profiles[_address].owner != address(0x0), "ERROR: <Profile does not exist>");
        _;
    }

    // Check that the message sender is not specifying an address that is itself
    modifier notSelf(address _address) {
        require(msg.sender != _address, "ERROR <You cannot follow/unfollow yourself");
        _;
    }

    // Check that the input is not empty
    modifier nonEmptyInput(string calldata _input) {
        require(keccak256(abi.encodePacked(_input)) != keccak256(abi.encodePacked("")), "ERROR: <Input cannot be empty>");
        _;
    }

    // Create a new profile from a given username
    function createProfile(string calldata _name) external nonEmptyInput(_name) {
        // Checks that the current account did not already make a profile and did not choose a taken username
        require(profiles[msg.sender].owner == address(0x0), "ERROR: <You have already created a profile>");
        require(names[_name] == address(0x0), "ERROR: <Username taken>");

        // Updates username list
        names[_name] = msg.sender;

        // Create the new profile object and add it to "profiles" mapping
        profiles[msg.sender] = Profile({
            owner: msg.sender,
            name: _name,
            timeCreated: block.timestamp,
            id: addresses.length,
            postCount: 0,
            followerCount: 0,
            followingCount: 0,
            followers: new address[](0x0),
            following: new address[](0x0)
        });

        // Add address to list of global addresses
        addresses.push(msg.sender);
    }

    // Follow a new profile
    function follow(address _address) external senderHasProfile profileExists(_address) notSelf(_address) {
        require(following[msg.sender][_address].owner == address(0x0), "ERROR: <You already follow this profile>");

        // Add entry to "followers" and "following" mappings
        followers[_address][msg.sender] = profiles[msg.sender];
        following[msg.sender][_address] = profiles[_address];

        // Add element to "followers" and "following" arrays in both Profile objects
        profiles[_address].followers.push(msg.sender);
        profiles[msg.sender].following.push(_address);

        // Increment "followerCount" and "followingCount" in both Profile objects
        profiles[_address].followerCount++;
        profiles[msg.sender].followingCount++;
    }

    // Unfollow a profile
    // This deletion operation has a time complexity of O(N), is there a better way to do this?
    function unfollow(address _address) external senderHasProfile profileExists(_address) notSelf(_address) {
        require(following[msg.sender][_address].owner != address(0x0), "ERROR: <You already do not follow this profile>");

        // Delete entry from "followers" and "following" mappings
        delete followers[_address][msg.sender];
        delete following[msg.sender][_address];

        // Delete element from "followers" array in Profile object and decrement followerCount
        for (uint i=0; i<profiles[_address].followerCount; i++) {
            if (profiles[_address].followers[i] == msg.sender) {
                delete profiles[_address].followers[i];
                profiles[_address].followerCount--;
                break;
            }
        }

        // Delete element from "following" array in Profile object and decrement followingCount
        for (uint i=0; i<profiles[msg.sender].followingCount; i++) {
            if (profiles[msg.sender].following[i] == _address) {
                delete profiles[msg.sender].following[i];
                profiles[msg.sender].followingCount--;
                break;
            }
        }
    }

    // Create a post
    function createPost(string calldata _content) external senderHasProfile() nonEmptyInput(_content) {
        // Create the Post object
        Post memory newPost = Post({
            author: msg.sender,
            content: _content,
            timeCreated: block.timestamp,
            id: posts[msg.sender].length
        });

        // Add entry to "posts" mappings
        posts[newPost.author].push(newPost);

        // Increment "postCount" in Profile object
        profiles[newPost.author].postCount++;
    }

    // Delete a post
    function deletePost(uint id) external senderHasProfile() {
        require(posts[msg.sender][id].author != address(0x0), "Post does not exist");

        delete posts[msg.sender][id];
        profiles[msg.sender].postCount--;
    }

    // Returns all posts from a given address
    function getPosts(address _address) external view profileExists(_address) returns(Post[] memory) {
        return posts[_address];
    }

    // Returns total user count
    function getUserCount() external view returns(uint) {
        return addresses.length;
    }

    // Returns all registered addresses
    function getAddresses() external view returns(address[] memory) {
        return addresses;
    }

    // Get all followers of a specific address
    function getFollowers(address _address) external view profileExists(_address) returns(address[] memory) {
        return profiles[_address].followers;
    }

    // Get all followed accounts of a specific address
    function getFollowing(address _address) external view returns(address[] memory) {
        return profiles[_address].following;
    }
}

/*
Ideally, I would like each profile to keep track of who they follow and who are their followers.
*/
