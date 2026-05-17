// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract CertificateVerification {

    struct Certificate {
        string studentName;
        string course;
        string hash;
        uint issueDate;
    }

    mapping(string => Certificate) public certificates;

    function issueCertificate(
        string memory _hash,
        string memory _studentName,
        string memory _course
    ) public {

        certificates[_hash] = Certificate(
            _studentName,
            _course,
            _hash,
            block.timestamp
        );
    }

    function verifyCertificate(string memory _hash)
        public
        view
        returns (Certificate memory)
    {
        return certificates[_hash];
    }
}