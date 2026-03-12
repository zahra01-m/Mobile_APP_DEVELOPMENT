import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const QuizApp());
}

// ----------------- MAIN APP -----------------
class QuizApp extends StatefulWidget {
  const QuizApp({super.key});

  @override
  State<QuizApp> createState() => _QuizAppState();
}

class _QuizAppState extends State<QuizApp> {
  bool isDarkMode = false;

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: isDarkMode
          ? ThemeData.dark(useMaterial3: true)
          : ThemeData.light(useMaterial3: true),
      home: UsernameScreen(toggleTheme: toggleTheme, isDarkMode: isDarkMode),
    );
  }
}

// ----------------- USERNAME SCREEN -----------------
class UsernameScreen extends StatefulWidget {
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const UsernameScreen(
      {super.key, required this.toggleTheme, required this.isDarkMode});

  @override
  State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> {
  final TextEditingController controller = TextEditingController();

  void next() {
    if (controller.text.trim().isEmpty) return;
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SubjectSelection(
              username: controller.text.trim(),
              toggleTheme: widget.toggleTheme,
              isDarkMode: widget.isDarkMode,
            )));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF141E30), Color(0xFF243B55)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Center(
          child: Container(
            width: 350,
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black45, blurRadius: 10, offset: Offset(3, 6))
                ]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Enter Your Name",
                    style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Username",
                    hintStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white12,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: next,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 14)),
                  child: const Text("Continue"),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ----------------- SUBJECT SELECTION -----------------
class SubjectSelection extends StatelessWidget {
  final String username;
  final VoidCallback toggleTheme;
  final bool isDarkMode;

  const SubjectSelection(
      {super.key,
        required this.username,
        required this.toggleTheme,
        required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    List<String> subjects = [
      "Operating System",
      "Design & Analysis of Algorithm",
      "Computer Org & Assembly",
      "Statistics & Probability",
      "Web Technologies",
      "Mobile App Development"
    ];

    // Calculate max width based on longest subject
    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    double maxWidth = 0;
    for (var subject in subjects) {
      textPainter.text = TextSpan(
        text: subject,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      if (textPainter.width > maxWidth) maxWidth = textPainter.width;
    }
    maxWidth += 40; // padding

    return Scaffold(
      appBar: AppBar(
        title: Text("Select Subject for $username"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: toggleTheme,
          )
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Center(
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            children: subjects.map((subject) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => DifficultySelection(
                              username: username, subject: subject)));
                },
                child: Container(
                  width: maxWidth,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFFf953c6), Color(0xFFb91d73)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black45,
                          blurRadius: 12,
                          offset: Offset(3, 6))
                    ],
                  ),
                  child: Center(
                    child: Text(
                      subject,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ----------------- DIFFICULTY SELECTION -----------------
class DifficultySelection extends StatelessWidget {
  final String username;
  final String subject;

  const DifficultySelection({super.key, required this.username, required this.subject});

  @override
  Widget build(BuildContext context) {
    List<String> levels = ["Easy", "Medium", "Hard"];

    final TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
    double maxWidth = 0;
    for (var level in levels) {
      textPainter.text = TextSpan(
        text: level,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      if (textPainter.width > maxWidth) maxWidth = textPainter.width;
    }
    maxWidth += 60;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Difficulty Level"),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF141E30), Color(0xFF243B55)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Center(
          child: Wrap(
            spacing: 20,
            runSpacing: 20,
            children: levels.map((level) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => QuizPage(
                              username: username,
                              subject: subject,
                              difficulty: level)));
                },
                child: Container(
                  width: maxWidth,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF12c2e9), Color(0xFFc471ed)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black38,
                          blurRadius: 10,
                          offset: Offset(3, 6))
                    ],
                  ),
                  child: Center(
                    child: Text(
                      level,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ----------------- QUIZ PAGE -----------------
class QuizPage extends StatefulWidget {
  final String username;
  final String subject;
  final String difficulty;

  const QuizPage(
      {super.key,
        required this.username,
        required this.subject,
        required this.difficulty});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int currentQuestion = 0;
  int score = 0;
  int timeLeft = 5;
  Timer? timer;
  bool answered = false;
  String? selectedAnswer;

  late List<Map<String, Object>> questions;

  @override
  void initState() {
    super.initState();
    loadQuestions();
    startTimer();
  }

  void loadQuestions() {
    Map<String, Map<String, List<Map<String, Object>>>> allQuestions = {
      "Operating System": {
        "Easy": [
          {"question": "What is OS?", "options": ["Interface", "Hardware", "App", "Compiler"], "answer": "Interface"},
          {"question": "Deadlock means?", "options": ["Waiting forever", "Crash", "Boot", "None"], "answer": "Waiting forever"},
          {"question": "FCFS is?", "options": ["Scheduling", "Memory", "File", "CPU"], "answer": "Scheduling"},
          {"question": "Kernel is?", "options": ["Core", "App", "User", "None"], "answer": "Core"},
          {"question": "Paging removes?", "options": ["Fragmentation", "CPU", "User", "File"], "answer": "Fragmentation"},
        ],
        "Medium": [
          {"question": "Round Robin uses?", "options": ["Time slice", "Priority", "FIFO", "None"], "answer": "Time slice"},
          {"question": "Thrashing due to?", "options": ["Excess paging", "CPU", "Disk", "None"], "answer": "Excess paging"},
          {"question": "Semaphore used for?", "options": ["Sync", "File", "Memory", "None"], "answer": "Sync"},
          {"question": "Virtual memory uses?", "options": ["Disk", "RAM", "CPU", "Cache"], "answer": "Disk"},
          {"question": "Context switch is?", "options": ["Process change", "Memory", "Disk", "None"], "answer": "Process change"},
        ],
        "Hard": [
          {"question": "Banker algorithm prevents?", "options": ["Deadlock", "Crash", "Error", "File"], "answer": "Deadlock"},
          {"question": "Starvation is?", "options": ["No CPU", "No RAM", "No Disk", "None"], "answer": "No CPU"},
          {"question": "Monolithic kernel?", "options": ["Single layer", "Multi", "None", "OS"], "answer": "Single layer"},
          {"question": "IPC stands for?", "options": ["Inter Process Communication", "Internal", "Internet", "None"], "answer": "Inter Process Communication"},
          {"question": "Spooling means?", "options": ["Queue jobs", "Delete", "Save", "Boot"], "answer": "Queue jobs"},
        ],
      },

      // ================= DAA =================
      "Design & Analysis of Algorithm": {
        "Easy": [
          {"question": "Binary search complexity?", "options": ["O(log n)", "O(n)", "O(n²)", "O(1)"], "answer": "O(log n)"},
          {"question": "Merge sort type?", "options": ["Divide & Conquer", "Greedy", "DP", "None"], "answer": "Divide & Conquer"},
          {"question": "Linear search?", "options": ["O(n)", "O(log n)", "O(1)", "O(n²)"], "answer": "O(n)"},
          {"question": "Sorting arranges?", "options": ["Data", "CPU", "RAM", "Disk"], "answer": "Data"},
          {"question": "Algorithm means?", "options": ["Steps", "Code", "Error", "None"], "answer": "Steps"},
        ],
        "Medium": [
          {"question": "Quick sort avg?", "options": ["O(n log n)", "O(n)", "O(n²)", "O(1)"], "answer": "O(n log n)"},
          {"question": "Dijkstra finds?", "options": ["Shortest path", "Sort", "Search", "None"], "answer": "Shortest path"},
          {"question": "Greedy works on?", "options": ["Local optimum", "Global", "None", "All"], "answer": "Local optimum"},
          {"question": "DP solves?", "options": ["Overlapping", "Sorting", "Searching", "None"], "answer": "Overlapping"},
          {"question": "Big-O shows?", "options": ["Complexity", "Error", "CPU", "Disk"], "answer": "Complexity"},
        ],
        "Hard": [
          {"question": "NP complete?", "options": ["Hard problems", "Easy", "Linear", "None"], "answer": "Hard problems"},
          {"question": "Backtracking used in?", "options": ["N-Queen", "Sort", "Search", "None"], "answer": "N-Queen"},
          {"question": "Heap used for?", "options": ["Priority queue", "Stack", "Queue", "None"], "answer": "Priority queue"},
          {"question": "Time complexity depends on?", "options": ["Input size", "CPU", "RAM", "None"], "answer": "Input size"},
          {"question": "Space complexity measures?", "options": ["Memory", "CPU", "Disk", "Time"], "answer": "Memory"},
        ],
      },

      // ================= COA =================
      "Computer Org & Assembly": {
        "Easy": [
          {"question": "ALU performs?", "options": ["Arithmetic", "Storage", "Control", "None"], "answer": "Arithmetic"},
          {"question": "Register is?", "options": ["Small memory", "Large", "Disk", "None"], "answer": "Small memory"},
          {"question": "Binary base?", "options": ["2", "10", "8", "16"], "answer": "2"},
          {"question": "Assembly is?", "options": ["Low level", "High", "None", "App"], "answer": "Low level"},
          {"question": "CPU full form?", "options": ["Central Processing Unit", "Control Unit", "None", "Core"], "answer": "Central Processing Unit"},
        ],
        "Medium": [
          {"question": "Stack works on?", "options": ["LIFO", "FIFO", "Random", "None"], "answer": "LIFO"},
          {"question": "Opcode is?", "options": ["Operation code", "Address", "Data", "None"], "answer": "Operation code"},
          {"question": "Cache memory is?", "options": ["Fast", "Slow", "External", "None"], "answer": "Fast"},
          {"question": "Interrupt is?", "options": ["Signal", "Error", "Memory", "None"], "answer": "Signal"},
          {"question": "Bus connects?", "options": ["Components", "Apps", "Users", "None"], "answer": "Components"},
        ],
        "Hard": [
          {"question": "Pipelining improves?", "options": ["Speed", "Size", "Disk", "None"], "answer": "Speed"},
          {"question": "Microprocessor contains?", "options": ["CPU", "RAM", "Disk", "None"], "answer": "CPU"},
          {"question": "RISC stands for?", "options": ["Reduced Instruction Set Computer", "Random", "None", "Core"], "answer": "Reduced Instruction Set Computer"},
          {"question": "Addressing mode?", "options": ["Operand location", "CPU", "RAM", "None"], "answer": "Operand location"},
          {"question": "Clock speed measured in?", "options": ["Hz", "MB", "GB", "Volt"], "answer": "Hz"},
        ],
      },

      // ================= STATISTICS =================
      "Statistics & Probability": {
        "Easy": [
          {"question": "Mean is?", "options": ["Average", "Middle", "Mode", "None"], "answer": "Average"},
          {"question": "Probability range?", "options": ["0-1", "1-10", "0-10", "None"], "answer": "0-1"},
          {"question": "Median is?", "options": ["Middle", "Avg", "Mode", "None"], "answer": "Middle"},
          {"question": "Mode is?", "options": ["Most frequent", "Least", "Avg", "None"], "answer": "Most frequent"},
          {"question": "Variance shows?", "options": ["Spread", "Mean", "Mode", "None"], "answer": "Spread"},
        ],
        "Medium": [
          {"question": "Normal curve shape?", "options": ["Bell", "Square", "Line", "None"], "answer": "Bell"},
          {"question": "Standard deviation?", "options": ["Spread", "Mean", "Mode", "None"], "answer": "Spread"},
          {"question": "Random variable?", "options": ["Outcome", "Mean", "Mode", "None"], "answer": "Outcome"},
          {"question": "Sampling is?", "options": ["Subset", "Whole", "None", "Mean"], "answer": "Subset"},
          {"question": "Correlation shows?", "options": ["Relation", "Mean", "Mode", "None"], "answer": "Relation"},
        ],
        "Hard": [
          {"question": "Binomial distribution?", "options": ["Discrete", "Continuous", "None", "Mean"], "answer": "Discrete"},
          {"question": "Poisson used for?", "options": ["Rare events", "Mean", "Mode", "None"], "answer": "Rare events"},
          {"question": "Z-score measures?", "options": ["Standard distance", "Mean", "Mode", "None"], "answer": "Standard distance"},
          {"question": "Confidence interval?", "options": ["Estimate range", "Mean", "Mode", "None"], "answer": "Estimate range"},
          {"question": "Hypothesis test?", "options": ["Decision rule", "Mean", "Mode", "None"], "answer": "Decision rule"},
        ],
      },

      // ================= WEB =================
      "Web Technologies": {
        "Easy": [
          {"question": "HTML used for?", "options": ["Structure", "Style", "Logic", "None"], "answer": "Structure"},
          {"question": "CSS used for?", "options": ["Styling", "Logic", "Server", "None"], "answer": "Styling"},
          {"question": "JS is?", "options": ["Programming", "Style", "Markup", "None"], "answer": "Programming"},
          {"question": "HTTP stands for?", "options": ["Hyper Text Transfer Protocol", "None", "Server", "App"], "answer": "Hyper Text Transfer Protocol"},
          {"question": "URL is?", "options": ["Web address", "Code", "App", "None"], "answer": "Web address"},
        ],
        "Medium": [
          {"question": "DOM stands for?", "options": ["Document Object Model", "Data", "None", "App"], "answer": "Document Object Model"},
          {"question": "REST is?", "options": ["Architecture", "Language", "None", "Server"], "answer": "Architecture"},
          {"question": "Bootstrap is?", "options": ["CSS framework", "Language", "None", "Server"], "answer": "CSS framework"},
          {"question": "API stands for?", "options": ["Application Programming Interface", "None", "App", "Server"], "answer": "Application Programming Interface"},
          {"question": "JSON is?", "options": ["Data format", "Language", "None", "Server"], "answer": "Data format"},
        ],
        "Hard": [
          {"question": "SPA means?", "options": ["Single Page Application", "Server", "None", "App"], "answer": "Single Page Application"},
          {"question": "Node.js is?", "options": ["Runtime", "Language", "None", "App"], "answer": "Runtime"},
          {"question": "SQL injection?", "options": ["Attack", "Framework", "None", "Server"], "answer": "Attack"},
          {"question": "HTTPS uses?", "options": ["SSL", "HTML", "CSS", "None"], "answer": "SSL"},
          {"question": "Responsive design?", "options": ["Flexible layout", "Static", "None", "Server"], "answer": "Flexible layout"},
        ],
      },

      // ================= MOBILE =================
      "Mobile App Development": {
        "Easy": [
          {"question": "Flutter language?", "options": ["Dart", "Java", "C++", "None"], "answer": "Dart"},
          {"question": "APK stands for?", "options": ["Android Package", "None", "App", "Server"], "answer": "Android Package"},
          {"question": "Widget is?", "options": ["UI element", "Logic", "None", "Server"], "answer": "UI element"},
          {"question": "Hot reload?", "options": ["Fast update", "Restart", "None", "Server"], "answer": "Fast update"},
          {"question": "Play Store is?", "options": ["Distribution", "Server", "None", "App"], "answer": "Distribution"},
        ],
        "Medium": [
          {"question": "Stateful widget?", "options": ["Mutable", "Static", "None", "App"], "answer": "Mutable"},
          {"question": "Provider is?", "options": ["State management", "Server", "None", "App"], "answer": "State management"},
          {"question": "Emulator is?", "options": ["Virtual device", "Server", "None", "App"], "answer": "Virtual device"},
          {"question": "Firebase is?", "options": ["Backend service", "Language", "None", "App"], "answer": "Backend service"},
          {"question": "Navigation uses?", "options": ["Routes", "Server", "None", "App"], "answer": "Routes"},
        ],
        "Hard": [
          {"question": "Bloc is?", "options": ["Architecture pattern", "Server", "None", "App"], "answer": "Architecture pattern"},
          {"question": "Riverpod is?", "options": ["State management", "Server", "None", "App"], "answer": "State management"},
          {"question": "Async means?", "options": ["Non blocking", "Blocking", "None", "App"], "answer": "Non blocking"},
          {"question": "Platform channel?", "options": ["Native communication", "Server", "None", "App"], "answer": "Native communication"},
          {"question": "Build method?", "options": ["Returns UI", "Server", "None", "App"], "answer": "Returns UI"},
        ],
      },
    };

    questions = List.from(allQuestions[widget.subject]?[widget.difficulty] ?? []);
    questions.shuffle(Random());
  }
// ------------------- TIMER & TIMEOUT WITH POPUP -------------------
  void startTimer() {
    timeLeft = 5;      // Reset timer for each question
    answered = false;  // Reset answered state
    selectedAnswer = null;

    timer?.cancel();   // Cancel any existing timer

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (timeLeft > 0) {
        setState(() => timeLeft--);  // Update countdown UI
      } else {
        t.cancel();                  // Stop timer
        showTimeOutPopup();          // Show timeout popup
      }
    });
  }

  void showTimeOutPopup() {
    answered = true; // Prevent clicking any option
    selectedAnswer = null;

    // Show popup using AlertDialog
    showDialog(
      context: context,
      barrierDismissible: false, // User cannot close manually
      builder: (_) => AlertDialog(
        title: const Text("Time's Up!"),
        content: const Text("Moving to the next question..."),
      ),
    );

    // Automatically close popup and move to next question after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pop(context); // Close the dialog
      nextQuestion();         // Go to next question
    });

    setState(() {}); // Refresh UI (optional)
  }

  void selectAnswer(String option) {
    if (answered) return;    // Prevent multiple selections
    timer?.cancel();         // Stop timer immediately
    answered = true;
    selectedAnswer = option;

    if (option == questions[currentQuestion]["answer"]) score++;

    setState(() {}); // Update UI colors

    Future.delayed(const Duration(seconds: 1), nextQuestion);
  }

  void nextQuestion() {
    if (currentQuestion < questions.length - 1) {
      setState(() {
        currentQuestion++;
      });
      startTimer();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            username: widget.username,
            score: score,
            total: questions.length,
          ),
        ),
      );
    }
  }
  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text("No questions available for this subject/difficulty",
              style: TextStyle(fontSize: 20, color: Colors.redAccent)),
        ),
      );
    }

    var q = questions[currentQuestion];

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.subject} (${widget.difficulty})"),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF1F1C2C), Color(0xFF928DAB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Timer + Progress
              Column(
                children: [
                  Container(
                    height: 14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFf953c6), Color(0xFFb91d73)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: FractionallySizedBox(
                      widthFactor: (currentQuestion + 1) / questions.length,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors: [Color(0xFF12c2e9), Color(0xFFc471ed)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                            color: Colors.black38, blurRadius: 6, offset: Offset(2, 4))
                      ],
                    ),
                    child: Text(
                      "Time Left: $timeLeft sec",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Question Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFf953c6), Color(0xFFb91d73)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black45, blurRadius: 10, offset: Offset(3, 6))
                  ],
                ),
                child: Text(
                  q["question"].toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              // Options
              ...List.generate(
                (q["options"] as List<String>).length,
                    (index) {
                  String option = (q["options"] as List<String>)[index];
                  Color startColor = Colors.blueAccent;
                  Color endColor = Colors.deepPurpleAccent;

                  if (answered) {
                    if (option == q["answer"]) {
                      startColor = Colors.greenAccent;
                      endColor = Colors.green;
                    } else if (option == selectedAnswer) {
                      startColor = Colors.redAccent;
                      endColor = Colors.red;
                    } else {
                      startColor = Colors.blueGrey;
                      endColor = Colors.blueGrey.shade700;
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                            colors: [startColor, endColor],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black38, blurRadius: 8, offset: Offset(2, 4))
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)),
                        ),
                        onPressed: answered ? null : () => selectAnswer(option),
                        child: Text(
                          option,
                          style: const TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- RESULT PAGE -----------------
class ResultPage extends StatelessWidget {
  final String username;
  final int score;
  final int total;

  const ResultPage(
      {super.key, required this.username, required this.score, required this.total});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              colors: [Color(0xFF141E30), Color(0xFF243B55)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Card(
                elevation: 10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                color: Colors.white24,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 40),
                  child: Text(
                    "$username, Your Score:\n$score / $total",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 26,
                        color: Colors.yellowAccent,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: 200,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [Color(0xFFf953c6), Color(0xFFb91d73)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black45, blurRadius: 10, offset: Offset(3, 6))
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 30),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25))),
                  onPressed: () {
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  child: const Text(
                    "Try Again",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}