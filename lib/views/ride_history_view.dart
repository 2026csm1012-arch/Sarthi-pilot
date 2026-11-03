import 'package:flutter/material.dart';
import 'package:sarthi_pilot/controllers/driver_controller.dart';
import 'package:sarthi_pilot/models/bus_ticket.dart';
import 'package:sarthi_pilot/models/driver_user.dart';
import 'package:sarthi_pilot/models/ride_request.dart';

/// Activity and Trip History view displaying live completed EV cart rides
/// and verified bus tickets directly from the Firebase Firestore database.
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
    return DefaultTabController(
      length: 2,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final history = controller.rideHistory;
          final completedCount = history
              .where((r) => r.status == 'completed')
              .length;
          final tickets = controller.tickets;
          final verifiedTickets = tickets.where((t) => t.isConfirmed).toList();

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              leading: const BackButton(color: Color(0xFF18181B)),
              titleSpacing: 0,
              title: const Text(
                'Driver History & Logs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF18181B),
                ),
              ),
              bottom: TabBar(
                indicatorColor: const Color(0xFF059669),
                labelColor: const Color(0xFF059669),
                unselectedLabelColor: const Color(0xFF71717A),
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.airport_shuttle, size: 16),
                        const SizedBox(width: 6),
                        Text('EV Carts (${history.length})'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.confirmation_number_outlined,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text('Bus Tickets (${tickets.length})'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                // TAB 1: EV Cart Rides
                SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildMetricRow(
                        metrics: [
                          _buildMetric(
                            label: 'Total Trips',
                            value: '${history.length}',
                            icon: Icons.route_rounded,
                            color: const Color(0xFF059669),
                          ),
                          _buildMetric(
                            label: 'Completed',
                            value: '$completedCount',
                            icon: Icons.check_circle_rounded,
                            color: const Color(0xFF16A34A),
                          ),
                          _buildMetric(
                            label: 'Driver ID',
                            value: driverUser.driverId,
                            icon: Icons.badge_outlined,
                            color: const Color(0xFF6366F1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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
                            'Completed',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (history.isEmpty)
                        _buildEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No Ride History Recorded',
                          subtitle: 'Trips accepted and completed by you will appear here automatically.',
                        )
                      else
                        ...history.map(_buildRideHistoryCard),
                    ],
                  ),
                ),

                // TAB 2: Scanned Bus Tickets
                SafeArea(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildMetricRow(
                        metrics: [
                          _buildMetric(
                            label: 'Total Scanned',
                            value: '${verifiedTickets.length}',
                            icon: Icons.qr_code_scanner_rounded,
                            color: const Color(0xFF059669),
                          ),
                          _buildMetric(
                            label: 'Active Tickets',
                            value: '${tickets.length}',
                            icon: Icons.confirmation_number_outlined,
                            color: const Color(0xFF2563EB),
                          ),
                          _buildMetric(
                            label: 'Bus Status',
                            value: controller.occupancy,
                            icon: Icons.event_seat_rounded,
                            color: controller.occupancy == 'Full'
                                ? Colors.redAccent
                                : const Color(0xFF16A34A),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Passenger Manifest & Scans',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF18181B),
                            ),
                          ),
                          Text(
                            'Verified',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (tickets.isEmpty)
                        _buildEmptyState(
                          icon: Icons.confirmation_number_outlined,
                          title: 'No Bus Tickets Recorded Yet',
                          subtitle: 'Tickets booked by students and confirmed via camera scan will appear here in real time.',
                        )
                      else
                        ...tickets.map(_buildBusTicketCard),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricRow({required List<Widget> metrics}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          metrics[0],
          Container(height: 36, width: 1, color: const Color(0xFFE4E4E7)),
          metrics[1],
          Container(height: 36, width: 1, color: const Color(0xFFE4E4E7)),
          metrics[2],
        ],
      ),
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

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
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
            child: Icon(icon, size: 32, color: const Color(0xFFA1A1AA)),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF27272A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Color(0xFF71717A)),
          ),
        ],
      ),
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
                    'Trip #${ride.id.length > 8 ? ride.id.substring(0, 8) : ride.id}',
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
                  color: ride.status == 'completed'
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  ride.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: ride.status == 'completed'
                        ? const Color(0xFF15803D)
                        : const Color(0xFFB91C1C),
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
                  const Icon(
                    Icons.person_outline,
                    size: 14,
                    color: Color(0xFF71717A),
                  ),
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

  Widget _buildBusTicketCard(BusTicket ticket) {
    final isConfirmed = ticket.isConfirmed;

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
                  Icon(
                    isConfirmed
                        ? Icons.check_circle_rounded
                        : Icons.confirmation_number_outlined,
                    size: 16,
                    color: isConfirmed
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF2563EB),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    ticket.id,
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
                  color: isConfirmed
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isConfirmed ? 'VERIFIED' : 'VALID',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isConfirmed
                        ? const Color(0xFF15803D)
                        : const Color(0xFF1D4ED8),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ticket.route,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF27272A),
            ),
          ),
          if (ticket.pickup.isNotEmpty || ticket.drop.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.directions_outlined,
                  size: 14,
                  color: Color(0xFF71717A),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${ticket.pickup} ➔ ${ticket.drop}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF52525B),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          const Divider(color: Color(0xFFF4F4F5), height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 14,
                    color: Color(0xFF71717A),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    ticket.passengerName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF52525B),
                    ),
                  ),
                ],
              ),
              Text(
                ticket.verifiedAt != null
                    ? 'Confirmed: ${ticket.verifiedAt!.hour.toString().padLeft(2, '0')}:${ticket.verifiedAt!.minute.toString().padLeft(2, '0')}'
                    : (ticket.busNo.isNotEmpty ? ticket.busNo : ticket.time),
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
