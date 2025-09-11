import 'package:flutter/material.dart';
import 'dropdown_page.dart';

class QuestionBankPage extends StatelessWidget {
  const QuestionBankPage({super.key});

  final Map<String, Map<String, Map<String, List<String>>>> qbData = const {
    "1st Year": {
      "Anatomy": {
        "Long Questions": ["Anatomy_LongQ.pdf"],
        "Short Questions": ["Anatomy_ShortQ.pdf"]
      }
    },
    "2nd Year": {
      "Pathology": {
        "MCQs": ["Patho_MCQs.pdf"]
      }
    }
  };

  @override
  Widget build(BuildContext context) {
    return DropdownPage(title: "Question Bank", data: qbData);
  }
}
