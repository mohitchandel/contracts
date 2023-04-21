pragma solidity 0.8.17;

import "ds-test/test.sol";
import { IHopBridge } from "lifi/Interfaces/IHopBridge.sol";
import { Test } from "forge-std/Test.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { HopDirect } from "lifi/Facets/HopFacetDirect.sol";
import { console } from "../utils/Console.sol";

contract HopDirectGasETH is Test {
    address internal constant HOP_USDC_BRIDGE =
        0x3666f603Cc164936C1b87e207F36BEBa4AC5f18a;
    address internal constant HOP_NATIVE_BRIDGE =
        0xb8901acB165ed027E32754E0FFe830802919727f;
    address internal constant USDC_ADDRESS =
        0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address internal constant WHALE =
        0x72A53cDBBcc1b9efa39c834A540550e23463AAcB; // USDC + ETH
    address internal constant RECEIVER =
        0x552008c0f6870c2f77e5cC1d2eb9bdff03e30Ea0;

    // IHopBridge internal hop;
    ERC20 internal usdc;
    HopDirect internal hopdirect;
    IHopBridge internal hopBridgeNative;

    bytes8 transactionId;
    uint256 destinationChainId;
    uint256 deadline;

    uint256 amountUSDC;
    uint256 amountBonderFeeUSDC;
    uint256 amountOutMinUSDC;
    bytes packedUSDC;

    uint256 amountNative;
    uint256 amountBonderFeeNative;
    uint256 amountOutMinNative;
    bytes forwardNative;
    bytes forwardNativeSelector;
    bytes packedNativeSelector;
    bytes packedNativeYulSelector;
    bytes packedFuncSelector;
    HopDirect.HopData nativeStruct;
    bytes packedNative;
    bytes nativeStructEncoded;

    function fork() internal {
        string memory rpcUrl = vm.envString("ETH_NODE_URI_MAINNET");
        uint256 blockNumber = 14847528;
        vm.createSelectFork(rpcUrl, blockNumber);
    }

    function setUp() public {
        fork();

        hopdirect = new HopDirect();
        usdc = ERC20(USDC_ADDRESS);
        hopBridgeNative = IHopBridge(HOP_NATIVE_BRIDGE);

        // prepare calls
        transactionId = bytes8("someId");
        destinationChainId = 137;
        deadline = block.timestamp + 7 * 24 * 60 * 60;

        // Native params
        amountNative = 1 * 10 ** 18;
        amountBonderFeeNative = (amountNative / 100) * 1;
        amountOutMinNative = (amountNative / 100) * 99;

        // USDC params
        amountUSDC = 100 * 10 ** usdc.decimals();
        amountBonderFeeUSDC = (amountUSDC / 100) * 1;
        amountOutMinUSDC = (amountUSDC / 100) * 99;

        forwardNative = abi.encode(
            destinationChainId,
            RECEIVER,
            amountNative,
            amountOutMinNative,
            block.timestamp + 7 * 24 * 60 * 60,
            address(0),
            0
        );
        forwardNativeSelector = bytes.concat(
            IHopBridge.sendToL2.selector,
            forwardNative
        );
        packedNative = bytes.concat(
            bytes8(transactionId), // transactionId
            bytes20(RECEIVER), // receiver
            bytes4(uint32(destinationChainId)), // destinationChainId
            bytes16(uint128(amountOutMinNative)), // destinationAmountOutMin
            bytes20(HOP_NATIVE_BRIDGE), // hopBridge
            bytes20(address(0)),
            bytes16(uint128(0))
        );

        packedNativeSelector = bytes.concat(
            HopDirect.bridgeNativeL1Packed.selector,
            packedNative
        );
        packedNativeYulSelector = bytes.concat(
            HopDirect.bridgeNativeL1PackedYul.selector,
            packedNative
        );
        packedFuncSelector = bytes.concat(bytes1(uint8(1)), packedNative);

        nativeStruct = HopDirect.HopData(
            bytes8(transactionId), // transactionId
            bytes20(RECEIVER), // receiver
            bytes4(uint32(destinationChainId)), // destinationChainId
            bytes16(uint128(amountOutMinNative)), // destinationAmountOutMin
            bytes20(HOP_NATIVE_BRIDGE), // hopBridge
            bytes20(address(0)), // relayer
            bytes16(uint128(0)) // relayerFee
        );
        nativeStructEncoded = abi.encode(nativeStruct);
    }

    function testLog() public {
        console.logString("packedNative");
        console.logBytes(packedNative);
        console.logString("nativeStructEncoded");
        console.logBytes(nativeStructEncoded);
    }

    function testCallHopNativeL1() public {
        vm.startPrank(WHALE);
        hopBridgeNative.sendToL2{ value: amountNative }(
            destinationChainId,
            RECEIVER,
            amountNative,
            amountOutMinNative,
            deadline,
            address(0),
            0
        );
        vm.stopPrank();
    }

    function testBridgeNativeL1Forward() public {
        vm.startPrank(WHALE);
        hopdirect.bridgeNativeL1Forward{ value: amountNative }(
            transactionId,
            HOP_NATIVE_BRIDGE,
            forwardNative
        );
        vm.stopPrank();
    }

    function testBridgeNativeL1Forward2() public {
        vm.startPrank(WHALE);
        hopdirect.bridgeNativeL1Forward2{ value: amountNative }(
            transactionId,
            HOP_NATIVE_BRIDGE,
            forwardNativeSelector
        );
        vm.stopPrank();
    }

    function testBridgeNativeL1Min() public {
        vm.startPrank(WHALE);
        hopdirect.bridgeNativeL1Min{ value: amountNative }(
            transactionId,
            RECEIVER,
            destinationChainId,
            amountOutMinNative,
            HOP_NATIVE_BRIDGE,
            deadline,
            address(0),
            0
        );
        vm.stopPrank();
    }

    function testBridgeNativeL1Packed() public {
        vm.startPrank(WHALE);
        (bool success, ) = address(hopdirect).call{ value: amountNative }(
            packedNativeSelector
        );
        if (!success) {
            revert();
        }
        vm.stopPrank();
    }

    function testBridgeNativeL1Func() public {
        vm.startPrank(WHALE);
        (bool success, ) = address(hopdirect).call{ value: amountNative }(
            packedFuncSelector
        );
        if (!success) {
            revert();
        }
        vm.stopPrank();
    }

    function testBridgeNativeL1Struct() public {
        vm.startPrank(WHALE);
        hopdirect.bridgeNativeL1Struct{ value: amountNative }(nativeStruct);
        vm.stopPrank();
    }

    function testBridgeNativeL1PackedYul() public {
        vm.startPrank(WHALE);
        (bool success, ) = address(hopdirect).call{ value: amountNative }(
            packedNativeSelector
        );
        if (!success) {
            revert();
        }
        vm.stopPrank();
    }

    // TODO: Compare to other implementations
    // function testCallOthersNativeL1() public {
    //     vm.startPrank(WHALE);
    //     bytes memory data = 0x00000011d025dec0000000000000000000000000552008c0f6870c2f77e5cc1d2eb9bdff03e30ea0000000000000000000000000b8901acb165ed027e32754e0ffe830802919727f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000089000000000000000000000000000000000000000000000000016345785d8a000000000000000000000000000000000000000000000000000001617326206fa00500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000018799d6f2790000000000000000000000000000000000000000000000000000000000000000;
    //     (bool success, ) = address(0x3a23F943181408EAC424116Af7b7790c94Cb97a5).call{ value: 100000000000000 }(
    //         data
    //     );
    //     if (!success) {
    //         revert();
    //     }
    //     vm.stopPrank();
    // }
}
