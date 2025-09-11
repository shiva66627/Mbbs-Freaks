
import 'package:flutter/material.dart';
import 'dropdown_page.dart';

class PyqsPage extends StatelessWidget {
  const PyqsPage({super.key});

  // Nested Map: Year → Subject → Chapter → PYQs
  final Map<String, Map<String, Map<String, List<String>>>> pyqsData = const {
    "1st Year": {
      "Anatomy": {
        "Chapter 1": ["Anatomy_2019.pdf", "Anatomy_2020.pdf"],
        "Chapter 2": ["Bones_2019.pdf", "Bones_2020.pdf"],
      },
      "Physiology": {
        "Chapter 1": ["Physiology_2019.pdf", "Physiology_2020.pdf"]
      }
    },
    "2nd Year": {
      "Pathology": {
        "Chapter 1": ["Patho_2019.pdf", "Patho_2020.pdf"]
      }
    },
    "3rd Year": {
      "Pharmacology": {
        "Chapter 1": ["Pharma_2019.pdf", "Pharma_2020.pdf"]
      }
    },
    "4th Year": {
      "Community Medicine": {
        "Chapter 1": ["CommMed_2019.pdf", "CommMed_2020.pdf"]
      }
    }
  };

  @override
  Widget build(BuildContext context) {
    return DropdownPage(
      title: "PYQs",
      data: pyqsData,
    );
  }
}
