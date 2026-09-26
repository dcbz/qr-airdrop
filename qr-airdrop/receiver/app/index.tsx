import { useRef, useState } from 'react';
import { Alert, Pressable, SafeAreaView, StyleSheet, Text, View } from 'react-native';
import { CameraView, useCameraPermissions } from 'expo-camera';
import { File, Paths } from 'expo-file-system';
import * as Sharing from 'expo-sharing';
import { StatusBar } from 'expo-status-bar';
import { parsePacket } from '../src/transfer/protocol';
import { TransferSession } from '../src/transfer/TransferSession';

type State='idle'|'receiving'|'verifying'|'complete'|'error';
export default function Home(){
  const [permission,requestPermission]=useCameraPermissions(); const session=useRef<TransferSession|null>(null);
  const [state,setState]=useState<State>('idle'); const [revision,setRevision]=useState(0); const [fileUri,setFileUri]=useState(''); const [error,setError]=useState('');
  const busy=useRef(false); const s=session.current;
  async function scanned(data:string){
    if(busy.current||state==='complete'||state==='verifying')return; busy.current=true;
    try{
      if(!session.current){ let p; try{p=parsePacket(data)}catch{return} session.current=new TransferSession(p); setState('receiving'); }
      const result=session.current.accept(data); if(result==='new') setRevision(x=>x+1);
      if(session.current.complete){ setState('verifying'); const bytes=session.current.assemble(); const safe=session.current.meta.n.replace(/[^a-zA-Z0-9._-]/g,'_'); const file=new File(Paths.document,safe); if(file.exists)file.delete(); file.create(); file.write(bytes); setFileUri(file.uri); setState('complete'); }
    }catch(e){setError(e instanceof Error?e.message:'Transfer failed');setState('error')}finally{busy.current=false}
  }
  function reset(){session.current=null;setFileUri('');setError('');setState('idle');setRevision(x=>x+1)}
  if(!permission)return <View style={styles.center}><Text style={styles.text}>Checking camera…</Text></View>;
  if(!permission.granted)return <SafeAreaView style={styles.center}><Text style={styles.title}>Camera access</Text><Text style={styles.sub}>QR AirDrop needs the camera to receive file frames.</Text><Pressable style={styles.button} onPress={requestPermission}><Text style={styles.buttonText}>Allow Camera</Text></Pressable></SafeAreaView>;
  const received=s?.received??0,total=s?.meta.t??0,percent=s?.percent??0;
  return <View style={styles.root}><StatusBar style="light"/><CameraView style={StyleSheet.absoluteFill} facing="back" barcodeScannerSettings={{barcodeTypes:['qr']}} onBarcodeScanned={e=>scanned(e.data)}/><View style={styles.shade}/><SafeAreaView style={styles.overlay}>
    <View style={styles.header}><Text style={styles.eyebrow}>{state==='idle'?'READY TO RECEIVE':state.toUpperCase()}</Text><Text numberOfLines={1} style={styles.title}>{s?.meta.n??'Point at the QR transfer'}</Text>{s&&<><Text style={styles.progress}>{received} / {total} · {percent}%</Text><View style={styles.track}><View style={[styles.fill,{width:`${percent}%`}]}/></View><Text style={styles.stats}>Missing {total-received}   Duplicates {s.duplicates}   Invalid {s.invalid}</Text></>}</View>
    <View style={[styles.target,state==='receiving'&&styles.targetActive]}><View style={styles.corner}/></View>
    <View style={styles.footer}>{state==='complete'&&<><Text style={styles.done}>✓ Transfer complete</Text><Pressable style={styles.button} onPress={()=>Sharing.shareAsync(fileUri)}><Text style={styles.buttonText}>Share or Save File</Text></Pressable><Pressable onPress={reset}><Text style={styles.link}>Receive another</Text></Pressable></>}{state==='receiving'&&<Pressable onPress={reset}><Text style={styles.link}>Cancel transfer</Text></Pressable>}{state==='error'&&<><Text style={styles.error}>{error}</Text><Pressable style={styles.button} onPress={reset}><Text style={styles.buttonText}>Start Over</Text></Pressable></>}</View>
  </SafeAreaView></View>;
}
const styles=StyleSheet.create({root:{flex:1,backgroundColor:'#05070a'},center:{flex:1,backgroundColor:'#090c11',alignItems:'center',justifyContent:'center',padding:28},text:{color:'white'},sub:{color:'#aeb7c6',fontSize:16,textAlign:'center',marginVertical:16},shade:{...StyleSheet.absoluteFill,backgroundColor:'rgba(0,0,0,.28)'},overlay:{flex:1,justifyContent:'space-between',alignItems:'center'},header:{width:'100%',padding:22,backgroundColor:'rgba(3,6,10,.75)'},eyebrow:{color:'#63e6be',fontSize:12,fontWeight:'800',letterSpacing:1.5},title:{color:'white',fontSize:24,fontWeight:'700',marginTop:5},progress:{color:'white',fontSize:32,fontWeight:'300',marginTop:10},track:{height:6,backgroundColor:'#39414d',borderRadius:4,marginTop:8,overflow:'hidden'},fill:{height:'100%',backgroundColor:'#63e6be'},stats:{color:'#c5ccd7',fontSize:12,marginTop:8},target:{width:265,height:265,borderWidth:2,borderColor:'rgba(255,255,255,.75)',borderRadius:24},targetActive:{borderColor:'#63e6be'},corner:{width:24,height:24,borderTopWidth:5,borderLeftWidth:5,borderColor:'#63e6be',borderTopLeftRadius:8,margin:-3},footer:{minHeight:150,width:'100%',padding:22,alignItems:'center',justifyContent:'center',backgroundColor:'rgba(3,6,10,.75)'},button:{backgroundColor:'#63e6be',borderRadius:14,paddingVertical:14,paddingHorizontal:24,marginTop:14},buttonText:{color:'#05120e',fontWeight:'800',fontSize:16},link:{color:'white',fontSize:16,padding:16},done:{color:'white',fontSize:21,fontWeight:'700'},error:{color:'#ff8787',fontSize:16,textAlign:'center'}});
