import 'package:flutter/material.dart';

import '../models/student.dart';

class StudentTile extends StatelessWidget {
  final Student student;
  final VoidCallback onToggle;
  final VoidCallback onEdit;

  const StudentTile({Key? key, required this.student, required this.onToggle, required this.onEdit})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(student.name.isNotEmpty ? student.name[0] : '?'),
      ),
      title: Text(student.name),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(
            value: student.isPresent,
            onChanged: (_) => onToggle(),
            activeColor: Colors.green,
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
          ),
        ],
      ),
      onTap: onToggle,
    );
  }
}