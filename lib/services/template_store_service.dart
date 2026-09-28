import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/render_template.dart';

/// Persists named RenderTemplates as a single JSON file under the app's
/// support directory, so a saved style configuration survives across
/// sessions and can be reapplied to a completely different release later.
class TemplateStoreService {
  Future<File> _file() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'templates.json'));
  }

  Future<List<RenderTemplate>> loadAll() async {
    try {
      final file = await _file();
      if (!await file.exists()) return [];
      final raw = await file.readAsString();
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => RenderTemplate.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeAll(List<RenderTemplate> templates) async {
    final file = await _file();
    await file.create(recursive: true);
    await file.writeAsString(
      jsonEncode(templates.map((t) => t.toJson()).toList()),
    );
  }

  /// Saves [template], replacing any existing template with the same name.
  Future<List<RenderTemplate>> save(RenderTemplate template) async {
    final templates = await loadAll();
    final next = [...templates.where((t) => t.name != template.name), template]
      ..sort((a, b) => a.name.compareTo(b.name));
    await _writeAll(next);
    return next;
  }

  Future<List<RenderTemplate>> delete(String name) async {
    final templates = await loadAll();
    final next = templates.where((t) => t.name != name).toList();
    await _writeAll(next);
    return next;
  }
}
