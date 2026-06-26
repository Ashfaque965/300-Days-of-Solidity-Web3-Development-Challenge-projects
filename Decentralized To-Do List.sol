// Decentralized To-Do List: Create, toggle, and manage tasks purely recorded on-chain.


// Decentralized To-Do List: Create, toggle, and manage tasks purely recorded on-chain.

// Building a decentralized to-do list involves modeling tasks as a structured data type (struct) and managing them through an array or mapping. This ensures that every creation, completion, or modification is permanently and transparently recorded on-chain.

// 🛠️ Solidity Implementation
// This contract allows any user to maintain their own private, independent list of tasks. We map each user's address to a dynamic array of Task structs so that multiple users can interact with the contract simultaneously without data overlap.

Solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TodoList {

    // Define the structure of a single Task
    struct Task {
        string content;   // The text description of the todo item
        bool isCompleted; // Completion status flag
    }

    // Mapping: User Address => Their personal array of Tasks
    mapping(address => Task[]) private _userTasks;

    // Events to track task lifecycle changes on-chain
    event TaskCreated(address indexed user, uint256 indexed taskId, string content);
    event TaskToggled(address indexed user, uint256 indexed taskId, bool isCompleted);
    event TaskUpdated(address indexed user, uint256 indexed taskId, string newContent);

    // Custom errors for gas efficiency
    error TaskDoesNotExist();

    /**
     * @dev Create a new task and append it to the caller's list.
     * @param content The text description of the task.
     */
    function createTask(string calldata content) external {
        require(bytes(content).length > 0, "Task content cannot be empty");

        _userTasks[msg.sender].push(Task({
            content: content,
            isCompleted: false
        }));

        // Get the index of the newly created task
        uint256 taskId = _userTasks[msg.sender].length - 1;

        emit TaskCreated(msg.sender, taskId, content);
    }

    /**
     * @dev Toggle the completion status of a specific task (Complete <-> Incomplete).
     * @param taskId The index position of the task in the user's array.
     */
    function toggleTaskCompletion(uint256 taskId) external {
        if (taskId >= _userTasks[msg.sender].length) {
            revert TaskDoesNotExist();
        }

        Task storage task = _userTasks[msg.sender][taskId];
        task.isCompleted = !task.isCompleted;

        emit TaskToggled(msg.sender, taskId, task.isCompleted);
    }

    /**
     * @dev Edit the text content of an existing task.
     * @param taskId The index position of the task in the user's array.
     * @param newContent The updated text description.
     */
    function updateTaskContent(uint256 taskId, string calldata newContent) external {
        if (taskId >= _userTasks[msg.sender].length) {
            revert TaskDoesNotExist();
        }
        require(bytes(newContent).length > 0, "New content cannot be empty");

        _userTasks[msg.sender][taskId].content = newContent;

        emit TaskUpdated(msg.sender, taskId, newContent);
    }

    /**
     * @dev Fetch a single task's details for a given user.
     */
    function getTask(address user, uint256 taskId) external view returns (string memory content, bool isCompleted) {
        if (taskId >= _userTasks[user].length) {
            revert TaskDoesNotExist();
        }
        Task memory task = _userTasks[user][taskId];
        return (task.content, task.isCompleted);
    }

    /**
     * @dev Returns the total number of tasks created by a specific user.
     * Essential for frontends to loop and fetch all tasks.
     */
    function getTaskCount(address user) external view returns (uint256) {
        return _userTasks[user].length;
    }
}



// 🧠 Architectural Insights
// 1. Storage Pointer: storage vs memory
// Inside the toggleTaskCompletion function, we explicitly use the storage keyword:

// Solidity
// Task storage task = _userTasks[msg.sender][taskId];
// This tells Solidity to create a reference pointer directly pointing to the contract's persistent state storage. Any changes made to the task variable alter the blockchain state directly. If we had mistakenly used memory, Solidity would have copied the data into temporary runtime memory, and modifying task.isCompleted would have had zero permanent effect once the transaction finished execution.

// 2. The UX Reality of On-Chain State Changes
// While a purely decentralized, on-chain to-do list is an excellent showcase of state management, it has practical engineering trade-offs for real-world applications:

// Gas Costs: Every time a user adds a task or checks an item off, they must sign a transaction and pay native gas fees (ETH, MATIC, etc.) to state-changing miners or validators.

// Latency: Checking off a box is not instant; the UI must wait for the block confirmation time (varying from seconds to minutes depending on the underlying network Layer 1 or Layer 2).

// For scalable consumer applications, developers often store the to-do data off-chain (e.g., decentralized databases like Ceramic or IPFS) and only settle critical state transitions or proof parameters on-chain.


