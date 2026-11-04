import 'package:flutter/material.dart';
import 'package:sarthi_pilot/controllers/driver_controller.dart';
import 'package:sarthi_pilot/models/bus_ticket.dart';
import 'package:sarthi_pilot/models/driver_user.dart';
import 'package:sarthi_pilot/models/ride_request.dart';
import 'package:sarthi_pilot/views/driver_profile_view.dart';
import 'package:sarthi_pilot/views/ride_history_view.dart';
import 'package:sarthi_pilot/views/qr_scanner_view.dart';

/// Driver dashboard view in MVC architecture.
class DriverView extends StatefulWidget {
  const DriverView({
    super.key,
    this.driverUser = const DriverUser(
      uid: '4A8F10CD',
      email: 'driver@iitrpr.ac.in',
      name: 'DRIVER',
      driverId: '4A8F10CD',
    ),
  });

  final DriverUser driverUser;

  @override
  State<DriverView> createState() => _DriverViewState();
}

class _DriverViewState extends State<DriverView> with WidgetsBindingObserver {
  late final DriverController _controller;
  final TextEditingController _ticketInputController = TextEditingController();
  bool _lastOnlineState = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = DriverController(driverUser: widget.driverUser);
    _controller.addListener(_onDriverStateChanged);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onDriverStateChanged);
    _controller.dispose();
    _ticketInputController.dispose();
    super.dispose();
  }

  void _onDriverStateChanged() {
    // If the vehicle was online and transitioned to offline due to location being turned off
    if (_lastOnlineState && !_controller.isOnline && _controller.gpsErrorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.location_off_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _controller.gpsErrorMessage!,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            action: SnackBarAction(
              label: 'Settings',
              textColor: Colors.white,
              onPressed: () => _controller.openLocationSettings(),
            ),
          ),
        );
      }
    }
    _lastOnlineState = _controller.isOnline;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Re-verify location status immediately when driver returns to the app
      if (_controller.isOnline) {
        _controller.checkLocationEnabled().then((isEnabled) {
          if (!isEnabled) {
            _controller.handleLocationDisabledWhileOnline();
          }
        });
      }
    } else if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused) {
      // Set vehicle offline in Firebase when app closes or minimizes
      _controller.setOfflineImmediate();
    }
  }

  // Shows a minimal floating toast notification
  void _showToast(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF18181B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _toggleOnline() async {
    // If going online, verify device location service is turned ON
    if (!_controller.isOnline) {
      final isGpsOn = await _controller.checkLocationEnabled();
      if (!isGpsOn) {
        if (!mounted) return;
        _showLocationSettingsDialog(
          'Location services are turned OFF. Please turn on Location in settings to go online.',
        );
        return;
      }
    }

    final success = await _controller.toggleOnlineStatus();
    if (!success && mounted) {
      final msg = _controller.gpsErrorMessage ??
          'GPS location is required to go online. Please enable Location in phone settings.';
      _showLocationSettingsDialog(msg);
    }
  }

  void _showLocationSettingsDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_off_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text(
              'Location Required',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, color: Color(0xFF3F3F46)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              _controller.openLocationSettings();
            },
            icon: const Icon(Icons.settings_rounded, size: 16),
            label: const Text('Open Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onAcceptRequest(dynamic id) {
    _controller.acceptRequest(id);
  }

  void _onRejectRequest(dynamic id) {
    _controller.rejectRequest(id);
  }

  void _onSetOccupancy(String status) {
    _controller.setOccupancy(status);
  }

  void _onVerifyTicket([String? codeToTest]) async {
    final code = codeToTest ?? _ticketInputController.text;
    if (code.trim().isEmpty) return;

    await _controller.verifyTicket(code);
    _ticketInputController.clear();
  }

  void _openCameraScanner() {
    Navigator.of(context).push(
      MaterialPageRoute<String>(
        builder: (_) => QrScannerView(
          currentBusInfo: _controller.currentRouteTitle,
          getFeedbackMessage: () => _controller.scanResultText,
          onScanned: (code) async {
            return await _controller.verifyTicket(code);
          },
          continuous: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF4FCF9),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF4FCF9),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 68,
            titleSpacing: 16,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: const Color(0xFFE5E7EB), height: 1),
            ),
            title: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.directions_bus_rounded,
                      color: Color(0xFF059669),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text(
                        'Sarthi Pilot',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                          color: Color(0xFF1F2937),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 1),
                      Text(
                        'IIT Ropar Transit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6B7280),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Ticket / History button with badge
              InkWell(
                key: const ValueKey('app_bar_history_button'),
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RideHistoryView(
                        driverUser: widget.driverUser,
                        controller: _controller,
                      ),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 8,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        size: 28,
                        color: Color(0xFF059669),
                      ),
                      Positioned(
                        top: -2,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 1,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xFF059669),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '${_controller.rideHistory.length}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Profile button (Account circle icon)
              IconButton(
                key: const ValueKey('app_bar_profile_button'),
                icon: const Icon(
                  Icons.account_circle_outlined,
                  size: 30,
                  color: Color(0xFF334155),
                ),
                tooltip: 'Driver Profile',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DriverProfileView(
                        driverUser: widget.driverUser,
                        controller: _controller,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // If EV Cart mode: display cart role banner and cart panel
                if (_controller.driverMode == 'cart') ...[
                  _buildCartRoleBanner(),
                  const SizedBox(height: 16),
                  _buildCartPanel(),
                ] else ...[
                  // City Bus Mode: starts directly at top with Today's bus schedule
                  _buildBusPanel(),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartRoleBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Center(
              child: Icon(
                Icons.electric_rickshaw_rounded,
                color: Color(0xFF059669),
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EV Cart Campus Transit',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.driverUser.email,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: const Text(
              'CART PILOT',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: Color(0xFF065F46),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Long rectangular button: Emerald when Online (active) and Red when Offline (inactive)
  Widget _buildOnlineDutyButton() {
    final isOnline = _controller.isOnline;
    final color = isOnline ? const Color(0xFF059669) : const Color(0xFFDC2626);

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _toggleOnline,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOnline
                  ? Icons.check_circle_rounded
                  : Icons.power_settings_new_rounded,
              size: 18,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Text(
              isOnline
                  ? 'ONLINE • VEHICLE ACTIVE'
                  : 'OFFLINE • VEHICLE INACTIVE',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= 1. EV CART DISPATCH PANEL =================
  Widget _buildCartPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cart Active / Inactive Toggle (Scoped to EV Cart Tab)
        _buildOnlineDutyButton(),
        const SizedBox(height: 16),

        // Cancellation alert if passenger cancelled
        if (_controller.cancellationNotice != null) _buildCancellationBanner(),

        // Active in-transit ride banner (if driver accepted a ride)
        _buildActiveRideCard(),

        // Live GPS Telemetry card
        _buildTelemetryCard(),

        const SizedBox(height: 16),

        // Pending Student Requests Section
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pending Student Requests',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF52525B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_controller.requests.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE5E7EB)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Center(
              child: Text(
                'No active ride requests',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ),
          )
        else
          ..._controller.requests.map(_buildRequestItem),

        const SizedBox(height: 18),

        // Capacity Status Section
        const Text(
          'Capacity Status',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF52525B),
          ),
        ),
        const SizedBox(height: 8),

        Row(
          children: [
            Expanded(child: _occupancyButton('Empty')),
            const SizedBox(width: 8),
            Expanded(child: _occupancyButton('Filling')),
            const SizedBox(width: 8),
            Expanded(child: _occupancyButton('Full')),
          ],
        ),
      ],
    );
  }

  Widget _buildRequestItem(RideRequest req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${req.from} → ${req.to}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  req.time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () => _onRejectRequest(req.id),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFFECDD3)),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text(
              'Reject',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: () => _onAcceptRequest(req.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              visualDensity: VisualDensity.compact,
            ),
            child: const Text(
              'Accept',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _occupancyButton(String status) {
    final isSelected = _controller.occupancy == status;

    Color bgColor = const Color(0xFFFAFAFA);
    Color borderColor = const Color(0xFFE4E4E7);
    Color textColor = const Color(0xFF52525B);

    if (isSelected) {
      if (status == 'Empty') {
        bgColor = const Color(0xFFECFDF5);
        borderColor = const Color(0xFF10B981);
        textColor = const Color(0xFF047857);
      } else if (status == 'Filling') {
        bgColor = const Color(0xFFFFFBEB);
        borderColor = const Color(0xFFF59E0B);
        textColor = const Color(0xFFB45309);
      } else {
        bgColor = const Color(0xFFFFF1F2);
        borderColor = const Color(0xFFF43F5E);
        textColor = const Color(0xFFBE123C);
      }
    }

    return InkWell(
      onTap: () => _onSetOccupancy(status),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: isSelected ? 1.2 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildCancellationBanner() {
    final notice = _controller.cancellationNotice;
    if (notice == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ride Cancelled by Passenger',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Color(0xFF991B1B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  notice,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _controller.clearCancellationNotice(),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 16, color: Color(0xFF991B1B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveRideCard() {
    final ride = _controller.activeRide;
    if (ride == null) return const SizedBox.shrink();

    String actionLabel = 'Mark Arrived at Pickup';
    IconData actionIcon = Icons.location_on_rounded;
    Color buttonColor = const Color(0xFF059669);

    if (ride.status == 'arriving') {
      actionLabel = 'Start Trip (Passenger Onboard)';
      actionIcon = Icons.play_arrow_rounded;
      buttonColor = const Color(0xFF059669);
    } else if (ride.status == 'in_progress') {
      actionLabel = 'Complete Ride (Arrived at Drop)';
      actionIcon = Icons.check_circle_rounded;
      buttonColor = const Color(0xFF059669);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  'ACTIVE TRIP · ${ride.status.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    color: Color(0xFF065F46),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
                onPressed: () {
                  _controller.cancelActiveRide();
                },
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${ride.pickup} ➔ ${ride.drop}',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Passenger: ${ride.userName} (${ride.id})',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              onPressed: () {
                _controller.advanceRideStatus();
              },
              icon: Icon(actionIcon, size: 18),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryCard() {
    final isLive = _controller.isBroadcasting;
    final hasRealGps = _controller.hasRealGpsFix;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isLive
                          ? const Color(0xFF059669)
                          : const Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isLive ? 'GPS TELEMETRY: ACTIVE' : 'GPS TELEMETRY: STANDBY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.6,
                      color: isLive
                          ? const Color(0xFF065F46)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    _controller.isCharging
                        ? Icons.battery_charging_full_rounded
                        : Icons.battery_std_rounded,
                    size: 14,
                    color: _controller.battery > 20
                        ? const Color(0xFF059669)
                        : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Battery: ${_controller.battery}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Current Zone: ${_controller.currentWaypointName}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${_controller.latitude.toStringAsFixed(6)}° N, ${_controller.longitude.toStringAsFixed(6)}° E',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Source: ${hasRealGps ? 'Phone GPS Sensor (Live Hardware)' : 'Initializing GPS...'} · Bearing: ${_controller.heading.toInt()}°',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Row(
              children: [
                Icon(
                  isLive ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  size: 15,
                  color: isLive
                      ? const Color(0xFF059669)
                      : const Color(0xFF94A3B8),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isLive
                        ? 'Broadcasting live coordinates to "locations"'
                        : 'Offline · Toggle online duty button above to broadcast',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isLive
                          ? const Color(0xFF065F46)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 2. CITY BUS DRIVER PANEL (STREAMLINED WORKFLOW) =================
  Widget _buildBusPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. At the top: Today's bus schedule
        _buildTodayBusRouteCard(),
        const SizedBox(height: 14),

        // 2. Option to "Start Trip" / "End Trip"
        _buildTripActionBar(),

        // 3. Then ONLY (when trip is started):
        if (_controller.isBusTripActive) ...[
          const SizedBox(height: 14),

          // Ticket System (minimal UI card)
          _buildMinimalTicketCard(),
          const SizedBox(height: 14),

          // Stops UI card
          _buildStopsConsoleCard(),
          const SizedBox(height: 14),

          // List of students according to reached stops
          _buildReachedStopStudentsCard(),
        ],
      ],
    );
  }

  /// 1. At the top: Today's bus schedule with route selector.
  Widget _buildTodayBusRouteCard() {
    final buses = _controller.availableBuses;
    final selectedId = _controller.selectedBusId;
    final isTripActive = _controller.isBusTripActive;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.directions_bus_rounded,
                          color: Color(0xFF059669),
                          size: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        "TODAY'S BUS SCHEDULE",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Text(
                  DriverController.formattedTodayDate,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF065F46),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (buses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No upcoming trips scheduled for today',
                style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: buses.any((b) => b['id'] == selectedId)
                      ? selectedId
                      : buses.first['id'] as String?,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: Color(0xFF64748B),
                  ),
                  items: buses.map((bus) {
                    final route = bus['route'] as String? ?? 'Bus Route';
                    final reg = bus['registrationNumber'] as String? ?? '';
                    final dep = bus['departureTime'] as String? ?? '';
                    return DropdownMenuItem<String>(
                      value: bus['id'] as String?,
                      child: Text(
                        dep.isNotEmpty
                            ? '$dep · $route ($reg)'
                            : '$route ($reg)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: isTripActive
                      ? null
                      : (val) {
                          if (val != null) _controller.setSelectedBusId(val);
                        },
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// 2. Trip Action Area: "Start Trip" / "End Trip".
  Widget _buildTripActionBar() {
    final isActive = _controller.isBusTripActive;

    if (!isActive) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _onStartTrip,
              icon: const Icon(Icons.play_arrow_rounded, size: 24),
              label: const Text(
                'Start Trip Now',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: Color(0xFF64748B),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Trip is in standby. Tap "Start Trip Now" to activate passenger scanning, stop navigation, and student manifest.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Active Trip Banner with End Trip action
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRIP ACTIVE · LIVE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: Color(0xFF065F46),
                    ),
                  ),
                  Text(
                    'Broadcasting real-time location',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF047857),
                    ),
                  ),
                ],
              ),
            ],
          ),
          OutlinedButton.icon(
            onPressed: _confirmEndTrip,
            icon: const Icon(Icons.stop_circle_outlined, size: 16),
            label: const Text('End Trip'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFDC2626),
              side: const BorderSide(color: Color(0xFFFECDD3)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  void _onStartTrip() async {
    final success = await _controller.startBusTrip();
    if (!success && mounted) {
      final msg = _controller.gpsErrorMessage ??
          'GPS location is required to start the trip. Please enable Location in settings.';
      _showLocationSettingsDialog(msg);
    }
  }

  void _confirmEndTrip() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.stop_circle_outlined, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text('End Bus Trip?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to end this trip? The vehicle will be taken offline.',
          style: TextStyle(fontSize: 13, color: Color(0xFF3F3F46)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('End Trip'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _controller.endBusTrip();
    }
  }

  /// 3. Minimal Ticket System Card (Ticket number, OK button, QR scanner option).
  Widget _buildMinimalTicketCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Ticket Number input field
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: TextField(
                    controller: _ticketInputController,
                    textCapitalization: TextCapitalization.characters,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.confirmation_number_outlined,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                      hintText: 'Ticket number',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
                      ),
                    ),
                    onSubmitted: (_) => _onVerifyTicket(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // OK button (confirm manual ticket number)
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  onPressed: () => _onVerifyTicket(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // QR scan option button
              SizedBox(
                height: 46,
                width: 46,
                child: Material(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _openCameraScanner,
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 22,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (_controller.scanResultType != 'idle' &&
              _controller.scanResultText.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildScanResultBox(),
          ],
        ],
      ),
    );
  }

  /// 4. Stops Console Card (stop name + dual navigation buttons).
  Widget _buildStopsConsoleCard() {
    final stops = _controller.currentBusStops;
    final currentStop = _controller.currentReachedStop;
    final currentIndex = _controller.currentStopIndex;
    final hasNext = _controller.hasNextStop;
    final isFinal = _controller.isFinalStop;
    final nextName = _controller.nextStopName;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  isFinal
                      ? 'FINAL DESTINATION'
                      : 'STOP ${currentIndex + 1} OF ${stops.length}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isFinal
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (stops.isNotEmpty)
                Flexible(
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isDense: true,
                        isExpanded: true,
                        value: (currentIndex >= 0 && currentIndex < stops.length)
                            ? currentIndex
                            : (stops.isNotEmpty ? 0 : null),
                        icon: const Icon(
                          Icons.arrow_drop_down,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                        items: stops.asMap().entries.map((e) {
                          return DropdownMenuItem<int>(
                            value: e.key,
                            child: Text(
                              '${e.key + 1}. ${e.value}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) _controller.setReachedStopIndex(val);
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            currentStop,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),

          if (hasNext) ...[
            const SizedBox(height: 2),
            Text(
              'Next: $nextName',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],

          const SizedBox(height: 14),

          // Two prominent side-by-side buttons for BOTH Previous Stop and Next Stop
          Row(
            children: [
              // Previous Stop Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _controller.hasPreviousStop
                        ? () => _controller.previousStop()
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF1E293B),
                      disabledForegroundColor: const Color(0xFF94A3B8),
                      side: BorderSide(
                        color: _controller.hasPreviousStop
                            ? const Color(0xFFCBD5E1)
                            : const Color(0xFFE2E8F0),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.arrow_back_rounded, size: 16),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _controller.hasPreviousStop
                                ? 'Prev: ${_controller.previousStopName}'
                                : 'First Stop',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Next Stop Button
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: hasNext
                        ? () => _controller.nextStop()
                        : () => _controller.setReachedStopIndex(0),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: hasNext
                          ? const Color(0xFF059669)
                          : const Color(0xFF475569),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            hasNext ? 'Next: $nextName' : 'Restart Route',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          hasNext
                              ? Icons.arrow_forward_rounded
                              : Icons.replay_rounded,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 5. List of students according to reached stops.
  Widget _buildReachedStopStudentsCard() {
    final currentStop = _controller.currentReachedStop;
    final dropOffs = _controller.currentStopDropOffs;
    final pickups = _controller.currentStopPickups;
    final onboarded = _controller.currentBusOnboardedTickets;
    final otherOnboarded = onboarded.where((t) => !dropOffs.any((d) => d.id == t.id)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'STUDENTS AT THIS STOP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF64748B),
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Text(
                    currentStop,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF065F46),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 1. Boarding Here Section
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Boarding Here (${pickups.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (pickups.isEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 14, bottom: 8),
              child: Text(
                'No students boarding at this stop.',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            )
          else
            ...pickups.map((t) => _buildStopStudentRow(ticket: t, isBoarding: true)),

          const SizedBox(height: 8),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 10),

          // 2. Exiting Here Section
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFFDC2626),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Exiting Here (${dropOffs.length})',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (dropOffs.isEmpty)
            const Padding(
              padding: EdgeInsets.only(left: 14),
              child: Text(
                'No students exiting at this stop.',
                style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
              ),
            )
          else
            ...dropOffs.map((t) => _buildStopStudentRow(ticket: t, isBoarding: false)),

          // 3. Other Onboarded Passengers Section
          if (otherOnboarded.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Other Onboarded Passengers (${otherOnboarded.length})',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...otherOnboarded.map(
              (t) => _buildStopStudentRow(
                ticket: t,
                isBoarding: false,
                isOnboardedList: true,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Minimal row displaying student ticket details for the reached stop with Board / Unboard actions.
  Widget _buildStopStudentRow({
    required BusTicket ticket,
    required bool isBoarding,
    bool isOnboardedList = false,
  }) {
    final isConfirmed = ticket.isConfirmed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isOnboardedList
                ? Icons.airline_seat_recline_normal_rounded
                : (isBoarding ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded),
            size: 14,
            color: isOnboardedList
                ? const Color(0xFF2563EB)
                : (isBoarding ? const Color(0xFF059669) : const Color(0xFFDC2626)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ticket.passengerName.isNotEmpty &&
                          ticket.passengerName != 'Student'
                      ? '${ticket.passengerName} (${ticket.id})'
                      : ticket.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  isOnboardedList
                      ? '${ticket.pickup} ➔ ${ticket.drop}'
                      : (isBoarding
                          ? 'Destination: ${ticket.drop}'
                          : 'Boarded at: ${ticket.pickup}'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Action Button: Completed, Unboard (if boarded), or Board (if valid/unscanned)
          if (ticket.isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFCBD5E1)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded, size: 10, color: Color(0xFF059669)),
                  SizedBox(width: 3),
                  Text(
                    'COMPLETED',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF059669),
                    ),
                  ),
                ],
              ),
            )
          else if (isConfirmed)
            InkWell(
              onTap: () async {
                await _controller.unboardTicket(ticket.id);
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFFECDD3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.person_remove_rounded,
                      size: 11,
                      color: Color(0xFFDC2626),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Unboard',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (isBoarding)
            InkWell(
              onTap: () async {
                await _controller.verifyTicket(ticket.id);
              },
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 11,
                      color: Color(0xFF059669),
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Board',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Text(
                'UNSCANNED',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildScanResultBox() {
    Color bgColor = const Color(0xFFF8FAFC);
    Color borderColor = const Color(0xFFE2E8F0);
    Color textColor = const Color(0xFF64748B);

    if (_controller.scanResultType == 'success') {
      bgColor = const Color(0xFFECFDF5);
      borderColor = const Color(0xFFA7F3D0);
      textColor = const Color(0xFF065F46);
    } else if (_controller.scanResultType == 'warning') {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      textColor = const Color(0xFFB45309);
    } else if (_controller.scanResultType == 'error') {
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECDD3);
      textColor = const Color(0xFF991B1B);
    }

    final lastTid = _controller.lastScannedTicketId;
    final lastTicket = lastTid != null && lastTid.isNotEmpty
        ? _controller.currentBusTickets.cast<BusTicket?>().firstWhere(
              (t) => t?.id.toUpperCase() == lastTid.toUpperCase(),
              orElse: () => null,
            )
        : null;
    final showUnboardBtn = lastTicket != null && lastTicket.isBoarded;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            _controller.scanResultText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: _controller.scanResultType == 'idle'
                  ? FontWeight.w400
                  : FontWeight.w600,
              color: textColor,
            ),
          ),
          if (showUnboardBtn) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                await _controller.unboardTicket(lastTid);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _controller.scanResultType == 'warning'
                        ? const Color(0xFFFDE68A)
                        : const Color(0xFFA7F3D0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.person_remove_rounded,
                      size: 13,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Manual Unboard ($lastTid)',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
