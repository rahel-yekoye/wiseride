// Fare Calculation Service
// Calculates ride fares based on distance, time, and surge pricing

const PRICING_CONFIG = {
  perKmRate: 15, // ETB per km
  perMinuteRate: 2, // ETB per minute
  minimumFare: 30, // ETB
  
  // Vehicle type multipliers and base fares
  vehicleMultipliers: {
    taxi: 1.0,
    private_car: 1.2,
    minibus: 0.8,  // Lower for shared rides
    bus: 0.5,      // Much lower for public transport
  },
  
  // Base fares by vehicle type (in ETB)
  baseFares: {
    taxi: 50,
    private_car: 60,
    minibus: 30,   // Lower base for minibus
    bus: 15,       // Much lower for bus
  },
  
  // Time-based surge pricing
  surgePricing: {
    enabled: true,
    peakHours: [
      { start: 7, end: 9, multiplier: 1.5 },   // Morning rush
      { start: 17, end: 19, multiplier: 1.5 }, // Evening rush
    ],
    nightTime: { start: 22, end: 5, multiplier: 1.3 }, // Night time
  },
  
  // Day-based pricing
  weekendMultiplier: 1.1,
  
  // Weather conditions (can be integrated with weather API)
  weatherMultipliers: {
    rain: 1.2,
    storm: 1.5,
  },
};

/**
 * Calculate distance between two coordinates (Haversine formula)
 * @param {number} lat1 - Latitude of point 1
 * @param {number} lng1 - Longitude of point 1
 * @param {number} lat2 - Latitude of point 2
 * @param {number} lng2 - Longitude of point 2
 * @returns {number} Distance in kilometers
 */
function calculateDistance(lat1, lng1, lat2, lng2) {
  const R = 6371; // Earth's radius in km
  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);
  
  const a = 
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  const distance = R * c;
  
  return distance;
}

function toRad(degrees) {
  return degrees * (Math.PI / 180);
}

/**
 * Estimate trip duration based on distance
 * @param {number} distanceKm - Distance in kilometers
 * @returns {number} Estimated duration in minutes
 */
function estimateDuration(distanceKm) {
  // Assuming average speed of 30 km/h in city traffic
  const averageSpeed = 30;
  const hours = distanceKm / averageSpeed;
  return Math.ceil(hours * 60); // Convert to minutes
}

/**
 * Get surge multiplier based on current time
 * @returns {number} Surge multiplier
 */
function getSurgeMultiplier() {
  if (!PRICING_CONFIG.surgePricing.enabled) return 1.0;
  
  const now = new Date();
  const hour = now.getHours();
  const day = now.getDay(); // 0 = Sunday, 6 = Saturday
  
  let multiplier = 1.0;
  
  // Check peak hours
  for (const peak of PRICING_CONFIG.surgePricing.peakHours) {
    if (hour >= peak.start && hour < peak.end) {
      multiplier = Math.max(multiplier, peak.multiplier);
    }
  }
  
  // Check night time
  const night = PRICING_CONFIG.surgePricing.nightTime;
  if (hour >= night.start || hour < night.end) {
    multiplier = Math.max(multiplier, night.multiplier);
  }
  
  // Check weekend
  if (day === 0 || day === 6) {
    multiplier *= PRICING_CONFIG.weekendMultiplier;
  }
  
  return multiplier;
}

/**
 * Calculate fare estimate
 * @param {Object} params - Calculation parameters
 * @param {number} params.originLat - Origin latitude
 * @param {number} params.originLng - Origin longitude
 * @param {number} params.destLat - Destination latitude
 * @param {number} params.destLng - Destination longitude
 * @param {string} params.vehicleType - Type of vehicle
 * @param {string} params.weatherCondition - Current weather (optional)
 * @returns {Object} Fare breakdown
 */
function calculateFareEstimate({ 
  originLat, 
  originLng, 
  destLat, 
  destLng, 
  vehicleType = 'taxi',
  weatherCondition = null 
}) {
  // Calculate distance
  const distanceKm = calculateDistance(originLat, originLng, destLat, destLng);
  
  // Estimate duration
  const durationMinutes = estimateDuration(distanceKm);
  
  // Get base fare for vehicle type
  const baseFare = PRICING_CONFIG.baseFares[vehicleType] || PRICING_CONFIG.baseFares.taxi;
  
  // Base calculation
  let fare = baseFare;
  fare += distanceKm * PRICING_CONFIG.perKmRate;
  fare += durationMinutes * PRICING_CONFIG.perMinuteRate;
  
  // Apply vehicle type multiplier
  const vehicleMultiplier = PRICING_CONFIG.vehicleMultipliers[vehicleType] || 1.0;
  fare *= vehicleMultiplier;
  
  // Apply surge pricing
  const surgeMultiplier = getSurgeMultiplier();
  const surgeAmount = fare * (surgeMultiplier - 1);
  fare *= surgeMultiplier;
  
  // Apply weather multiplier if applicable
  let weatherMultiplier = 1.0;
  if (weatherCondition && PRICING_CONFIG.weatherMultipliers[weatherCondition]) {
    weatherMultiplier = PRICING_CONFIG.weatherMultipliers[weatherCondition];
    fare *= weatherMultiplier;
  }
  
  // Ensure minimum fare
  fare = Math.max(fare, PRICING_CONFIG.minimumFare);
  
  // Round to nearest 5 ETB
  fare = Math.ceil(fare / 5) * 5;
  
  return {
    estimatedFare: fare,
    breakdown: {
      baseFare: PRICING_CONFIG.baseFare,
      distanceFare: distanceKm * PRICING_CONFIG.perKmRate,
      timeFare: durationMinutes * PRICING_CONFIG.perMinuteRate,
      surgeAmount: surgeAmount,
      vehicleMultiplier: vehicleMultiplier,
      surgeMultiplier: surgeMultiplier,
      weatherMultiplier: weatherMultiplier,
    },
    tripDetails: {
      distanceKm: parseFloat(distanceKm.toFixed(2)),
      estimatedDuration: durationMinutes,
      vehicleType: vehicleType,
    },
    priceRange: {
      min: Math.floor(fare * 0.9 / 5) * 5, // -10%
      max: Math.ceil(fare * 1.1 / 5) * 5,  // +10%
    },
  };
}

/**
 * Calculate actual fare after ride completion
 * @param {Object} params - Calculation parameters
 * @param {number} params.distanceKm - Actual distance traveled
 * @param {number} params.durationMinutes - Actual duration
 * @param {string} params.vehicleType - Type of vehicle
 * @param {number} params.waitingTimeMinutes - Waiting time (optional)
 * @returns {Object} Final fare breakdown
 */
function calculateActualFare({
  distanceKm,
  durationMinutes,
  vehicleType = 'taxi',
  waitingTimeMinutes = 0,
}) {
  let fare = PRICING_CONFIG.baseFare;
  fare += distanceKm * PRICING_CONFIG.perKmRate;
  fare += durationMinutes * PRICING_CONFIG.perMinuteRate;
  
  // Add waiting time charge (if applicable)
  const waitingCharge = waitingTimeMinutes * 1.5; // 1.5 ETB per minute
  fare += waitingCharge;
  
  // Apply vehicle type multiplier
  const vehicleMultiplier = PRICING_CONFIG.vehicleMultipliers[vehicleType] || 1.0;
  fare *= vehicleMultiplier;
  
  // Apply surge pricing
  const surgeMultiplier = getSurgeMultiplier();
  fare *= surgeMultiplier;
  
  // Ensure minimum fare
  fare = Math.max(fare, PRICING_CONFIG.minimumFare);
  
  // Round to nearest 5 ETB
  fare = Math.ceil(fare / 5) * 5;
  
  return {
    totalFare: fare,
    breakdown: {
      baseFare: PRICING_CONFIG.baseFare,
      distanceFare: distanceKm * PRICING_CONFIG.perKmRate,
      timeFare: durationMinutes * PRICING_CONFIG.perMinuteRate,
      waitingCharge: waitingCharge,
      vehicleMultiplier: vehicleMultiplier,
      surgeMultiplier: surgeMultiplier,
    },
  };
}

module.exports = {
  calculateFareEstimate,
  calculateActualFare,
  calculateDistance,
  estimateDuration,
  getSurgeMultiplier,
  PRICING_CONFIG,
};
