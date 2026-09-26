export type Packet = { v: 1; id: string; n: string; s: number; i: number; t: number; d: string; h: string; f: string };
const hex64 = /^[0-9a-f]{64}$/;
export function parsePacket(raw: string): Packet {
  const p: unknown = JSON.parse(raw);
  if (!p || typeof p !== 'object') throw new Error('Packet is not an object');
  const x = p as Record<string, unknown>;
  if (x.v !== 1 || typeof x.id !== 'string' || !/^[0-9a-f]{12}$/.test(x.id) || typeof x.n !== 'string' || !x.n || x.n.includes('/') || x.n.includes('\\') || !Number.isSafeInteger(x.s) || (x.s as number) < 0 || !Number.isSafeInteger(x.i) || !Number.isSafeInteger(x.t) || (x.t as number) < 1 || (x.i as number) < 0 || (x.i as number) >= (x.t as number) || typeof x.d !== 'string' || typeof x.h !== 'string' || !hex64.test(x.h) || typeof x.f !== 'string' || !hex64.test(x.f)) throw new Error('Invalid packet fields');
  return x as Packet;
}

