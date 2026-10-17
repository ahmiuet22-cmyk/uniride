/**
 * UniRide Admin Portal - Initial Seed Mock Data
 * Synchronized with UniRide Flutter Mobile App (UET RCET Gujranwala Campus)
 */

const INITIAL_ROUTES = [
  {
    id: "route_1",
    code: "Route No. 1",
    title: "Chanda Qila / Wapda Town",
    description: "Hino Bus GAU-2555 • Connecting route for transfer of students to/from KSK campus.",
    color: "#0A2240",
    estimatedDurationMinutes: 90,
    activeBusCount: 1,
    isActive: true,
    stops: [
      { id: "stop_chanda_qila", name: "Chanda Qila", timeMorning: "7:00 am", timeEvening: "04:15 PM", lat: 32.0950, lng: 74.1985 },
      { id: "stop_kangni_wala", name: "Kangni wala", timeMorning: "7:05 am", timeEvening: "04:25 PM", lat: 32.1158, lng: 74.1931 },
      { id: "stop_nigar_phatak", name: "Nigar Phatak", timeMorning: "7:10 am", timeEvening: "04:35 PM", lat: 32.1369, lng: 74.1946 },
      { id: "stop_sheikhupura_mor", name: "Sheikhupura Mor", timeMorning: "7:15 am", timeEvening: "04:45 PM", lat: 32.1494, lng: 74.1895 },
      { id: "stop_lari_adda", name: "Lari Adda", timeMorning: "7:30 am", timeEvening: "04:55 PM", lat: 32.1724, lng: 74.1839 },
      { id: "stop_pindi_bypass", name: "Pindi Bypass", timeMorning: "7:35 am", timeEvening: "05:05 PM", lat: 32.2030, lng: 74.1750 },
      { id: "stop_rahwali", name: "Rahwali", timeMorning: "7:45 am", timeEvening: "05:15 PM", lat: 32.2446, lng: 74.1642 },
      { id: "stop_ghakhar", name: "Ghakhar", timeMorning: "8:00 am", timeEvening: "05:25 PM", lat: 32.3042, lng: 74.1465 },
      { id: "stop_rcet_campus", name: "RCET Campus", timeMorning: "8:15 am", timeEvening: "05:45 PM", lat: 32.362339, lng: 74.208769 }
    ]
  },
  {
    id: "route_2",
    code: "Route No. 2",
    title: "Sheikhupura Mor via Sialkot Road",
    description: "Hino Bus LEJ-6832 • Covers Sheranwala bagh, Gondlanwala Adda, Cricket Stadium, Katchery, Session Court & Sialkot Bypass.",
    color: "#1D3E6E",
    estimatedDurationMinutes: 90,
    activeBusCount: 1,
    isActive: true,
    stops: [
      { id: "stop_sheikhupura_mor", name: "Sheikhupura Mor", timeMorning: "6:40 am", timeEvening: "04:10 PM", lat: 32.1494, lng: 74.1895 },
      { id: "stop_sheranwala_bagh", name: "Sheranwala bagh", timeMorning: "7:15 am", timeEvening: "04:20 PM", lat: 32.1550, lng: 74.1890 },
      { id: "stop_gondlanwala_adda", name: "Gondlanwala Adda", timeMorning: "7:20 am", timeEvening: "04:30 PM", lat: 32.1585, lng: 74.1830 },
      { id: "stop_cricket_stadium", name: "Cricket Stadium", timeMorning: "7:30 am", timeEvening: "04:40 PM", lat: 32.1636, lng: 74.1911 },
      { id: "stop_katchery", name: "Katchery", timeMorning: "7:32 am", timeEvening: "04:50 PM", lat: 32.1692, lng: 74.1970 },
      { id: "stop_dastagir_chowk", name: "Dastagir chowk", timeMorning: "7:34 am", timeEvening: "05:00 PM", lat: 32.1616, lng: 74.2101 },
      { id: "stop_session_court", name: "Session court/church", timeMorning: "7:37 am", timeEvening: "05:08 PM", lat: 32.1718, lng: 74.1983 },
      { id: "stop_khokharki_hbl", name: "Khokharki HBL stop", timeMorning: "7:40 am", timeEvening: "05:10 PM", lat: 32.1750, lng: 74.2005 },
      { id: "stop_pakki_fattomand", name: "Pakki Fattomand", timeMorning: "7:42 am", timeEvening: "05:14 PM", lat: 32.1836, lng: 74.2078 },
      { id: "stop_jagna", name: "Jagna", timeMorning: "7:45 am", timeEvening: "05:16 PM", lat: 32.1867, lng: 74.2144 },
      { id: "stop_sialkot_bypass", name: "Sialkot bypass", timeMorning: "7:50 am", timeEvening: "05:18 PM", lat: 32.2031, lng: 74.1970 },
      { id: "stop_board_office", name: "Board office", timeMorning: "7:55 am", timeEvening: "05:22 PM", lat: 32.2021, lng: 74.1880 },
      { id: "stop_pindi_bypass", name: "Pindi Bypass", timeMorning: "8:00 am", timeEvening: "05:25 PM", lat: 32.2030, lng: 74.1750 },
      { id: "stop_ghakhar", name: "Ghakhar", timeMorning: "8:10 am", timeEvening: "05:35 PM", lat: 32.3042, lng: 74.1465 },
      { id: "stop_rcet_campus", name: "RCET Campus", timeMorning: "8:20 am", timeEvening: "05:50 PM", lat: 32.362339, lng: 74.208769 }
    ]
  },
  {
    id: "route_3",
    code: "Route No. 3",
    title: "Sheikhupura Mor via Lari Adda",
    description: "Hino Bus GAX-4555 • Covers Sheranwala bagh, Old Railway Station, Gondlanwala Adda, Lari Adda, Sharifpura & Shaheenabad.",
    color: "#13335D",
    estimatedDurationMinutes: 70,
    activeBusCount: 1,
    isActive: true,
    stops: [
      { id: "stop_sheikhupura_mor", name: "Sheikhupura Mor", timeMorning: "6:50 am", timeEvening: "04:20 PM", lat: 32.1494, lng: 74.1895 },
      { id: "stop_sheranwala_bagh", name: "Sheranwala bagh", timeMorning: "7:00 am", timeEvening: "04:30 PM", lat: 32.1550, lng: 74.1890 },
      { id: "stop_old_railway", name: "Old Railway Station", timeMorning: "7:27 am", timeEvening: "04:40 PM", lat: 32.1767, lng: 74.1873 },
      { id: "stop_gondlanwala_adda", name: "Gondlanwala Adda", timeMorning: "7:20 am", timeEvening: "04:45 PM", lat: 32.1585, lng: 74.1830 },
      { id: "stop_lari_adda", name: "Lari Adda", timeMorning: "7:30 am", timeEvening: "04:50 PM", lat: 32.1724, lng: 74.1839 },
      { id: "stop_sharifpura", name: "Sharifpura", timeMorning: "7:38 am", timeEvening: "05:00 PM", lat: 32.1810, lng: 74.1805 },
      { id: "stop_shaheenabad", name: "Shaheenabad", timeMorning: "7:40 am", timeEvening: "05:10 PM", lat: 32.1915, lng: 74.1767 },
      { id: "stop_pindi_bypass", name: "Pindi Bypass", timeMorning: "7:50 am", timeEvening: "05:20 PM", lat: 32.2030, lng: 74.1750 },
      { id: "stop_rahwali", name: "Rahwali", timeMorning: "7:55 am", timeEvening: "05:25 PM", lat: 32.2446, lng: 74.1642 },
      { id: "stop_ghakhar", name: "Ghakhar", timeMorning: "8:05 am", timeEvening: "05:35 PM", lat: 32.3042, lng: 74.1465 },
      { id: "stop_ojla_pull", name: "Ojla Pull", timeMorning: "8:20 am", timeEvening: "05:45 PM", lat: 32.3364, lng: 74.1578 },
      { id: "stop_rcet_campus", name: "RCET Campus", timeMorning: "8:25 am", timeEvening: "05:50 PM", lat: 32.362339, lng: 74.208769 }
    ]
  },
  {
    id: "route_4",
    code: "Route No. 4",
    title: "Pindi Bypass Shuttle",
    description: "Hino Bus LWN-3033 • Fast transit via DC Colony gate, Rahwali gate, Ghakhar Grid & Ojla Pull.",
    color: "#1D3E6E",
    estimatedDurationMinutes: 60,
    activeBusCount: 1,
    isActive: true,
    stops: [
      { id: "stop_pindi_bypass", name: "Pindi Bypass", timeMorning: "7:35 am", timeEvening: "04:45 PM", lat: 32.2030, lng: 74.1750 },
      { id: "stop_dc_colony", name: "DC Colony gate", timeMorning: "7:45 am", timeEvening: "04:55 PM", lat: 32.2358, lng: 74.1670 },
      { id: "stop_rahwali_gate", name: "Rahwali gate", timeMorning: "7:50 am", timeEvening: "05:05 PM", lat: 32.2510, lng: 74.1550 },
      { id: "stop_ghakhar_grid", name: "Ghakhar Grid", timeMorning: "8:00 am", timeEvening: "05:20 PM", lat: 32.2940, lng: 74.1350 },
      { id: "stop_ghakhar", name: "Ghakhar", timeMorning: "8:05 am", timeEvening: "05:25 PM", lat: 32.3042, lng: 74.1465 },
      { id: "stop_ojla_pull", name: "Ojla Pull", timeMorning: "8:20 am", timeEvening: "05:35 PM", lat: 32.3364, lng: 74.1578 },
      { id: "stop_rcet_campus", name: "RCET Campus", timeMorning: "8:25 am", timeEvening: "05:50 PM", lat: 32.362339, lng: 74.208769 }
    ]
  },
  {
    id: "route_5",
    code: "Route No. 5",
    title: "Gujranwala Cantt Express",
    description: "Hino Mini-Bus LEA-6834 • Covers Check Post, Rahwali, Chenab gate, DHA, Ghakhar & Ojla Pull.",
    color: "#0A2240",
    estimatedDurationMinutes: 45,
    activeBusCount: 1,
    isActive: true,
    stops: [
      { id: "stop_check_post", name: "Check Post", timeMorning: "7:50 am", timeEvening: "04:50 PM", lat: 32.2451, lng: 74.1637 },
      { id: "stop_rahwali", name: "Rahwali", timeMorning: "7:45 am", timeEvening: "05:00 PM", lat: 32.2446, lng: 74.1642 },
      { id: "stop_chenab_gate", name: "Chenab gate", timeMorning: "8:00 am", timeEvening: "05:10 PM", lat: 32.2584, lng: 74.1434 },
      { id: "stop_dha", name: "DHA Gujranwala", timeMorning: "8:05 am", timeEvening: "05:20 PM", lat: 32.2856, lng: 74.1229 },
      { id: "stop_ghakhar", name: "Ghakhar", timeMorning: "8:00 am", timeEvening: "05:30 PM", lat: 32.3042, lng: 74.1465 },
      { id: "stop_ojla_pull", name: "Ojla Pull", timeMorning: "8:20 am", timeEvening: "05:40 PM", lat: 32.3364, lng: 74.1578 },
      { id: "stop_rcet_campus", name: "RCET Campus", timeMorning: "8:25 am", timeEvening: "05:45 PM", lat: 32.362339, lng: 74.208769 }
    ]
  }
];

const INITIAL_DRIVERS = [
  {
    id: "drv_01",
    name: "Muhammad Ali",
    phone: "+92 300 1234567",
    cnic: "34101-1234567-1",
    licenseNo: "GRW-78921-PSV",
    rating: 4.9,
    assignedBusId: "bus_gau_2555",
    pin: "1234",
    status: "Active",
    experienceYears: 12
  },
  {
    id: "drv_02",
    name: "Tariq Mehmood",
    phone: "+92 301 9876543",
    cnic: "34101-9876543-3",
    licenseNo: "GRW-44512-PSV",
    rating: 4.8,
    assignedBusId: "bus_lej_6832",
    pin: "2555",
    status: "Active",
    experienceYears: 9
  },
  {
    id: "drv_03",
    name: "Zubair Khan",
    phone: "+92 333 4567890",
    cnic: "34101-4567890-5",
    licenseNo: "LHR-88219-PSV",
    rating: 4.7,
    assignedBusId: "bus_gax_4555",
    pin: "4555",
    status: "Active",
    experienceYears: 7
  },
  {
    id: "drv_04",
    name: "Imran Hashmi",
    phone: "+92 345 5678901",
    cnic: "34101-5678901-7",
    licenseNo: "GRW-11029-PSV",
    rating: 4.9,
    assignedBusId: "bus_lwn_3033",
    pin: "3033",
    status: "Active",
    experienceYears: 14
  },
  {
    id: "drv_05",
    name: "Asif Butt",
    phone: "+92 321 7654321",
    cnic: "34101-7654321-9",
    licenseNo: "SKT-99302-PSV",
    rating: 4.8,
    assignedBusId: "bus_lea_6834",
    pin: "6834",
    status: "Active",
    experienceYears: 6
  }
];

const INITIAL_BUSES = [
  {
    id: "bus_gau_2555",
    name: "GAU-2555",
    model: "Hino Heavy Transit 52-Seater",
    routeId: "route_1",
    routeName: "Route No. 1 - Chanda Qila/Wapda Town",
    driverId: "drv_01",
    driverName: "Muhammad Ali",
    driverPhone: "+92 300 1234567",
    capacity: 52,
    currentPassengers: 0,
    status: "stopped",
    speed: 0.0,
    etaMinutes: 0,
    nextStop: "Standby at Chanda Qila",
    location: { lat: 32.0950, lng: 74.1985 },
    fuelLevel: 82,
    lastServiceDate: "2026-09-15"
  },
  {
    id: "bus_lej_6832",
    name: "LEJ-6832",
    model: "Hino Heavy Transit 52-Seater",
    routeId: "route_2",
    routeName: "Route No. 2 - Sheikhupura Mor via Sialkot Road",
    driverId: "drv_02",
    driverName: "Tariq Mehmood",
    driverPhone: "+92 301 9876543",
    capacity: 52,
    currentPassengers: 0,
    status: "stopped",
    speed: 0.0,
    etaMinutes: 0,
    nextStop: "Standby at Sheikhupura Mor",
    location: { lat: 32.1494, lng: 74.1895 },
    fuelLevel: 68,
    lastServiceDate: "2026-09-20"
  },
  {
    id: "bus_gax_4555",
    name: "GAX-4555",
    model: "Hino Heavy Transit 52-Seater",
    routeId: "route_3",
    routeName: "Route No. 3 - Sheikhupura Mor via Lari Adda",
    driverId: "drv_03",
    driverName: "Zubair Khan",
    driverPhone: "+92 333 4567890",
    capacity: 52,
    currentPassengers: 0,
    status: "stopped",
    speed: 0.0,
    etaMinutes: 0,
    nextStop: "Standby at Sheikhupura Mor",
    location: { lat: 32.1494, lng: 74.1895 },
    fuelLevel: 74,
    lastServiceDate: "2026-09-10"
  },
  {
    id: "bus_lwn_3033",
    name: "LWN-3033",
    model: "Hino Heavy Transit 52-Seater",
    routeId: "route_4",
    routeName: "Route No. 4 - Pindi Bypass Shuttle",
    driverId: "drv_04",
    driverName: "Imran Hashmi",
    driverPhone: "+92 345 5678901",
    capacity: 52,
    currentPassengers: 0,
    status: "stopped",
    speed: 0.0,
    etaMinutes: 0,
    nextStop: "Standby at Pindi Bypass",
    location: { lat: 32.2030, lng: 74.1750 },
    fuelLevel: 95,
    lastServiceDate: "2026-09-25"
  },
  {
    id: "bus_lea_6834",
    name: "LEA-6834",
    model: "Hino Coaster Mini 30-Seater",
    routeId: "route_5",
    routeName: "Route No. 5 - Gujranwala Cantt Express",
    driverId: "drv_05",
    driverName: "Asif Butt",
    driverPhone: "+92 321 7654321",
    capacity: 30,
    currentPassengers: 0,
    status: "stopped",
    speed: 0.0,
    etaMinutes: 0,
    nextStop: "Standby at Check Post",
    location: { lat: 32.2451, lng: 74.1637 },
    fuelLevel: 60,
    lastServiceDate: "2026-09-18"
  }
];

const INITIAL_TIMETABLES = [
  {
    id: "tt_01",
    shiftName: "Morning Shift (University Arrival)",
    routeId: "route_1",
    routeName: "Route No. 1 - Chanda Qila/Wapda Town",
    busId: "bus_gau_2555",
    busName: "GAU-2555",
    departureTime: "06:45 AM",
    arrivalTime: "08:15 AM",
    days: "Mon - Fri",
    status: "Scheduled"
  },
  {
    id: "tt_02",
    shiftName: "Morning Shift (University Arrival)",
    routeId: "route_2",
    routeName: "Route No. 2 - Sheikhupura Mor via Sialkot Road",
    busId: "bus_lej_6832",
    busName: "LEJ-6832",
    departureTime: "06:40 AM",
    arrivalTime: "08:20 AM",
    days: "Mon - Fri",
    status: "In Progress"
  },
  {
    id: "tt_03",
    shiftName: "Morning Shift (University Arrival)",
    routeId: "route_3",
    routeName: "Route No. 3 - Sheikhupura Mor via Lari Adda",
    busId: "bus_gax_4555",
    busName: "GAX-4555",
    departureTime: "06:50 AM",
    arrivalTime: "08:20 AM",
    days: "Mon - Fri",
    status: "In Progress"
  },
  {
    id: "tt_04",
    shiftName: "Morning Shift (University Arrival)",
    routeId: "route_4",
    routeName: "Route No. 4 - Pindi Bypass Shuttle",
    busId: "bus_lwn_3033",
    busName: "LWN-3033",
    departureTime: "07:15 AM",
    arrivalTime: "08:20 AM",
    days: "Mon - Fri",
    status: "Standby"
  },
  {
    id: "tt_05",
    shiftName: "Morning Shift (University Arrival)",
    routeId: "route_5",
    routeName: "Route No. 5 - Gujranwala Cantt Express",
    busId: "bus_lea_6834",
    busName: "LEA-6834",
    departureTime: "07:20 AM",
    arrivalTime: "08:15 AM",
    days: "Mon - Fri",
    status: "In Progress"
  },
  {
    id: "tt_06",
    shiftName: "Evening Return Shift (Departure from RCET)",
    routeId: "route_1",
    routeName: "Route No. 1 - Chanda Qila/Wapda Town",
    busId: "bus_gau_2555",
    busName: "GAU-2555",
    departureTime: "04:00 PM",
    arrivalTime: "05:30 PM",
    days: "Mon - Fri",
    status: "Scheduled"
  },
  {
    id: "tt_07",
    shiftName: "Evening Return Shift (Departure from RCET)",
    routeId: "route_2",
    routeName: "Route No. 2 - Sheikhupura Mor via Sialkot Road",
    busId: "bus_lej_6832",
    busName: "LEJ-6832",
    departureTime: "04:00 PM",
    arrivalTime: "05:35 PM",
    days: "Mon - Fri",
    status: "Scheduled"
  }
];

const INITIAL_ALERTS = [
  {
    id: "alt_01",
    title: "Route 2 Road Maintenance Alert",
    type: "warning", // warning | info | emergency
    message: "Sheranwala Bagh underpass maintenance. Expect 10-15 min delay for Route 2 morning arrival.",
    routeId: "route_2",
    timestamp: "2026-09-30 07:10 AM",
    sentBy: "Admin Control"
  },
  {
    id: "alt_02",
    title: "Campus Exam Schedule Transit Shift",
    type: "info",
    message: "Special return bus departs RCET at 02:00 PM on Friday for Mid-Term exam session.",
    routeId: "all",
    timestamp: "2026-09-29 02:30 PM",
    sentBy: "Transport Office"
  }
];
