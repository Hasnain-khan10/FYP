import 'package:flutter/material.dart';
import 'package:frontened/main.dart';


class TeacherAIPlanLoadingScreen extends StatefulWidget {
  const TeacherAIPlanLoadingScreen({super.key});

  @override
  State<TeacherAIPlanLoadingScreen> createState() =>
      _TeacherAIPlanLoadingScreenState();
}

class _TeacherAIPlanLoadingScreenState extends State<TeacherAIPlanLoadingScreen> {

  double progress = 0;

  @override
  void initState() {
    super.initState();
    _startLoading();
  }

  void _startLoading() async {
    for (int i = 1; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 30));
      setState(() {
        progress = i / 100;
      });
    }

    /// After complete → go back to Course Main
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.3),

      body: Center(
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                color: Color(0x20000000),
                blurRadius: 20,
                offset: Offset(0, 10),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [

              /// AI ICON
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(height: 16),

              /// TITLE
              const Text(
                "Generating AI Plan...",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 14),

              /// PROGRESS BAR
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor:
                  AppColors.primary.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation(
                      AppColors.primary),
                ),
              ),

              const SizedBox(height: 10),

              /// PERCENTAGE TEXT
              Text(
                "${(progress * 100).toInt()}%",
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:open_file/open_file.dart';
// import 'package:parent_teacher_meeting/Provider/week_plan_provider.dart';
// import 'package:parent_teacher_meeting/main.dart';
// import 'package:parent_teacher_meeting/services/week_plan_service.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:provider/provider.dart';

// class TeacherCourseMainScreen extends StatefulWidget {
//   static const String courseMain = '/course-main';
//   final String courseId;

//   const TeacherCourseMainScreen({super.key, required this.courseId});

//   @override
//   State<TeacherCourseMainScreen> createState() =>
//       _TeacherCourseMainScreenState();
// }

// class _TeacherCourseMainScreenState extends State<TeacherCourseMainScreen> {
//   bool _loadingFullPdf = false;

//   final TextEditingController _aiPromptController =
//       TextEditingController();

//   /// ===============================
//   /// FULL AI PDF
//   /// ===============================
//   Future<void> _openAIPlanPDF() async {
//     try {
//       setState(() => _loadingFullPdf = true);

//       final bytes =
//           await WeekPlanService.downloadAIPlanPDF(widget.courseId);

//       final dir = await getTemporaryDirectory();

//       final file = File(
//         "${dir.path}/AI_18_Week_Plan_${widget.courseId}.pdf",
//       );

//       await file.writeAsBytes(bytes);

//       await OpenFile.open(file.path);
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: ${e.toString()}")),
//       );
//     } finally {
//       setState(() => _loadingFullPdf = false);
//     }
//   }

//   /// ===============================
//   /// WEEK PDF
//   /// ===============================
//   Future<void> _openWeekPDF(int weekNumber) async {
//     await context
//         .read<WeekPlanProvider>()
//         .downloadAndOpenWeekPDF(widget.courseId, weekNumber);
//   }

//   /// ===============================
//   /// 🧠 AI UPDATE WEEK BOTTOM SHEET
//   /// ===============================
//   void _showAIUpdateSheet(int weekNumber) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       builder: (_) {
//         return Padding(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//             top: 20,
//             left: 20,
//             right: 20,
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Text(
//                 "Improve Week with AI",
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),

//               const SizedBox(height: 10),

//               TextField(
//                 controller: _aiPromptController,
//                 maxLines: 3,
//                 decoration: const InputDecoration(
//                   hintText: "e.g. make it more practical, add coding examples",
//                   border: OutlineInputBorder(),
//                 ),
//               ),

//               const SizedBox(height: 12),

//               ElevatedButton(
//                 onPressed: () async {
//                   Navigator.pop(context);

//                   await context.read<WeekPlanProvider>().updateWeekAI(
//                         widget.courseId,
//                         weekNumber,
//                         prompt: _aiPromptController.text,
//                       );

//                   _aiPromptController.clear();
//                 },
//                 child: const Text("Generate AI Update"),
//               ),

//               const SizedBox(height: 10),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   /// ===============================
//   /// 🗑️ DELETE WEEK
//   /// ===============================
//   Future<void> _deleteWeek(int weekNumber) async {
//     final confirm = await showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Delete Week"),
//         content: const Text("Are you sure you want to delete this week?"),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context, false),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.pop(context, true),
//             child: const Text("Delete"),
//           ),
//         ],
//       ),
//     );

//     if (confirm == true) {
//       await context
//           .read<WeekPlanProvider>()
//           .deleteWeek(widget.courseId, weekNumber);
//     }
//   }

//   @override
//   void initState() {
//     super.initState();

//     Future.microtask(() {
//       context.read<WeekPlanProvider>().fetchPlan(widget.courseId);
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     final provider = context.watch<WeekPlanProvider>();
//     final plan = provider.plan;
//     final weeks = plan?.weeks ?? [];

//     return Scaffold(
//       body: Column(
//         children: [
//           /// ================= HEADER =================
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.only(
//                 top: 50, left: 20, right: 20, bottom: 20),
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [AppColors.primary, AppColors.secondary],
//               ),
//               borderRadius: BorderRadius.vertical(
//                 bottom: Radius.circular(28),
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     GestureDetector(
//                       onTap: () => Navigator.pop(context),
//                       child: const Icon(Icons.arrow_back_ios,
//                           color: Colors.white, size: 20),
//                     ),
//                     const SizedBox(width: 10),
//                     const Expanded(
//                       child: Text(
//                         "AI Course Plan",
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 20,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 20),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//                 Text(
//                   plan?.title ?? "Loading Course...",
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 22,
//                     fontWeight: FontWeight.w700,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 16),

//           /// ================= BODY =================
//           Expanded(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Column(
//                 children: [
//                   /// FULL PDF
//                   GestureDetector(
//                     onTap: _loadingFullPdf ? null : _openAIPlanPDF,
//                     child: Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         gradient: const LinearGradient(
//                           colors: [AppColors.primary, AppColors.secondary],
//                         ),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Row(
//                         children: [
//                           const Icon(Icons.picture_as_pdf,
//                               color: Colors.white),
//                           const SizedBox(width: 10),
//                           const Expanded(
//                             child: Text(
//                               "Full AI 18-Week Plan",
//                               style: TextStyle(color: Colors.white),
//                             ),
//                           ),
//                           if (_loadingFullPdf)
//                             const SizedBox(
//                               height: 18,
//                               width: 18,
//                               child: CircularProgressIndicator(
//                                 color: Colors.white,
//                                 strokeWidth: 2,
//                               ),
//                             )
//                         ],
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 20),

//                   const Align(
//                     alignment: Alignment.centerLeft,
//                     child: Text(
//                       "Week-by-Week",
//                       style:
//                           TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                   ),

//                   const SizedBox(height: 10),

//                   Expanded(
//                     child: provider.isLoading
//                         ? const Center(child: CircularProgressIndicator())
//                         : ListView.builder(
//                             itemCount: weeks.length,
//                             itemBuilder: (context, index) {
//                               final week = weeks[index];
//                               final loading =
//                                   provider.isWeekActionLoading(
//                                       week.weekNumber);

//                               return GestureDetector(
//                                 onLongPress: () =>
//                                     _deleteWeek(week.weekNumber),

//                                 child: Container(
//                                   margin:
//                                       const EdgeInsets.only(bottom: 12),
//                                   padding: const EdgeInsets.all(14),
//                                   decoration: BoxDecoration(
//                                     color: Colors.white,
//                                     borderRadius:
//                                         BorderRadius.circular(16),
//                                     boxShadow: const [
//                                       BoxShadow(
//                                         blurRadius: 10,
//                                         color: Color(0x12000000),
//                                       )
//                                     ],
//                                   ),
//                                   child: Row(
//                                     children: [
//                                       const Icon(Icons.auto_awesome),

//                                       const SizedBox(width: 10),

//                                       Expanded(
//                                         child: Column(
//                                           crossAxisAlignment:
//                                               CrossAxisAlignment.start,
//                                           children: [
//                                             Text(
//                                               "Week ${week.weekNumber}",
//                                               style: const TextStyle(
//                                                   fontWeight:
//                                                       FontWeight.bold),
//                                             ),
//                                             Text(
//                                               week.title,
//                                               style: const TextStyle(
//                                                   fontSize: 12),
//                                             ),
//                                           ],
//                                         ),
//                                       ),

//                                       if (loading)
//                                         const SizedBox(
//                                           height: 18,
//                                           width: 18,
//                                           child:
//                                               CircularProgressIndicator(
//                                             strokeWidth: 2,
//                                           ),
//                                         )
//                                       else
//                                         Row(
//                                           children: [
//                                             IconButton(
//                                               icon: const Icon(
//                                                   Icons.picture_as_pdf),
//                                               onPressed: () =>
//                                                   _openWeekPDF(
//                                                       week.weekNumber),
//                                             ),
//                                             IconButton(
//                                               icon: const Icon(
//                                                   Icons.auto_fix_high),
//                                               onPressed: () =>
//                                                   _showAIUpdateSheet(
//                                                       week.weekNumber),
//                                             ),
//                                           ],
//                                         )
//                                     ],
//                                   ),
//                                 ),
//                               );
//                             },
//                           ),
//                   )
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }