// Medical Health Records Permissions: Give patients the power to grant or revoke viewing rights to clinical staff.


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract HealthRecordPermissions {

    struct Record {
        string encryptedDataURI; // IPFS/Arweave link to the encrypted medical record file
        bytes32 dataHash;        // SHA-256/Keccak256 hash of the file for integrity verification
        uint256 lastUpdated;     // Timestamp of the latest record update
    }

    // Patient Address => (Doctor Address => Is Authorized)
    mapping(address => mapping(address => bool)) private _accessRegistry;

    // Patient Address => Array of their unique medical record metadata entries
    mapping(address => Record[]) private _patientRecords;

    // Events for real-time audit logs
    event AccessGranted(address indexed patient, address indexed practitioner);
    event AccessRevoked(address indexed patient, address indexed practitioner);
    event RecordAdded(address indexed patient, bytes32 indexed dataHash);

    // Custom Errors for gas optimization
    error AccessDenied();
    error RecordNotFound();

    modifier onlyPatientOrAuthorized(address patient) {
        if (msg.sender != patient && !_accessRegistry[patient][msg.sender]) {
            revert AccessDenied();
        }
        _;
    }

    /**
     * @dev Step 1: Patient grants access to a specific clinical staff member or medical center.
     * @param practitioner The wallet address of the doctor or hospital node.
     */
    function grantAccess(address practitioner) external {
        require(practitioner != address(0), "Invalid practitioner address");
        require(practitioner != msg.sender, "Cannot grant access to yourself");

        _accessRegistry[msg.sender][practitioner] = true;
        emit AccessGranted(msg.sender, practitioner);
    }

    /**
     * @dev Step 2: Patient instantly revokes viewing rights from a practitioner.
     * @param practitioner The wallet address of the doctor being barred.
     */
    function revokeAccess(address practitioner) external {
        require(_accessRegistry[msg.sender][practitioner], "Practitioner does not have access");

        _accessRegistry[msg.sender][practitioner] = false;
        emit AccessRevoked(msg.sender, practitioner);
    }

    /**
     * @dev Step 3: Add an encrypted medical record entry. 
     * Can be done by the patient or an authorized doctor who treated them.
     */
    function addMedicalRecord(
        address patient, 
        string calldata encryptedURI, 
        bytes32 dataHash
    ) 
        external 
        onlyPatientOrAuthorized(patient) 
    {
        require(bytes(encryptedURI).length > 0, "URI cannot be empty");

        _patientRecords[patient].push(Record({
            encryptedDataURI: encryptedURI,
            dataHash: dataHash,
            lastUpdated: block.timestamp
        }));

        emit RecordAdded(patient, dataHash);
    }

    /**
     * @dev Secure Read Step: Clinician fetches the data URI of a patient's record.
     * The modifier strictly blocks the call if access has not been granted by the patient.
     */
    function getPatientRecords(address patient) 
        external 
        view 
        onlyPatientOrAuthorized(patient) 
        returns (Record[] memory) 
    {
        return _patientRecords[patient];
    }

    /**
     * @dev Helper view function to verify an individual doctor's current permission status.
     */
    function checkAccess(address patient, address practitioner) external view returns (bool) {
        return _accessRegistry[patient][practitioner];
    }
}