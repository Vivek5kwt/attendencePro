import 'package:flutter/material.dart';

import '../models/student.dart';

class StudentTile extends StatelessWidget {
  final Student student;
  final VoidCallback onToggle;

  const StudentTile({Key? key, required this.student, required this.onToggle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(student.name.isNotEmpty ? student.name[0] : '?'),
      ),
      title: Text(student.name),
      trailing: Switch(
        value: student.isPresent,
        onChanged: (_) => onToggle(),
        activeColor: Colors.green,
      ),
      onTap: onToggle,
    );
  }
}