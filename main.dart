import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const CGPAApp());

class CGPAApp extends StatelessWidget {
  const CGPAApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
    home: const RootShell(),
  );
}

// ─── Palette ──────────────────────────────────────────────────────────────────
const kIndigo     = Color(0xFF6366F1);
const kCyan       = Color(0xFF22D3EE);
const kCoral      = Color(0xFFF97316);
const kGold       = Color(0xFFF59E0B);
const kCherry     = Color(0xFFEC4899);
const kMint       = Color(0xFF10B981);
const kViolet     = Color(0xFF8B5CF6);
const kGlass      = Color(0xCC0E0B22);
const kBorder     = Color(0x556366F1);
const kBorderCyan = Color(0x4422D3EE);
const kWhite      = Color(0xFFF1F5F9);
const kDim        = Color(0xFF94A3B8);

const List<Color> kSemCols = [kIndigo, kCyan, kCoral, kMint, kViolet, kGold, kCherry];

// ─── XP Levels ────────────────────────────────────────────────────────────────
const List<Map<String, Object>> kLevels = [
  {'min': 0,    'name': '🎓 Scholar',        'color': kDim},
  {'min': 100,  'name': '📖 Achiever',        'color': kCyan},
  {'min': 300,  'name': '⭐ Honor Student',   'color': kMint},
  {'min': 700,  'name': '🔥 Dean\'s Scholar', 'color': kGold},
  {'min': 1400, 'name': '💎 Summa Cum Laude', 'color': kCherry},
  {'min': 2500, 'name': '🏆 Valedictorian',   'color': kIndigo},
];

Map<String, Object> levelInfo(int xp) {
  Map<String, Object> cur = kLevels[0];
  for (final l in kLevels) { if (xp >= (l['min'] as int)) cur = l; }
  final idx     = kLevels.indexOf(cur);
  final nextMin = idx < kLevels.length - 1 ? (kLevels[idx + 1]['min'] as int) : 9999;
  final prevMin = cur['min'] as int;
  final double frac = nextMin == 9999 ? 1.0 : (xp - prevMin) / (nextMin - prevMin);
  return {'name': cur['name'] as String, 'color': cur['color'] as Color,
    'frac': frac.clamp(0.0, 1.0), 'nextMin': nextMin};
}

// ─── Achievements ─────────────────────────────────────────────────────────────
const Map<String, Map<String, String>> kAchievements = {
  'first_a':    {'icon':'🌟','title':'First A!',        'desc':'Score 80%+ for the first time'},
  'on_fire':    {'icon':'🔥','title':'On Fire!',         'desc':'3+ A\'s in one semester'},
  'dean_list':  {'icon':'🏅','title':'Dean\'s List',     'desc':'Achieve CGPA ≥ 3.5'},
  'distinction':{'icon':'💎','title':'Distinction',      'desc':'Achieve CGPA ≥ 3.7'},
  'bookworm':   {'icon':'📚','title':'Bookworm',         'desc':'Complete 50+ credit hours'},
  'century':    {'icon':'🎯','title':'Century Club',     'desc':'Complete 100+ credit hours'},
  'perfectsem': {'icon':'⭐','title':'Perfect Semester', 'desc':'Get 4.0 GPA in a semester'},
  'streak3':    {'icon':'⚡','title':'On A Roll!',       'desc':'3 semesters ≥ 3.0 GPA'},
  'perfectsub': {'icon':'💯','title':'100 Club',         'desc':'Score 100% in any subject'},
};

// ─── Models ───────────────────────────────────────────────────────────────────
class Subject {
  String name;
  double creditHours;
  bool   isExpanded;
  double quizObt;   double quizTotal;   double quizW;
  double assignObt; double assignTotal; double assignW;
  double midObt;    double midTotal;    double midW;
  double finalObt;  double finalTotal;  double finalW;

  Subject({
    this.name='', this.creditHours=0, this.isExpanded=false,
    this.quizObt=0,   this.quizTotal=10,  this.quizW=10,
    this.assignObt=0, this.assignTotal=10, this.assignW=10,
    this.midObt=0,    this.midTotal=30,   this.midW=30,
    this.finalObt=0,  this.finalTotal=50,  this.finalW=50,
  });

  double get percentage {
    double t = 0;
    if (quizTotal   > 0) t += (quizObt   / quizTotal)   * quizW;
    if (assignTotal > 0) t += (assignObt / assignTotal) * assignW;
    if (midTotal    > 0) t += (midObt    / midTotal)    * midW;
    if (finalTotal  > 0) t += (finalObt  / finalTotal)  * finalW;
    return t.clamp(0.0, 100.0);
  }
  bool get hasAnyMark => quizObt>0 || assignObt>0 || midObt>0 || finalObt>0;

  double get gradePoints {
    final p = percentage;
    if (p>=90) return 4.0; if (p>=85) return 3.7; if (p>=80) return 3.3;
    if (p>=75) return 3.0; if (p>=70) return 2.7; if (p>=65) return 2.3;
    if (p>=60) return 2.0; if (p>=55) return 1.7; if (p>=50) return 1.3;
    return 0.0;
  }
  String get letterGrade {
    final p = percentage;
    if (p>=85) return 'A';  if (p>=80) return 'A-';
    if (p>=75) return 'B+'; if (p>=70) return 'B';
    if (p>=65) return 'B-'; if (p>=60) return 'C+';
    if (p>=55) return 'C';  if (p>=50) return 'C-';
    return 'F';
  }
  Color get gradeColor {
    final p = percentage;
    if (p>=80) return kMint; if (p>=65) return kCyan;
    if (p>=50) return kGold; return kCherry;
  }
  String get gradeEmoji {
    final p = percentage;
    if (p>=90) return '💯'; if (p>=80) return '🌟';
    if (p>=70) return '👍'; if (p>=55) return '📖';
    if (p>=50) return '⚠️'; return '❌';
  }
  Map<String,dynamic> toJson() => {
    'name':name,'creditHours':creditHours,
    'quizObt':quizObt,'quizTotal':quizTotal,'quizW':quizW,
    'assignObt':assignObt,'assignTotal':assignTotal,'assignW':assignW,
    'midObt':midObt,'midTotal':midTotal,'midW':midW,
    'finalObt':finalObt,'finalTotal':finalTotal,'finalW':finalW,
  };
  factory Subject.fromJson(Map<String,dynamic> j) => Subject(
    name:j['name']??'', creditHours:(j['creditHours']??0).toDouble(),
    quizObt:(j['quizObt']??0).toDouble(),     quizTotal:(j['quizTotal']??10).toDouble(),   quizW:(j['quizW']??10).toDouble(),
    assignObt:(j['assignObt']??0).toDouble(), assignTotal:(j['assignTotal']??10).toDouble(),assignW:(j['assignW']??10).toDouble(),
    midObt:(j['midObt']??0).toDouble(),       midTotal:(j['midTotal']??30).toDouble(),      midW:(j['midW']??30).toDouble(),
    finalObt:(j['finalObt']??0).toDouble(),   finalTotal:(j['finalTotal']??50).toDouble(),  finalW:(j['finalW']??50).toDouble(),
  );
}

class Semester {
  String name; List<Subject> subjects; bool isExpanded;
  Semester({required this.name, List<Subject>? subjects, this.isExpanded=true})
      : subjects = subjects ?? [Subject()];

  double get gpa {
    double tp=0,tc=0;
    for (var s in subjects) { if(s.creditHours>0){tp+=s.gradePoints*s.creditHours;tc+=s.creditHours;} }
    return tc>0?tp/tc:0.0;
  }
  double get totalCredits => subjects.fold(0,(sum,s)=>sum+(s.creditHours>0?s.creditHours:0));
  int get aCount => subjects.where((s)=>s.percentage>=80).length;

  Map<String,dynamic> toJson() => {'name':name,'subjects':subjects.map((s)=>s.toJson()).toList()};
  factory Semester.fromJson(Map<String,dynamic> j) => Semester(
      name:j['name']??'Semester',
      subjects:(j['subjects'] as List<dynamic>?)?.map((s)=>Subject.fromJson(s)).toList()??[Subject()]);
}

// ─── Confetti ─────────────────────────────────────────────────────────────────
class _Confetti {
  double x,y,vx,vy,rot,rotV,size; Color color; int shape;
  static const cols=[kIndigo,kCyan,kGold,kCherry,kMint,kCoral,kViolet,Color(0xFFFF6B6B)];
  _Confetti(Random r,double w):x=r.nextDouble()*w,y=-30-r.nextDouble()*120,
        vx=(r.nextDouble()-0.5)*5,vy=2+r.nextDouble()*6,
        rot=r.nextDouble()*pi*2,rotV=(r.nextDouble()-0.5)*0.3,
        size=7+r.nextDouble()*8,shape=r.nextInt(3),color=cols[r.nextInt(cols.length)];
  void tick(){x+=vx;y+=vy;rot+=rotV;vy+=0.08;vx*=0.994;}
}
class _ConfettiPainter extends CustomPainter {
  final List<_Confetti> ps; _ConfettiPainter(this.ps);
  @override void paint(Canvas c, Size s) {
    for (final p in ps) {
      if(p.y>s.height) continue;
      c.save(); c.translate(p.x,p.y); c.rotate(p.rot);
      final paint=Paint()..color=p.color.withOpacity(0.9);
      if(p.shape==1){ c.drawCircle(Offset.zero,p.size/2,paint);
      } else if(p.shape==0){
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center:Offset.zero,width:p.size,height:p.size*0.45),const Radius.circular(2)),paint);
      } else {
        final path=Path();
        for(int i=0;i<10;i++){final a=pi/5*i-pi/2;final r=i.isEven?p.size/2:p.size/4.5;i==0?path.moveTo(cos(a)*r,sin(a)*r):path.lineTo(cos(a)*r,sin(a)*r);}
        path.close(); c.drawPath(path,paint);
      }
      c.restore();
    }
  }
  @override bool shouldRepaint(_ConfettiPainter o)=>true;
}

// ─── Arc Gauge ────────────────────────────────────────────────────────────────
class _GaugePainter extends CustomPainter {
  final double value, progress;
  _GaugePainter(this.value, this.progress);
  @override void paint(Canvas c, Size s) {
    final cx=s.width/2,cy=s.height*0.82,r=s.width*0.40;
    const sa=pi*0.78,sw=pi*1.44;
    c.drawArc(Rect.fromCircle(center:Offset(cx,cy),radius:r+4),sa,sw,false,
        Paint()..color=kIndigo.withOpacity(0.15)..style=PaintingStyle.stroke..strokeWidth=20..strokeCap=StrokeCap.round);
    c.drawArc(Rect.fromCircle(center:Offset(cx,cy),radius:r),sa,sw,false,
        Paint()..color=Colors.white.withOpacity(0.06)..style=PaintingStyle.stroke..strokeWidth=12..strokeCap=StrokeCap.round);
    for(int i=0;i<4;i++){
      c.drawArc(Rect.fromCircle(center:Offset(cx,cy),radius:r),sa+(sw/4)*i+0.04,(sw/4)-0.08,false,
          Paint()..color=[kCherry,kGold,kCyan,kMint][i].withOpacity(0.18)..style=PaintingStyle.stroke..strokeWidth=12..strokeCap=StrokeCap.butt);}
    final vs=sw*(value/4.0).clamp(0.0,1.0)*progress;
    if(vs>0.01){
      final rect=Rect.fromCircle(center:Offset(cx,cy),radius:r);
      c.drawArc(rect,sa,vs,false,Paint()
        ..shader=SweepGradient(startAngle:sa,endAngle:sa+sw,colors:const[kCherry,kGold,kCyan,kMint],stops:const[0,0.33,0.66,1.0]).createShader(rect)
        ..style=PaintingStyle.stroke..strokeWidth=12..strokeCap=StrokeCap.round);
      final na=sa+sw*(value/4.0).clamp(0.0,1.0)*progress;
      final nx=cx+r*cos(na),ny=cy+r*sin(na);
      c.drawCircle(Offset(nx,ny),14,Paint()..color=kCyan.withOpacity(0.25)..maskFilter=const MaskFilter.blur(BlurStyle.normal,8));
      c.drawCircle(Offset(nx,ny),8,Paint()..color=kWhite);
      c.drawCircle(Offset(nx,ny),8,Paint()..color=kCyan.withOpacity(0.6)..style=PaintingStyle.stroke..strokeWidth=2);
    }
    for(int i=0;i<=4;i++){
      final a=sa+sw*(i/4.0);
      c.drawLine(Offset(cx+(r-16)*cos(a),cy+(r-16)*sin(a)),Offset(cx+(r+4)*cos(a),cy+(r+4)*sin(a)),
          Paint()..color=Colors.white.withOpacity(0.25)..strokeWidth=1.5);}
    final tp=TextPainter(textDirection:TextDirection.ltr);
    for(int i=0;i<=4;i++){
      final a=sa+sw*(i/4.0);
      tp.text=TextSpan(text:'$i',style:TextStyle(color:Colors.white.withOpacity(0.35),fontSize:9,fontWeight:FontWeight.bold));
      tp.layout(); tp.paint(c,Offset(cx+(r+16)*cos(a)-tp.width/2,cy+(r+16)*sin(a)-tp.height/2));}
  }
  @override bool shouldRepaint(_GaugePainter o)=>o.value!=value||o.progress!=progress;
}

// ─── Shared helpers ───────────────────────────────────────────────────────────
Color cgpaColor(double v){if(v>=3.5)return kMint;if(v>=2.7)return kCyan;if(v>=2.0)return kGold;return kCherry;}
String cgpaLabel(double v){
  if(v>=3.7)return '💎 DISTINCTION';if(v>=3.3)return '🌟 HIGH MERIT';
  if(v>=3.0)return '✨ MERIT';if(v>=2.0)return '👍 SATISFACTORY';
  if(v>0)return '📖 NEEDS IMPROVEMENT';return '🎯 ENTER GRADES';
}

// ─── App State (InheritedWidget) ──────────────────────────────────────────────
class AppState extends InheritedWidget {
  final List<Semester> sems;
  final int xp;
  final Set<String> achieved;
  final VoidCallback onSave;
  final void Function(int) addXP;
  final void Function(Semester) calculate;
  final VoidCallback addSemester;
  final void Function(int) deleteSemester;
  final void Function(int) rename;
  final void Function(String,Color) snack;
  final void Function() burst;
  final void Function(String?) setAchieveToast;

  const AppState({
    super.key, required super.child,
    required this.sems, required this.xp, required this.achieved,
    required this.onSave, required this.addXP, required this.calculate,
    required this.addSemester, required this.deleteSemester,
    required this.rename, required this.snack, required this.burst,
    required this.setAchieveToast,
  });

  double get cgpa {
    double tp=0,tc=0;
    for(var s in sems){if(s.totalCredits>0){tp+=s.gpa*s.totalCredits;tc+=s.totalCredits;}}
    return tc>0?tp/tc:0.0;
  }

  static AppState of(BuildContext ctx) => ctx.dependOnInheritedWidgetOfExactType<AppState>()!;
  @override bool updateShouldNotify(AppState o) => true;
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ROOT SHELL
// ═══════════════════════════════════════════════════════════════════════════════
class RootShell extends StatefulWidget {
  const RootShell({super.key});
  @override State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> with TickerProviderStateMixin {
  List<Semester> _sems    = [Semester(name:'Semester 1')];
  int            _xp      = 0;
  Set<String>    _achieved = {};
  int            _page    = 0;

  late AnimationController _confCtrl, _pulseCtrl, _bannerCtrl, _levelCtrl;
  late Animation<double>   _bannerAnim, _levelAnim;
  final List<_Confetti> _particles = [];
  final _rng = Random();
  String? _achieveToast;
  String? _levelUpName;

  static const _navCfg = [
    {'icon': Icons.dashboard_rounded,    'label': 'Dashboard',    'color': kCyan},
    {'icon': Icons.school_rounded,       'label': 'Semesters',    'color': kIndigo},
    {'icon': Icons.bar_chart_rounded,    'label': 'Analytics',    'color': kMint},
    {'icon': Icons.emoji_events_rounded, 'label': 'Achievements', 'color': kGold},
  ];

  @override
  void initState() {
    super.initState();
    _confCtrl   = AnimationController(vsync:this,duration:const Duration(milliseconds:3000))..addListener(_tickConf);
    _pulseCtrl  = AnimationController(vsync:this,duration:const Duration(seconds:3))..repeat(reverse:true);
    _bannerCtrl = AnimationController(vsync:this,duration:const Duration(milliseconds:600));
    _bannerAnim = CurvedAnimation(parent:_bannerCtrl,curve:Curves.elasticOut);
    _levelCtrl  = AnimationController(vsync:this,duration:const Duration(milliseconds:400));
    _levelAnim  = CurvedAnimation(parent:_levelCtrl,curve:Curves.easeOutBack);
    _loadData();
  }

  @override
  void dispose(){
    _confCtrl.dispose();_pulseCtrl.dispose();_bannerCtrl.dispose();_levelCtrl.dispose();
    super.dispose();
  }

  void _tickConf(){
    if(_confCtrl.isAnimating){
      setState((){for(final p in _particles)p.tick();_particles.removeWhere((p)=>p.y>1300);});
    }
  }

  void _burst(){
    final w=MediaQuery.of(context).size.width;
    _particles.clear();
    for(int i=0;i<90;i++) _particles.add(_Confetti(_rng,w));
    _confCtrl.forward(from:0);
    HapticFeedback.heavyImpact();
  }

  // ── Data ─────────────────────────────────────────────────────────────────
  Future<void> _loadData() async {
    final p=await SharedPreferences.getInstance();
    final raw=p.getString('sems_v2');
    if(raw!=null) setState(()=>_sems=(jsonDecode(raw) as List).map((e)=>Semester.fromJson(e)).toList());
    _xp=p.getInt('xp_v2')??0;
    final achRaw=p.getString('ach_v2');
    if(achRaw!=null) _achieved=Set<String>.from(jsonDecode(achRaw) as List);
    setState((){});
    if(_cgpa>=3.5) _bannerCtrl.forward();
  }

  Future<void> _save() async {
    final p=await SharedPreferences.getInstance();
    await p.setString('sems_v2',jsonEncode(_sems.map((s)=>s.toJson()).toList()));
    await p.setInt('xp_v2',_xp);
    await p.setString('ach_v2',jsonEncode(_achieved.toList()));
  }

  void _resetAll() async {
    final p=await SharedPreferences.getInstance();
    await p.remove('sems_v2');await p.remove('xp_v2');await p.remove('ach_v2');
    setState((){_sems=[Semester(name:'Semester 1')];_xp=0;_achieved={};});
    _bannerCtrl.reverse();
  }

  double get _cgpa {
    double tp=0,tc=0;
    for(var s in _sems){if(s.totalCredits>0){tp+=s.gpa*s.totalCredits;tc+=s.totalCredits;}}
    return tc>0?tp/tc:0.0;
  }

  void _addXP(int amount){
    final old=levelInfo(_xp)['name'] as String;
    setState(()=>_xp+=amount);
    final nw=levelInfo(_xp)['name'] as String;
    if(old!=nw){
      setState(()=>_levelUpName=nw);
      _levelCtrl.forward(from:0);
      Future.delayed(const Duration(seconds:3),(){if(mounted) setState(()=>_levelUpName=null);});
    }
  }

  void _checkAchievements(){
    final tc=_sems.fold(0.0,(s,sem)=>s+sem.totalCredits);
    final gpa=_cgpa;
    final allA=_sems.fold(0,(s,sem)=>s+sem.aCount);
    void chk(String key,bool cond){
      if(cond&&!_achieved.contains(key)){
        setState((){_achieved.add(key);_achieveToast=key;});
        _addXP(150);HapticFeedback.mediumImpact();
        Future.delayed(const Duration(seconds:4),(){if(mounted) setState(()=>_achieveToast=null);});
      }
    }
    chk('first_a',allA>=1);
    chk('on_fire',_sems.any((s)=>s.aCount>=3));
    chk('dean_list',gpa>=3.5);
    chk('distinction',gpa>=3.7);
    chk('bookworm',tc>=50);
    chk('century',tc>=100);
    chk('perfectsem',_sems.any((s)=>s.gpa>=3.999));
    chk('streak3',_sems.length>=3&&_sems.sublist(_sems.length-3).every((s)=>s.gpa>=3.0));
    chk('perfectsub',_sems.any((s)=>s.subjects.any((sub)=>sub.percentage>=100)));
  }

  void _calculate(Semester sem){
    _addXP(20);
    _save(); _checkAchievements();
    if(_cgpa>=3.5){_bannerCtrl.forward();_burst();}
    else if(sem.gpa>=3.5){_burst();}
    else HapticFeedback.selectionClick();
    final e=sem.gpa>=3.5?'🎉':sem.gpa>=2.5?'👏':'💪';
    _snack('$e  ${sem.name}  ·  GPA: ${sem.gpa.toStringAsFixed(2)}',kIndigo);
  }

  void _addSemester(){setState(()=>_sems.add(Semester(name:'Semester ${_sems.length+1}')));_addXP(30);_save();}

  void _deleteSemester(int i){
    if(_sems.length==1){_snack('Need at least one semester',kCherry);return;}
    setState(()=>_sems.removeAt(i));_save();
  }

  void _snack(String msg,Color color){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:Text(msg,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w600)),
        backgroundColor:color.withOpacity(0.9),behavior:SnackBarBehavior.floating,
        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14))));
  }

  void _rename(int idx){
    final ctrl=TextEditingController(text:_sems[idx].name);
    showDialog(context:context,builder:(_)=>BackdropFilter(
        filter:ImageFilter.blur(sigmaX:10,sigmaY:10),
        child:AlertDialog(
            backgroundColor:const Color(0xFF1A1640),
            shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22),side:const BorderSide(color:kBorder,width:1.5)),
            title:const Text('Rename Semester',style:TextStyle(color:kWhite,fontWeight:FontWeight.bold)),
            content:TextField(controller:ctrl,autofocus:true,cursorColor:kCyan,style:const TextStyle(color:kWhite),
                decoration:InputDecoration(hintText:'e.g. Fall 2024',hintStyle:const TextStyle(color:kDim),
                    filled:true,fillColor:const Color(0x33FFFFFF),
                    enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:const BorderSide(color:kBorder)),
                    focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(12),borderSide:const BorderSide(color:kCyan,width:2)))),
            actions:[
              TextButton(onPressed:()=>Navigator.pop(context),child:const Text('Cancel',style:TextStyle(color:kDim))),
              ElevatedButton(
                  style:ElevatedButton.styleFrom(backgroundColor:kIndigo,foregroundColor:Colors.white,
                      shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10))),
                  onPressed:(){
                    setState(()=>_sems[idx].name=ctrl.text.trim().isEmpty?_sems[idx].name:ctrl.text.trim());
                    Navigator.pop(context);_save();},
                  child:const Text('Save'))])));
  }

  @override
  Widget build(BuildContext context) {
    return AppState(
      sems:_sems, xp:_xp, achieved:_achieved,
      onSave:_save, addXP:_addXP, calculate:_calculate,
      addSemester:_addSemester, deleteSemester:_deleteSemester,
      rename:_rename, snack:_snack, burst:_burst,
      setAchieveToast:(k)=>setState(()=>_achieveToast=k),
      child: Scaffold(
        backgroundColor:Colors.transparent,
        extendBody:true,
        body:Stack(children:[
          Positioned.fill(child:Image.asset('assets/images/my_images.png',fit:BoxFit.cover)),
          // Pages
          IndexedStack(index:_page,children:[
            DashboardPage(pulseCtrl:_pulseCtrl,resetAll:_resetAll),
            SemestersPage(),
            AnalyticsPage(),
            AchievementsPage(showTarget:_showTargetSheet),
          ]),
          // Confetti
          if(_particles.isNotEmpty)
            Positioned.fill(child:IgnorePointer(child:AnimatedBuilder(
                animation:_confCtrl,
                builder:(_,__)=>CustomPaint(painter:_ConfettiPainter(List.from(_particles)))))),
          // Achievement toast
          if(_achieveToast!=null) _achieveToastWidget(_achieveToast!),
          // Level up toast
          if(_levelUpName!=null) _levelToastWidget(_levelUpName!),
          // Honor banner
          if(_cgpa>=3.5) _honorBanner(),
          // Bottom nav
          Positioned(bottom:0,left:0,right:0,child:_bottomNav()),
        ]),
      ),
    );
  }

  Widget _bottomNav() => ClipRRect(
      borderRadius:const BorderRadius.vertical(top:Radius.circular(28)),
      child:BackdropFilter(filter:ImageFilter.blur(sigmaX:24,sigmaY:24),
          child:Container(
              padding:const EdgeInsets.symmetric(horizontal:8,vertical:10),
              decoration:BoxDecoration(
                  color:const Color(0xDD0B0920),
                  borderRadius:const BorderRadius.vertical(top:Radius.circular(28)),
                  border:const Border(top:BorderSide(color:kBorder,width:1.2)),
                  boxShadow:[BoxShadow(color:kIndigo.withOpacity(0.22),blurRadius:28,spreadRadius:-4)]),
              child:Row(mainAxisAlignment:MainAxisAlignment.spaceAround,
                  children:List.generate(4,(i){
                    final sel=_page==i;
                    final col=_navCfg[i]['color'] as Color;
                    final ic=_navCfg[i]['icon'] as IconData;
                    final lb=_navCfg[i]['label'] as String;
                    return GestureDetector(
                        onTap:(){setState(()=>_page=i);HapticFeedback.selectionClick();},
                        child:AnimatedContainer(
                            duration:const Duration(milliseconds:280),curve:Curves.easeOutCubic,
                            padding:EdgeInsets.symmetric(horizontal:sel?18:12,vertical:8),
                            decoration:BoxDecoration(
                                color:sel?col.withOpacity(0.14):Colors.transparent,
                                borderRadius:BorderRadius.circular(18),
                                border:sel?Border.all(color:col.withOpacity(0.38)):null,
                                boxShadow:sel?[BoxShadow(color:col.withOpacity(0.25),blurRadius:14)]:[]),
                            child:Row(mainAxisSize:MainAxisSize.min,children:[
                              Icon(ic,color:sel?col:kDim,size:sel?22:20),
                              if(sel)...[const SizedBox(width:6),
                                Text(lb,style:TextStyle(color:col,fontSize:12,fontWeight:FontWeight.w700,letterSpacing:0.3))]])));
                  })))));

  Widget _honorBanner()=>Positioned(top:56,left:16,right:16,
      child:SlideTransition(
          position:Tween<Offset>(begin:const Offset(0,-1.5),end:Offset.zero).animate(_bannerAnim),
          child:Container(
              padding:const EdgeInsets.symmetric(horizontal:16,vertical:10),
              decoration:BoxDecoration(
                  gradient:const LinearGradient(colors:[Color(0xFF065F46),Color(0xFF047857)],begin:Alignment.topLeft,end:Alignment.bottomRight),
                  borderRadius:BorderRadius.circular(16),
                  border:Border.all(color:kMint.withOpacity(0.5)),
                  boxShadow:[BoxShadow(color:kMint.withOpacity(0.35),blurRadius:20,offset:const Offset(0,4))]),
              child:Row(children:[
                const Text('🏅',style:TextStyle(fontSize:20)),const SizedBox(width:10),
                const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text('HONOR ROLL',style:TextStyle(color:kMint,fontSize:11,letterSpacing:2,fontWeight:FontWeight.w900)),
                  Text('You\'ve made the Dean\'s List!',style:TextStyle(color:Colors.white70,fontSize:12))])),
                IconButton(icon:const Icon(Icons.close,color:Colors.white54,size:16),onPressed:()=>_bannerCtrl.reverse())]))));

  Widget _achieveToastWidget(String key){
    final d=kAchievements[key]!;
    return Positioned(bottom:100,left:20,right:20,
        child:Container(
            padding:const EdgeInsets.all(14),
            decoration:BoxDecoration(
                gradient:LinearGradient(colors:[kGold.withOpacity(0.18),kGold.withOpacity(0.06)]),
                borderRadius:BorderRadius.circular(18),
                border:Border.all(color:kGold.withOpacity(0.5),width:1.5),
                boxShadow:[BoxShadow(color:kGold.withOpacity(0.28),blurRadius:24)]),
            child:Row(children:[
              Text(d['icon']!,style:const TextStyle(fontSize:28)),const SizedBox(width:12),
              Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                const Text('Achievement Unlocked!',style:TextStyle(color:kGold,fontSize:10,letterSpacing:1.5,fontWeight:FontWeight.w800)),
                Text(d['title']!,style:const TextStyle(color:kWhite,fontSize:14,fontWeight:FontWeight.bold)),
                Text(d['desc']!, style:const TextStyle(color:kDim,fontSize:11))])])));
  }

  Widget _levelToastWidget(String name)=>Positioned(top:60,left:20,right:20,
      child:ScaleTransition(scale:_levelAnim,
          child:Container(
              padding:const EdgeInsets.symmetric(horizontal:18,vertical:12),
              decoration:BoxDecoration(
                  gradient:LinearGradient(colors:[kViolet.withOpacity(0.22),kIndigo.withOpacity(0.12)]),
                  borderRadius:BorderRadius.circular(18),
                  border:Border.all(color:kViolet.withOpacity(0.55),width:1.5),
                  boxShadow:[BoxShadow(color:kViolet.withOpacity(0.32),blurRadius:24)]),
              child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
                const Text('⚡ ',style:TextStyle(fontSize:22)),
                Column(mainAxisSize:MainAxisSize.min,children:[
                  const Text('LEVEL UP!',style:TextStyle(color:kViolet,fontSize:11,letterSpacing:2,fontWeight:FontWeight.w900)),
                  Text(name,style:const TextStyle(color:kWhite,fontSize:14,fontWeight:FontWeight.bold))])]))));

  void _showTargetSheet(){
    showModalBottomSheet(context:context,isScrollControlled:true,backgroundColor:Colors.transparent,
        builder:(_){
          double target=3.5;
          return StatefulBuilder(builder:(ctx,setS){
            final cur=_cgpa;
            final curCr=_sems.fold(0.0,(s,sem)=>s+sem.totalCredits);
            const futCr=15.0;
            final needed=curCr+futCr>0?((target*(curCr+futCr))-(cur*curCr))/futCr:0.0;
            final feasible=needed<=4.0&&needed>=0;
            return BackdropFilter(filter:ImageFilter.blur(sigmaX:16,sigmaY:16),
                child:Container(
                    decoration:const BoxDecoration(color:Color(0xFF12102A),borderRadius:BorderRadius.vertical(top:Radius.circular(30))),
                    padding:EdgeInsets.fromLTRB(24,16,24,MediaQuery.of(ctx).viewInsets.bottom+40),
                    child:Column(mainAxisSize:MainAxisSize.min,children:[
                      Container(width:40,height:4,decoration:BoxDecoration(color:kBorder,borderRadius:BorderRadius.circular(2))),
                      const SizedBox(height:20),
                      Row(children:[
                        Container(padding:const EdgeInsets.all(9),
                            decoration:BoxDecoration(color:kIndigo.withOpacity(0.15),borderRadius:BorderRadius.circular(12)),
                            child:const Icon(Icons.track_changes_rounded,color:kIndigo,size:22)),
                        const SizedBox(width:12),
                        const Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                          Text('Target CGPA Calculator',style:TextStyle(fontSize:16,fontWeight:FontWeight.bold,color:kWhite)),
                          Text('How hard do you need to grind?',style:TextStyle(fontSize:12,color:kDim))])]),
                      const SizedBox(height:20),
                      Container(padding:const EdgeInsets.symmetric(horizontal:16,vertical:14),
                          decoration:BoxDecoration(color:cgpaColor(cur).withOpacity(0.10),borderRadius:BorderRadius.circular(14),border:Border.all(color:cgpaColor(cur).withOpacity(0.30))),
                          child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
                            const Text('Current CGPA',style:TextStyle(color:kDim,fontSize:13)),
                            Text(cur.toStringAsFixed(2),style:TextStyle(color:cgpaColor(cur),fontSize:22,fontWeight:FontWeight.w900))])),
                      const SizedBox(height:18),
                      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
                        const Text('Target',style:TextStyle(color:kDim,fontSize:13,fontWeight:FontWeight.w600)),
                        Container(padding:const EdgeInsets.symmetric(horizontal:14,vertical:5),
                            decoration:BoxDecoration(color:kIndigo.withOpacity(0.15),borderRadius:BorderRadius.circular(10),border:Border.all(color:kBorder)),
                            child:Text(target.toStringAsFixed(1),style:const TextStyle(color:kCyan,fontSize:16,fontWeight:FontWeight.bold)))]),
                      SliderTheme(data:SliderThemeData(activeTrackColor:kCyan,thumbColor:kIndigo,inactiveTrackColor:kBorder,overlayColor:kIndigo.withOpacity(0.15),trackHeight:4),
                          child:Slider(value:target,min:1.0,max:4.0,divisions:30,onChanged:(v)=>setS(()=>target=v))),
                      Padding(padding:const EdgeInsets.only(bottom:14),
                          child:Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,
                              children:['1.0','2.0','3.0','4.0'].map((l)=>Text(l,style:const TextStyle(color:kDim,fontSize:10))).toList())),
                      AnimatedContainer(duration:const Duration(milliseconds:300),padding:const EdgeInsets.all(18),
                          decoration:BoxDecoration(
                              color:feasible?kMint.withOpacity(0.08):kCherry.withOpacity(0.08),
                              borderRadius:BorderRadius.circular(18),
                              border:Border.all(color:feasible?kMint.withOpacity(0.35):kCherry.withOpacity(0.35))),
                          child:Column(children:[
                            Text(feasible?'You need a  ${needed.toStringAsFixed(2)}  GPA\nnext semester (15 credits)':'Not achievable in one semester.',
                                textAlign:TextAlign.center,
                                style:TextStyle(color:feasible?kMint:kCherry,fontWeight:FontWeight.w800,fontSize:15,height:1.5)),
                            if(feasible)...[const SizedBox(height:10),
                              Text(needed<=2?'🟢 Very achievable!':needed<=3?'🟡 Challenging!':needed<=3.7?'🟠 Very tough!':'🔴 Near-perfect needed!',
                                  style:const TextStyle(color:kDim,fontSize:13))]])),
                      const SizedBox(height:8),
                      const Text('* Based on 15 credit hours next semester',style:TextStyle(color:kDim,fontSize:11)),
                    ])));
          });
        });
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PAGE 1 — DASHBOARD
// ═══════════════════════════════════════════════════════════════════════════════
class DashboardPage extends StatefulWidget {
  final AnimationController pulseCtrl;
  final VoidCallback resetAll;
  const DashboardPage({super.key, required this.pulseCtrl, required this.resetAll});
  @override State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with SingleTickerProviderStateMixin {
  late AnimationController _gaugeCtrl;
  late Animation<double>   _gaugeAnim;
  late Animation<double>   _pulseAnim;
  int _quoteIdx = 0;

  static const _quotes = [
    '✨ The universe rewards those who dare to be great.',
    '🚀 Every grade is a stepping stone to the stars.',
    '💡 Curiosity is the compass that guides scholars.',
    '🌌 Your potential is as infinite as the cosmos.',
    '🔥 Burn bright — knowledge is your superpower.',
    '⚡ One more subject. One step closer to legends.',
    '🏆 Excellence isn\'t luck — it\'s daily discipline.',
    '🌟 The best view comes after the hardest climb.',
    '💎 Pressure makes diamonds. Study is your pressure.',
    '🎯 Aim for distinction. Settle for nothing less.',
  ];

  @override
  void initState(){
    super.initState();
    _gaugeCtrl=AnimationController(vsync:this,duration:const Duration(milliseconds:1600));
    _gaugeAnim=CurvedAnimation(parent:_gaugeCtrl,curve:Curves.easeOutCubic);
    _pulseAnim=Tween<double>(begin:0.97,end:1.03).animate(CurvedAnimation(parent:widget.pulseCtrl,curve:Curves.easeInOut));
    _gaugeCtrl.forward();
  }

  @override void dispose(){ _gaugeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context){
    final state=AppState.of(context);
    final gpa=state.cgpa; final col=cgpaColor(gpa);
    final li=levelInfo(state.xp);
    final lvlName=li['name'] as String; final lvlColor=li['color'] as Color; final lvlFrac=li['frac'] as double;
    final totalCr=state.sems.fold(0.0,(s,sem)=>s+sem.totalCredits);
    final totalSubs=state.sems.fold(0,(s,sem)=>s+sem.subjects.length);
    int streak=0;
    for(int i=state.sems.length-1;i>=0;i--){if(state.sems[i].gpa>=3.0)streak++;else break;}

    return Scaffold(backgroundColor:Colors.transparent,extendBodyBehindAppBar:true,
        appBar:_appBar(context,state),
        body:SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(16,8,16,100),children:[
          // ── CGPA Card ──────────────────────────────────────────────────────
          _glassCard(child:Row(children:[
            // Gauge
            SizedBox(width:140,height:96,child:Stack(alignment:Alignment.center,children:[
              AnimatedBuilder(animation:_gaugeAnim,builder:(_,__)=>CustomPaint(
                  painter:_GaugePainter(gpa,_gaugeAnim.value),size:const Size(140,96))),
              Positioned(bottom:0,child:Column(mainAxisSize:MainAxisSize.min,children:[
                ScaleTransition(scale:_pulseAnim,child:ShaderMask(
                    shaderCallback:(b)=>LinearGradient(colors:[col,kCyan]).createShader(b),
                    child:Text(gpa.toStringAsFixed(2),style:const TextStyle(fontSize:28,fontWeight:FontWeight.w900,color:Colors.white,height:1)))),
                const Text('/ 4.00',style:TextStyle(fontSize:10,color:kDim))]))
            ])),
            const SizedBox(width:12),
            Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
                  decoration:BoxDecoration(color:col.withOpacity(0.12),borderRadius:BorderRadius.circular(20),border:Border.all(color:col.withOpacity(0.35))),
                  child:Text(cgpaLabel(gpa),style:TextStyle(color:col,fontSize:9,letterSpacing:0.8,fontWeight:FontWeight.w800))),
              const SizedBox(height:10),
              // Stat chips
              Wrap(spacing:6,runSpacing:6,children:[
                _chip(Icons.school_rounded,'${state.sems.length}','Sems',kIndigo),
                _chip(Icons.menu_book_rounded,'$totalSubs','Subs',kCoral),
                _chip(Icons.stars_rounded,'${totalCr.toStringAsFixed(0)}','Cr',kGold),
              ]),
              const SizedBox(height:8),
              if(streak>0) Row(children:[
                const Text('🔥 ',style:TextStyle(fontSize:12)),
                Text('$streak-semester streak',style:const TextStyle(color:kGold,fontSize:11,fontWeight:FontWeight.bold))]),
              const SizedBox(height:8),
              // XP Bar
              Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
                Text(lvlName,style:TextStyle(color:lvlColor,fontSize:10,fontWeight:FontWeight.bold)),
                Text('${state.xp} XP',style:const TextStyle(color:kDim,fontSize:9))]),
              const SizedBox(height:4),
              ClipRRect(borderRadius:BorderRadius.circular(6),child:Stack(children:[
                Container(height:7,color:Colors.white.withOpacity(0.08)),
                FractionallySizedBox(widthFactor:lvlFrac,child:Container(height:7,
                    decoration:BoxDecoration(
                        gradient:LinearGradient(colors:[lvlColor.withOpacity(0.6),lvlColor]),
                        borderRadius:BorderRadius.circular(6),
                        boxShadow:[BoxShadow(color:lvlColor.withOpacity(0.5),blurRadius:6)]))),
              ])),
            ])),
          ])),
          const SizedBox(height:12),

          // ── Quote Card ─────────────────────────────────────────────────────
          GestureDetector(
              onTap:()=>setState(()=>_quoteIdx=(_quoteIdx+1)%_quotes.length),
              child:Container(
                  padding:const EdgeInsets.symmetric(horizontal:14,vertical:12),
                  decoration:BoxDecoration(color:kIndigo.withOpacity(0.10),borderRadius:BorderRadius.circular(14),border:Border.all(color:kBorder)),
                  child:Row(children:[
                    const Icon(Icons.auto_awesome,color:kIndigo,size:14),const SizedBox(width:8),
                    Expanded(child:AnimatedSwitcher(duration:const Duration(milliseconds:450),
                        transitionBuilder:(child,anim)=>FadeTransition(opacity:anim,
                            child:SlideTransition(position:Tween<Offset>(begin:const Offset(0,0.3),end:Offset.zero).animate(anim),child:child)),
                        child:Text(_quotes[_quoteIdx],key:ValueKey(_quoteIdx),
                            style:const TextStyle(color:kDim,fontSize:11,fontStyle:FontStyle.italic,height:1.4)))),
                    const SizedBox(width:4),
                    const Icon(Icons.touch_app,color:kDim,size:12)]))),
          const SizedBox(height:16),

          // ── Quick Stats Grid ───────────────────────────────────────────────
          const Padding(padding:EdgeInsets.only(bottom:10),
              child:Text('Quick Overview',style:TextStyle(color:kWhite,fontSize:15,fontWeight:FontWeight.bold))),
          GridView.count(crossAxisCount:2,crossAxisSpacing:10,mainAxisSpacing:10,shrinkWrap:true,
              physics:const NeverScrollableScrollPhysics(),childAspectRatio:1.8,
              children:[
                _statCard('📊','Current CGPA',gpa.toStringAsFixed(2),col),
                _statCard('📚','Total Credits',totalCr.toStringAsFixed(0),kCyan),
                _statCard('✅','Subjects',totalSubs.toString(),kMint),
                _statCard('🏅','Achievements','${state.achieved.length}/9',kGold),
              ]),
          const SizedBox(height:16),

          // ── Per-Semester GPA mini bars ─────────────────────────────────────
          if(state.sems.isNotEmpty) _glassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[
              Container(padding:const EdgeInsets.all(7),
                  decoration:BoxDecoration(color:kCyan.withOpacity(0.12),borderRadius:BorderRadius.circular(10)),
                  child:const Icon(Icons.bar_chart_rounded,size:16,color:kCyan)),
              const SizedBox(width:8),
              const Text('Semester GPAs',style:TextStyle(color:kWhite,fontSize:14,fontWeight:FontWeight.bold))]),
            const SizedBox(height:14),
            ...state.sems.asMap().entries.map((e){
              final g=e.value.gpa; final c=cgpaColor(g);
              return Padding(padding:const EdgeInsets.only(bottom:8),child:Row(children:[
                SizedBox(width:60,child:Text(e.value.name.length>6?'S${e.key+1}':e.value.name,
                    style:const TextStyle(color:kDim,fontSize:11,fontWeight:FontWeight.w600))),
                Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(8),child:Stack(children:[
                  Container(height:18,color:Colors.white.withOpacity(0.05)),
                  FractionallySizedBox(widthFactor:(g/4.0).clamp(0,1),child:Container(height:18,
                      decoration:BoxDecoration(gradient:LinearGradient(colors:[c.withOpacity(0.7),c]),
                          borderRadius:BorderRadius.circular(8),boxShadow:[BoxShadow(color:c.withOpacity(0.3),blurRadius:6)])))]))),
                const SizedBox(width:8),
                SizedBox(width:36,child:Text(g.toStringAsFixed(2),style:TextStyle(color:c,fontSize:11,fontWeight:FontWeight.bold)))]));
            }),
          ])),
        ])));
  }

  PreferredSizeWidget _appBar(BuildContext ctx, AppState state) => PreferredSize(
      preferredSize:const Size.fromHeight(62),
      child:ClipRRect(child:BackdropFilter(filter:ImageFilter.blur(sigmaX:20,sigmaY:20),
          child:AppBar(
            backgroundColor:Colors.black.withOpacity(0.50),elevation:0,centerTitle:true,
            title:ShaderMask(shaderCallback:(b)=>const LinearGradient(colors:[kCyan,kIndigo,kCherry]).createShader(b),
                child:const Text('DASHBOARD',style:TextStyle(color:Colors.white,fontSize:17,letterSpacing:2.8,fontWeight:FontWeight.w900))),
            bottom:PreferredSize(preferredSize:const Size.fromHeight(1),
                child:Container(height:1.5,decoration:const BoxDecoration(gradient:LinearGradient(colors:[kCyan,kIndigo,kCherry])))),
            actions:[IconButton(icon:const Icon(Icons.refresh_rounded,color:kDim),
                onPressed:()=>showDialog(context:ctx,builder:(_)=>BackdropFilter(
                    filter:ImageFilter.blur(sigmaX:10,sigmaY:10),
                    child:AlertDialog(backgroundColor:const Color(0xFF1A1640),
                        shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(22),side:const BorderSide(color:kCherry)),
                        title:const Text('Reset Everything?',style:TextStyle(color:kWhite,fontWeight:FontWeight.bold)),
                        content:const Text('All data, XP and achievements will be wiped.',style:TextStyle(color:kDim)),
                        actions:[
                          TextButton(onPressed:()=>Navigator.pop(ctx),child:const Text('Cancel',style:TextStyle(color:kDim))),
                          ElevatedButton(
                              style:ElevatedButton.styleFrom(backgroundColor:kCherry,foregroundColor:Colors.white,
                                  shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(10))),
                              onPressed:(){widget.resetAll();Navigator.pop(ctx);},
                              child:const Text('Reset'))]))))],))));

  Widget _chip(IconData icon,String val,String label,Color color)=>Container(
      padding:const EdgeInsets.symmetric(horizontal:7,vertical:4),
      decoration:BoxDecoration(color:color.withOpacity(0.10),borderRadius:BorderRadius.circular(8),border:Border.all(color:color.withOpacity(0.25))),
      child:Row(mainAxisSize:MainAxisSize.min,children:[
        Icon(icon,size:10,color:color),const SizedBox(width:3),
        Text(val,style:TextStyle(color:color,fontSize:11,fontWeight:FontWeight.bold)),
        Text(' $label',style:const TextStyle(color:kDim,fontSize:9))]));

  Widget _statCard(String emoji,String label,String value,Color color)=>_glassCard(
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,mainAxisAlignment:MainAxisAlignment.center,children:[
        Row(children:[Text(emoji,style:const TextStyle(fontSize:18)),const SizedBox(width:6),
          Text(label,style:const TextStyle(color:kDim,fontSize:11))]),
        const SizedBox(height:4),
        Text(value,style:TextStyle(color:color,fontSize:22,fontWeight:FontWeight.w900))]));
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PAGE 2 — SEMESTERS
// ═══════════════════════════════════════════════════════════════════════════════
class SemestersPage extends StatefulWidget {
  const SemestersPage({super.key});
  @override State<SemestersPage> createState() => _SemestersPageState();
}

class _SemestersPageState extends State<SemestersPage> {
  @override
  Widget build(BuildContext context) {
    final state=AppState.of(context);
    return Scaffold(backgroundColor:Colors.transparent,extendBodyBehindAppBar:true,
        appBar:_appBar(),
        floatingActionButton:Container(
            decoration:BoxDecoration(
                gradient:const LinearGradient(colors:[kIndigo,kViolet],begin:Alignment.topLeft,end:Alignment.bottomRight),
                borderRadius:BorderRadius.circular(18),
                boxShadow:[BoxShadow(color:kIndigo.withOpacity(0.5),blurRadius:18,offset:const Offset(0,5))]),
            child:FloatingActionButton.extended(
                heroTag:'add_sem',
                onPressed:(){state.addSemester();setState((){});},
                backgroundColor:Colors.transparent,elevation:0,
                icon:const Icon(Icons.add_rounded,color:Colors.white),
                label:const Text('Add Semester',style:TextStyle(color:Colors.white,fontWeight:FontWeight.bold)))),
        body:SafeArea(child:state.sems.isEmpty
            ?const Center(child:Text('No semesters yet.\nTap + to add one.',textAlign:TextAlign.center,style:TextStyle(color:kDim,fontSize:16)))
            :ListView.builder(
            padding:const EdgeInsets.fromLTRB(16,8,16,120),
            itemCount:state.sems.length,
            itemBuilder:(_,i)=>_SemCard(idx:i,onRefresh:()=>setState((){})))));
  }

  PreferredSizeWidget _appBar()=>PreferredSize(preferredSize:const Size.fromHeight(62),
      child:ClipRRect(child:BackdropFilter(filter:ImageFilter.blur(sigmaX:20,sigmaY:20),
          child:AppBar(backgroundColor:Colors.black.withOpacity(0.50),elevation:0,centerTitle:true,
              title:ShaderMask(shaderCallback:(b)=>const LinearGradient(colors:[kIndigo,kViolet,kCyan]).createShader(b),
                  child:const Text('SEMESTERS',style:TextStyle(color:Colors.white,fontSize:17,letterSpacing:2.8,fontWeight:FontWeight.w900))),
              bottom:PreferredSize(preferredSize:const Size.fromHeight(1),
                  child:Container(height:1.5,decoration:const BoxDecoration(gradient:LinearGradient(colors:[kIndigo,kViolet,kCyan]))))))));
}

class _SemCard extends StatefulWidget {
  final int idx; final VoidCallback onRefresh;
  const _SemCard({required this.idx, required this.onRefresh});
  @override State<_SemCard> createState() => _SemCardState();
}

class _SemCardState extends State<_SemCard> {
  @override
  Widget build(BuildContext context){
    final state=AppState.of(context);
    final sem=state.sems[widget.idx];
    final gpa=sem.gpa; final gpaCol=cgpaColor(gpa);
    final semCol=kSemCols[widget.idx%kSemCols.length];
    final bestIdx=sem.subjects.isEmpty?-1:
    sem.subjects.asMap().entries.reduce((a,b)=>a.value.percentage>=b.value.percentage?a:b).key;

    return Container(margin:const EdgeInsets.only(top:14),
        child:ClipRRect(borderRadius:BorderRadius.circular(22),child:BackdropFilter(
            filter:ImageFilter.blur(sigmaX:18,sigmaY:18),
            child:Container(
                decoration:BoxDecoration(color:kGlass,borderRadius:BorderRadius.circular(22),
                    border:Border.all(color:semCol.withOpacity(0.30),width:1.2),
                    boxShadow:[BoxShadow(color:semCol.withOpacity(0.18),blurRadius:20,spreadRadius:1)]),
                child:Column(children:[
                  // Header
                  InkWell(
                    onTap:()=>setState(()=>sem.isExpanded=!sem.isExpanded),
                    borderRadius:const BorderRadius.vertical(top:Radius.circular(22)),
                    child:Container(
                        padding:const EdgeInsets.symmetric(horizontal:16,vertical:12),
                        decoration:BoxDecoration(
                            gradient:LinearGradient(colors:[semCol.withOpacity(0.14),Colors.transparent]),
                            borderRadius:sem.isExpanded?const BorderRadius.vertical(top:Radius.circular(22)):BorderRadius.circular(22),
                            border:Border(bottom:BorderSide(color:sem.isExpanded?semCol.withOpacity(0.22):Colors.transparent))),
                        child:Row(children:[
                          AnimatedRotation(turns:sem.isExpanded?0:-0.25,duration:const Duration(milliseconds:250),
                              child:Icon(Icons.keyboard_arrow_down_rounded,color:semCol,size:22)),
                          const SizedBox(width:8),
                          Container(padding:const EdgeInsets.symmetric(horizontal:9,vertical:4),
                              decoration:BoxDecoration(gradient:LinearGradient(colors:[semCol,semCol.withOpacity(0.65)]),
                                  borderRadius:BorderRadius.circular(8),boxShadow:[BoxShadow(color:semCol.withOpacity(0.4),blurRadius:8)]),
                              child:Text('S${widget.idx+1}',style:const TextStyle(color:Colors.white,fontSize:11,fontWeight:FontWeight.bold))),
                          const SizedBox(width:10),
                          Expanded(child:Text(sem.name,style:const TextStyle(color:kWhite,fontSize:15,fontWeight:FontWeight.w700))),
                          Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:5),
                              decoration:BoxDecoration(color:gpaCol.withOpacity(0.12),borderRadius:BorderRadius.circular(20),
                                  border:Border.all(color:gpaCol.withOpacity(0.40)),boxShadow:[BoxShadow(color:gpaCol.withOpacity(0.20),blurRadius:8)]),
                              child:Text(gpa.toStringAsFixed(2),style:TextStyle(fontSize:14,fontWeight:FontWeight.bold,color:gpaCol))),
                          const SizedBox(width:2),
                          PopupMenuButton<String>(color:const Color(0xFF1A1640),
                              shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(16),side:BorderSide(color:semCol.withOpacity(0.35))),
                              icon:const Icon(Icons.more_vert_rounded,color:kDim,size:20),
                              onSelected:(v){
                                if(v=='rename') state.rename(widget.idx);
                                if(v=='delete'){state.deleteSemester(widget.idx);widget.onRefresh();}
                                if(v=='add') setState(()=>sem.subjects.add(Subject()));
                              },
                              itemBuilder:(_)=>[
                                _mi('add',Icons.add_circle_outline,'Add Subject',kCyan),
                                _mi('rename',Icons.edit_outlined,'Rename',kGold),
                                _mi('delete',Icons.delete_outline,'Delete',kCherry)]),
                        ])),
                  ),
                  if(sem.isExpanded)...[
                    if(sem.subjects.any((s)=>s.percentage>0))
                      Padding(padding:const EdgeInsets.fromLTRB(16,10,16,0),child:Row(children:[
                        const Text('Grades: ',style:TextStyle(color:kDim,fontSize:11,fontWeight:FontWeight.w600)),
                        _gBadge('A',sem.subjects.where((s)=>s.percentage>=80).length,kMint),const SizedBox(width:4),
                        _gBadge('B',sem.subjects.where((s)=>s.percentage>=65&&s.percentage<80).length,kCyan),const SizedBox(width:4),
                        _gBadge('C',sem.subjects.where((s)=>s.percentage>=50&&s.percentage<65).length,kGold),const SizedBox(width:4),
                        _gBadge('F',sem.subjects.where((s)=>s.percentage>0&&s.percentage<50).length,kCherry)])),
                    ...List.generate(sem.subjects.length,(si)=>_SubjectRow(
                        semIdx:widget.idx,subIdx:si,semCol:semCol,isBest:si==bestIdx&&sem.subjects[si].percentage>0,
                        onRefresh:()=>setState((){}))),
                    Padding(padding:const EdgeInsets.fromLTRB(14,10,14,14),child:Row(children:[
                      Expanded(child:_btn2(icon:Icons.add_rounded,label:'Add Subject',color:kCyan,filled:false,
                          onTap:()=>setState(()=>sem.subjects.add(Subject())))),
                      const SizedBox(width:10),
                      Expanded(child:_btn2(icon:Icons.calculate_rounded,label:'Calculate',color:semCol,filled:true,
                          onTap:(){state.calculate(sem);widget.onRefresh();}))]))],
                ])))));
  }

  Widget _gBadge(String g,int n,Color c)=>Container(
      padding:const EdgeInsets.symmetric(horizontal:8,vertical:3),
      decoration:BoxDecoration(color:c.withOpacity(0.12),borderRadius:BorderRadius.circular(8),border:Border.all(color:c.withOpacity(0.30))),
      child:Text('$g:$n',style:TextStyle(color:c,fontSize:10,fontWeight:FontWeight.bold)));

  PopupMenuItem<String> _mi(String v,IconData icon,String label,Color color)=>
      PopupMenuItem(value:v,child:Row(children:[Icon(icon,size:18,color:color),const SizedBox(width:10),
        Text(label,style:TextStyle(color:color,fontWeight:FontWeight.w600,fontSize:14))]));

  Widget _btn2({required IconData icon,required String label,required Color color,required bool filled,required VoidCallback onTap})=>
      GestureDetector(onTap:onTap,child:Container(
          padding:const EdgeInsets.symmetric(vertical:11),
          decoration:BoxDecoration(
              gradient:filled?LinearGradient(colors:[color,color.withOpacity(0.7)]):null,
              color:filled?null:Colors.white.withOpacity(0.05),
              borderRadius:BorderRadius.circular(13),
              border:Border.all(color:filled?Colors.transparent:color.withOpacity(0.35)),
              boxShadow:filled?[BoxShadow(color:color.withOpacity(0.35),blurRadius:12,offset:const Offset(0,3))]:[]
          ),
          child:Row(mainAxisAlignment:MainAxisAlignment.center,children:[
            Icon(icon,size:16,color:Colors.white),const SizedBox(width:6),
            Text(label,style:const TextStyle(color:Colors.white,fontWeight:FontWeight.w700,fontSize:13))])));
}

// ── Subject Row ───────────────────────────────────────────────────────────────
class _SubjectRow extends StatefulWidget {
  final int semIdx,subIdx; final Color semCol; final bool isBest; final VoidCallback onRefresh;
  const _SubjectRow({required this.semIdx,required this.subIdx,required this.semCol,required this.isBest,required this.onRefresh});
  @override State<_SubjectRow> createState()=>_SubjectRowState();
}

class _SubjectRowState extends State<_SubjectRow> {
  @override
  Widget build(BuildContext context){
    final state=AppState.of(context);
    final sub=state.sems[widget.semIdx].subjects[widget.subIdx];
    final pct=sub.percentage; final barFrac=(pct/100.0).clamp(0.0,1.0);

    return Dismissible(
      key:Key('sub_${widget.semIdx}_${widget.subIdx}'),
      direction:DismissDirection.endToStart,
      confirmDismiss:(_) async {
        if(state.sems[widget.semIdx].subjects.length==1){state.snack('Need at least one subject',kCherry);return false;}
        return true;
      },
      onDismissed:(_){setState(()=>state.sems[widget.semIdx].subjects.removeAt(widget.subIdx));state.onSave();widget.onRefresh();},
      background:Container(margin:const EdgeInsets.fromLTRB(12,8,12,0),alignment:Alignment.centerRight,
          padding:const EdgeInsets.only(right:16),
          decoration:BoxDecoration(color:kCherry.withOpacity(0.18),borderRadius:BorderRadius.circular(14),border:Border.all(color:kCherry.withOpacity(0.35))),
          child:const Icon(Icons.delete_rounded,color:kCherry,size:22)),
      child:AnimatedContainer(duration:const Duration(milliseconds:300),
          margin:const EdgeInsets.fromLTRB(12,8,12,0),
          decoration:BoxDecoration(
              color:widget.isBest?kGold.withOpacity(0.07):Colors.white.withOpacity(0.04),
              borderRadius:BorderRadius.circular(16),
              border:Border.all(color:widget.isBest?kGold.withOpacity(0.40):widget.semCol.withOpacity(0.18),width:widget.isBest?1.5:1.0),
              boxShadow:widget.isBest?[BoxShadow(color:kGold.withOpacity(0.20),blurRadius:12)]:[]
          ),
          child:Column(children:[
            // Top row
            Padding(padding:EdgeInsets.fromLTRB(10,9,6,sub.hasAnyMark?3:9),
                child:Row(children:[
                  Stack(clipBehavior:Clip.none,children:[
                    Container(width:26,height:26,alignment:Alignment.center,
                        decoration:BoxDecoration(shape:BoxShape.circle,
                            gradient:LinearGradient(colors:[widget.semCol,widget.semCol.withOpacity(0.55)]),
                            boxShadow:[BoxShadow(color:widget.semCol.withOpacity(0.4),blurRadius:8)]),
                        child:Text('${widget.subIdx+1}',style:const TextStyle(fontSize:11,fontWeight:FontWeight.bold,color:Colors.white))),
                    if(widget.isBest) Positioned(top:-4,right:-4,
                        child:Container(width:14,height:14,alignment:Alignment.center,
                            decoration:const BoxDecoration(shape:BoxShape.circle,color:kGold),
                            child:const Text('★',style:TextStyle(fontSize:8,color:Colors.black))))]),
                  const SizedBox(width:8),
                  Expanded(flex:3,child:_tf(hint:'Subject name',value:sub.name,col:widget.semCol,
                      onChanged:(v){sub.name=v;state.onSave();})),
                  const SizedBox(width:5),
                  SizedBox(width:46,child:_tf(hint:'Cr.',col:widget.semCol,num:true,
                      value:sub.creditHours>0?sub.creditHours.toStringAsFixed(0):'',
                      onChanged:(v){sub.creditHours=double.tryParse(v)??0;state.onSave();})),
                  const SizedBox(width:6),
                  if(sub.hasAnyMark) Container(
                      padding:const EdgeInsets.symmetric(horizontal:8,vertical:5),
                      decoration:BoxDecoration(color:sub.gradeColor.withOpacity(0.12),borderRadius:BorderRadius.circular(10),border:Border.all(color:sub.gradeColor.withOpacity(0.40))),
                      child:Column(mainAxisSize:MainAxisSize.min,children:[
                        Text(sub.letterGrade,style:TextStyle(color:sub.gradeColor,fontSize:11,fontWeight:FontWeight.bold)),
                        Text('${pct.toStringAsFixed(1)}%',style:TextStyle(color:sub.gradeColor.withOpacity(0.8),fontSize:9))])),
                  GestureDetector(
                      onTap:()=>setState(()=>sub.isExpanded=!sub.isExpanded),
                      child:Container(padding:const EdgeInsets.all(6),
                          decoration:BoxDecoration(color:widget.semCol.withOpacity(0.10),borderRadius:BorderRadius.circular(8),border:Border.all(color:widget.semCol.withOpacity(0.25))),
                          child:AnimatedRotation(turns:sub.isExpanded?0.5:0.0,duration:const Duration(milliseconds:250),
                              child:Icon(Icons.expand_more_rounded,size:16,color:widget.semCol))))])),
            // Progress bar
            if(sub.hasAnyMark)
              Padding(padding:const EdgeInsets.fromLTRB(12,0,12,8),
                  child:ClipRRect(borderRadius:BorderRadius.circular(6),child:Row(children:[
                    if(sub.quizTotal>0) Flexible(flex:sub.quizW.round(),child:Container(height:5,color:kCyan.withOpacity((sub.quizObt/sub.quizTotal).clamp(0,1)*0.8+0.2))),
                    if(sub.assignTotal>0) Flexible(flex:sub.assignW.round(),child:Container(height:5,color:kMint.withOpacity((sub.assignObt/sub.assignTotal).clamp(0,1)*0.8+0.2))),
                    if(sub.midTotal>0) Flexible(flex:sub.midW.round(),child:Container(height:5,color:kGold.withOpacity((sub.midObt/sub.midTotal).clamp(0,1)*0.8+0.2))),
                    if(sub.finalTotal>0) Flexible(flex:sub.finalW.round(),child:Container(height:5,color:kCherry.withOpacity((sub.finalObt/sub.finalTotal).clamp(0,1)*0.8+0.2)))]))),
            // Expanded marks panel
            if(sub.isExpanded)
              Container(margin:const EdgeInsets.fromLTRB(10,0,10,10),padding:const EdgeInsets.all(12),
                  decoration:BoxDecoration(color:Colors.white.withOpacity(0.03),borderRadius:BorderRadius.circular(12),border:Border.all(color:widget.semCol.withOpacity(0.18))),
                  child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Padding(padding:const EdgeInsets.only(bottom:10),
                        child:Row(children:[
                          const Icon(Icons.bar_chart_rounded,size:13,color:kDim),const SizedBox(width:5),
                          const Text('Marks Breakdown',style:TextStyle(color:kDim,fontSize:11,fontWeight:FontWeight.w600,letterSpacing:0.4)),
                          const Spacer(),
                          ...[('Q',kCyan),('A',kMint),('M',kGold),('F',kCherry)].map((t)=>Padding(padding:const EdgeInsets.only(left:6),
                              child:Row(mainAxisSize:MainAxisSize.min,children:[
                                Container(width:8,height:8,decoration:BoxDecoration(color:t.$2,shape:BoxShape.circle)),
                                const SizedBox(width:3),
                                Text(t.$1,style:TextStyle(color:t.$2,fontSize:9,fontWeight:FontWeight.bold))])))])),
                    _markRow('📝 Quiz',sub.quizObt,sub.quizTotal,sub.quizW,kCyan,
                            (v){setState(()=>sub.quizObt=double.tryParse(v)??0);state.onSave();},
                            (v){setState(()=>sub.quizTotal=double.tryParse(v)??10);state.onSave();}),
                    const SizedBox(height:7),
                    _markRow('📋 Assignment',sub.assignObt,sub.assignTotal,sub.assignW,kMint,
                            (v){setState(()=>sub.assignObt=double.tryParse(v)??0);state.onSave();},
                            (v){setState(()=>sub.assignTotal=double.tryParse(v)??10);state.onSave();}),
                    const SizedBox(height:7),
                    _markRow('📘 Midterm',sub.midObt,sub.midTotal,sub.midW,kGold,
                            (v){setState(()=>sub.midObt=double.tryParse(v)??0);state.onSave();},
                            (v){setState(()=>sub.midTotal=double.tryParse(v)??30);state.onSave();}),
                    const SizedBox(height:7),
                    _markRow('🎓 Final',sub.finalObt,sub.finalTotal,sub.finalW,kCherry,
                            (v){setState(()=>sub.finalObt=double.tryParse(v)??0);state.onSave();},
                            (v){setState(()=>sub.finalTotal=double.tryParse(v)??50);state.onSave();}),
                    if(sub.hasAnyMark)...[
                      const SizedBox(height:10),
                      Container(height:1,color:Colors.white.withOpacity(0.08)),
                      const SizedBox(height:8),
                      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
                        Row(children:[Text(sub.gradeEmoji,style:const TextStyle(fontSize:16)),const SizedBox(width:6),
                          const Text('Total Score',style:TextStyle(color:kWhite,fontSize:12,fontWeight:FontWeight.w700))]),
                        Row(children:[
                          Container(padding:const EdgeInsets.symmetric(horizontal:12,vertical:5),
                              decoration:BoxDecoration(color:sub.gradeColor.withOpacity(0.14),borderRadius:BorderRadius.circular(10),border:Border.all(color:sub.gradeColor.withOpacity(0.45))),
                              child:Text('${pct.toStringAsFixed(1)}%',style:TextStyle(color:sub.gradeColor,fontSize:13,fontWeight:FontWeight.w900))),
                          const SizedBox(width:6),
                          Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:5),
                              decoration:BoxDecoration(color:sub.gradeColor.withOpacity(0.10),borderRadius:BorderRadius.circular(10),border:Border.all(color:sub.gradeColor.withOpacity(0.35))),
                              child:Text(sub.letterGrade,style:TextStyle(color:sub.gradeColor,fontSize:13,fontWeight:FontWeight.w900)))])])]
                  ])),
          ])),
    );
  }

  Widget _markRow(String label,double obtained,double total,double weight,Color col,Function(String) onObt,Function(String) onTotal){
    final frac=total>0?(obtained/total).clamp(0.0,1.0):0.0;
    final scored=total>0?(obtained/total)*weight:0.0;
    return Row(children:[
      SizedBox(width:98,child:Text(label,style:const TextStyle(color:kDim,fontSize:11,fontWeight:FontWeight.w600))),
      SizedBox(width:46,child:_tf(hint:'0',col:col,num:true,value:obtained>0?obtained.toStringAsFixed(0):'',onChanged:onObt)),
      Padding(padding:const EdgeInsets.symmetric(horizontal:4),child:Text('/',style:TextStyle(color:kDim.withOpacity(0.6),fontSize:13,fontWeight:FontWeight.bold))),
      SizedBox(width:46,child:_tf(hint:total.toStringAsFixed(0),col:col,num:true,value:total.toStringAsFixed(0),onChanged:onTotal)),
      const SizedBox(width:6),
      Container(width:34,padding:const EdgeInsets.symmetric(vertical:4),alignment:Alignment.center,
          decoration:BoxDecoration(color:col.withOpacity(0.10),borderRadius:BorderRadius.circular(6),border:Border.all(color:col.withOpacity(0.25))),
          child:Text('${weight.toStringAsFixed(0)}%',style:TextStyle(color:col,fontSize:9,fontWeight:FontWeight.bold))),
      const SizedBox(width:6),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
        ClipRRect(borderRadius:BorderRadius.circular(4),child:Stack(children:[
          Container(height:6,color:Colors.white.withOpacity(0.05)),
          FractionallySizedBox(widthFactor:frac,child:Container(height:6,
              decoration:BoxDecoration(color:col.withOpacity(0.7),borderRadius:BorderRadius.circular(4),boxShadow:[BoxShadow(color:col.withOpacity(0.3),blurRadius:4)])))])),
        const SizedBox(height:2),
        Text('${scored.toStringAsFixed(1)} pts',style:TextStyle(color:col.withOpacity(0.7),fontSize:8))]))]);
  }

  Widget _tf({required String hint,required String value,required Color col,required Function(String) onChanged,bool num=false}){
    final ctrl=TextEditingController(text:value)..selection=TextSelection.collapsed(offset:value.length);
    return TextField(controller:ctrl,
        style:const TextStyle(color:kWhite,fontSize:12,fontWeight:FontWeight.w600),
        cursorColor:col,keyboardType:num?TextInputType.number:TextInputType.text,
        onChanged:onChanged,
        decoration:InputDecoration(hintText:hint,hintStyle:const TextStyle(color:kDim,fontSize:11),
            isDense:true,contentPadding:const EdgeInsets.symmetric(horizontal:8,vertical:8),
            filled:true,fillColor:Colors.white.withOpacity(0.05),
            enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(9),borderSide:BorderSide(color:col.withOpacity(0.22))),
            focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(9),borderSide:BorderSide(color:col,width:1.8))));
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PAGE 3 — ANALYTICS
// ═══════════════════════════════════════════════════════════════════════════════
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context){
    final state=AppState.of(context);
    final gpa=state.cgpa; final col=cgpaColor(gpa);
    final totalCr=state.sems.fold(0.0,(s,sem)=>s+sem.totalCredits);
    final allSubs=state.sems.expand((s)=>s.subjects).toList();
    final hasData=allSubs.any((s)=>s.hasAnyMark);

    return Scaffold(backgroundColor:Colors.transparent,extendBodyBehindAppBar:true,
        appBar:PreferredSize(preferredSize:const Size.fromHeight(62),
            child:ClipRRect(child:BackdropFilter(filter:ImageFilter.blur(sigmaX:20,sigmaY:20),
                child:AppBar(backgroundColor:Colors.black.withOpacity(0.50),elevation:0,centerTitle:true,
                    title:ShaderMask(shaderCallback:(b)=>const LinearGradient(colors:[kMint,kCyan,kIndigo]).createShader(b),
                        child:const Text('ANALYTICS',style:TextStyle(color:Colors.white,fontSize:17,letterSpacing:2.8,fontWeight:FontWeight.w900))),
                    bottom:PreferredSize(preferredSize:const Size.fromHeight(1),
                        child:Container(height:1.5,decoration:const BoxDecoration(gradient:LinearGradient(colors:[kMint,kCyan,kIndigo])))))))),
        body:SafeArea(child:!hasData
            ?const Center(child:Padding(padding:EdgeInsets.all(32),
            child:Text('No data yet.\nGo to Semesters and enter your marks!',textAlign:TextAlign.center,
                style:TextStyle(color:kDim,fontSize:15,height:1.6))))
            :ListView(padding:const EdgeInsets.fromLTRB(16,8,16,100),children:[
          // ── Overview Strip ─────────────────────────────────────────────
          Row(children:[
            Expanded(child:_metricCard('📊','CGPA',gpa.toStringAsFixed(2),cgpaLabel(gpa),col)),
            const SizedBox(width:10),
            Expanded(child:_metricCard('📚','Credits',totalCr.toStringAsFixed(0),'Total earned',kCyan)),
            const SizedBox(width:10),
            Expanded(child:_metricCard('🎓','Semesters',state.sems.length.toString(),'Completed',kMint)),
          ]),
          const SizedBox(height:14),

          // ── GPA Trend ─────────────────────────────────────────────────
          if(state.sems.length>=2) ...[
            _glassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              _sectionTitle('📈','GPA Trend',kCyan),
              const SizedBox(height:14),
              ...state.sems.asMap().entries.map((e){
                final g=e.value.gpa; final c=cgpaColor(g);
                return Padding(padding:const EdgeInsets.only(bottom:10),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
                    Text(e.value.name,style:const TextStyle(color:kWhite,fontSize:12,fontWeight:FontWeight.w600)),
                    Text(g.toStringAsFixed(2),style:TextStyle(color:c,fontSize:12,fontWeight:FontWeight.bold))]),
                  const SizedBox(height:4),
                  ClipRRect(borderRadius:BorderRadius.circular(8),child:Stack(children:[
                    Container(height:20,color:Colors.white.withOpacity(0.05)),
                    FractionallySizedBox(widthFactor:(g/4.0).clamp(0,1),child:Container(height:20,
                        decoration:BoxDecoration(gradient:LinearGradient(colors:[c.withOpacity(0.7),c]),
                            borderRadius:BorderRadius.circular(8),boxShadow:[BoxShadow(color:c.withOpacity(0.3),blurRadius:6)])))]))]));
              }),
              const Divider(height:20,color:Color(0x226366F1)),
              Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
                _miniStat('🏅 Best',state.sems.reduce((a,b)=>a.gpa>=b.gpa?a:b).gpa,kMint),
                _miniStat('📉 Lowest',state.sems.reduce((a,b)=>a.gpa<=b.gpa?a:b).gpa,kCherry),
                _miniStat('📊 Average',gpa,kCyan)]),
            ])),
            const SizedBox(height:14),
          ],

          // ── Grade Distribution ─────────────────────────────────────────
          _glassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            _sectionTitle('🎯','Grade Distribution',kGold),
            const SizedBox(height:14),
            ...[
              ('A  (80–100%)', kMint,  allSubs.where((s)=>s.hasAnyMark&&s.percentage>=80).length),
              ('B  (65–79%)',  kCyan,  allSubs.where((s)=>s.hasAnyMark&&s.percentage>=65&&s.percentage<80).length),
              ('C  (50–64%)',  kGold,  allSubs.where((s)=>s.hasAnyMark&&s.percentage>=50&&s.percentage<65).length),
              ('F  (<50%)',    kCherry,allSubs.where((s)=>s.hasAnyMark&&s.percentage<50).length),
            ].map((t){
              final total=allSubs.where((s)=>s.hasAnyMark).length;
              final frac=total>0?t.$3/total:0.0;
              return Padding(padding:const EdgeInsets.only(bottom:10),child:Row(children:[
                SizedBox(width:80,child:Text(t.$1,style:const TextStyle(color:kDim,fontSize:11,fontWeight:FontWeight.w600))),
                Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(8),child:Stack(children:[
                  Container(height:18,color:Colors.white.withOpacity(0.05)),
                  FractionallySizedBox(widthFactor:frac,child:Container(height:18,
                      decoration:BoxDecoration(color:t.$2.withOpacity(0.8),borderRadius:BorderRadius.circular(8))))]))),
                const SizedBox(width:8),
                Text('${t.$3}',style:TextStyle(color:t.$2,fontSize:12,fontWeight:FontWeight.bold))]));
            }),
          ])),
          const SizedBox(height:14),

          // ── Component Averages ─────────────────────────────────────────
          _glassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            _sectionTitle('📝','Component Averages',kViolet),
            const SizedBox(height:14),
            ...[
              ('📝 Quiz',    kCyan,   allSubs.where((s)=>s.quizTotal>0).map((s)=>(s.quizObt/s.quizTotal)*100).toList()),
              ('📋 Assignment',kMint, allSubs.where((s)=>s.assignTotal>0).map((s)=>(s.assignObt/s.assignTotal)*100).toList()),
              ('📘 Midterm', kGold,   allSubs.where((s)=>s.midTotal>0).map((s)=>(s.midObt/s.midTotal)*100).toList()),
              ('🎓 Final',   kCherry, allSubs.where((s)=>s.finalTotal>0).map((s)=>(s.finalObt/s.finalTotal)*100).toList()),
            ].map((t){
              final vals=t.$3;
              final avg=vals.isEmpty?0.0:vals.reduce((a,b)=>a+b)/vals.length;
              return Padding(padding:const EdgeInsets.only(bottom:10),child:Row(children:[
                SizedBox(width:100,child:Text(t.$1,style:const TextStyle(color:kDim,fontSize:11,fontWeight:FontWeight.w600))),
                Expanded(child:ClipRRect(borderRadius:BorderRadius.circular(8),child:Stack(children:[
                  Container(height:20,color:Colors.white.withOpacity(0.05)),
                  FractionallySizedBox(widthFactor:(avg/100).clamp(0,1),child:Container(height:20,
                      decoration:BoxDecoration(gradient:LinearGradient(colors:[t.$2.withOpacity(0.6),t.$2]),
                          borderRadius:BorderRadius.circular(8),boxShadow:[BoxShadow(color:t.$2.withOpacity(0.3),blurRadius:6)])))]))),
                const SizedBox(width:8),
                SizedBox(width:44,child:Text('${avg.toStringAsFixed(1)}%',style:TextStyle(color:t.$2,fontSize:11,fontWeight:FontWeight.bold)))]));
            }),
          ])),
          const SizedBox(height:14),

          // ── Top 5 Subjects ─────────────────────────────────────────────
          if(allSubs.any((s)=>s.hasAnyMark))
            _glassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
              _sectionTitle('🌟','Top Performing Subjects',kGold),
              const SizedBox(height:14),
              ...(()=>([...allSubs.where((s)=>s.hasAnyMark)]..sort((a,b)=>b.percentage.compareTo(a.percentage))).take(5).toList())()
                  .asMap().entries.map((e){
                final s=e.value; final rank=e.key+1;
                final medals=['🥇','🥈','🥉','4️⃣','5️⃣'];
                return Padding(padding:const EdgeInsets.only(bottom:8),child:Row(children:[
                  Text(medals[e.key],style:const TextStyle(fontSize:18)),const SizedBox(width:10),
                  Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                    Text(s.name.isEmpty?'Subject $rank':s.name,style:const TextStyle(color:kWhite,fontSize:13,fontWeight:FontWeight.w600)),
                    Text(s.letterGrade,style:TextStyle(color:s.gradeColor,fontSize:11))])),
                  Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
                      decoration:BoxDecoration(color:s.gradeColor.withOpacity(0.12),borderRadius:BorderRadius.circular(8),border:Border.all(color:s.gradeColor.withOpacity(0.35))),
                      child:Text('${s.percentage.toStringAsFixed(1)}%',style:TextStyle(color:s.gradeColor,fontSize:12,fontWeight:FontWeight.bold)))]));
              }),
            ])),
        ])));
  }

  Widget _metricCard(String emoji,String label,String value,String sub,Color col)=>_glassCard(
      child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Text(emoji,style:const TextStyle(fontSize:20)),const SizedBox(height:4),
        Text(value,style:TextStyle(color:col,fontSize:22,fontWeight:FontWeight.w900)),
        Text(label,style:const TextStyle(color:kWhite,fontSize:11,fontWeight:FontWeight.w600)),
        Text(sub,style:const TextStyle(color:kDim,fontSize:9))]));

  Widget _sectionTitle(String icon,String title,Color col)=>Row(children:[
    Container(padding:const EdgeInsets.all(7),
        decoration:BoxDecoration(color:col.withOpacity(0.12),borderRadius:BorderRadius.circular(10)),
        child:Text(icon,style:const TextStyle(fontSize:14))),
    const SizedBox(width:10),
    Text(title,style:const TextStyle(color:kWhite,fontSize:14,fontWeight:FontWeight.bold))]);

  Widget _miniStat(String label,double val,Color col)=>Column(children:[
    Text(label,style:const TextStyle(color:kDim,fontSize:10)),const SizedBox(height:3),
    Text(val.toStringAsFixed(2),style:TextStyle(color:col,fontSize:16,fontWeight:FontWeight.bold))]);
}

// ═══════════════════════════════════════════════════════════════════════════════
//  PAGE 4 — ACHIEVEMENTS
// ═══════════════════════════════════════════════════════════════════════════════
class AchievementsPage extends StatelessWidget {
  final VoidCallback showTarget;
  const AchievementsPage({super.key, required this.showTarget});

  @override
  Widget build(BuildContext context){
    final state=AppState.of(context);
    final li=levelInfo(state.xp);
    final lvlName=li['name'] as String; final lvlColor=li['color'] as Color; final lvlFrac=li['frac'] as double;
    final nextMin=li['nextMin'] as int;
    final remaining=nextMin==9999?0:nextMin-state.xp;

    return Scaffold(backgroundColor:Colors.transparent,extendBodyBehindAppBar:true,
        appBar:PreferredSize(preferredSize:const Size.fromHeight(62),
            child:ClipRRect(child:BackdropFilter(filter:ImageFilter.blur(sigmaX:20,sigmaY:20),
                child:AppBar(backgroundColor:Colors.black.withOpacity(0.50),elevation:0,centerTitle:true,
                    title:ShaderMask(shaderCallback:(b)=>const LinearGradient(colors:[kGold,kCherry,kViolet]).createShader(b),
                        child:const Text('ACHIEVEMENTS',style:TextStyle(color:Colors.white,fontSize:17,letterSpacing:2.8,fontWeight:FontWeight.w900))),
                    bottom:PreferredSize(preferredSize:const Size.fromHeight(1),
                        child:Container(height:1.5,decoration:const BoxDecoration(gradient:LinearGradient(colors:[kGold,kCherry,kViolet])))))))),
        body:SafeArea(child:ListView(padding:const EdgeInsets.fromLTRB(16,8,16,100),children:[

          // ── Level Card ─────────────────────────────────────────────────────
          _glassCard(child:Column(children:[
            Row(children:[
              Container(width:56,height:56,decoration:BoxDecoration(shape:BoxShape.circle,
                  gradient:LinearGradient(colors:[lvlColor,lvlColor.withOpacity(0.5)]),
                  boxShadow:[BoxShadow(color:lvlColor.withOpacity(0.4),blurRadius:16)]),
                  child:Center(child:Text(lvlName.split(' ')[0],style:const TextStyle(fontSize:26)))),
              const SizedBox(width:14),
              Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text(lvlName,style:TextStyle(color:lvlColor,fontSize:16,fontWeight:FontWeight.w800)),
                const SizedBox(height:4),
                Text('${state.xp} XP total',style:const TextStyle(color:kDim,fontSize:12)),
                if(nextMin!=9999) Text('$remaining XP to next level',style:TextStyle(color:lvlColor.withOpacity(0.7),fontSize:11))])),
              Column(children:[
                Text('${(lvlFrac*100).toStringAsFixed(0)}%',style:TextStyle(color:lvlColor,fontSize:20,fontWeight:FontWeight.w900)),
                const Text('Progress',style:TextStyle(color:kDim,fontSize:10))]),
            ]),
            const SizedBox(height:14),
            ClipRRect(borderRadius:BorderRadius.circular(8),child:Stack(children:[
              Container(height:10,color:Colors.white.withOpacity(0.08)),
              FractionallySizedBox(widthFactor:lvlFrac,child:Container(height:10,
                  decoration:BoxDecoration(gradient:LinearGradient(colors:[lvlColor.withOpacity(0.6),lvlColor]),
                      borderRadius:BorderRadius.circular(8),boxShadow:[BoxShadow(color:lvlColor.withOpacity(0.5),blurRadius:8)])))])),
            const SizedBox(height:10),
            // Level roadmap
            Row(mainAxisAlignment:MainAxisAlignment.spaceAround,
                children:kLevels.map((l){
                  final reached=state.xp>=(l['min'] as int);
                  final c=l['color'] as Color;
                  return Column(children:[
                    Container(width:28,height:28,decoration:BoxDecoration(shape:BoxShape.circle,
                        color:reached?c.withOpacity(0.20):Colors.white.withOpacity(0.05),
                        border:Border.all(color:reached?c:Colors.white.withOpacity(0.12),width:1.5)),
                        child:Center(child:Text((l['name'] as String).split(' ')[0],style:const TextStyle(fontSize:14)))),
                    const SizedBox(height:3),
                    Text((l['min'] as int)==0?'0':'${(l['min'] as int) ~/ 100}h',
                        style:TextStyle(color:reached?c:kDim,fontSize:8))]);
                }).toList()),
          ])),
          const SizedBox(height:14),

          // ── XP Guide ──────────────────────────────────────────────────────
          _glassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            _sectionHeader('⚡','How to earn XP',kCyan),
            const SizedBox(height:12),
            ...[
              ('🧮 Calculate semester','+ 20 XP',kCyan),
              ('📅 Add a semester','+ 30 XP',kMint),
              ('🏅 Unlock achievement','+ 150 XP',kGold),
            ].map((t)=>Padding(padding:const EdgeInsets.only(bottom:8),child:Row(children:[
              Text(t.$1,style:const TextStyle(color:kDim,fontSize:12)),const Spacer(),
              Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
                  decoration:BoxDecoration(color:t.$3.withOpacity(0.12),borderRadius:BorderRadius.circular(8),border:Border.all(color:t.$3.withOpacity(0.35))),
                  child:Text(t.$2,style:TextStyle(color:t.$3,fontSize:11,fontWeight:FontWeight.bold)))]))),
          ])),
          const SizedBox(height:14),

          // ── Badges Grid ────────────────────────────────────────────────────
          _glassCard(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
            Row(children:[
              _sectionHeader('🏆','Badges',kGold),const Spacer(),
              Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:4),
                  decoration:BoxDecoration(color:kGold.withOpacity(0.12),borderRadius:BorderRadius.circular(10),border:Border.all(color:kGold.withOpacity(0.35))),
                  child:Text('${state.achieved.length}/${kAchievements.length}',
                      style:const TextStyle(color:kGold,fontSize:12,fontWeight:FontWeight.bold)))]),
            const SizedBox(height:14),
            GridView.count(crossAxisCount:3,shrinkWrap:true,physics:const NeverScrollableScrollPhysics(),
                crossAxisSpacing:8,mainAxisSpacing:8,childAspectRatio:1.1,
                children:kAchievements.entries.map((e){
                  final unlocked=state.achieved.contains(e.key);
                  final d=e.value;
                  return Tooltip(message:d['desc']!,
                      child:AnimatedContainer(duration:const Duration(milliseconds:300),
                          padding:const EdgeInsets.all(10),
                          decoration:BoxDecoration(
                              color:unlocked?kGold.withOpacity(0.10):Colors.white.withOpacity(0.04),
                              borderRadius:BorderRadius.circular(14),
                              border:Border.all(color:unlocked?kGold.withOpacity(0.50):Colors.white.withOpacity(0.08)),
                              boxShadow:unlocked?[BoxShadow(color:kGold.withOpacity(0.18),blurRadius:12)]:[]),
                          child:Column(mainAxisAlignment:MainAxisAlignment.center,children:[
                            Text(unlocked?d['icon']!:'🔒',style:const TextStyle(fontSize:22)),
                            const SizedBox(height:5),
                            Text(d['title']!,textAlign:TextAlign.center,style:TextStyle(
                                color:unlocked?kGold:kDim,fontSize:10,
                                fontWeight:unlocked?FontWeight.bold:FontWeight.normal))])));
                }).toList()),
          ])),
          const SizedBox(height:14),

          // ── Target CGPA Button ─────────────────────────────────────────────
          GestureDetector(
              onTap:showTarget,
              child:Container(
                  padding:const EdgeInsets.all(18),
                  decoration:BoxDecoration(
                      gradient:LinearGradient(colors:[kIndigo.withOpacity(0.20),kViolet.withOpacity(0.10)]),
                      borderRadius:BorderRadius.circular(20),
                      border:Border.all(color:kIndigo.withOpacity(0.45)),
                      boxShadow:[BoxShadow(color:kIndigo.withOpacity(0.25),blurRadius:20)]),
                  child:Row(children:[
                    Container(padding:const EdgeInsets.all(12),
                        decoration:BoxDecoration(color:kIndigo.withOpacity(0.18),borderRadius:BorderRadius.circular(14)),
                        child:const Icon(Icons.track_changes_rounded,color:kIndigo,size:26)),
                    const SizedBox(width:14),
                    const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                      Text('Target CGPA Calculator',style:TextStyle(color:kWhite,fontSize:15,fontWeight:FontWeight.bold)),
                      SizedBox(height:3),
                      Text('Find out what GPA you need next semester',style:TextStyle(color:kDim,fontSize:12))])),
                    const Icon(Icons.arrow_forward_ios_rounded,color:kDim,size:16)]))),
        ])));
  }

  Widget _sectionHeader(String icon,String title,Color col)=>Row(children:[
    Container(padding:const EdgeInsets.all(7),
        decoration:BoxDecoration(color:col.withOpacity(0.12),borderRadius:BorderRadius.circular(10)),
        child:Icon(_iconFor(icon),size:16,color:col)),
    const SizedBox(width:10),
    Text(title,style:const TextStyle(color:kWhite,fontSize:14,fontWeight:FontWeight.bold))]);

  IconData _iconFor(String s){
    if(s=='⚡') return Icons.bolt_rounded;
    if(s=='🏆') return Icons.emoji_events_rounded;
    return Icons.star_rounded;
  }
}

// ─── Shared Glass Card ────────────────────────────────────────────────────────
Widget _glassCard({required Widget child, EdgeInsets? padding}){
  return ClipRRect(borderRadius:BorderRadius.circular(22),
      child:BackdropFilter(filter:ImageFilter.blur(sigmaX:16,sigmaY:16),
          child:Container(
              padding:padding??const EdgeInsets.all(16),
              decoration:BoxDecoration(color:kGlass,borderRadius:BorderRadius.circular(22),border:Border.all(color:kBorder)),
              child:child)));
}

// ─── Dashboard helper (defined outside so both page types can use) ─────────────
Widget _tf2({required String hint,required String value,required Color col,required Function(String) onChanged,bool num=false}){
  final ctrl=TextEditingController(text:value)..selection=TextSelection.collapsed(offset:value.length);
  return TextField(controller:ctrl,
      style:const TextStyle(color:kWhite,fontSize:12,fontWeight:FontWeight.w600),
      cursorColor:col,keyboardType:num?TextInputType.number:TextInputType.text,
      onChanged:onChanged,
      decoration:InputDecoration(hintText:hint,hintStyle:const TextStyle(color:kDim,fontSize:11),
          isDense:true,contentPadding:const EdgeInsets.symmetric(horizontal:8,vertical:8),
          filled:true,fillColor:Colors.white.withOpacity(0.05),
          enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(9),borderSide:BorderSide(color:col.withOpacity(0.22))),
          focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(9),borderSide:BorderSide(color:col,width:1.8))));
}