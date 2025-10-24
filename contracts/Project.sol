pragma solidity ^0.8.0;

contract Project {

    struct Prop {
        uint id;
        string desc;
        uint deadline;
        uint yes;
        uint no;
        bool done;
        address creator;
        address to;
        uint val;
        mapping(address => bool) voted;
    }

    address public admin;
    mapping(address => bool) public members;
    Prop[] public props;
    uint public propNum;

    event PropAdded(uint id, string desc, uint deadline);
    event VotedOn(uint id, address voter, bool support);
    event PropDone(uint id, address to, uint val);

    constructor() {
        admin = msg.sender;
        members[msg.sender] = true;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "admin:!");
        _;
    }

    modifier onlyMember() {
        require(members[msg.sender], "member:!");
        _;
    }

    receive() external payable {}

    function addMember(address _member) public onlyAdmin {
        require(_member != address(0), "zero:!");
        members[_member] = true;
    }

    function createProp(string memory _desc, uint _time, address _to, uint _val) public onlyMember {
        require(_time > 0, "time:!");
        uint dead = block.timestamp + _time;
        
        Prop storage p = props.push();
        p.id = propNum;
        p.desc = _desc;
        p.deadline = dead;
        p.creator = msg.sender;
        p.to = _to;
        p.val = _val;
        
        propNum++;
        
        emit PropAdded(p.id, _desc, dead);
    }

    function vote(uint _id, bool _support) public onlyMember {
        require(_id < propNum, "id:!");
        
        Prop storage p = props[_id];
        
        require(!p.voted[msg.sender], "voted:!");
        require(block.timestamp < p.deadline, "deadline:!");

        p.voted[msg.sender] = true;
        
        if (_support) {
            p.yes++;
        } else {
            p.no++;
        }
        
        emit VotedOn(_id, msg.sender, _support);
    }

    function execProp(uint _id) public onlyMember {
        require(_id < propNum, "id:!");
        
        Prop storage p = props[_id];
        
        require(!p.done, "done:!");
        require(block.timestamp >= p.deadline, "active:!");
        require(p.yes > p.no, "failed:!");

        p.done = true;

        if (p.to != address(0) && p.val > 0) {
            require(address(this).balance >= p.val, "funds:!");
            (bool sent, ) = p.to.call{value: p.val}("");
            require(sent, "send:!");
        }

        emit PropDone(_id, p.to, p.val);
    }

    function getProp(uint _id) public view returns (uint, string memory, uint, uint, uint, bool, address, address, uint) {
        require(_id < propNum, "id:!");
        Prop storage p = props[_id];
        return (
            p.id,
            p.desc,
            p.deadline,
            p.yes,
            p.no,
            p.done,
            p.creator,
            p.to,
            p.val
        );
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }
}
