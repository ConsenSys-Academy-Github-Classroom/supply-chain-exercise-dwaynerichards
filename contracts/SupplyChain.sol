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

    event LogForSale(uint256 sku);
    event LogSold(uint256 sku);
    event LogShipped(uint256 sku);
    event LogRecieved(uint256 sku);

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
        uint256 _price = items[_sku].price;
        uint256 amountToRefund = msg.value - _price;
        payable(items[_sku].buyer).transfer(amountToRefund);
        _; //invoked after each function
    }

    modifier forSale(uint256 _sku) {
        //get item frrom marring, check state
        Item storage item = items[_sku];
        require(item.state == State.ForSale);
        _;
    }

    modifier sold(uint256 _sku) {
        _;
        Item storage item = items[_sku];
        item.state = State.Sold;
    }
    modifier shipped(uint256 _sku) {
        _;
        Item storage item = items[_sku];
        item.state = State.Shipped;
    }
    modifier received(uint256 _sku) {
        _;
        Item storage item = items[_sku];
        item.state = State.Recieved;
    }

    //every time item is added to mapping, change state to for sale
    //
    constructor() public {
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

    // Implement this buyItem function.
    // 1. it should be payable in order to receive refunds
    // 2. this should transfer money to the seller,
    // 3. set the buyer as the person who called this transaction,
    // 4. set the state to Sold.
    // 5. this function should use 3 modifiers to check
    //    - if the item is for sale,
    //    - if the buyer paid enough,
    //    - check the value after the function is called to make
    //      sure the buyer is refunded any excess ether sent.
    // 6. call the event associated with this function!
    //verify calller(address), PaidEnough(uint price), CheckValue(uint sku)=> IssuesRefund
    function buyItem(uint256 _sku)
        external
        payable
        forSale(_sku)
        paidEnough(_sku)
        checkValue(_sku)
    {
        Item storage item = items[_sku];
        item.state = State.Sold;
        item.buyer = msg.sender;
        //send money to seller
        //seller is in mapping
        //is modifier invoked before function??
        (bool success, ) = item.seller.call{value: msg.value}('');
        emit LogSold(_sku);
        require(success, 'Transaction not set');
    }

    // 1. Add modifiers to check:
    //    - the item is sold already
    //    - the person calling this function is the seller.
    // 2. Change the state of the item to shipped.
    // 3. call the event associated with this function!
    function shipItem(uint256 sku) public {}

    // 1. Add modifiers to check
    //    - the item is shipped already
    //    - the person calling this function is the buyer.
    // 2. Change the state of the item to received.
    // 3. Call the event associated with this function!
    function receiveItem(uint256 sku) public {}

    // Uncomment the following code block. it is needed to run tests
    /* function fetchItem(uint _sku) public view */
    /*   returns (string memory name, uint sku, uint price, uint state, address seller, address buyer) */
    /* { */
    /*   name = items[_sku].name; */
    /*   sku = items[_sku].sku; */
    /*   price = items[_sku].price; */
    /*   state = uint(items[_sku].state); */
    /*   seller = items[_sku].seller; */
    /*   buyer = items[_sku].buyer; */
    /*   return (name, sku, price, state, seller, buyer); */
    /* } */
}
