pragma solidity 0.8.17;

import { IHopBridge } from "../Interfaces/IHopBridge.sol";
import { ILiFi } from "../Interfaces/ILiFi.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Hop Facet (Optimized for Rollups)
/// @author LI.FI (https://li.fi)
/// @notice Provides functionality for bridging through Hop
contract HopDirect is ILiFi {
    /// External Methods ///

    event LiFiTransactionId(bytes8 transactionId);

    struct HopData {
        bytes8 transactionId;
        bytes20 receiver;
        bytes4 destinationChainId;
        bytes16 amountOutMinNative;
        bytes20 hopBridge;
        bytes20 relayer;
        bytes16 relayerFee;
    }

    // for L1
    // precompiled
    // native, precompiled calldata for hop, transferId log
    function bridgeNativeL1Forward(
        bytes8 transactionId,
        address hopBridge,
        bytes calldata data
    ) external payable {
        (bool success, ) = hopBridge.call{ value: msg.value }(
            bytes.concat(IHopBridge.sendToL2.selector, data)
        );
        if (!success) {
            revert();
        }

        emit LiFiTransactionId(transactionId);
    }

    // strangly more expensive:
    function bridgeNativeL1Forward2(
        bytes8 transactionId,
        address hopBridge,
        bytes calldata data
    ) external payable {
        (bool success, ) = hopBridge.call{ value: msg.value }(data);
        if (!success) {
            revert();
        }

        emit LiFiTransactionId(transactionId);
    }

    // TODO: ERC20, token+amount, precompiled calldata for hop, transferId log

    // min
    // native, min params, transferId log
    function bridgeNativeL1Min(
        bytes8 transactionId,
        address receiver,
        uint256 destinationChainId,
        uint256 destinationAmountOutMin,
        address hopBridge,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    ) external payable {
        IHopBridge(hopBridge).sendToL2{ value: msg.value }(
            destinationChainId,
            receiver,
            msg.value,
            destinationAmountOutMin,
            deadline,
            relayer,
            relayerFee
        );

        emit LiFiTransactionId(transactionId);
    }

    // TODO: ERC20, min params, transferId log

    // native, packed data, transferId log
    function bridgeNativeL1Packed() external payable {
        IHopBridge(address(bytes20(msg.data[52:72]))).sendToL2{
            value: msg.value
        }(
            uint256(uint32(bytes4(msg.data[32:36]))),
            address(bytes20(msg.data[12:32])),
            msg.value,
            uint256(uint128(bytes16(msg.data[36:52]))),
            block.timestamp + 7 * 24 * 60 * 60,
            address(bytes20(msg.data[72:92])),
            uint256(uint128(bytes16(msg.data[92:108])))
        );

        emit LiFiTransactionId(bytes8(msg.data[4:12]));
    }

    function bridgeNativeL1Struct(HopData calldata hopData) external payable {
        IHopBridge(address(hopData.hopBridge)).sendToL2{ value: msg.value }(
            uint256(uint32(hopData.destinationChainId)),
            address(hopData.receiver),
            msg.value,
            uint256(uint128(hopData.amountOutMinNative)),
            block.timestamp + 7 * 24 * 60 * 60,
            address(hopData.relayer),
            uint256(uint128(hopData.relayerFee))
        );

        emit LiFiTransactionId(bytes8(hopData.transactionId));
    }

    // native, packed data, transferId log
    function bridgeNativeL1PackedYul() external payable {
        assembly {
            // Prepare calldata for sendToL2
            mstore(0, 0x5c6bc100) // sendToL2 function selector
            mstore(4, and(calldataload(32), 0xFFFFFFFF))
            mstore(
                8,
                and(
                    calldataload(12),
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000
                )
            )
            mstore(28, callvalue())
            mstore(
                44,
                and(calldataload(36), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            )
            mstore(60, add(timestamp(), 604800))
            mstore(
                68,
                and(
                    calldataload(72),
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000
                )
            )
            mstore(
                88,
                and(calldataload(92), 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            )

            // Perform sendToL2
            let success := call(
                gas(),
                and(
                    calldataload(52),
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000
                ),
                callvalue(),
                0,
                104,
                0,
                0
            )
            if iszero(success) {
                revert(0, 0)
            }

            // Emit LiFiTransactionId event
            log1(0, 8, and(calldataload(4), 0xFFFFFFFFFFFFFFFF))
        }
    }

    fallback() external payable {
        uint _func = uint8(bytes1(msg.data[0:1]));

        if (_func == 1) {
            IHopBridge(address(bytes20(msg.data[49:69]))).sendToL2{
                value: msg.value
            }(
                uint256(uint32(bytes4(msg.data[29:33]))),
                address(bytes20(msg.data[9:29])),
                msg.value,
                uint256(uint128(bytes16(msg.data[33:49]))),
                block.timestamp + 7 * 24 * 60 * 60,
                address(bytes20(msg.data[69:89])),
                uint256(uint128(bytes16(msg.data[89:105])))
            );

            emit LiFiTransactionId(bytes8(msg.data[1:9]));
        }
    }

    // TODO: ERC20, packed data, transferId log
}
