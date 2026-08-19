export interface Point { lat: number; lng: number }
const R = 6_371_000;
const rad = (d: number) => d * Math.PI / 180;
export function haversineMetres(a: Point, b: Point) {
  const dLat = rad(b.lat - a.lat); const dLng = rad(b.lng - a.lng);
  const h = Math.sin(dLat/2)**2 + Math.cos(rad(a.lat))*Math.cos(rad(b.lat))*Math.sin(dLng/2)**2;
  return R * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1-h));
}
