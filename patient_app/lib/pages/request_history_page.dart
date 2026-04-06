import 'package:flutter/material.dart';
import '../widgets/patient_app_bar.dart';
import '../widgets/patient_section_card.dart';
import '../services/request_history_service.dart';

class RequestHistoryPage extends StatefulWidget {
  const RequestHistoryPage({super.key});

  @override
  State<RequestHistoryPage> createState() => _RequestHistoryPageState();
}

class _RequestHistoryPageState extends State<RequestHistoryPage> {
  final RequestHistoryService _historyService = RequestHistoryService();
  late Future<List<PatientRequestHistoryItem>> _requestsFuture;

  @override
  void initState() {
    super.initState();
    _requestsFuture = _historyService.fetchPatientRequests();
  }

  Future<void> _refreshRequests() async {
    setState(() {
      _requestsFuture = _historyService.fetchPatientRequests();
    });
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date not available';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    int hour = date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;
    if (hour == 0) hour = 12;

    return '$day/$month/$year • $hour:$minute $period';
  }

  Color _statusBackgroundColor(String status) {
    final normalized = status.toLowerCase();

    if (normalized == 'completed') {
      return const Color(0xffecfdf3);
    }

    if (normalized == 'accepted' ||
        normalized == 'dispatched' ||
        normalized == 'in progress') {
      return const Color(0xffeff6ff);
    }

    if (normalized == 'cancelled' || normalized == 'rejected') {
      return const Color(0xfffef2f2);
    }

    return const Color(0xfffff7ed);
  }

  Color _statusTextColor(String status) {
    final normalized = status.toLowerCase();

    if (normalized == 'completed') {
      return const Color(0xff166534);
    }

    if (normalized == 'accepted' ||
        normalized == 'dispatched' ||
        normalized == 'in progress') {
      return const Color(0xff1d4ed8);
    }

    if (normalized == 'cancelled' || normalized == 'rejected') {
      return const Color(0xffb91c1c);
    }

    return const Color(0xff9a3412);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: patientAppBar(context, 'My Requests'),
      body: RefreshIndicator(
        onRefresh: _refreshRequests,
        child: FutureBuilder<List<PatientRequestHistoryItem>>(
          future: _requestsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Color(0xffef3b4c),
                ),
              );
            }

            if (snapshot.hasError) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: PatientSectionCard(
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Color(0xffef3b4c),
                              size: 42,
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Failed to load your requests.',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff111827),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xff6b7280),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _refreshRequests,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xffef3b4c),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            final requests = snapshot.data ?? [];

            if (requests.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: PatientSectionCard(
                        child: Column(
                          children: const [
                            Icon(
                              Icons.inbox_outlined,
                              color: Color(0xff9ca3af),
                              size: 42,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'No requests found yet.',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff111827),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Your emergency and transport requests will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xff6b7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      children: requests.map((request) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: PatientSectionCard(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffffeef1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.receipt_long_outlined,
                                    color: Color(0xffef3b4c),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        request.title,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xff111827),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDate(request.createdAt),
                                        style: const TextStyle(
                                          color: Color(0xff6b7280),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        request.subtitle,
                                        style: const TextStyle(
                                          color: Color(0xff4b5563),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusBackgroundColor(
                                      request.status,
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    request.status,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: _statusTextColor(request.status),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}