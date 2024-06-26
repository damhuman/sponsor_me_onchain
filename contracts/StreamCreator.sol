// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.26;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ud2x18 } from "@prb/math/src/UD2x18.sol";
import { ud60x18 } from "@prb/math/src/UD60x18.sol";
import { ISablierV2LockupDynamic } from "@sablier/v2-core/src/interfaces/ISablierV2LockupDynamic.sol";
import { Broker, LockupDynamic } from "@sablier/v2-core/src/types/DataTypes.sol";
// import { IWETH } from "./IWETH.sol";

interface IWETH1 is IERC20 {
  receive() external payable;

  function deposit() external payable;

  function withdraw(uint256 wad) external;
}


contract StreamCreator {
    address payable private constant WETH_ADDR = payable(0x5300000000000000000000000000000000000004);
    IWETH1 public constant WETH = IWETH1(WETH_ADDR);

    ISablierV2LockupDynamic public constant LOCKUP_DYNAMIC =
        ISablierV2LockupDynamic(0xc9940AD8F43aAD8e8f33A4D5dbBf0a8F7FF4429A);

    function createStream(uint128 amount_per_month, uint128 count_of_months, address recipient_addr) public returns (uint256 streamId) {
        uint256 totalAmount = amount_per_month * count_of_months;
        WETH.transferFrom(msg.sender, address(this), totalAmount);
        WETH.approve(address(LOCKUP_DYNAMIC), totalAmount);

        LockupDynamic.CreateWithDeltas memory params;

        params.sender = msg.sender;
        params.recipient = recipient_addr;
        params.totalAmount = uint128(totalAmount);
        params.asset = WETH;
        params.cancelable = true;
        params.transferable = false;
        params.broker = Broker(address(0), ud60x18(0));

        params.segments = new LockupDynamic.SegmentWithDelta[](count_of_months);

        uint256 oneMonthInSeconds = 30 * 86400;
        uint256 twoMinutes = 120;
        for (uint256 i = 0; i < count_of_months; i++) {
            params.segments[i] = LockupDynamic.SegmentWithDelta({
                amount: amount_per_month,
                exponent: ud2x18(1e18),
                delta: uint40(twoMinutes)
            });
        }

        streamId = LOCKUP_DYNAMIC.createWithDeltas(params);
    }
}