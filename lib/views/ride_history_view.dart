import 'package:flutter/material.dart';
import 'package:sarthi_pilot/controllers/driver_controller.dart';
import 'package:sarthi_pilot/models/driver_user.dart';
import 'package:sarthi_pilot/models/ride_request.dart';

/// Dedicated Ride History view displaying past completed rides for the driver.
class RideHistoryView extends StatelessWidget {
  const RideHistoryView({
    super.key,
    required this.driverUser,
    required this.controller,
  });

  final DriverUser driverUser;
  final DriverController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
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
              'Ride History',
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
                child: Text(
                  '$completedCount Completed',
                  style: const TextStyle(
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
                // Driver Stats Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE4E4E7)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetric(
                        label: 'Total Trips',
                        value: '${history.length}',
                        icon: Icons.route_rounded,
                        color: const Color(0xFF059669),
                      ),
                      Container(height: 36, width: 1, color: const Color(0xFFE4E4E7)),
                      _buildMetric(
                        label: 'Completed',
                        value: '$completedCount',
                        icon: Icons.check_circle_rounded,
                        color: const Color(0xFF16A34A),
                      ),
                      Container(height: 36, width: 1, color: const Color(0xFFE4E4E7)),
                      _buildMetric(
                        label: 'Driver ID',
                        value: driverUser.uid.length > 8
                            ? driverUser.uid.substring(0, 8)
                            : driverUser.uid,
                        icon: Icons.badge_outlined,
                        color: const Color(0xFF6366F1),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // History Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Past Trips & Logs',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    Text(
                      'Tied to ${driverUser.uid}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF71717A),
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Empty state or trip list
                if (history.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE4E4E7)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4F4F5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            size: 32,
                            color: Color(0xFFA1A1AA),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No Ride History Recorded',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF27272A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Trips accepted and completed by you will appear here automatically.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFF71717A)),
                        ),
                      ],
                    ),
                  )
                else
                  ...history.map(_buildRideHistoryCard),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetric({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Color(0xFF71717A),
          ),
        ),
      ],
    );
  }

  Widget _buildRideHistoryCard(RideRequest ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE4E4E7)),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
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
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF18181B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          const SizedBox(height: 12),
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
                    height: 20,
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.from,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF27272A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      ride.to,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF27272A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFF4F4F5), height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Color(0xFF71717A)),
                  const SizedBox(width: 4),
                  Text(
                    ride.userName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF52525B),
                    ),
                  ),
                ],
              ),
              Text(
                '${ride.assignedCartId ?? "EV Cart"} · ${ride.time}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF71717A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
