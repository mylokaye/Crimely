import CoreLocation

@inline(__always)
func haversineDistanceMeters(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
    let r = 6_371_000.0
    let dLat = (b.latitude - a.latitude) * .pi / 180
    let dLon = (b.longitude - a.longitude) * .pi / 180
    let la1 = a.latitude * .pi / 180
    let la2 = b.latitude * .pi / 180
    let h = sin(dLat/2)*sin(dLat/2) + sin(dLon/2)*sin(dLon/2) * cos(la1)*cos(la2)
    return 2*r*asin(min(1, sqrt(h)))
}