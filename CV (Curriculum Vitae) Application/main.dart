import 'package:flutter/material.dart';

void main() => runApp(ProfileApp());

class ProfileApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ProfilePage(),
    );
  }
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // ── Personal Info ──────────────────────────────────────────────────────────
  final String name     = 'Zahra Mushtaq';
  final String email    = 'zahramushtaq28@gmail.com';
  final String phone    = '+923059288814';
  final String tagline  = 'Front-end Developer';

  // ── State ──────────────────────────────────────────────────────────────────
  int  selectedTheme = 0;
  bool isDarkMode    = false;

  /// false = Professional CV (default)   true = Hobby CV
  bool showHobbyCv   = false;

  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isDarkMode ? Colors.black : Colors.grey[100],
      appBar: AppBar(
        title: Text(showHobbyCv ? 'Hobby CV' : 'Professional CV'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Dark-mode toggle
          IconButton(
            icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => setState(() => isDarkMode = !isDarkMode),
          ),
        ],
      ),
      body: Container(
        decoration: _getBackgroundDecoration(),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── Theme buttons ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildGradientButton('Classic',  [Color(0xFF1A1A2E), Color(0xFFE2B96F)],               0),
                    _buildGradientButton('Modern',   [Color(0xFF7B2FBE), Color(0xFF00C6FF)],               1),
                    _buildGradientButton('Creative', [Color(0xFF11998E), Color(0xFF38EF7D)],               2),
                  ],
                ),

                const SizedBox(height: 16),

                // ── CV-type toggle ─────────────────────────────────────────
                _buildCvToggle(),

                const SizedBox(height: 16),

                // ── Dynamic content ────────────────────────────────────────
                showHobbyCv ? _buildHobbyCV() : _buildProfessionalCV(),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  CV-TYPE TOGGLE WIDGET
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildCvToggle() {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleTab('Professional', icon: Icons.work_outline,    isActive: !showHobbyCv, onTap: () => setState(() => showHobbyCv = false)),
          _toggleTab('Hobby',        icon: Icons.favorite_outline, isActive:  showHobbyCv, onTap: () => setState(() => showHobbyCv = true)),
        ],
      ),
    );
  }

  Widget _toggleTab(String label, {required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(colors: [Colors.indigo, Colors.blue])
              : null,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isActive ? Colors.white : (isDarkMode ? Colors.grey[400] : Colors.grey[600])),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isActive ? Colors.white : (isDarkMode ? Colors.grey[400] : Colors.grey[700]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PROFESSIONAL CV  (default view)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildProfessionalCV() {
    return Column(
      children: [
        _buildProfileCard(subtitle: 'Front-end Developer'),
        const SizedBox(height: 20),
        _buildEducationCard(),
        const SizedBox(height: 20),
        _buildProfessionalSkillsCard(),
        const SizedBox(height: 20),
        _buildExperienceCard(),
        const SizedBox(height: 20),
        _buildContactCard(),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HOBBY CV
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildHobbyCV() {
    return Column(
      children: [
        _buildProfileCard(subtitle: 'Creative Enthusiast & Tech Lover'),
        const SizedBox(height: 20),
        _buildHobbiesCard(),
        const SizedBox(height: 20),
        _buildInterestsCard(),
        const SizedBox(height: 20),
        _buildPersonalSkillsCard(),
        const SizedBox(height: 20),
        _buildContactCard(),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SHARED SECTIONS
  // ══════════════════════════════════════════════════════════════════════════

  /// Profile card – subtitle changes per CV type
  Widget _buildProfileCard({required String subtitle}) {
    return _cardWrapper(
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.indigo[100],
                backgroundImage: const AssetImage('images/my.jpeg'),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            name,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.indigo,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 15,
              color: isDarkMode ? Colors.green[300] : Colors.black54,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return _cardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.contact_mail, 'Contact Information'),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildContactItem(Icons.email, email, 'Email'),
              _buildContactItem(Icons.phone, phone, 'Phone'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String text, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.indigo),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text(text, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.grey[300] : Colors.grey[700])),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  PROFESSIONAL CV SECTIONS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildEducationCard() {
    final List<Map<String, String>> education = [
      {
        'degree'     : 'BS Computer Science',
        'institution': 'University of Engineering & Technology (UET)',
        'year'       : '2023 – Present',
      },
      {
        'degree'     : 'FSc Pre-Engineering',
        'institution': 'Punjab Group of Colleges',
        'year'       : '2021 – 2023',
      },
      {
        'degree'     : 'Matriculation (Science)',
        'institution': 'District Model School',
        'year'       : '2019 – 2021',
      },
    ];

    return _cardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.school, 'Education'),
          const SizedBox(height: 15),
          ...education.map((e) => _buildTimelineItem(
            title    : e['degree']!,
            subtitle : e['institution']!,
            trailing : e['year']!,
            dotColor : Colors.indigo,
          )),
        ],
      ),
    );
  }

  Widget _buildProfessionalSkillsCard() {
    final List<Map<String, dynamic>> skills = [
      {'name': 'Java Programming',          'icon': Icons.code,            'color': Colors.orange,     'level': 0.75},
      {'name': 'Flutter / Dart',            'icon': Icons.phone_android,   'color': Colors.blue,       'level': 0.70},
      {'name': 'Data Structures',           'icon': Icons.account_tree,    'color': Colors.green,      'level': 0.65},
      {'name': 'Git & GitHub',              'icon': Icons.storage,         'color': Colors.black87,    'level': 0.80},
      {'name': 'Python',                    'icon': Icons.memory,          'color': Colors.deepPurple, 'level': 0.60},
      {'name': 'UI / UX Design',            'icon': Icons.design_services, 'color': Colors.pink,       'level': 0.70},
    ];

    return _cardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.star, 'Core Skills'),
          const SizedBox(height: 15),
          ...skills.map((s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(s['icon'] as IconData, color: s['color'] as Color, size: 20),
                    const SizedBox(width: 10),
                    Text(s['name'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.grey[800],
                        )),
                    const Spacer(),
                    Text('${((s['level'] as double) * 100).toInt()}%',
                        style: TextStyle(fontSize: 12, color: s['color'] as Color)),
                  ],
                ),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: s['level'] as double,
                    minHeight: 7,
                    backgroundColor: (s['color'] as Color).withOpacity(0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(s['color'] as Color),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildExperienceCard() {
    return _cardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.work, 'Work Experience'),
          const SizedBox(height: 15),
          _buildTimelineItem(
              title    : 'Front-End Developer',
              subtitle : 'Tech Solutions Inc.',
              trailing : '2025 – Present',
              dotColor : Colors.green),
          _buildTimelineItem(
              title    : 'Graphic Designer',
              subtitle : 'Google (Internship)',
              trailing : '2025 – 2026',
              dotColor : Colors.blue),
          _buildTimelineItem(
              title    : 'Cybersecurity Learner',
              subtitle : 'Self-Learning',
              trailing : '2025 – 2026',
              dotColor : Colors.orange),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HOBBY CV SECTIONS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHobbiesCard() {
    final List<Map<String, dynamic>> hobbies = [
      {
        'name' : 'Competitive Programming',
        'desc' : 'Solving DSA problems on LeetCode & HackerRank daily',
        'icon' : Icons.terminal,
        'color': const Color(0xFF4776E6),
        'stars': 5,
      },
      {
        'name' : 'Tech Blogging',
        'desc' : 'Writing tutorials on Flutter, Git & dev tools',
        'icon' : Icons.edit_note,
        'color': const Color(0xFF11998E),
        'stars': 4,
      },
      {
        'name' : 'UI / UX Sketching',
        'desc' : 'Designing wireframes & mockups using Figma',
        'icon' : Icons.brush,
        'color': const Color(0xFFE91E8C),
        'stars': 4,
      },
      {
        'name' : 'Open-Source Projects',
        'desc' : 'Contributing to GitHub repos & building side projects',
        'icon' : Icons.folder_special,
        'color': const Color(0xFF9B27AF),
        'stars': 4,
      },
      {
        'name' : 'Watching Sci-Fi / Tech Docs',
        'desc' : 'Loves Black Mirror, Mr. Robot & AI documentaries',
        'icon' : Icons.movie_filter,
        'color': const Color(0xFFFF6B35),
        'stars': 5,
      },
      {
        'name' : 'Reading Research Papers',
        'desc' : 'Following latest AI & cybersecurity publications',
        'icon' : Icons.menu_book,
        'color': const Color(0xFF00BCD4),
        'stars': 3,
      },
    ];

    return _cardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.sports_esports, 'Hobbies'),
          const SizedBox(height: 6),
          Text(
            "Things I enjoy when I'm not coding (or while coding 😄)",
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: isDarkMode ? Colors.grey[400] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ...hobbies.map((h) {
            final Color c = h['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [c.withOpacity(0.3), c.withOpacity(0.1)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(h['icon'] as IconData, color: c, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          h['name'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDarkMode ? Colors.white : Colors.grey[850],
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          h['desc'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(5, (i) => Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: Icon(
                              i < (h['stars'] as int) ? Icons.star : Icons.star_border,
                              size: 13,
                              color: i < (h['stars'] as int) ? c : Colors.grey[400],
                            ),
                          )),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInterestsCard() {
    final List<Map<String, dynamic>> interests = [
      {
        'title': 'Mobile App Development',
        'desc' : 'Building cross-platform apps with Flutter & Dart.',
        'icon' : Icons.phone_android,
        'color': Colors.blue,
      },
      {
        'title': 'Cybersecurity',
        'desc' : 'Exploring ethical hacking and network security concepts.',
        'icon' : Icons.security,
        'color': Colors.red,
      },
      {
        'title': 'Artificial Intelligence',
        'desc' : 'Curious about ML models and AI-driven solutions.',
        'icon' : Icons.smart_toy,
        'color': Colors.purple,
      },
      {
        'title': 'Open-Source Contribution',
        'desc' : 'Contributing to community-driven software projects.',
        'icon' : Icons.public,
        'color': Colors.green,
      },
    ];

    return _cardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.lightbulb, 'Interests'),
          const SizedBox(height: 15),
          ...interests.map((i) => Container(
            margin: const EdgeInsets.symmetric(vertical: 7),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (i['color'] as Color).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (i['color'] as Color).withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (i['color'] as Color).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(i['icon'] as IconData, color: i['color'] as Color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(i['title'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDarkMode ? Colors.white : Colors.grey[850],
                          )),
                      const SizedBox(height: 3),
                      Text(i['desc'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          )),
                    ],
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPersonalSkillsCard() {
    final List<Map<String, dynamic>> skills = [
      {'name': 'Creative Thinking',  'icon': Icons.psychology,         'color': Colors.indigo},
      {'name': 'Problem Solving',    'icon': Icons.extension,          'color': Colors.teal},
      {'name': 'Teamwork',           'icon': Icons.people,             'color': Colors.blue},
      {'name': 'Time Management',    'icon': Icons.timer,              'color': Colors.orange},
      {'name': 'Communication',      'icon': Icons.chat_bubble_outline, 'color': Colors.pink},
      {'name': 'Adaptability',       'icon': Icons.swap_horiz,         'color': Colors.green},
      {'name': 'Self-Motivation',    'icon': Icons.rocket_launch,      'color': Colors.purple},
    ];

    return _cardWrapper(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle(Icons.emoji_events, 'Personal Skills'),
          const SizedBox(height: 15),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3.0,
            children: skills.map((s) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: (s['color'] as Color).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(s['icon'] as IconData, color: s['color'] as Color, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        s['name'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : Colors.grey[800],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HELPERS
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTimelineItem({
    required String title,
    required String subtitle,
    required String trailing,
    required Color dotColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
              ),
              Container(width: 2, height: 46, color: dotColor.withOpacity(0.25)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isDarkMode ? Colors.white : Colors.indigo[800],
                    )),
                Text(subtitle,
                    style: TextStyle(
                        color: isDarkMode ? Colors.grey[300] : Colors.grey[600])),
                Text(trailing,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardWrapper({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: isDarkMode ? Colors.white : Colors.indigo),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.indigo,
            )),
      ],
    );
  }

  Widget _buildGradientButton(String text, List<Color> colors, int themeIndex) {
    bool isSelected = selectedTheme == themeIndex;
    return GestureDetector(
      onTap: () => setState(() => selectedTheme = themeIndex),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(20),
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
        ),
        child: Text(text,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  BoxDecoration _getBackgroundDecoration() {
    switch (selectedTheme) {
      case 0: // Classic – midnight navy → warm gold
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFFE2B96F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 1: // Modern – deep violet → sky cyan
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7B2FBE), Color(0xFF4776E6), Color(0xFF00C6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case 2: // Creative – teal → mint green
        return const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF11998E), Color(0xFF2ECC71), Color(0xFF38EF7D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      default:
        return BoxDecoration(
          color: isDarkMode ? Colors.black : Colors.grey[100],
        );
    }
  }
}