import 'package:app_front_mobile/services/company_lookup_service.dart';
import 'package:app_front_mobile/services/product_service.dart';
import 'package:app_front_mobile/storage/token_storage.dart';
import 'package:app_front_mobile/utils/app_message.dart';
import 'package:app_front_mobile/widgets/company_lookup_modal.dart';
import 'package:flutter/material.dart';

class ProductFormPage extends StatefulWidget {
  final String currentUserRole;

  final String? productId;

  const ProductFormPage({
    super.key,
    required this.currentUserRole,
    this.productId,
  });

  bool get isEdit => productId != null && productId!.isNotEmpty;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();

  final _descriptionCtrl = TextEditingController();

  final _priceCtrl = TextEditingController();

  final _stockCtrl = TextEditingController();

  final _imageUrlCtrl = TextEditingController();

  final _tokenStorage = TokenStorage();

  final _service = ProductService(baseUrl: 'http://localhost:8081/product');

  final _companyLookupService = CompanyLookupService(
    baseUrl: 'http://localhost:8081/company',
  );

  String? _companyId;

  String _companyName = '';

  String _status = 'ACTIVE';

  bool _loading = true;

  bool _saving = false;

  bool get _isMasterAdmin => widget.currentUserRole == 'MASTER_ADMIN';

  @override
  void initState() {
    super.initState();

    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _imageUrlCtrl.dispose();

    super.dispose();
  }

  Future<String> _token() async {
    final token = await _tokenStorage.getAccessToken();

    if (token == null || token.isEmpty) {
      throw Exception('Token nao encontrado');
    }

    return token;
  }

  Future<void> _load() async {
    try {
      if (widget.isEdit) {
        final token = await _token();

        final product = await _service.findById(
          token: token,
          id: widget.productId!,
        );

        _nameCtrl.text = product.name;

        _descriptionCtrl.text = product.description;

        _priceCtrl.text = product.price.toStringAsFixed(2).replaceAll('.', ',');

        _stockCtrl.text = product.stockQuantity.toString();

        _imageUrlCtrl.text = product.imageUrl;

        _companyId = product.companyId;

        _companyName = product.companyName;

        _status = product.status;
      }

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      AppMessage.apiError(context, e, fallback: 'Erro ao carregar produto.');
    }
  }

  Future<void> _selectCompany() async {
    if (!_isMasterAdmin || widget.isEdit) {
      return;
    }

    try {
      final token = await _token();

      if (!mounted) return;

      final selected = await CompanyLookupModal.show(
        context: context,
        token: token,
        service: _companyLookupService,
      );

      if (selected == null || !mounted) {
        return;
      }

      setState(() {
        _companyId = selected.id;

        _companyName = selected.displayName;
      });
    } catch (e) {
      if (!mounted) return;

      AppMessage.apiError(context, e, fallback: 'Erro ao selecionar empresa.');
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_isMasterAdmin &&
        !widget.isEdit &&
        (_companyId == null || _companyId!.isEmpty)) {
      AppMessage.info(context, 'Selecione a empresa.');

      return;
    }

    final price = double.tryParse(_priceCtrl.text.trim().replaceAll(',', '.'));

    final stock = int.tryParse(_stockCtrl.text.trim());

    if (price == null || price < 0) {
      AppMessage.info(context, 'Preço inválido.');

      return;
    }

    if (stock == null || stock < 0) {
      AppMessage.info(context, 'Quantidade em estoque inválida.');

      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final token = await _token();

      final request = ProductRequest(
        companyId: _isMasterAdmin ? _companyId : null,

        name: _nameCtrl.text.trim(),

        description: _descriptionCtrl.text.trim(),

        price: price,

        stockQuantity: stock,

        imageUrl: _imageUrlCtrl.text.trim(),

        status: _status,
      );

      if (widget.isEdit) {
        await _service.update(
          token: token,
          id: widget.productId!,
          request: request,
        );
      } else {
        await _service.create(token: token, request: request);
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;

      AppMessage.apiError(context, e, fallback: 'Erro ao salvar produto.');
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
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Editar Produto' : 'Novo Produto'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isMasterAdmin) _buildCompanyField(),

                  if (_isMasterAdmin) const SizedBox(height: 16),

                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nome do produto',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Nome obrigatório';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Descrição',
                      alignLabelWithHint: true,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Preço',
                            prefixText: 'R\$ ',
                          ),
                          validator: (value) {
                            final parsed = double.tryParse(
                              (value ?? '').replaceAll(',', '.'),
                            );

                            if (parsed == null || parsed < 0) {
                              return 'Preço inválido';
                            }

                            return null;
                          },
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: TextFormField(
                          controller: _stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantidade em estoque',
                          ),
                          validator: (value) {
                            final parsed = int.tryParse(value ?? '');

                            if (parsed == null || parsed < 0) {
                              return 'Estoque inválido';
                            }

                            return null;
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: const InputDecoration(labelText: 'Status'),
                    items: const [
                      DropdownMenuItem(value: 'ACTIVE', child: Text('Ativo')),
                      DropdownMenuItem(
                        value: 'INACTIVE',
                        child: Text('Inativo'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _status = value ?? 'ACTIVE';
                      });
                    },
                  ),

                  const SizedBox(height: 22),

                  Text(
                    'Imagem do produto',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _imageUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'URL da imagem',
                      hintText: 'https://...',
                    ),
                    onChanged: (_) {
                      setState(() {});
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Imagem obrigatória';
                      }

                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildImagePreview(),

                  const SizedBox(height: 28),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.isEdit
                                  ? 'Salvar alterações'
                                  : 'Cadastrar produto',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyField() {
    return InkWell(
      onTap: widget.isEdit ? null : _selectCompany,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Empresa',
          suffixIcon: Icon(Icons.search),
        ),
        child: Text(_companyName.isEmpty ? 'Selecionar empresa' : _companyName),
      ),
    );
  }

  Widget _buildImagePreview() {
    final imageUrl = _imageUrlCtrl.text.trim();

    return Container(
      width: double.infinity,
      height: 260,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.22),
        ),
      ),
      child: imageUrl.isEmpty
          ? const Center(child: Icon(Icons.image_outlined, size: 54))
          : Image.network(
              imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text('Não foi possível carregar a imagem'),
                );
              },
            ),
    );
  }
}
