pragma solidity 0.8.17;

import { IHopBridge } from "../Interfaces/IHopBridge.sol";
import { ILiFi } from "../Interfaces/ILiFi.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Hop Facet (Optimized for Rollups)
/// @author LI.FI (https://li.fi)
/// @notice Provides functionality for bridging through Hop
contract HopDirect is ILiFi {
    /// External Methods ///

    event LiFiTransactionId(
        bytes8 transactionId
    );

    // for L1
    // precompiled
    // native, precompiled calldata for hop, transferId log
    function bridgeNativeL1Forward(
        bytes8 transactionId,
        address hopBridge,
        bytes calldata data
    ) external payable {
        (bool success, ) = hopBridge.call{ value: msg.value }(
            bytes.concat(
                IHopBridge.sendToL2.selector,
                data
            )
        );
        if (!success) {
            revert();
        }

        emit LiFiTransactionId(
            transactionId
        );
    }

    // strangly more expensive:
    function bridgeNativeL1Forward2(
        bytes8 transactionId,
        address hopBridge,
        bytes calldata data
    ) external payable {
        (bool success, ) = hopBridge.call{ value: msg.value }(
            data
        );
        if (!success) {
            revert();
        }

        emit LiFiTransactionId(
            transactionId
        );
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

        emit LiFiTransactionId(
            transactionId
        );
    }
    // TODO: ERC20, min params, transferId log

    // native, packed data, transferId log
    function bridgeNativeL1Packed(
    ) external payable {
        IHopBridge(address(bytes20(msg.data[52:72]))).sendToL2{ value: msg.value }(
            uint256(uint32(bytes4(msg.data[32:36]))),
            address(bytes20(msg.data[12:32])),
            msg.value,
            uint256(uint128(bytes16(msg.data[36:52]))),
            block.timestamp + 7 * 24 * 60 * 60,
            address(bytes20(msg.data[72:92])),
            uint256(uint128(bytes16(msg.data[92:108])))
        );

        emit LiFiTransactionId(
            bytes8(msg.data[4:12])
        );
    }

    // TODO: ERC20, packed data, transferId log
}
