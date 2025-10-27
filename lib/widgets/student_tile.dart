import 'package:flutter/material.dart';

import '../models/student.dart';
import '../utils/responsive.dart';

class StudentTile extends StatelessWidget {
  final Student student;
  final VoidCallback onToggle;

  const StudentTile({Key? key, required this.student, required this.onToggle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final displayInitial = student.name.isNotEmpty ? student.name[0] : '?';
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: responsive.scale(16),
        vertical: responsive.scale(8),
      ),
      leading: CircleAvatar(
        radius: responsive.scale(20),
        child: Text(
          displayInitial,
          style: TextStyle(fontSize: responsive.scaleText(16)),
        ),
      ),
      title: Text(
        student.name,
        style: TextStyle(fontSize: responsive.scaleText(16)),
      ),
      trailing: Transform.scale(
        scale: responsive.scale(1),
        child: Switch(
          value: student.isPresent,
          onChanged: (_) => onToggle(),
          activeColor: Colors.green,
        ),
      ),
      onTap: onToggle,
    );
  }
}