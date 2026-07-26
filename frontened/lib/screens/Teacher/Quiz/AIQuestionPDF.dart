// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:open_file/open_file.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:shimmer/shimmer.dart';

// import '../../../Provider/quiz_provider.dart';
// import '../../../main.dart';
// import '../../../models/Quiz/quiz_model.dart';

// class AIQuestionPDF extends StatefulWidget {
//   final List<Quiz> quiz;

//   const AIQuestionPDF({
//     super.key,
//     required this.quiz,
//   });

//   @override
//   State<AIQuestionPDF> createState() =>
//       _AIQuestionPDFState();
// }

// class _AIQuestionPDFState
//     extends State<AIQuestionPDF> {

//   bool _isDownloading = false;
//   int? _loadingQuizIndex;

//   bool _isLoading = true;

//   @override
// void initState() {
//   super.initState();

//   Future.delayed(
//     const Duration(seconds: 2),
//     () {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     },
//   );
// }


//   // ================= PDF GENERATION =================
//   Future<void> _generateAndOpenPdf(
//     Quiz quiz,
//     int index,
//   ) async {
//     try {
//       setState(() {
//      _isDownloading = true;
//      _loadingQuizIndex = index;
//     });

//       final provider =
//           Provider.of<QuizProvider>(
//         context,
//         listen: false,
//       );

//       // =========================================
//       // GENERATE AI QUESTION PDF
//       // =========================================
//       final pdfUrl =
//           await provider.generateAIQuestionQuizPdf(
//         quizId: quiz.id,
//       );

//       if (pdfUrl == null) {
//         _showMessage(
//           "Failed to generate PDF",
//         );
//         return;
//       }

//       // =========================================
//       // DOWNLOAD PDF
//       // =========================================
//       final response = await http.get(
//         Uri.parse(pdfUrl),
//       );

//       if (response.statusCode != 200) {
//         _showMessage(
//           "Failed to download PDF",
//         );
//         return;
//       }

//       final dir =
//           await getTemporaryDirectory();

//       final filePath =
//           "${dir.path}/${quiz.title}.pdf";

//       final file = File(filePath);

//       await file.writeAsBytes(
//         response.bodyBytes,
//       );

//       // =========================================
//       // OPEN PDF
//       // =========================================
//       await OpenFile.open(file.path);

//       _showMessage(
//         "PDF opened successfully",
//       );
//     } catch (e) {
//       _showMessage(e.toString());
//     } finally {
//       setState(() {
//         _isDownloading = false;
//         _loadingQuizIndex = null;
//       });
//     }
//   }

//   // ================= SNACKBAR =================
//   void _showMessage(String message) {
//     ScaffoldMessenger.of(context)
//         .showSnackBar(
//       SnackBar(
//         content: Text(message),
//        backgroundColor: Colors.green,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//       ),
//     );
//   }

//   // ================= SORT =================
//   List<Quiz> get sortedQuizzes {
//     final list = [...widget.quiz];

//     list.sort((a, b) {
//       final aDate =
//           a.createdAt ?? DateTime(2000);

//       final bDate =
//           b.createdAt ?? DateTime(2000);

//       return bDate.compareTo(aDate);
//     });

//     return list;
//   }

//   // ================= QUIZ CARD =================
//   Widget _quizCard(
//     Quiz quiz,
//     int index,
//   ) {
//     return Container(
//       margin:
//           const EdgeInsets.only(bottom: 14),

//       padding: const EdgeInsets.all(14),

//       decoration: BoxDecoration(
//         color: Colors.white,

//         borderRadius:
//             BorderRadius.circular(16),

//         boxShadow: const [
//           BoxShadow(
//             color: Color(0x11000000),
//             blurRadius: 10,
//             offset: Offset(0, 5),
//           )
//         ],
//       ),

//       child: Column(
//         crossAxisAlignment:
//             CrossAxisAlignment.start,

//         children: [

//           // ================= HEADER =================
//           Row(
//             children: [
//               Container(
//                 height: 44,
//                 width: 44,

//                 decoration: BoxDecoration(
//                   color: AppColors.primary
//                       .withOpacity(0.1),

//                   borderRadius:
//                       BorderRadius.circular(
//                     12,
//                   ),
//                 ),

//                 child: const Icon(
//                   Icons.picture_as_pdf,
//                   color: AppColors.primary,
//                 ),
//               ),

//               const SizedBox(width: 10),

//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment
//                           .start,

//                   children: [
//                     Text(
//                       quiz.title,

//                       style:
//                           const TextStyle(
//                         fontWeight:
//                             FontWeight.w600,

//                         fontSize: 15,
//                       ),
//                     ),

//                     const SizedBox(height: 3),

//                     Text(
//   quiz.shortQuestions.isNotEmpty && quiz.longQuestions.isNotEmpty
//       ? "QUESTION (SHORT + LONG) • ${quiz.totalMarks} Marks"
//       : quiz.shortQuestions.isNotEmpty
//           ? "QUESTION (SHORT) • ${quiz.totalMarks} Marks"
//           : "QUESTION (LONG) • ${quiz.totalMarks} Marks",
//   style: const TextStyle(
//     fontSize: 12,
//     color: Colors.grey,
//   ),
// ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 12),

//           // ================= ACTION =================
//           Row(
//             children: [
//               Expanded(
//                 child:
//                     OutlinedButton.icon(
//                   onPressed:
//                       _isDownloading
//                           ? null
//                           : () =>
//                               _generateAndOpenPdf(
//                                 quiz,
//                                 index,
//                               ),

//                   icon:
//                       _loadingQuizIndex ==
//                               index
//                           ? const SizedBox(
//                               height: 16,
//                               width: 16,

//                               child:
//                                   CircularProgressIndicator(
//                                 strokeWidth: 2,
//                               ),
//                             )
//                           : const Icon(
//                               Icons
//                                   .picture_as_pdf,
//                               size: 18,
//                             ),

//                   label: const Text(
//                     "Open PDF",
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }

//   // ================= UI =================
//   @override
//   Widget build(BuildContext context) {
//     final quizzes = sortedQuizzes;

//     return Scaffold(
//       body: Column(
//         children: [

//           // ================= HEADER =================
//           Container(
//             width: double.infinity,

//             padding:
//                 const EdgeInsets.only(
//               top: 50,
//               left: 20,
//               right: 20,
//               bottom: 20,
//             ),

//             decoration:
//                 const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [
//                   AppColors.primary,
//                   AppColors.secondary,
//                 ],
//               ),

//               borderRadius:
//                   BorderRadius.vertical(
//                 bottom:
//                     Radius.circular(28),
//               ),
//             ),

//             child: Column(
//               crossAxisAlignment:
//                   CrossAxisAlignment.start,

//               children: [
//                 Row(
//                   children: [
//                     GestureDetector(
//                       onTap: () =>
//                           Navigator.pop(
//                             context,
//                           ),

//                       child: const Icon(
//                         Icons.arrow_back_ios,
//                         color:
//                             Colors.white,
//                         size: 20,
//                       ),
//                     ),

//                     const SizedBox(
//                         width: 10),

//                     const Expanded(
//                       child: Text(
//                         "AI Question PDFs",

//                         textAlign:
//                             TextAlign.center,

//                         style: TextStyle(
//                           color:
//                               Colors.white,

//                           fontSize: 20,

//                           fontWeight:
//                               FontWeight
//                                   .w700,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 10),

//                 const Text(
//                   "All AI Generated Question PDFs",

//                   style: TextStyle(
//                     color:
//                         Colors.white70,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           const SizedBox(height: 10),

//           // ================= LIST =================
//           Expanded(
//      child: _isLoading
//       ? ListView.builder(
//           padding: const EdgeInsets.all(16),
//           itemCount: 6,
//           itemBuilder: (context, index) {
//             return _shimmerCard();
//           },
//         )
//       : ListView.builder(
//           padding: const EdgeInsets.all(16),

//           itemCount: quizzes.length,

//           itemBuilder: (context, index) {
//             return _quizCard(
//               quizzes[index],
//               index,
//             );
//           },
//         ),
// ),
//         ],
//       ),
//     );
//   }
  
//   Widget _shimmerCard() {
//   return Shimmer.fromColors(
//     baseColor: Colors.grey.shade300,
//     highlightColor: Colors.grey.shade100,

//     child: Container(
//       margin: const EdgeInsets.only(
//         bottom: 14,
//       ),

//       padding: const EdgeInsets.all(14),

//       decoration: BoxDecoration(
//         color: Colors.white,

//         borderRadius:
//             BorderRadius.circular(16),
//       ),

//       child: Column(
//         children: [

//           Row(
//             children: [

//               Container(
//                 height: 44,
//                 width: 44,

//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius:
//                       BorderRadius.circular(
//                     12,
//                   ),
//                 ),
//               ),

//               const SizedBox(width: 10),

//               Expanded(
//                 child: Column(
//                   crossAxisAlignment:
//                       CrossAxisAlignment
//                           .start,

//                   children: [

//                     Container(
//                       height: 14,
//                       width: double.infinity,
//                       color: Colors.white,
//                     ),

//                     const SizedBox(height: 8),

//                     Container(
//                       height: 12,
//                       width: 120,
//                       color: Colors.white,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),

//           const SizedBox(height: 16),

//           Container(
//             height: 42,
//             width: double.infinity,
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius:
//                   BorderRadius.circular(10),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );
// }
// }