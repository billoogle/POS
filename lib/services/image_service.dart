import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';

class ImageService {
  // ============================================
  // 🔑 STEP 1: ADD YOUR IMGBB API KEY HERE
  // ============================================
  // Get FREE API key from: https://api.imgbb.com/
  // Steps:
  // 1. Visit https://imgbb.com/
  // 2. Sign Up (Email/Google/Facebook) - NO CARD REQUIRED!
  // 3. Go to https://api.imgbb.com/
  // 4. Click "Get API Key"
  // 5. Copy your API key and paste below
  // ============================================
  
  static const String _apiKey = '8de07bef1fe079897600de3cb42542e0'; // 👈 PASTE YOUR KEY HERE
  
  // ============================================
  
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';
  final ImagePicker _picker = ImagePicker();

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('❌ Error picking image from camera: $e');
      return null;
    }
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('❌ Error picking image from gallery: $e');
      return null;
    }
  }

  // Upload image to ImgBB
  Future<Map<String, dynamic>> uploadImage(File imageFile) async {
    try {
      // Check if API key is configured
      if (_apiKey == 'YOUR_IMGBB_API_KEY' || _apiKey.isEmpty) {
        return {
          'success': false,
          'message': '⚠️ ImgBB API Key not configured!\n\n'
              'Steps to fix:\n'
              '1. Visit https://imgbb.com/ and Sign Up (FREE)\n'
              '2. Go to https://api.imgbb.com/\n'
              '3. Get your API Key\n'
              '4. Open lib/services/image_service.dart\n'
              '5. Replace YOUR_IMGBB_API_KEY with your key\n\n'
              'NO CREDIT CARD REQUIRED! 100% FREE!',
        };
      }

      print('📤 Starting image upload to ImgBB...');
      
      // Read image file
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      print('📦 Image size: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
      print('🔄 Converting to base64...');

      // Create multipart request
      final uri = Uri.parse(_uploadUrl);
      final request = http.MultipartRequest('POST', uri);
      
      // Add API key and image
      request.fields['key'] = _apiKey;
      request.fields['image'] = base64Image;
      
      print('🚀 Uploading to ImgBB...');

      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Upload timed out after 30 seconds');
        },
      );
      
      final response = await http.Response.fromStream(streamedResponse);
      
      print('📥 Response received: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        
        if (jsonResponse['success'] == true) {
          final imageUrl = jsonResponse['data']['url'];
          final displayUrl = jsonResponse['data']['display_url'];
          
          print('✅ Upload successful!');
          print('🔗 URL: $imageUrl');
          
          return {
            'success': true,
            'imageUrl': displayUrl ?? imageUrl,
            'message': 'Image uploaded successfully! ✓',
          };
        } else {
          print('❌ Upload failed: $jsonResponse');
          return {
            'success': false,
            'message': 'Upload failed: ${jsonResponse['error']?['message'] ?? 'Unknown error'}',
          };
        }
      } else if (response.statusCode == 400) {
        print('❌ Bad request: ${response.body}');
        
        // Check for invalid API key
        if (response.body.contains('invalid') || response.body.contains('key')) {
          return {
            'success': false,
            'message': '❌ Invalid API Key!\n\n'
                'Please check your ImgBB API key.\n'
                'Make sure you copied it correctly from https://api.imgbb.com/',
          };
        }
        
        return {
          'success': false,
          'message': 'Bad request: ${response.body}',
        };
      } else {
        print('❌ Server error: ${response.statusCode}');
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}\n${response.body}',
        };
      }
    } on TimeoutException catch (e) {
      print('⏱️ Timeout: $e');
      return {
        'success': false,
        'message': '⏱️ Upload timeout!\n\nPlease check your internet connection and try again.',
      };
    } on SocketException catch (e) {
      print('🌐 Network error: $e');
      return {
        'success': false,
        'message': '🌐 No internet connection!\n\nPlease check your network and try again.',
      };
    } catch (e) {
      print('❌ Upload error: $e');
      return {
        'success': false,
        'message': '❌ Error uploading image:\n${e.toString()}',
      };
    }
  }

  // Show image source selection dialog
  Future<File?> showImageSourceDialog(BuildContext context) async {
    File? selectedFile;
    
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_photo_alternate,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Select Image Source'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildSourceOption(
                context: dialogContext,
                icon: Icons.camera_alt,
                title: 'Camera',
                subtitle: 'Take a new photo',
                color: const Color(0xFF2563EB),
                onTap: () {
                  Navigator.pop(dialogContext, 'camera');
                },
              ),
              const SizedBox(height: 12),
              _buildSourceOption(
                context: dialogContext,
                icon: Icons.photo_library,
                title: 'Gallery',
                subtitle: 'Choose from gallery',
                color: const Color(0xFF10B981),
                onTap: () {
                  Navigator.pop(dialogContext, 'gallery');
                },
              ),
            ],
          ),
        );
      },
    );

    if (result == 'camera') {
      print('📷 Camera selected');
      selectedFile = await pickImageFromCamera();
    } else if (result == 'gallery') {
      print('🖼️ Gallery selected');
      selectedFile = await pickImageFromGallery();
    }

    if (selectedFile != null) {
      print('✅ Image selected: ${selectedFile.path}');
    } else {
      print('❌ No image selected');
    }

    return selectedFile;
  }

  Widget _buildSourceOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE2E8F0)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
  
  @override
  String toString() => message;
}