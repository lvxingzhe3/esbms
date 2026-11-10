import 'dart:async';

import 'package:bms_app/generated/l10n.dart';
import 'package:bms_app/ui/theme/theme.dart';
import 'package:bms_app/widgets/customWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
class ScanResultTile extends StatefulWidget {
  const ScanResultTile(
      {Key? key, required this.device, this.onTap, this.onStop,this.modify})
      : super(key: key);

  final BluetoothDevice device;
  final VoidCallback? onTap;
  final VoidCallback? onStop;
  final VoidCallback? modify;

  @override
  State<ScanResultTile> createState() => _ScanResultTileState();
}

class _ScanResultTileState extends State<ScanResultTile> {
  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;

  late StreamSubscription<BluetoothConnectionState>
      _connectionStateSubscription;

  @override
  void initState() {
    super.initState();

    _connectionStateSubscription =
        widget.device.connectionState.listen((state) {
      _connectionState = state;
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _connectionStateSubscription.cancel();
    super.dispose();
  }

  bool get isConnected {
    return _connectionState == BluetoothConnectionState.connected;
  }

  Widget _buildTitle(BuildContext context) {
    if (widget.device.platformName.isNotEmpty) {
      return GestureDetector(
            child: customText(
              style: TextStyles.textStyle14,
              widget.device.platformName,
              overflow: TextOverflow.ellipsis,
            ),
            onLongPress: isConnected ?widget.modify:null,
        );
    } else {
      return customText(style: TextStyles.textStyle14,widget.device.remoteId.toString());
    }
  }

  Widget _buildConnectButton(BuildContext context) {
    return ElevatedButton(
      child: isConnected
          ? Text(S.of(context).disconnect)
          : Text(S.of(context).connect),
      style: ElevatedButton.styleFrom(
        backgroundColor: isConnected ? AppColor.error : Colors.blue,
        foregroundColor: Colors.white,
      ),
      onPressed: isConnected ? widget.onStop : connectDevice,
    );
  }

  void connectDevice ()async 
  {
    widget.onTap?.call();

  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: _buildTitle(context),
      trailing: _buildConnectButton(context),
    );
  }
}
