import 'package:flutter/material.dart';

class RequestServiceScreen extends StatefulWidget {
  final String providerName;

  const RequestServiceScreen({
    super.key,
    required this.providerName,
  });

  @override
  State<RequestServiceScreen> createState() => _RequestServiceScreenState();
}

class _RequestServiceScreenState extends State<RequestServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isSubmitting = false;

  static const _primary = Color(0xFF087A45);
  static const _dark = Color(0xFF102A43);
  static const _background = Color(0xFFF6F8F7);
  static const _muted = Color(0xFF667085);
  static const _border = Color(0xFFE3E8E5);

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Keep the small delay so the UI gives clear feedback while a real
    // Firebase/API request can be connected here later.
    await Future<void>.delayed(const Duration(milliseconds: 650));

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        title: const Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Color(0xFFE8F7EF),
              child: Icon(Icons.check_rounded, color: _primary),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Request sent',
                style: TextStyle(
                  color: _dark,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Your service request has been sent to ${widget.providerName}. '
          'You can track the request from your requests dashboard.',
          style: const TextStyle(
            color: _muted,
            height: 1.5,
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: FilledButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(96, 46),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Done'),
          ),
        ],
      ),
    );

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _primary),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD92D20)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD92D20), width: 1.6),
      ),
      labelStyle: const TextStyle(
        color: _muted,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String? _required(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Go back',
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        title: const Text(
          'Request a service',
          style: TextStyle(
            color: _dark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final contentWidth = constraints.maxWidth > 720
                  ? 680.0
                  : constraints.maxWidth;

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: contentWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProviderCard(),
                        const SizedBox(height: 22),
                        const Text(
                          'Tell us what you need',
                          style: TextStyle(
                            color: _dark,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Add your details so the provider can understand '
                          'the job and contact you quickly.',
                          style: TextStyle(
                            color: _muted,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildFormCard(),
                        const SizedBox(height: 18),
                        _buildNotice(),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton.icon(
                            onPressed:
                                _isSubmitting ? null : _submitRequest,
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  _primary.withOpacity(.55),
                              disabledForegroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                              ),
                            ),
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.3,
                                      valueColor:
                                          AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  )
                                : const Icon(Icons.send_rounded),
                            label: Text(
                              _isSubmitting
                                  ? 'Sending request...'
                                  : 'Send service request',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Center(
                          child: Text(
                            'You can review your request before any payment is made.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _muted,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProviderCard() {
    final initial = widget.providerName.trim().isEmpty
        ? 'G'
        : widget.providerName.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF087A45),
            Color(0xFF045A32),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 29,
            backgroundColor: Colors.white.withOpacity(.16),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SERVICE PROVIDER',
                  style: TextStyle(
                    color: Color(0xFFB8F2D1),
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.providerName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 15,
                      color: Color(0xFFB8F2D1),
                    ),
                    SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        'Ready to receive your request',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              label: 'Your name',
              hint: 'Enter your full name',
              icon: Icons.person_outline_rounded,
            ),
            validator: (value) =>
                _required(value, 'Please enter your name'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _locationController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: _inputDecoration(
              label: 'Service location',
              hint: 'Where should the service be provided?',
              icon: Icons.location_on_outlined,
            ),
            validator: (value) =>
                _required(value, 'Please enter the service location'),
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _messageController,
            minLines: 5,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.newline,
            decoration: _inputDecoration(
              label: 'Describe the service',
              hint: 'Tell the provider what you need, preferred time, '
                  'important details, or special instructions.',
              icon: Icons.description_outlined,
            ).copyWith(
              alignLabelWithHint: true,
            ),
            validator: (value) =>
                _required(value, 'Please describe the service you need'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotice() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF8F3),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFCDEBD9),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            color: _primary,
            size: 21,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Text(
              'Keep your request clear and accurate. A provider may '
              'contact you to confirm the details before accepting the job.',
              style: TextStyle(
                color: Color(0xFF245B3D),
                fontSize: 12.5,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
