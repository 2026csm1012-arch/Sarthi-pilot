import 'package:flutter/material.dart';
import 'package:sarthi_pilot/controllers/driver_controller.dart';
import 'package:sarthi_pilot/models/driver_user.dart';
import 'package:sarthi_pilot/models/ride_request.dart';
import 'package:sarthi_pilot/views/driver_profile_view.dart';
import 'package:sarthi_pilot/views/qr_scanner_view.dart';

/// Driver dashboard view in MVC architecture.
class DriverView extends StatefulWidget {
  const DriverView({
    super.key,
    this.driverUser = const DriverUser(
      uid: 'DEMO-DRIVER-01',
      email: 'driver@iitrpr.ac.in',
      name: 'DRIVER',
    ),
  });

  final DriverUser driverUser;

  @override
  State<DriverView> createState() => _DriverViewState();
}

class _DriverViewState extends State<DriverView> {
  late final DriverController _controller;
  final TextEditingController _ticketInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = DriverController(driverUser: widget.driverUser);
  }

  @override
  void dispose() {
    _controller.dispose();
    _ticketInputController.dispose();
    super.dispose();
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

  void _toggleOnline() {
    _controller.toggleOnlineStatus();
    if (_controller.isOnline) {
      _showToast('You are ONLINE: Vehicle is active & visible on campus map.');
    } else {
      _showToast('You are OFFLINE: Vehicle is inactive (off-duty).');
    }
  }

  void _onAcceptRequest(dynamic id) {
    _controller.acceptRequest(id);
    _showToast('Ride accepted! Vehicle is ONLINE & GPS broadcast started.');
  }

  void _onRejectRequest(dynamic id) {
    _controller.rejectRequest(id);
    _showToast('Ride request declined.');
  }

  void _onAddTestRequest() {
    _controller.addTestRequest();
    _showToast('New student hail request received!');
  }

  void _onSetOccupancy(String status) {
    _controller.setOccupancy(status);
    _showToast('Capacity updated: $status');
  }

  void _onVerifyTicket([String? codeToTest]) {
    final code = codeToTest ?? _ticketInputController.text;
    if (code.trim().isEmpty) return;

    _controller.verifyTicket(code);

    if (_controller.scanResultType == 'success') {
      _showToast('Passenger onboarded!');
    }
    _ticketInputController.clear();
  }

  void _openCameraScanner() {
    Navigator.of(context).push(
      MaterialPageRoute<String>(
        builder: (_) => QrScannerView(
          onScanned: (code) async {
            final valid = _controller.verifyTicket(code);
            if (valid) {
              _showToast('Passenger onboarded with ticket $code!');
            }
            return valid;
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
            titleSpacing: 20,
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: const Color(0xFFF4F4F5), height: 1),
            ),
            title: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF059669),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'IIT ROPAR TRANSIT',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: Color(0xFF71717A),
                  ),
                ),
              ],
            ),
            actions: [
              InkWell(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => DriverProfileView(
                        driverUser: widget.driverUser,
                        controller: _controller,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F4F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE4E4E7)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: const Color(0xFF059669),
                        child: Text(
                          widget.driverUser.name.isNotEmpty
                              ? widget.driverUser.name[0].toUpperCase()
                              : 'D',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.driverUser.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF27272A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.electric_rickshaw,
                              size: 11,
                              color: Color(0xFF047857),
                            ),
                            const SizedBox(width: 3),
                            Text(
                              _controller.assignedCartId,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF047857),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF71717A),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Header Section
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'OPERATOR DASHBOARD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: Color(0xFF059669),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Driver & Bus Control',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF18181B),
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Mode Selector: EV Cart Dispatch vs City Bus Scanner
                Row(
                  children: [
                    Expanded(
                      child: _modeButton(
                        title: 'EV Cart Dispatch',
                        isSelected: _controller.driverMode == 'cart',
                        onTap: () => _controller.setDriverMode('cart'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _modeButton(
                        title: 'City Bus Scanner',
                        isSelected: _controller.driverMode == 'bus',
                        onTap: () => _controller.setDriverMode('bus'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Active Panel Body
                if (_controller.driverMode == 'cart') _buildCartPanel() else _buildBusPanel(),
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
              isOnline ? Icons.check_circle_rounded : Icons.power_settings_new_rounded,
              size: 20,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              isOnline ? 'ONLINE • VEHICLE ACTIVE' : 'OFFLINE • VEHICLE INACTIVE',
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

  // Mode button toggle (Cart vs Bus)
  Widget _modeButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFECFDF5) : const Color(0xFFFAFAFA),
          border: Border.all(
            color: isSelected ? const Color(0xFF10B981) : const Color(0xFFE4E4E7),
            width: isSelected ? 1.2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? const Color(0xFF047857) : const Color(0xFF52525B),
          ),
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
        if (_controller.cancellationNotice != null)
          _buildCancellationBanner(),

        // Active in-transit ride banner (if driver accepted a ride)
        _buildActiveRideCard(),

        // Live GPS Telemetry card
        _buildTelemetryCard(),

        // Assigned Vehicle Section
        const Text(
          'Assigned Vehicle',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF52525B),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            border: Border.all(color: const Color(0xFFE4E4E7)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _controller.availableCarts.any((c) => c.id == _controller.selectedCart)
                  ? _controller.selectedCart
                  : (_controller.availableCarts.isNotEmpty
                      ? _controller.availableCarts.first.id
                      : _controller.selectedCart),
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF71717A)),
              style: const TextStyle(fontSize: 12, color: Color(0xFF18181B)),
              items: _controller.availableCarts.isEmpty
                  ? [
                      DropdownMenuItem<String>(
                        value: _controller.selectedCart,
                        child: Text(_controller.selectedCartName),
                      ),
                    ]
                  : _controller.availableCarts.map((cart) {
                      return DropdownMenuItem<String>(
                        value: cart.id,
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: cart.isOnline
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFA1A1AA),
                              ),
                            ),
                            Text(
                              cart.name,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              onChanged: (val) {
                if (val != null) _controller.setSelectedCart(val);
              },
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Pending Student Requests Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Pending Student Requests',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF52525B),
              ),
            ),
            GestureDetector(
              onTap: _onAddTestRequest,
              child: const Text(
                '+ Add Test',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF059669),
                ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
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
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Color(0xFF64748B)),
                onPressed: () {
                  _controller.cancelActiveRide();
                  _showToast('Active ride cleared.');
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
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
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
                _showToast('Ride status updated!');
              },
              icon: Icon(actionIcon, size: 18),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: buttonColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                      color: isLive ? const Color(0xFF16A34A) : const Color(0xFFA1A1AA),
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
                      color: isLive ? const Color(0xFF15803D) : const Color(0xFF71717A),
                    ),
                  ),
                ],
              ),
              Text(
                'Battery: ${_controller.battery}%',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF52525B)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Current Zone: ${_controller.currentWaypointName}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF18181B)),
          ),
          const SizedBox(height: 3),
          Text(
            'Coordinates: ${_controller.latitude.toStringAsFixed(6)}° N, ${_controller.longitude.toStringAsFixed(6)}° E',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF3F3F46)),
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
                  color: isLive ? const Color(0xFF16A34A) : const Color(0xFF71717A),
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
                      color: isLive ? const Color(0xFF15803D) : const Color(0xFF71717A),
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

  // ================= 2. CITY BUS SCANNER PANEL =================
  Widget _buildBusPanel() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            border: Border.all(color: const Color(0xFFE4E4E7)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Circle QR Avatar
              Container(
                width: 60,
                height: 60,
                decoration: const BoxDecoration(
                  color: Color(0xFFD1FAE5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.qr_code_scanner,
                  size: 32,
                  color: Color(0xFF059669),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Scan Student Ticket',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF18181B),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Verify onboarding for Rupnagar City Bus #104',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF71717A),
                ),
              ),

              const SizedBox(height: 16),

              // Camera QR Scanner Trigger
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _openCameraScanner,
                  icon: const Icon(Icons.qr_code_scanner, size: 20),
                  label: const Text(
                    'Open Camera QR Scanner',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Divider between QR Camera and Manual entry
              Row(
                children: [
                  const Expanded(child: Divider(color: Color(0xFFE4E4E7))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'OR ENTER TICKET ID',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: Color(0xFFE4E4E7))),
                ],
              ),

              const SizedBox(height: 14),

              // Ticket ID input field
              TextField(
                controller: _ticketInputController,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter ticket ID (e.g. TKT-8841)',
                  hintStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                    color: Color(0xFFA1A1AA),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE4E4E7)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
                  ),
                ),
                onSubmitted: (_) => _onVerifyTicket(),
              ),

              const SizedBox(height: 10),

              // Quick Test helper chips
              Wrap(
                spacing: 8,
                children: [
                  _demoChip('TKT-8841 (Valid)', () => _onVerifyTicket('TKT-8841')),
                  _demoChip('TKT-1042 (Valid)', () => _onVerifyTicket('TKT-1042')),
                  _demoChip('TKT-9999 (Invalid)', () => _onVerifyTicket('TKT-9999')),
                ],
              ),

              const SizedBox(height: 12),

              // Verify button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _onVerifyTicket(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    side: const BorderSide(color: Color(0xFF059669)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Verify & Check-In Passenger',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Result status box
        _buildScanResultBox(),

        const SizedBox(height: 20),

        // Passenger Manifest Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Boarded Passenger Manifest',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF52525B),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFD1FAE5),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${_controller.onboardedCount} / ${_controller.totalSeats} Boarded',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF047857),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        if (_controller.tickets.isEmpty)
          Container(
            padding: const EdgeInsets.all(14),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              border: Border.all(color: const Color(0xFFE4E4E7)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'No passengers onboard yet',
                style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
              ),
            ),
          )
        else
          ..._controller.tickets.map((t) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              border: Border.all(color: const Color(0xFFE4E4E7)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.id,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF18181B),
                        ),
                      ),
                      Text(
                        '${t.route} · ${t.busNo}',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF71717A)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: t.status == 'Valid'
                        ? const Color(0xFFFEF3C7)
                        : const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    t.status,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: t.status == 'Valid'
                          ? const Color(0xFF92400E)
                          : const Color(0xFF065F46),
                    ),
                  ),
                ),
              ],
            ),
          )),
      ],
    );
  }

  Widget _demoChip(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFE4E4E7)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, color: Color(0xFF71717A)),
        ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _controller.scanResultText,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: _controller.scanResultType == 'idle' ? FontWeight.w400 : FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
