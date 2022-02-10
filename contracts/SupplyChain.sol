// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {
    address public owner;
    uint256 public skuCount;
    struct Item {
        string name;
        uint256 sku;
        uint256 price;
        State state;
        address seller;
        address buyer;
    }

    mapping(uint256 => Item) public items;

    enum State {
        ForSale,
        Sold,
        Shipped,
        Recieved
    }

    event LogForSale(uint256 _sku);
    event LogSold(uint256 _sku);
    event LogShipped(uint256 _sku);
    event LogRecieved(uint256 _sku);

    modifier isOwner(address _owner) {
        require(_owner == owner, 'Not Owner');
        _;
    }

    modifier verifyCaller(address _address) {
        require(msg.sender == _address);
        _;
    }

    modifier paidEnough(uint256 _sku) {
        uint256 _price = items[_sku].price;
        require(msg.value >= _price);
        _;
    }

    modifier checkValue(uint256 _sku) {
        _; //invoked after each function
        uint256 _price = items[_sku].price;
        uint256 amountToRefund = msg.value - _price;
        payable(items[_sku].buyer).transfer(amountToRefund);
    }

    modifier forSale(uint256 _sku) {
        //get item frrom marring, check state
        Item storage item = items[_sku];
        require(item.state == State.ForSale);
        _;
    }

    modifier sold(uint256 _sku) {
        Item storage item = items[_sku];
        require(item.state == State.Sold, 'item not for sale');
        _;
    }
    modifier shipped(uint256 _sku) {
        Item storage item = items[_sku];
        require(item.state == State.Shipped, 'Item not shipped');
        _;
    }
    modifier received(uint256 _sku) {
        _;
        Item storage item = items[_sku];
        item.state = State.Recieved;
        require(item.state == State.Recieved, 'Item not received');
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function addItem(string memory _name, uint256 _price) public returns (bool success) {
        items[skuCount] = Item({
            name: _name,
            sku: skuCount,
            price: _price,
            state: State.ForSale,
            seller: payable(msg.sender),
            buyer: address(0)
        });
        emit LogForSale(skuCount);
        skuCount++;
        success = true;
    }

    function buyItem(uint256 _sku)
        external
        payable
        forSale(_sku)
        paidEnough(_sku)
        checkValue(_sku)
    {
        Item storage item = items[_sku];
        item.buyer = msg.sender;
        item.state = State.Sold;
        (bool success, ) = item.seller.call{value: item.price}('');
        emit LogSold(_sku);
        require(success, 'Transaction not set');
    }

    function shipItem(uint256 _sku) external sold(_sku) verifyCaller(items[_sku].buyer) {
        Item storage item = items[_sku];
        item.state = State.Shipped;
        emit LogShipped(_sku);
        require(item.state == State.Shipped, 'Item not shipped');
    }

    function receiveItem(uint256 _sku)
        external
        shipped(_sku)
        verifyCaller(items[_sku].buyer)
        received(_sku)
    {
        emit LogRecieved(_sku);
    }

    function fetchItem(uint256 _sku)
        public
        view
        returns (
            string memory name,
            uint256 sku,
            uint256 price,
            uint256 state,
            address seller,
            address buyer
        )
    {
        name = items[_sku].name;
        sku = items[_sku].sku;
        price = items[_sku].price;
        state = uint256(items[_sku].state);
        seller = items[_sku].seller;
        buyer = items[_sku].buyer;
        return (name, sku, price, state, seller, buyer);
    }
}
