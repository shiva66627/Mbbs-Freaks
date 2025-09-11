import 'package:flutter/material.dart';
import 'dropdown_page.dart';

class QuizPage extends StatelessWidget {
  const QuizPage({super.key});

  final Map<String, Map<String, Map<String, List<String>>>> quizData = const {
    "1st Year": {
      "Anatomy": {
        "Chapter 1": ["Quiz Set 1", "Quiz Set 2"],
        "Chapter 2": ["Quiz Set 1"]
      },
      "Physiology": {
        "Chapter 1": ["Quiz Set 1"]
      }
    },
    "2nd Year": {
      "Pathology": {
        "Chapter 1": ["Quiz Set 1", "Quiz Set 2"]
      }
    },
    "3rd Year": {
      "Pharmacology": {
        "Chapter 1": ["Quiz Set 1"]
      }
    }
  };

  @override
  Widget build(BuildContext context) {
    return DropdownPage(title: "Quiz", data: quizData);
  }
}
