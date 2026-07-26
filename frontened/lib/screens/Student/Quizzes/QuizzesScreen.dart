import "dart:async";
import "dart:io";
import "package:flutter/material.dart";
import "package:frontened/Provider/quiz_provider.dart";
import "package:open_file/open_file.dart";
import "package:path_provider/path_provider.dart";
import "package:provider/provider.dart";
import "package:intl/intl.dart";

class AppColors {
  static const Color primary = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF7C3AED);
}

class QuizzesScreen extends StatefulWidget {
  const QuizzesScreen({super.key});
  static const String routeName = "/quizzes";
  @override
  State<QuizzesScreen> createState() => _QuizzesScreenState();
}

class _QuizzesScreenState extends State<QuizzesScreen> {
  final bool _isDownloading = false;
  int? _loadingQuizIndex;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    Future.microtask(() { context.read<QuizProvider>().fetchAllQuizzes(); });

    // 🔥 REAL-TIME TICKER: Keep countdown and live lock check perfectly updated
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async { await context.read<QuizProvider>().fetchAllQuizzes(); }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppColors.primary,
        behavior: SnackBarBehavior.floating
    ));
  }

  List _sortByCreatedAt(List quizzes) {
    quizzes.sort((a, b) {
      final DateTime aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final DateTime bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return quizzes;
  }

  bool _isCompletedSafe(dynamic quiz) => quiz.isCompleted == true;

  DateTime? _getSafeDate(dynamic rawDate) {
    if (rawDate == null) return null;
    if (rawDate is DateTime) return rawDate;
    return DateTime.tryParse(rawDate.toString());
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "00:00:00";
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String days = d.inDays > 0 ? "${d.inDays}d " : "";
    String hours = twoDigits(d.inHours.remainder(24));
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$days$hours:$minutes:$seconds";
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<QuizProvider>();
    final quizzes = provider.quizzes;
    final now = DateTime.now();

    // 🔥 FILTERING ENGINE: Separate active/upcoming from completed/expired
    final upcoming = quizzes.where((q) {
      if (_isCompletedSafe(q) || q.evaluatedByAI == true) return false;
      return true; // Keep all scheduled/active quizzes in this list to show their locks/expired state
    }).toList();

    final attempted = quizzes.where((q) => _isCompletedSafe(q) || q.evaluatedByAI == true).toList();
    _sortByCreatedAt(upcoming);
    _sortByCreatedAt(attempted);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 180.0, pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text("Quizzes", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                background: Container(
                  decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary])),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 20, bottom: 60),
                    child: Column(mainAxisAlignment: MainAxisAlignment.end, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text("Dashboard", style: TextStyle(color: Colors.white70, fontSize: 14)),
                      Text("Learning Journey", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("Scheduled & Active Exams", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                  const SizedBox(height: 12),
                  if (upcoming.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                      child: const Center(child: Text("No scheduled or active exams.", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
                    )
                  else
                    ...upcoming.map((q) {
                      final openDate = _getSafeDate(q.openDateTime);
                      final deadline = _getSafeDate(q.deadlineDateTime);

                      // 🔥 STRICT TIME ENGINE EVALUATION
                      final bool isNotStartedYet = openDate != null && now.isBefore(openDate);
                      final bool isClosedAlready = deadline != null && now.isAfter(deadline);
                      final bool isWorkingActive = !isNotStartedYet && !isClosedAlready;

                      Color statusColor = Colors.green;
                      String statusText = "ACTIVE";
                      IconData statusIcon = Icons.play_circle_filled;
                      Color cardBg = Colors.white;

                      if (isNotStartedYet) {
                        statusColor = Colors.orange;
                        statusText = "LOCKED";
                        statusIcon = Icons.lock;
                        cardBg = const Color(0xFFFAFAFA);
                      } else if (isClosedAlready) {
                        statusColor = Colors.redAccent;
                        statusText = "CLOSED";
                        statusIcon = Icons.block;
                        cardBg = const Color(0xFFF5F5F5);
                      }

                      return InkWell(
                        onTap: () {
                          // 🔥 FULL ENTIRE QUIZ CARD CLICK BLOCK INJECTION
                          if (isNotStartedYet) {
                            _showMessage("This examination has not started yet! Unlocks at ${DateFormat('hh:mm a, dd MMM').format(openDate)}", isError: true);
                          } else if (isClosedAlready) {
                            _showMessage("This examination is closed! Deadline passed.", isError: true);
                          } else {
                            Navigator.pushNamed(context, '/quiz-attempt', arguments: q);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4))
                              ],
                              border: Border.all(
                                  color: isWorkingActive ? AppColors.primary.withValues(alpha: 0.3) : Colors.grey.shade300,
                                  width: isWorkingActive ? 1.5 : 1.0
                              )
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Top Header Badge layout inside card context
                              Row(
// 💡 FIX CODE: Isay change kar lein
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,                              children: [
                                  Row(
                                    children: [
                                      Icon(statusIcon, color: statusColor, size: 18),
                                      const SizedBox(width: 6),
                                      Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5)),
                                    ],
                                  ),
                                  if (isWorkingActive && deadline != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(6)),
                                      child: Text(
                                        "Ends in: ${_formatDuration(deadline.difference(now))}",
                                        style: const TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                  q.title ?? "Untitled Assessment Paper",
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isClosedAlready ? Colors.grey : const Color(0xFF1E1B4B)
                                  )
                              ),
                              const SizedBox(height: 14),
                              const Divider(height: 1, color: Color(0xFFE2E8F0)),
                              const SizedBox(height: 12),

                              // 🔥 METADATA GRID FOR TIME AND DATE RENDERING
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.date_range, size: 12, color: Colors.grey),
                                            SizedBox(width: 4),
                                            Text("START TIME", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          openDate != null ? DateFormat('hh:mm a, dd MMM').format(openDate) : "Immediate Start",
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                                        )
                                      ],
                                    ),
                                  ),
                                  Container(width: 1, height: 25, color: Colors.grey.shade200),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.gpp_maybe, size: 12, color: Colors.grey),
                                            SizedBox(width: 4),
                                            Text("DEADLINE TIME", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          deadline != null ? DateFormat('hh:mm a, dd MMM').format(deadline) : "No Deadline Set",
                                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isClosedAlready ? Colors.red.shade400 : const Color(0xFF475569)),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 30),
                  const Text("Attempted Quizzes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E1B4B))),
                  const SizedBox(height: 10),
                  if (attempted.isEmpty)
                    const Text("No attempted quizzes.", style: TextStyle(color: Colors.grey))
                  else
                    ...attempted.map((q) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
                      child: ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(q.title ?? "Untitled", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Score: ${q.score ?? 0}", style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.pushNamed(context, '/quiz-result', arguments: q),
                      ),
                    )),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}