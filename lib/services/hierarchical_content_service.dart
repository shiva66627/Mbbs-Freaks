import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hierarchical_content_model.dart';

class HierarchicalContentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Admin Methods
  Future<void> addSubject(ContentSubject subject) async {
    await _firestore.collection('subjects').add({
      'name': subject.name,
      'code': subject.code,
      'description': subject.description,
      'category': subject.category.name,
      'year': subject.year.name,
      'order': subject.order,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': subject.isActive,
    });
  }

  Future<void> addChapter(ContentChapter chapter) async {
    await _firestore.collection('chapters').add({
      'name': chapter.name,
      'description': chapter.description,
      'subjectId': chapter.subjectId,
      'order': chapter.order,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': chapter.isActive,
    });
  }

  Future<void> addPDF(ContentPDF pdf) async {
    await _firestore.collection('pdfs').add({
      'title': pdf.title,
      'description': pdf.description,
      'driveFileId': pdf.driveFileId,
      'downloadUrl': pdf.downloadUrl,
      'storagePath': pdf.storagePath,
      'fileSize': pdf.fileSize,
      'pageCount': pdf.pageCount,
      'metadata': pdf.metadata,
      'tags': pdf.tags,
      'order': pdf.order,
      'uploadedAt': FieldValue.serverTimestamp(),
      'lastAccessedAt': pdf.lastAccessedAt,
      'downloadCount': pdf.downloadCount,
      'isActive': pdf.isActive,
      'isPublic': pdf.isPublic,
      'uploadedBy': pdf.uploadedBy,
      'chapterId': pdf.chapterId ?? '', // Add chapterId for relationship
    });
  }

  // User Methods
  Future<List<ContentSubject>> getSubjects({
    required ContentCategory category,
    required AcademicYear year,
  }) async {
    final querySnapshot = await _firestore
        .collection('subjects')
        .where('category', isEqualTo: category.name)
        .where('year', isEqualTo: year.name)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .get();

    return querySnapshot.docs
        .map((doc) => ContentSubject.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<List<ContentChapter>> getChapters(String subjectId) async {
    final querySnapshot = await _firestore
        .collection('chapters')
        .where('subjectId', isEqualTo: subjectId)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .get();

    return querySnapshot.docs
        .map((doc) => ContentChapter.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Future<List<ContentPDF>> getPDFs(String chapterId) async {
    final querySnapshot = await _firestore
        .collection('pdfs')
        .where('chapterId', isEqualTo: chapterId)
        .where('isActive', isEqualTo: true)
        .where('isPublic', isEqualTo: true)
        .orderBy('order')
        .get();

    return querySnapshot.docs
        .map((doc) => ContentPDF.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  // Statistics Methods
  Future<Map<String, int>> getCategoryStatistics() async {
    final Map<String, int> stats = {};

    for (final category in ContentCategory.values) {
      final querySnapshot = await _firestore
          .collection('subjects')
          .where('category', isEqualTo: category.name)
          .where('isActive', isEqualTo: true)
          .get();

      stats[category.name] = querySnapshot.docs.length;
    }

    return stats;
  }

  Future<HierarchicalContentStatistics> getFullStatistics() async {
    final Map<ContentCategory, Map<AcademicYear, ContentCategoryStats>>
    statsByCategory = {};
    final Map<ContentCategory, int> totalSubjectsByCategory = {};
    final Map<ContentCategory, int> totalChaptersByCategory = {};
    final Map<ContentCategory, int> totalPDFsByCategory = {};
    final Map<AcademicYear, int> totalSubjectsByYear = {};
    final Map<AcademicYear, int> totalChaptersByYear = {};
    final Map<AcademicYear, int> totalPDFsByYear = {};

    int totalSubjects = 0;
    int totalChapters = 0;
    int totalPDFs = 0;
    int totalSize = 0;

    // Initialize stats maps
    for (final category in ContentCategory.values) {
      statsByCategory[category] = {};
      totalSubjectsByCategory[category] = 0;
      totalChaptersByCategory[category] = 0;
      totalPDFsByCategory[category] = 0;

      for (final year in AcademicYear.values) {
        statsByCategory[category]![year] = ContentCategoryStats(
          subjects: 0,
          chapters: 0,
          pdfs: 0,
          totalSize: 0,
        );
      }
    }

    for (final year in AcademicYear.values) {
      totalSubjectsByYear[year] = 0;
      totalChaptersByYear[year] = 0;
      totalPDFsByYear[year] = 0;
    }

    // Get subjects
    final subjectsSnapshot = await _firestore
        .collection('subjects')
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in subjectsSnapshot.docs) {
      final data = doc.data();
      final category = ContentCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => ContentCategory.notes,
      );
      final year = AcademicYear.values.firstWhere(
        (e) => e.name == data['year'],
        orElse: () => AcademicYear.first,
      );

      totalSubjects++;
      totalSubjectsByCategory[category] =
          (totalSubjectsByCategory[category] ?? 0) + 1;
      totalSubjectsByYear[year] = (totalSubjectsByYear[year] ?? 0) + 1;

      final currentStats = statsByCategory[category]![year]!;
      statsByCategory[category]![year] = ContentCategoryStats(
        subjects: currentStats.subjects + 1,
        chapters: currentStats.chapters,
        pdfs: currentStats.pdfs,
        totalSize: currentStats.totalSize,
      );
    }

    // Get chapters
    final chaptersSnapshot = await _firestore
        .collection('chapters')
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in chaptersSnapshot.docs) {
      final data = doc.data();
      final subjectId = data['subjectId'] as String;

      // Get subject to determine category and year
      final subjectDoc = await _firestore
          .collection('subjects')
          .doc(subjectId)
          .get();
      if (subjectDoc.exists) {
        final subjectData = subjectDoc.data()!;
        final category = ContentCategory.values.firstWhere(
          (e) => e.name == subjectData['category'],
          orElse: () => ContentCategory.notes,
        );
        final year = AcademicYear.values.firstWhere(
          (e) => e.name == subjectData['year'],
          orElse: () => AcademicYear.first,
        );

        totalChapters++;
        totalChaptersByCategory[category] =
            (totalChaptersByCategory[category] ?? 0) + 1;
        totalChaptersByYear[year] = (totalChaptersByYear[year] ?? 0) + 1;

        final currentStats = statsByCategory[category]![year]!;
        statsByCategory[category]![year] = ContentCategoryStats(
          subjects: currentStats.subjects,
          chapters: currentStats.chapters + 1,
          pdfs: currentStats.pdfs,
          totalSize: currentStats.totalSize,
        );
      }
    }

    // Get PDFs
    final pdfsSnapshot = await _firestore
        .collection('pdfs')
        .where('isActive', isEqualTo: true)
        .where('isPublic', isEqualTo: true)
        .get();

    for (final doc in pdfsSnapshot.docs) {
      final data = doc.data();
      final chapterId = data['chapterId'] as String;
      final fileSize = data['fileSize'] as int? ?? 0;

      // Get chapter to determine subject, then category and year
      final chapterDoc = await _firestore
          .collection('chapters')
          .doc(chapterId)
          .get();
      if (chapterDoc.exists) {
        final chapterData = chapterDoc.data()!;
        final subjectId = chapterData['subjectId'] as String;

        final subjectDoc = await _firestore
            .collection('subjects')
            .doc(subjectId)
            .get();
        if (subjectDoc.exists) {
          final subjectData = subjectDoc.data()!;
          final category = ContentCategory.values.firstWhere(
            (e) => e.name == subjectData['category'],
            orElse: () => ContentCategory.notes,
          );
          final year = AcademicYear.values.firstWhere(
            (e) => e.name == subjectData['year'],
            orElse: () => AcademicYear.first,
          );

          totalPDFs++;
          totalSize += fileSize;
          totalPDFsByCategory[category] =
              (totalPDFsByCategory[category] ?? 0) + 1;
          totalPDFsByYear[year] = (totalPDFsByYear[year] ?? 0) + 1;

          final currentStats = statsByCategory[category]![year]!;
          statsByCategory[category]![year] = ContentCategoryStats(
            subjects: currentStats.subjects,
            chapters: currentStats.chapters,
            pdfs: currentStats.pdfs + 1,
            totalSize: currentStats.totalSize + fileSize,
          );
        }
      }
    }

    return HierarchicalContentStatistics(
      statsByCategory: statsByCategory,
      totalSubjectsByCategory: totalSubjectsByCategory,
      totalChaptersByCategory: totalChaptersByCategory,
      totalPDFsByCategory: totalPDFsByCategory,
      totalSubjectsByYear: totalSubjectsByYear,
      totalChaptersByYear: totalChaptersByYear,
      totalPDFsByYear: totalPDFsByYear,
      totalSubjects: totalSubjects,
      totalChapters: totalChapters,
      totalPDFs: totalPDFs,
      totalSize: totalSize,
    );
  }

  // Search Methods
  Future<List<ContentPDF>> searchContent(String query) async {
    if (query.isEmpty) return [];

    final queryLower = query.toLowerCase();
    final List<ContentPDF> results = [];

    // Search in PDFs
    final pdfsSnapshot = await _firestore
        .collection('pdfs')
        .where('isActive', isEqualTo: true)
        .where('isPublic', isEqualTo: true)
        .get();

    for (final doc in pdfsSnapshot.docs) {
      final data = doc.data();
      final title = (data['title'] as String? ?? '').toLowerCase();
      final description = (data['description'] as String? ?? '').toLowerCase();
      final tags = List<String>.from(data['tags'] ?? []);

      if (title.contains(queryLower) ||
          description.contains(queryLower) ||
          tags.any((tag) => tag.toLowerCase().contains(queryLower))) {
        results.add(ContentPDF.fromJson({...data, 'id': doc.id}));
      }
    }

    return results;
  }

  // Update Methods
  Future<void> updateSubject(
    String subjectId,
    Map<String, dynamic> updates,
  ) async {
    await _firestore.collection('subjects').doc(subjectId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateChapter(
    String chapterId,
    Map<String, dynamic> updates,
  ) async {
    await _firestore.collection('chapters').doc(chapterId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updatePDF(String pdfId, Map<String, dynamic> updates) async {
    await _firestore.collection('pdfs').doc(pdfId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete Methods
  Future<void> deleteSubject(String subjectId) async {
    // First, get all chapters for this subject
    final chaptersSnapshot = await _firestore
        .collection('chapters')
        .where('subjectId', isEqualTo: subjectId)
        .get();

    // Delete all PDFs in these chapters
    for (final chapterDoc in chaptersSnapshot.docs) {
      final pdfsSnapshot = await _firestore
          .collection('pdfs')
          .where('chapterId', isEqualTo: chapterDoc.id)
          .get();

      for (final pdfDoc in pdfsSnapshot.docs) {
        await pdfDoc.reference.delete();
      }

      // Delete the chapter
      await chapterDoc.reference.delete();
    }

    // Finally, delete the subject
    await _firestore.collection('subjects').doc(subjectId).delete();
  }

  Future<void> deleteChapter(String chapterId) async {
    // First, delete all PDFs in this chapter
    final pdfsSnapshot = await _firestore
        .collection('pdfs')
        .where('chapterId', isEqualTo: chapterId)
        .get();

    for (final pdfDoc in pdfsSnapshot.docs) {
      await pdfDoc.reference.delete();
    }

    // Then delete the chapter
    await _firestore.collection('chapters').doc(chapterId).delete();
  }

  Future<void> deletePDF(String pdfId) async {
    await _firestore.collection('pdfs').doc(pdfId).delete();
  }

  // Utility Methods
  Future<void> incrementDownloadCount(String pdfId) async {
    await _firestore.collection('pdfs').doc(pdfId).update({
      'downloadCount': FieldValue.increment(1),
      'lastAccessedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateLastAccessed(String pdfId) async {
    await _firestore.collection('pdfs').doc(pdfId).update({
      'lastAccessedAt': FieldValue.serverTimestamp(),
    });
  }
}
