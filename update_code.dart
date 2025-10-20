import 'dart:io';
import 'package:attendancepro/apis/edit_code_api.dart';


final editCodeService = EditCodeService();

Future<void> main() async {
  final file = File('lib/screens/verify_screen.dart');
  print('Processing file: ${file.path}');
  final content = await file.readAsString();

  final updatedCode = await editCodeService.editCode(
    fileContent: content,
    instruction: "same issue on this scrren back button is not working pleae check why it is not working"
  );

  if (updatedCode != null) {
    await file.writeAsString(updatedCode);
    print("✅ Updated ${file.path}");
  } else {
    print("❌ Failed to update ${file.path}");
  }
}
