import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants.dart';
import '../models/garment_item.dart';
import '../models/tryon_request.dart';
import '../models/tryon_result.dart';
import '../services/api_service.dart';

class TryOnProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  // Selected inputs
  Uint8List? _personImageBytes;
  String? _personImageName;

  Uint8List? _garmentImageBytes;
  String? _garmentImageName;
  GarmentItem? _selectedGarmentItem;

  // Fit & Generation Controls
  String _selectedFit = 'Tailored'; // 'Tailored', 'Regular', 'Oversized'
  bool _lockPose = false;
  bool _autoCleanBg = true;

  // Inference state
  bool _isLoading = false;
  String _currentStepDescription = 'AI is weaving your outfit...';
  double _progress = 0.0;
  String? _errorMessage;

  // Output
  TryOnResult? _latestResult;

  // Curated capsule items
  final List<GarmentItem> _capsuleItems = const [
    GarmentItem(
      id: 'capsule_1',
      name: 'Drape Coat',
      designer: 'Maison K.',
      assetPath: AppConstants.sampleRecentTrench,
      category: 'Outerwear',
      price: '\$1,420',
    ),
    GarmentItem(
      id: 'capsule_2',
      name: 'Silk Gown',
      designer: 'Atelier Noir',
      assetPath: AppConstants.sampleRecentSilk,
      category: 'Dresses',
      price: '\$980',
    ),
    GarmentItem(
      id: 'capsule_3',
      name: 'Tweed Blazer',
      designer: 'Studio 88',
      assetPath: AppConstants.sampleGarmentBlazer,
      category: 'Jackets',
      price: '\$750',
    ),
    GarmentItem(
      id: 'capsule_4',
      name: 'Boxy Trench',
      designer: 'Studio Lab',
      assetPath: AppConstants.sampleRecentTrench,
      category: 'Outerwear',
      price: '\$1,100',
    ),
  ];

  // Recent renders history
  final List<TryOnResult> _recentRenders = [
    TryOnResult(
      id: 'recent_1',
      title: 'Wool Trench',
      designer: 'Maison K.',
      resultAssetPath: AppConstants.sampleRecentTrench,
      fitScore: 98.0,
      renderTimeSec: 3.4,
      fitType: 'Tailored',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    TryOnResult(
      id: 'recent_2',
      title: 'Ivory Silk Shirt',
      designer: 'Atelier Noir',
      resultAssetPath: AppConstants.sampleRecentSilk,
      fitScore: 95.0,
      renderTimeSec: 3.1,
      fitType: 'Regular',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
    ),
  ];

  // Getters
  Uint8List? get personImageBytes => _personImageBytes;
  String? get personImageName => _personImageName;
  Uint8List? get garmentImageBytes => _garmentImageBytes;
  String? get garmentImageName => _garmentImageName;
  GarmentItem? get selectedGarmentItem => _selectedGarmentItem;
  String get selectedFit => _selectedFit;
  bool get lockPose => _lockPose;
  bool get autoCleanBg => _autoCleanBg;
  bool get isLoading => _isLoading;
  String get currentStepDescription => _currentStepDescription;
  double get progress => _progress;
  String? get errorMessage => _errorMessage;
  TryOnResult? get latestResult => _latestResult;
  List<TryOnResult> get recentRenders => List.unmodifiable(_recentRenders);
  List<GarmentItem> get capsuleItems => List.unmodifiable(_capsuleItems);

  bool get canProceedToTryOn =>
      _personImageBytes != null && _garmentImageBytes != null;

  // Actions for Person Silhouette
  Future<void> pickPersonImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 2400,
        imageQuality: 92,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        _personImageBytes = bytes;
        _personImageName = file.name;
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[TryOnProvider] Error picking person image: $e');
    }
  }

  Future<void> loadMuseElenaPreset() async {
    try {
      final byteData = await rootBundle.load(AppConstants.sampleMuseElena);
      _personImageBytes = byteData.buffer.asUint8List();
      _personImageName = 'Muse_Elena_Preset.png';
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[TryOnProvider] Error loading Muse Elena: $e');
    }
  }

  void setPersonBytes(Uint8List bytes, String name) {
    _personImageBytes = bytes;
    _personImageName = name;
    notifyListeners();
  }

  void clearPersonImage() {
    _personImageBytes = null;
    _personImageName = null;
    notifyListeners();
  }

  // Actions for Garment
  Future<void> pickGarmentImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 2400,
        imageQuality: 92,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        _garmentImageBytes = bytes;
        _garmentImageName = file.name;
        _selectedGarmentItem = null;
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[TryOnProvider] Error picking garment image: $e');
    }
  }

  Future<void> loadGarmentPreset(GarmentItem item) async {
    try {
      final byteData = await rootBundle.load(item.assetPath);
      _garmentImageBytes = byteData.buffer.asUint8List();
      _garmentImageName = item.name;
      _selectedGarmentItem = item;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('[TryOnProvider] Error loading garment preset: $e');
    }
  }

  void clearGarmentImage() {
    _garmentImageBytes = null;
    _garmentImageName = null;
    _selectedGarmentItem = null;
    notifyListeners();
  }

  // Fit & Control Setters
  void setSelectedFit(String fit) {
    _selectedFit = fit;
    notifyListeners();
  }

  void toggleLockPose(bool value) {
    _lockPose = value;
    notifyListeners();
  }

  void toggleAutoCleanBg(bool value) {
    _autoCleanBg = value;
    notifyListeners();
  }

  // Virtual Try-On Execution
  Future<bool> executeVirtualTryOn() async {
    if (!canProceedToTryOn) {
      _errorMessage = 'Please select both your silhouette and a garment to try on.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _progress = 0.05;
    _currentStepDescription = 'Initializing IDM-VTON diffusion pipeline...';
    _errorMessage = null;
    notifyListeners();

    try {
      final request = TryOnRequest(
        personImageBytes: _personImageBytes!,
        personImageName: _personImageName,
        garmentImageBytes: _garmentImageBytes!,
        garmentImageName: _garmentImageName,
        fitType: _selectedFit,
        lockPose: _lockPose,
        autoCleanBg: _autoCleanBg,
      );

      final result = await _apiService.processVirtualTryOn(
        request,
        onProgress: (step, progressValue) {
          _currentStepDescription = step;
          _progress = progressValue;
          notifyListeners();
        },
      );

      _latestResult = result;
      _recentRenders.insert(0, result);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Inference failed: $e';
      notifyListeners();
      return false;
    }
  }

  void resetForNewTryOn() {
    _garmentImageBytes = null;
    _garmentImageName = null;
    _selectedGarmentItem = null;
    _latestResult = null;
    _errorMessage = null;
    notifyListeners();
  }

  void setLatestResult(TryOnResult result) {
    _latestResult = result;
    notifyListeners();
  }
}
