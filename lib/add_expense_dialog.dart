import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:personal_pudget/services/firebase_service.dart';

/// A dialog that allows users to add a new expense.
class AddExpenseDialog extends StatefulWidget {
  const AddExpenseDialog({super.key});

  @override
  _AddExpenseDialogState createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final TextEditingController _amountController = TextEditingController();
  String? _category;
  DateTime _selectedDate = DateTime.now();
  String? _notes;
  bool _isRecurring = false;
  String? _frequency;
  bool _isLoading = false;
  final FirebaseService _firebaseService = FirebaseService();

  final List<String> _categories = [
    'Groceries',
    'Transportation',
    'Entertainment',
    'Utilities',
    'Dining',
    'Other'
  ]; // Added 'Other' as a default category

  final List<IconData> _categoryIcons = [
    Icons.shopping_basket,
    Icons.directions_car,
    Icons.movie,
    Icons.lightbulb,
    Icons.restaurant,
    Icons.category,
  ];

  Future<void> _saveExpense() async {
    if (_amountController.text.isEmpty || _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _firebaseService.addExpense(
        amount: double.parse(_amountController.text),
        category: _category!,
        date: _selectedDate,
        notes: _notes,
        isRecurring: _isRecurring,
        frequency: _frequency,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving expense: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add Expense',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixIcon: Icon(Icons.attach_money),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.category),
              ),
              value: _category,
              items: [
                ..._categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Row(
                      children: [
                        Icon(_categoryIcons[_categories
                            .indexOf(category)]), // Get icon based on index
                        const SizedBox(width: 8),
                        Text(category),
                      ],
                    ),
                  );
                }),
                const DropdownMenuItem<String>(
                  value: 'Add Custom Category',
                  child: Row(
                    children: [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text('Add Custom Category'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  if (value == 'Add Custom Category') {
                    _showAddCustomCategoryDialog(context);
                  } else {
                    _category = value;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Date'),
              subtitle: Text(DateFormat.yMMMd().format(_selectedDate)),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (picked != null && picked != _selectedDate) {
                  setState(() {
                    _selectedDate = picked;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Notes',
                prefixIcon: Icon(Icons.notes),
              ),
              onChanged: (value) {
                setState(() {
                  _notes = value;
                });
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Recurring Expense'),
              value: _isRecurring,
              onChanged: (value) {
                setState(() {
                  _isRecurring = value;
                });
              },
            ),
            if (_isRecurring)
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  prefixIcon: Icon(Icons.repeat),
                ),
                value: _frequency,
                items: <String>['Daily', 'Weekly', 'Monthly']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _frequency = value;
                  });
                },
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.grey)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveExpense,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Shows a dialog to add a custom category.
  void _showAddCustomCategoryDialog(BuildContext context) {
    String? customCategoryName;
    Color? selectedColor = Colors.blue; // Default color
    IconData? selectedIcon = Icons.category; // Default icon

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add Custom Category',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Category Name',
                        prefixIcon: Icon(Icons.title),
                      ),
                      onChanged: (value) {
                        customCategoryName = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Color Picker
                    DropdownButtonFormField<Color>(
                      decoration: const InputDecoration(
                        labelText: 'Color',
                        prefixIcon: Icon(Icons.color_lens),
                      ),
                      value: selectedColor,
                      items: [
                        Colors.red,
                        Colors.blue,
                        Colors.green,
                        Colors.yellow,
                        Colors.purple,
                        Colors.orange,
                      ].map<DropdownMenuItem<Color>>((Color color) {
                        return DropdownMenuItem<Color>(
                          value: color,
                          child: Container(
                            width: 20,
                            height: 20,
                            color: color,
                          ),
                        );
                      }).toList(),
                      onChanged: (Color? value) {
                        setState(() {
                          selectedColor = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Icon Picker
                    DropdownButtonFormField<IconData>(
                      decoration: const InputDecoration(
                        labelText: 'Icon',
                        prefixIcon: Icon(Icons.insert_emoticon),
                      ),
                      value: selectedIcon,
                      items: [
                        Icons.shopping_basket,
                        Icons.directions_car,
                        Icons.movie,
                        Icons.lightbulb,
                        Icons.restaurant,
                        Icons.category,
                      ].map<DropdownMenuItem<IconData>>((IconData icon) {
                        return DropdownMenuItem<IconData>(
                          value: icon,
                          child: Icon(icon),
                        );
                      }).toList(),
                      onChanged: (IconData? value) {
                        setState(() {
                          selectedIcon = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (customCategoryName != null &&
                                customCategoryName!.isNotEmpty) {
                              // Add the new category to the list and show it in the dropdown
                              setState(() {
                                _categories.insert(_categories.length - 1,
                                    customCategoryName!);
                                _categoryIcons.insert(
                                    _categoryIcons.length - 1, selectedIcon!);
                                _category = customCategoryName;
                              });
                            }
                            Navigator.of(context)
                                .pop(); // Close the custom category dialog
                            Navigator.of(context)
                                .pop(); // Close the add expense dialog
                            _showAddExpenseDialog(
                                context); // Reopen the add expense dialog with the new category
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors
                                .indigo, // Changed primary to backgroundColor
                          ),
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // This function should be inside _AddExpenseDialogState
  void _showAddExpenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const AddExpenseDialog();
      },
    );
  }
}
