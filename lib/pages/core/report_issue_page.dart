import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart'; // ⭐ UI: Added for animations
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:c_h_p/app/providers.dart';

//==============================================================================
// Page for Users to SUBMIT an Issue
//==============================================================================

class ReportIssuePage extends ConsumerStatefulWidget {
  const ReportIssuePage({super.key});

  @override
  ConsumerState<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends ConsumerState<ReportIssuePage> {
  final _formKey = GlobalKey<FormState>();
  final _issueController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(reportVMProvider.notifier)
          .submitIssue(_issueController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Thank you! Your report has been submitted.'),
            backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("Report an Issue",
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: IconThemeData(color: Colors.grey.shade800),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("We're here to help!",
                  style: GoogleFonts.poppins(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                  "You are reporting as: ${_currentUser?.displayName ?? _currentUser?.email}",
                  style: GoogleFonts.poppins(color: Colors.grey.shade600)),
              const SizedBox(height: 32),
              TextFormField(
                controller: _issueController,
                decoration: const InputDecoration(
                    labelText: "Describe the issue",
                    alignLabelWithHint: true,
                    prefixIcon: Icon(Iconsax.message_text)),
                maxLines: 5,
                validator: (value) =>
                    value!.isEmpty ? 'Please describe the issue' : null,
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Colors.deepOrange))
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text('Submit Report',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 16)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

//==============================================================================
// Page for Admins to VIEW all Issues
//==============================================================================

class ViewReportsPage extends ConsumerStatefulWidget {
  const ViewReportsPage({super.key});

  @override
  ConsumerState<ViewReportsPage> createState() => _ViewReportsPageState();
}

class _ViewReportsPageState extends ConsumerState<ViewReportsPage> {
  // ⭐ FIX: Restored the specific issue text to the notification
  Future<void> _resolveReport(
      String reportKey, String userId, String issueText) async {
    try {
      await ref
          .read(reportVMProvider.notifier)
          .resolve(reportKey: reportKey, userId: userId, issueText: issueText);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Report resolved and notification sent.'),
            backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Operation failed: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("User Reports",
            style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: Colors.red.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<MapEntry<String, Map<String, dynamic>>>>(
        stream: ref.read(reportVMProvider.notifier).reportsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reportsList = snapshot.data ?? const [];
          if (reportsList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.document_text,
                      size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text("No reports have been submitted yet.",
                      style: GoogleFonts.poppins()),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            cacheExtent: 800,
            itemCount: reportsList.length,
            itemBuilder: (context, index) {
              final reportKey = reportsList[index].key;
              final reportData = reportsList[index].value;
              final ts = reportData['timestamp'];
              final timestamp =
                  ts is int ? DateTime.fromMillisecondsSinceEpoch(ts) : null;
              final formattedDate = timestamp != null
                  ? DateFormat('MMM d, yyyy - h:mm a').format(timestamp)
                  : 'N/A';
              final status = reportData['status'] ?? 'Pending';
              final userId = reportData['userId'];
              final issueText = reportData['issue'] ?? 'No issue description.';

              return RepaintBoundary(
                      child: Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.05),
                child: ListTile(
                  leading: CircleAvatar(
                      backgroundColor: Colors.red.shade50,
                      child: Icon(Iconsax.message_question,
                          color: Colors.red.shade700)),
                  isThreeLine: true,
                  title: Text(reportData['name'] ?? 'No Name',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '$issueText\nReported on: $formattedDate',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: status == 'Pending'
                      ? IconButton(
                          icon: Icon(Iconsax.tick_circle,
                              color: Colors.blue.shade600, size: 28),
                          tooltip: 'Mark as Resolved',
                          onPressed: () {
                            if (userId != null) {
                              _resolveReport(reportKey, userId, issueText);
                            }
                          },
                        )
                      : Icon(Iconsax.tick_circle,
                          color: Colors.green.shade600, size: 28),
                ),
              ))
                  .animate()
                  .fade(duration: 500.ms, delay: (100 * index).ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut);
            },
          );
        },
      ),
    );
  }
}
