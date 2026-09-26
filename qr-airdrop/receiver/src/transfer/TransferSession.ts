import { fromByteArray, toByteArray } from 'base64-js';
import { sha256 } from '@noble/hashes/sha2.js';
import { bytesToHex } from '@noble/hashes/utils.js';
import { Packet, parsePacket } from './protocol';

export type AcceptResult = 'new' | 'duplicate' | 'invalid' | 'other-transfer';
export class TransferSession {
  readonly meta: Pick<Packet, 'id'|'n'|'s'|'t'|'f'>;
  private chunks = new Map<number, Uint8Array>();
  duplicates = 0; invalid = 0;
  constructor(first: Packet) { this.meta = { id:first.id, n:first.n, s:first.s, t:first.t, f:first.f }; }
  static fromPayload(raw: string) { return new TransferSession(parsePacket(raw)); }
  accept(raw: string): AcceptResult {
    let p: Packet;
    try { p = parsePacket(raw); } catch { this.invalid++; return 'invalid'; }
    const m = this.meta;
    if (p.id !== m.id) return 'other-transfer';
    if (p.n !== m.n || p.s !== m.s || p.t !== m.t || p.f !== m.f) { this.invalid++; return 'invalid'; }
    let bytes: Uint8Array;
    try { bytes = toByteArray(p.d); } catch { this.invalid++; return 'invalid'; }
    if (bytesToHex(sha256(bytes)) !== p.h) { this.invalid++; return 'invalid'; }
    const old = this.chunks.get(p.i);
    if (old) { this.duplicates++; return 'duplicate'; }
    this.chunks.set(p.i, bytes); return 'new';
  }
  get received() { return this.chunks.size; }
  get percent() { return Math.floor(this.received / this.meta.t * 100); }
  get complete() { return this.received === this.meta.t; }
  missing() { const out:number[]=[]; for(let i=0;i<this.meta.t;i++) if(!this.chunks.has(i)) out.push(i); return out; }
  assemble(): Uint8Array {
    if (!this.complete) throw new Error('Transfer is incomplete');
    const out = new Uint8Array(this.meta.s); let offset=0;
    for(let i=0;i<this.meta.t;i++){ const c=this.chunks.get(i)!; if(offset+c.length>out.length) throw new Error('File is larger than declared'); out.set(c,offset); offset+=c.length; }
    if(offset!==this.meta.s) throw new Error('File size mismatch');
    if(bytesToHex(sha256(out))!==this.meta.f) throw new Error('File hash mismatch');
    return out;
  }
  assembledBase64() { return fromByteArray(this.assemble()); }
}

