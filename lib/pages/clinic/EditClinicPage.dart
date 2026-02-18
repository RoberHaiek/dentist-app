import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────
class _Member {
  String id, name, role, experience;
  List<String> specs;
  String? photoUrl;
  _Member({required this.id, required this.name, this.role='', this.experience='', this.specs=const[], this.photoUrl});
  factory _Member.from(Map<String,dynamic> m) => _Member(
    id: m['id'] as String? ?? UniqueKey().toString(),
    name: m['name'] as String? ?? '', role: m['role'] as String? ?? '',
    experience: m['experience'] as String? ?? '',
    specs: List<String>.from(m['specializations'] as List? ?? []),
    photoUrl: m['photoUrl'] as String?,
  );
  Map<String,dynamic> toMap() => {'id':id,'name':name,'role':role,'experience':experience,'specializations':specs,'photoUrl':photoUrl};
}

class _GalCat {
  String id, name;
  List<String> urls;
  _GalCat({required this.id, required this.name, this.urls=const[]});
  factory _GalCat.from(Map<String,dynamic> m) => _GalCat(
    id: m['id'] as String? ?? UniqueKey().toString(),
    name: m['name'] as String? ?? 'Gallery',
    urls: List<String>.from(m['photoUrls'] as List? ?? []),
  );
  Map<String,dynamic> toMap() => {'id':id,'name':name,'photoUrls':urls};
}

class _DayH {
  bool open, brk;
  TimeOfDay s1,e1,s2,e2;
  _DayH({this.open=true,this.brk=false,TimeOfDay? s1,TimeOfDay? e1,TimeOfDay? s2,TimeOfDay? e2})
      :s1=s1??const TimeOfDay(hour:9,minute:0), e1=e1??const TimeOfDay(hour:13,minute:0),
        s2=s2??const TimeOfDay(hour:16,minute:0), e2=e2??const TimeOfDay(hour:20,minute:0);
  static TimeOfDay _p(String? s){if(s==null||s.isEmpty)return const TimeOfDay(hour:9,minute:0);final p=s.split(':');return TimeOfDay(hour:int.tryParse(p[0])??9,minute:int.tryParse(p[1])??0);}
  static String _f(TimeOfDay t)=>'${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
  factory _DayH.from(Map<String,dynamic> m)=>_DayH(open:m['open'] as bool?? true,brk:m['hasBreak'] as bool?? false,s1:_p(m['start1'] as String?),e1:_p(m['end1'] as String?),s2:_p(m['start2'] as String?),e2:_p(m['end2'] as String?));
  Map<String,dynamic> toMap()=>{'open':open,'hasBreak':brk,'start1':_f(s1),'end1':_f(e1),'start2':_f(s2),'end2':_f(e2)};
  String get display{if(!open)return 'Closed';final r='${_f(s1)} – ${_f(e1)}';return brk?'$r,  ${_f(s2)} – ${_f(e2)}':r;}
}

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────
const _kTech=['Digital X-Ray','CBCT 3D Imaging','Laser Dentistry','CAD/CAM (CEREC)','Intraoral Camera','Digital Impressions','Air Abrasion','Piezo Surgery','Ozone Therapy','Microscope Dentistry'];
const _kPay =['Cash','Credit Card','Debit Card','Bank Transfer','Health Fund','Installments','Cryptocurrency'];
const _kIns =['Maccabi','Clalit','Meuhedet','Leumit','Harel','Migdal','Phoenix','Ayalon','Menora','No Insurance'];
const _kLang=['Hebrew','Arabic','English','Russian','French','Spanish','Amharic','Romanian','Portuguese'];
const _kPark=['Free Parking','Paid Parking','Street Parking','Wheelchair Access','Elevator','Ground Floor','Public Transport Nearby'];
const _kSvc =['General Dentistry','Teeth Cleaning','Whitening','Fillings','Root Canal','Crowns & Bridges','Implants','Orthodontics','Invisalign','Veneers','Dentures','Pediatric Dentistry','Periodontics','Oral Surgery','Emergency Care','Sedation Dentistry'];
const _kDays=['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];


// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────
class EditClinicPage extends StatefulWidget {
  const EditClinicPage({super.key});
  @override State<EditClinicPage> createState() => _EditClinicPageState();
}

class _EditClinicPageState extends State<EditClinicPage> with SingleTickerProviderStateMixin {
  late TabController _tc;
  bool _loading=true, _saving=false;

  // Identity
  String _name=''; String? _logoUrl; File? _logoFile;

  // Text fields
  final _aboutC=TextEditingController();
  final _addrC=TextEditingController();
  final _phoneC=TextEditingController();
  final _emailC=TextEditingController();

  // Sets
  Set<String> _tech={},_ins={},_pay={},_lang={},_park={},_svc={};
  List<String> _certs=[];
  List<_Member> _team=[];
  List<_GalCat> _gal=[];
  final Map<String,_DayH> _hrs={ for(final d in _kDays) d:_DayH() };

  @override void initState(){ super.initState(); _tc=TabController(length:5,vsync:this); _load(); }
  @override void dispose(){ _tc.dispose(); _aboutC.dispose(); _addrC.dispose(); _phoneC.dispose(); _emailC.dispose(); super.dispose(); }

  Future<void> _load() async {
    final u=FirebaseAuth.instance.currentUser;
    if(u==null){setState(()=>_loading=false);return;}
    try{
      final d=(await FirebaseFirestore.instance.collection('clinics').doc(u.uid).get()).data()??{};
      setState((){
        _name=d['clinicName'] as String?? ''; _logoUrl=d['logoUrl'] as String?;
        _aboutC.text=d['about'] as String?? ''; _addrC.text=d['address'] as String?? '';
        _phoneC.text=d['phone'] as String?? ''; _emailC.text=d['email'] as String?? '';
        _tech=Set<String>.from(d['technologies'] as List?? []); _ins=Set<String>.from(d['insurances'] as List?? []);
        _pay=Set<String>.from(d['paymentMethods'] as List?? []); _lang=Set<String>.from(d['languages'] as List?? []);
        _park=Set<String>.from(d['parking'] as List?? []); _svc=Set<String>.from(d['services'] as List?? []);
        _certs=List<String>.from(d['certificates'] as List?? []);
        _team=(d['team'] as List?? []).map((e)=>_Member.from(Map<String,dynamic>.from(e as Map))).toList();
        _gal=(d['gallery'] as List?? []).map((e)=>_GalCat.from(Map<String,dynamic>.from(e as Map))).toList();
        final hm=d['openingHours'] as Map<String,dynamic>?? {};
        for(final day in _kDays){ if(hm.containsKey(day)) _hrs[day]=_DayH.from(Map<String,dynamic>.from(hm[day] as Map)); }
        _loading=false;
      });
    }catch(e){debugPrint('load:$e');setState(()=>_loading=false);}
  }

  Future<void> _save() async {
    final u=FirebaseAuth.instance.currentUser;
    if(u==null) return;
    setState(()=>_saving=true);
    try{
      if(_logoFile!=null){
        final logoFile = _logoFile!;
        final u2 = u;
        _logoUrl = await Future.microtask(() async {
          final snap = await FirebaseStorage.instance.ref('clinics/${u2.uid}/logo.jpg').putFile(logoFile);
          return snap.ref.getDownloadURL();
        });
        _logoFile=null;
      }
      await FirebaseFirestore.instance.collection('clinics').doc(u.uid).set({
        'logoUrl':_logoUrl,'about':_aboutC.text.trim(),'address':_addrC.text.trim(),
        'phone':_phoneC.text.trim(),'email':_emailC.text.trim(),
        'technologies':_tech.toList(),'certificates':_certs,'insurances':_ins.toList(),
        'paymentMethods':_pay.toList(),'languages':_lang.toList(),'parking':_park.toList(),
        'services':_svc.toList(),'team':_team.map((m)=>m.toMap()).toList(),
        'gallery':_gal.map((g)=>g.toMap()).toList(),
        'openingHours':{ for(final d in _kDays) d:_hrs[d]!.toMap() },
        'updatedAt':FieldValue.serverTimestamp(),
      },SetOptions(merge:true));
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Profile saved!'),backgroundColor:Color(0xFF7DD3C0)));
    }catch(e){
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Save failed: $e'),backgroundColor:Colors.red));
    }finally{ if(mounted) setState(()=>_saving=false); }
  }

  Future<File?> _pick() async {
    final xf=await ImagePicker().pickImage(source:ImageSource.gallery,imageQuality:85);
    return xf==null?null:File(xf.path);
  }
  Future<String> _upload(File f, String path) async {
    // Run the upload task inside Future.microtask to keep it on the Dart event
    // loop — this avoids the firebase_storage iOS plugin threading warning where
    // native callbacks fire on a background thread instead of the platform thread.
    return Future.microtask(() async {
      final task = FirebaseStorage.instance.ref(path).putFile(f);
      final snap = await task;
      return snap.ref.getDownloadURL();
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context){
    if(_loading) return const Scaffold(backgroundColor:Color(0xFFF2EBE2),body:Center(child:CircularProgressIndicator(color:Color(0xFF7DD3C0))));
    return Scaffold(
      backgroundColor: const Color(0xFFF2EBE2),
      body: NestedScrollView(
        headerSliverBuilder:(ctx,_)=>[
          SliverAppBar(
            expandedHeight:380, pinned:true, backgroundColor:const Color(0xFF7DD3C0),
            leading:IconButton(icon:const Icon(Icons.arrow_back,color:Colors.white),onPressed:()=>Navigator.pop(context)),
            actions:[
              TextButton.icon(
                onPressed:()=>ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Patient view coming soon'))),
                icon:const Icon(Icons.visibility_outlined,color:Colors.white,size:18),
                label:const Text('View as Patient',style:TextStyle(color:Colors.white,fontSize:13)),
              ),
              _saving
                  ? const Padding(padding:EdgeInsets.symmetric(horizontal:14,vertical:14),child:SizedBox(width:20,height:20,child:CircularProgressIndicator(color:Colors.white,strokeWidth:2)))
                  : TextButton.icon(onPressed:_save,
                  icon:const Icon(Icons.check,color:Colors.white,size:18),
                  label:const Text('Save',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold,fontSize:14))),
              const SizedBox(width:4),
            ],
            flexibleSpace:FlexibleSpaceBar(background:_buildHero()),
            bottom:PreferredSize(
              preferredSize:const Size.fromHeight(48),
              child:Container(
                color:const Color(0xFFF2EBE2),
                child:TabBar(
                  controller:_tc, isScrollable:true,
                  indicatorColor:const Color(0xFF7DD3C0), indicatorWeight:3,
                  labelColor:const Color(0xFF7DD3C0), unselectedLabelColor:Colors.grey,
                  labelStyle:const TextStyle(fontWeight:FontWeight.bold,fontSize:15),
                  unselectedLabelStyle:const TextStyle(fontWeight:FontWeight.w600,fontSize:14),
                  tabs:const[Tab(text:'About'),Tab(text:'Team'),Tab(text:'Services'),Tab(text:'Gallery'),Tab(text:'Contact')],
                ),
              ),
            ),
          ),
        ],
        body:TabBarView(controller:_tc,children:[_tabAbout(),_tabTeam(),_tabServices(),_tabGallery(),_tabContact()]),
      ),
    );
  }

  // ── Hero (identical structure to ClinicProfilePage, logo tappable) ─────────
  Widget _buildHero(){
    return Container(
      decoration:const BoxDecoration(gradient:LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFFA8E6CF),Color(0xFF7DD3C0)])),
      child:SafeArea(child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
        const SizedBox(height:10),
        GestureDetector(
          onTap:() async{ final f=await _pick(); if(f!=null&&mounted) setState(()=>_logoFile=f); },
          child:Stack(alignment:Alignment.center,children:[
            Container(
              width:100,height:100,padding:const EdgeInsets.all(8),
              decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),
                  boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.1),blurRadius:15,offset:const Offset(0,5))]),
              child:ClipRRect(borderRadius:BorderRadius.circular(12),
                  child:_logoFile!=null
                      ? Image.file(_logoFile!,fit:BoxFit.cover,width:double.infinity,height:double.infinity)
                      : (_logoUrl!=null
                      ? Image.network(_logoUrl!,fit:BoxFit.cover,width:double.infinity,height:double.infinity,
                      errorBuilder:(_,__,___)=>const Icon(Icons.business,size:48,color:Color(0xFF7DD3C0)))
                      : const Icon(Icons.business,size:48,color:Color(0xFF7DD3C0)))),
            ),
            // Camera overlay — matches the "tap to change" affordance
            Container(width:100,height:100,
                decoration:BoxDecoration(borderRadius:BorderRadius.circular(20),color:Colors.black.withOpacity(0.28)),
                child:const Icon(Icons.camera_alt,color:Colors.white,size:28)),
          ]),
        ),
        const SizedBox(height:16),
        Text(_name.isNotEmpty?_name:'Your Clinic',
            style:const TextStyle(fontSize:26,fontWeight:FontWeight.bold,color:Colors.white)),
        const SizedBox(height:4),
        const Text('Tap logo to change  •  Press Save when done',
            style:TextStyle(fontSize:13,color:Colors.white70)),
        const SizedBox(height:20),
        // Same 4 quick-action buttons as ClinicProfilePage (decorative in edit mode)
        Padding(
          padding:const EdgeInsets.symmetric(horizontal:20),
          child:Row(children:[
            Expanded(child:_qBtn(Icons.phone,'Call')),         const SizedBox(width:12),
            Expanded(child:_qBtn(Icons.chat,'WhatsApp')),      const SizedBox(width:12),
            Expanded(child:_qBtn(Icons.calendar_today,'Book')),const SizedBox(width:12),
            Expanded(child:_qBtn(Icons.map,'Map')),
          ]),
        ),
        const SizedBox(height:10),
      ])),
    );
  }

  Widget _qBtn(IconData icon,String label)=>Container(
    padding:const EdgeInsets.symmetric(vertical:16,horizontal:6),
    decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),
        boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.1),blurRadius:8,offset:const Offset(0,2))]),
    child:Column(mainAxisSize:MainAxisSize.min,children:[
      Icon(icon,color:const Color(0xFF7DD3C0),size:24),
      const SizedBox(height:6),
      Text(label,style:const TextStyle(fontSize:11,fontWeight:FontWeight.w600,color:Color(0xFF333333)),textAlign:TextAlign.center,maxLines:1,overflow:TextOverflow.ellipsis),
    ]),
  );

  // ── Shared helpers matching ClinicProfilePage exactly ─────────────────────
  Widget _secTitle(String title,IconData icon)=>Row(children:[
    Icon(icon,color:const Color(0xFF7DD3C0),size:22),const SizedBox(width:8),
    Text(title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:Color(0xFF333333))),
  ]);

  Widget _card(Widget child)=>Container(
    padding:const EdgeInsets.all(16),
    decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),
        boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:10,offset:const Offset(0,2))]),
    child:child,
  );

  InputDecoration _dec(String hint,{IconData? icon})=>InputDecoration(
    hintText:hint,hintStyle:const TextStyle(color:Color(0xFFAAAAAA),fontSize:14),
    prefixIcon:icon!=null?Icon(icon,color:const Color(0xFF7DD3C0),size:20):null,
    filled:true,fillColor:Colors.white,
    border:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:BorderSide(color:Colors.grey.shade200)),
    enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:BorderSide(color:Colors.grey.shade200)),
    focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:const BorderSide(color:Color(0xFF7DD3C0),width:2)),
    contentPadding:const EdgeInsets.symmetric(horizontal:14,vertical:12),
  );

  // Selectable chips — same visual style as ClinicProfilePage language chips, but toggle-able
  Widget _chips(List<String> opts,Set<String> sel)=>Wrap(spacing:8,runSpacing:8,
    children:opts.map((o){
      final on=sel.contains(o);
      return GestureDetector(
        onTap:()=>setState(()=>on?sel.remove(o):sel.add(o)),
        child:AnimatedContainer(duration:const Duration(milliseconds:150),
          padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),
          decoration:BoxDecoration(
              color:on?const Color(0xFFA8E6CF).withOpacity(0.2):Colors.white,
              borderRadius:BorderRadius.circular(16),
              border:Border.all(color:on?const Color(0xFF7DD3C0):Colors.grey.shade300,width:1.5)),
          child:Row(mainAxisSize:MainAxisSize.min,children:[
            if(on) const Padding(padding:EdgeInsets.only(right:5),child:Icon(Icons.check_circle,size:13,color:Color(0xFF7DD3C0))),
            Text(o,style:TextStyle(fontSize:13,fontWeight:on?FontWeight.w600:FontWeight.normal,color:on?const Color(0xFF7DD3C0):const Color(0xFF555555))),
          ]),
        ),
      );
    }).toList(),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 1: About  (matches ClinicProfilePage._buildAboutTab exactly)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _tabAbout(){
    return SingleChildScrollView(
      padding:const EdgeInsets.all(20),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[

        // ── About text (was read-only Text, now TextField) ─────────────────
        _secTitle('About Us',Icons.info_outline),
        const SizedBox(height:12),
        _card(TextField(controller:_aboutC,maxLines:6,
            style:const TextStyle(fontSize:15,color:Color(0xFF666666),height:1.6),
            decoration:const InputDecoration(border:InputBorder.none,
                hintText:'Describe your clinic, your values, and what makes you special…',
                hintStyle:TextStyle(color:Color(0xFFAAAAAA))))),
        const SizedBox(height:24),

        // ── Technology (was fixed list of 4 cards, now selectable cards same style) ──
        _secTitle('Technology & Equipment',Icons.computer_outlined),
        const SizedBox(height:12),
        ..._kTech.map((tech){
          final on=_tech.contains(tech);
          return GestureDetector(
            onTap:()=>setState(()=>on?_tech.remove(tech):_tech.add(tech)),
            child:AnimatedContainer(duration:const Duration(milliseconds:150),
              margin:const EdgeInsets.only(bottom:10),
              padding:const EdgeInsets.all(14),
              decoration:BoxDecoration(
                  color:on?const Color(0xFFA8E6CF).withOpacity(0.08):Colors.white,
                  borderRadius:BorderRadius.circular(12),
                  border:Border.all(color:on?const Color(0xFF7DD3C0):Colors.transparent,width:1.5),
                  boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:8,offset:const Offset(0,2))]),
              child:Row(children:[
                Container(padding:const EdgeInsets.all(10),
                    decoration:BoxDecoration(color:const Color(0xFFA8E6CF).withOpacity(0.2),borderRadius:BorderRadius.circular(10)),
                    child:Icon(_techIcon(tech),color:const Color(0xFF7DD3C0),size:24)),
                const SizedBox(width:12),
                Expanded(child:Text(tech,style:const TextStyle(fontSize:15,fontWeight:FontWeight.w600,color:Color(0xFF333333)))),
                Icon(on?Icons.check_circle:Icons.check_circle_outline,color:on?const Color(0xFF7DD3C0):Colors.grey.shade300,size:22),
              ]),
            ),
          );
        }),
        const SizedBox(height:24),

        // ── Certifications (same 3-col grid, + "add" cell appended) ─────────
        Row(children:[
          Expanded(child:_secTitle('Certifications & Awards',Icons.workspace_premium_outlined)),
        ]),
        const SizedBox(height:12),
        GridView.builder(
          shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
          gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1),
          itemCount:_certs.length+1,
          itemBuilder:(ctx,i){
            if(i==_certs.length) return _addCertCell();
            return GestureDetector(onTap:()=>_certMenu(i),
              child:Stack(children:[
                Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),
                    boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:8,offset:const Offset(0,2))]),
                    child:ClipRRect(borderRadius:BorderRadius.circular(12),
                        child:Image.network(_certs[i],fit:BoxFit.cover,width:double.infinity,height:double.infinity,
                            errorBuilder:(_,__,___)=>const Icon(Icons.image,color:Colors.grey)))),
                Positioned(top:4,right:4,child:Container(padding:const EdgeInsets.all(3),
                    decoration:BoxDecoration(color:Colors.black54,borderRadius:BorderRadius.circular(5)),
                    child:const Icon(Icons.more_vert,size:12,color:Colors.white))),
              ]),
            );
          },
        ),
        const SizedBox(height:24),

        // ── Insurance & Payment (same card with two rows, now editable) ──────
        _secTitle('Insurance & Payment',Icons.account_balance_wallet),
        const SizedBox(height:12),
        _card(Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          const Text('Insurance Accepted',style:TextStyle(fontSize:13,color:Color(0xFF999999))),
          const SizedBox(height:10),
          _chips(_kIns,_ins),
          const Divider(height:24),
          const Text('Payment Methods',style:TextStyle(fontSize:13,color:Color(0xFF999999))),
          const SizedBox(height:10),
          _chips(_kPay,_pay),
        ])),
        const SizedBox(height:24),

        // ── Languages (same chip style as ClinicProfilePage._buildLanguageChip) ──
        _secTitle('Languages Spoken',Icons.language),
        const SizedBox(height:12),
        _card(_chips(_kLang,_lang)),
        const SizedBox(height:24),

        // ── Parking & Accessibility (same card style) ─────────────────────
        _secTitle('Parking & Accessibility',Icons.local_parking),
        const SizedBox(height:12),
        _card(_chips(_kPark,_park)),
        const SizedBox(height:20),
      ]),
    );
  }

  IconData _techIcon(String t){
    if(t.contains('X-Ray'))  return Icons.camera_alt;
    if(t.contains('3D')||t.contains('CBCT')) return Icons.view_in_ar;
    if(t.contains('Laser'))  return Icons.lightbulb;
    if(t.contains('CAD'))    return Icons.precision_manufacturing;
    if(t.contains('Camera')) return Icons.videocam;
    if(t.contains('Impres')) return Icons.fingerprint;
    if(t.contains('Abras'))  return Icons.air;
    if(t.contains('Piezo'))  return Icons.electric_bolt;
    if(t.contains('Ozone'))  return Icons.bubble_chart;
    return Icons.computer;
  }

  Widget _addCertCell()=>GestureDetector(
    onTap:_addCert,
    child:Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),
        border:Border.all(color:const Color(0xFF7DD3C0).withOpacity(0.4),width:1.5),
        boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:8,offset:const Offset(0,2))]),
        child:const Column(mainAxisAlignment:MainAxisAlignment.center,children:[
          Icon(Icons.add_photo_alternate,color:Color(0xFF7DD3C0),size:28),
          SizedBox(height:6),
          Text('Add',style:TextStyle(fontSize:12,color:Color(0xFF7DD3C0),fontWeight:FontWeight.w600)),
        ])),
  );

  Future<void> _addCert() async {
    final f=await _pick(); if(f==null||!mounted) return;
    setState(()=>_saving=true);
    try{
      final u=FirebaseAuth.instance.currentUser!;
      final url=await _upload(f,'clinics/${u.uid}/certificates/${DateTime.now().millisecondsSinceEpoch}.jpg');
      if(mounted) setState((){_certs.add(url);_saving=false;});
    }catch(e){
      if(mounted){setState(()=>_saving=false);ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Upload failed: $e'),backgroundColor:Colors.red));}
    }
  }

  void _certMenu(int i){
    showModalBottomSheet(context:context,shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(20))),
      builder:(_)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
        ListTile(leading:const Icon(Icons.visibility,color:Color(0xFF7DD3C0)),title:const Text('View'),
          onTap:(){Navigator.pop(context);showDialog(context:context,builder:(_)=>Dialog(child:InteractiveViewer(child:Image.network(_certs[i]))));},),
        ListTile(leading:const Icon(Icons.edit,color:Color(0xFF7DD3C0)),title:const Text('Replace'),
            onTap:() async{
              Navigator.pop(context);
              final f=await _pick(); if(f==null||!mounted) return;
              setState(()=>_saving=true);
              try{final u=FirebaseAuth.instance.currentUser!;final url=await _upload(f,'clinics/${u.uid}/certificates/${DateTime.now().millisecondsSinceEpoch}.jpg');if(mounted)setState((){_certs[i]=url;_saving=false;});}
              catch(e){if(mounted)setState(()=>_saving=false);}
            }),
        ListTile(leading:const Icon(Icons.delete,color:Colors.red),title:const Text('Remove',style:TextStyle(color:Colors.red)),
          onTap:(){Navigator.pop(context);setState(()=>_certs.removeAt(i));},),
      ])),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 2: Team  (same card layout as ClinicProfilePage._buildTeamTab)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _tabTeam(){
    return ListView.builder(
      padding:const EdgeInsets.all(20),
      itemCount:_team.length+1,
      itemBuilder:(ctx,i){
        if(i==_team.length) return _addMemberBtn();
        final m=_team[i];
        return Container(
          margin:const EdgeInsets.only(bottom:16),
          padding:const EdgeInsets.all(16),
          decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),
              boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:10,offset:const Offset(0,2))]),
          child:Row(children:[
            // Photo — same 80×80 rounded box as profile
            Container(width:80,height:80,
                decoration:BoxDecoration(color:const Color(0xFFA8E6CF).withOpacity(0.3),borderRadius:BorderRadius.circular(12),
                    image:m.photoUrl!=null?DecorationImage(image:NetworkImage(m.photoUrl!),fit:BoxFit.cover):null),
                child:m.photoUrl==null?const Icon(Icons.person,size:40,color:Color(0xFF7DD3C0)):null),
            const SizedBox(width:16),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Text(m.name,style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:Color(0xFF333333))),
              const SizedBox(height:4),
              Text(m.role,style:const TextStyle(fontSize:14,color:Color(0xFF7DD3C0),fontWeight:FontWeight.w600)),
              if(m.experience.isNotEmpty)...[const SizedBox(height:4),Text(m.experience,style:const TextStyle(fontSize:12,color:Color(0xFF999999)))],
              if(m.specs.isNotEmpty)...[const SizedBox(height:8),
                Wrap(spacing:6,runSpacing:6,children:m.specs.map((s)=>Container(
                    padding:const EdgeInsets.symmetric(horizontal:8,vertical:4),
                    decoration:BoxDecoration(color:const Color(0xFFA8E6CF).withOpacity(0.2),borderRadius:BorderRadius.circular(8)),
                    child:Text(s,style:const TextStyle(fontSize:11,color:Color(0xFF666666))))).toList())],
            ])),
            // ••• menu (only in edit mode)
            PopupMenuButton<String>(
              icon:const Icon(Icons.more_vert,color:Color(0xFF999999)),
              onSelected:(v){ if(v=='edit')_editMember(i); if(v=='remove')setState(()=>_team.removeAt(i)); },
              itemBuilder:(_)=>[
                const PopupMenuItem(value:'edit',child:Text('Edit')),
                const PopupMenuItem(value:'remove',child:Text('Remove',style:TextStyle(color:Colors.red))),
              ],
            ),
          ]),
        );
      },
    );
  }

  Widget _addMemberBtn()=>Padding(
    padding:const EdgeInsets.only(top:4),
    child:GestureDetector(onTap:()=>_editMember(null),
      child:Container(
        padding:const EdgeInsets.symmetric(vertical:14),
        decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),
            border:Border.all(color:const Color(0xFF7DD3C0).withOpacity(0.4),width:1.5),
            boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:10,offset:const Offset(0,2))]),
        child:const Row(mainAxisAlignment:MainAxisAlignment.center,children:[
          Icon(Icons.add,color:Color(0xFF7DD3C0),size:22),SizedBox(width:8),
          Text('Add Team Member',style:TextStyle(color:Color(0xFF7DD3C0),fontWeight:FontWeight.bold,fontSize:15)),
        ]),
      ),
    ),
  );

  void _editMember(int? idx){
    final e=idx!=null?_team[idx]:null;
    final nc=TextEditingController(text:e?.name??'');
    final rc=TextEditingController(text:e?.role??'');
    final ec=TextEditingController(text:e?.experience??'');
    final sc=TextEditingController(text:e?.specs.join(', ')??'');
    showDialog(context:context,builder:(_)=>AlertDialog(
      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16)),
      title:Text(idx==null?'Add Team Member':'Edit Team Member',style:const TextStyle(fontWeight:FontWeight.bold,fontSize:17)),
      content:SingleChildScrollView(child:Column(mainAxisSize:MainAxisSize.min,children:[
        TextField(controller:nc,decoration:_dec('Full name',icon:Icons.person)),
        const SizedBox(height:12),
        TextField(controller:rc,decoration:_dec('Role (e.g. Dentist)',icon:Icons.work_outline)),
        const SizedBox(height:12),
        TextField(controller:ec,decoration:_dec('Experience (e.g. 10 years)',icon:Icons.timer_outlined)),
        const SizedBox(height:12),
        TextField(controller:sc,decoration:_dec('Specializations, comma separated',icon:Icons.star_outline)),
      ])),
      actions:[
        TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel',style:TextStyle(color:Color(0xFF999999)))),
        ElevatedButton(
          onPressed:(){
            final n=nc.text.trim(); if(n.isEmpty) return;
            final specs=sc.text.trim().isEmpty?<String>[]:sc.text.split(',').map((s)=>s.trim()).where((s)=>s.isNotEmpty).toList();
            setState((){
              if(idx==null) _team.add(_Member(id:DateTime.now().millisecondsSinceEpoch.toString(),name:n,role:rc.text.trim(),experience:ec.text.trim(),specs:specs));
              else{_team[idx].name=n;_team[idx].role=rc.text.trim();_team[idx].experience=ec.text.trim();_team[idx].specs=specs;}
            });
            Navigator.pop(context);
          },
          style:ElevatedButton.styleFrom(backgroundColor:const Color(0xFF7DD3C0),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10))),
          child:const Text('Save',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold)),
        ),
      ],
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 3: Services  (same 2-col grid as ClinicProfilePage._buildServicesTab)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _tabServices(){
    return GridView.builder(
      padding:const EdgeInsets.all(20),
      gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:2,crossAxisSpacing:12,mainAxisSpacing:12,childAspectRatio:1.2),
      itemCount:_kSvc.length,
      itemBuilder:(ctx,i){
        final s=_kSvc[i]; final on=_svc.contains(s);
        return GestureDetector(
          onTap:()=>setState(()=>on?_svc.remove(s):_svc.add(s)),
          child:AnimatedContainer(duration:const Duration(milliseconds:150),
            padding:const EdgeInsets.all(16),
            decoration:BoxDecoration(
                color:on?const Color(0xFFA8E6CF).withOpacity(0.1):Colors.white,
                borderRadius:BorderRadius.circular(16),
                border:Border.all(color:on?const Color(0xFF7DD3C0):Colors.transparent,width:2),
                boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:10,offset:const Offset(0,2))]),
            child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
              Container(padding:const EdgeInsets.all(12),
                  decoration:BoxDecoration(color:const Color(0xFFA8E6CF).withOpacity(0.2),borderRadius:BorderRadius.circular(12)),
                  child:Icon(_svcIcon(s),color:const Color(0xFF7DD3C0),size:32)),
              const SizedBox(height:12),
              Text(s,style:TextStyle(fontSize:14,fontWeight:FontWeight.bold,color:on?const Color(0xFF7DD3C0):const Color(0xFF333333)),
                  textAlign:TextAlign.center,maxLines:2,overflow:TextOverflow.ellipsis),
              if(on)...[const SizedBox(height:4),const Icon(Icons.check_circle,size:14,color:Color(0xFF7DD3C0))],
            ]),
          ),
        );
      },
    );
  }

  IconData _svcIcon(String s){
    if(s.contains('Clean'))  return Icons.cleaning_services;
    if(s.contains('Whiten')) return Icons.auto_awesome;
    if(s.contains('Impl'))   return Icons.construction;
    if(s.contains('Root'))   return Icons.healing;
    if(s.contains('Veneer')) return Icons.diamond;
    if(s.contains('Ortho')||s.contains('Invis')) return Icons.straighten;
    if(s.contains('Pediat')) return Icons.child_care;
    if(s.contains('Emerg'))  return Icons.emergency;
    if(s.contains('Sedat'))  return Icons.bedtime;
    return Icons.medical_services;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 4: Gallery  (same category → 3-col-grid structure as profile)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _tabGallery(){
    return ListView.builder(
      padding:const EdgeInsets.all(20),
      itemCount:_gal.length+(_gal.length<5?1:0),
      itemBuilder:(ctx,i){
        if(i==_gal.length) return GestureDetector(
          onTap:()=>setState(()=>_gal.add(_GalCat(id:DateTime.now().millisecondsSinceEpoch.toString(),name:'Category ${_gal.length+1}',urls:[]))),
          child:Container(
            padding:const EdgeInsets.symmetric(vertical:14),
            decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(16),
                border:Border.all(color:const Color(0xFF7DD3C0).withOpacity(0.4),width:1.5),
                boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:10,offset:const Offset(0,2))]),
            child:const Row(mainAxisAlignment:MainAxisAlignment.center,children:[
              Icon(Icons.add,color:Color(0xFF7DD3C0),size:22),SizedBox(width:8),
              Text('Add Category  (max 5)',style:TextStyle(color:Color(0xFF7DD3C0),fontWeight:FontWeight.bold,fontSize:15)),
            ]),
          ),
        );
        return _galCatSection(i,_gal[i]);
      },
    );
  }

  Widget _galCatSection(int ci,_GalCat cat){
    return Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
      // Category header — same layout as ClinicProfilePage gallery header
      Padding(padding:const EdgeInsets.only(bottom:12),
        child:Row(children:[
          Expanded(
            child:TextField(
              controller:TextEditingController(text:cat.name)..selection=TextSelection.collapsed(offset:cat.name.length),
              onChanged:(v)=>cat.name=v,
              style:const TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:Color(0xFF333333)),
              decoration:InputDecoration(border:InputBorder.none,hintText:'Category name',
                  suffixIcon:const Icon(Icons.edit,size:14,color:Color(0xFF7DD3C0))),
            ),
          ),
          Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
              decoration:BoxDecoration(color:const Color(0xFFA8E6CF).withOpacity(0.2),borderRadius:BorderRadius.circular(12)),
              child:Text('${cat.urls.length} photos',style:const TextStyle(fontSize:12,fontWeight:FontWeight.w600,color:Color(0xFF7DD3C0)))),
          const SizedBox(width:8),
          GestureDetector(onTap:()=>setState(()=>_gal.removeAt(ci)),
              child:Container(padding:const EdgeInsets.all(6),
                  decoration:BoxDecoration(color:Colors.red.withOpacity(0.1),borderRadius:BorderRadius.circular(8)),
                  child:const Icon(Icons.delete_outline,color:Colors.red,size:18))),
        ]),
      ),
      // Photo grid — identical to ClinicProfilePage photo grid + add cell
      GridView.builder(
        shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
        gridDelegate:const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount:3,crossAxisSpacing:8,mainAxisSpacing:8,childAspectRatio:1),
        itemCount:cat.urls.length+(cat.urls.length<5?1:0),
        itemBuilder:(ctx,pi){
          if(pi==cat.urls.length) return GestureDetector(
            onTap:()=>_addGalPhoto(ci),
            child:Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),
                border:Border.all(color:const Color(0xFF7DD3C0).withOpacity(0.4)),
                boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:8,offset:const Offset(0,2))]),
                child:const Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                  Icon(Icons.add_photo_alternate,color:Color(0xFF7DD3C0),size:26),
                  SizedBox(height:4),
                  Text('Add',style:TextStyle(fontSize:11,color:Color(0xFF7DD3C0))),
                ])),
          );
          // Same card style as ClinicProfilePage photo cell + ✕ to remove
          return GestureDetector(
            onTap:()=>showModalBottomSheet(context:context,shape:const RoundedRectangleBorder(borderRadius:BorderRadius.vertical(top:Radius.circular(20))),
                builder:(_)=>SafeArea(child:Column(mainAxisSize:MainAxisSize.min,children:[
                  ListTile(leading:const Icon(Icons.delete,color:Colors.red),title:const Text('Remove photo',style:TextStyle(color:Colors.red)),
                    onTap:(){Navigator.pop(context);setState(()=>_gal[ci].urls.removeAt(pi));},),
                ]))),
            child:Stack(children:[
              Container(decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),
                  boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.1),blurRadius:8,offset:const Offset(0,2))]),
                  child:ClipRRect(borderRadius:BorderRadius.circular(12),
                      child:Image.network(cat.urls[pi],fit:BoxFit.cover,width:double.infinity,height:double.infinity,
                          errorBuilder:(_,__,___)=>Container(color:Colors.grey.shade200,child:const Icon(Icons.broken_image,color:Colors.grey))))),
              Positioned(top:4,right:4,child:Container(padding:const EdgeInsets.all(4),
                  decoration:BoxDecoration(color:Colors.black54,borderRadius:BorderRadius.circular(6)),
                  child:const Icon(Icons.close,size:12,color:Colors.white))),
            ]),
          );
        },
      ),
      const SizedBox(height:24),
    ]);
  }

  Future<void> _addGalPhoto(int ci) async {
    final f=await _pick(); if(f==null||!mounted) return;
    setState(()=>_saving=true);
    try{
      final u=FirebaseAuth.instance.currentUser!;
      final url=await _upload(f,'clinics/${u.uid}/gallery/${DateTime.now().millisecondsSinceEpoch}.jpg');
      if(mounted) setState((){_gal[ci].urls.add(url);_saving=false;});
    }catch(e){if(mounted) setState(()=>_saving=false);}
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB 5: Contact  (same layout as ClinicProfilePage._buildContactTab)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _tabContact(){
    return SingleChildScrollView(
      padding:const EdgeInsets.all(20),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[

        // Opening Hours — same card, each row now has editable time pills + open toggle
        _secTitle('Opening Hours',Icons.access_time),
        const SizedBox(height:12),
        _card(Column(children:_kDays.map((d)=>_dayRow(d,d!=_kDays.last)).toList())),
        const SizedBox(height:24),

        // Contact Info — same _buildContactRow card style, but value is a TextField
        _secTitle('Contact Info',Icons.contact_mail),
        const SizedBox(height:12),
        _editContactRow(Icons.location_on,'Address',_addrC),
        const SizedBox(height:12),
        _editContactRow(Icons.phone,'Phone',_phoneC,type:TextInputType.phone),
        const SizedBox(height:12),
        _editContactRow(Icons.email,'Email',_emailC,type:TextInputType.emailAddress),
        const SizedBox(height:20),
      ]),
    );
  }

  // Matches _buildContactRow but value is editable TextField
  Widget _editContactRow(IconData icon,String label,TextEditingController ctrl,{TextInputType? type}){
    return Container(
      padding:const EdgeInsets.all(14),
      decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(12),
          boxShadow:[BoxShadow(color:Colors.black.withOpacity(0.05),blurRadius:8,offset:const Offset(0,2))]),
      child:Row(children:[
        Container(padding:const EdgeInsets.all(8),
            decoration:BoxDecoration(color:const Color(0xFFA8E6CF).withOpacity(0.3),borderRadius:BorderRadius.circular(8)),
            child:Icon(icon,color:const Color(0xFF7DD3C0),size:20)),
        const SizedBox(width:12),
        Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
          Text(label,style:const TextStyle(fontSize:12,color:Color(0xFF999999))),
          const SizedBox(height:2),
          TextField(controller:ctrl,keyboardType:type,
              style:const TextStyle(fontSize:14,fontWeight:FontWeight.w600,color:Color(0xFF333333)),
              decoration:const InputDecoration(border:InputBorder.none,isDense:true,contentPadding:EdgeInsets.zero,
                  hintStyle:TextStyle(color:Color(0xFFCCCCCC)))),
        ])),
        const Icon(Icons.edit,size:14,color:Color(0xFF7DD3C0)),
      ]),
    );
  }

  // Matches _buildHoursRow but hours are editable
  Widget _dayRow(String day,bool showDivider){
    final h=_hrs[day]!;
    final today=_isToday(day);
    return Padding(padding:const EdgeInsets.only(bottom:8),
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[
          SizedBox(width:90,child:Text(day,style:TextStyle(fontSize:14,
              fontWeight:today?FontWeight.bold:FontWeight.normal,
              color:today?const Color(0xFF7DD3C0):const Color(0xFF666666)))),
          const Spacer(),
          Transform.scale(scale:0.8,child:Switch(value:h.open,onChanged:(v)=>setState(()=>h.open=v),activeColor:const Color(0xFF7DD3C0))),
          SizedBox(width:52,child:Text(h.open?'Open':'Closed',style:TextStyle(fontSize:12,color:h.open?const Color(0xFF7DD3C0):const Color(0xFFAAAAAA)))),
        ]),
        if(h.open)...[
          const SizedBox(height:4),
          Row(children:[
            const SizedBox(width:90),
            _pill(h.s1,()async{final t=await _pickT(h.s1);if(t!=null)setState(()=>h.s1=t);}),
            const Padding(padding:EdgeInsets.symmetric(horizontal:6),child:Text('–',style:TextStyle(fontWeight:FontWeight.bold,color:Color(0xFF666666)))),
            _pill(h.e1,()async{final t=await _pickT(h.e1);if(t!=null)setState(()=>h.e1=t);}),
            const Spacer(),
            GestureDetector(onTap:()=>setState(()=>h.brk=!h.brk),
                child:Row(mainAxisSize:MainAxisSize.min,children:[
                  Icon(h.brk?Icons.check_box:Icons.check_box_outline_blank,size:16,color:const Color(0xFF7DD3C0)),
                  const SizedBox(width:4),
                  const Text('Break',style:TextStyle(fontSize:11,color:Color(0xFF777777))),
                ])),
          ]),
          if(h.brk)...[
            const SizedBox(height:4),
            Row(children:[
              const SizedBox(width:90),
              _pill(h.s2,()async{final t=await _pickT(h.s2);if(t!=null)setState(()=>h.s2=t);}),
              const Padding(padding:EdgeInsets.symmetric(horizontal:6),child:Text('–',style:TextStyle(fontWeight:FontWeight.bold,color:Color(0xFF666666)))),
              _pill(h.e2,()async{final t=await _pickT(h.e2);if(t!=null)setState(()=>h.e2=t);}),
            ]),
          ],
        ],
        if(showDivider) const Divider(height:16),
      ]),
    );
  }

  Widget _pill(TimeOfDay t,VoidCallback onTap)=>GestureDetector(onTap:onTap,
      child:Container(
          padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
          decoration:BoxDecoration(color:const Color(0xFFA8E6CF).withOpacity(0.2),borderRadius:BorderRadius.circular(8),
              border:Border.all(color:const Color(0xFF7DD3C0).withOpacity(0.3))),
          child:Text('${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}',
              style:const TextStyle(fontSize:13,fontWeight:FontWeight.bold,color:Color(0xFF7DD3C0)))));

  bool _isToday(String day){
    const days=['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    return days.indexOf(day)==DateTime.now().weekday-1;
  }

  Future<TimeOfDay?> _pickT(TimeOfDay init)=>showTimePicker(
      context:context,initialTime:init,
      builder:(ctx,child)=>MediaQuery(data:MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat:true),child:child!));
}