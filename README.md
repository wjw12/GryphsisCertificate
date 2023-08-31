# Gryphsis Course Certificate

This repository contains the smart contracts for the Gryphsis Course, an online education platform that allows students to enroll in courses, complete them, and receive a non-transferrable certificate (NFT) upon completion. The course has a tuition fee, a portion of which is refundable if the student completes the course within a specified period.

## Smart Contracts

The repository contains two main smart contracts:

1. `GryphsisCourse.sol`: This is the main contract that handles student enrollment, completion, tuition fee payments, and refunds.

2. `StudentCertificate.sol`: This contract is an ERC1155 contract that mints non-transferrable NFT certificates for students who complete the course.

## Features

### GryphsisCourse.sol

- Allows students to enroll in the course by paying a tuition fee.
- Allows the admin to mark a student as having completed the course.
- Allows students who have completed the course within the maximum study period to request a refund of the refundable portion of the tuition fee.
- Allows the admin to withdraw the non-refundable portion of the tuition fees to a treasury address.
- In case of emergencies, allows the admin to withdraw any tokens from the contract.

### StudentCertificate.sol

- Mints a new certificate (NFT) for a student when they complete the course.
- The certificate includes metadata such as the completion date and a report URL.
- Certificates are non-transferrable.

## Interaction Flow

1. A student enrolls in the course by calling the `enroll` function and transferring the tuition fee to the contract.
2. After the student completes the course, the admin calls the `completeCourse` function, which marks the student as completed, withdraws the non-refundable portion of the tuition fee to the treasury, and mints a certificate for the student.
3. If the student completed the course within the maximum study period, they can call the `requestRefund` function to receive a refund of the refundable portion of the tuition fee.
4. The admin can call the `withdrawAll` or `withdrawBatch` functions to withdraw the non-refundable portion of the tuition fees for all students or a batch of students, respectively.

## Auditing Findings

1. `GryphsisCourse.sol`: The smart contract logic appears to be sound and the funds are safe. The contract correctly handles the tuition payment and refund logic as per the comments in the code. However, the contract could benefit from additional checks to prevent reentrancy attacks.

2. `StudentCertificate.sol`: The smart contract logic appears to be sound. The contract correctly mints a new certificate for a student upon completion of the course. However, the metadata of the contract does not strictly follow the ERC1155 standard, as the metadata is stored on-chain and the contract does not implement a function to retrieve the URI of a specific token. The contract could also benefit from additional checks to prevent reentrancy attacks.

## Other Notes

- The `GryphsisCourse.sol` contract does not implement any mechanism to prevent the admin from marking a student as completed without them actually having completed the course. This could potentially be addressed by implementing a verification mechanism or by decentralizing the process of marking a student as completed.

- The `StudentCertificate.sol` contract does not allow the transfer of certificates. This is by design, as the certificates are meant to be non-transferrable. However, this could potentially limit the use cases for the certificates in the future.

- The `GryphsisCourse.sol` contract stores the addresses of all students in an array. This could potentially lead to high gas costs when withdrawing the tuition fees for all students. It may be more efficient to store the addresses in a mapping or to allow the admin to specify a batch of addresses to withdraw the fees for.

- The `emergencyWithdraw` function in the `GryphsisCourse.sol` contract allows the admin to withdraw any tokens from the contract. This could potentially be abused by a malicious admin. It may be more secure to implement a time lock or a multi-signature mechanism for this function.

## Conclusion

The Gryphsis Course smart contracts provide a solid foundation for an online education platform. However, there are several areas where the contracts could be improved or extended. It is recommended to conduct a thorough security audit before deploying the contracts on the mainnet.