import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:csv/csv.dart';

void main() => runApp(DataEntryApp());

// Model to represent each data entry
class DataEntry {
  final String variableName;
  final double variableValue;
  final DateTime timestamp;

  DataEntry({required this.variableName, required this.variableValue, required this.timestamp});

  // Convert each entry to a CSV-compatible format
  List<String> toCsvRow() {
    return [variableName, variableValue.toString(), timestamp.toIso8601String()];
  }
}

// Main App Widget
class DataEntryApp extends StatelessWidget {
  const DataEntryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Data Entry App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DataEntryScreen(),
    );
  }
}

class DataEntryScreen extends StatefulWidget {
  const DataEntryScreen({super.key});

  @override
  DataEntryScreenState createState() => DataEntryScreenState();
}

class DataEntryScreenState extends State<DataEntryScreen> {
  final TextEditingController _variableNameController = TextEditingController();
  final TextEditingController _variableValueController = TextEditingController();
  final List<DataEntry> _dataEntries = [];

  @override
  void initState() {
    super.initState();
    _loadCsvData();  // Load existing data on startup
  }

  // Method to load existing CSV data on app startup
  Future<void> _loadCsvData() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/data_entries.csv';
      final file = File(path);

      if (await file.exists()) {
        final csvString = await file.readAsString();
        List<List<dynamic>> csvData = const CsvToListConverter().convert(csvString);

        setState(() {
          _dataEntries.addAll(csvData.skip(1).map((row) {
            return DataEntry(
              variableName: row[0] as String,
              variableValue: double.parse(row[1].toString()),
              timestamp: DateTime.parse(row[2] as String),
            );
          }));
        });
      }
    } catch (e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  // Method to add a new entry
  void _addEntry() {
    final variableName = _variableNameController.text;
    final variableValue = double.tryParse(_variableValueController.text);

    if (variableName.isNotEmpty && variableValue != null) {
      final entry = DataEntry(
        variableName: variableName,
        variableValue: variableValue,
        timestamp: DateTime.now(),
      );

      setState(() {
        _dataEntries.add(entry);
      });

      _variableNameController.clear();
      _variableValueController.clear();
    }
  }

  // Method to save all entries to CSV file
  Future<void> _exportToCsv() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/data_entries.csv';
      final file = File(path);

      List<List<dynamic>> csvData = [
        ['Variable Name', 'Variable Value', 'Timestamp']
      ];

      if (await file.exists()) {
        final existingCsvString = await file.readAsString();
        List<List<dynamic>> existingCsvData = const CsvToListConverter().convert(existingCsvString);
        csvData.addAll(existingCsvData.skip(1));
      }

      csvData.addAll(_dataEntries.map((entry) => entry.toCsvRow()));

      final updatedCsvString = const ListToCsvConverter().convert(csvData);
      await file.writeAsString(updatedCsvString);

      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Data saved to $path')),
        );
      }
    } catch (e) {
      if(mounted){
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save data: $e')),
        );
      }
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Entry App')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _variableNameController,
              decoration: const InputDecoration(labelText: 'Variable Name'),
            ),
            TextField(
              controller: _variableValueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Variable Value'),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _addEntry,
                  child: const Text('Add Entry'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _exportToCsv,
                  child: const Text('Export to CSV'),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: _dataEntries.length,
                itemBuilder: (context, index) {
                  final entry = _dataEntries[index];
                  return ListTile(
                    title: Text('${entry.variableName}: ${entry.variableValue}'),
                    subtitle: Text(entry.timestamp.toIso8601String()),
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