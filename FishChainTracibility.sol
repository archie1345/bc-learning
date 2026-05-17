// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/*
    FishChain Traceability System
    Case Study: eFishery Aquaculture Supply Chain

    Purpose:
    - Record aquaculture product batches
    - Track harvest and distribution status
    - Allow buyers to verify product history
    - Improve transparency and traceability
*/

contract FishChainTraceability {
    address public admin;
    uint256 public batchCounter;

    enum BatchStatus{
        Created, Harvested, InDistribution, Delivered, Verified
    }

    struct Batch {
        uint256 batchId;
        string productName;
        string species;
        string farmLocation;
        string farmerName;
        uint256 harvestDate;
        uint256 weightKg;
        string qualityGrade;
        string distributorName;
        string destination;
        BatchStatus status;
        address createdBy;
        bool exists;
    }

    struct History {
        uint256 timestamp;
        string action;
        string description;
        address updatedBy;
    }

    mapping(uint256 => Batch) private batches;
    mapping(uint256 => History[]) private batchHistories;

    event BatchCreated(
        uint256 indexed batchId,
        string productName,
        string farmerName,
        address createdBy
    );

    event BatchUpdated(
        uint256 indexed batchId,
        string action,
        address updatedBy
    );

    modifier onlyAdmin(){
        require(msg.sender == admin, "only admin can perform this action");
        _;
    }

    modifier batchExists(uint256 _batchId){
        require(batches[_batchId].exists, "batch does not exist");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function createBatch(string memory _productName, string memory _species, string memory _farmLocation, string memory _farmerName) public onlyAdmin{
        batchCounter++;

        batches[batchCounter] = Batch({
            batchId: batchCounter,
            productName: _productName,
            species: _species,
            farmLocation: _farmLocation,
            farmerName: _farmerName,
            harvestDate: 0,
            weightKg: 0,
            qualityGrade: "",
            distributorName: "",
            destination: "",
            status: BatchStatus.Created,
            createdBy: msg.sender,
            exists: true
        });

        batchHistories[batchCounter].push(
            History({
                timestamp: block.timestamp,
                action: "Batch Created",
                description: "New aquaculture product batch registered",
                updatedBy: msg.sender
            })
        );

        emit BatchCreated(batchCounter, _productName, _farmerName, msg.sender);
    }

    function addHarvestData(uint256 _batchId, uint256 _weightKg, string memory _qualityGrade) public batchExists(_batchId){
        Batch storage batch = batches[_batchId];

        require(batch.status == BatchStatus.Created, "Harvest data can only be added after batch creation");

        batch.harvestDate = block.timestamp;
        batch.weightKg = _weightKg;
        batch.qualityGrade = _qualityGrade;
        batch.status = BatchStatus.Harvested;

        batchHistories[_batchId].push(History({
            timestamp: block.timestamp,
            action: "Harvest Data Added",
            description: "Harvest weight and quality grade recorded",
            updatedBy: msg.sender
            })
        );

        emit BatchUpdated(_batchId, "Harvest Data Added", msg.sender);
    }

    function addDistributionData(uint256 _batchId, string memory _distributorName, string memory _destination) public batchExists(_batchId){
        Batch storage batch = batches[_batchId];

        require(batch.status == BatchStatus.Harvested, "Distribution can only start after harvest");

        batch.destination = _destination;
        batch.distributorName = _distributorName;
        batch.status = BatchStatus.InDistribution;

        batchHistories[_batchId].push(History({
            timestamp: block.timestamp,
            action: "Distribution Started",
            description: "Distributor and destination data recorded",
            updatedBy: msg.sender
            })
        );

        emit BatchUpdated(_batchId, "Distribution Started", msg.sender);
    }

    function markAsDelivered(uint256 _batchId) public batchExists(_batchId){
        Batch storage batch = batches[_batchId];

        require(batch.status ==  BatchStatus.InDistribution, "Batch must be in distribution first");

        batch.status = BatchStatus.Delivered;

        batchHistories[_batchId].push(History({
            timestamp: block.timestamp,
            action: "Batch Delivered",
            description: "Product batch delivered to destination",
            updatedBy: msg.sender
            })
        );

        emit BatchUpdated(_batchId, "Batch Delivered", msg.sender);
    }

    function verifyBatch(uint256 _batchId) public batchExists(_batchId){
        Batch storage batch = batches[_batchId];

        require(batch.status == BatchStatus.Delivered, "Batch must be delivered before verification");

        batch.status = BatchStatus.Verified;

        batchHistories[_batchId].push(History({
            timestamp: block.timestamp,
            action: "Batch Verified",
            description: "Buyer verified product tracebility",
            updatedBy: msg.sender
            })
        );

        emit BatchUpdated(_batchId, "Batch Verified", msg.sender);
    }

    function getBasicBatchInfo(uint256 _batchId) public view batchExists(_batchId) returns (
        uint256 batchId,
        string memory productName,
        string memory species,
        string memory farmLocation,
        string memory farmerName,
        address createdBy
    ){
        Batch storage batch = batches[_batchId];

        return (
            batch.batchId,
            batch.productName,
            batch.species,
            batch.farmLocation,
            batch.farmerName,
            batch.createdBy
        );
    }

    function getHarvestInfo(uint256 _batchId) public view batchExists(_batchId) returns (
        uint256 harvestDate,
        uint256 weightKg,
        string memory qualityGrade
    ){
        Batch storage batch = batches[_batchId];

        return (
            batch.harvestDate,
            batch.weightKg,
            batch.qualityGrade
        );
    }

    function getDistributionInfo(uint256 _batchId) public view batchExists(_batchId) returns (
        string memory distributorName,
        string memory destination,
        BatchStatus status
    ){
        Batch storage batch = batches[_batchId];

        return (
            batch.distributorName,
            batch.destination,
            batch.status
        );
    }

    function getHistoryByIndex(uint256 _batchId, uint256 _index) public view batchExists(_batchId) returns (
        string memory action,
        string memory description,
        address updatedBy
    ){
        require(_index < batchHistories[_batchId].length, "History index out of range");

        History memory history = batchHistories[_batchId][_index];

        return (history.action,history.description,history.updatedBy);
    }

    function getBatchHash(uint256 _batchId) public view batchExists(_batchId) returns (bytes32){
        Batch memory batch = batches[_batchId];

        return keccak256(abi.encode(
            batch.batchId,
            batch.productName,
            batch.species,
            batch.farmLocation,
            batch.farmerName,
            batch.harvestDate,
            batch.weightKg,
            batch.qualityGrade,
            batch.distributorName,
            batch.destination,
            batch.status
        ));
    }
}