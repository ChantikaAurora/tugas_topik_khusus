import 'package:flutter/material.dart';
import '../services/report_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _queryCtrl = TextEditingController();
  List<dynamic> _results = [];
  bool _isLoading = false;

  Future<void> _search() async {
    if (_queryCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final results = await ReportService.searchReports(_queryCtrl.text);
      setState(() => _results = results);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cari Barang')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Cari mis: dompet coklat',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _search, child: const Text('Cari')),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading) const CircularProgressIndicator(),
            if (!_isLoading)
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final item = _results[index];
                    return Card(
                      child: ListTile(
                        title: Text(item['title'] ?? ''),
                        subtitle: Text('${item['description']}\nLokasi: ${item['location']}'),
                        trailing: Chip(
                          label: Text(item['report_type'] ?? ''),
                          backgroundColor: item['report_type'] == 'hilang'
                              ? Colors.red.shade100
                              : Colors.green.shade100,
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
