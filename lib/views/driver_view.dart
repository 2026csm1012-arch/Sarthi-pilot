import 'package:flutter/material.dart';
import 'package:sarthi_pilot/controllers/auth_controller.dart';
import 'package:sarthi_pilot/controllers/driver_controller.dart';
import 'package:sarthi_pilot/models/driver_user.dart';
import 'package:sarthi_pilot/models/ride_request.dart';
import 'package:sarthi_pilot/views/login_view.dart';
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
    _controller = DriverController();
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

  void _onAcceptRequest(int id) {
    _controller.acceptRequest(id);
    _showToast('Ride accepted! Heading to pickup zone.');
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Driver View',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, size: 18, color: Color(0xFF71717A)),
                tooltip: 'Sign Out',
                onPressed: () async {
                  await AuthController().signOut();
                  if (!context.mounted) return;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(builder: (_) => const LoginView()),
                  );
                },
              ),
              const SizedBox(width: 8),
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

                const SizedBox(height: 20),

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
              value: _controller.selectedCart,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Color(0xFF71717A)),
              style: const TextStyle(fontSize: 12, color: Color(0xFF18181B)),
              items: const [
                DropdownMenuItem(
                  value: 'cart-1',
                  child: Text('Cart #1 (Satlej Loop)'),
                ),
                DropdownMenuItem(
                  value: 'cart-2',
                  child: Text('Cart #2 (Hostel Shuttle)'),
                ),
              ],
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
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => _onAcceptRequest(req.id),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
