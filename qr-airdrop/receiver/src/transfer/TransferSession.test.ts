import { sha256 } from '@noble/hashes/sha2.js';
import { bytesToHex } from '@noble/hashes/utils.js';
import { fromByteArray } from 'base64-js';
import { TransferSession } from './TransferSession';

const enc = new TextEncoder();
function packets(text:string, size=4) { const all=enc.encode(text), f=bytesToHex(sha256(all)), t=Math.ceil(all.length/size); return Array.from({length:t},(_,i)=>{const c=all.slice(i*size,(i+1)*size); return JSON.stringify({v:1,id:'abcdef123456',n:'x.txt',s:all.length,i,t,d:fromByteArray(c),h:bytesToHex(sha256(c)),f});}); }
test('accepts shuffled packets and duplicates',()=>{const p=packets('hello optical world'); const s=TransferSession.fromPayload(p[0]); expect(s.accept(p[2])).toBe('new'); expect(s.accept(p[0])).toBe('new'); expect(s.accept(p[0])).toBe('duplicate'); for(const x of p.slice(1)) s.accept(x); expect(new TextDecoder().decode(s.assemble())).toBe('hello optical world');});
test('rejects malformed and damaged chunks',()=>{const p=packets('abcdef'); const s=TransferSession.fromPayload(p[0]); expect(s.accept('nope')).toBe('invalid'); const bad=JSON.parse(p[1]); bad.d='AAAA'; expect(s.accept(JSON.stringify(bad))).toBe('invalid');});

