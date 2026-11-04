library;

/// Model classes and default timetable dataset for IIT Ropar Bus Schedules.
/// Based directly on the official institute timetable w.e.f. 27-07-2026.

class BusStopSchedule {
  final String stopName;
  final String time;
  final String type; // 'departure', 'pickup', 'dropoff', 'both', 'arrival'

  const BusStopSchedule({
    required this.stopName,
    required this.time,
    this.type = 'both',
  });

  factory BusStopSchedule.fromMap(Map<String, dynamic> map) {
    return BusStopSchedule(
      stopName: map['stopName'] as String? ?? '',
      time: map['time'] as String? ?? '',
      type: map['type'] as String? ?? 'both',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'stopName': stopName,
      'time': time,
      'type': type,
    };
  }

  BusStopSchedule copyWith({
    String? stopName,
    String? time,
    String? type,
  }) {
    return BusStopSchedule(
      stopName: stopName ?? this.stopName,
      time: time ?? this.time,
      type: type ?? this.type,
    );
  }
}

class ScheduledTrip {
  final String id;
  final int tripNumber;
  final String title;
  final String departureTime;
  final String arrivalTime;
  final List<BusStopSchedule> stops;
  final String registrationNumber;
  final int totalSeats;
  final int availableSeats;
  final bool isActive;
  final String? note;

  const ScheduledTrip({
    required this.id,
    required this.tripNumber,
    required this.title,
    required this.departureTime,
    required this.arrivalTime,
    required this.stops,
    this.registrationNumber = 'PB-12-Bus-01',
    this.totalSeats = 35,
    this.availableSeats = 35,
    this.isActive = true,
    this.note,
  });

  factory ScheduledTrip.fromMap(Map<String, dynamic> map) {
    return ScheduledTrip(
      id: map['id'] as String? ?? '',
      tripNumber: (map['tripNumber'] as num?)?.toInt() ?? 1,
      title: map['title'] as String? ?? '',
      departureTime: map['departureTime'] as String? ?? '',
      arrivalTime: map['arrivalTime'] as String? ?? '',
      stops: (map['stops'] as List<dynamic>? ?? [])
          .map((item) => BusStopSchedule.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      registrationNumber: map['registrationNumber'] as String? ?? 'PB-12-Bus-01',
      totalSeats: (map['totalSeats'] as num?)?.toInt() ?? 35,
      availableSeats: (map['availableSeats'] as num?)?.toInt() ?? 35,
      isActive: map['isActive'] as bool? ?? true,
      note: map['note'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tripNumber': tripNumber,
      'title': title,
      'departureTime': departureTime,
      'arrivalTime': arrivalTime,
      'stops': stops.map((s) => s.toMap()).toList(),
      'registrationNumber': registrationNumber,
      'totalSeats': totalSeats,
      'availableSeats': availableSeats,
      'isActive': isActive,
      'note': note,
    };
  }

  ScheduledTrip copyWith({
    String? id,
    int? tripNumber,
    String? title,
    String? departureTime,
    String? arrivalTime,
    List<BusStopSchedule>? stops,
    String? registrationNumber,
    int? totalSeats,
    int? availableSeats,
    bool? isActive,
    String? note,
  }) {
    return ScheduledTrip(
      id: id ?? this.id,
      tripNumber: tripNumber ?? this.tripNumber,
      title: title ?? this.title,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      stops: stops ?? this.stops,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      isActive: isActive ?? this.isActive,
      note: note ?? this.note,
    );
  }
}

class DayBusSchedule {
  final String dayId; // 'monday', 'tuesday_thursday', 'friday', 'saturday_holidays', 'sunday'
  final String dayTitle;
  final String subtitle;
  final List<ScheduledTrip> trips;
  final List<String> generalRules;
  final DateTime? lastUpdated;

  const DayBusSchedule({
    required this.dayId,
    required this.dayTitle,
    this.subtitle = 'w.e.f. 27-07-2026',
    required this.trips,
    this.generalRules = const [
      'Buses will run on a point to point basis with authorized stops only.',
      'All the passengers are required to carry their institute identity card. The driver is authorized to check any passenger’s identity card.',
      'For any grievance/problem, please don’t argue with the driver(s), instead, contact the facilities section.',
    ],
    this.lastUpdated,
  });

  factory DayBusSchedule.fromMap(Map<String, dynamic> map) {
    return DayBusSchedule(
      dayId: map['dayId'] as String? ?? 'monday',
      dayTitle: map['dayTitle'] as String? ?? 'Daily Schedule',
      subtitle: map['subtitle'] as String? ?? 'w.e.f. 27-07-2026',
      trips: (map['trips'] as List<dynamic>? ?? [])
          .map((item) => ScheduledTrip.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
      generalRules: (map['generalRules'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [
            'Buses will run on a point to point basis with authorized stops only.',
            'All the passengers are required to carry their institute identity card. The driver is authorized to check any passenger’s identity card.',
            'For any grievance/problem, please don’t argue with the driver(s), instead, contact the facilities section.',
          ],
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] is DateTime
              ? map['lastUpdated'] as DateTime
              : DateTime.tryParse(map['lastUpdated'].toString()))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'dayId': dayId,
      'dayTitle': dayTitle,
      'subtitle': subtitle,
      'trips': trips.map((t) => t.toMap()).toList(),
      'generalRules': generalRules,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  DayBusSchedule copyWith({
    String? dayId,
    String? dayTitle,
    String? subtitle,
    List<ScheduledTrip>? trips,
    List<String>? generalRules,
    DateTime? lastUpdated,
  }) {
    return DayBusSchedule(
      dayId: dayId ?? this.dayId,
      dayTitle: dayTitle ?? this.dayTitle,
      subtitle: subtitle ?? this.subtitle,
      trips: trips ?? this.trips,
      generalRules: generalRules ?? this.generalRules,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Factory repository providing the exact IIT Ropar bus schedule from the official PDF.
class OfficialBusScheduleData {
  static const List<String> standardInstituteRules = [
    'Buses will run on a point to point basis with authorized stops only.',
    'All the passengers are required to carry their institute identity card. The driver is authorized to check any passenger’s identity card.',
    'For any grievance/problem, please don’t argue with the driver(s), instead, contact the facilities section.',
  ];

  /// Schedule for Mondays (Includes 05:05 AM pickup from Railway Station + regular trips)
  static DayBusSchedule get mondaySchedule => DayBusSchedule(
        dayId: 'monday',
        dayTitle: 'Monday',
        subtitle: 'w.e.f. 27-07-2026',
        generalRules: standardInstituteRules,
        trips: [
          const ScheduledTrip(
            id: 'mon_trip_1',
            tripNumber: 1,
            title: 'Pickup from Railway Station only on Monday\'s',
            departureTime: '05:05 AM',
            arrivalTime: '05:40 AM',
            registrationNumber: 'PB-12-Bus-01',
            note: 'Kindly note that pickup from railway station will be done 10 minutes after arrival of train or whichever is later.',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '05:05 AM', type: 'departure'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at new bus stand', time: '05:17 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at old bus stand/railway station', time: '05:20 AM', type: 'both'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '05:40 AM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'mon_trip_2',
            tripNumber: 2,
            title: 'Local Round Trip',
            departureTime: '08:15 AM',
            arrivalTime: '08:50 AM',
            registrationNumber: 'PB-12-Bus-02',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '08:15 AM', type: 'departure'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at new bus stand', time: '08:27 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at old bus stand/ railway station', time: '08:30 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at police lines', time: '08:37 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '08:42 AM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up near over bridge', time: '08:45 AM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '08:50 AM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'mon_trip_3',
            tripNumber: 3,
            title: 'Local Round Trip',
            departureTime: '09:05 AM',
            arrivalTime: '09:50 AM',
            registrationNumber: 'PB-12-Bus-01',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '09:05 AM', type: 'departure'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at new bus stand', time: '09:17 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at old bus stand/ railway station', time: '09:20 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at police lines', time: '09:27 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at bela chowk', time: '09:37 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '09:42 AM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up near over bridge', time: '09:45 AM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '09:50 AM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'mon_trip_4',
            tripNumber: 4,
            title: 'Local Trip to Bela Chowk and back',
            departureTime: '03:10 PM',
            arrivalTime: '04:43 PM',
            registrationNumber: 'PB-12-Bus-02',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '03:10 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital light point', time: '03:20 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at g s resort (near to hmt)', time: '03:22 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at bela chowk', time: '03:25 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Pick-up from bela chowk', time: '04:30 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '04:33 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '04:35 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '04:43 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'mon_trip_5',
            tripNumber: 5,
            title: 'Local Trip to Bela Chowk and back',
            departureTime: '05:00 PM',
            arrivalTime: '05:31 PM',
            registrationNumber: 'PB-12-Bus-01',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '05:00 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital light point', time: '05:10 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at g s resort (near to hmt)', time: '05:12 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at bela chowk', time: '05:15 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Pick-up from bela chowk', time: '05:18 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '05:21 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '05:23 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '05:31 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'mon_trip_6',
            tripNumber: 6,
            title: 'Local Trip to Bus Stand and Police lines',
            departureTime: '05:50 PM',
            arrivalTime: '06:25 PM',
            registrationNumber: 'PB-12-Bus-03',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '05:50 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop near over bridge', time: '05:55 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at new bus stand', time: '06:02 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at old bus stand/railway station', time: '06:05 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at police lines', time: '06:12 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '06:17 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '06:25 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'mon_trip_7',
            tripNumber: 7,
            title: 'Local Round Trip',
            departureTime: '07:00 PM',
            arrivalTime: '07:43 PM',
            registrationNumber: 'PB-12-Bus-02',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '07:00 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital light point', time: '07:10 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off/ pick-up at police lines', time: '07:20 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at bela chowk', time: '07:30 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at g s resort(near to hmt)', time: '07:33 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '07:35 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '07:43 PM', type: 'arrival'),
            ],
          ),
        ],
      );

  /// Schedule for Tuesday to Thursday (Trips 2-7 from Monday-Thursday schedule)
  static DayBusSchedule get tuesdayThursdaySchedule => DayBusSchedule(
        dayId: 'tuesday_thursday',
        dayTitle: 'Tuesday - Thursday',
        subtitle: 'w.e.f. 27-07-2026',
        generalRules: standardInstituteRules,
        trips: [
          const ScheduledTrip(
            id: 'tt_trip_1',
            tripNumber: 1,
            title: 'Local Round Trip',
            departureTime: '08:15 AM',
            arrivalTime: '08:50 AM',
            registrationNumber: 'PB-12-Bus-02',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '08:15 AM', type: 'departure'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at new bus stand', time: '08:27 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at old bus stand/ railway station', time: '08:30 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at police lines', time: '08:37 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '08:42 AM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up near over bridge', time: '08:45 AM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '08:50 AM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'tt_trip_2',
            tripNumber: 2,
            title: 'Local Round Trip',
            departureTime: '09:05 AM',
            arrivalTime: '09:50 AM',
            registrationNumber: 'PB-12-Bus-01',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '09:05 AM', type: 'departure'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at new bus stand', time: '09:17 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at old bus stand/ railway station', time: '09:20 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at police lines', time: '09:27 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at bela chowk', time: '09:37 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '09:42 AM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up near over bridge', time: '09:45 AM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '09:50 AM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'tt_trip_3',
            tripNumber: 3,
            title: 'Local Trip to Bela Chowk and back',
            departureTime: '03:10 PM',
            arrivalTime: '04:43 PM',
            registrationNumber: 'PB-12-Bus-02',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '03:10 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital light point', time: '03:20 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at g s resort (near to hmt)', time: '03:22 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at bela chowk', time: '03:25 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Pick-up from bela chowk', time: '04:30 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '04:33 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '04:35 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '04:43 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'tt_trip_4',
            tripNumber: 4,
            title: 'Local Trip to Bela Chowk and back',
            departureTime: '05:00 PM',
            arrivalTime: '05:31 PM',
            registrationNumber: 'PB-12-Bus-01',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '05:00 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital light point', time: '05:10 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at g s resort (near to hmt)', time: '05:12 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at bela chowk', time: '05:15 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Pick-up from bela chowk', time: '05:18 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '05:21 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '05:23 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '05:31 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'tt_trip_5',
            tripNumber: 5,
            title: 'Local Trip to Bus Stand and Police lines',
            departureTime: '05:50 PM',
            arrivalTime: '06:25 PM',
            registrationNumber: 'PB-12-Bus-03',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '05:50 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop near over bridge', time: '05:55 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at new bus stand', time: '06:02 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at old bus stand/railway station', time: '06:05 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at police lines', time: '06:12 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '06:17 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '06:25 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'tt_trip_6',
            tripNumber: 6,
            title: 'Local Round Trip',
            departureTime: '07:00 PM',
            arrivalTime: '07:43 PM',
            registrationNumber: 'PB-12-Bus-02',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '07:00 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital light point', time: '07:10 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off/ pick-up at police lines', time: '07:20 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at bela chowk', time: '07:30 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at g s resort(near to hmt)', time: '07:33 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '07:35 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '07:43 PM', type: 'arrival'),
            ],
          ),
        ],
      );

  /// Schedule for Fridays (9 trips from Pages 4, 5, 6 of the PDF)
  static DayBusSchedule get fridaySchedule => DayBusSchedule(
        dayId: 'friday',
        dayTitle: 'Friday',
        subtitle: 'w.e.f. 27-07-2026',
        generalRules: standardInstituteRules,
        trips: [
          const ScheduledTrip(
            id: 'fri_trip_1',
            tripNumber: 1,
            title: 'Local Trip to Bus Stand and police lines',
            departureTime: '08:15 AM',
            arrivalTime: '08:50 AM',
            registrationNumber: 'PB-12-Bus-01',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '08:15 AM', type: 'departure'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at new bus stand', time: '08:27 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at old bus stand/railway station', time: '08:30 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at police lines', time: '08:37 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '08:42 AM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up near overbridge', time: '08:45 AM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '08:50 AM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'fri_trip_2',
            tripNumber: 2,
            title: 'Local Trip to Bela Chowk and back',
            departureTime: '09:05 AM',
            arrivalTime: '09:50 AM',
            registrationNumber: 'PB-12-Bus-02',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '09:05 AM', type: 'departure'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at new bus stand', time: '09:17 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at old bus stand/railway station', time: '09:20 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at police lines', time: '09:27 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at bela chowk', time: '09:37 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '09:42 AM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up near overbridge', time: '09:45 AM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '09:50 AM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'fri_trip_3',
            tripNumber: 3,
            title: 'Local Trip to Railway Station, Bela Chowk and back',
            departureTime: '02:30 PM',
            arrivalTime: '04:43 PM',
            registrationNumber: 'PB-12-Bus-01',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '02:30 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at new bus stand', time: '02:42 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at old bus stand/railway station', time: '02:45 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at police lines', time: '02:52 PM', type: 'both'),
              BusStopSchedule(stopName: 'Drop-off at bela chowk', time: '03:02 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Pick-up from bela chowk', time: '04:30 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '04:33 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up near overbridge', time: '04:38 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '04:43 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'fri_trip_4',
            tripNumber: 4,
            title: 'Local Trip to Bela Chowk and back',
            departureTime: '05:00 PM',
            arrivalTime: '05:31 PM',
            registrationNumber: 'PB-12-Bus-02',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '05:00 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital light point', time: '05:10 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at g s resort(near to hmt)', time: '05:12 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at bela chowk', time: '05:15 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Pick-up from bela chowk', time: '05:18 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '05:21 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '05:23 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '05:31 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'fri_trip_5',
            tripNumber: 5,
            title: 'Local Trip to Bela Chowk and back Added',
            departureTime: '05:30 PM',
            arrivalTime: '05:57 PM',
            registrationNumber: 'PB-12-Bus-03',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '05:30 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital light point', time: '05:38 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at g s resort(near to hmt)', time: '05:40 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at bela chowk', time: '05:43 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Pick-up from bela chowk', time: '05:44 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '05:47 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '05:49 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main camps', time: '05:57 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'fri_trip_6',
            tripNumber: 6,
            title: 'Local Round Trip',
            departureTime: '05:50 PM',
            arrivalTime: '06:25 PM',
            registrationNumber: 'PB-12-Bus-01',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '05:50 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off near over bridge', time: '05:55 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off/ pick-up new bus stand', time: '06:02 PM', type: 'both'),
              BusStopSchedule(stopName: 'Drop-off/ pick-up old bus stand/railway station', time: '06:05 PM', type: 'both'),
              BusStopSchedule(stopName: 'Drop-off/ pick-up at police lines', time: '06:12 PM', type: 'both'),
              BusStopSchedule(stopName: 'Drop-off / pick-up at surjit hospital light point', time: '06:17 PM', type: 'both'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '06:25 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'fri_trip_7',
            tripNumber: 7,
            title: 'Local Trip to Bela Chowk and back',
            departureTime: '06:15 PM',
            arrivalTime: '07:28 PM',
            registrationNumber: 'PB-12-Bus-02',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '06:15 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital light point', time: '06:25 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at g s resort(near to hmt)', time: '06:27 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at bela chowk', time: '06:29 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Pick-up from bela chowk', time: '07:15 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '07:18 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '07:21 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '07:28 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'fri_trip_8',
            tripNumber: 8,
            title: 'Local Round Trip',
            departureTime: '07:10 PM',
            arrivalTime: '07:53 PM',
            registrationNumber: 'PB-12-Bus-01',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '07:10 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital light point', time: '07:20 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at police lines', time: '07:30 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Pick-up at bela chowk', time: '07:40 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at opposite to gs resort (near to hmt)', time: '07:45 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '07:53 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'fri_trip_9',
            tripNumber: 9,
            title: 'Local round trip',
            departureTime: '10:00 PM',
            arrivalTime: '10:30 PM',
            registrationNumber: 'PB-12-Bus-03',
            note: 'First come first serve basis only, if all seats are full then students will be responsible for making their own travel arrangements.',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '10:00 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off near overbridge', time: '10:05 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off/ pick-up new bus stand', time: '10:12 PM', type: 'both'),
              BusStopSchedule(stopName: 'Drop-off/ pick-up old bus stand/railway station', time: '10:15 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at new bus stand', time: '10:18 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '10:30 PM', type: 'arrival'),
            ],
          ),
        ],
      );

  /// Schedule for Saturdays & Holidays (7 trips from Pages 7, 8, 9 of the PDF)
  static DayBusSchedule get saturdayHolidaysSchedule => DayBusSchedule(
        dayId: 'saturday_holidays',
        dayTitle: 'Saturday & Holidays',
        subtitle: 'w.e.f. 27-07-2026',
        generalRules: standardInstituteRules,
        trips: [
          const ScheduledTrip(
            id: 'sat_trip_1',
            tripNumber: 1,
            title: 'Local Round Trip',
            departureTime: '08:30 AM',
            arrivalTime: '09:05 AM',
            registrationNumber: 'PB-12-Bus-01',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '08:30 AM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off/ pick-up new bus stand', time: '08:42 AM', type: 'both'),
              BusStopSchedule(stopName: 'Drop-off/ pick-up old bus stand/railway station', time: '08:45 AM', type: 'both'),
              BusStopSchedule(stopName: 'Drop-off/ pick-up at police lines', time: '08:52 AM', type: 'both'),
              BusStopSchedule(stopName: 'Drop-off / pick-up at surjit hospital light point', time: '08:57 AM', type: 'both'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '09:05 AM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'sat_trip_2',
            tripNumber: 2,
            title: 'Local Trip to Bela Chowk and back',
            departureTime: '10:30 AM',
            arrivalTime: '10:58 AM',
            registrationNumber: 'PB-12-Bus-02',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '10:30 AM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital light point', time: '10:40 AM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at g s resort(near to hmt)', time: '10:42 AM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off /pick up at bela chowk', time: '10:45 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '10:48 AM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick up at surjit hospital light point', time: '10:50 AM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '10:58 AM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'sat_trip_3',
            tripNumber: 3,
            title: 'Local Trip to Bela Chowk and back',
            departureTime: '11:10 AM',
            arrivalTime: '01:48 PM',
            registrationNumber: 'PB-12-Bus-01',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '11:10 AM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital light point', time: '11:20 AM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at g s resort(near to hmt)', time: '11:22 AM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at bela chowk', time: '11:25 AM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Pick-up from bela chowk', time: '01:25 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '01:38 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '01:40 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '01:48 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'sat_trip_4',
            tripNumber: 4,
            title: 'Local Trip to Bela Chowk and back',
            departureTime: '03:00 PM',
            arrivalTime: '03:28 PM',
            registrationNumber: 'PB-12-Bus-02',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '03:00 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital light point', time: '03:10 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at g s resort(near to hmt)', time: '03:12 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off/ pick-up at bela chowk', time: '03:15 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '03:18 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick up at surjit hospital light point', time: '03:20 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '03:28 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'sat_trip_5',
            tripNumber: 5,
            title: 'Local Trip to Bela Chowk and back',
            departureTime: '04:00 PM',
            arrivalTime: '04:30 PM',
            registrationNumber: 'PB-12-Bus-03',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '04:00 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital light point', time: '04:10 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at g s resort(near to hmt)', time: '04:12 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at bela chowk', time: '04:15 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Pick-up from bela chowk', time: '04:17 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '04:20 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '04:22 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '04:30 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'sat_trip_6',
            tripNumber: 6,
            title: 'Local Round Trip',
            departureTime: '05:30 PM',
            arrivalTime: '06:08 PM',
            registrationNumber: 'PB-12-Bus-01',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '05:30 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital', time: '05:40 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at opposite to gs resort (near to hmt)', time: '05:42 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off and pick-up at bela chowk', time: '05:45 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '05:48 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at police lines', time: '05:55 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '06:00 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '06:08 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'sat_trip_7',
            tripNumber: 7,
            title: 'Local Round Trip to police lines',
            departureTime: '06:40 PM',
            arrivalTime: '07:25 PM',
            registrationNumber: 'PB-12-Bus-02',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '06:40 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at new bus stand', time: '06:52 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at old bus stand/railway station', time: '06:55 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at police lines', time: '07:02 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '07:07 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at bela chowk', time: '07:12 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '07:15 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '07:17 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '07:25 PM', type: 'arrival'),
            ],
          ),
        ],
      );

  /// Schedule for Sundays (6 trips from Pages 10, 11 of the PDF)
  static DayBusSchedule get sundaySchedule => DayBusSchedule(
        dayId: 'sunday',
        dayTitle: 'Sunday',
        subtitle: 'w.e.f. 27-07-2026',
        generalRules: standardInstituteRules,
        trips: [
          const ScheduledTrip(
            id: 'sun_trip_1',
            tripNumber: 1,
            title: 'Local Trip to Bela Chowk and back',
            departureTime: '10:30 AM',
            arrivalTime: '10:58 AM',
            registrationNumber: 'PB-12-Bus-02',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '10:30 AM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital light point', time: '10:40 AM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at g s resort(near to hmt)', time: '10:42 AM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off /pick up at bela chowk', time: '10:45 AM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '10:48 AM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick up at surjit hospital light point', time: '10:50 AM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '10:58 AM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'sun_trip_2',
            tripNumber: 2,
            title: 'Local Trip to Bela Chowk and back',
            departureTime: '11:10 AM',
            arrivalTime: '01:48 PM',
            registrationNumber: 'PB-12-Bus-01',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '11:10 AM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital light point', time: '11:20 AM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at g s resort(near to hmt)', time: '11:22 AM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at bela chowk', time: '11:25 AM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Pick-up from bela chowk', time: '01:25 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '01:38 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '01:40 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '01:48 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'sun_trip_3',
            tripNumber: 3,
            title: 'Local Trip to Bela Chowk and back',
            departureTime: '03:00 PM',
            arrivalTime: '03:28 PM',
            registrationNumber: 'PB-12-Bus-02',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '03:00 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital light point', time: '03:10 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at g s resort(near to hmt)', time: '03:12 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off/ pick-up at bela chowk', time: '03:15 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '03:18 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick up at surjit hospital light point', time: '03:20 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '03:28 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'sun_trip_4',
            tripNumber: 4,
            title: 'Local Trip to Bela Chowk and back',
            departureTime: '04:00 PM',
            arrivalTime: '04:30 PM',
            registrationNumber: 'PB-12-Bus-03',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '04:00 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital light point', time: '04:10 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at g s resort(near to hmt)', time: '04:12 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at bela chowk', time: '04:15 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Pick-up from bela chowk', time: '04:17 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '04:20 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '04:22 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '04:30 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'sun_trip_5',
            tripNumber: 5,
            title: 'Local Round Trip',
            departureTime: '05:30 PM',
            arrivalTime: '06:08 PM',
            registrationNumber: 'PB-12-Bus-01',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '05:30 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Drop-off at surjit hospital', time: '05:40 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off at opposite to gs resort (near to hmt)', time: '05:42 PM', type: 'dropoff'),
              BusStopSchedule(stopName: 'Drop-off and pick-up at bela chowk', time: '05:45 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '05:48 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at police lines', time: '05:55 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '06:00 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '06:08 PM', type: 'arrival'),
            ],
          ),
          const ScheduledTrip(
            id: 'sun_trip_6',
            tripNumber: 6,
            title: 'Local Round Trip to police lines',
            departureTime: '06:40 PM',
            arrivalTime: '07:25 PM',
            registrationNumber: 'PB-12-Bus-02',
            stops: [
              BusStopSchedule(stopName: 'Departure from main campus', time: '06:40 PM', type: 'departure'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at new bus stand', time: '06:52 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at old bus stand/railway station', time: '06:55 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at police lines', time: '07:02 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '07:07 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up/drop-off at bela chowk', time: '07:12 PM', type: 'both'),
              BusStopSchedule(stopName: 'Pick-up at opposite to g s resort (near to hmt)', time: '07:15 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Pick-up at surjit hospital light point', time: '07:17 PM', type: 'pickup'),
              BusStopSchedule(stopName: 'Arrival at main campus', time: '07:25 PM', type: 'arrival'),
            ],
          ),
        ],
      );

  static Map<String, DayBusSchedule> get allDefaultSchedules => {
        'monday': mondaySchedule,
        'tuesday_thursday': tuesdayThursdaySchedule,
        'friday': fridaySchedule,
        'saturday_holidays': saturdayHolidaysSchedule,
        'sunday': sundaySchedule,
      };

  /// Returns the day ID corresponding to a given DateTime.
  static String dayIdForDate(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
      case DateTime.wednesday:
      case DateTime.thursday:
        return 'tuesday_thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday_holidays';
      case DateTime.sunday:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  /// Returns the readable title for a given dayId.
  static String dayTitleForId(String dayId) {
    switch (dayId) {
      case 'monday':
        return 'Monday';
      case 'tuesday_thursday':
        return 'Tuesday - Thursday';
      case 'friday':
        return 'Friday';
      case 'saturday_holidays':
        return 'Saturday & Holidays';
      case 'sunday':
        return 'Sunday';
      default:
        return 'Daily Schedule';
    }
  }
}
