<?php

namespace App\Services;

class GeoService
{
    /**
     * Calculate distance between two GPS coordinates using Haversine formula.
     *
     * @param float $lat1 Latitude of point 1
     * @param float $lon1 Longitude of point 1
     * @param float $lat2 Latitude of point 2
     * @param float $lon2 Longitude of point 2
     * @return float Distance in meters
     */
    public function calculateDistance(float $lat1, float $lon1, float $lat2, float $lon2): float
    {
        $earthRadius = 6371000; // meters

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2)
            + cos(deg2rad($lat1)) * cos(deg2rad($lat2))
            * sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return round($earthRadius * $c, 2);
    }

    /**
     * Check if a point is within a given radius of a center point.
     *
     * @param float $lat User latitude
     * @param float $lon User longitude
     * @param float $centerLat Center latitude (location)
     * @param float $centerLon Center longitude (location)
     * @param int $radius Radius in meters
     * @return array{within: bool, distance: float}
     */
    public function isWithinRadius(
        float $lat,
        float $lon,
        float $centerLat,
        float $centerLon,
        int $radius
    ): array {
        $distance = $this->calculateDistance($lat, $lon, $centerLat, $centerLon);

        return [
            'within' => $distance <= $radius,
            'distance' => $distance,
        ];
    }
}
