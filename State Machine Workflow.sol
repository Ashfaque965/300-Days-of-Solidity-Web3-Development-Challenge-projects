// State Machine Workflow: Move an object through Draft -> Review -> Approved -> Published.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract DocumentWorkflow is Ownable {

    // 1. Define the states using an enum
    enum WorkflowState { Draft, Review, Approved, Published }

    // Struct representing the object moving through the workflow
    struct Document {
        string content;
        WorkflowState state;
    }

    // Map a unique ID to each Document
    mapping(uint256 => Document) private _documents;
    uint256 public documentCount;

    // Events to track state changes
    event DocumentCreated(uint256 indexed docId);
    event StateTransitioned(uint256 indexed docId, WorkflowState indexed fromState, WorkflowState indexed toState);

    // Custom errors for gas efficiency
    error InvalidState(WorkflowState expected, WorkflowState actual);
    error DocumentDoesNotExist();

    constructor(address initialOwner) Ownable(initialOwner) {}

    // Modifier to enforce strict state pre-requisites
    modifier atState(uint256 docId, WorkflowState expectedState) {
        if (docId >= documentCount) revert DocumentDoesNotExist();
        if (_documents[docId].state != expectedState) {
            revert InvalidState(expectedState, _documents[docId].state);
        }
        _;
    }

    /**
     * @dev Step 1: Create a new document. Starts implicitly in the `Draft` state.
     */
    function createDocument(string calldata content) external onlyOwner {
        uint256 docId = documentCount;
        _documents[docId] = Document({
            content: content,
            state: WorkflowState.Draft
        });
        
        documentCount++;
        emit DocumentCreated(docId);
    }

    /**
     * @dev Step 2: Move from Draft to Review.
     */
    function submitForReview(uint256 docId) external onlyOwner atState(docId, WorkflowState.Draft) {
        _documents[docId].state = WorkflowState.Review;
        emit StateTransitioned(docId, WorkflowState.Draft, WorkflowState.Review);
    }

    /**
     * @dev Step 3: Move from Review to Approved.
     */
    function approveDocument(uint256 docId) external onlyOwner atState(docId, WorkflowState.Review) {
        _documents[docId].state = WorkflowState.Approved;
        emit StateTransitioned(docId, WorkflowState.Review, WorkflowState.Approved);
    }

    /**
     * @dev Step 4: Move from Approved to Published.
     */
    function publishDocument(uint256 docId) external onlyOwner atState(docId, WorkflowState.Approved) {
        _documents[docId].state = WorkflowState.Published;
        emit StateTransitioned(docId, WorkflowState.Approved, WorkflowState.Published);
    }

    /**
     * @dev Read function to fetch document details.
     */
    function getDocument(uint256 docId) external view returns (string memory content, WorkflowState state) {
        if (docId >= documentCount) revert DocumentDoesNotExist();
        Document memory doc = _documents[docId];
        return (doc.content, doc.state);
    }
}