pragma solidity ^0.8.0;

import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";
import "openzeppelin-contracts/contracts/utils/math/SafeMath.sol";
import "./StudentCertificate.sol";

contract GryphsisCourse is AccessControl {
    using SafeMath for uint256;

    IERC20 public paymentToken;
    StudentCertificate public studentCertificate;

    // Tuition has two parts: non-refundable and refundable
    // `tuitionFee` is paid in full at enrollment
    // `refundableFee` is refunded if the student completes the course within the max study period
    uint256 public tuitionFee;
    uint256 public refundableFee;
    uint256 public maxStudyPeriod;
    address public treasury;

    struct Student {
        uint256 enrollmentTime;
        bool completed;
        bool refunded;
        bool withdrawnNonRefundable;
        bool withdrawnRefundable;
    }

    mapping(address => Student) public students;
    address[] public studentAddresses;

    event Enrollment(address indexed student, uint256 enrollmentTime, uint256 tuitionFee);
    event Completion(address indexed student);
    event Refund(address indexed student, uint256 amount);
    event TuitionCollection(address indexed to, address indexed student, uint256 amount);

    constructor(
        address _paymentToken,
        address _studentCertificate,
        uint256 _tuitionFee,
        uint256 _refundableFee,
        uint256 _maxStudyPeriod,
        address _treasury
    ) {
        require(_tuitionFee > 0, "Tuition fee must be greater than 0");
        require(_maxStudyPeriod > 0, "Max study period must be greater than 0");
        require(_refundableFee <= _tuitionFee, "Refundable fee must <= tuition fee");

        paymentToken = IERC20(_paymentToken);
        studentCertificate = StudentCertificate(_studentCertificate);
        tuitionFee = _tuitionFee;
        maxStudyPeriod = _maxStudyPeriod;
        refundableFee = _refundableFee;
        treasury = _treasury;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function setPaymentToken(address _paymentToken) external onlyRole(DEFAULT_ADMIN_ROLE) {
        paymentToken = IERC20(_paymentToken);
    }

    function setTuitionFee(uint256 _tuitionFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_tuitionFee >= refundableFee, "Tuition fee must >= refundable fee");
        tuitionFee = _tuitionFee;
    }

    function setrefundableFee(uint256 _refundableFee) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(_refundableFee <= tuitionFee, "Refundable fee must <= tuition fee");
        refundableFee = _refundableFee;
    }

    function setMaxStudyPeriod(uint256 _maxStudyPeriod) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxStudyPeriod = _maxStudyPeriod;
    }

    function setTreasury(address _treasury) external onlyRole(DEFAULT_ADMIN_ROLE) {
        treasury = _treasury;
    }

    function enroll() external {
        require(students[msg.sender].enrollmentTime == 0, "Already enrolled");
        require(paymentToken.transferFrom(msg.sender, address(this), tuitionFee), "Tuition fee transfer failed");

        students[msg.sender] = Student({
            enrollmentTime: block.timestamp,
            completed: false,
            refunded: false,
            withdrawnNonRefundable: false,
            withdrawnRefundable: false
        });

        studentAddresses.push(msg.sender);

        emit Enrollment(msg.sender, block.timestamp, tuitionFee);
    }

    // Admin should call this function after the student has completed the course
    function completeCourse(address studentAddress, string memory reportURL) external onlyRole(DEFAULT_ADMIN_ROLE) {
        Student storage student = students[studentAddress];
        require(student.enrollmentTime > 0, "Student not enrolled");
        require(!student.completed, "Already completed");

        student.completed = true;
        
        // withdraw the non-refundable fee
        withdrawSingle(studentAddress);

        // mint the NFT
        studentCertificate.mintCertificate(studentAddress, reportURL);

        emit Completion(studentAddress);
    }

    // Student who has completed the course in time can call this function to request a refund
    function requestRefund() external {
        Student storage student = students[msg.sender];
        require(student.completed, "Course not completed");
        require(!student.refunded, "Already refunded");
        require(block.timestamp <= student.enrollmentTime + maxStudyPeriod, "Max study period exceeded");

        require(paymentToken.transfer(msg.sender, refundableFee), "Refund transfer failed");

        student.refunded = true;

        emit Refund(msg.sender, refundableFee);
    }

    function withdrawAll() external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < studentAddresses.length; i++) {
            withdrawSingle(studentAddresses[i]);
        }
    }

    function withdrawBatch(address[] memory studentBatch) external onlyRole(DEFAULT_ADMIN_ROLE) {
        for (uint256 i = 0; i < studentBatch.length; i++) {
            withdrawSingle(studentBatch[i]);
        }
    }

    function withdrawSingle(address studentAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        Student storage student = students[studentAddress];
        require(student.enrollmentTime > 0, "Student not enrolled");

        uint256 withdrawAmount = 0;

        // Withdraw the non-refundable amount once per student
        if (!student.withdrawnNonRefundable) {
            student.withdrawnNonRefundable = true;
            uint256 nonrefundableFee = tuitionFee.sub(refundableFee);
            withdrawAmount = withdrawAmount.add(nonrefundableFee);
        }

        // Withdraw the refundable amount only for students who haven't completed the curriculum after the max study period
        if (!student.completed && block.timestamp > student.enrollmentTime + maxStudyPeriod && !student.withdrawnRefundable) {
            student.withdrawnRefundable = true;
            withdrawAmount = withdrawAmount.add(refundableFee);
        }

        if (withdrawAmount > 0) {
            require(paymentToken.transfer(treasury, withdrawAmount), "Withdraw transfer failed");
            emit TuitionCollection(treasury, studentAddress, withdrawAmount);
        }
    }

    function emergencyWithdraw(address tokenAddress, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        require(IERC20(tokenAddress).transfer(treasury, amount), "Withdraw transfer failed");
    }

    function allStudentAddresses() public view returns (address[] memory) {
        return studentAddresses;
    }

}
