// Peer-to-Peer Car Rental: Book time slots on a shared asset calendar registry.

// 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract PeerToPeerCarRental {

    struct Car {
        address owner;
        uint256 pricePerDay;
        bool isListed;
    }

    // Car ID => General Profile Details
    mapping(uint256 => Car) private _cars;
    
    // Car ID => (Day Index => Renter Address)
    // Tracks specific day availability to avoid double booking
    mapping(uint256 => mapping(uint256 => address)) private _calendar;

    uint256 public totalCarsListed;

    // Events
    event CarListed(uint256 indexed carId, address indexed owner, uint256 pricePerDay);
    event CarBooked(uint256 indexed carId, address indexed renter, uint256 indexed dayIndex, uint256 amountPaid);

    // Custom Errors
    error CarNotAvailable();
    error CarNotRegistered();
    error IncorrectPayment();
    error Unauthorized();

    /**
     * @dev List a new car in the registry with a set daily price.
     */
    function listCar(uint256 pricePerDayInWei) external returns (uint256) {
        uint256 carId = totalCarsListed;
        
        _cars[carId] = Car({
            owner: msg.sender,
            pricePerDay: pricePerDayInWei,
            isListed: true
        });

        totalCarsListed++;
        emit CarListed(carId, msg.sender, pricePerDayInWei);
        return carId;
    }

    /**
     * @dev Book a specific day slot for a registered car.
     * @param carId The unique ID of the vehicle.
     * @param dayIndex A numerical representation of the day (e.g., Unix timestamp / 86400).
     */
    function bookCar(uint256 carId, uint256 dayIndex) external payable {
        Car memory car = _cars[carId];
        if (!car.isListed) revert CarNotRegistered();
        if (msg.value != car.pricePerDay) revert IncorrectPayment();
        
        // Check if the specific day slot is already filled
        if (_calendar[carId][dayIndex] != address(0)) {
            revert CarNotAvailable();
        }

        // Effect: Lock the day slot for the caller
        _calendar[carId][dayIndex] = msg.sender;

        emit CarBooked(carId, msg.sender, dayIndex, msg.value);

        // Interaction: Forward the payment immediately to the vehicle owner
        (bool success, ) = payable(car.owner).call{value: msg.value}("");
        if (!success) revert CarNotAvailable(); // Fallback safety catch
    }

    /**
     * @dev View function to check who has rented a car on a given day.
     * Returns address(0) if the slot is completely vacant.
     */
    function getBookingStatus(uint256 carId, uint256 dayIndex) external view returns (address) {
        return _calendar[carId][dayIndex];
    }

    /**
     * @dev Public helper to inspect car metadata.
     */
    function getCarDetails(uint256 carId) external view returns (address owner, uint256 pricePerDay, bool isListed) {
        Car memory car = _cars[carId];
        return (car.owner, car.pricePerDay, car.isListed);
    }
}