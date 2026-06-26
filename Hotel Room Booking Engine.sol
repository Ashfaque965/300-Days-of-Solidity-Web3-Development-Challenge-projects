// Hotel Room Booking Engine: Check-in and check-out logic tied to address variables.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

contract HotelBookingEngine is Ownable {

    enum RoomStatus { Vacant, CheckedIn }

    struct Room {
        uint256 pricePerNight;
        bool exists;
    }

    struct StayRecord {
        address guest;
        uint256 checkInDay;
        uint256 checkOutDay;
        RoomStatus status;
    }

    // Room ID => Room Configurations
    mapping(uint256 => Room) private _rooms;

    // Room ID => (Day Index => Guest Address) [Calendar Matrix]
    mapping(uint256 => mapping(uint256 => address)) private _reservations;

    // Room ID => Active Stay Details
    mapping(uint256 => StayRecord) private _activeStays;

    // Events
    event RoomAdded(uint256 indexed roomId, uint256 pricePerNight);
    event RoomBooked(uint256 indexed roomId, address indexed guest, uint256 startDay, uint256 endDay);
    event GuestCheckedIn(uint256 indexed roomId, address indexed guest);
    event GuestCheckedOut(uint256 indexed roomId, address indexed guest);

    // Custom Errors
    error RoomDoesNotExist();
    error RoomAlreadyBooked();
    error IncorrectPayment();
    error InvalidDateRange();
    error ActionNotAvailable();
    error Unauthorized();

    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @dev Admin adds a new room configuration to the inventory.
     */
    function addRoom(uint256 roomId, uint256 pricePerNightInWei) external onlyOwner {
        _rooms[roomId] = Room({
            pricePerNight: pricePerNightInWei,
            exists: true
        });
        emit RoomAdded(roomId, pricePerNightInWei);
    }

    /**
     * @dev Step 1: Guest books a dynamic range of days.
     * @param roomId Target room ID.
     * @param startDay Calendar day index (e.g., Unix timestamp / 86400).
     * @param endDay Calendar day index marking checkout morning.
     */
    function bookRoom(uint256 roomId, uint256 startDay, uint256 endDay) external payable {
        Room memory room = _rooms[roomId];
        if (!room.exists) revert RoomDoesNotExist();
        if (startDay >= endDay) revert InvalidDateRange();

        uint256 totalNights = endDay - startDay;
        if (msg.value != room.pricePerNight * totalNights) revert IncorrectPayment();

        // Loop through calendar index to ensure no overlapping bookings exist
        for (uint256 i = startDay; i < endDay; i++) {
            if (_reservations[roomId][i] != address(0)) {
                revert RoomAlreadyBooked();
            }
            // Effect: Map the room date directly to the guest's address variable
            _reservations[roomId][i] = msg.sender;
        }

        emit RoomBooked(roomId, msg.sender, startDay, endDay);
    }

    /**
     * @dev Step 2: Guest arrives at the hotel on their startDay and checks in.
     * Activates the room lock state variables.
     */
    function checkIn(uint256 roomId, uint256 currentDayIndex) external {
        // Verify the caller holds the reservation for this specific room on this day index
        if (_reservations[roomId][currentDayIndex] != msg.sender) revert Unauthorized();
        
        StayRecord storage stay = _activeStays[roomId];
        if (stay.status == RoomStatus.CheckedIn) revert ActionNotAvailable();

        // Look ahead to find the full duration booked by this guest to map checkout parameters
        uint256 endDay = currentDayIndex;
        while (_reservations[roomId][endDay] == msg.sender) {
            endDay++;
        }

        // Effect: Lock the room state to CheckedIn tied to this guest variable
        _activeStays[roomId] = StayRecord({
            guest: msg.sender,
            checkInDay: currentDayIndex,
            checkOutDay: endDay,
            status: RoomStatus.CheckedIn
        });

        emit GuestCheckedIn(roomId, msg.sender);
    }

    /**
     * @dev Step 3: Guest or front desk triggers checkout at or before checkOutDay.
     */
    function checkOut(uint256 roomId) external {
        StayRecord storage stay = _activeStays[roomId];
        if (stay.status != RoomStatus.CheckedIn) revert ActionNotAvailable();
        
        // Ensure either the guest is checking out, or the admin is clearing an expired stay
        if (msg.sender != stay.guest && msg.sender != owner()) revert Unauthorized();

        emit GuestCheckedOut(roomId, stay.guest);

        // Effect: Clear the active stay storage mapping entirely, returning status to Vacant
        delete _activeStays[roomId];
    }

    /**
     * @dev Read function to check booking calendar state.
     */
    function getReservation(uint256 roomId, uint256 dayIndex) external view returns (address) {
        return _reservations[roomId][dayIndex];
    }

    /**
     * @dev Read function to inspect current occupancy profile.
     */
    function getActiveStay(uint256 roomId) external view returns (address guest, uint256 checkOutDay, RoomStatus status) {
        StayRecord memory stay = _activeStays[roomId];
        return (stay.guest, stay.checkOutDay, stay.status);
    }
}

