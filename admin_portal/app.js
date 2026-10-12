/**
 * UniRide Admin Control Center - 100% Firebase Cloud Realtime Database
 * Direct Cloud CRUD for Buses, Routes, Timetables, Drivers & Alerts
 */

// Firebase Realtime Database Configuration
const FIREBASE_CONFIG = {
  dbUrl: 'https://uniride-app-79177-default-rtdb.firebaseio.com',
  isOnline: true
};

// Application State (Cleanly initialized on Cloud Connect)
const state = {
  routes: [],
  buses: [],
  drivers: [],
  timetables: [],
  alerts: [],
  specialShuttles: [],
  selectedSpecialPurpose: '🎓 Exam Special Departure',
  currentTab: 'overview',
  activeBusFilter: 'all',
  busSearchQuery: '',
  routeSearchQuery: '',
  map: null,
  mapMarkers: {},
  routePolylines: {},
  stopMarkers: [],
  simulationInterval: null,
  firebasePollInterval: null,
  editingBusId: null,
  editingRouteId: null,
  editingTimetableId: null,
  editingDriverId: null,
  isInitialLoaded: false
};

// Initialize App (Direct Cloud Sync with Loading Screen)
document.addEventListener('DOMContentLoaded', async () => {
  setupNavigation();
  setupSearchAndFilters();

  const statusText = document.getElementById('loaderStatusText');
  if (statusText) statusText.innerText = 'Loading Campus Fleet System...';

  // Seed default data first for instant UI response
  if (state.buses.length === 0 && typeof INITIAL_BUSES !== 'undefined') state.buses = [...INITIAL_BUSES];
  if (state.routes.length === 0 && typeof INITIAL_ROUTES !== 'undefined') state.routes = [...INITIAL_ROUTES];
  if (state.drivers.length === 0 && typeof INITIAL_DRIVERS !== 'undefined') state.drivers = [...INITIAL_DRIVERS];
  if (state.timetables.length === 0 && typeof INITIAL_TIMETABLES !== 'undefined') state.timetables = [...INITIAL_TIMETABLES];
  if (state.alerts.length === 0 && typeof INITIAL_ALERTS !== 'undefined') state.alerts = [...INITIAL_ALERTS];

  try {
    initLeafletMap();
  } catch (e) {
    console.warn('Map initialization notice:', e);
  }

  try {
    renderAll();
  } catch (e) {
    console.warn('Render notice:', e);
  }

  // Smoothly hide loader immediately
  const loader = document.getElementById('appLoader');
  if (loader) {
    loader.classList.add('hidden');
    setTimeout(() => { if (loader.parentNode) loader.remove(); }, 400);
  }
  state.isInitialLoaded = true;

  // Background Cloud Sync
  syncAllFromFirebase(true).then(() => {
    renderAll();
  }).catch(err => {
    console.warn('Initial cloud sync notice:', err);
  });

  startFirebasePolling();
});

// ==========================================================================
// Direct Firebase Cloud Operations
// ==========================================================================

// 1. Buses: Push & Delete
async function pushBusToFirebase(bus) {
  try {
    const lat = typeof bus.latitude === 'number' ? bus.latitude : (bus.location ? bus.location.lat : 32.0950);
    const lng = typeof bus.longitude === 'number' ? bus.longitude : (bus.location ? bus.location.lng : 74.1985);
    const isLive = bus.status === 'onRoute' || bus.status === 'approaching' || bus.is_live === true;
    const url = `${FIREBASE_CONFIG.dbUrl}/live_buses/${bus.id}.json`;
    await fetch(url, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        bus_id: bus.id,
        name: bus.name,
        model: bus.model || '',
        route_name: bus.routeName,
        route_id: bus.routeId,
        routeId: bus.routeId,
        routeName: bus.routeName,
        driver_name: bus.driverName,
        driver_phone: bus.driverPhone,
        driver_id: bus.driverId || '',
        is_live: isLive,
        status: bus.status,
        latitude: lat,
        longitude: lng,
        speed: bus.speed || 0.0,
        next_stop: bus.nextStop,
        eta_minutes: bus.etaMinutes || 0,
        is_special: bus.is_special || false,
        isSpecial: bus.is_special || false,
        specialPurpose: bus.specialPurpose || '',
        special_purpose: bus.specialPurpose || '',
        specialOrigin: bus.specialOrigin || '',
        specialDestination: bus.specialDestination || '',
        special_origin: bus.specialOrigin || '',
        special_destination: bus.specialDestination || '',
        last_updated: Date.now()
      })
    });
  } catch (err) {
    console.warn('Firebase push bus error:', err);
  }
}

async function deleteBusFromFirebase(busId) {
  try {
    const url = `${FIREBASE_CONFIG.dbUrl}/live_buses/${busId}.json`;
    await fetch(url, { method: 'DELETE' });
  } catch (err) {
    console.warn('Firebase delete bus error:', err);
  }
}

// 2. Routes: Push & Delete
async function pushRouteToFirebase(route) {
  try {
    const url = `${FIREBASE_CONFIG.dbUrl}/routes/${route.id}.json`;
    await fetch(url, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(route)
    });
  } catch (err) {
    console.warn('Firebase push route error:', err);
  }
}

async function deleteRouteFromFirebase(routeId) {
  try {
    const url = `${FIREBASE_CONFIG.dbUrl}/routes/${routeId}.json`;
    await fetch(url, { method: 'DELETE' });
  } catch (err) {
    console.warn('Firebase delete route error:', err);
  }
}

// 3. Timetables: Push & Delete
async function pushTimetableToFirebase(timetable) {
  try {
    const url = `${FIREBASE_CONFIG.dbUrl}/timetables/${timetable.id}.json`;
    await fetch(url, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(timetable)
    });
  } catch (err) {
    console.warn('Firebase push timetable error:', err);
  }
}

async function deleteTimetableFromFirebase(ttId) {
  try {
    const url = `${FIREBASE_CONFIG.dbUrl}/timetables/${ttId}.json`;
    await fetch(url, { method: 'DELETE' });
  } catch (err) {
    console.warn('Firebase delete timetable error:', err);
  }
}

// 4. Drivers: Push & Delete
async function pushDriverToFirebase(driver) {
  try {
    const url = `${FIREBASE_CONFIG.dbUrl}/drivers/${driver.id}.json`;
    await fetch(url, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(driver)
    });
  } catch (err) {
    console.warn('Firebase push driver error:', err);
  }
}

async function deleteDriverFromFirebase(drvId) {
  try {
    const url = `${FIREBASE_CONFIG.dbUrl}/drivers/${drvId}.json`;
    await fetch(url, { method: 'DELETE' });
  } catch (err) {
    console.warn('Firebase delete driver error:', err);
  }
}

// 5. Alerts: Push & Delete
async function pushAlertToFirebase(alert) {
  try {
    const url = `${FIREBASE_CONFIG.dbUrl}/alerts/${alert.id}.json`;
    await fetch(url, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(alert)
    });
  } catch (err) {
    console.warn('Firebase push alert error:', err);
  }
}

async function deleteAlertFromFirebase(altId) {
  try {
    const url = `${FIREBASE_CONFIG.dbUrl}/alerts/${altId}.json`;
    await fetch(url, { method: 'DELETE' });
  } catch (err) {
    console.warn('Firebase delete alert error:', err);
  }
}

// 6. Special Shuttles: Push & Delete
async function pushSpecialShuttleToFirebase(shuttle) {
  try {
    const url = `${FIREBASE_CONFIG.dbUrl}/special_shuttles/${shuttle.id}.json`;
    await fetch(url, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(shuttle)
    });
  } catch (err) {
    console.warn('Firebase push special shuttle error:', err);
  }

  // Backup sync to /alerts (guaranteed open in Firebase RTDB Rules)
  try {
    const backupUrl = `${FIREBASE_CONFIG.dbUrl}/alerts/${shuttle.id}.json`;
    await fetch(backupUrl, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        ...shuttle,
        is_special_shuttle: true,
        type: 'special_shuttle',
        title: `⚡ Special Bus: ${shuttle.busName}`,
        message: `${shuttle.purpose} | Route: ${shuttle.route || shuttle.destination} | Time: ${shuttle.startTime} – ${shuttle.endTime}`,
        description: `${shuttle.purpose} | Route: ${shuttle.route || shuttle.destination} | Time: ${shuttle.startTime} – ${shuttle.endTime}`,
        timestamp: new Date().toISOString()
      })
    });
  } catch (_) {}
}

async function deleteSpecialShuttleFromFirebase(shuttleId) {
  try {
    const url = `${FIREBASE_CONFIG.dbUrl}/special_shuttles/${shuttleId}.json`;
    await fetch(url, { method: 'DELETE' });
  } catch (err) {
    console.warn('Firebase delete special shuttle error:', err);
  }
  try {
    const backupUrl = `${FIREBASE_CONFIG.dbUrl}/alerts/${shuttleId}.json`;
    await fetch(backupUrl, { method: 'DELETE' });
  } catch (_) {}
}

// Automatically broadcast real-time campus notice to Mobile App & Web
async function broadcastSystemAlert({ title, message, type = 'info', routeId = null, busId = null }) {
  const alertId = `alt_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
  const newAlert = {
    id: alertId,
    title: title,
    description: message,
    message: message,
    type: type,
    category: type,
    routeId: routeId,
    relatedRouteId: routeId,
    relatedBusId: busId,
    timestamp: new Date().toISOString(),
    isRead: false,
    sentBy: 'Transit HQ'
  };
  state.alerts.unshift(newAlert);
  await pushAlertToFirebase(newAlert);
  renderAll();
}

// Helper to get starting stop of a route
function getRouteStartStop(routeId) {
  const route = state.routes.find(r => r.id === routeId) || INITIAL_ROUTES.find(r => r.id === routeId);
  if (route && route.stops && route.stops.length > 0) {
    return route.stops[0];
  }
  return { name: 'Terminal Standby', lat: 32.2030, lng: 74.1750 };
}

// Fetch All Collections from Firebase Realtime Database
async function syncAllFromFirebase() {
  try {
    // 1. Fetch Buses
    const busesRes = await fetch(`${FIREBASE_CONFIG.dbUrl}/live_buses.json`, { cache: 'no-store' });
    if (busesRes.ok) {
      const busesData = await busesRes.json();
      if (busesData && typeof busesData === 'object') {
        const loadedBuses = [];
        const seenIds = new Set();

        Object.keys(busesData).forEach(id => {
          const item = busesData[id];
          if (item) {
            const busId = item.bus_id || id;
            seenIds.add(busId);
            const initialMatch = INITIAL_BUSES.find(b => b.id === busId) || {};

            // Accurate Live Detection: is_live flag or active status
            const isLive = item.is_live === true || item.status === 'onRoute' || item.status === 'approaching';
            const routeStart = getRouteStartStop(item.route_id || initialMatch.routeId || 'route_1');

            // Preserve real live coordinates from Firebase GPS telemetry
            let busLat = (typeof item.latitude === 'number' && !isNaN(item.latitude) && item.latitude !== 0)
              ? item.latitude
              : (initialMatch.location?.lat || routeStart.lat);
            let busLng = (typeof item.longitude === 'number' && !isNaN(item.longitude) && item.longitude !== 0)
              ? item.longitude
              : (initialMatch.location?.lng || routeStart.lng);

            let busStatus = item.status || (isLive ? 'onRoute' : (initialMatch.status || 'stopped'));
            let busSpeed = typeof item.speed === 'number' ? item.speed : (initialMatch.speed || 0.0);
            let busNextStop = item.next_stop || (isLive ? 'En Route to Next Stop' : (initialMatch.nextStop || `Standby at ${routeStart.name}`));
            let busEta = typeof item.eta_minutes === 'number' ? item.eta_minutes : (initialMatch.etaMinutes || 0);

            loadedBuses.push({
              id: busId,
              name: item.name || initialMatch.name || id,
              model: item.model || initialMatch.model || 'Hino Heavy Transit',
              routeId: item.route_id || initialMatch.routeId || 'route_1',
              routeName: item.route_name || initialMatch.routeName || 'Campus Transit',
              driverId: item.driver_id || initialMatch.driverId || '',
              driverName: item.driver_name || initialMatch.driverName || 'Driver',
              driverPhone: item.driver_phone || initialMatch.driverPhone || '',
              capacity: item.capacity || initialMatch.capacity || 52,
              currentPassengers: item.current_passengers || initialMatch.currentPassengers || 0,
              fuelLevel: item.fuel_level || initialMatch.fuelLevel || 80,
              lastServiceDate: item.last_service_date || initialMatch.lastServiceDate || '2026-09-15',
              status: busStatus,
              speed: busSpeed,
              etaMinutes: busEta,
              nextStop: busNextStop,
              isLive: isLive,
              lastUpdated: item.last_updated || Date.now(),
              location: {
                lat: busLat,
                lng: busLng
              }
            });
          }
        });

        // Retain initial buses not yet seeded in Firebase
        INITIAL_BUSES.forEach(ib => {
          if (!seenIds.has(ib.id)) {
            loadedBuses.push({ ...ib });
          }
        });

        if (loadedBuses.length > 0) {
          state.buses = loadedBuses;
        }
      } else {
        if (state.buses.length === 0) state.buses = [...INITIAL_BUSES];
      }
    } else {
      if (state.buses.length === 0) state.buses = [...INITIAL_BUSES];
    }

    // 2. Fetch Routes
    const routesRes = await fetch(`${FIREBASE_CONFIG.dbUrl}/routes.json`, { cache: 'no-store' });
    if (routesRes.ok) {
      const routesData = await routesRes.json();
      if (routesData && typeof routesData === 'object') {
        const loadedRoutes = Object.values(routesData).filter(Boolean);
        if (loadedRoutes.length > 0) {
          state.routes = loadedRoutes;
        } else {
          state.routes = [...INITIAL_ROUTES];
          state.routes.forEach(r => pushRouteToFirebase(r));
        }
      } else {
        state.routes = [...INITIAL_ROUTES];
        state.routes.forEach(r => pushRouteToFirebase(r));
      }
    } else {
      if (state.routes.length === 0) state.routes = [...INITIAL_ROUTES];
    }

    // 3. Fetch Drivers
    const driversRes = await fetch(`${FIREBASE_CONFIG.dbUrl}/drivers.json`, { cache: 'no-store' });
    if (driversRes.ok) {
      const driversData = await driversRes.json();
      if (driversData && typeof driversData === 'object') {
        const loadedDrivers = Object.values(driversData).filter(Boolean);
        if (loadedDrivers.length > 0) {
          state.drivers = loadedDrivers;
        } else {
          state.drivers = [...INITIAL_DRIVERS];
          state.drivers.forEach(d => pushDriverToFirebase(d));
        }
      } else {
        state.drivers = [...INITIAL_DRIVERS];
        state.drivers.forEach(d => pushDriverToFirebase(d));
      }
    } else {
      if (state.drivers.length === 0) state.drivers = [...INITIAL_DRIVERS];
    }

    // 4. Fetch Timetables
    const ttRes = await fetch(`${FIREBASE_CONFIG.dbUrl}/timetables.json`, { cache: 'no-store' });
    if (ttRes.ok) {
      const ttData = await ttRes.json();
      if (ttData && typeof ttData === 'object') {
        const loadedTt = Object.values(ttData).filter(Boolean);
        if (loadedTt.length > 0) {
          state.timetables = loadedTt;
        } else {
          state.timetables = [...INITIAL_TIMETABLES];
          state.timetables.forEach(t => pushTimetableToFirebase(t));
        }
      } else {
        state.timetables = [...INITIAL_TIMETABLES];
        state.timetables.forEach(t => pushTimetableToFirebase(t));
      }
    } else {
      if (state.timetables.length === 0) state.timetables = [...INITIAL_TIMETABLES];
    }

    // 5. Fetch Alerts
    const alertsRes = await fetch(`${FIREBASE_CONFIG.dbUrl}/alerts.json`, { cache: 'no-store' });
    if (alertsRes.ok) {
      const alertsData = await alertsRes.json();
      if (alertsData && typeof alertsData === 'object') {
        const loadedAlerts = Object.values(alertsData).filter(Boolean);
        if (loadedAlerts.length > 0) {
          state.alerts = loadedAlerts;
        } else {
          state.alerts = [...INITIAL_ALERTS];
          state.alerts.forEach(a => pushAlertToFirebase(a));
        }
      } else {
        state.alerts = [...INITIAL_ALERTS];
        state.alerts.forEach(a => pushAlertToFirebase(a));
      }
    } else {
      if (state.alerts.length === 0) state.alerts = [...INITIAL_ALERTS];
    }

    // 6. Fetch Special Shuttles (Ephemeral / Auto-expiring runs)
    try {
      const specRes = await fetch(`${FIREBASE_CONFIG.dbUrl}/special_shuttles.json`, { cache: 'no-store' });
      if (specRes.ok) {
        const specData = await specRes.json();
        if (specData && typeof specData === 'object') {
          state.specialShuttles = Object.values(specData).filter(Boolean);
        }
      } else {
        // Fallback to /alerts node (which is open in Firebase Rules)
        const alertsRes = await fetch(`${FIREBASE_CONFIG.dbUrl}/alerts.json`, { cache: 'no-store' });
        if (alertsRes.ok) {
          const alertsData = await alertsRes.json();
          if (alertsData && typeof alertsData === 'object') {
            const list = Object.values(alertsData).filter(item => item && (item.is_special_shuttle || (item.id && item.id.startsWith('spec_'))));
            if (list.length > 0) state.specialShuttles = list;
          }
        }
      }
    } catch (e) {
      console.warn('Special shuttles sync notice:', e);
    }
    checkSpecialShuttlesExpiry();

    updateMapMarkers();
    drawRoutePolylines();
    renderAll();
  } catch (err) {
    console.warn('Firebase sync offline fallback:', err);
    if (state.buses.length === 0) state.buses = [...INITIAL_BUSES];
    if (state.routes.length === 0) state.routes = [...INITIAL_ROUTES];
    if (state.drivers.length === 0) state.drivers = [...INITIAL_DRIVERS];
    if (state.timetables.length === 0) state.timetables = [...INITIAL_TIMETABLES];
    if (state.alerts.length === 0) state.alerts = [...INITIAL_ALERTS];
    updateMapMarkers();
    drawRoutePolylines();
    renderAll();
  }
}

function startFirebasePolling() {
  if (state.firebasePollInterval) clearInterval(state.firebasePollInterval);
  state.firebasePollInterval = setInterval(syncAllFromFirebase, 3000);
}

// ==========================================================================
// Navigation & Tabs
// ==========================================================================
function setupNavigation() {
  const navItems = document.querySelectorAll('.nav-item[data-tab]');
  navItems.forEach(item => {
    item.addEventListener('click', (e) => {
      e.preventDefault();
      const tabId = item.getAttribute('data-tab');
      switchTab(tabId);
    });
  });
}

function switchTab(tabId) {
  state.currentTab = tabId;

  document.querySelectorAll('.nav-item[data-tab]').forEach(el => {
    el.classList.toggle('active', el.getAttribute('data-tab') === tabId);
  });

  document.querySelectorAll('.tab-pane').forEach(el => {
    el.classList.toggle('active', el.id === `tab-${tabId}`);
  });

  const titles = {
    overview: { title: 'Fleet Control Center', desc: 'Real-time telemetry and campus transport monitoring' },
    buses: { title: 'Manage Fleet Buses', desc: 'Add, update registration, inspect status & assign drivers' },
    routes: { title: 'Routes & Stop Networks', desc: 'Configure university routes, pickup stops & timetables' },
    timetables: { title: 'Timetable Schedules', desc: 'Shift timings, morning arrivals and evening return drops' },
    'special-shuttle': { title: 'Special Shuttle Dispatch', desc: 'Temporary, on-demand campus transit with auto-expiry' },
    drivers: { title: 'Transport Staff & Drivers', desc: 'Driver directory, licenses, contact & ratings' },
    alerts: { title: 'Campus Broadcast Alerts', desc: 'Dispatch route delays, bad weather & exam notifications' },
    settings: { title: 'System Settings & Sync', desc: 'Export fleet data, reset demo data, manage university config' }
  };

  const meta = titles[tabId] || titles.overview;
  document.getElementById('topbarPageTitle').innerText = meta.title;
  document.getElementById('topbarPageSubtitle').innerText = meta.desc;

  if (tabId === 'overview' && state.map) {
    setTimeout(() => state.map.invalidateSize(), 200);
  }
}

// Setup Real-time Search and Filtering
function setupSearchAndFilters() {
  const busSearchInput = document.getElementById('busSearchInput');
  if (busSearchInput) {
    busSearchInput.addEventListener('input', (e) => {
      state.busSearchQuery = e.target.value.toLowerCase();
      renderBusesTable();
    });
  }

  const busStatusFilter = document.getElementById('busStatusFilter');
  if (busStatusFilter) {
    busStatusFilter.addEventListener('change', (e) => {
      state.activeBusFilter = e.target.value;
      renderBusesTable();
    });
  }

  const routeSearchInput = document.getElementById('routeSearchInput');
  if (routeSearchInput) {
    routeSearchInput.addEventListener('input', (e) => {
      state.routeSearchQuery = e.target.value.toLowerCase();
      renderRoutesGrid();
    });
  }
}

// ==========================================================================
// Render Functions
// ==========================================================================
function renderAll() {
  renderOverviewKPIs();
  renderLiveBusList();
  renderBusesTable();
  renderRoutesGrid();
  renderTimetablesTable();
  renderDriversGrid();
  renderAlertsList();
  renderSpecialShuttles();
  updateNavCounters();
  populateDropdownOptions();
  renderMapRouteFilterBar();
  updateMapMarkers();
}

function updateNavCounters() {
  document.getElementById('navBusCount').innerText = state.buses.length;
  document.getElementById('navRouteCount').innerText = state.routes.length;
  document.getElementById('navDriverCount').innerText = state.drivers.length;
  document.getElementById('navAlertCount').innerText = state.alerts.length;

  const activeSpecialCount = state.specialShuttles.filter(s => s.status === 'active').length;
  const navSpecialEl = document.getElementById('navSpecialShuttleCount');
  if (navSpecialEl) navSpecialEl.innerText = activeSpecialCount;
  const headerSpecialEl = document.getElementById('activeShuttlesHeaderCount');
  if (headerSpecialEl) headerSpecialEl.innerText = activeSpecialCount;
}

// 1. Overview KPIs
function renderOverviewKPIs() {
  const activeBuses = state.buses.filter(b => b.status === 'onRoute' || b.status === 'approaching').length;
  const totalBuses = state.buses.length;
  const totalRoutes = state.routes.length;
  const totalDrivers = state.drivers.length;

  document.getElementById('kpiActiveBuses').innerText = `${activeBuses} / ${totalBuses}`;
  document.getElementById('kpiActiveBusesSub').innerText = `${Math.round((activeBuses / (totalBuses || 1)) * 100)}% fleet active on road`;
  document.getElementById('kpiTotalRoutes').innerText = totalRoutes;
  document.getElementById('kpiActiveDrivers').innerText = totalDrivers;
}

/// 2. Live Bus Movement List in Overview
function renderLiveBusList() {
  const container = document.getElementById('overviewLiveBusList');
  if (!container) return;

  container.innerHTML = state.buses.map(bus => {
    const isStandby = bus.status === 'stopped' || bus.status === 'maintenance';
    const statusClass = `badge-${bus.status}`;
    const statusText = bus.status === 'onRoute' ? 'Live On Route' :
      bus.status === 'approaching' ? 'Approaching Stop' :
        bus.status === 'stopped' ? 'Standby (Location Off)' : 'Maintenance';

    const speedDisplay = isStandby ? '0.0 km/h' : `${typeof bus.speed === 'number' ? bus.speed.toFixed(1) : bus.speed} km/h`;
    const etaDisplay = isStandby ? 'Parked at Terminal' : `ETA ~${bus.etaMinutes}m`;

    return `
      <div class="live-bus-item ${isStandby ? 'standby-item' : ''}" onclick="focusBusOnMap('${bus.id}')">
        <div class="bus-meta-main">
          <span class="bus-tag-badge" style="${isStandby ? 'opacity:0.65;' : ''}">${bus.name}</span>
          <div class="bus-info-text">
            <h4>${bus.routeName}</h4>
            <p>${isStandby ? '🅿️ ' : '📍 Next: '}<strong>${bus.nextStop || 'Starting Terminal'}</strong> • Driver: ${bus.driverName}</p>
          </div>
        </div>
        <div class="bus-metrics-pill">
          <div class="speed-val" style="${isStandby ? 'color:var(--text-muted);' : ''}">${speedDisplay}</div>
          <div class="eta-val" style="${isStandby ? 'font-size:10px;' : ''}">${etaDisplay}</div>
          <span class="badge ${statusClass}" style="margin-top:4px; font-size:10px;">${statusText}</span>
        </div>
      </div>
    `;
  }).join('');
}

// 3. Buses Table in Manage Buses Tab
function renderBusesTable() {
  const tbody = document.getElementById('busesTableBody');
  if (!tbody) return;

  const filtered = state.buses.filter(bus => {
    const matchesFilter = state.activeBusFilter === 'all' || bus.status === state.activeBusFilter;
    const matchesSearch = !state.busSearchQuery ||
      bus.name.toLowerCase().includes(state.busSearchQuery) ||
      bus.routeName.toLowerCase().includes(state.busSearchQuery) ||
      bus.driverName.toLowerCase().includes(state.busSearchQuery);
    return matchesFilter && matchesSearch;
  });

  if (filtered.length === 0) {
    tbody.innerHTML = `
      <tr>
        <td colspan="6" style="text-align:center; padding: 36px; color: var(--text-muted);">
          No buses found matching your filter or search query.
        </td>
      </tr>
    `;
    return;
  }

  tbody.innerHTML = filtered.map(bus => {
    const isStandby = bus.status === 'stopped' || bus.status === 'maintenance';
    const statusBadge = `
      <span class="badge badge-${bus.status}">
        <span class="pulse-dot" style="width:7px; height:7px; background:${bus.status === 'onRoute' ? 'var(--primary-navy)' : bus.status === 'approaching' ? 'var(--uet-gold)' : 'var(--text-muted)'}"></span>
        ${bus.status === 'onRoute' ? 'On Route' : bus.status === 'approaching' ? 'Approaching' : bus.status === 'stopped' ? 'Standby' : 'Maintenance'}
      </span>
    `;

    const speedDisplay = isStandby ? '0.0 km/h' : `${typeof bus.speed === 'number' ? bus.speed.toFixed(1) : bus.speed} km/h`;

    return `
      <tr>
        <td>
          <div style="display:flex; align-items:center; gap:10px;">
            <span class="bus-tag-badge">${bus.name}</span>
            <div>
              <strong style="color:var(--text-primary); font-size:13.5px;">${bus.name}</strong>
              <div style="font-size:11.5px; color:var(--text-muted);">${bus.model || 'Hino Transit'}</div>
            </div>
          </div>
        </td>
        <td>
          <span style="display:inline-block; font-weight:600; color:var(--primary-navy); background:var(--ice-blue); border:1px solid var(--border-color); padding:4px 10px; border-radius:6px; font-size:12px;">
            ${bus.routeName}
          </span>
        </td>
        <td>
          <div style="display:flex; align-items:center; gap:8px;">
            <div style="width:28px; height:28px; border-radius:50%; background:var(--uet-gold); color:var(--primary-navy); display:flex; align-items:center; justify-content:center; font-weight:700; font-size:11px;">
              ${bus.driverName.charAt(0)}
            </div>
            <div>
              <strong style="font-size:13px; color:var(--text-primary);">${bus.driverName}</strong>
              <div style="font-size:11px; color:var(--text-secondary);">${bus.driverPhone}</div>
            </div>
          </div>
        </td>
        <td>${statusBadge}</td>
        <td>
          <strong style="color:${isStandby ? 'var(--text-muted)' : 'var(--primary-navy)'};">${speedDisplay}</strong>
          <div style="font-size:11.5px; color:var(--secondary-navy); font-weight:600;">${isStandby ? '🅿️ ' : 'Next: '}${bus.nextStop || 'Route Start'}</div>
        </td>
        <td>
          <div class="action-btns">
            <button class="btn-table-icon" title="Edit Bus Profile" onclick="openEditBusModal('${bus.id}')">✏️</button>
            <button class="btn-table-icon" title="Track Live on Map" onclick="switchTab('overview'); setTimeout(() => focusBusOnMap('${bus.id}'), 300)">📍</button>
            <button class="btn-table-icon delete" title="Delete Bus" onclick="deleteBus('${bus.id}')">🗑️</button>
          </div>
        </td>
      </tr>
    `;
  }).join('');
}

// 4. Routes Grid in Manage Routes Tab
function renderRoutesGrid() {
  const container = document.getElementById('routesCardGrid');
  if (!container) return;

  const filtered = state.routes.filter(r => {
    if (!state.routeSearchQuery) return true;
    return r.title.toLowerCase().includes(state.routeSearchQuery) ||
      r.code.toLowerCase().includes(state.routeSearchQuery) ||
      r.description.toLowerCase().includes(state.routeSearchQuery);
  });

  if (filtered.length === 0) {
    container.innerHTML = `
      <div style="grid-column: 1/-1; text-align:center; padding: 48px; color: var(--text-muted);">
        No routes match your search.
      </div>
    `;
    return;
  }

  container.innerHTML = filtered.map(route => {
    const stopsHtml = (route.stops || []).map((s, idx) => `
      <span class="stop-pill" title="Stop #${idx + 1}: ${s.name} (🌅 ${s.timeMorning || 'N/A'} • 🌇 ${s.timeEvening || 'N/A'})">
        <strong style="color:var(--uet-gold); margin-right:4px;">${idx + 1}.</strong>${s.name}
      </span>
    `).join('');
    const assignedBuses = state.buses.filter(b => b.routeId === route.id);

    return `
      <div class="route-card" style="border-top: 4px solid ${route.color || 'var(--primary-navy)'};">
        <div>
          <div class="route-header">
            <span class="route-badge-code" style="background:${route.color || 'var(--primary-navy)'};">${route.code}</span>
            <span style="font-size:12px; font-weight:600; color:var(--text-secondary);">⏱️ ~${route.estimatedDurationMinutes} mins</span>
          </div>
          <h3 class="route-title">${route.title}</h3>
          <p class="route-desc">${route.description}</p>
          
          <div class="route-stops-preview">
            <div class="stops-count-row">
              <span>📍 Route Stops (${(route.stops || []).length})</span>
              <span>🚌 ${assignedBuses.length} Bus Assigned</span>
            </div>
            <div class="stop-pill-list">
              ${stopsHtml || '<span style="font-size:11.5px; color:var(--text-muted);">No stops defined yet.</span>'}
            </div>
          </div>
        </div>

        <div style="display:flex; align-items:center; justify-content:space-between; margin-top:16px; border-top:1px solid var(--border-color); padding-top:12px;">
          <div style="font-size:11.5px; color:var(--text-secondary);">
            First pickup: <strong>${route.stops && route.stops.length ? route.stops[0].timeMorning || '06:45 AM' : '06:45 AM'}</strong>
          </div>
          <div class="action-btns">
            <button class="btn btn-secondary btn-sm" onclick="openEditRouteModal('${route.id}')">✏️ Edit Route & Stops</button>
            <button class="btn btn-danger-ghost btn-sm" onclick="deleteRoute('${route.id}')">Delete</button>
          </div>
        </div>
      </div>
    `;
  }).join('');
}

// 5. Timetables Table
function renderTimetablesTable() {
  const tbody = document.getElementById('timetablesTableBody');
  if (!tbody) return;

  tbody.innerHTML = state.timetables.map(item => `
    <tr>
      <td><strong>${item.shiftName}</strong></td>
      <td><span style="font-weight:600; color:var(--primary-navy);">${item.routeName}</span></td>
      <td><span class="bus-tag-badge">${item.busName}</span></td>
      <td><strong style="color:var(--secondary-navy);">${item.departureTime}</strong></td>
      <td><strong style="color:var(--primary-navy);">${item.arrivalTime}</strong></td>
      <td>${item.days}</td>
      <td>
        <span class="badge ${item.status === 'In Progress' ? 'badge-onRoute' : 'badge-stopped'}">
          ${item.status}
        </span>
      </td>
      <td>
        <div class="action-btns">
          <button class="btn-table-icon" onclick="openEditTimetableModal('${item.id}')">✏️</button>
          <button class="btn-table-icon delete" onclick="deleteTimetable('${item.id}')">🗑️</button>
        </div>
      </td>
    </tr>
  `).join('');
}

// 6. Drivers Grid
function renderDriversGrid() {
  const container = document.getElementById('driversCardGrid');
  if (!container) return;

  container.innerHTML = state.drivers.map((drv) => {
    const assignedBus = state.buses.find(b => b.id === drv.assignedBusId);

    return `
      <div class="card" style="padding:22px;">
        <div style="display:flex; align-items:center; gap:14px; margin-bottom:14px;">
          <div class="admin-avatar" style="width:46px; height:46px; font-size:16px;">
            ${drv.name.split(' ').map(n=>n[0]).join('')}
          </div>
          <div>
            <h3 style="font-size:16px; font-weight:700; color:var(--primary-navy);">${drv.name}</h3>
            <p style="font-size:12px; color:var(--text-secondary);">📞 ${drv.phone}</p>
          </div>
          <span class="badge badge-approaching" style="margin-left:auto;">⭐ ${drv.rating || 4.9}</span>
        </div>

        <div style="background:var(--ice-blue); padding:12px; border-radius:var(--radius-md); font-size:12px; margin-bottom:14px; border:1px solid var(--border-color);">
          <div style="display:flex; justify-content:space-between; margin-bottom:4px;">
            <span style="color:var(--text-secondary);">License No:</span>
            <strong>${drv.licenseNo || 'GRW-12345-PSV'}</strong>
          </div>
          <div style="display:flex; justify-content:space-between; margin-bottom:4px;">
            <span style="color:var(--text-secondary);">CNIC:</span>
            <strong>${drv.cnic || '34101-*******-1'}</strong>
          </div>
          <div style="display:flex; justify-content:space-between;">
            <span style="color:var(--text-secondary);">Assigned Vehicle:</span>
            <span class="bus-tag-badge" style="font-size:10.5px; padding:2px 7px;">${assignedBus ? assignedBus.name : 'Unassigned'}</span>
          </div>
        </div>

        <div style="display:flex; justify-content:flex-end; gap:8px;">
          <button class="btn btn-secondary btn-sm" onclick="openEditDriverModal('${drv.id}')">Edit Profile</button>
          <button class="btn btn-danger-ghost btn-sm" onclick="deleteDriver('${drv.id}')">Remove</button>
        </div>
      </div>
    `;
  }).join('');
}

// 7. Alerts List
function renderAlertsList() {
  const container = document.getElementById('alertsListContainer');
  if (!container) return;

  if (state.alerts.length === 0) {
    container.innerHTML = `
      <div style="text-align:center; padding:40px; color:var(--text-muted);">
        No active broadcast alerts currently.
      </div>
    `;
    return;
  }

  container.innerHTML = state.alerts.map(alt => {
    const targetText = (!alt.routeId || alt.routeId === 'all')
      ? 'All University Routes'
      : String(alt.routeId).toUpperCase();
    const titleText = escapeHtml(alt.title || 'Campus Alert');
    const msgText = escapeHtml(alt.message || alt.description || '');
    const timeText = escapeHtml(alt.timestamp || '');
    const sentByText = escapeHtml(alt.sentBy || 'Transit HQ');

    return `
      <div class="card" style="padding:18px 22px; border-left: 5px solid var(--primary-navy); margin-bottom:14px;">
        <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom:6px;">
          <h4 style="font-size:15px; font-weight:700; color:var(--primary-navy);">${titleText}</h4>
          <span style="font-size:11px; color:var(--text-muted);">${timeText}</span>
        </div>
        <p style="font-size:13px; color:var(--text-secondary); margin-bottom:10px;">${msgText}</p>
        <div style="display:flex; align-items:center; justify-content:space-between; font-size:11.5px;">
          <span style="color:var(--text-muted);">Target: <strong>${targetText}</strong> • By ${sentByText}</span>
          <button class="btn-danger-ghost btn-sm" style="padding:3px 8px;" onclick="deleteAlert('${alt.id}')">Dismiss Alert</button>
        </div>
      </div>
    `;
  }).join('');
}

// Populate Modal Select Dropdowns (Preserves user selection during live cloud polling)
function populateDropdownOptions() {
  const routeSelects = document.querySelectorAll('.route-select-populate');
  routeSelects.forEach(select => {
    const curVal = select.value;
    select.innerHTML = state.routes.map(r => `<option value="${r.id}">${r.code} - ${r.title}</option>`).join('');
    if (curVal) select.value = curVal;
  });

  const driverSelects = document.querySelectorAll('.driver-select-populate');
  driverSelects.forEach(select => {
    const curVal = select.value;
    select.innerHTML = state.drivers.map(d => `<option value="${d.id}">${d.name} (${d.phone})</option>`).join('');
    if (curVal) select.value = curVal;
  });

  const busSelects = document.querySelectorAll('.bus-select-populate');
  busSelects.forEach(select => {
    const curVal = select.value;
    select.innerHTML = state.buses.map(b => `<option value="${b.id}">${b.name} (${b.routeName})</option>`).join('');
    if (curVal) select.value = curVal;
  });

  const specialBusSelect = document.getElementById('specialBusSelect');
  if (specialBusSelect) {
    const curVal = specialBusSelect.value;
    specialBusSelect.innerHTML = `<option value="">-- Choose Available Fleet Bus --</option>` +
      state.buses.map(b => `<option value="${b.id}">${b.name} (${b.model || 'Bus'} • Driver: ${b.driverName || 'None'} • Status: ${b.status})</option>`).join('');
    if (curVal) specialBusSelect.value = curVal;
  }

  const specialRouteSelect = document.getElementById('specialRouteSelect');
  if (specialRouteSelect) {
    const curVal = specialRouteSelect.value;
    specialRouteSelect.innerHTML = `<option value="custom">🌐 Custom Destination / Flexible Route</option>` +
      state.routes.map(r => `<option value="${r.id}">${r.code} - ${r.title}</option>`).join('');
    if (curVal) specialRouteSelect.value = curVal;
  }
}

// ==========================================================================
// Interactive Leaflet Map (Matched to Flutter Mobile App)
// ==========================================================================
state.mapLayerType = 'streets';
state.activeRouteFilter = 'all';
state.baseTileLayer = null;
state.overlayTileLayer = null;
state.campusMarker = null;

function setMapLayerType(type) {
  state.mapLayerType = type;
  
  // Update button active classes
  ['Streets', 'Satellite', 'Hybrid'].forEach(t => {
    const btn = document.getElementById(`btnLayer${t}`);
    if (btn) {
      btn.classList.toggle('active', t.toLowerCase() === type);
    }
  });

  if (!state.map) return;

  // Remove existing tile layers
  if (state.baseTileLayer) {
    state.map.removeLayer(state.baseTileLayer);
    state.baseTileLayer = null;
  }
  if (state.overlayTileLayer) {
    state.map.removeLayer(state.overlayTileLayer);
    state.overlayTileLayer = null;
  }

  if (type === 'satellite') {
    state.baseTileLayer = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
      maxZoom: 19,
      attribution: 'Esri, Maxar, Earthstar Geographics'
    }).addTo(state.map);
  } else if (type === 'hybrid') {
    state.baseTileLayer = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}', {
      maxZoom: 19,
      attribution: 'Esri, Maxar'
    }).addTo(state.map);
    state.overlayTileLayer = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}', {
      maxZoom: 19
    }).addTo(state.map);
  } else {
    // Default streets
    state.baseTileLayer = L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}', {
      maxZoom: 19,
      attribution: 'Esri, OpenStreetMap contributors'
    }).addTo(state.map);
  }

  // Redraw polylines so colors contrast nicely with dark satellite/light street layers
  drawRoutePolylines();
}

function renderMapRouteFilterBar() {
  const container = document.getElementById('mapRouteFilterBar');
  if (!container) return;

  const allActive = state.activeRouteFilter === 'all';
  let html = `
    <div class="map-route-chip ${allActive ? 'active' : ''}" onclick="selectMapRouteFilter('all')">
      <span class="chip-bullet" style="background:${allActive ? '#FED136' : '#64748B'};"></span>
      <span>⭐ All Routes</span>
    </div>
  `;

  html += state.routes.map(r => {
    const isSelected = state.activeRouteFilter === r.id;
    return `
      <div class="map-route-chip ${isSelected ? 'active' : ''}" onclick="selectMapRouteFilter('${r.id}')">
        <span class="chip-bullet" style="background:${isSelected ? '#FED136' : (r.color || '#0A2240')};"></span>
        <span>🚍 ${escapeHtml(r.code)}</span>
      </div>
    `;
  }).join('');

  container.innerHTML = html;
}

function selectMapRouteFilter(routeId) {
  state.activeRouteFilter = routeId;
  renderMapRouteFilterBar();
  drawRoutePolylines();
  updateMapMarkers();

  if (!state.map) return;

  if (routeId === 'all') {
    resetMapView();
  } else {
    const route = state.routes.find(r => r.id === routeId);
    if (!route) return;

    const points = getRouteRoadCoordinates(route);
    if (points && points.length > 0) {
      const bounds = L.latLngBounds(points);
      state.map.fitBounds(bounds, { padding: [40, 40], maxZoom: 14.5 });
    }
  }
}

function locateCampusGate() {
  if (!state.map) return;
  state.map.flyTo([32.362339, 74.208769], 14.8, { duration: 1.2 });
  if (state.campusMarker) {
    setTimeout(() => {
      state.campusMarker.openPopup();
    }, 800);
  }
}

function resetMapView() {
  if (!state.map) return;
  state.map.flyTo([32.2200, 74.1750], 11, { duration: 1.0 });
}

function toggleMapFullscreen() {
  const mapCard = document.getElementById('liveMapCard');
  const btn = document.getElementById('btnToggleMapFullscreen');
  if (!mapCard) return;

  const isFullscreen = mapCard.classList.toggle('fullscreen-mode');
  
  if (btn) {
    btn.innerHTML = isFullscreen ? '🗗 Exit Fullscreen' : '⛶ Fullscreen';
    btn.classList.toggle('btn-gold', isFullscreen);
    btn.classList.toggle('btn-secondary', !isFullscreen);
  }

  // Allow native browser fullscreen if supported
  if (isFullscreen) {
    if (mapCard.requestFullscreen) {
      mapCard.requestFullscreen().catch(() => {});
    }
  } else {
    if (document.fullscreenElement && document.exitFullscreen) {
      document.exitFullscreen().catch(() => {});
    }
  }

  // Recalculate Leaflet tiles after layout change
  setTimeout(() => {
    if (state.map) {
      state.map.invalidateSize();
    }
  }, 250);
}

// Exit fullscreen on Esc key
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    const mapCard = document.getElementById('liveMapCard');
    if (mapCard && mapCard.classList.contains('fullscreen-mode')) {
      toggleMapFullscreen();
    }
  }
});

document.addEventListener('fullscreenchange', () => {
  const mapCard = document.getElementById('liveMapCard');
  const btn = document.getElementById('btnToggleMapFullscreen');
  if (!document.fullscreenElement && mapCard && mapCard.classList.contains('fullscreen-mode')) {
    mapCard.classList.remove('fullscreen-mode');
    if (btn) {
      btn.innerHTML = '⛶ Fullscreen';
      btn.classList.remove('btn-gold');
      btn.classList.add('btn-secondary');
    }
    setTimeout(() => {
      if (state.map) state.map.invalidateSize();
    }, 250);
  }
});

function initLeafletMap() {
  const mapElement = document.getElementById('leafletLiveMap');
  if (!mapElement) return;

  if (typeof window.L === 'undefined') {
    setTimeout(initLeafletMap, 200);
    return;
  }

  try {
    if (state.map) {
      state.map.remove();
      state.map = null;
      state.mapMarkers = {};
      state.routePolylines = {};
      state.stopMarkers = [];
      state.campusMarker = null;
    }

    state.map = L.map('leafletLiveMap', {
      zoomControl: true,
      attributionControl: false
    }).setView([32.2200, 74.1750], 11);

    // Apply active tile layer (Streets / Satellite / Hybrid)
    setMapLayerType(state.mapLayerType || 'streets');

    // Prominent Campus Destination Marker (Matched to Flutter Mobile App)
    const campusHtml = `
      <div class="campus-destination-marker" onclick="locateCampusGate()">
        <div class="campus-dest-pill">
          <span>🎓</span>
          <span>University Campus Gate</span>
        </div>
        <div class="campus-pin-dot">
          <span>🏛️</span>
        </div>
      </div>
    `;

    const campusIcon = L.divIcon({
      className: 'campus-marker-wrapper',
      html: campusHtml,
      iconSize: [130, 60],
      iconAnchor: [65, 55]
    });

    state.campusMarker = L.marker([32.362339, 74.208769], { icon: campusIcon })
      .addTo(state.map)
      .bindPopup(`
        <div style="font-family:'Poppins',sans-serif; min-width:200px;">
          <h4 style="margin:0; font-size:13.5px; color:#0A2240; display:flex; align-items:center; gap:6px;">
            🎓 <span>University Campus (RCET)</span>
          </h4>
          <p style="margin:4px 0 0 0; font-size:11.5px; color:#64748B;">Central University Transport Terminal & Main Gates</p>
        </div>
      `);

    renderMapRouteFilterBar();
    drawRoutePolylines();
    updateMapMarkers();
  } catch (err) {
    console.error('Error initializing Leaflet map:', err);
  }
}

const pendingRouteRoadFetches = new Set();

async function fetchAndCacheRoadPolyline(route) {
  if (!route || !route.stops || !Array.isArray(route.stops)) return null;
  const validStops = route.stops.filter(s => typeof s.lat === 'number' && typeof s.lng === 'number' && !isNaN(s.lat) && !isNaN(s.lng));
  if (validStops.length < 2) return null;

  const cacheKey = route.id;
  if (pendingRouteRoadFetches.has(cacheKey)) return null;
  pendingRouteRoadFetches.add(cacheKey);

  try {
    const coordsStr = validStops.map(s => `${s.lng.toFixed(6)},${s.lat.toFixed(6)}`).join(';');
    const url = `https://router.project-osrm.org/route/v1/driving/${coordsStr}?overview=full&geometries=geojson`;
    
    const resp = await fetch(url);
    if (resp.ok) {
      const data = await resp.json();
      if (data.code === 'Ok' && data.routes && data.routes.length > 0) {
        const coords = data.routes[0].geometry.coordinates.map(c => [c[1], c[0]]);
        if (coords.length > 0) {
          if (typeof ROUTE_ROAD_POLYLINES === 'undefined') {
            window.ROUTE_ROAD_POLYLINES = {};
          }
          ROUTE_ROAD_POLYLINES[route.id] = coords;
          route.polylinePoints = coords;
          pendingRouteRoadFetches.delete(cacheKey);
          return coords;
        }
      }
    }
  } catch (err) {
    console.warn('Dynamic road routing notice for route:', route.id, err);
  }

  pendingRouteRoadFetches.delete(cacheKey);
  return null;
}

function getRouteRoadCoordinates(route) {
  if (!route) return [];

  // 1. Direct match in ROUTE_ROAD_POLYLINES cache
  if (typeof ROUTE_ROAD_POLYLINES !== 'undefined' && ROUTE_ROAD_POLYLINES[route.id] && ROUTE_ROAD_POLYLINES[route.id].length > 0) {
    return ROUTE_ROAD_POLYLINES[route.id];
  }

  // 2. Direct match by route.polylinePoints (saved in Firebase or object)
  if (route.polylinePoints && Array.isArray(route.polylinePoints) && route.polylinePoints.length > 0) {
    if (typeof ROUTE_ROAD_POLYLINES === 'undefined') window.ROUTE_ROAD_POLYLINES = {};
    ROUTE_ROAD_POLYLINES[route.id] = route.polylinePoints;
    return route.polylinePoints;
  }
  
  // 3. Match by route code / title (e.g. Route No. 1, Route 2, etc.)
  if (typeof ROUTE_ROAD_POLYLINES !== 'undefined') {
    const codeStr = `${route.id || ''} ${route.code || ''} ${route.title || ''}`.toLowerCase();
    for (let i = 1; i <= 5; i++) {
      if (codeStr.includes(`route_${i}`) || codeStr.includes(`no. ${i}`) || codeStr.includes(`no.${i}`) || codeStr.includes(`route ${i}`) || codeStr.includes(`route-${i}`) || codeStr.includes(`${i}`)) {
        if (ROUTE_ROAD_POLYLINES[`route_${i}`]) {
          return ROUTE_ROAD_POLYLINES[`route_${i}`];
        }
      }
    }
  }

  // 4. Auto-generate turn-by-turn road polyline dynamically for newly added routes
  if (route.stops && Array.isArray(route.stops) && route.stops.length >= 2) {
    fetchAndCacheRoadPolyline(route).then(coords => {
      if (coords && coords.length > 0 && state.map) {
        drawRoutePolylines();
      }
    });

    // Fallback to stop coordinates until OSRM returns turn-by-turn geometry
    return route.stops
      .filter(s => typeof s.lat === 'number' && typeof s.lng === 'number' && !isNaN(s.lat) && !isNaN(s.lng))
      .map(s => [s.lat, s.lng]);
  }

  return [];
}

function drawRoutePolylines() {
  if (!state.map) return;

  // Clear existing stop markers
  state.stopMarkers.forEach(m => state.map.removeLayer(m));
  state.stopMarkers = [];

  // Clear all old route polylines
  Object.keys(state.routePolylines).forEach(key => {
    if (state.routePolylines[key]) {
      state.map.removeLayer(state.routePolylines[key]);
    }
  });
  state.routePolylines = {};

  const isSatelliteMode = state.mapLayerType === 'satellite' || state.mapLayerType === 'hybrid';
  const filterActive = state.activeRouteFilter !== 'all';

  state.routes.forEach(route => {
    if (filterActive && route.id !== state.activeRouteFilter) return;

    // Get high-precision road snapped polyline points (OSRM GT Road tracks matched to Mobile App)
    const roadCoords = getRouteRoadCoordinates(route);

    if (roadCoords && roadCoords.length > 1) {
      const isHighlighted = filterActive && route.id === state.activeRouteFilter;
      const baseColor = route.color || '#0A2240';

      // 1. Outer Road Casing / Glow (Matched to Flutter PolylineLayer)
      const glowPolyline = L.polyline(roadCoords, {
        color: isSatelliteMode ? '#FED136' : (isHighlighted ? '#FED136' : '#0A2240'),
        weight: isHighlighted ? 8.0 : 6.0,
        opacity: isSatelliteMode ? 0.65 : (isHighlighted ? 0.5 : 0.2),
        lineCap: 'round',
        lineJoin: 'round'
      }).addTo(state.map);

      // 2. Core Vibrant Solid Road Line (Matched to Flutter PolylineLayer)
      const corePolyline = L.polyline(roadCoords, {
        color: isSatelliteMode ? '#FFFFFF' : (isHighlighted ? '#0A2240' : baseColor),
        weight: isHighlighted ? 5.0 : 3.8,
        opacity: isHighlighted ? 1.0 : 0.85,
        lineCap: 'round',
        lineJoin: 'round'
      }).addTo(state.map);

      state.routePolylines[`${route.id}_glow`] = glowPolyline;
      state.routePolylines[`${route.id}_core`] = corePolyline;
    }

    // Add Stop Pins along the Route (Matched to Flutter Mobile App stop pins)
    if (route.stops && Array.isArray(route.stops)) {
      route.stops.forEach((stop, idx) => {
        // Skip campus point as it has its own dedicated destination landmark
        if (stop.id === 'stop_rcet_campus' || (stop.name && stop.name.toLowerCase().includes('rcet campus'))) {
          return;
        }

        const isStart = idx === 0;
        const stopPinHtml = `
          <div class="app-map-stop-pin" style="border-color:${isStart ? '#FED136' : (route.color || '#0A2240')};">
            <span class="stop-dot-inner" style="background:${isStart ? '#0A2240' : (route.color || '#0A2240')};"></span>
          </div>
        `;

        const stopIcon = L.divIcon({
          className: 'route-stop-wrapper',
          html: stopPinHtml,
          iconSize: [20, 20],
          iconAnchor: [10, 10]
        });

        const marker = L.marker([stop.lat, stop.lng], { icon: stopIcon })
          .addTo(state.map)
          .bindTooltip(`
            <div style="font-family:'Poppins', sans-serif;">
              <strong>${idx + 1}. ${escapeHtml(stop.name)}</strong><br>
              <small style="color:#64748B;">Route: ${escapeHtml(route.code)}</small><br>
              <div style="margin-top:2px; font-size:11px;">
                <span>🌅 Pickup: <strong>${stop.timeMorning || '07:30 AM'}</strong></span> • 
                <span>🌇 Return: <strong>${stop.timeEvening || '04:30 PM'}</strong></span>
              </div>
            </div>
          `, {
            direction: 'top',
            offset: [0, -8],
            opacity: 0.95
          });

        state.stopMarkers.push(marker);
      });
    }
  });
}

function updateMapMarkers() {
  if (!state.map) return;

  const currentBusIds = new Set(state.buses.map(b => b.id));

  // Remove stale markers
  Object.keys(state.mapMarkers).forEach(busId => {
    if (!currentBusIds.has(busId)) {
      state.map.removeLayer(state.mapMarkers[busId]);
      delete state.mapMarkers[busId];
    }
  });

  const filterActive = state.activeRouteFilter !== 'all';

  state.buses.forEach(bus => {
    // If route filter is active, only show buses assigned to this route
    if (filterActive && bus.routeId !== state.activeRouteFilter) {
      if (state.mapMarkers[bus.id]) {
        state.map.removeLayer(state.mapMarkers[bus.id]);
        delete state.mapMarkers[bus.id];
      }
      return;
    }

    if (!bus.location || !bus.location.lat || !bus.location.lng) return;

    const isStandby = bus.status === 'stopped' || bus.status === 'maintenance';
    const isMoving = bus.status === 'onRoute' || bus.status === 'approaching';

    const iconHtml = `
      <div class="custom-bus-marker ${isMoving ? 'moving' : ''}" style="${isStandby ? 'background:#334155; border-color:#94A3B8;' : ''}">
        🚌
        <div class="bus-label-badge" style="${isStandby ? 'background:#1E293B; color:#CBD5E1;' : ''}">${escapeHtml(bus.name)}</div>
      </div>
    `;

    const busIcon = L.divIcon({
      className: 'bus-marker-wrapper',
      html: iconHtml,
      iconSize: [40, 40],
      iconAnchor: [20, 20]
    });

    const speedVal = isStandby ? '0.0 km/h (Standby)' : `${typeof bus.speed === 'number' ? bus.speed.toFixed(1) : bus.speed} km/h`;

    const popupContent = `
      <div style="font-family:'Poppins', sans-serif; min-width:200px;">
        <h4 style="margin:0; font-size:14px; color:#0A2240; display:flex; align-items:center; gap:6px;">
          🚌 <span>${escapeHtml(bus.name)}</span>
        </h4>
        <p style="margin:3px 0 6px; font-size:11.5px; color:#475569;">${escapeHtml(bus.routeName)}</p>
        <hr style="border:0; border-top:1px solid #E2E8F0; margin:6px 0;">
        <div style="font-size:11.5px; line-height:1.6;">
          <div><strong>Live Speed:</strong> <span style="font-weight:700; color:#0A2240;">${speedVal}</span></div>
          <div><strong>Status:</strong> <span style="font-weight:600; color:${isMoving ? '#059669' : '#64748B'};">${bus.status === 'stopped' ? 'Standby (Parked)' : bus.status}</span></div>
          <div><strong>Driver:</strong> ${escapeHtml(bus.driverName)} (${escapeHtml(bus.driverPhone)})</div>
          <div><strong>${isStandby ? 'Parked at:' : 'Current / Next Stop:'}</strong> <strong>${escapeHtml(bus.nextStop || 'Route Starting Point')}</strong></div>
        </div>
      </div>
    `;

    if (state.mapMarkers[bus.id]) {
      state.mapMarkers[bus.id].setLatLng([bus.location.lat, bus.location.lng]);
      state.mapMarkers[bus.id].setIcon(busIcon);
      state.mapMarkers[bus.id].setPopupContent(popupContent);
    } else {
      const marker = L.marker([bus.location.lat, bus.location.lng], { icon: busIcon })
        .addTo(state.map)
        .bindPopup(popupContent);
      state.mapMarkers[bus.id] = marker;
    }
  });
}

function focusBusOnMap(busId) {
  const bus = state.buses.find(b => b.id === busId);
  if (!bus || !state.map) return;

  if (state.currentTab !== 'overview') {
    switchTab('overview');
  }

  state.map.flyTo([bus.location.lat, bus.location.lng], 14.5, { duration: 1.2 });
  if (state.mapMarkers[busId]) {
    setTimeout(() => {
      state.mapMarkers[busId].openPopup();
    }, 700);
  }
}

// ==========================================================================
// CRUD Handlers (Direct Firebase Cloud Publishing)
// ==========================================================================

// 1. Bus CRUD
function openAddBusModal() {
  state.editingBusId = null;
  document.getElementById('busModalTitle').innerText = 'Add New Bus to Fleet';
  document.getElementById('busForm').reset();
  populateDropdownOptions();
  showModal('busModal');
}

function openEditBusModal(busId) {
  const bus = state.buses.find(b => b.id === busId);
  if (!bus) return;

  state.editingBusId = busId;
  document.getElementById('busModalTitle').innerText = `Edit Bus (${bus.name})`;
  populateDropdownOptions();

  document.getElementById('busNumberInput').value = bus.name;
  document.getElementById('busModelInput').value = bus.model || '';
  document.getElementById('busRouteSelect').value = bus.routeId;
  document.getElementById('busDriverSelect').value = bus.driverId || '';
  
  const capacityInput = document.getElementById('busCapacityInput');
  if (capacityInput) capacityInput.value = bus.capacity || 52;

  showModal('busModal');
}

async function handleBusFormSubmit(e) {
  e.preventDefault();
  const name = document.getElementById('busNumberInput').value.trim();
  const model = document.getElementById('busModelInput').value.trim();
  const routeId = document.getElementById('busRouteSelect').value;
  const driverId = document.getElementById('busDriverSelect').value;
  const capacity = parseInt(document.getElementById('busCapacityInput').value) || 52;

  if (!name) {
    showToast('Please provide a bus registration number', 'warning');
    return;
  }

  const route = state.routes.find(r => r.id === routeId) || INITIAL_ROUTES.find(r => r.id === routeId);
  const routeStart = getRouteStartStop(routeId);
  const driver = state.drivers.find(d => d.id === driverId);

  if (state.editingBusId) {
    const busIndex = state.buses.findIndex(b => b.id === state.editingBusId);
    if (busIndex !== -1) {
      const existing = state.buses[busIndex];

      state.buses[busIndex] = {
        ...existing,
        name,
        model,
        routeId,
        routeName: route ? `${route.code} - ${route.title}` : 'Unassigned Route',
        driverId,
        driverName: driver ? driver.name : 'Unassigned',
        driverPhone: driver ? driver.phone : '',
        capacity
      };
      await pushBusToFirebase(state.buses[busIndex]);
      await broadcastSystemAlert({
        title: `Bus Updated: ${name}`,
        message: `Bus ${name} assignment updated on ${state.buses[busIndex].routeName} with Driver ${driver ? driver.name : 'Assigned'}.`,
        type: 'info',
        routeId: routeId,
        busId: state.buses[busIndex].id
      });
      showToast(`Bus ${name} updated successfully!`, 'success');
    }
  } else {
    const newBus = {
      id: `bus_${Date.now()}`,
      name,
      model: model || 'Hino Transit',
      routeId,
      routeName: route ? `${route.code} - ${route.title}` : 'Unassigned Route',
      driverId,
      driverName: driver ? driver.name : 'Unassigned',
      driverPhone: driver ? driver.phone : '',
      capacity,
      status: 'stopped', // Default Standby
      speed: 0.0,
      etaMinutes: 0,
      isLive: false,
      nextStop: routeStart.name ? `Standby at ${routeStart.name}` : 'Terminal Standby',
      location: { lat: routeStart.lat, lng: routeStart.lng },
      fuelLevel: 100,
      lastServiceDate: new Date().toISOString().split('T')[0]
    };
    state.buses.unshift(newBus);
    await pushBusToFirebase(newBus);
    await broadcastSystemAlert({
      title: `New Bus Added: ${name}`,
      message: `Bus ${name} (${model || 'Transit Fleet'}) has been added and assigned to ${newBus.routeName}.`,
      type: 'info',
      routeId: routeId,
      busId: newBus.id
    });
    showToast(`Bus ${name} added successfully!`, 'success');
  }

  hideModal('busModal');
  updateMapMarkers();
  renderAll();
}

async function deleteBus(busId) {
  const bus = state.buses.find(b => b.id === busId);
  if (!bus) return;

  if (confirm(`Are you sure you want to remove Bus ${bus.name}?`)) {
    if (state.mapMarkers[busId]) {
      state.map.removeLayer(state.mapMarkers[busId]);
      delete state.mapMarkers[busId];
    }
    state.buses = state.buses.filter(b => b.id !== busId);
    await deleteBusFromFirebase(busId);
    await broadcastSystemAlert({
      title: `Bus Service Notice: ${bus.name}`,
      message: `Bus ${bus.name} has been removed from active fleet operations.`,
      type: 'warning',
      routeId: bus.routeId,
      busId: bus.id
    });
    renderAll();
    showToast(`Bus ${bus.name} removed successfully.`, 'danger');
  }
}

// 2. Route CRUD & Dynamic Interactive Map Stops Sequencer
let modalRouteStops = [];
let modalPickerMap = null;
let modalPickerMarkers = [];
let modalPickerPolyline = null;
let modalCampusMarker = null;
let activePickerStopIndex = 0;

function escapeHtml(str) {
  if (typeof str !== 'string') return str || '';
  return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

function initModalPickerMap() {
  const mapElement = document.getElementById('routePickerLeafletMap');
  if (!mapElement || typeof window.L === 'undefined') return;

  if (!modalPickerMap) {
    try {
      modalPickerMap = L.map('routePickerLeafletMap', {
        zoomControl: true,
        attributionControl: false
      }).setView([32.2200, 74.1750], 11);

      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19
      }).addTo(modalPickerMap);

      // Dedicated Campus Landmark Pin
      const campusHtml = `
        <div style="background:#0A2240; color:#FED136; border:2px solid #FED136; border-radius:12px; padding:3px 8px; font-size:11px; font-weight:700; white-space:nowrap; box-shadow:0 2px 8px rgba(0,0,0,0.35);">
          🎓 RCET Campus
        </div>
      `;
      const campusIcon = L.divIcon({
        className: 'modal-campus-pin',
        html: campusHtml,
        iconSize: [80, 24],
        iconAnchor: [40, 24]
      });

      modalCampusMarker = L.marker([32.362339, 74.208769], { icon: campusIcon })
        .addTo(modalPickerMap)
        .bindTooltip('UET RCET Gujranwala Campus Terminal (32.362339, 74.208769)');

      // Map Click Event: Relocates active selected stop to clicked coordinates
      modalPickerMap.on('click', (e) => {
        const lat = parseFloat(e.latlng.lat.toFixed(6));
        const lng = parseFloat(e.latlng.lng.toFixed(6));

        if (modalRouteStops.length === 0) {
          addModalStopRow();
          activePickerStopIndex = 0;
        }

        if (activePickerStopIndex >= 0 && activePickerStopIndex < modalRouteStops.length) {
          modalRouteStops[activePickerStopIndex].lat = lat;
          modalRouteStops[activePickerStopIndex].lng = lng;
          renderModalStops();
          renderModalPickerMarkers();
          showToast(`Stop ${activePickerStopIndex + 1} position updated to [${lat.toFixed(4)}, ${lng.toFixed(4)}]`, 'info');
        }
      });
    } catch (err) {
      console.error('Error initializing route picker map:', err);
    }
  }

  setTimeout(() => {
    if (modalPickerMap) {
      modalPickerMap.invalidateSize();
      resetModalPickerView();
    }
  }, 220);
}

function renderModalPickerMarkers() {
  if (!modalPickerMap) return;

  // Clear previous markers and polyline
  modalPickerMarkers.forEach(m => modalPickerMap.removeLayer(m));
  modalPickerMarkers = [];

  if (modalPickerPolyline) {
    modalPickerMap.removeLayer(modalPickerPolyline);
    modalPickerPolyline = null;
  }

  const validCoords = [];

  modalRouteStops.forEach((stop, idx) => {
    const hasCoords = typeof stop.lat === 'number' && typeof stop.lng === 'number' && !isNaN(stop.lat) && !isNaN(stop.lng);
    if (!hasCoords) return;

    const isSelected = idx === activePickerStopIndex;
    const pinBg = isSelected ? '#2563EB' : '#0A2240';
    const textColor = isSelected ? '#FFFFFF' : '#FED136';
    const borderGlow = isSelected ? '3px solid #FED136' : '2px solid #FFFFFF';

    const iconHtml = `
      <div class="picker-stop-marker ${isSelected ? 'active-marker' : ''}" style="
        background: ${pinBg};
        color: ${textColor};
        width: 28px;
        height: 28px;
        border-radius: 50%;
        border: ${borderGlow};
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: 800;
        font-size: 12px;
        box-shadow: 0 3px 8px rgba(0,0,0,0.38);
        cursor: grab;
      ">
        ${idx + 1}
      </div>
    `;

    const icon = L.divIcon({
      className: 'route-picker-marker-wrap',
      html: iconHtml,
      iconSize: [28, 28],
      iconAnchor: [14, 14]
    });

    const marker = L.marker([stop.lat, stop.lng], {
      icon: icon,
      draggable: true
    }).addTo(modalPickerMap);

    marker.bindTooltip(`
      <div style="font-family:'Poppins', sans-serif;">
        <strong>Stop ${idx + 1}: ${escapeHtml(stop.name || 'Unnamed')}</strong><br>
        <span style="font-size:11px; color:#64748B;">🖐️ Drag pin to fine-tune location</span>
      </div>
    `, {
      direction: 'top',
      offset: [0, -10]
    });

    marker.on('dragend', (e) => {
      const newPos = e.target.getLatLng();
      stop.lat = parseFloat(newPos.lat.toFixed(6));
      stop.lng = parseFloat(newPos.lng.toFixed(6));
      renderModalStops();
      updateModalPickerPolyline();
      showToast(`Stop ${idx + 1} moved to [${stop.lat.toFixed(4)}, ${stop.lng.toFixed(4)}]`, 'info');
    });

    marker.on('click', (e) => {
      L.DomEvent.stopPropagation(e);
      setActivePickerStop(idx);
    });

    modalPickerMarkers.push(marker);
    validCoords.push([stop.lat, stop.lng]);
  });

  // Connect stops visually with route dashed line
  if (validCoords.length > 1) {
    modalPickerPolyline = L.polyline(validCoords, {
      color: '#2563EB',
      weight: 4,
      opacity: 0.85,
      dashArray: '6, 8'
    }).addTo(modalPickerMap);
  }
}

function updateModalPickerPolyline() {
  const validCoords = modalRouteStops
    .filter(s => typeof s.lat === 'number' && typeof s.lng === 'number' && !isNaN(s.lat) && !isNaN(s.lng))
    .map(s => [s.lat, s.lng]);

  if (modalPickerPolyline) {
    modalPickerPolyline.setLatLngs(validCoords);
  } else if (validCoords.length > 1 && modalPickerMap) {
    modalPickerPolyline = L.polyline(validCoords, {
      color: '#2563EB',
      weight: 4,
      opacity: 0.85,
      dashArray: '6, 8'
    }).addTo(modalPickerMap);
  }
}

function setActivePickerStop(index) {
  if (index < 0 || index >= modalRouteStops.length) return;
  activePickerStopIndex = index;
  const stop = modalRouteStops[index];

  const hintBadge = document.getElementById('pickerActiveStopHint');
  if (hintBadge) {
    hintBadge.innerHTML = `🎯 Target: <strong>Stop ${index + 1} (${escapeHtml(stop.name || 'Unnamed')})</strong>`;
  }

  // Highlight card in DOM
  document.querySelectorAll('.stop-row-card').forEach((el, i) => {
    if (i === index) {
      el.classList.add('active-picker-stop');
    } else {
      el.classList.remove('active-picker-stop');
    }
  });

  renderModalPickerMarkers();

  if (modalPickerMap && typeof stop.lat === 'number' && typeof stop.lng === 'number' && !isNaN(stop.lat) && !isNaN(stop.lng)) {
    modalPickerMap.panTo([stop.lat, stop.lng], { animate: true, duration: 0.4 });
  }
}

function addModalStopAtMapCenter() {
  if (!modalPickerMap) return;
  const center = modalPickerMap.getCenter();
  const lat = parseFloat(center.lat.toFixed(6));
  const lng = parseFloat(center.lng.toFixed(6));

  const newIdx = modalRouteStops.length;
  modalRouteStops.push({
    id: `stop_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
    name: `Stop ${newIdx + 1}`,
    timeMorning: '07:30 AM',
    timeEvening: '04:30 PM',
    lat: lat,
    lng: lng
  });

  activePickerStopIndex = newIdx;
  renderModalStops();
  renderModalPickerMarkers();
  showToast(`Stop ${newIdx + 1} created at current map center!`, 'success');
}

function snapModalStopToCampus() {
  const campusLat = 32.362339;
  const campusLng = 74.208769;

  const newIdx = modalRouteStops.length;
  modalRouteStops.push({
    id: `stop_rcet_campus_${Date.now()}`,
    name: 'University Campus Terminal (RCET)',
    timeMorning: '08:15 AM',
    timeEvening: '05:30 PM',
    lat: campusLat,
    lng: campusLng
  });

  activePickerStopIndex = newIdx;
  renderModalStops();
  renderModalPickerMarkers();

  if (modalPickerMap) {
    modalPickerMap.setView([campusLat, campusLng], 14);
  }
  showToast('University Campus Terminal stop added!', 'success');
}

function resetModalPickerView() {
  if (!modalPickerMap) return;
  const coords = modalRouteStops
    .filter(s => typeof s.lat === 'number' && typeof s.lng === 'number' && !isNaN(s.lat) && !isNaN(s.lng))
    .map(s => [s.lat, s.lng]);

  if (coords.length > 0) {
    try {
      const bounds = L.latLngBounds(coords);
      bounds.extend([32.362339, 74.208769]); // Include campus landmark
      modalPickerMap.fitBounds(bounds, { padding: [35, 35], maxZoom: 15 });
    } catch (e) {
      modalPickerMap.setView([32.2200, 74.1750], 11);
    }
  } else {
    modalPickerMap.setView([32.2200, 74.1750], 11);
  }
}

function renderModalStops() {
  const container = document.getElementById('routeStopsContainer');
  const countBadge = document.getElementById('modalStopsCountBadge');
  if (!container) return;

  if (countBadge) {
    countBadge.innerText = `${modalRouteStops.length} ${modalRouteStops.length === 1 ? 'Stop' : 'Stops'}`;
  }

  if (modalRouteStops.length === 0) {
    container.innerHTML = `
      <div class="empty-stops-placeholder">
        <span style="font-weight:600; color:var(--primary-navy);">No stops configured yet for this route.</span><br>
        <span style="font-size:12px; color:var(--text-secondary);">Click "📍 Add Stop at Center" above or "➕ Add Another Stop" to place stops visually on the map.</span>
      </div>
    `;
    return;
  }

  container.innerHTML = modalRouteStops.map((stop, idx) => {
    const isFirst = idx === 0;
    const isLast = idx === modalRouteStops.length - 1;
    const isSelected = idx === activePickerStopIndex;
    const hasValidCoords = typeof stop.lat === 'number' && typeof stop.lng === 'number' && !isNaN(stop.lat) && !isNaN(stop.lng);
    const coordDisplay = hasValidCoords ? `${stop.lat.toFixed(4)}, ${stop.lng.toFixed(4)}` : 'Location not set';

    return `
      <div class="stop-row-card ${isSelected ? 'active-picker-stop' : ''}" data-stop-idx="${idx}" onclick="setActivePickerStop(${idx})">
        <div class="stop-row-top">
          <div class="stop-row-badge-name">
            <span class="stop-seq-badge">Stop ${idx + 1}</span>
            <input type="text" 
                   class="stop-name-input" 
                   placeholder="Stop Name (e.g. Kangni wala, Pindi Bypass, RCET...)" 
                   value="${escapeHtml(stop.name || '')}" 
                   onclick="event.stopPropagation()"
                   oninput="updateModalStopField(${idx}, 'name', this.value)" 
                   required>
          </div>
          <div class="stop-row-actions" onclick="event.stopPropagation()">
            <button type="button" 
                    class="btn-icon-reorder" 
                    title="Move Stop Earlier (⬆)" 
                    onclick="moveModalStopRow(${idx}, -1)" 
                    ${isFirst ? 'disabled' : ''}>⬆</button>
            <button type="button" 
                    class="btn-icon-reorder" 
                    title="Move Stop Later (⬇)" 
                    onclick="moveModalStopRow(${idx}, 1)" 
                    ${isLast ? 'disabled' : ''}>⬇</button>
            <button type="button" 
                    class="btn-remove-stop" 
                    title="Remove this stop" 
                    onclick="removeModalStopRow(${idx})">🗑️ Remove</button>
          </div>
        </div>

        <div class="stop-row-fields-grid" onclick="event.stopPropagation()">
          <div class="stop-field-col">
            <label>🌅 Morning Pickup Time</label>
            <input type="text" 
                   placeholder="e.g. 07:15 AM" 
                   value="${escapeHtml(stop.timeMorning || '')}" 
                   oninput="updateModalStopField(${idx}, 'timeMorning', this.value)">
          </div>

          <div class="stop-field-col">
            <label>🌇 Evening Return Time</label>
            <input type="text" 
                   placeholder="e.g. 04:30 PM" 
                   value="${escapeHtml(stop.timeEvening || '')}" 
                   oninput="updateModalStopField(${idx}, 'timeEvening', this.value)">
          </div>

          <div class="stop-field-col">
            <label>📍 Map Pinpoint Location</label>
            <div class="stop-location-display-box">
              <div class="stop-location-pill" title="Exact Coordinates: ${hasValidCoords ? `${stop.lat}, ${stop.lng}` : 'Unset'}">
                <span>📍</span>
                <span>${coordDisplay}</span>
              </div>
              <button type="button" class="btn-map-pick" onclick="setActivePickerStop(${idx})">
                🎯 Set on Map
              </button>
            </div>
          </div>
        </div>
      </div>
    `;
  }).join('');
}

function updateModalStopField(index, field, value) {
  if (modalRouteStops[index]) {
    modalRouteStops[index][field] = value;
    if (field === 'name') {
      const hintBadge = document.getElementById('pickerActiveStopHint');
      if (hintBadge && index === activePickerStopIndex) {
        hintBadge.innerHTML = `🎯 Target: <strong>Stop ${index + 1} (${escapeHtml(value || 'Unnamed')})</strong>`;
      }
    }
  }
}

function addModalStopRow() {
  let baseLat = 32.1600;
  let baseLng = 74.1800;
  if (modalRouteStops.length > 0) {
    const last = modalRouteStops[modalRouteStops.length - 1];
    baseLat = last.lat ? parseFloat((last.lat + 0.012).toFixed(4)) : 32.2000;
    baseLng = last.lng ? parseFloat((last.lng - 0.004).toFixed(4)) : 74.1700;
  }

  const newIdx = modalRouteStops.length;
  modalRouteStops.push({
    id: `stop_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`,
    name: '',
    timeMorning: '07:30 AM',
    timeEvening: '04:30 PM',
    lat: baseLat,
    lng: baseLng
  });

  activePickerStopIndex = newIdx;
  renderModalStops();
  renderModalPickerMarkers();
}

function removeModalStopRow(index) {
  if (index >= 0 && index < modalRouteStops.length) {
    modalRouteStops.splice(index, 1);
    if (activePickerStopIndex >= modalRouteStops.length) {
      activePickerStopIndex = Math.max(0, modalRouteStops.length - 1);
    }
    renderModalStops();
    renderModalPickerMarkers();
  }
}

function moveModalStopRow(index, delta) {
  const targetIndex = index + delta;
  if (targetIndex < 0 || targetIndex >= modalRouteStops.length) return;

  const temp = modalRouteStops[index];
  modalRouteStops[index] = modalRouteStops[targetIndex];
  modalRouteStops[targetIndex] = temp;

  activePickerStopIndex = targetIndex;
  renderModalStops();
  renderModalPickerMarkers();
}

function openAddRouteModal() {
  state.editingRouteId = null;
  document.getElementById('routeModalTitle').innerText = 'Create New Transport Route';
  document.getElementById('routeForm').reset();
  document.getElementById('routeColorInput').value = '#0A2240';

  // Provide initial template stops
  modalRouteStops = [
    {
      id: `stop_${Date.now()}_1`,
      name: 'City Terminal / Starting Point',
      timeMorning: '07:00 AM',
      timeEvening: '04:15 PM',
      lat: 32.1620,
      lng: 74.1850
    },
    {
      id: `stop_${Date.now()}_2`,
      name: 'Pindi Bypass Connecting Hub',
      timeMorning: '07:35 AM',
      timeEvening: '05:00 PM',
      lat: 32.2030,
      lng: 74.1750
    },
    {
      id: `stop_${Date.now()}_3`,
      name: 'University Campus Terminal',
      timeMorning: '08:15 AM',
      timeEvening: '05:45 PM',
      lat: 32.362339,
      lng: 74.208769
    }
  ];

  activePickerStopIndex = 0;
  showModal('routeModal');
  initModalPickerMap();
  renderModalStops();
  renderModalPickerMarkers();
}

function openEditRouteModal(routeId) {
  const route = state.routes.find(r => r.id === routeId);
  if (!route) return;

  state.editingRouteId = routeId;
  document.getElementById('routeModalTitle').innerText = `Edit Route: ${route.code}`;
  document.getElementById('routeCodeInput').value = route.code || '';
  document.getElementById('routeTitleInput').value = route.title || '';
  document.getElementById('routeDescInput').value = route.description || '';
  document.getElementById('routeDurationInput').value = route.estimatedDurationMinutes || 60;
  document.getElementById('routeColorInput').value = route.color || '#0A2240';

  // Deep copy route stops into working modal array
  if (route.stops && Array.isArray(route.stops) && route.stops.length > 0) {
    modalRouteStops = route.stops.map((s, idx) => ({
      id: s.id || `stop_${Date.now()}_${idx}`,
      name: s.name || '',
      timeMorning: s.timeMorning || '',
      timeEvening: s.timeEvening || '',
      lat: typeof s.lat === 'number' && !isNaN(s.lat) ? s.lat : (parseFloat(s.lat) || 32.1800),
      lng: typeof s.lng === 'number' && !isNaN(s.lng) ? s.lng : (parseFloat(s.lng) || 74.1900)
    }));
  } else {
    modalRouteStops = [];
  }

  activePickerStopIndex = 0;
  showModal('routeModal');
  initModalPickerMap();
  renderModalStops();
  renderModalPickerMarkers();
}

async function handleRouteFormSubmit(e) {
  e.preventDefault();
  const code = document.getElementById('routeCodeInput').value.trim();
  const title = document.getElementById('routeTitleInput').value.trim();
  const description = document.getElementById('routeDescInput').value.trim();
  const estimatedDurationMinutes = parseInt(document.getElementById('routeDurationInput').value) || 60;
  const color = document.getElementById('routeColorInput').value || '#0A2240';

  if (!code || !title) {
    showToast('Please enter both route code and route title.', 'warning');
    return;
  }

  // Filter out empty stop names and sanitize coordinates
  const sanitizedStops = modalRouteStops
    .filter(s => s && s.name && s.name.trim() !== '')
    .map((s, idx) => ({
      id: s.id || `stop_${Date.now()}_${idx}`,
      name: s.name.trim(),
      timeMorning: s.timeMorning ? s.timeMorning.trim() : '07:30 AM',
      timeEvening: s.timeEvening ? s.timeEvening.trim() : '04:30 PM',
      lat: typeof s.lat === 'number' && !isNaN(s.lat) ? s.lat : (parseFloat(s.lat) || 32.1800),
      lng: typeof s.lng === 'number' && !isNaN(s.lng) ? s.lng : (parseFloat(s.lng) || 74.1900)
    }));

  if (sanitizedStops.length === 0) {
    showToast('Please add at least 1 stop with a name for this route.', 'warning');
    return;
  }

  if (state.editingRouteId) {
    const index = state.routes.findIndex(r => r.id === state.editingRouteId);
    if (index !== -1) {
      const updatedRoute = {
        ...state.routes[index],
        code,
        title,
        description,
        estimatedDurationMinutes,
        color,
        stops: sanitizedStops
      };

      // Generate precise road-following turn-by-turn polyline for updated route stops
      const roadCoords = await fetchAndCacheRoadPolyline(updatedRoute);
      if (roadCoords && roadCoords.length > 0) {
        updatedRoute.polylinePoints = roadCoords;
      }

      state.routes[index] = updatedRoute;
      await pushRouteToFirebase(updatedRoute);
      await broadcastSystemAlert({
        title: `Route Updated: ${code}`,
        message: `Schedule and stops for ${code} (${title}) have been updated with ${sanitizedStops.length} stops.`,
        type: 'info',
        routeId: updatedRoute.id
      });
      showToast(`Route ${code} updated with active road map lines!`, 'success');
    }
  } else {
    const newRoute = {
      id: `route_${Date.now()}`,
      code,
      title,
      description,
      color,
      estimatedDurationMinutes,
      activeBusCount: 0,
      isActive: true,
      stops: sanitizedStops
    };

    // Generate precise road-following turn-by-turn polyline for new route stops
    const roadCoords = await fetchAndCacheRoadPolyline(newRoute);
    if (roadCoords && roadCoords.length > 0) {
      newRoute.polylinePoints = roadCoords;
    }

    state.routes.push(newRoute);
    await pushRouteToFirebase(newRoute);
    await broadcastSystemAlert({
      title: `New Route Launched: ${code}`,
      message: `Route ${code} (${title}) is now operational with ${sanitizedStops.length} checkpoints connecting campus.`,
      type: 'info',
      routeId: newRoute.id
    });
    showToast(`New route ${code} added with active road map lines!`, 'success');
  }

  hideModal('routeModal');
  drawRoutePolylines();
  renderAll();
}

async function deleteRoute(routeId) {
  const route = state.routes.find(r => r.id === routeId);
  if (!route) return;

  if (confirm(`Are you sure you want to delete ${route.code}?`)) {
    if (state.routePolylines[`${routeId}_glow`]) {
      state.map.removeLayer(state.routePolylines[`${routeId}_glow`]);
    }
    if (state.routePolylines[`${routeId}_core`]) {
      state.map.removeLayer(state.routePolylines[`${routeId}_core`]);
    }
    state.routes = state.routes.filter(r => r.id !== routeId);
    await deleteRouteFromFirebase(routeId);
    await broadcastSystemAlert({
      title: `Route Service Discontinued: ${route.code}`,
      message: `Transit Route ${route.code} (${route.title}) has been discontinued.`,
      type: 'warning',
      routeId: route.id
    });
    drawRoutePolylines();
    renderAll();
    showToast(`Route ${route.code} deleted successfully.`, 'danger');
  }
}

// 3. Timetable CRUD
function openAddTimetableModal() {
  state.editingTimetableId = null;
  document.getElementById('ttModalTitle').innerText = 'Add Timetable Schedule Shift';
  document.getElementById('timetableForm').reset();
  populateDropdownOptions();
  showModal('timetableModal');
}

function openEditTimetableModal(ttId) {
  const tt = state.timetables.find(t => t.id === ttId);
  if (!tt) return;

  state.editingTimetableId = ttId;
  document.getElementById('ttModalTitle').innerText = 'Edit Timetable Shift';
  populateDropdownOptions();

  document.getElementById('ttShiftName').value = tt.shiftName;
  document.getElementById('ttRouteSelect').value = tt.routeId;
  document.getElementById('ttBusSelect').value = tt.busId;
  document.getElementById('ttDepTime').value = tt.departureTime;
  document.getElementById('ttArrTime').value = tt.arrivalTime;
  document.getElementById('ttDays').value = tt.days;

  showModal('timetableModal');
}

async function handleTimetableSubmit(e) {
  e.preventDefault();
  const shiftName = document.getElementById('ttShiftName').value;
  const routeId = document.getElementById('ttRouteSelect').value;
  const busId = document.getElementById('ttBusSelect').value;
  const departureTime = document.getElementById('ttDepTime').value.trim();
  const arrivalTime = document.getElementById('ttArrTime').value.trim();
  const days = document.getElementById('ttDays').value.trim();

  const route = state.routes.find(r => r.id === routeId);
  const bus = state.buses.find(b => b.id === busId);

  if (state.editingTimetableId) {
    const idx = state.timetables.findIndex(t => t.id === state.editingTimetableId);
    if (idx !== -1) {
      state.timetables[idx] = {
        ...state.timetables[idx],
        shiftName,
        routeId,
        routeName: route ? `${route.code} - ${route.title}` : 'Unassigned',
        busId,
        busName: bus ? bus.name : 'Unassigned',
        departureTime,
        arrivalTime,
        days
      };
      await pushTimetableToFirebase(state.timetables[idx]);
      await broadcastSystemAlert({
        title: `Timetable Updated: ${shiftName}`,
        message: `Schedule adjusted on ${state.timetables[idx].routeName}: Departure at ${departureTime}, Arrival at ${arrivalTime}.`,
        type: 'info',
        routeId: routeId,
        busId: busId
      });
      showToast('Timetable shift updated successfully!', 'success');
    }
  } else {
    const newTt = {
      id: `tt_${Date.now()}`,
      shiftName,
      routeId,
      routeName: route ? `${route.code} - ${route.title}` : 'Unassigned',
      busId,
      busName: bus ? bus.name : 'Unassigned',
      departureTime,
      arrivalTime,
      days,
      status: "Scheduled"
    };
    state.timetables.push(newTt);
    await pushTimetableToFirebase(newTt);
    await broadcastSystemAlert({
      title: `New Schedule Added: ${shiftName}`,
      message: `New shift slot added for ${newTt.routeName}: Departure ${departureTime} (${days}).`,
      type: 'info',
      routeId: routeId,
      busId: busId
    });
    showToast('Timetable schedule slot added successfully!', 'success');
  }

  hideModal('timetableModal');
  renderAll();
}

async function deleteTimetable(ttId) {
  const tt = state.timetables.find(t => t.id === ttId);
  if (!tt) return;

  if (confirm('Are you sure you want to delete this timetable shift?')) {
    state.timetables = state.timetables.filter(t => t.id !== ttId);
    await deleteTimetableFromFirebase(ttId);
    await broadcastSystemAlert({
      title: `Schedule Cancelled: ${tt.shiftName}`,
      message: `Timetable shift on ${tt.routeName} (${tt.departureTime}) has been cancelled.`,
      type: 'warning',
      routeId: tt.routeId,
      busId: tt.busId
    });
    renderAll();
    showToast('Timetable shift removed.', 'danger');
  }
}

// 4. Driver CRUD
function openAddDriverModal() {
  state.editingDriverId = null;
  document.getElementById('driverModalTitle').innerText = 'Add New Transport Driver';
  document.getElementById('driverForm').reset();
  populateDropdownOptions();
  showModal('driverModal');
}

function openEditDriverModal(drvId) {
  const drv = state.drivers.find(d => d.id === drvId);
  if (!drv) return;

  state.editingDriverId = drvId;
  document.getElementById('driverModalTitle').innerText = `Edit Driver (${drv.name})`;
  populateDropdownOptions();

  document.getElementById('drvNameInput').value = drv.name;
  document.getElementById('drvPhoneInput').value = drv.phone;
  document.getElementById('drvCnicInput').value = drv.cnic || '';
  document.getElementById('drvLicenseInput').value = drv.licenseNo || '';
  document.getElementById('drvBusSelect').value = drv.assignedBusId || '';

  showModal('driverModal');
}

async function handleDriverSubmit(e) {
  e.preventDefault();
  const name = document.getElementById('drvNameInput').value.trim();
  const phone = document.getElementById('drvPhoneInput').value.trim();
  const cnic = document.getElementById('drvCnicInput').value.trim();
  const licenseNo = document.getElementById('drvLicenseInput').value.trim();
  const assignedBusId = document.getElementById('drvBusSelect').value;

  if (!name || !phone) {
    showToast('Please provide Driver Name & Phone number.', 'warning');
    return;
  }

  if (state.editingDriverId) {
    const idx = state.drivers.findIndex(d => d.id === state.editingDriverId);
    if (idx !== -1) {
      state.drivers[idx] = {
        ...state.drivers[idx],
        name,
        phone,
        cnic,
        licenseNo,
        assignedBusId
      };
      await pushDriverToFirebase(state.drivers[idx]);
      showToast(`Driver ${name} updated successfully!`, 'success');
    }
  } else {
    const newDrv = {
      id: `drv_${Date.now()}`,
      name,
      phone,
      cnic,
      licenseNo,
      rating: 4.9,
      assignedBusId,
      status: "Active",
      experienceYears: 5
    };
    state.drivers.push(newDrv);
    await pushDriverToFirebase(newDrv);
    showToast(`Driver ${name} registered successfully!`, 'success');
  }

  hideModal('driverModal');
  renderAll();
}

async function deleteDriver(drvId) {
  const drv = state.drivers.find(d => d.id === drvId);
  if (!drv) return;

  if (confirm(`Are you sure you want to remove driver ${drv.name}?`)) {
    state.drivers = state.drivers.filter(d => d.id !== drvId);
    await deleteDriverFromFirebase(drvId);
    renderAll();
    showToast(`Driver ${drv.name} removed successfully.`, 'danger');
  }
}

// 5. Broadcast Alert Actions
function openBroadcastAlertModal() {
  document.getElementById('alertForm').reset();
  showModal('alertModal');
}

async function handleAlertSubmit(e) {
  e.preventDefault();
  const title = document.getElementById('alertTitleInput').value.trim();
  const type = document.getElementById('alertTypeSelect').value;
  const message = document.getElementById('alertMsgInput').value.trim();
  const routeId = document.getElementById('alertRouteTarget').value;

  if (!title || !message) {
    showToast('Please enter alert title and message.', 'warning');
    return;
  }

  const newAlert = {
    id: `alt_${Date.now()}`,
    title,
    type,
    message,
    routeId,
    timestamp: new Date().toLocaleString(),
    sentBy: 'Admin Control'
  };

  state.alerts.unshift(newAlert);
  await pushAlertToFirebase(newAlert);
  hideModal('alertModal');
  renderAll();
  showToast('Broadcast alert dispatched successfully!', 'success');
}

async function deleteAlert(alertId) {
  state.alerts = state.alerts.filter(a => a.id !== alertId);
  await deleteAlertFromFirebase(alertId);
  renderAll();
  showToast('Alert dismissed successfully.', 'info');
}

// ==========================================================================
// Export Utilities
// ==========================================================================
function exportFleetJSON() {
  const exportPayload = {
    exportDate: new Date().toISOString(),
    system: "UniRide Transport Management System (UET RCET Gujranwala)",
    routes: state.routes,
    buses: state.buses,
    drivers: state.drivers,
    timetables: state.timetables
  };

  const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(JSON.stringify(exportPayload, null, 2));
  const downloadAnchor = document.createElement('a');
  downloadAnchor.setAttribute("href", dataStr);
  downloadAnchor.setAttribute("download", `uniride_fleet_backup_${Date.now()}.json`);
  document.body.appendChild(downloadAnchor);
  downloadAnchor.click();
  downloadAnchor.remove();

  showToast('Fleet configuration JSON exported!', 'success');
}

function exportBusesCSV() {
  let csv = "Bus Number,Model,Route Name,Driver Name,Driver Phone,Status,Speed\n";
  state.buses.forEach(b => {
    csv += `"${b.name}","${b.model || ''}","${b.routeName}","${b.driverName}","${b.driverPhone}","${b.status}",${b.speed}\n`;
  });

  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
  const url = URL.createObjectURL(blob);
  const link = document.createElement("a");
  link.setAttribute("href", url);
  link.setAttribute("download", `uniride_buses_${Date.now()}.csv`);
  document.body.appendChild(link);
  link.click();
  link.remove();

  showToast('Buses CSV exported!', 'success');
}

function resetToDefaultData() {
  if (confirm('Reset and re-publish default university fleet data to Firebase Database?')) {
    state.routes = [...INITIAL_ROUTES];
    state.buses = [...INITIAL_BUSES];
    state.drivers = [...INITIAL_DRIVERS];
    state.timetables = [...INITIAL_TIMETABLES];
    state.alerts = [...INITIAL_ALERTS];

    state.buses.forEach(b => pushBusToFirebase(b));
    state.routes.forEach(r => pushRouteToFirebase(r));
    state.drivers.forEach(d => pushDriverToFirebase(d));
    state.timetables.forEach(t => pushTimetableToFirebase(t));
    state.alerts.forEach(a => pushAlertToFirebase(a));

    renderAll();
    drawRoutePolylines();
    showToast('Firebase Database re-synced to default fleet.', 'info');
  }
}

// Modal Helpers
function showModal(id) {
  const el = document.getElementById(id);
  if (el) el.classList.add('show');
}

function hideModal(id) {
  const el = document.getElementById(id);
  if (el) el.classList.remove('show');
}

// Toast System
function showToast(message, type = 'info') {
  const container = document.getElementById('toastContainer');
  if (!container) return;

  const toast = document.createElement('div');
  toast.className = `toast ${type}`;
  const icon = type === 'success' ? '✅' : type === 'warning' ? '⚠️' : type === 'danger' ? '❌' : 'ℹ️';

  toast.innerHTML = `
    <span style="font-size:18px;">${icon}</span>
    <div style="font-size:13px; font-weight:500; color:#0B192C;">${message}</div>
  `;

  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(100%)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 3500);
}

// ==========================================================================
// 7. Special Shuttle Schedule Announcements Management
// ==========================================================================

function openSpecialShuttleModal() {
  const form = document.getElementById('specialShuttleForm');
  if (form) form.reset();

  populateDropdownOptions();

  // Auto-set current date (YYYY-MM-DD) and departure time (1 hour in advance)
  const now = new Date();
  const pad = n => String(n).padStart(2, '0');
  const todayStr = `${now.getFullYear()}-${pad(now.getMonth() + 1)}-${pad(now.getDate())}`;
  const depTime = new Date(now.getTime() + 60 * 60 * 1000);
  const startStr = `${pad(depTime.getHours())}:${pad(depTime.getMinutes())}`;

  const dateInput = document.getElementById('specialDateInput');
  const startInput = document.getElementById('specialStartTime');
  const endInput = document.getElementById('specialEndTime');
  const routeInput = document.getElementById('specialRouteInput');

  if (dateInput) dateInput.value = todayStr;
  if (startInput) startInput.value = startStr;
  if (endInput) endInput.value = '23:59';
  if (routeInput && !routeInput.value) {
    routeInput.value = 'RCET Campus ➔ Sheikhupura Mor';
  }

  selectSpecialPurposeChip('🎓 Exam Special Departure');
  showModal('specialShuttleModal');
}

function selectSpecialPurposeChip(purpose) {
  state.selectedSpecialPurpose = purpose;
  const input = document.getElementById('specialPurposeInput');
  if (input) input.value = purpose;

  document.querySelectorAll('.purpose-chip-btn').forEach(btn => {
    btn.classList.toggle('selected', btn.innerText.trim().toLowerCase() === purpose.toLowerCase() || (btn.getAttribute('onclick') && btn.getAttribute('onclick').includes(purpose)));
  });
}

async function handleSpecialShuttleSubmit(e) {
  e.preventDefault();

  try {
    const busId = document.getElementById('specialBusSelect').value;
    const routeText = (document.getElementById('specialRouteInput').value || '').trim() || 'RCET Campus ➔ City Route';
    const purpose = (document.getElementById('specialPurposeInput').value || '').trim() || 'Special Shuttle Service';
    const tripDate = (document.getElementById('specialDateInput') && document.getElementById('specialDateInput').value)
      ? document.getElementById('specialDateInput').value
      : new Date().toISOString().split('T')[0];
    const startTime = (document.getElementById('specialStartTime') && document.getElementById('specialStartTime').value) || '07:30';
    const endTime = (document.getElementById('specialEndTime') && document.getElementById('specialEndTime').value) || '23:59';
    const broadcastAlert = document.getElementById('specialBroadcastAlertCheckbox') ? document.getElementById('specialBroadcastAlertCheckbox').checked : true;

    if (!busId) {
      showToast('Please select a bus from the fleet.', 'warning');
      return;
    }

    const bus = state.buses.find(b => b.id === busId);
    const busName = bus ? bus.name : 'University Bus';
    const shuttleId = `spec_${Date.now()}`;

    const newShuttle = {
      id: shuttleId,
      busId: busId,
      busName: busName,
      route: routeText,
      routeName: routeText,
      destination: routeText,
      purpose: purpose,
      startTime: startTime,
      endTime: endTime,
      date: tripDate,
      createdAt: Date.now(),
      status: 'active',
      isSpecial: true,
      driverName: bus ? (bus.driverName || 'Assigned Staff') : 'Assigned Staff'
    };

    // 1. Save locally and push to Firebase RTDB
    state.specialShuttles.unshift(newShuttle);
    await pushSpecialShuttleToFirebase(newShuttle);

    // 2. Broadcast instant alert to mobile app & web if enabled
    if (broadcastAlert) {
      await broadcastSystemAlert({
        title: `⚡ Special Bus: ${busName}`,
        message: `${purpose} | Route: ${routeText} | Date: ${tripDate} | Time: ${startTime} – ${endTime}`,
        type: 'info',
        busId: busId
      });
    }

    hideModal('specialShuttleModal');
    renderAll();
    showToast(`⚡ Special Shuttle ${busName} (${routeText}) scheduled successfully!`, 'success');
  } catch (err) {
    console.error('Error dispatching special shuttle:', err);
    showToast(`Failed to dispatch shuttle: ${err.message}`, 'danger');
  }
}

async function endSpecialShuttle(shuttleId) {
  const shuttle = state.specialShuttles.find(s => s.id === shuttleId);
  if (!shuttle) return;

  if (confirm(`Remove special shuttle schedule for ${shuttle.busName} (${shuttle.purpose})?`)) {
    shuttle.status = 'completed';
    shuttle.endedAt = Date.now();
    await pushSpecialShuttleToFirebase(shuttle);

    // Reset bus state if needed
    const bus = state.buses.find(b => b.id === shuttle.busId);
    if (bus) {
      bus.status = 'stopped';
      bus.is_special = false;
      delete bus.specialPurpose;
      await pushBusToFirebase(bus);
    }

    renderAll();
    showToast(`Special shuttle announcement for ${shuttle.busName} ended.`, 'info');
  }
}

// Automatic Time-Based Expiry Checker
function checkSpecialShuttlesExpiry() {
  if (!state.specialShuttles || state.specialShuttles.length === 0) return;

  const now = new Date();
  const todayStr = now.toISOString().split('T')[0];
  let updatedAny = false;

  state.specialShuttles.forEach(shuttle => {
    if (shuttle.status !== 'expired' && shuttle.status !== 'completed') {
      const shuttleDate = shuttle.date || todayStr;
      const ageHours = (Date.now() - (shuttle.createdAt || 0)) / (1000 * 60 * 60);

      let isExpired = false;
      // Expire only if scheduled for a past date and not newly created
      if (shuttleDate < todayStr && ageHours > 12) {
        isExpired = true;
      }

      if (isExpired) {
        shuttle.status = 'expired';
        shuttle.endedAt = Date.now();
        pushSpecialShuttleToFirebase(shuttle);
        updatedAny = true;
      }
    }
  });

  if (updatedAny) {
    renderAll();
  }
}

// Check every 30 seconds for auto-expiration
setInterval(checkSpecialShuttlesExpiry, 30000);

// Calculate remaining time text
function getShuttleRemainingText(endTime) {
  if (!endTime) return 'Active';
  const parts = endTime.split(':');
  if (parts.length !== 2) return 'Active';

  const now = new Date();
  const currentMinutes = now.getHours() * 60 + now.getMinutes();
  const endMinutes = parseInt(parts[0], 10) * 60 + parseInt(parts[1], 10);
  const diff = endMinutes - currentMinutes;

  if (diff <= 0) return 'Expiring soon';
  if (diff < 60) return `${diff}m remaining`;
  const hrs = Math.floor(diff / 60);
  const mins = diff % 60;
  return `${hrs}h ${mins > 0 ? mins + 'm' : ''} remaining`;
}

function getSpecialPurposeTheme(purpose) {
  const p = (purpose || '').toLowerCase();
  if (p.includes('exam')) {
    return { themeClass: 'purpose-theme-exam', icon: '🎓', label: 'Exam Session Departure' };
  } else if (p.includes('breakdown') || p.includes('emergency')) {
    return { themeClass: 'purpose-theme-emergency', icon: '🚨', label: 'Emergency Backup Fleet' };
  } else if (p.includes('sports') || p.includes('gala') || p.includes('event')) {
    return { themeClass: 'purpose-theme-sports', icon: '⚽', label: 'Campus Gala / Event Special' };
  } else if (p.includes('weather') || p.includes('rain')) {
    return { themeClass: 'purpose-theme-weather', icon: '🌧️', label: 'Weather Contingency Run' };
  } else if (p.includes('shift') || p.includes('city')) {
    return { themeClass: 'purpose-theme-general', icon: '🚌', label: 'Extra Peak Shuttle' };
  }
  return { themeClass: 'purpose-theme-general', icon: '⚡', label: 'Special Shuttle Service' };
}

function renderSpecialShuttles() {
  const activeShuttles = state.specialShuttles.filter(s => s.status === 'active');
  const pastShuttles = state.specialShuttles.filter(s => s.status !== 'active');

  // Update Metric Counters
  const heroActive = document.getElementById('heroActiveShuttlesCount');
  if (heroActive) heroActive.innerText = activeShuttles.length;
  const heroPast = document.getElementById('heroPastShuttlesCount');
  if (heroPast) heroPast.innerText = pastShuttles.length;
  const headerCount = document.getElementById('activeShuttlesHeaderCount');
  if (headerCount) headerCount.innerText = activeShuttles.length;
  const navCount = document.getElementById('navSpecialShuttleCount');
  if (navCount) navCount.innerText = activeShuttles.length;

  // 1. Overview Dynamic Banner
  const overviewBanner = document.getElementById('overviewSpecialShuttleBanner');
  if (overviewBanner) {
    if (activeShuttles.length > 0) {
      overviewBanner.style.display = 'block';
      const firstShuttle = activeShuttles[0];
      const theme = getSpecialPurposeTheme(firstShuttle.purpose);
      overviewBanner.innerHTML = `
        <div class="special-banner-card">
          <div style="display:flex; align-items:center; gap:14px;">
            <div style="width:42px; height:42px; border-radius:12px; background:#07172C; color:#FED136; display:flex; align-items:center; justify-content:center; font-size:20px; border:1.5px solid rgba(254,209,54,0.4); box-shadow:0 4px 12px rgba(10,34,64,0.3);">
              ${theme.icon}
            </div>
            <div>
              <div style="display:flex; align-items:center; gap:8px; flex-wrap:wrap;">
                <h4 style="margin:0; font-size:14.5px; color:#FED136; font-weight:800; letter-spacing:-0.2px;">
                  Active Special Shuttle: ${escapeHtml(firstShuttle.busName)}
                </h4>
                <span class="badge-special">Off-Schedule</span>
                <span class="special-countdown-pill">⏳ ${getShuttleRemainingText(firstShuttle.endTime)}</span>
              </div>
              <p style="margin:4px 0 0; font-size:12.5px; color:#E2E8F0;">
                <strong>${escapeHtml(firstShuttle.purpose)}</strong> • Route: <strong>${escapeHtml(firstShuttle.route || firstShuttle.destination)}</strong> (${firstShuttle.startTime} – ${firstShuttle.endTime})
              </p>
            </div>
          </div>
          <div style="display:flex; align-items:center; gap:8px;">
            <button class="btn btn-gold btn-sm" onclick="switchTab('special-shuttle')" style="font-weight:700;">
              View Announcements (${activeShuttles.length})
            </button>
          </div>
        </div>
      `;
    } else {
      overviewBanner.style.display = 'none';
      overviewBanner.innerHTML = '';
    }
  }

  // 2. Active Special Shuttles Grid in dedicated tab
  const activeGrid = document.getElementById('activeSpecialShuttlesGrid');
  if (activeGrid) {
    if (activeShuttles.length === 0) {
      activeGrid.innerHTML = `
        <div style="grid-column: 1 / -1; background:#FFFFFF; border:2px dashed #CBD5E1; border-radius:var(--radius-lg); padding:44px 24px; text-align:center; box-shadow:0 2px 8px rgba(0,0,0,0.02);">
          <div style="width:56px; height:56px; border-radius:16px; background:#F8FAFC; border:1px solid #E2E8F0; display:flex; align-items:center; justify-content:center; font-size:28px; margin:0 auto 14px; box-shadow:0 2px 8px rgba(0,0,0,0.04);">⚡</div>
          <h4 style="font-size:16px; font-weight:800; color:#0A2240; margin:0 0 6px;">No Active Special Shuttles Scheduled</h4>
          <p style="font-size:13px; color:#64748B; max-width:480px; margin:0 auto 18px; line-height:1.5;">
            Broadcast an on-demand transit trip with customized routes, date, and times whenever off-schedule bus support is needed for students.
          </p>
          <button class="btn btn-gold-premium" onclick="openSpecialShuttleModal()" style="padding:10px 22px;">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.6"><line x1="12" y1="5" x2="12" y2="19"></line><line x1="5" y1="12" x2="19" y2="12"></line></svg>
            <span>Dispatch Special Shuttle Now</span>
          </button>
        </div>
      `;
    } else {
      activeGrid.innerHTML = activeShuttles.map(s => {
        const routeDisplay = escapeHtml(s.route || s.destination || s.routeName || 'Special Campus Route');
        const theme = getSpecialPurposeTheme(s.purpose);

        return `
          <div class="special-shuttle-card">
            <div>
              <div class="special-card-header">
                <div class="special-bus-title">
                  <div class="license-plate-tag">
                    <span class="flag-icon">🇵🇰</span>
                    <span class="plate-number">${escapeHtml(s.busName)}</span>
                  </div>
                </div>
                <div class="special-countdown-pill">
                  <span>⏳</span> ${getShuttleRemainingText(s.endTime)}
                </div>
              </div>

              <!-- Category-Themed Purpose Banner -->
              <div class="special-purpose-banner ${theme.themeClass}">
                <span class="purpose-badge-icon">${theme.icon}</span>
                <div class="purpose-text-box">
                  <div class="purpose-type-label">${theme.label}</div>
                  <div class="purpose-title">${escapeHtml(s.purpose)}</div>
                </div>
              </div>

              <!-- Route Visual -->
              <div class="special-route-visual">
                <span class="route-arrow-icon">➔</span>
                <div class="route-text">
                  <strong>${routeDisplay}</strong>
                </div>
              </div>

              <!-- 2x2 Meta Grid -->
              <div class="special-info-grid">
                <div class="special-info-chip">
                  <span class="chip-icon">📅</span>
                  <div>
                    <div class="chip-label">Trip Date</div>
                    <div class="chip-val">${s.date || 'Today'}</div>
                  </div>
                </div>
                <div class="special-info-chip">
                  <span class="chip-icon">🕒</span>
                  <div>
                    <div class="chip-label">Operating Window</div>
                    <div class="chip-val">${s.startTime} – ${s.endTime}</div>
                  </div>
                </div>
                <div class="special-info-chip">
                  <span class="chip-icon">👨‍✈️</span>
                  <div>
                    <div class="chip-label">Assigned Driver</div>
                    <div class="chip-val">${escapeHtml(s.driverName || 'Staff Assigned')}</div>
                  </div>
                </div>
                <div class="special-info-chip">
                  <span class="chip-icon">📲</span>
                  <div>
                    <div class="chip-label">Student App</div>
                    <div class="chip-val" style="color:#059669;">Broadcast Active</div>
                  </div>
                </div>
              </div>
            </div>

            <div class="special-card-footer">
              <button class="btn-end-shuttle" onclick="endSpecialShuttle('${s.id}')">
                <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4"><circle cx="12" cy="12" r="10"></circle><line x1="15" y1="9" x2="9" y2="15"></line><line x1="9" y1="9" x2="15" y2="15"></line></svg>
                <span>End / Complete Shuttle Run</span>
              </button>
            </div>
          </div>
        `;
      }).join('');
    }
  }

  // 3. Past Special Shuttles History Table
  const historyTbody = document.getElementById('specialShuttlesHistoryTable');
  if (historyTbody) {
    if (pastShuttles.length === 0) {
      historyTbody.innerHTML = `
        <tr>
          <td colspan="6" style="text-align:center; padding:32px; color:var(--text-secondary);">
            No past special shuttle logs recorded yet.
          </td>
        </tr>
      `;
    } else {
      historyTbody.innerHTML = pastShuttles.map(s => {
        const isCompleted = s.status === 'completed';
        const routeDisplay = escapeHtml(s.route || s.destination || s.routeName || 'Special Campus Route');
        const theme = getSpecialPurposeTheme(s.purpose);

        return `
          <tr>
            <td>
              <div class="special-table-bus-cell">
                <div class="bus-avatar">🚌</div>
                <div>
                  <div style="font-weight:700; font-family:'SF Mono', Monaco, monospace; font-size:13px; color:#0A2240;">
                    ${escapeHtml(s.busName)}
                  </div>
                  <div style="font-size:11px; color:#64748B;">${s.date || 'Past'}</div>
                </div>
              </div>
            </td>
            <td>
              <div style="display:inline-flex; align-items:center; gap:6px; font-weight:600; color:#1E293B; font-size:13px;">
                <span>${theme.icon}</span>
                <span>${escapeHtml(s.purpose)}</span>
              </div>
            </td>
            <td>
              <span style="font-weight:500; color:#334155; font-size:13px;">${routeDisplay}</span>
            </td>
            <td>
              <span style="font-family:'SF Mono', Monaco, monospace; font-size:12px; color:#475569; background:#F1F5F9; border:1px solid #E2E8F0; padding:4px 8px; border-radius:6px;">
                ${s.startTime} – ${s.endTime}
              </span>
            </td>
            <td>
              <span class="special-status-badge ${isCompleted ? 'special-status-completed' : 'special-status-expired'}">
                ${isCompleted ? '✓ Completed' : '⏱ Expired'}
              </span>
            </td>
            <td>
              <button class="btn btn-secondary btn-xs" onclick="openSpecialShuttleModal()" style="font-weight:600; gap:5px; display:inline-flex; align-items:center;">
                <span>⚡</span> Re-dispatch
              </button>
            </td>
          </tr>
        `;
      }).join('');
    }
  }
}


