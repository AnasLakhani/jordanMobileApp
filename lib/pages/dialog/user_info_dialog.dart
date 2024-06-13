import 'package:flutter/material.dart';

class UserInfoDialog extends StatefulWidget {
  final String? name;
  final String? gender;
  final Function(String, String) onSubmitted;

  const UserInfoDialog(
      {super.key, required this.onSubmitted, this.name, this.gender});

  @override
  _UserInfoDialogState createState() => _UserInfoDialogState();
}

class _UserInfoDialogState extends State<UserInfoDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedGender = 'Boy';

  @override
  void initState() {
    _nameController.text = widget.name ?? "";
    _selectedGender = widget.gender ?? "";
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter Your Information'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Name',
            ),
          ),
          const SizedBox(height: 20),
          const Text('Select Character:'),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = 'Boy';
                  });
                },
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/man.png',
                      width: 50,
                      height: 50,
                    ),
                    Radio(
                      value: 'Boy',
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                    const Text('Boy'),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = 'Girl';
                  });
                },
                child: Column(
                  children: [
                    Image.asset(
                      'assets/images/woman.png',
                      width: 50,
                      height: 50,
                    ),
                    Radio(
                      value: 'Girl',
                      groupValue: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value!;
                        });
                      },
                    ),
                    const Text('Girl'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isEmpty) return;
            // if (_selectedGender.isEmpty) return;
            widget.onSubmitted(_nameController.text, _selectedGender);
            Navigator.of(context).pop();
          },
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
