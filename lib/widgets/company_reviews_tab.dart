import 'package:app_front_mobile/services/company_review_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/api_error_handler.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:app_front_mobile/utils/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CompanyReviewsTab extends StatefulWidget {
  final String companyId;

  const CompanyReviewsTab({super.key, required this.companyId});

  @override
  State<CompanyReviewsTab> createState() => _CompanyReviewsTabState();
}

class _CompanyReviewsTabState extends State<CompanyReviewsTab> {
  final _service = CompanyReviewService(baseUrl: 'http://localhost:8081');

  final _tokenStorage = TokenStorage();

  bool _loading = true;

  List<CompanyReviewItem> _reviews = [];

  CompanyReviewSummary _summary = const CompanyReviewSummary(
    average: 0,
    total: 0,
  );

  @override
  void initState() {
    super.initState();

    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _service.findPublic(companyId: widget.companyId),
        _service.findSummary(companyId: widget.companyId),
      ]);

      if (!mounted) return;

      final reviews = results[0] as CompanyReviewPage;

      final summary = results[1] as CompanyReviewSummary;

      setState(() {
        _reviews = reviews.content;
        _summary = summary;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _review() async {
    final allowed = await AuthGate.requireLogin(
      context,
      reason: 'Voce precisa estar logado para avaliar este estabelecimento.',
    );

    if (!allowed || !mounted) {
      return;
    }

    await showDialog(
      context: context,
      builder: (_) => _ReviewDialog(
        companyId: widget.companyId,
        service: _service,
        tokenStorage: _tokenStorage,
      ),
    );

    await _load();
  }

  Widget _stars(int value, {double size = 18}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < value ? Icons.star : Icons.star_border,
          size: size,
          color: Colors.amber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _summary.average.toStringAsFixed(1),
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                _stars(_summary.average.round()),
                const SizedBox(height: 4),
                Text(
                  '${_summary.total} avaliacoes',
                  style: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _review,
              icon: const Icon(Icons.star_outline),
              label: const Text('Avaliar estabelecimento'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (_reviews.isEmpty)
          const SizedBox(
            height: 120,
            child: Center(
              child: Text('Este estabelecimento ainda nao possui avaliacoes.'),
            ),
          )
        else
          ..._reviews.map((review) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          child: Text(
                            review.authorName.isNotEmpty
                                ? review.authorName[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            review.authorName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        _stars(review.rating, size: 16),
                      ],
                    ),
                    if (review.comment.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(review.comment),
                    ],
                    if (review.imageUrl.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          'http://localhost:8081${review.imageUrl}',
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _ReviewDialog extends StatefulWidget {
  final String companyId;

  final CompanyReviewService service;

  final TokenStorage tokenStorage;

  const _ReviewDialog({
    required this.companyId,
    required this.service,
    required this.tokenStorage,
  });

  @override
  State<_ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<_ReviewDialog> {
  final _commentCtrl = TextEditingController();

  int _rating = 5;

  XFile? _image;

  bool _saving = false;

  @override
  void dispose() {
    _commentCtrl.dispose();

    super.dispose();
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (image == null) return;

    setState(() {
      _image = image;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
    });

    try {
      final token = await widget.tokenStorage.getAccessToken();

      if (token == null || token.isEmpty) {
        return;
      }

      String imageUrl = '';

      if (_image != null) {
        imageUrl = await widget.service.uploadImage(
          token: token,
          bytes: await _image!.readAsBytes(),
          filename: _image!.name,
        );
      }

      await widget.service.create(
        token: token,
        companyId: widget.companyId,
        rating: _rating,
        comment: _commentCtrl.text.trim(),
        imageUrl: imageUrl,
      );

      if (!mounted) return;

      Navigator.of(context).pop();

      AppMessage.success(context, 'Avaliacao enviada com sucesso');
    } catch (e) {
      if (!mounted) return;

      AppMessage.apiError(context, e, fallback: 'Erro ao enviar avaliacao.');
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sua avaliacao'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = index + 1;
                    });
                  },
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Comentario (opcional)',
                hintText: 'Conte como foi sua experiencia',
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image_outlined),
              label: Text(_image == null ? 'Adicionar imagem' : _image!.name),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Publicar'),
        ),
      ],
    );
  }
}
