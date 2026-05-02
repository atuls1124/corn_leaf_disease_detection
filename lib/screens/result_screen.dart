import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../models/disease_model.dart';
import '../utils/grad_cam_service.dart';
import '../utils/app_theme.dart';

class ResultScreen extends StatefulWidget {
  final String imagePath;
  final PredictionResult prediction;

  const ResultScreen({
    super.key,
    required this.imagePath,
    required this.prediction,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _isGeneratingCAM = false;
  Uint8List? _heatmapImage;
  bool _showGradCam = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Prediction Result'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImagePreview(),
            const SizedBox(height: 25),
            _buildGradCamButton(),
            if (_showGradCam && _heatmapImage != null) ...[
              const SizedBox(height: 20),
              _buildHeatmapView(),
            ],
            const SizedBox(height: 25),
            _buildPredictionCard(),
            const SizedBox(height: 25),
            _buildConfidenceSection(),
            const SizedBox(height: 25),
            _buildAllProbabilities(),
            const SizedBox(height: 30),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Image.file(File(widget.imagePath), fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildGradCamButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isGeneratingCAM ? null : _toggleGradCam,
        style: ElevatedButton.styleFrom(
          backgroundColor: _showGradCam ? Colors.orange : AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        icon: _isGeneratingCAM
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(_showGradCam ? Icons.visibility_off : Icons.visibility),
        label: Text(
          _isGeneratingCAM
              ? 'Generating...'
              : _showGradCam
              ? 'Hide Grad-CAM'
              : 'View Grad-CAM',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Future<void> _toggleGradCam() async {
    if (_showGradCam) {
      setState(() => _showGradCam = false);
      return;
    }

    if (_heatmapImage != null) {
      setState(() => _showGradCam = true);
      return;
    }

    setState(() => _isGeneratingCAM = true);

    try {
      final heatmap = await GradCamService.generateHeatmap(
        widget.imagePath,
        widget.prediction.label,
      );

      if (mounted) {
        setState(() {
          _heatmapImage = heatmap;
          _showGradCam = true;
          _isGeneratingCAM = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingCAM = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate Grad-CAM: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildHeatmapView() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.layers, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              const Text(
                'AI Attention (Grad-CAM)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Red/Yellow regions indicate high attention areas',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.memory(
              _heatmapImage!,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 15),
          _buildColorLegend(),
        ],
      ),
    );
  }

  Widget _buildColorLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem(const Color(0xFF0000FF), 'Low'),
        _buildLegendItem(const Color(0xFF00FF00), 'Medium'),
        _buildLegendItem(const Color(0xFFFFFF00), 'High'),
        _buildLegendItem(const Color(0xFFFF0000), 'Very High'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildPredictionCard() {
    final confidence = widget.prediction.confidencePercentage;
    final isHighConfidence = confidence >= 70;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            isHighConfidence ? Icons.check_circle : Icons.warning,
            size: 50,
            color: isHighConfidence ? Colors.green : Colors.orange,
          ),
          const SizedBox(height: 15),
          Text(
            'Predicted Disease',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            widget.prediction.label,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: _getConfidenceColor(confidence).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology,
                  size: 20,
                  color: _getConfidenceColor(confidence),
                ),
                const SizedBox(width: 8),
                Text(
                  '${confidence.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _getConfidenceColor(confidence),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceSection() {
    final confidence = widget.prediction.confidencePercentage;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bar_chart, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Text(
                'Confidence Level',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: widget.prediction.confidence,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getConfidenceColor(confidence),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getConfidenceLabel(confidence),
                style: TextStyle(
                  fontSize: 14,
                  color: _getConfidenceColor(confidence),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(confidence).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 14,
                  color: _getConfidenceColor(confidence),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllProbabilities() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart, color: AppTheme.primaryColor),
              const SizedBox(width: 10),
              Text(
                'All Probabilities',
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ...List.generate(DiseaseModel.labels.length, (index) {
            final label = DiseaseModel.labels[index];
            final probability = widget.prediction.allProbabilities[index];
            final isSelected = label == widget.prediction.label;

            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        '${(probability * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: LinearProgressIndicator(
                      value: probability,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isSelected ? AppTheme.primaryColor : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Another'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share functionality coming soon!'),
                ),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ],
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 80) return Colors.green;
    if (confidence >= 60) return Colors.lightGreen;
    if (confidence >= 40) return Colors.orange;
    return Colors.red;
  }

  String _getConfidenceLabel(double confidence) {
    if (confidence >= 80) return 'Very High';
    if (confidence >= 60) return 'High';
    if (confidence >= 40) return 'Medium';
    return 'Low';
  }
}
