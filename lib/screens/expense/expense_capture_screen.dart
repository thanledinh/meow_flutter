import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../config/theme.dart';
import '../../api/pet_api.dart';
import '../../api/expense_api.dart';
import '../../api/upload_api.dart';
import '../../api/api_client.dart';
import '../../api/upload_api.dart';
import '../../models/pet_model.dart';
import '../../widgets/toast.dart';
import 'package:go_router/go_router.dart';

class ExpenseCaptureScreen extends StatefulWidget {
  final Map<dynamic, dynamic>? expense;

  const ExpenseCaptureScreen({super.key, this.expense});

  @override
  State<ExpenseCaptureScreen> createState() => _ExpenseCaptureScreenState();
}

enum CaptureState { loading, error, liveCamera, preview }

class _ExpenseCaptureScreenState extends State<ExpenseCaptureScreen> {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];

  CaptureState _state = CaptureState.loading;
  String _errorMessage = '';

  File? _localImage;
  String? _remoteImageUrl;

  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _focusNodeNote = FocusNode();
  final _focusNodeAmount = FocusNode();

  String? _petId;
  List<PetModel> _pets = [];
  bool _saving = false;
  bool _uploadingImage = false;
  int _selectedCameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchPets();
    
    if (widget.expense != null) {
      // Edit mode: jump to preview state
      _amountCtrl.text = widget.expense!['amount']?.toString() ?? '';
      _noteCtrl.text = widget.expense!['note']?.toString() ?? '';
      _petId = widget.expense!['petId']?.toString();
      _remoteImageUrl = widget.expense!['imageUrl']?.toString();
      setState(() => _state = CaptureState.preview);
    } else {
      // Create mode: start camera
      _initCamera();
    }
  }

  Future<void> _fetchPets() async {
    try {
      final res = await PetApi.getAll();
      if (res.success && mounted) {
         final List items = (res.data is Map ? res.data['data'] : res.data) ?? [];
         setState(() {
           _pets = items.map((e) => PetModel.fromJson(e)).toList();
         });
      }
    } catch (_) {}
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _state = CaptureState.error;
          _errorMessage = 'Không tìm thấy Camera trên thiết bị';
        });
        return;
      }
      
      _selectedCameraIndex = 0; // Usually back camera
      await _setupCameraController();
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = CaptureState.error;
        _errorMessage = 'Lỗi khởi tạo Camera:\n$e';
      });
    }
  }

  Future<void> _setupCameraController() async {
    final camera = _cameras[_selectedCameraIndex];
    
    final oldController = _cameraController;
    if (oldController != null) {
      await oldController.dispose();
    }
    
    _cameraController = CameraController(
      camera, 
      ResolutionPreset.high, 
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg
    );
    
    try {
      await _cameraController!.initialize();
      if (!mounted) return;
      setState(() {
        _state = CaptureState.liveCamera;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _state = CaptureState.error;
        _errorMessage = 'Lỗi truy cập Camera:\n$e';
      });
    }
  }

  Future<void> _flipCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    setState(() => _state = CaptureState.loading);
    await _setupCameraController();
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (_cameraController!.value.isTakingPicture) return;

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      setState(() {
        _localImage = File(imageFile.path);
        _state = CaptureState.preview;
      });
      // Bắt đầu upload ngầm
      _uploadLocalImage();
    } catch (e) {
      MoewToast.show(context, message: 'Lỗi chụp ảnh: $e', type: ToastType.error);
    }
  }
  
  Future<void> _uploadLocalImage() async {
    if (_localImage == null) return;
    setState(() => _uploadingImage = true);
    final res = await UploadApi.image(_localImage!.path);
    if (!mounted) return;
    setState(() => _uploadingImage = false);

    if (res.success) {
      final payload = res.data is Map ? res.data['data'] : res.data;
      _remoteImageUrl = (payload is Map ? payload['url'] : payload)?.toString();
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi tải ảnh lên Cloud', type: ToastType.error);
    }
  }

  void _retake() {
    _localImage = null;
    _amountCtrl.clear();
    _noteCtrl.clear();
    setState(() => _state = CaptureState.liveCamera);
  }

  Future<void> _save() async {
    final amountText = _amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (amountText.isEmpty) {
       MoewToast.show(context, message: 'Vui lòng nhập số tiền hợp lệ', type: ToastType.error);
       return;
    }
    
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    
    if (_uploadingImage) {
      // Đang upload dở thì khoan lưu, đợi tý
      await Future.delayed(const Duration(seconds: 2));
    }

    final data = {
      'amount': int.parse(amountText),
      'currency': 'VND',
      if (_noteCtrl.text.trim().isNotEmpty) 'note': _noteCtrl.text.trim(),
      'date': DateTime.now().toIso8601String().split('T')[0],
      if (_petId != null) 'petId': int.parse(_petId!),
      if (_remoteImageUrl != null && _remoteImageUrl!.isNotEmpty) 'imageUrl': _remoteImageUrl,
    };

    final isEdit = widget.expense != null;
    ApiResponse res;
    if (isEdit) {
      res = await ExpenseApi.updateExpense(widget.expense!['id'], data);
    } else {
      res = await ExpenseApi.createExpense(data);
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (res.success) {
      MoewToast.show(context, message: isEdit ? 'Đã cập nhật' : 'Đã ghi chi tiêu', type: ToastType.success);
      context.pop(true);
    } else {
      MoewToast.show(context, message: res.error ?? 'Lỗi không xác định', type: ToastType.error);
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    _focusNodeNote.dispose();
    _focusNodeAmount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E), // Phông nền chì đen mờ
      body: SafeArea(
        child: Column(
          children: [
            // Thanh Top Nav
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 28),
                    onPressed: () => context.pop(),
                  ),
                  if (_pets.isNotEmpty)
                    Container(
                      height: 36,
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(18)),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _petId,
                          dropdownColor: const Color(0xFF2A2A2A),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                          hint: const Text('🐶 Tất cả', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('🐶 Tất cả', style: TextStyle(color: Colors.white))),
                            ..._pets.map((p) => DropdownMenuItem(value: p.id.toString(), child: Text(p.name, style: const TextStyle(color: Colors.white)))),
                          ],
                          onChanged: (val) {
                            setState(() => _petId = val);
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Khung Camera / Ảnh tĩnh
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_state == CaptureState.preview) {
                    _focusNodeNote.requestFocus();
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      _buildBackground(),
                      if (_uploadingImage)
                         Container(color: Colors.black26, alignment: Alignment.topRight, padding: EdgeInsets.all(16), child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))),
                      _buildOverlays(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Khu vực Nút bấm bên dưới
            Container(
              height: 120,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: _buildBottomControls(),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (_state == CaptureState.loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (_state == CaptureState.error) {
      return Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.white), textAlign: TextAlign.center));
    }
    
    if (_state == CaptureState.liveCamera && _cameraController != null) {
      return Center(
        child: AspectRatio(
          aspectRatio: 1 / _cameraController!.value.aspectRatio,
          child: CameraPreview(_cameraController!),
        ),
      );
    }
    
    if (_state == CaptureState.preview) {
      if (_localImage != null) {
         return Image.file(_localImage!, fit: BoxFit.cover);
      } else if (_remoteImageUrl != null && _remoteImageUrl!.isNotEmpty) {
         return Image.network(_remoteImageUrl!, fit: BoxFit.cover);
      }
    }
    
    return const Center(child: Icon(Icons.receipt, color: Colors.white30, size: 64));
  }

  Widget _buildOverlays() {
    if (_state != CaptureState.preview) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Khung text để gõ ghi chú nổi trên ảnh
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _noteCtrl,
              focusNode: _focusNodeNote,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(color: Colors.black87, blurRadius: 10, offset: Offset(0, 2))],
              ),
              maxLength: 100,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Chạm đẽ gõ...',
                hintStyle: TextStyle(color: Colors.white60, fontSize: 32, shadows: [], fontWeight: FontWeight.normal),
                border: InputBorder.none,
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Khung tiền
          Container(
             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
             margin: const EdgeInsets.only(bottom: 32),
             decoration: BoxDecoration(
               color: Colors.black.withValues(alpha: 0.5),
               borderRadius: BorderRadius.circular(24),
               border: Border.all(color: Colors.white24),
             ),
             child: IntrinsicWidth(
               child: Row(
                 mainAxisSize: MainAxisSize.min,
                 children: [
                   const Text('₫', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                   const SizedBox(width: 8),
                   Container(
                     constraints: const BoxConstraints(minWidth: 40, maxWidth: 120),
                     child: TextField(
                       controller: _amountCtrl,
                       focusNode: _focusNodeAmount,
                       keyboardType: TextInputType.number,
                       style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                       decoration: const InputDecoration(
                         hintText: '0',
                         hintStyle: TextStyle(color: Colors.white54),
                         border: InputBorder.none,
                         isDense: true,
                         contentPadding: EdgeInsets.zero,
                       ),
                     ),
                   ),
                 ],
               ),
             ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    if (_state == CaptureState.loading || _state == CaptureState.error) {
       return const SizedBox.shrink();
    }
    
    if (_state == CaptureState.liveCamera) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.flash_off, color: Colors.white, size: 28),
            onPressed: () {},
          ),
          GestureDetector(
            onTap: _takePicture,
            child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFB800), width: 5),
              ),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.flip_camera_ios, color: Colors.white, size: 28),
            onPressed: _flipCamera,
          ),
        ],
      );
    }
    
    // Trạng thái preview ảnh đã chụp/chỉnh sửa
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
         InkWell(
           onTap: _retake,
           child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
               Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
                 child: const Icon(Icons.close, color: Colors.white),
               ),
               const SizedBox(height: 8),
               const Text('Chụp lại', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
             ],
           ),
         ),
         
         const SizedBox(width: 32),
         
         Expanded(
           child: InkWell(
             onTap: _saving ? null : _save,
             child: Container(
               height: 60,
               decoration: BoxDecoration(color: const Color(0xFFFFB800), borderRadius: BorderRadius.circular(30)),
               alignment: Alignment.center,
               child: _saving 
                   ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 3))
                   : const Row(
                       mainAxisAlignment: MainAxisAlignment.center,
                       children: [
                         Text('LƯU VỀ', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                         SizedBox(width: 8),
                         Icon(Icons.send, color: Colors.black, size: 20),
                       ],
                     ),
             ),
           )
         ),
      ],
    );
  }
}
