import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/learning.dart';
import '../services/app_store.dart';
import '../widgets/game_widgets.dart';
import 'lesson_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store, this.bootError});
  final AppStore store;
  final String? bootError;
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int nav = 0;
  late int selectedDay = widget.store.currentDay;
  AppStore get store => widget.store;
  String? boardError;
  bool boardLoading = false;
  static const labels = [
    'Moje učenie',
    'Plán na 14 dní',
    'Rebríček',
    'Nastavenia',
  ];
  static const icons = [
    Icons.dashboard_rounded,
    Icons.route_rounded,
    Icons.emoji_events_rounded,
    Icons.tune_rounded,
  ];
  Future<void> selectNav(int value) async {
    setState(() => nav = value);
    if (value == 2 && store.signedIn) {
      setState(() {
        boardError = null;
        boardLoading = true;
      });
      try {
        await store.loadLeaderboard();
      } catch (_) {
        if (mounted) {
          setState(
            () => boardError = 'Rebríček sa nepodarilo načítať. Skús to znova.',
          );
        }
      } finally {
        if (mounted) setState(() => boardLoading = false);
      }
    }
  }

  Future<void> openLesson(DailyLesson lesson) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => LessonScreen(lesson: lesson, store: store),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1100;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (wide)
              Container(
                width: 240,
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 24),
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(
                    right: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: .4),
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Brand(),
                    const SizedBox(height: 8),
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Text(
                        'MALÉ KROKY. VEĽKÉ VEDOMOSTI.',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w800,
                          color: teal,
                        ),
                      ),
                    ),
                    const SizedBox(height: 44),
                    ...List.generate(
                      4,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            selected: nav == i,
                            selectedTileColor: teal.withValues(alpha: .09),
                            selectedColor: teal,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            leading: Icon(icons[i], size: 23),
                            title: Text(
                              labels[i],
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            onTap: () => selectNav(i),
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Panel(
                      padding: const EdgeInsets.all(16),
                      color: violet.withValues(alpha: .06),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.school_rounded, color: violet),
                          const SizedBox(height: 10),
                          const Text(
                            'Tvoj vlastný rytmus',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '12 otázok denne. Každý deň nový kúsok sveta.',
                            style: TextStyle(fontSize: 12, height: 1.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${store.grade}. ročník · plán 2026',
                            style: const TextStyle(
                              fontSize: 11,
                              color: violet,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Vedomax 2.0 • vytvorené pre zvedavých',
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: wide ? 36 : 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: cs.surface,
                      border: Border(
                        bottom: BorderSide(
                          color: cs.outlineVariant.withValues(alpha: .35),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        if (!wide && MediaQuery.sizeOf(context).width < 370)
                          const Mascot(size: 40)
                        else if (!wide)
                          const Brand(compact: true)
                        else
                          Text(
                            labels[nav],
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        const Spacer(),
                        if (MediaQuery.sizeOf(context).width > 440)
                          _Stat(
                            icon: Icons.local_fire_department_rounded,
                            color: const Color(0xffdc7c26),
                            text: '${store.profile.streak}',
                          ),
                        const SizedBox(width: 16),
                        _Stat(
                          icon: Icons.bolt_rounded,
                          color: violet,
                          text: '${store.profile.xp} XP',
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          tooltip: 'Účet a prihlásenie',
                          onPressed: auth,
                          icon: CircleAvatar(
                            radius: 18,
                            backgroundColor: teal.withValues(alpha: .1),
                            child: Icon(
                              store.signedIn
                                  ? Icons.person_rounded
                                  : Icons.person_outline_rounded,
                              color: teal,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1250),
                        child: ListView(
                          padding: EdgeInsets.all(wide ? 36 : 20),
                          children: [
                            if (widget.bootError != null)
                              _Notice(widget.bootError!),
                            if (store.syncError != null)
                              _Notice(
                                store.syncError!,
                                action: () => store.refreshProfile(),
                              ),
                            if (nav == 0) ...home(wide),
                            if (nav == 1) ...plan(),
                            if (nav == 2) ...board(),
                            if (nav == 3)
                              SettingsPanel(store: store, onAuth: auth),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: nav,
              onDestinationSelected: selectNav,
              destinations: List.generate(
                4,
                (i) => NavigationDestination(
                  icon: Icon(icons[i]),
                  label: i == 0
                      ? 'Učenie'
                      : i == 1
                      ? 'Plán'
                      : labels[i],
                ),
              ),
            ),
    );
  }

  List<Widget> home(bool wide) {
    final lessons = store.lessons
        .where((l) => l.grade == store.grade && l.day == selectedDay)
        .toList();
    final done = store.completedOn(selectedDay);
    return [
      Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 20,
        runSpacing: 12,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ahoj, ${store.profile.username}!',
                style: const TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.8,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Dnes je dobrý deň naučiť sa niečo nové.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          _GradeSwitch(store: store),
        ],
      ),
      const SizedBox(height: 26),
      Container(
        padding: EdgeInsets.all(wide ? 32 : 24),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xff087f8c), Color(0xff12665f)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            final horizontal = c.maxWidth > 580;
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .13),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'TVOJA DENNÁ VÝZVA  •  DEŇ $selectedDay / 14',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: Color(0xffc8f2df),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Vedomosti na\nMaximum.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                    letterSpacing: -1.7,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Vedomax - Vedomosti na Maximum pre všetky deti',
                  style: TextStyle(
                    color: Color(0xffdef2e9),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                GameButton(
                  label: done == 3 ? 'Zopakovať dnešnú výzvu' : 'Poďme na to',
                  icon: Icons.play_arrow_rounded,
                  color: const Color(0xffd88a15),
                  expand: false,
                  onPressed: () => openLesson(
                    lessons.firstWhere(
                      (l) => !store.completed(l.id),
                      orElse: () => lessons.first,
                    ),
                  ),
                ),
              ],
            );
            return horizontal
                ? Row(
                    children: [
                      Expanded(child: copy),
                      const SizedBox(width: 12),
                      const Mascot(size: 245),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      copy,
                      const Center(child: Mascot(size: 165)),
                    ],
                  );
          },
        ),
      ),
      const SizedBox(height: 26),
      LayoutBuilder(
        builder: (context, c) {
          final children = [
            _Metric(
              title: 'DNEŠNÝ POKROK',
              value: '$done / 3 oblasti',
              icon: Icons.donut_large_rounded,
              color: teal,
            ),
            _Metric(
              title: 'DENNÝ CIEĽ',
              value:
                  '${(done * 4).clamp(0, store.dailyGoal)} / ${store.dailyGoal} otázok',
              icon: Icons.flag_rounded,
              color: violet,
            ),
            _Metric(
              title: 'TVOJ REŽIM',
              value: store.signedIn
                  ? 'Účet synchronizovaný'
                  : 'Učenie bez účtu',
              icon: store.signedIn
                  ? Icons.cloud_done_rounded
                  : Icons.devices_rounded,
              color: const Color(0xffc18129),
            ),
          ];
          if (c.maxWidth > 680) {
            return Row(
              children: children
                  .asMap()
                  .entries
                  .expand(
                    (e) => [
                      if (e.key > 0) const SizedBox(width: 14),
                      Expanded(child: e.value),
                    ],
                  )
                  .toList(),
            );
          }
          return Column(
            children: children
                .map(
                  (w) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: w,
                  ),
                )
                .toList(),
          );
        },
      ),
      const SizedBox(height: 30),
      Row(
        children: [
          const Expanded(
            child: Text(
              'Tri oblasti. Jeden veľký krok.',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
            ),
          ),
          TextButton(
            onPressed: () => selectNav(1),
            child: const Text('Celý plán'),
          ),
        ],
      ),
      const SizedBox(height: 6),
      Text(
        'Deň $selectedDay · ${store.grade}. ročník · 4 otázky v každej oblasti',
      ),
      const SizedBox(height: 18),
      LayoutBuilder(
        builder: (context, c) {
          final cards = lessons
              .map(
                (l) => _LessonCard(
                  lesson: l,
                  store: store,
                  onTap: () => openLesson(l),
                ),
              )
              .toList();
          return c.maxWidth > 800
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: cards
                      .asMap()
                      .entries
                      .expand(
                        (e) => [
                          if (e.key > 0) const SizedBox(width: 16),
                          Expanded(child: e.value),
                        ],
                      )
                      .toList(),
                )
              : Column(
                  children: cards
                      .map(
                        (w) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: w,
                        ),
                      )
                      .toList(),
                );
        },
      ),
      const SizedBox(height: 26),
      Panel(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.lightbulb_outline_rounded, color: amber, size: 30),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Najprv pochopiť. Potom oslavovať.',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Po odpovedi uvidíš riešenie a vysvetlenie. Až potom odhalíš svoje body.',
                    style: TextStyle(fontSize: 13, height: 1.5),
                  ),
                  if (!store.signedIn)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Pokrok sa ukladá v tomto zariadení. Účet umožní synchronizáciu.',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> plan() => [
    const Text(
      'Tvoja cesta na dva týždne',
      style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900),
    ),
    const SizedBox(height: 8),
    const Text(
      'Každý deň matematika, slovenčina a geografia. Všetky dni môžeš otvoriť aj vopred.',
    ),
    const SizedBox(height: 20),
    _GradeSwitch(store: store),
    const SizedBox(height: 24),
    ...List.generate(14, (i) {
      final day = i + 1;
      final lessons = store.lessons
          .where((l) => l.grade == store.grade && l.day == day)
          .toList();
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Panel(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: store.completedOn(day) == 3
                        ? teal
                        : violet.withValues(alpha: .12),
                    child: store.completedOn(day) == 3
                        ? const Icon(Icons.check, color: Colors.white)
                        : Text(
                            '$day',
                            style: const TextStyle(
                              color: violet,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Deň $day${day == store.currentDay ? ' · Dnes' : ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  Text(
                    '${store.completedOn(day)} / 3',
                    style: const TextStyle(
                      color: teal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...lessons.map(
                (l) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: Icon(
                    l.subject == 'math'
                        ? Icons.calculate_rounded
                        : l.subject == 'slovak'
                        ? Icons.menu_book_rounded
                        : Icons.public_rounded,
                    color: teal,
                  ),
                  title: Text(l.title),
                  subtitle: Text(
                    '4 otázky${store.completed(l.id) ? ' · najlepšie ${store.best(l.id)} %' : ''}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    setState(() => selectedDay = day);
                    openLesson(l);
                  },
                ),
              ),
            ],
          ),
        ),
      );
    }),
  ];
  List<Widget> board() => [
    const Text(
      'Každé zlepšenie sa počíta',
      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
    ),
    const SizedBox(height: 12),
    const Text(
      'Rebríček zobrazuje iba hráčov, ktorí zdieľanie prezývky a XP zapli v nastaveniach.',
    ),
    const SizedBox(height: 24),
    if (!store.signedIn)
      Panel(
        child: Column(
          children: [
            const Icon(Icons.emoji_events_rounded, color: amber, size: 56),
            const SizedBox(height: 16),
            const Text(
              'Tvoj pokrok má hodnotu aj bez rebríčka.',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Ak sa chceš zapojiť, prihlás sa a potom povoľ zobrazenie v nastaveniach.',
            ),
            const SizedBox(height: 20),
            GameButton(label: 'Možnosti účtu', onPressed: auth),
          ],
        ),
      )
    else if (boardLoading)
      const Center(child: CircularProgressIndicator())
    else if (boardError != null)
      _Notice(boardError!, action: () => selectNav(2))
    else if (store.leaderboard.isEmpty)
      const Panel(child: Text('Zatiaľ sa nezapojil žiadny hráč.'))
    else
      Panel(
        child: Column(
          children: store.leaderboard
              .asMap()
              .entries
              .map(
                (e) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: amber.withValues(alpha: .12),
                    child: Text('${e.key + 1}'),
                  ),
                  title: Text(e.value['username']),
                  trailing: Text(
                    '${e.value['experience_points']} XP',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: violet,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
  ];
  Future<void> auth() async {
    if (store.signedIn) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tvoj účet'),
          content: Text(
            'Prihlásený ako ${store.profile.username}. Výsledky a nastavenia profilu sa ukladajú do účtu.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Zavrieť'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await store.client!.auth.signOut();
                  await store.refreshProfile();
                  if (context.mounted) Navigator.pop(context);
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Odhlásenie sa nepodarilo. Skús znova.'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Odhlásiť sa'),
            ),
          ],
        ),
      );
    } else {
      await showDialog<void>(
        context: context,
        builder: (_) => AuthDialog(store: store),
      );
    }
    if (mounted) setState(() {});
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color, size: 21),
      const SizedBox(width: 4),
      Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
      ),
    ],
  );
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String title, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Panel(
    padding: const EdgeInsets.all(18),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 23),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 9,
                  letterSpacing: .8,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.store,
    required this.onTap,
  });
  final DailyLesson lesson;
  final AppStore store;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (lesson.subject) {
      'math' => (teal, Icons.calculate_rounded, 'MATEMATIKA'),
      'slovak' => (violet, Icons.menu_book_rounded, 'SLOVENČINA'),
      _ => (const Color(0xffcb8524), Icons.public_rounded, 'GEOGRAFIA'),
    };
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              const Spacer(),
              if (store.completed(lesson.id))
                const Icon(Icons.check_circle_rounded, color: teal)
              else
                const Text(
                  '4 otázky',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 58,
            child: Text(
              lesson.title,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            store.completed(lesson.id)
                ? 'Najlepší výsledok: ${store.best(lesson.id)} %'
                : 'Objavuj, premýšľaj, vyskúšaj.',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 22),
          GameButton(
            label: store.completed(lesson.id)
                ? 'Precvičiť znova'
                : 'Začať oblasť',
            icon: Icons.arrow_forward_rounded,
            color: color,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

class _GradeSwitch extends StatelessWidget {
  const _GradeSwitch({required this.store});
  final AppStore store;
  @override
  Widget build(BuildContext context) => SegmentedButton<int>(
    segments: const [
      ButtonSegment(value: 8, label: Text('8. ročník')),
      ButtonSegment(value: 9, label: Text('9. ročník')),
    ],
    selected: {store.grade},
    onSelectionChanged: (v) => store.setting('grade', v.first),
  );
}

class _Notice extends StatelessWidget {
  const _Notice(this.text, {this.action});
  final String text;
  final VoidCallback? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Panel(
      color: amber.withValues(alpha: .1),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text),
          if (action != null)
            TextButton(onPressed: action, child: const Text('Skúsiť znova')),
        ],
      ),
    ),
  );
}

class SettingsPanel extends StatefulWidget {
  const SettingsPanel({super.key, required this.store, required this.onAuth});
  final AppStore store;
  final VoidCallback onAuth;
  @override
  State<SettingsPanel> createState() => _SettingsPanelState();
}

class _SettingsPanelState extends State<SettingsPanel> {
  late final name = TextEditingController(text: widget.store.profile.username);
  late bool visible = widget.store.profile.visible;
  bool saving = false;
  String? message;
  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.store;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nastav si vlastné tempo',
          style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        const Text('Tvoje učenie, tvoje pravidlá.'),
        const SizedBox(height: 24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Učenie a vzhľad',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              const Text('Ročník'),
              const SizedBox(height: 8),
              _GradeSwitch(store: s),
              const SizedBox(height: 20),
              DropdownButtonFormField<int>(
                initialValue: s.theme.index,
                decoration: const InputDecoration(labelText: 'Farebný režim'),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Podľa zariadenia')),
                  DropdownMenuItem(value: 1, child: Text('Svetlý')),
                  DropdownMenuItem(value: 2, child: Text('Tmavý')),
                ],
                onChanged: (v) {
                  if (v != null) s.setting('theme', v);
                },
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<int>(
                initialValue: s.dailyGoal,
                decoration: const InputDecoration(labelText: 'Denný cieľ'),
                items: [4, 8, 12]
                    .map(
                      (v) =>
                          DropdownMenuItem(value: v, child: Text('$v otázok')),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) s.setting('goal', v);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Obmedziť animácie'),
                subtitle: const Text(
                  'Pokojnejšie prechody a okamžité počítadlá.',
                ),
                value: s.reducedMotion,
                onChanged: (v) => s.setting('reduced_motion', v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hmatová odozva'),
                subtitle: const Text(
                  'Jemné vibrácie na podporovaných zariadeniach.',
                ),
                value: s.haptics,
                onChanged: (v) => s.setting('haptics', v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Profil a súkromie',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: name,
                maxLength: 24,
                decoration: const InputDecoration(
                  labelText: 'Prezývka',
                  helperText: '3 až 24 znakov. Nepoužívaj celé meno.',
                ),
              ),
              if (s.signedIn)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Zobraziť ma v rebríčku'),
                  subtitle: const Text(
                    'Verejne sa zobrazí iba prezývka a počet XP.',
                  ),
                  value: visible,
                  onChanged: (v) => setState(() => visible = v),
                ),
              const SizedBox(height: 16),
              GameButton(
                label: saving ? 'Ukladám…' : 'Uložiť profil',
                onPressed: saving
                    ? null
                    : () async {
                        setState(() {
                          saving = true;
                          message = null;
                        });
                        try {
                          await s.updateProfile(name.text, visible);
                          if (mounted) {
                            setState(() => message = 'Profil uložený.');
                          }
                        } catch (_) {
                          if (mounted) {
                            setState(
                              () => message =
                                  'Profil sa nepodarilo uložiť. Prezývka musí mať 3 až 24 znakov; skontroluj aj pripojenie.',
                            );
                          }
                        } finally {
                          if (mounted) setState(() => saving = false);
                        }
                      },
              ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(message!),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: widget.onAuth,
                child: Text(
                  s.signedIn
                      ? 'Spravovať prihlásenie'
                      : 'Prihlásiť sa a synchronizovať pokrok',
                ),
              ),
              const Text(
                'Bez účtu sa pokrok ukladá iba v tomto prehliadači alebo zariadení. Lokálne výsledky sa nepripisujú do rebríčka účtu.',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'O aplikácii a učive',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              const Text(
                'Vedomax - Vedomosti na Maximum pre všetky deti',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              const Text(
                '14 dní · 3 oblasti · 4 otázky denne v každej oblasti · samostatný obsah pre 8. a 9. ročník. Spolu 336 otázok.',
                style: TextStyle(height: 1.5),
              ),
              const SizedBox(height: 10),
              const Text(
                'Autorské precvičovanie vychádza z iŠVP a predmetových štandardov MŠVVaM SR pre 2. stupeň ZŠ. Rozvrhnutie učiva sa môže líšiť podľa školského programu. Nejde o ministerskú certifikáciu.',
                style: TextStyle(fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 12),
              const SelectableText(
                'Štandardy: https://www.minedu.sk/vzdelavacie-standardy-pre-2-stupen-zs/\nMapové podklady: Natural Earth (public domain). Súradnice: GeoNames (CC BY 4.0).',
                style: TextStyle(fontSize: 11, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AuthDialog extends StatefulWidget {
  const AuthDialog({super.key, required this.store});
  final AppStore store;
  @override
  State<AuthDialog> createState() => _AuthDialogState();
}

class _AuthDialogState extends State<AuthDialog> {
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false, register = false;
  String? message;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit({bool resend = false}) async {
    final clean = email.text.trim().toLowerCase();
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(clean) ||
        (!resend &&
            (password.text.isEmpty ||
                (register && password.text.length < 8)))) {
      setState(
        () => message =
            'Zadaj platný e-mail${resend
                ? ''
                : register
                ? ' a heslo s aspoň 8 znakmi'
                : ' a heslo'}.',
      );
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final auth = widget.store.client!.auth;
      if (resend) {
        await auth.resend(type: OtpType.signup, email: clean);
        if (mounted) {
          setState(
            () => message =
                'Ak účet čaká na potvrdenie, požiadavka na e-mail bola prijatá. Skontroluj aj spam.',
          );
        }
      } else if (register) {
        final res = await auth.signUp(email: clean, password: password.text);
        if (res.session == null) {
          if (mounted) {
            setState(
              () => message =
                  'Registráciu dokončíš potvrdením e-mailu. Potom sa prihlás.',
            );
          }
        } else {
          await widget.store.refreshProfile();
          if (mounted) Navigator.pop(context);
        }
      } else {
        await auth.signInWithPassword(email: clean, password: password.text);
        await widget.store.refreshProfile();
        if (mounted) Navigator.pop(context);
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(
          () => message = e.code == 'email_not_confirmed'
              ? 'Najprv potvrď e-mail. Potvrdzovací e-mail môžeš poslať znova.'
              : e.code == 'invalid_credentials'
              ? 'Nesprávny e-mail alebo heslo.'
              : 'Požiadavka sa nepodarila. Skontroluj údaje, pripojenie a skús to neskôr.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => message = 'Pripojenie sa nepodarilo. Skús znova.');
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(
      widget.store.client == null
          ? 'Učenie bez účtu'
          : register
          ? 'Vytvor si účet'
          : 'Vitaj späť',
    ),
    content: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.store.client == null)
              const Text(
                'Prihlásenie cez Supabase zatiaľ nie je nakonfigurované. Všetkých 336 otázok môžeš používať bez účtu; pokrok ostane v tomto zariadení.',
              )
            else ...[
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'E-mail'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: password,
                obscureText: true,
                autofillHints: [
                  register ? AutofillHints.newPassword : AutofillHints.password,
                ],
                decoration: const InputDecoration(labelText: 'Heslo'),
                onSubmitted: (_) {
                  if (!busy) submit();
                },
              ),
              if (message != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Semantics(liveRegion: true, child: Text(message!)),
                ),
              const SizedBox(height: 18),
              GameButton(
                label: busy
                    ? 'Počkaj…'
                    : register
                    ? 'Vytvoriť účet'
                    : 'Prihlásiť sa',
                onPressed: busy ? null : submit,
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () => setState(() {
                        register = !register;
                        message = null;
                      }),
                child: Text(register ? 'Už mám účet' : 'Vytvoriť nový účet'),
              ),
              TextButton(
                onPressed: busy ? null : () => submit(resend: true),
                child: const Text('Poslať potvrdzovací e-mail znova'),
              ),
              const Text(
                'Registráciu a ochranu osobných údajov preber so zákonným zástupcom. Používaj prezývku.',
                style: TextStyle(fontSize: 11),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: busy ? null : () => Navigator.pop(context),
        child: const Text('Späť k učeniu'),
      ),
    ],
  );
}
