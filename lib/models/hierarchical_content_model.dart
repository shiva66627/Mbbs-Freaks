enum ContentCategory {
  notes('Notes', 'Study materials and lecture notes', 'notes'),
  pyqs('PYQs', 'Previous Year Questions', 'pyqs'),
  questionBanks(
    'Question Banks',
    'Practice question collections',
    'question_banks',
  );

  const ContentCategory(
    this.displayName,
    this.description,
    this.firestoreCollection,
  );

  final String displayName;
  final String description;
  final String firestoreCollection;
}

enum AcademicYear {
  first('1st Year', '1st', 1),
  second('2nd Year', '2nd', 2),
  third('3rd Year', '3rd', 3),
  fourth('4th Year', '4th', 4);

  const AcademicYear(this.displayName, this.shortName, this.yearNumber);

  final String displayName;
  final String shortName;
  final int yearNumber;
}

class ContentSubject {
  final String id;
  final String name;
  final String code;
  final String description;
  final ContentCategory category; // Notes, PYQs, or Question Banks
  final AcademicYear year; // 1st, 2nd, 3rd, 4th
  final List<ContentChapter> chapters;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ContentSubject({
    required this.id,
    required this.name,
    required this.code,
    required this.description,
    required this.category,
    required this.year,
    this.chapters = const [],
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory ContentSubject.fromJson(Map<String, dynamic> json) {
    return ContentSubject(
      id: json['id'] as String,
      name: json['name'] as String,
      code: json['code'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: ContentCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ContentCategory.notes,
      ),
      year: AcademicYear.values.firstWhere(
        (e) => e.name == json['year'],
        orElse: () => AcademicYear.first,
      ),
      chapters:
          (json['chapters'] as List<dynamic>?)
              ?.map(
                (chapter) =>
                    ContentChapter.fromJson(chapter as Map<String, dynamic>),
              )
              .toList() ??
          [],
      order: json['order'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'description': description,
      'category': category.name,
      'year': year.name,
      'chapters': chapters.map((chapter) => chapter.toJson()).toList(),
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  ContentSubject copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    ContentCategory? category,
    AcademicYear? year,
    List<ContentChapter>? chapters,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ContentSubject(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      category: category ?? this.category,
      year: year ?? this.year,
      chapters: chapters ?? this.chapters,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  int get totalChapters => chapters.where((c) => c.isActive).length;
  int get totalPDFs =>
      chapters.fold(0, (sum, chapter) => sum + chapter.totalPDFs);
  int get totalFileSize =>
      chapters.fold(0, (sum, chapter) => sum + chapter.totalFileSize);
}

class ContentChapter {
  final String id;
  final String name;
  final String description;
  final String subjectId; // Parent subject ID
  final List<ContentPDF> pdfs;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ContentChapter({
    required this.id,
    required this.name,
    required this.description,
    required this.subjectId,
    this.pdfs = const [],
    required this.order,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  factory ContentChapter.fromJson(Map<String, dynamic> json) {
    return ContentChapter(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      subjectId: json['subjectId'] as String,
      pdfs:
          (json['pdfs'] as List<dynamic>?)
              ?.map((pdf) => ContentPDF.fromJson(pdf as Map<String, dynamic>))
              .toList() ??
          [],
      order: json['order'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'subjectId': subjectId,
      'pdfs': pdfs.map((pdf) => pdf.toJson()).toList(),
      'order': order,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  ContentChapter copyWith({
    String? id,
    String? name,
    String? description,
    String? subjectId,
    List<ContentPDF>? pdfs,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return ContentChapter(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      subjectId: subjectId ?? this.subjectId,
      pdfs: pdfs ?? this.pdfs,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  int get totalPDFs => pdfs.where((pdf) => pdf.isActive).length;
  int get totalFileSize => pdfs.fold(0, (sum, pdf) => sum + pdf.fileSize);
}

class ContentPDF {
  final String id;
  final String title;
  final String description;
  final String
  driveFileId; // Google Drive file ID (since files are in admin's Google Drive)
  final String downloadUrl;
  final String storagePath; // Path in Google Drive or local reference
  final int fileSize;
  final int pageCount;
  final Map<String, String> metadata; // Additional content-specific metadata
  final List<String> tags;
  final int order;
  final DateTime uploadedAt;
  final DateTime? lastAccessedAt;
  final int downloadCount;
  final bool isActive;
  final bool isPublic;
  final String uploadedBy; // Admin user identifier
  final String? chapterId; // Reference to parent chapter

  ContentPDF({
    required this.id,
    required this.title,
    required this.description,
    required this.driveFileId,
    required this.downloadUrl,
    required this.storagePath,
    required this.fileSize,
    required this.pageCount,
    this.metadata = const {},
    this.tags = const [],
    required this.order,
    required this.uploadedAt,
    this.lastAccessedAt,
    this.downloadCount = 0,
    this.isActive = true,
    this.isPublic = true,
    required this.uploadedBy,
    this.chapterId,
  });

  factory ContentPDF.fromJson(Map<String, dynamic> json) {
    return ContentPDF(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      driveFileId:
          json['driveFileId'] as String? ??
          json['fileId'] as String? ??
          '', // Backward compatibility
      downloadUrl: json['downloadUrl'] as String? ?? '',
      storagePath: json['storagePath'] as String? ?? '',
      fileSize: json['fileSize'] as int? ?? 0,
      pageCount: json['pageCount'] as int? ?? 0,
      metadata: Map<String, String>.from(json['metadata'] ?? {}),
      tags: List<String>.from(json['tags'] ?? []),
      order: json['order'] as int? ?? 0,
      uploadedAt: DateTime.parse(json['uploadedAt'] as String),
      lastAccessedAt: json['lastAccessedAt'] != null
          ? DateTime.parse(json['lastAccessedAt'] as String)
          : null,
      downloadCount: json['downloadCount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? true,
      isPublic: json['isPublic'] as bool? ?? true,
      uploadedBy: json['uploadedBy'] as String? ?? 'admin',
      chapterId: json['chapterId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'driveFileId': driveFileId,
      'fileId': driveFileId, // For backward compatibility
      'downloadUrl': downloadUrl,
      'storagePath': storagePath,
      'fileSize': fileSize,
      'pageCount': pageCount,
      'metadata': metadata,
      'tags': tags,
      'order': order,
      'uploadedAt': uploadedAt.toIso8601String(),
      'lastAccessedAt': lastAccessedAt?.toIso8601String(),
      'downloadCount': downloadCount,
      'isActive': isActive,
      'isPublic': isPublic,
      'uploadedBy': uploadedBy,
      'chapterId': chapterId,
    };
  }

  ContentPDF copyWith({
    String? id,
    String? title,
    String? description,
    String? driveFileId,
    String? downloadUrl,
    String? storagePath,
    int? fileSize,
    int? pageCount,
    Map<String, String>? metadata,
    List<String>? tags,
    int? order,
    DateTime? uploadedAt,
    DateTime? lastAccessedAt,
    int? downloadCount,
    bool? isActive,
    bool? isPublic,
    String? uploadedBy,
    String? chapterId,
  }) {
    return ContentPDF(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      driveFileId: driveFileId ?? this.driveFileId,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      storagePath: storagePath ?? this.storagePath,
      fileSize: fileSize ?? this.fileSize,
      pageCount: pageCount ?? this.pageCount,
      metadata: metadata ?? this.metadata,
      tags: tags ?? this.tags,
      order: order ?? this.order,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      lastAccessedAt: lastAccessedAt ?? this.lastAccessedAt,
      downloadCount: downloadCount ?? this.downloadCount,
      isActive: isActive ?? this.isActive,
      isPublic: isPublic ?? this.isPublic,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      chapterId: chapterId ?? this.chapterId,
    );
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024)
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Content-specific metadata helpers
  String? get examYear => metadata['examYear'];
  String? get university => metadata['university'];
  String? get author => metadata['author'];
  String? get questionType =>
      metadata['questionType']; // For PYQs and Question Banks
  String? get difficulty => metadata['difficulty'];
  String? get topic => metadata['topic'];

  // Google Drive specific URL
  String get googleDriveViewUrl =>
      'https://drive.google.com/file/d/$driveFileId/view';
  String get googleDriveDownloadUrl =>
      'https://drive.google.com/uc?export=download&id=$driveFileId';
}

// Navigation breadcrumb helper
class ContentBreadcrumb {
  final ContentCategory? category;
  final AcademicYear? year;
  final ContentSubject? subject;
  final ContentChapter? chapter;

  ContentBreadcrumb({this.category, this.year, this.subject, this.chapter});

  List<String> get breadcrumbParts {
    final parts = <String>[];
    if (category != null) parts.add(category!.displayName);
    if (year != null) parts.add(year!.displayName);
    if (subject != null) parts.add(subject!.name);
    if (chapter != null) parts.add(chapter!.name);
    return parts;
  }

  String get breadcrumbText => breadcrumbParts.join(' → ');

  bool get isComplete =>
      category != null && year != null && subject != null && chapter != null;
  bool get hasCategory => category != null;
  bool get hasYear => year != null;
  bool get hasSubject => subject != null;
  bool get hasChapter => chapter != null;
}

// Hierarchical content statistics
class HierarchicalContentStatistics {
  final Map<ContentCategory, Map<AcademicYear, ContentCategoryStats>>
  statsByCategory;
  final Map<ContentCategory, int> totalSubjectsByCategory;
  final Map<ContentCategory, int> totalChaptersByCategory;
  final Map<ContentCategory, int> totalPDFsByCategory;
  final Map<AcademicYear, int> totalSubjectsByYear;
  final Map<AcademicYear, int> totalChaptersByYear;
  final Map<AcademicYear, int> totalPDFsByYear;
  final int totalSubjects;
  final int totalChapters;
  final int totalPDFs;
  final int totalSize;

  HierarchicalContentStatistics({
    required this.statsByCategory,
    required this.totalSubjectsByCategory,
    required this.totalChaptersByCategory,
    required this.totalPDFsByCategory,
    required this.totalSubjectsByYear,
    required this.totalChaptersByYear,
    required this.totalPDFsByYear,
    required this.totalSubjects,
    required this.totalChapters,
    required this.totalPDFs,
    required this.totalSize,
  });

  String get formattedTotalSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024)
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  ContentCategoryStats? getStats(ContentCategory category, AcademicYear year) {
    return statsByCategory[category]?[year];
  }
}

class ContentCategoryStats {
  final int subjects;
  final int chapters;
  final int pdfs;
  final int totalSize;

  ContentCategoryStats({
    required this.subjects,
    required this.chapters,
    required this.pdfs,
    required this.totalSize,
  });

  String get formattedSize {
    if (totalSize < 1024) return '$totalSize B';
    if (totalSize < 1024 * 1024)
      return '${(totalSize / 1024).toStringAsFixed(1)} KB';
    return '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
