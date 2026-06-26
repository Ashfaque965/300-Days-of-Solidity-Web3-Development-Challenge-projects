// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract GradeBook is Ownable {

    // Nested Mapping: Student Address => (Test ID => Score)
    mapping(address => mapping(uint256 => uint256)) private _grades;
    
    // Track whether a grade has been submitted (to handle a score of 0 vs unsubmitted)
    mapping(address => mapping(uint256 => bool)) private _isGraded;

    // Events
    event GradeRecorded(address indexed student, uint256 indexed testId, uint256 score);
    event GradeUpdated(address indexed student, uint256 indexed testId, uint256 oldScore, uint256 newScore);

    // Custom Errors
    error GradeNotSet();

    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @dev Set or record a grade for a student. Only the teacher/owner can call this.
     * @param student The wallet address of the student.
     * @param testId The unique identifier for the exam/test.
     * @param score The grade achieved by the student.
     */
    function setGrade(address student, uint256 testId, uint256 score) external onlyOwner {
        require(student != address(0), "Invalid student address");

        if (_isGraded[student][testId]) {
            uint256 oldScore = _grades[student][testId];
            _grades[student][testId] = score;
            emit GradeUpdated(student, testId, oldScore, score);
        } else {
            _isGraded[student][testId] = true;
            _grades[student][testId] = score;
            emit GradeRecorded(student, testId, score);
        }
    }

    /**
     * @dev Fetch a student's score for a specific test.
     */
    function getGrade(address student, uint256 testId) external view returns (uint256) {
        if (!_isGraded[student][testId]) {
            revert GradeNotSet();
        }
        return _grades[student][testId];
    }

    /**
     * @dev Utility to check if a student has a recorded grade for a test.
     */
    function hasGrade(address student, uint256 testId) external view returns (bool) {
        return _isGraded[student][testId];
    }
}