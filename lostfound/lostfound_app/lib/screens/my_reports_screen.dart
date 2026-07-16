import 'package:flutter/material.dart';
import '../services/report_service.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key});

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  List<dynamic> _reports = [];
  bool _isLoading = true;
  String? _errorMessage;

  // ID laporan yang sedang diproses (biar tombolnya kasih loading state per-item)
  String? _updatingId;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final reports = await ReportService.getMyReports();
      setState(() => _reports = reports);
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(String reportId, String currentStatus) async {
    final newStatus = currentStatus == 'open' ? 'matched' : 'open';
    setState(() => _updatingId = reportId);
    try {
      await ReportService.updateReportStatus(reportId, newStatus);
      await _loadReports();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newStatus == 'matched'
                ? 'Laporan ditandai sudah ketemu'
                : 'Laporan dibuka kembali',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _updatingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Saya')),
      body: RefreshIndicator(
        onRefresh: _loadReports,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Center(child: Text(_errorMessage!, textAlign: TextAlign.center)),
        ],
      );
    }

    if (_reports.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Center(child: Text('Kamu belum pernah membuat laporan')),
        ],
      );
    }

    return ListView.builder(
      itemCount: _reports.length,
      itemBuilder: (context, index) {
        final item = _reports[index];
        final reportId = item['_id'] as String;
        final status = item['status'] as String? ?? 'open';
        final photoUrl = item['photo_url'] as String?;
        final isMatched = status == 'matched';
        final isUpdating = _updatingId == reportId;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: (photoUrl != null && photoUrl.isNotEmpty)
                    ? Image.network(
                        ReportService.resolvePhotoUrl(photoUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      )
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
                      ),
              ),
            ),
            title: Text(item['title'] ?? ''),
            subtitle: Text('${item['description']}\nLokasi: ${item['location']}'),
            isThreeLine: true,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Chip(
                  label: Text(isMatched ? 'Sudah Ketemu' : (item['report_type'] ?? '')),
                  backgroundColor: isMatched
                      ? Colors.blue.shade100
                      : (item['report_type'] == 'hilang' ? Colors.red.shade100 : Colors.green.shade100),
                  padding: EdgeInsets.zero,
                  labelStyle: const TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 6),
                isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: () => _toggleStatus(reportId, status),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                        child: Text(
                          isMatched ? 'Buka lagi' : 'Tandai ketemu',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }
}
