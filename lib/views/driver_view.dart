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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = DriverController(driverUser: widget.driverUser);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _ticketInputController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.detached ||
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
    final success = await _controller.toggleOnlineStatus();
    if (!success && mounted) {
      final msg = _controller.gpsErrorMessage ??
          'GPS location is required to go online. Please enable GPS in device settings.';
      _showGpsRequiredDialog(msg);
    }
  }

  void _showGpsRequiredDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.location_off_rounded, color: Color(0xFFDC2626), size: 22),
            SizedBox(width: 8),
            Text(
              'GPS Required',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(fontSize: 13, color: Color(0xFF3F3F46)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF18181B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('OK'),
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
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: 68,
            titleSpacing: 16,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: const Color(0xFFF1F5F9), height: 1),
            ),
            title: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.directions_bus_rounded,
                      color: Color(0xFF047857),
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'PILOT',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'IIT Ropar Transit',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
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
                // Assigned Service Role Banner (Fixed strictly by driver email)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _controller.isBusMode
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _controller.isBusMode
                          ? const Color(0xFFBFDBFE)
                          : const Color(0xFFA7F3D0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: _controller.isBusMode
                              ? const Color(0xFFDBEAFE)
                              : const Color(0xFFD1FAE5),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _controller.isBusMode
                              ? Icons.directions_bus_rounded
                              : Icons.electric_rickshaw_rounded,
                          color: _controller.isBusMode
                              ? const Color(0xFF1D4ED8)
                              : const Color(0xFF047857),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _controller.isBusMode
                                  ? 'City Bus Transit Service'
                                  : 'EV Cart Campus Transit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _controller.isBusMode
                                    ? const Color(0xFF1E3A8A)
                                    : const Color(0xFF064E3B),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              _controller.isBusMode
                                  ? 'Role bound to ${widget.driverUser.email}'
                                  : 'Role bound to ${widget.driverUser.email}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _controller.isBusMode
                                    ? const Color(0xFF3B82F6)
                                    : const Color(0xFF059669),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _controller.isBusMode
                                ? const Color(0xFF93C5FD)
                                : const Color(0xFF86EFAC),
                          ),
                        ),
                        child: Text(
                          _controller.isBusMode ? 'BUS MODE' : 'EV CART',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: _controller.isBusMode
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Active Panel Body (EV Cart or City Bus strictly based on email role)
                if (_controller.driverMode == 'cart')
                  _buildCartPanel()
                else
                  _buildBusPanel(),
              ],
            ),
          ),
        );
      },
    );
  }

  // Long rectangular button: Green when Online (active) and Red when Offline (inactive)
  Widget _buildOnlineDutyButton() {
    final isOnline = _controller.isOnline;
    final color = isOnline ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _toggleOnline,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
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
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              isOnline
                  ? 'ONLINE • VEHICLE ACTIVE'
                  : 'OFFLINE • VEHICLE INACTIVE',
              style: const TextStyle(
                fontSize: 13,
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
              color: const Color(0xFFFAFAFA),
              border: Border.all(color: const Color(0xFFE4E4E7)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text(
                'No active ride requests',
                style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFE4E4E7)),
        borderRadius: BorderRadius.circular(12),
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
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  req.time,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFFA1A1AA),
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
              side: const BorderSide(color: Color(0xFFFCA5A5)),
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
    Color buttonColor = const Color(0xFF2563EB);

    if (ride.status == 'arriving') {
      actionLabel = 'Start Trip (Passenger Onboard)';
      actionIcon = Icons.play_arrow_rounded;
      buttonColor = const Color(0xFF059669);
    } else if (ride.status == 'in_progress') {
      actionLabel = 'Complete Ride (Arrived at Drop)';
      actionIcon = Icons.check_circle_rounded;
      buttonColor = const Color(0xFF16A34A);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFF93C5FD)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1D4ED8),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ACTIVE TRIP · ${ride.status.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 16,
                  color: Color(0xFF64748B),
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
          const SizedBox(height: 8),
          Text(
            'Trip: ${ride.pickup} ➔ ${ride.drop}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Passenger: ${ride.userName} (${ride.id})',
            style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
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
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFFF0FDF4) : const Color(0xFFFAFAFA),
        border: Border.all(
          color: isLive ? const Color(0xFF86EFAC) : const Color(0xFFE4E4E7),
        ),
        borderRadius: BorderRadius.circular(14),
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
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isLive
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFA1A1AA),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isLive ? 'GPS TELEMETRY: ACTIVE' : 'GPS TELEMETRY: STANDBY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isLive
                          ? const Color(0xFF15803D)
                          : const Color(0xFF71717A),
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
                    'Device Battery: ${_controller.battery}%',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF52525B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Current Zone: ${_controller.currentWaypointName}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Coordinates: ${_controller.latitude.toStringAsFixed(6)}° N, ${_controller.longitude.toStringAsFixed(6)}° E',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3F3F46),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Source: ${hasRealGps ? 'Phone GPS Sensor (Live Hardware)' : 'Initializing GPS...'} · Bearing: ${_controller.heading.toInt()}°',
            style: const TextStyle(fontSize: 10, color: Color(0xFF71717A)),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isLive ? const Color(0xFFDCFCE7) : const Color(0xFFF4F4F5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isLive ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  size: 14,
                  color: isLive
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF71717A),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    isLive
                        ? 'Broadcasting live 6-digit coordinates to "locations"'
                        : 'Offline · Toggle online duty button above to broadcast',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isLive
                          ? const Color(0xFF15803D)
                          : const Color(0xFF71717A),
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

  // ================= 2. CITY BUS DRIVER PANEL (MINIMAL) =================
  Widget _buildBusPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Online / Offline Duty Switch
        _buildOnlineDutyButton(),
        const SizedBox(height: 10),

        // 2. Compact GPS Status Pill
        _buildCompactGpsBar(),
        const SizedBox(height: 14),

        // 3. Today's Bus Route (Today Only)
        _buildTodayBusRouteCard(),
        const SizedBox(height: 14),

        // 4. Current Stop Console (Clean & Direct)
        _buildMinimalStopConsole(),
        const SizedBox(height: 14),

        // 5. Scan Ticket Section (Clean)
        _buildMinimalScanSection(),
        const SizedBox(height: 14),

        // 6. Occupancy & Manifest (Clean & Compact)
        _buildMinimalOccupancySection(),
      ],
    );
  }

  /// Compact single-line GPS status bar.
  Widget _buildCompactGpsBar() {
    final isLive = _controller.isBroadcasting;
    final hasRealGps = _controller.hasRealGpsFix;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isLive ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLive ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isLive
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF94A3B8),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                isLive
                    ? (hasRealGps
                          ? 'GPS Active · Broadcasting'
                          : 'GPS Initializing...')
                    : 'GPS Standby · Offline',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isLive
                      ? const Color(0xFF15803D)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          Text(
            'Battery: ${_controller.battery}%',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  /// Today's route card strictly showing today's trips.
  Widget _buildTodayBusRouteCard() {
    final buses = _controller.availableBuses;
    final selectedId = _controller.selectedBusId;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TODAY'S ROUTE",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                DriverController.formattedTodayDate,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2563EB),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (buses.isEmpty)
            const Text(
              'No trips scheduled for today',
              style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
            )
          else
            DropdownButtonHideUnderline(
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
                onChanged: (val) {
                  if (val != null) _controller.setSelectedBusId(val);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Minimal stop console: clear stop name, one-tap next stop button, and simple exit/board counts.
  Widget _buildMinimalStopConsole() {
    final stops = _controller.currentBusStops;
    final currentStop = _controller.currentReachedStop;
    final dropOffs = _controller.currentStopDropOffs;
    final pickups = _controller.currentStopPickups;
    final currentIndex = _controller.currentStopIndex;
    final hasNext = _controller.hasNextStop;
    final isFinal = _controller.isFinalStop;
    final nextName = _controller.nextStopName;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isFinal
                    ? 'FINAL DESTINATION'
                    : 'STOP ${currentIndex + 1} OF ${stops.length}',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: isFinal
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF64748B),
                ),
              ),
              if (stops.isNotEmpty)
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: (currentIndex >= 0 && currentIndex < stops.length)
                        ? currentIndex
                        : (stops.isNotEmpty ? 0 : null),
                    icon: const Icon(
                      Icons.arrow_drop_down,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                    items: stops.asMap().entries.map((e) {
                      return DropdownMenuItem<int>(
                        value: e.key,
                        child: Text(e.value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) _controller.setReachedStopIndex(val);
                    },
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

          // Solid Next Stop button
          SizedBox(
            width: double.infinity,
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
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                hasNext ? 'Next Stop: $nextName ➔' : 'Restart Route at Stop 1',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          if (_controller.hasPreviousStop) ...[
            const SizedBox(height: 4),
            Center(
              child: TextButton(
                onPressed: () => _controller.previousStop(),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  foregroundColor: const Color(0xFF94A3B8),
                ),
                child: Text(
                  '← Previous: ${_controller.previousStopName}',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Compact activity pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
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
                      '${dropOffs.length} Exiting',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                Container(height: 16, width: 1, color: const Color(0xFFCBD5E1)),
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
                      '${pickups.length} Boarding',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          if (dropOffs.isNotEmpty || pickups.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...dropOffs.map(
              (t) => _buildStopPassengerItem(ticket: t, isDropOff: true),
            ),
            ...pickups.map(
              (t) => _buildStopPassengerItem(ticket: t, isDropOff: false),
            ),
          ],
        ],
      ),
    );
  }

  /// Minimal stop passenger item with clean row formatting.
  Widget _buildStopPassengerItem({
    required BusTicket ticket,
    required bool isDropOff,
  }) {
    final isConfirmed = ticket.isConfirmed;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                isDropOff
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                size: 13,
                color: isDropOff
                    ? const Color(0xFFDC2626)
                    : const Color(0xFF059669),
              ),
              const SizedBox(width: 6),
              Text(
                ticket.passengerName.isNotEmpty &&
                        ticket.passengerName != 'Student'
                    ? '${ticket.passengerName} (${ticket.id})'
                    : ticket.id,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isConfirmed
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isConfirmed ? 'BOARDED' : 'UNSCANNED',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: isConfirmed
                    ? const Color(0xFF15803D)
                    : const Color(0xFFB45309),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Minimal scan section: clear button and compact ticket ID input.
  Widget _buildMinimalScanSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _openCameraScanner,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: const Text(
                'Scan QR Ticket',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          _buildScanResultBox(),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ticketInputController,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Or enter Ticket ID (TKT-...)',
                    hintStyle: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF059669)),
                    ),
                  ),
                  onSubmitted: (_) => _onVerifyTicket(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 38,
                child: OutlinedButton(
                  onPressed: () => _onVerifyTicket(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Check-In',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Minimal occupancy section: clean progress bar and passenger list.
  Widget _buildMinimalOccupancySection() {
    final tickets = _controller.currentBusTickets;
    final onboarded = _controller.onboardedCount;
    final total = _controller.totalSeats;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'OCCUPANCY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Color(0xFF64748B),
                ),
              ),
              Text(
                '$onboarded / $total seats',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: total > 0 ? (onboarded / total).clamp(0.0, 1.0) : 0.0,
              minHeight: 4,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF059669),
              ),
            ),
          ),

          if (tickets.where((t) => t.isConfirmed).isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(color: Color(0xFFF1F5F9), height: 1),
            const SizedBox(height: 8),
            Text(
              'Boarded Passengers (${tickets.where((t) => t.isConfirmed).length}):',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            ...tickets.where((t) => t.isConfirmed).map(
              (t) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t.passengerName.isNotEmpty &&
                              t.passengerName != 'Student'
                          ? '${t.passengerName} (${t.id})'
                          : t.id,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    Text(
                      '${t.pickup} → ${t.drop}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF64748B),
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

  Widget _buildScanResultBox() {
    Color bgColor = const Color(0xFFFAFAFA);
    Color borderColor = const Color(0xFFE4E4E7);
    Color textColor = const Color(0xFF71717A);

    if (_controller.scanResultType == 'success') {
      bgColor = const Color(0xFFECFDF5);
      borderColor = const Color(0xFFA7F3D0);
      textColor = const Color(0xFF047857);
    } else if (_controller.scanResultType == 'warning') {
      bgColor = const Color(0xFFFFFBEB);
      borderColor = const Color(0xFFFDE68A);
      textColor = const Color(0xFFB45309);
    } else if (_controller.scanResultType == 'error') {
      bgColor = const Color(0xFFFFF1F2);
      borderColor = const Color(0xFFFECDD3);
      textColor = const Color(0xFFBE123C);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
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
    );
  }
}
