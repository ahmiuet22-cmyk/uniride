import '../models/route_model.dart';
import '../models/stop_model.dart';
import 'mock_stops.dart';
import 'route_road_polylines.dart';

class MockRoutes {
  static BusStopModel _getStop(String id) {
    return MockStops.allStops.firstWhere(
      (s) => s.id == id,
      orElse: () => MockStops.allStops.first,
    );
  }

  static final List<RouteModel> allRoutes = [
    // Route No. 1 - Chanda Qila/Wapda Town (Hino Bus GAU-2555)
    RouteModel(
      id: 'route_1',
      code: 'Route No. 1',
      title: 'Chanda Qila / Wapda Town',
      description: 'Hino Bus GAU-2555 • Connecting route for transfer of students to/from KSK campus.',
      estimatedDurationMinutes: 90,
      activeBusCount: 1,
      isActive: true,
      stops: [
        _getStop('stop_chanda_qila'),
        _getStop('stop_kangni_wala'),
        _getStop('stop_nigar_phatak'),
        _getStop('stop_sheikhupura_mor'),
        _getStop('stop_lari_adda'),
        _getStop('stop_pindi_bypass'),
        _getStop('stop_rahwali'),
        _getStop('stop_ghakhar'),
        _getStop('stop_rcet_campus'),
      ],
      polylinePoints: RouteRoadPolylines.route1Points,
    ),

    // Route No. 2 - Sheikhupura Mor via Sialkot Road (Hino Bus LEJ-6832)
    RouteModel(
      id: 'route_2',
      code: 'Route No. 2',
      title: 'Sheikhupura Mor via Sialkot Road',
      description: 'Hino Bus LEJ-6832 • Covers Sheranwala bagh, Gondlanwala Adda, Cricket Stadium, Katchery, Session Court & Sialkot Bypass.',
      estimatedDurationMinutes: 90,
      activeBusCount: 1,
      isActive: true,
      stops: [
        _getStop('stop_sheikhupura_mor'),
        _getStop('stop_sheranwala_bagh'),
        _getStop('stop_gondlanwala_adda'),
        _getStop('stop_cricket_stadium'),
        _getStop('stop_katchery'),
        _getStop('stop_dastagir_chowk'),
        _getStop('stop_session_court'),
        _getStop('stop_khokharki_hbl'),
        _getStop('stop_pakki_fattomand'),
        _getStop('stop_jagna'),
        _getStop('stop_sialkot_bypass'),
        _getStop('stop_board_office'),
        _getStop('stop_pindi_bypass'),
        _getStop('stop_ghakhar'),
        _getStop('stop_rcet_campus'),
      ],
      polylinePoints: RouteRoadPolylines.route2Points,
    ),

    // Route No. 3 - Sheikhupura Mor (Hino Bus GAX-4555)
    RouteModel(
      id: 'route_3',
      code: 'Route No. 3',
      title: 'Sheikhupura Mor via Lari Adda',
      description: 'Hino Bus GAX-4555 • Covers Sheranwala bagh, Old Railway Station, Gondlanwala Adda, Lari Adda, Sharifpura & Shaheenabad.',
      estimatedDurationMinutes: 70,
      activeBusCount: 1,
      isActive: true,
      stops: [
        _getStop('stop_sheikhupura_mor'),
        _getStop('stop_sheranwala_bagh'),
        _getStop('stop_old_railway'),
        _getStop('stop_gondlanwala_adda'),
        _getStop('stop_lari_adda'),
        _getStop('stop_sharifpura'),
        _getStop('stop_shaheenabad'),
        _getStop('stop_pindi_bypass'),
        _getStop('stop_rahwali'),
        _getStop('stop_ghakhar'),
        _getStop('stop_ojla_pull'),
        _getStop('stop_rcet_campus'),
      ],
      polylinePoints: RouteRoadPolylines.route3Points,
    ),

    // Route No. 4 - Pindi Bypass (Hino Bus LWN-3033)
    RouteModel(
      id: 'route_4',
      code: 'Route No. 4',
      title: 'Pindi Bypass Shuttle',
      description: 'Hino Bus LWN-3033 • Fast transit via DC Colony gate, Rahwali gate, Ghakhar Grid & Ojla Pull.',
      estimatedDurationMinutes: 60,
      activeBusCount: 1,
      isActive: true,
      stops: [
        _getStop('stop_pindi_bypass'),
        _getStop('stop_dc_colony'),
        _getStop('stop_rahwali_gate'),
        _getStop('stop_ghakhar_grid'),
        _getStop('stop_ghakhar'),
        _getStop('stop_ojla_pull'),
        _getStop('stop_rcet_campus'),
      ],
      polylinePoints: RouteRoadPolylines.route4Points,
    ),

    // Route No. 5 - Gujranwala Cantt (Hino Mini-Bus LEA-6834)
    RouteModel(
      id: 'route_5',
      code: 'Route No. 5',
      title: 'Gujranwala Cantt Express',
      description: 'Hino Mini-Bus LEA-6834 • Covers Check Post, Rahwali, Chenab gate, DHA, Ghakhar & Ojla Pull.',
      estimatedDurationMinutes: 40,
      activeBusCount: 1,
      isActive: true,
      stops: [
        _getStop('stop_check_post'),
        _getStop('stop_rahwali'),
        _getStop('stop_chenab_gate'),
        _getStop('stop_dha'),
        _getStop('stop_ghakhar'),
        _getStop('stop_ojla_pull'),
        _getStop('stop_rcet_campus'),
      ],
      polylinePoints: RouteRoadPolylines.route5Points,
    ),
  ];
}
