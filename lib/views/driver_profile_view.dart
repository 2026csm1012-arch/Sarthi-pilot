import 'package:flutter/material.dart';
import 'package:sarthi_pilot/controllers/auth_controller.dart';
import 'package:sarthi_pilot/controllers/driver_controller.dart';
import 'package:sarthi_pilot/models/driver_user.dart';
import 'package:sarthi_pilot/models/ride_request.dart';
import 'package:sarthi_pilot/views/login_view.dart';

/// Driver profile view displaying assigned vehicle details, ride history tied to driver ID,
/// and profile logout action in MVC architecture.
class DriverProfileView extends StatelessWidget {
  const DriverProfileView({
    super.key,
    required this.driverUser,
    required this.controller,
  });

  final DriverUser driverUser;
  final DriverController controller;

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to log out of the Driver Portal? Any active vehicle will be set to offline and location broadcast will stop.',
          style: TextStyle(fontSize: 13, color: Color(0xFF52525B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF71717A))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      if (controller.isOnline) {
        await controller.toggleOnlineStatus();
      }
      await AuthController().signOut();
      if (!context.mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const LoginView()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final isOnline = controller.isOnline;
        final cartName = controller.selectedCartName;
        final cartId = controller.selectedCart;
        final history = controller.rideHistory;
        final completedCount = history.where((r) => r.status == 'completed').length;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leading: const BackButton(color: Color(0xFF18181B)),
            titleSpacing: 0,
            title: const Text(
              'Driver Profile',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF18181B),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: const Color(0xFFF4F4F5), height: 1),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'IIT Ropar Transit',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF047857),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. Driver Profile Header Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    border: Border.all(color: const Color(0xFFE4E4E7)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFF059669),
                            child: Text(
                              driverUser.name.isNotEmpty
                                  ? driverUser.name[0].toUpperCase()
                                  : 'D',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driverUser.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF18181B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  driverUser.email,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF71717A),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF4F4F5),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xFFE4E4E7)),
                                  ),
                                  child: Text(
                                    'Driver ID: ${driverUser.uid}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF52525B),
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Color(0xFFE4E4E7), height: 1),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isOnline
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFA1A1AA),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isOnline ? 'Duty: Active On-Duty' : 'Duty: Off-Duty',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isOnline
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF71717A),
                                ),
                              ),
                            ],
                          ),
                          const Text(
                            'Authorized Pilot Operator',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2. Assigned Vehicle Section
                const Text(
                  'Assigned Cart',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF18181B),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE4E4E7)),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: const Icon(
                              Icons.electric_rickshaw_rounded,
                              color: Color(0xFF059669),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cartName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF18181B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'ID: $cartId · Location: ${controller.currentWaypointName}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF71717A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFE4E4E7)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.battery_charging_full_rounded,
                                    size: 16,
                                    color: Color(0xFF059669),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Battery: ${controller.battery}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF27272A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isOnline
                                      ? const Color(0xFF86EFAC)
                                      : const Color(0xFFE4E4E7),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isOnline
                                        ? Icons.sensors_rounded
                                        : Icons.sensors_off_rounded,
                                    size: 16,
                                    color: isOnline
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFA1A1AA),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isOnline ? 'GPS Active' : 'GPS Standby',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isOnline
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFF71717A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Re-assign Cart dropdown
                      DropdownButtonHideUnderline(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAFAFA),
                            border: Border.all(color: const Color(0xFFE4E4E7)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButton<String>(
                            value: controller.availableCarts.any((c) => c.id == controller.selectedCart)
                                ? controller.selectedCart
                                : (controller.availableCarts.isNotEmpty
                                    ? controller.availableCarts.first.id
                                    : controller.selectedCart),
                            isExpanded: true,
                            icon: const Icon(
                              Icons.swap_horiz_rounded,
                              size: 20,
                              color: Color(0xFF059669),
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF18181B),
                            ),
                            items: controller.availableCarts.isEmpty
                                ? [
                                    DropdownMenuItem<String>(
                                      value: controller.selectedCart,
                                      child: Text(
                                        'Assigned: ${controller.selectedCartName}',
                                      ),
                                    ),
                                  ]
                                : controller.availableCarts.map((cart) {
                                    return DropdownMenuItem<String>(
                                      value: cart.id,
                                      child: Text(
                                        'Assigned: ${cart.name}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                controller.setSelectedCart(val);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Assigned cart switched to ${controller.selectedCartName}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    backgroundColor: const Color(0xFF18181B),
                                    behavior: SnackBarBehavior.floating,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // 3. Ride History Section (tied to Driver ID)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Ride History',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Text(
                        '$completedCount Completed',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Trips associated with Driver ID: ${driverUser.uid}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
                ),
                const SizedBox(height: 10),

                if (history.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      border: Border.all(color: const Color(0xFFE4E4E7)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'No ride history recorded yet for this driver',
                        style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
                      ),
                    ),
                  )
                else
                  ...history.map(_buildRideHistoryCard),

                const SizedBox(height: 24),

                // 4. Logout in Profile Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmLogout(context),
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 20,
                      color: Color(0xFFDC2626),
                    ),
                    label: const Text(
                      'Log Out from Driver Portal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFFECDD3)),
                      backgroundColor: const Color(0xFFFFF1F2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRideHistoryCard(RideRequest ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E4E7)),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                  const Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: Color(0xFF16A34A),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Trip #${ride.id}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF18181B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'COMPLETED',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF059669),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 1.5,
                    height: 18,
                    color: const Color(0xFFE4E4E7),
                  ),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFDC2626),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.from,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF27272A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ride.to,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF27272A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFF4F4F5), height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Passenger: ${ride.userName}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF71717A)),
              ),
              Text(
                '${ride.assignedCartId ?? "EV Cart"} · ${ride.time}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF52525B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
