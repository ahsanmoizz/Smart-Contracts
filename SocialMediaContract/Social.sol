pragma solidity ^0.8.20;

contract Social {
    // Mapping to access user details from struct
    mapping(address => User) public userData;
    mapping(address => Posts) public userPosts;
     mapping(address => bool) public hasEngaged; // T
    mapping(address => address[]) public followers; // Track followers of a user
    mapping(address => address[]) public following; // Track users being followed
    uint256 public userProfileCount;  
    uint256 public userPostCount;
    uint256 public likes;
    uint256 public comments;
    uint256 public shares;
    address[] public userIds;
    address[] public posts;
    uint256[] public totalCount;
    bool public liked;
    bool public shared;
    bool public commented;

    // Modifier to ensure actions are "Unreacted"
      modifier Unreacted() {
        require(!hasEngaged[msg.sender], "Already engaged");
        _;
    }


    // User struct contains user details for creating an account    
    struct User {
        string name;
        string email;
        uint256 password;
        uint256 dateOfbirth;
        string IPFS;
    }

    // Struct that contains post details
    struct Posts {
        string IPFS;
    }

    // Logic for users to create an account/profile
    function Profile(
        string memory _name, 
        string memory _email, 
        uint256 _password,
        uint256 _dateOfbirth, 
        string memory _IPFS
    ) public {
        require(msg.sender != address(0), "Should be a valid user"); 
        require(bytes(_name).length > 0, "Name is required");
        require(bytes(_email).length > 0, "Email is required");
        require(_password > 0, "Password is required");
        require(_dateOfbirth > 0, "Date of birth is required");
        require(bytes(_IPFS).length > 0, "IPFS hash is required");

        // Check if user already exists
        require(bytes(userData[msg.sender].name).length == 0, "User already exists");

        // Save user data to the mapping
        userData[msg.sender] = User({
            name: _name,
            email: _email,
            password: _password,
            dateOfbirth: _dateOfbirth,
            IPFS: _IPFS  
        });

        userProfileCount++;
        userIds.push(msg.sender);
    }

    // Upload photos, audios, and videos
    function post(string memory _IPFS) public {
        require(msg.sender != address(0), "Should be a valid user"); 
        require(bytes(_IPFS).length > 0, "Post something");
        
        userPosts[msg.sender] = Posts({
            IPFS: _IPFS
        });

        userPostCount++;
        posts.push(msg.sender);
        totalCount.push(userPostCount);
    }

    // Analytics of posts
    function analytics() public view returns (uint256, uint256, uint256, uint256) {
        return (userPostCount, likes, comments, shares);
    }

    // Engage with a post (like, comment, share)
    function engage() public Unreacted {
        require(msg.sender != address(0), "Should be a valid user"); 
          hasEngaged[msg.sender] = true;
        

        likes++;
        comments++;
        shares++;
    }

    function edit(string memory _IPFS) public {
        require(msg.sender != address(0), "Should be a valid user"); 
        require(bytes(_IPFS).length > 0, "Post something");

        userPosts[msg.sender] = Posts({
            IPFS: _IPFS
        });
        posts.push(msg.sender);
        delete userPosts[msg.sender];
    }

    // Follow a user
    function followUser(address _user) public {
        require(_user != msg.sender, "You cannot follow yourself");
        require(msg.sender != address(0) && _user != address(0), "Invalid addresses");

        // Ensure the user is not already followed
        bool alreadyFollowing = false;
        for (uint256 i = 0; i < following[msg.sender].length; i++) {
            if (following[msg.sender][i] == _user) {
                alreadyFollowing = true;
                break;
            }
        }
        require(!alreadyFollowing, "Already following this user");

        // Add to following and followers
        following[msg.sender].push(_user);
        followers[_user].push(msg.sender);
    }

    // Get followers of a user
    function getFollowers(address _user) public view returns (address[] memory) {
        return followers[_user];
    }

    // Get users being followed by a user
    function getFollowing(address _user) public view returns (address[] memory) {
        return following[_user];
    }
}
