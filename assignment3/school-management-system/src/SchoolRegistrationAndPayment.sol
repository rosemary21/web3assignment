// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract SchoolRegistrationAndPayment {
    address public owner;
    uint256 public total_supply;


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event FeePaid(address indexed student, uint256 amount);
    event SalaryPaid(address indexed staff, uint256 amount);
    event SuspendStaff(uint256 staffId);
    event RemoveStudent(uint256 studentId);

    mapping(address => uint256) public studentFees;
    mapping(address => uint256) public staffSalary;

    mapping(address => mapping(address => uint256)) public allowances;



    
    constructor(){
        owner=msg.sender;
    }

    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }

    enum PaymentStatus{
        UNPAID,PAID
    }

    struct Student{

        uint256 id;
        string name;
        uint256 age;
        string course;
        string email;
        PaymentStatus PaymentStatus;
        uint256 amountPaid;
        bool isRegistered;
    }

    struct Staff{
        uint256 id;
        string name;
        string email;
        PaymentStatus PaymentStatus;
        bool isActive;
        bool isRegistered;
        bool isSuspend;
    }

    mapping(uint256=>Student) public student;
    mapping(uint256=>Staff) public staffMember;
    mapping(uint8=>uint256) public gradeFees;
    mapping(address=>uint256) public balances;

    event StudentRegistered(uint256 id, string name);
    event StaffRegistered(uint256 id, string name);

    modifier onlyOwner(){
        require(msg.sender==owner,"Not Owner");
        _;
    }


function setGradeFee(uint8 _grade, uint256 _fee)  public onlyOwner{
                gradeFees[_grade] = _fee;

    }


    function registerStudent(
        uint256 _id,
        string memory _name,
        uint256 _age,
        string memory _course,
        uint8 _gradeLevel,
        string memory _email
    ) public payable {
        require(!student[_id].isRegistered, "Student Already Registered");

        uint256 requiredFee = gradeFees[_gradeLevel];
        require(requiredFee > 0, "Invalid grade level");
        require(msg.value == requiredFee, "Incorrect fee amount");

        student[_id]=Student({
            id: _id,
            name: _name,
            age:_age,
            course:_course,
            email:_email,
            isRegistered: true,
            amountPaid: 0,
            PaymentStatus: PaymentStatus.UNPAID

        });

        emit StudentRegistered(_id, _name);
    }

    uint256 public staffRegistrationFee = 1 ether;

    function registerStaff(uint256 _id,string memory _name,string memory _email)  public{
        require(staffMember[_id].isRegistered,"Staff Already Registered");

        staffMember[_id]=Staff({
            id:_id,
            name:_name,
            email:_email,
            PaymentStatus: PaymentStatus.UNPAID,
            isActive:false,
            isRegistered:true,
            isSuspend:false
        });

        emit StaffRegistered (_id,_name);
        
    }



    function removeStudent(uint256 _id) external onlyOwner {
        require(student[_id].isRegistered, "Not a registered student");
        delete student[_id];
        emit RemoveStudent(_id);


    }


    function getStudent(uint256 _id) public view returns(
        uint256, string memory,uint256,string memory)
        {
            require(student[_id].isRegistered, "Student Not Found");
            Student memory s=student[_id];
            return (s.id,s.name,s.age,s.course);
        }


    function getStaff(uint256 _id) public view returns(uint256, string memory,string memory){
        require(staffMember[_id].isRegistered,"Staff Not Found");

        Staff memory s=staffMember[_id];
        return (s.id,s.name,s.email);
        
    }
        
    function mint(address _to, uint256 _amount) public onlyOwner{
        require(_to !=address(0),"Cannot Mint to Zero address");
        total_supply+=_amount;
        balances[_to] +=_amount;
        emit Transfer(address (0),_to,_amount);
        

    }


    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowances[_owner][_spender];
    }


     function approve(address _spender, uint256 _value) public returns (bool) {
        require(_spender != address(0), "Cannot approve zero address");
        require(_value > 0, "Cannot approve zero value");
        require(balances[msg.sender] >= _value, "Insufficient balance to approve");

        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }





     function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "Cannot transfer to zero address");
        require(_value > 0, "Cannot transfer zero value");
        require(balances[msg.sender] >= _value, "Insufficient balance");

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0), "Cannot transfer to zero address");
        require(_value > 0, "Cannot transfer zero value");
        require(balances[_from] >= _value, "Insufficient balance");
        require(allowances[_from][msg.sender] >= _value, "Insufficient allowance");

        balances[_from] -= _value;
        balances[_to] += _value;
        allowances[_from][msg.sender] -= _value;

        emit Transfer(_from, _to, _value);
        return true;
    }
    


    function setStudentFee(address student, uint256 amount) external onlyOwner {
        studentFees[student] = amount;
    }


   function suspendStaff(uint256 _id) public{ 
    require(!staffMember[_id].isSuspend,"Staff is Suspend");
    staffMember[_id].isSuspend=true;
    emit SuspendStaff(_id);
   }


    function payFee(uint256 amount) external {
        require(studentFees[msg.sender] >= amount, "Exceeds required fee");
        require(transferFrom(msg.sender, address(this), amount), "Payment failed");

        studentFees[msg.sender] -= amount;
        emit FeePaid(msg.sender, amount);
    }

    function setStaffSalary(address staff, uint256 amount) external onlyOwner {
        staffSalary[staff] = amount;
    }

    function paySalary(address staff) external onlyOwner {
        uint256 amount = staffSalary[staff];
        require(amount > 0, "No salary set");

        require(transfer(staff, amount), "Salary transfer failed");
        emit SalaryPaid(staff, amount);
    }


     function contractBalance() external view returns (uint256) {
        return balances[address(this)];
    }



}
